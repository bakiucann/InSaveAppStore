// FeedbackView.swift

import SwiftUI
import MessageUI
import PhotosUI

struct FeedbackView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var feedbackType: FeedbackType = .general
    @State private var feedbackText: String = ""
    @State private var showMailCompose = false
    @State private var showSuccessAlert = false
    @State private var showImagePicker = false
    @State private var attachedImages: [UIImage] = []
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
        case feature = "Feature"
        case other = "Other"
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Bar with Glassmorphic Back Button
                HStack {
                    GlassmorphicBackButton {
                        presentationMode.wrappedValue.dismiss()
                    }
                    
                    Spacer()
                    
                    // Send Button - Glassmorphic with gradient when active
                    Button(action: submitFeedback) {
                        Text(NSLocalizedString("Send", comment: ""))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(feedbackText.isEmpty ? Color("igPink").opacity(0.5) : .white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(
                                        feedbackText.isEmpty ?
                                        LinearGradient(
                                            colors: [
                                                Color("igPurple").opacity(0.15),
                                                Color("igPink").opacity(0.15)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ) :
                                        instagramGradient
                                    )
                            )
                            .shadow(
                                color: feedbackText.isEmpty ? Color.clear : Color("igPink").opacity(0.3),
                                radius: feedbackText.isEmpty ? 0 : 8,
                                x: 0,
                                y: feedbackText.isEmpty ? 0 : 4
                            )
                    }
                    .disabled(feedbackText.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                ScrollView {
                    VStack(spacing: 28) {
                        // Feedback Type Section with Professional Glassmorphic Design
                        VStack(alignment: .leading, spacing: 18) {
                            Text(NSLocalizedString("What type of feedback do you have?", comment: ""))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black.opacity(0.9))
                            
                            HStack(spacing: 12) {
                                ForEach(FeedbackType.allCases, id: \.self) { type in
                                    feedbackTypeButton(type)
                                }
                            }
                        }
                        .padding(.top, 12)
                        
                        // Feedback Text Section with Enhanced Glassmorphic Design
                        VStack(alignment: .leading, spacing: 18) {
                            Text(NSLocalizedString("Tell us more", comment: ""))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black.opacity(0.9))
                            
                            ZStack(alignment: .topLeading) {
                                // Glassmorphic background container
                                if #available(iOS 15.0, *) {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            // Tinted gradient overlay
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [
                                                            Color("igPurple").opacity(0.05),
                                                            Color("igPink").opacity(0.04),
                                                            Color("igOrange").opacity(0.03)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                        )
                                        .overlay(
                                            // Elegant border
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [
                                                            Color("igPurple").opacity(0.3),
                                                            Color("igPink").opacity(0.3),
                                                            Color("igOrange").opacity(0.2)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1.5
                                                )
                                        )
                                        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 8)
                                        .shadow(color: Color("igPink").opacity(0.08), radius: 25, x: 0, y: 12)
                                } else {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.92),
                                                    Color.white.opacity(0.88)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            // Tinted gradient overlay
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [
                                                            Color("igPurple").opacity(0.05),
                                                            Color("igPink").opacity(0.04),
                                                            Color("igOrange").opacity(0.03)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                        )
                                        .overlay(
                                            // Elegant border
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [
                                                            Color("igPurple").opacity(0.3),
                                                            Color("igPink").opacity(0.3),
                                                            Color("igOrange").opacity(0.2)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1.5
                                                )
                                        )
                                        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 8)
                                        .shadow(color: Color("igPink").opacity(0.08), radius: 25, x: 0, y: 12)
                                }
                                
                                // TextEditor with proper styling
                                if #available(iOS 16.0, *) {
                                    TextEditor(text: $feedbackText)
                                        .font(.system(size: 17))
                                        .foregroundColor(.black.opacity(0.9))
                                        .padding(18)
                                        .scrollContentBackground(.hidden)
                                } else {
                                    TextEditor(text: $feedbackText)
                                        .font(.system(size: 17))
                                        .foregroundColor(.black.opacity(0.9))
                                        .padding(18)
                                        .onAppear {
                                            UITextView.appearance().backgroundColor = .clear
                                        }
                                }
                            }
                            .frame(height: 180)
                        }
                    
                        // Screenshot Section with Professional Glassmorphic Design
                        VStack(alignment: .leading, spacing: 18) {
                            Text(NSLocalizedString("Add a screenshot", comment: ""))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black.opacity(0.9))
                            
                            Button(action: { showImagePicker = true }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color("igPurple").opacity(0.15),
                                                        Color("igPink").opacity(0.15)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: attachedImages.isEmpty ? "camera.fill" : "checkmark.circle.fill")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(Color("igPink"))
                                    }
                                    
                                    Text(attachedImages.isEmpty ? NSLocalizedString("Choose from library", comment: "") : "\(attachedImages.count) \(NSLocalizedString("Image selected", comment: ""))")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.black.opacity(0.8))
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color("igPink").opacity(0.5))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 18)
                                .background(
                                    ZStack {
                                        // Glassmorphic background
                                        if #available(iOS 15.0, *) {
                                            RoundedRectangle(cornerRadius: 18)
                                                .fill(.ultraThinMaterial)
                                        } else {
                                            RoundedRectangle(cornerRadius: 18)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [
                                                            Color.white.opacity(0.92),
                                                            Color.white.opacity(0.88)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                        }
                                        
                                        // Tinted gradient overlay
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color("igPurple").opacity(0.05),
                                                        Color("igPink").opacity(0.04),
                                                        Color("igOrange").opacity(0.03)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                        
                                        // Elegant border
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color("igPurple").opacity(0.3),
                                                        Color("igPink").opacity(0.3),
                                                        Color("igOrange").opacity(0.2)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                    }
                                    .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 8)
                                    .shadow(color: Color("igPink").opacity(0.08), radius: 25, x: 0, y: 12)
                                )
                            }
                            
                            if !attachedImages.isEmpty {
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ], spacing: 12) {
                                    ForEach(Array(attachedImages.enumerated()), id: \.offset) { index, image in
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 100, height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(
                                                            LinearGradient(
                                                                colors: [
                                                                    Color("igPurple").opacity(0.4),
                                                                    Color("igPink").opacity(0.4)
                                                                ],
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            ),
                                                            lineWidth: 2
                                                        )
                                                )
                                                .shadow(color: Color("igPink").opacity(0.2), radius: 10, x: 0, y: 5)
                                            
                                            Button(action: { 
                                                attachedImages.remove(at: index)
                                            }) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.white)
                                                        .frame(width: 28, height: 28)
                                                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                                                    
                                                    Image(systemName: "xmark")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundColor(Color("igPink"))
                                                }
                                            }
                                            .offset(x: 8, y: -8)
                                        }
                                    }
                                }
                                .padding(.top, 12)
                            }
                        }
                    
                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showMailCompose) {
            MailComposeView(
                toRecipients: ["ucnllc@gmail.com"],
                subject: "[\(feedbackType.rawValue)] InSave Feedback",
                messageBody: createEmailBody(),
                attachedImages: attachedImages
            )
        }
        .sheet(isPresented: $showImagePicker) {
            PHPickerView(images: $attachedImages)
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
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                feedbackType = type
            }
        }) {
            Text(NSLocalizedString(type.rawValue, comment: ""))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(feedbackType == type ? .white : Color("igPink"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    ZStack {
                        if feedbackType == type {
                            // Selected state: Gradient background with shadow
                            Capsule()
                                .fill(instagramGradient)
                                .shadow(color: Color("igPink").opacity(0.4), radius: 12, x: 0, y: 6)
                                .shadow(color: Color("igPurple").opacity(0.3), radius: 8, x: 0, y: 4)
                        } else {
                            // Unselected state: Professional glassmorphic background
                            if #available(iOS 15.0, *) {
                                Capsule()
                                    .fill(.ultraThinMaterial)
                            } else {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.92),
                                                Color.white.opacity(0.88)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            // Tinted overlay for unselected
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color("igPurple").opacity(0.04),
                                            Color("igPink").opacity(0.04)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            // Elegant border for unselected
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color("igPurple").opacity(0.35),
                                            Color("igPink").opacity(0.35),
                                            Color("igOrange").opacity(0.25)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 1.5
                                )
                        }
                    }
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
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - Mail Compose View
struct MailComposeView: UIViewControllerRepresentable {
    let toRecipients: [String]
    let subject: String
    let messageBody: String
    let attachedImages: [UIImage]
    
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
        
        // Add all images as attachments
        for (index, image) in attachedImages.enumerated() {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                vc.addAttachmentData(imageData, mimeType: "image/jpeg", fileName: "screenshot_\(index + 1).jpg")
            }
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

// MARK: - PHPicker View (Multiple Image Selection)
@available(iOS 14.0, *)
struct PHPickerView: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    @Environment(\.presentationMode) var presentationMode
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 10 // Allow up to 10 images
        configuration.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PHPickerView
        
        init(_ parent: PHPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard !results.isEmpty else { return }
            
            var loadedImages: [UIImage] = []
            let dispatchGroup = DispatchGroup()
            
            for result in results {
                dispatchGroup.enter()
                
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                        if let image = object as? UIImage {
                            loadedImages.append(image)
                        }
                        dispatchGroup.leave()
                    }
                } else {
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.parent.images = loadedImages
            }
        }
    }
}
