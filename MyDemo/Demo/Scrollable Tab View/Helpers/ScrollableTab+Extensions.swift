//
//  ScrollableTab+Extensions.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/11.
//

import SwiftUI

struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

extension View {

    // create a mask effect
    @ViewBuilder
    func tabMask(progress: CGFloat) -> some View {
        ZStack {
            self
                .foregroundStyle(.gray)
            self
                .symbolVariant(.fill)
                .mask {
                    GeometryReader { proxy in
                        let size = proxy.size
                        let capsuleWidth = size.width / CGFloat(Tabs.allCases.count)
                        Capsule()
                            .frame(width: capsuleWidth)
                            // calculating the selected tab Capsule position base on progress
                            .offset(x: progress * (size.width - capsuleWidth))
                    }
                }
        }
    }

    @ViewBuilder
    func getFrame(completion: @escaping (CGRect) -> Void) -> some View {
        self
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { newValue in
                completion(newValue)
            }
    }

    // Lagacy style for getting the scroll content offset. After iOS 18 we can use onScrollGeometryChange modifier to get scroll context's geometry value.
    @ViewBuilder
    func getOffset(completion: @escaping (CGSize) -> Void) -> some View {
        self
            .overlay {
                GeometryReader { proxy in
                    let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
                    let minY = proxy.frame(in: .scrollView(axis: .horizontal)).minY
                    Color.clear
                        .preference(key: OffsetPreferenceKey.self, value: CGSize(width: minX, height: minY))
                        .onPreferenceChange(OffsetPreferenceKey.self, perform: completion)
                }
            }
    }
}
