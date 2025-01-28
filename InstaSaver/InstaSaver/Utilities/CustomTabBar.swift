// CustomTabBar.swift

import SwiftUI

struct CustomTabBar: View {
    @Binding var currentTab: Tab
    @State private var hoveredTab: Tab?
    
    private let instagramGradient = LinearGradient(
        colors: [
            Color("igPurple"),
            Color("igPink"),
            Color("igOrange")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        HStack(spacing: 35) {
            ForEach(Tab.allCases, id: \.self) { tab in
                TabButton(
                    tab: tab,
                    currentTab: $currentTab,
                    hoveredTab: $hoveredTab,
                    gradient: instagramGradient
                )
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 15)
    }
}

struct TabButton: View {
    let tab: Tab
    @Binding var currentTab: Tab
    @Binding var hoveredTab: Tab?
    let gradient: LinearGradient
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                currentTab = tab
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    // Floating effect shadow for inactive state
                    if currentTab != tab {
                        Circle()
                            .fill(.white)
                            .frame(width: 50, height: 50)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    // Active state with gradient and enhanced shadow
                    if currentTab == tab {
                        Circle()
                            .fill(gradient)
                            .frame(width: 50, height: 50)
                            .shadow(color: Color("igPink").opacity(0.3), radius: 10, x: 0, y: 5)
                            .shadow(color: Color("igPurple").opacity(0.2), radius: 4, x: 0, y: 2)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .matchedGeometryEffect(id: "TAB", in: namespace)
                    }
                    
                    Image(systemName: tab.icon)
                        .font(.system(size: 22, weight: currentTab == tab ? .semibold : .medium))
                        .foregroundColor(currentTab == tab ? .white : Color(.systemGray))
                }
                .offset(y: hoveredTab == tab ? -5 : 0)
                
                Text(tab.title)
                    .font(.system(size: 12, weight: currentTab == tab ? .medium : .regular))
                    .foregroundColor(currentTab == tab ? Color("igPink") : Color(.systemGray))
                    .opacity(hoveredTab == tab ? 0.5 : 1.0)
            }
            .contentShape(Rectangle())
            .scaleEffect(hoveredTab == tab ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hoveredTab)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                hoveredTab = isHovered ? tab : nil
            }
        }
    }
    
    @Namespace private var namespace
}
