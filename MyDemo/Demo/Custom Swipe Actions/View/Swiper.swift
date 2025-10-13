//
//  Swiper.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/10/13.
//

import SwiftUI

struct Swiper<Content: View>: View {
    var cornerRadius: CGFloat = 0
    var direction: SwipeDirection = .trailing
    @ViewBuilder var content: Content
    @ActionBuilder var actions: [SwipeAction]
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - View State
    let viewID = "CONTENTVIEW"
    @State private var isEnabled: Bool = true
    @State private var scrollOffsetX: CGFloat = .zero

    // MARK: - View
    var body: some View {
        ScrollViewReader {scrollProxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    content
                        .rotationEffect(.init(degrees: direction == .leading ? -180 : 0))
                        // to set cotent's frame to match the specified axis of its parent container.
                        .containerRelativeFrame(.horizontal)
                        .background(colorScheme == .dark ? .black : .white)
                        .background {
                            if let firstAction = filteredActions.first {
                                Rectangle()
                                    .fill(firstAction.tint)
                                    .opacity(scrollOffsetX == .zero ? 0 : 1)
                            }
                        }
                        .id(viewID)
                        .transition(.identity)
                        .onGeometryChange(for: CGFloat.self) { proxy in
                            proxy.frame(in: .scrollView(axis: .horizontal)).minX
                        } action: { newValue in
                            scrollOffsetX = newValue
                        }
                        .onAppear {
                            scrollProxy.scrollTo(viewID, anchor: direction == .trailing ? .topTrailing : .topLeading)
                        }

                    actionButton {
                        withAnimation(.snappy) {
                            scrollProxy.scrollTo(viewID, anchor: direction == .trailing ? .topLeading : .topTrailing)
                        }
                    }
                    .opacity(scrollOffsetX == .zero ? 0 : 1)
                }
                .scrollTargetLayout()
                // visualEffect is nonisolated, so we should only use it to do calculation, not to change state.
                .visualEffect { content, geometry in
                    content
                        .offset(x: scrollOffset(geometry))
                }
            }
            .scrollIndicators(.hidden)
            // make the scroll content can be aligned to the leading or trailing edge of the scroll view.
            .scrollTargetBehavior(.viewAligned)
            .background {
                if let lastAction = actions.last {
                    Rectangle()
                        .fill(lastAction.tint)
                        .opacity(scrollOffsetX == .zero ? 0 : 1)
                }
            }
            .clipShape(.rect(cornerRadius: cornerRadius))
            .rotationEffect(.init(degrees: direction == .leading ? 180 : 0))
        }
        .allowsHitTesting(isEnabled)
        .transition(DisappearTransition())
    }

    @ViewBuilder
    func actionButton(resetPosition: @escaping () -> Void) -> some View {
        Rectangle()
            .fill(.clear)
            .frame(width: CGFloat(filteredActions.count) * 100)
            .overlay(alignment: direction.alignment) {
                HStack(spacing: 0) {
                    ForEach(filteredActions) { button in
                        Button {
                            Task {
                                isEnabled = false
                                resetPosition()
                                try? await Task.sleep(for: .seconds(0.25))
                                button.action()
                                try? await Task.sleep(for: .seconds(0.1))
                                isEnabled = true
                            }
                        } label: {
                            Image(systemName: button.icon)
                                .font(button.iconFont)
                                .foregroundStyle(button.iconTint)
                                .frame(width: 100)
                                .frame(maxHeight: .infinity)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .background(button.tint)
                        .rotationEffect(.init(degrees: direction == .leading ? -180 : 0))
                    }
                }
            }
    }

    // MARK: - private method
    nonisolated private func scrollOffset(_ proxy: GeometryProxy) -> CGFloat {
        let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
        return (minX > 0 ? -minX : 0)
    }

    var filteredActions: [SwipeAction] {
        return actions.filter { $0.isEnabled }
    }
}

#Preview {
    CustomSwipeActionDemo()
}
