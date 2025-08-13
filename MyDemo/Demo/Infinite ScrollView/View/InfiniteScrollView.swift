//
//  InfiniteScrollView.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/14.
//

import SwiftUI

struct InfiniteScrollView<Content: View>: View {
    var spacing: CGFloat = 10
    @ViewBuilder var content: Content
    // view state
    @State private var contentSize: CGSize = .zero
    @State private var scrollContentSize: CGSize = .zero
    @State private var extraContentCount: Int = 0
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: spacing) {
                Group(subviews: content) { collection in
                    // first loop
                    HStack(spacing: 10) {
                        ForEach(collection) { view in
                            view
                        }
                    }
                    .onGeometryChange(for: CGSize.self) { proxy in
                        proxy.size
                    } action: { newValue in
                        // get the scroll content size
                        contentSize = .init(
                            width: newValue.width + spacing,
                            height: newValue.height + spacing
                        )
                        extraContentCount = max(Int((scrollContentSize.width / contentSize.width).rounded()), 1)
                    }

                    // second loop
                    HStack(spacing: spacing) {
                        ForEach(0..<extraContentCount, id: \.self) { index in
                            let view = Array(collection)[
                                index % collection.count
                            ]
                            view
                        }
                    }
                }
            }
            .background(InfiniteScrollHelper(contentSize: $contentSize, decelerationRate: .constant(.fast)))
        }
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .scrollView)
        } action: { oldValue, newValue in
            guard newValue.size != oldValue.size else { return }
            scrollContentSize = newValue.size
        }

    }
}

private struct InfiniteScrollHelper: UIViewRepresentable {
    @Binding var contentSize: CGSize
    @Binding var decelerationRate: UIScrollView.DecelerationRate

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        Task { @MainActor in
            if let scrollView = view.scrollView {
                context.coordinator.defaultDelegate = scrollView.delegate
                scrollView.decelerationRate = decelerationRate
                scrollView.delegate = context.coordinator
            }
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.contentSize = contentSize
        context.coordinator.decelerationRate = decelerationRate
    }
}

extension InfiniteScrollHelper {

    func makeCoordinator() -> Coordinator {
        Coordinator(
            contentSize: contentSize,
            decelerationRate: decelerationRate
        )
    }
    class Coordinator: NSObject, UIScrollViewDelegate {
        var contentSize: CGSize
        var decelerationRate: UIScrollView.DecelerationRate

        init(
            contentSize: CGSize,
            decelerationRate: UIScrollView.DecelerationRate,
        ) {
            self.contentSize = contentSize
            self.decelerationRate = decelerationRate
        }

        weak var defaultDelegate: UIScrollViewDelegate?

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            scrollView.decelerationRate = decelerationRate
            let minX = scrollView.contentOffset.x
            // if the scroll offset is bigger than the content size, we need to reset it to the beginning
            if minX > contentSize.width {
                scrollView.contentOffset.x -= contentSize.width
            }

            // if the scroll offset is smaller than 0, we need to reset it to the end
            if minX < 0 {
                scrollView.contentOffset.x += contentSize.width
            }
            defaultDelegate?.scrollViewDidScroll?(scrollView)
        }

        func scrollViewDidEndDragging(
            _ scrollView: UIScrollView,
            willDecelerate decelerate: Bool
        ) {
            defaultDelegate?.scrollViewDidEndDragging?(
                scrollView,
                willDecelerate: decelerate
            )
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            defaultDelegate?.scrollViewDidEndDecelerating?(scrollView)
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            defaultDelegate?.scrollViewWillBeginDragging?(scrollView)
        }

        func scrollViewWillEndDragging(
            _ scrollView: UIScrollView,
            withVelocity velocity: CGPoint,
            targetContentOffset: UnsafeMutablePointer<CGPoint>
        ) {
            defaultDelegate?.scrollViewWillEndDragging?(
                scrollView,
                withVelocity: velocity,
                targetContentOffset: targetContentOffset
            )
        }
    }
}

extension UIView {
    var scrollView: UIScrollView? {
        if let superview, superview is UIScrollView {
            return superview as? UIScrollView
        }
        return superview?.scrollView
    }
}
