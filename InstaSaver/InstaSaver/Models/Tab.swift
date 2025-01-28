//
//  Tab.swift
//  InstaSaver
//
//  Created by Baki Uçan on 6.01.2025.
//

import Foundation

enum Tab: String, CaseIterable {
    case home
    case collections
    case history
    
    var title: String {
        switch self {
        case .home:
            return NSLocalizedString("Home", comment: "TabBar home title")
        case .collections:
            return NSLocalizedString("Collections", comment: "TabBar collections title")
        case .history:
            return NSLocalizedString("History", comment: "TabBar history title")
        }
    }
    
    var icon: String {
        switch self {
        case .home:
            return "house.fill"
        case .collections:
            return "square.grid.2x2.fill"
        case .history:
            return "clock.fill"
        }
    }
} 