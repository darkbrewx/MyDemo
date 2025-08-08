//
//  ExpandedHeaderView.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/11.
//

import SwiftUI

struct ExpandedHeaderView<Header: View, Content: View>: View {
    @ViewBuilder var header: (Binding<Bool>) -> Header
    @ViewBuilder var content: (Binding<Bool>) -> Content

    @State private var dragHScaleState: CGFloat = 1.0
    @Binding var isHeaderExpanded: Bool
    @Binding var unexpandedHeaderRect: CGRect
    // dismiss view callback
    var dissmissView: () -> Void

    // constant for drag gesture
    private let dragRatio: CGFloat = 0.1

    var body: some View {
        expandedView
            .frame(maxWidth: isHeaderExpanded ? .infinity : nil)
            .padding(isHeaderExpanded ? 15 : 0)
            .setCoverSolidBackground(color: .gray, opacity: 0.1, isExpanded: isHeaderExpanded)
            .clipShape(.rect(cornerRadius: isHeaderExpanded ? 20 : 10))
            .dragEffect(dragHScaleState: $dragHScaleState, dragRatio: dragRatio)
            .syncRect(
                unexpandedHeaderRect: unexpandedHeaderRect,
                isHeaderExpanded: $isHeaderExpanded
            )
            .ignoresSafeArea()
            .presentationBackground {
                coverBackground
                    .headerDragGesture(
                        dragHScaleState: $dragHScaleState,
                        dragRatio: dragRatio,
                        dissmissView: dissmissView
                    )
            }
            .onAppear {
                Task { @MainActor in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isHeaderExpanded = true
                    }
                }
            }
            .headerDragGesture(
                dragHScaleState: $dragHScaleState,
                dragRatio: dragRatio,
                dissmissView: dissmissView
            )
    }

    var expandedView: some View {
        VStack(alignment: .leading, spacing: 15) {
            headerPart
            if isHeaderExpanded {
                content($isHeaderExpanded)
                    .transition(.blurReplace)
            }
        }
    }

    var headerPart: some View {
        HStack(spacing: 0) {
            closeButton
            header($isHeaderExpanded)
        }
    }

    var closeButton: some View {
        Button(action: { dissmissView() }) {
            Image(systemName: "xmark")
                .foregroundStyle(Color.primary)
                .contentShape(.rect)
        }
        .opacity(isHeaderExpanded ? 1 : 0)
        .frame(maxWidth: isHeaderExpanded ? nil : 0)
        .offset(x: isHeaderExpanded ? 0 : 10)
        .padding(.trailing, isHeaderExpanded ? 10 : 0)
    }

    var coverBackground: some View {
        Rectangle()
            .fill(.black.opacity(isHeaderExpanded ? 0.5 : 0))
            .onTapGesture {
                dissmissView()
            }
    }
}

extension View {
    /// Sync the position and size of the header view
    fileprivate func syncRect(
        unexpandedHeaderRect: CGRect,
        isHeaderExpanded: Binding<Bool>
    ) -> some View {
        self
            .modifier(
                SyncRect(
                    unexpandedHeaderRect: unexpandedHeaderRect,
                    isHeaderExpanded: isHeaderExpanded
                )
            )
    }

    /// Customized drag effect
    fileprivate func dragEffect(
        dragHScaleState: Binding<CGFloat>,
        dragRatio: CGFloat
    ) -> some View {
        self.modifier(
            DragEffect(dragHScaleState: dragHScaleState, dragRatio: dragRatio)
        )
    }

    /// Handle header drag gesture
    fileprivate func headerDragGesture(
        dragHScaleState: Binding<CGFloat>,
        dragRatio: CGFloat,
        dissmissView: @escaping () -> Void
    ) -> some View {
        self.modifier(
            HeaderDragGesture(
                dragHScaleState: dragHScaleState,
                dragRatio: dragRatio,
                dissmissView: dissmissView
            )
        )
    }

    fileprivate func setCoverSolidBackground(color: Color, opacity: CGFloat, isExpanded: Bool)
        -> some View
    {
        self.background {
            ZStack {
                solidBackground(color: color, opacity: opacity)
                Rectangle()
                    .fill(.background)
                    .opacity(isExpanded ? 1 : 0)
            }
        }
    }
}

private struct SyncRect: ViewModifier {
    let unexpandedHeaderRect: CGRect
    let isHeaderExpanded: Binding<Bool>
    var isExpanded: Bool {
        isHeaderExpanded.wrappedValue
    }

    func body(content: Content) -> some View {
        content
            .frame(
                width: isExpanded ? nil : unexpandedHeaderRect.width,
                height: isExpanded ? nil : unexpandedHeaderRect.height
            )
            // Reset view position to top-leading alignment
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
            // sync the position with unexpanded header rect
            .offset(
                x: isExpanded ? 0 : unexpandedHeaderRect.minX,
                y: isExpanded
                    ? unexpandedHeaderRect.minY : unexpandedHeaderRect.minY
            )
            // Horizontal padding
            .padding(.horizontal, isExpanded ? 15 : 0)
    }
}


private struct DragEffect: ViewModifier {
    @Binding var dragHScaleState: CGFloat
    let dragRatio: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(dragHScaleState, anchor: .top)
            .rotation3DEffect(
                .degrees(CGFloat((dragHScaleState - 1) * 50)),
                axis: (x: 1, y: 0, z: 0)
            )
            .offset(y: (dragHScaleState - 1)  * 10)
    }
}

private struct HeaderDragGesture: ViewModifier {
    @Binding var dragHScaleState: CGFloat
    let dragRatio: CGFloat
    // dismiss view callback
    var dissmissView: () -> Void

    func body(content: Content) -> some View {
        content
            // Use .simultaneousGesture(...) to avoid conflict with the button’s tap action.
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let dragHeight = value.translation.height
                        let dragHScale =
                            dragHeight / UIScreen.main.bounds.height
                        dragHScaleState = 1.0 + (dragHScale * dragRatio)
                    }
                    .onEnded { value in
                        // points per second
                        let dragHVelocity = value.velocity.height / 5
                        let dragHeight = value.translation.height
                        withAnimation(.easeInOut(duration: 0.25)) {
                            dragHScaleState = 1.0
                        }
                        // conditions to dismiss the view
                        if -dragHVelocity > 500
                            || -dragHeight > UIScreen.main.bounds.height / 5
                        {
                            dissmissView()
                        }
                    }
            )
    }
}

