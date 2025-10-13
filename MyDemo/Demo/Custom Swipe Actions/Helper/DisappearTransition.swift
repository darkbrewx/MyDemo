//
//  DisappearTransition.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/10/14.
//

import SwiftUI

struct DisappearTransition: Transition {
    // phase: willAppear .identity, .didDisappear
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .mask {
                GeometryReader { proxy in
                    let size = proxy.size
                    Rectangle()
                        .offset(y: phase == .identity ? 0 : -size.height)
                }
                .containerRelativeFrame(.horizontal)
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

struct offsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
