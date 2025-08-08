//
//  UnExpandedHeaderView.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/07.
//

import SwiftUI

struct UnExpandedHeaderView<Header: View, ExpandedContent: View>: View {
    @ViewBuilder var header: (Binding<Bool>) -> Header
    @ViewBuilder var expandedContent: (Binding<Bool>) -> ExpandedContent

    /// Time sequence of the expansion.
    /// 1. show full screen cover including header
    /// 2. expand the header to show content
    // trigger to expand the header
    @State private var isHeaderExpanded: Bool = false
    // trigger to show full screen cover
    @State private var showFullScreenCover: Bool = false
    // ensure that the header in full screen cover matches the same rect as current header when unexpanded
    @State private var unexpandedHeaderRect: CGRect = .zero
    // add haptic feedback
    @State private var haptics = false
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header($isHeaderExpanded)
                .setSolidBackground(color: .gray, opacity: 0.1)
                .clipShape(.rect(cornerRadius: 10))
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .global)
                } action: { newValue in
                    unexpandedHeaderRect = newValue
                }
                .contentShape(.rect)
                .opacity(showFullScreenCover ? 0 : 1)
                .onTapGesture {
                    // keep the haptic feedback be triggered before show full screen cover, or it will trigger the cover shown animation
                    haptics.toggle()
                    toggleFullScreenCover()
                }
                .fullScreenCover(isPresented: $showFullScreenCover) {
                    // full screen cover with expanded header
                    ExpandedHeaderView(
                        header: header,
                        content: expandedContent,
                        isHeaderExpanded: $isHeaderExpanded,
                        unexpandedHeaderRect: $unexpandedHeaderRect
                    ) {
                        withAnimation(
                            .easeInOut(duration: 0.25),
                            completionCriteria: .removed
                        ) {
                            isHeaderExpanded = false
                        } completion: {
                            toggleFullScreenCover()
                        }
                    }
                }
                .sensoryFeedback(.impact, trigger: haptics)
        }
    }

    // show full screen cover with no animation effect
    private func toggleFullScreenCover() {
        // disable animations when expanding
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            showFullScreenCover.toggle()
        }
    }
}

extension View {
    // solid background with color and opacity, prevent the background Flicker when closing full sheet
    fileprivate func setSolidBackground(color: Color, opacity: CGFloat) -> some View {
        self.background {
            ZStack {
                solidBackground(color: color, opacity: opacity)
            }
        }
    }

    @ViewBuilder
    func solidBackground(color: Color, opacity: CGFloat) -> some View {
        Rectangle()
            .fill(.background)
            .overlay {
                Rectangle()
                    .fill(color.opacity(opacity))
            }
    }
}
