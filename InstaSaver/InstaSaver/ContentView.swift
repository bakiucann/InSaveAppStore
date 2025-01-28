//
//  ContentView.swift
//  InstaSaver
//
//  Created by Baki Uçan on 5.01.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject var bottomSheetManager = BottomSheetManager()
    var body: some View {
        TabBarView()
            .environmentObject(bottomSheetManager)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
