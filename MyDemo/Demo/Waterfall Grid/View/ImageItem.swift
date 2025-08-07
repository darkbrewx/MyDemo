//
//  ImageItem.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/06.
//

import SwiftUI

struct LoadingShimmerView: View {
    @State private var isAnimating = false
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.3))
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.1))
                .mask {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.5), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: isAnimating ? 200 : -200)
                }
        }
        .onAppear {
            withAnimation(
                .linear(duration: 1.5).repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

struct ErrorStateView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.red.opacity(0.3))

            VStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)

                Text("Failed to load image")
                    .font(.caption)
            }
            .foregroundColor(.red)
        }
    }
}

struct FullScreenImageView: View {
    let image: ImageData
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            remoteImageView

            VStack {
                HStack {
                    Spacer()
                    closeButton
                        .padding()
                }
                Spacer()
            }
        }
    }

    var remoteImageView: some View {
        AsyncImage(url: image.url) { phase in
            switch phase {
            case .empty:
                LoadingShimmerView()
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = value
                            }
                    )
            case .failure:
                ErrorStateView()
            @unknown default:
                ErrorStateView()
            }
        }
    }

    var closeButton: some View {

        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .foregroundColor(.white)
                .padding()
                .background(.black.opacity(0.5))
                .clipShape(Circle())
        }
    }
}

#Preview {
    FullScreenImageView(image: ImageData.mock.first!)
}
