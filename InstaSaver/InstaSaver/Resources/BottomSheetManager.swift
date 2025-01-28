// BottomSheetManager.swift

import SwiftUI

class BottomSheetManager: ObservableObject {
    @Published var showBottomSheet: Bool = false
    var actions: [BottomSheetAction] = [] // Aksiyon dizisini ekledik
}
