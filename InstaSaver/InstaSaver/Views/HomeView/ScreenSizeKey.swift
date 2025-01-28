//
//  ScreenSizeKey.swift
//  InstaSaver
//
//  Created by Baki Uçan on 6.01.2025.
//

import SwiftUI

struct ScreenSizeKey: EnvironmentKey {
    static let defaultValue: CGSize = UIScreen.main.bounds.size
}

extension EnvironmentValues {
    var screenSize: CGSize {
        get { self[ScreenSizeKey.self] }
        set { self[ScreenSizeKey.self] = newValue }
    }
}
