//
//  WaterfallGrid.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/06.
//

import SwiftUI

struct WaterfallGridDemo: View {
    private let columns: Int = 2
    private let spacing: CGFloat = 12
    private let horizontalPadding: CGFloat = 10
    @State private var images: [ImageData] = ImageData.mock
    var body: some View {
        ScrollView {
            WaterfallGrid(
                imageDatas: images,
                columns: columns,
                spacing: spacing,
                horizontalPadding: horizontalPadding
            )
            .padding(.horizontal, horizontalPadding)
        }
        .refreshable {
            await refreshaContent()
        }
        .navigationTitle("Photo Gallery")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    shuffleImages()
                } label: {
                    Image(systemName: "shuffle")
                }
            }
        }

    }
    private func refreshaContent() async {
        try? await Task.sleep(for: .seconds(1.5))
        images = ImageData.mock.shuffled()
    }

    private func shuffleImages() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.3)) {
            images.shuffle()
        }
    }
}

struct WaterfallGrid: View {
    let imageDatas: [ImageData]
    let columns: Int
    let spacing: CGFloat
    let horizontalPadding: CGFloat
    @State var selectedImage: ImageData?

    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - horizontalPadding * 2
        let allPadding = spacing * CGFloat(columns - 1)
        let columnWidth = (availableWidth - allPadding) / CGFloat(columns)
        let columnData = distributeImages(columnWidht: columnWidth)

        HStack(alignment: .top, spacing: 10) {
            ForEach(0..<columns, id: \.self) { columnIndex in
                ColumnView(
                    images: columnData[columnIndex],
                    columnIndex: columnIndex,
                    columnWidth: columnWidth,
                    spacing: spacing,
                    selectedImage: $selectedImage
                )
            }
        }
    }

    @ViewBuilder
    func ColumnView(
        images: [ImageData],
        columnIndex: Int,
        columnWidth: CGFloat,
        spacing: CGFloat,
        selectedImage: Binding<ImageData?>
    ) -> some View {
        LazyVStack {
            ForEach(images) { imageItem in
                let height = columnWidth / imageItem.aspectRatio
                AnimatedAsyncImage(
                    imageItem: imageItem,
                    width: columnWidth,
                    height: height
                )
                .id(imageItem.id)
            }
        }
    }

    private func distributeImages(columnWidht: CGFloat) -> [[ImageData]] {
        // create image array for each column
        var columns = Array(repeating: [ImageData](), count: self.columns)
        // create the height of each column
        var columnHeights = Array(repeating: CGFloat(0), count: self.columns)

        for image in imageDatas {
            // calculate the height of the column based on width and aspect ratio
            let imageHeight = columnWidht / image.aspectRatio
            // find the index of the column with the minimum height
            guard
                let minHeightIndex = columnHeights.enumerated().min(by: {
                    $0.element < $1.element
                })?.offset
            else {
                continue
            }
            // distribute the image to the column with the minimum height
            columns[minHeightIndex].append(image)
            // update the height of the column
            columnHeights[minHeightIndex] += imageHeight + spacing
        }

        return columns
    }

}

struct AnimatedAsyncImage: View {
    let imageItem: ImageData
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        AsyncImage(
            url: imageItem.url,
            transaction: Transaction(animation: .easeInOut(duration: 0.2))
        ) { phase in
            switch phase {
            case .empty:
                LoadingShimmerView()
                    .frame(width: width, height: height)
                    .aspectRatio(contentMode: .fit)
            case .success(let image):
                remoteImage(image: image)
            case .failure(_):
                ErrorStateView()
                    .frame(width: width, height: height)
            @unknown default:
                ProgressView()
                    .frame(width: width, height: height)
            }
        }
    }

    @ViewBuilder
    func remoteImage(image: Image) -> some View {
        ZStack {
            image
                .resizable()
                .frame(width: width, height: height)
                .aspectRatio(contentMode: .fit)
                .transition(.scale(scale: 0.5).combined(with: .opacity))
            VStack(alignment: .leading) {
                Spacer()
                HStack {
                    Text(imageItem.caption)
                        .foregroundStyle(.white)
                        .font(.caption)
                        .padding(8)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.8))
                        }
                    Spacer()
                }
            }
            .padding(8)
        }
    }
}

#Preview {
    WaterfallGridDemo()
}
