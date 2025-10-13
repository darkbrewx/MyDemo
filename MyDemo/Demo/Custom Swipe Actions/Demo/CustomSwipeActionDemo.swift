//
//  CustomSwipeActionDemo.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/10/13.
//

import SwiftUI

struct CustomSwipeActionDemo: View {
    @State private var colors:  [Color] = [.redMuted, .greenMuted, .blueMuted, .orangeMuted, .purpleMuted, .aquaMuted, .yellowMuted, .grayMuted]
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                LazyVStack(spacing: 10) {
                    ForEach(colors, id: \.self) { color in
                        Swiper(cornerRadius: 15, direction: .trailing) {
                            contentCardView(color: color)
                        } actions: {
                            SwipeAction(tint: .blue, icon: "star.fill") {
                                print("Bookmarked")
                            }
                            SwipeAction(tint: .red, icon: "trash.fill") {
                                withAnimation(.easeInOut) {
                                    colors.removeAll(where: { $0 == color } )
                                }
                            }
                        }
                    }
                }
                .padding(15)
            }
            .scrollIndicators(.hidden)
                .navigationTitle("Message")
        }
    }

    @ViewBuilder
        func contentCardView(color: Color) -> some View {
            HStack(spacing: 12) {
                Circle()
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 5)
                        .frame(width: 80, height: 5)
                    RoundedRectangle(cornerRadius: 5)
                        .frame(width: 60, height: 5)
                }

                Spacer(minLength: 0)
            }
            .foregroundStyle(.white.opacity(0.4))
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background(color.gradient)
        }
}

#Preview {
    CustomSwipeActionDemo()
}
