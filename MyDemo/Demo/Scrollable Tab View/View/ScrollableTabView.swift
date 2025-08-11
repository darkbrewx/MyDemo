//
//  ScrollableTabView.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/11.
//

import SwiftUI

struct ScrollableTabView: View {
    @State private var selectedTab: Tabs?
    @Environment(\.colorScheme) var colorScheme
    @State private var tabProgress: CGFloat = 0
    @State private var scrollPageWidth: CGFloat = .zero
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 15) {
            tabBarHeader
            CustomTabBar()
            ScrollableTabContentView(
                selectedTab: $selectedTab,
                scrollPageWidth: $scrollPageWidth,
                tabProgress: $tabProgress
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.gray.opacity(0.1))
    }

    var tabBarHeader: some View {
        HStack {
            Button(action: {dismiss()}) {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "bell.badge")
            }
        }
        .font(.title2)
        .overlay {
            Text("Message")
                .font(.title3.bold())
        }
        .foregroundStyle(.primary)
        .padding(15)
    }

    @ViewBuilder
    func CustomTabBar() -> some View {
        HStack(spacing: 0) {
            ForEach(Tabs.allCases, id: \.self) { tab in
                HStack(spacing: 10) {
                    Image(systemName: tab.systemImage)
                    Text(tab.rawValue)
                        .font(.callout)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .contentShape(.capsule)
                .onTapGesture {
                    withAnimation(.snappy) {
                        selectedTab = tab
                    }
                }
            }
        }
        .tabMask(progress: tabProgress)
        .background {
            GeometryReader { proxy in
                let size = proxy.size
                let capsuleWidth = size.width / CGFloat(Tabs.allCases.count)
                Capsule()
                    .fill(colorScheme == .dark ? .black : .white)
                    .frame(width: capsuleWidth)
                    // calculating the selected tab Capsule position base on progress
                    .offset(x: tabProgress * (size.width - capsuleWidth))
            }
        }
        .background(.gray.opacity(0.1), in: .capsule)
        .padding(.horizontal, 15)
    }
}

struct ScrollableTabContentView: View {
    @Binding var selectedTab: Tabs?
    @Binding var scrollPageWidth: CGFloat
    @Binding var tabProgress: CGFloat

    var body: some View {
        tabView
    }

    var tabView: some View {
        ScrollView(.horizontal) {
            tabContent
        }
        .scrollPosition(id: $selectedTab)
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        // make scroll view don't clip the content when scrolling out of bounds
//        .scrollClipDisabled()
        .getFrame { frame in
            scrollPageWidth = frame.width
        }
        .onScrollGeometryChange(for: CGPoint.self) { proxy in
            proxy.contentOffset
        } action: { oldValue, newValue in
            Task { @MainActor in
                // This is for guarantee the tabProgress calculation be occured after onGeometryChange
                try? await Task.sleep(for: .seconds(0.001))
                let offsetX = newValue.x
                let progress = offsetX / (scrollPageWidth * CGFloat(( Tabs.allCases.count - 1 )))
                tabProgress = max(0, min(1, progress))
            }
        }
    }

    var tabContent: some View {
        LazyHStack(spacing: 0) {
            contentSample(color: .red)
                // tells contentSample calculating the self size based on the ScrollView width
                .containerRelativeFrame(.horizontal)
                .id(Tabs.chats)
            contentSample(color: .blue)
                .containerRelativeFrame(.horizontal)
                .id(Tabs.calls)
            contentSample(color: .green)
                .containerRelativeFrame(.horizontal)
                .id(Tabs.settings)
        }
        .scrollTargetLayout()
    }

    @ViewBuilder
    func contentSample(color: Color) -> some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: GridItem(), count: 2), spacing: 15) {
                ForEach(0..<10, id: \.self) { index in
                    contentItem(color: color)
                }
            }
            .padding(15)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    func contentItem(color: Color) -> some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(color.gradient)
            .frame(height: 150)
            .overlay {
                VStack(alignment: .leading) {
                    Circle()
                        .fill(.white.opacity(0.25))
                        .frame(width: 50, height: 50)

                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.white.opacity(0.25))
                            .frame(width: 80, height: 8)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.white.opacity(0.25))
                            .frame(width: 60, height: 8)
                    }
                    Spacer()
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white.opacity(0.25))
                        .frame(width: 40, height: 8)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(15)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
    }
}

#Preview {
    ScrollableTabView()
}
