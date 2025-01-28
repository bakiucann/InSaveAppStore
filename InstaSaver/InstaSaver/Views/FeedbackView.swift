// FeedbackView.swift

import SwiftUI
import MessageUI

struct FeedbackView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var feedbackType: FeedbackType = .general
    @State private var feedbackText: String = ""
    @State private var showMailCompose = false
    @State private var showSuccessAlert = false
    @State private var showImagePicker = false
    @State private var attachedImage: UIImage?
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let instagramGradient = LinearGradient(
        colors: [
            Color("igPurple"),
            Color("igPink"),
            Color("igOrange")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    enum FeedbackType: String, CaseIterable {
        case general = "General"
        case bugReport = "Bug"
        case feature = "Feature Request"
        case other = "Other"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text(NSLocalizedString("Cancel", comment: ""))
                        .font(.system(size: 16))
                        .foregroundColor(Color("igPurple"))
                }
                
                Spacer()
                
                Button(action: submitFeedback) {
                    Text(NSLocalizedString("Send", comment: ""))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(feedbackText.isEmpty ? Color("igPurple").opacity(0.6) : Color("igPurple"))
                }
                .disabled(feedbackText.isEmpty)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Feedback Type Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(NSLocalizedString("What type of feedback do you have?", comment: ""))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.black.opacity(0.8))
                        
                        HStack(spacing: 10) {
                            ForEach(FeedbackType.allCases, id: \.self) { type in
                                feedbackTypeButton(type)
                            }
                        }
                    }
                    .padding(.top, 16)
                    
                    // Feedback Text Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(NSLocalizedString("Tell us more", comment: ""))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.black.opacity(0.8))
                        
                        TextEditor(text: $feedbackText)
                            .frame(height: 120)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color("igPurple").opacity(0.2),
                                                        Color("igPink").opacity(0.2)
                                                    ],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .foregroundColor(.black)
                            .font(.system(size: 15))
                    }
                    
                    // Screenshot Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(NSLocalizedString("Add a screenshot", comment: ""))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.black.opacity(0.8))
                        
                        Button(action: { showImagePicker = true }) {
                            HStack {
                                Image(systemName: attachedImage == nil ? "camera.fill" : "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                Text(attachedImage == nil ? NSLocalizedString("Choose from library", comment: "") : NSLocalizedString("Image selected", comment: ""))
                                    .font(.system(size: 14))
                                Spacer()
                            }
                            .foregroundColor(attachedImage == nil ? .black.opacity(0.6) : Color("igPurple"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color("igPurple").opacity(0.2),
                                                        Color("igPink").opacity(0.2)
                                                    ],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        
                        if let image = attachedImage {
                            HStack {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                Button(action: { attachedImage = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showMailCompose) {
            MailComposeView(
                toRecipients: ["ucnllc@gmail.com"],
                subject: "[\(feedbackType.rawValue)] InSave Feedback",
                messageBody: createEmailBody(),
                attachedImage: attachedImage
            )
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $attachedImage)
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text(NSLocalizedString("Alternative Contact Options", comment: "")),
                message: Text(errorMessage),
                primaryButton: .default(Text(NSLocalizedString("Copy Feedback", comment: ""))) {
                    UIPasteboard.general.string = createEmailBody()
                },
                secondaryButton: .cancel(Text(NSLocalizedString("OK", comment: "")))
            )
        }
    }
    
    private func feedbackTypeButton(_ type: FeedbackType) -> some View {
        Button(action: { feedbackType = type }) {
            Text(NSLocalizedString(type.rawValue, comment: ""))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(feedbackType == type ? .white : .black.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(feedbackType == type ? 
                            instagramGradient : LinearGradient(
                                colors: [Color(.systemGray6), Color(.systemGray6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    feedbackType == type ? LinearGradient(
                                        colors: [Color.clear, Color.clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) : LinearGradient(
                                        colors: [
                                            Color("igPurple").opacity(0.2),
                                            Color("igPink").opacity(0.2)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
        }
    }
    
    private func createEmailBody() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let iosVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.model
        
        return """
        \(String(format: NSLocalizedString("Feedback Type: %@", comment: ""), feedbackType.rawValue))
        
        \(NSLocalizedString("User Feedback:", comment: ""))
        \(feedbackText)
        
        --- \(NSLocalizedString("Device Info", comment: "")) ---
        \(String(format: NSLocalizedString("App Version: %@ (%@)", comment: ""), appVersion, buildNumber))
        \(String(format: NSLocalizedString("iOS Version: %@", comment: ""), iosVersion))
        \(String(format: NSLocalizedString("Device: %@", comment: ""), deviceModel))
        """
    }
    
    private func submitFeedback() {
        if MFMailComposeViewController.canSendMail() {
            showMailCompose = true
        } else {
            errorMessage = NSLocalizedString("Email not available message", comment: "")
            showError = true
            UIPasteboard.general.string = createEmailBody()
        }
    }
}

// MARK: - Mail Compose View
struct MailComposeView: UIViewControllerRepresentable {
    let toRecipients: [String]
    let subject: String
    let messageBody: String
    let attachedImage: UIImage?
    
    @Environment(\.presentationMode) var presentationMode
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(toRecipients)
        vc.setSubject(subject)
        vc.setMessageBody(messageBody, isHTML: false)
        
        if let image = attachedImage,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            vc.addAttachmentData(imageData, mimeType: "image/jpeg", fileName: "screenshot.jpg")
        }
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController,
                                 didFinishWith result: MFMailComposeResult,
                                 error: Error?) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                 didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
