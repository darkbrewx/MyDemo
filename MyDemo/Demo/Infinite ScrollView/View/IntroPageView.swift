//
//  IntroPageView.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/12.
//

import SwiftUI

struct IntroPageView: View {

    // MARK: - properties
    @State private var activeCard: Card? = cards.first
    @State private var scrollPostion: ScrollPosition = .init()
    @State private var currentScrollOffset: CGFloat = .zero
    @State private var timer = Timer.publish(every: 0.01, on: .current, in: .default)
    @State private var initialAnimation: Bool = false
    @State private var titleProgress: CGFloat = .zero
    @State private var scrollPhase: ScrollPhase = .idle

    var body: some View {
        ZStack {
            AmbientBackground()
                .animation(.easeInOut(duration: 1.0), value: activeCard)
            CarouselView()
        }
        .task {
            try? await Task.sleep(for: .seconds(0.35))
            withAnimation(.smooth(duration: 0.75, extraBounce: 0)) {
                initialAnimation = true
            } completion: {
                _ = timer.connect()
            }
            // animate title progress
            withAnimation(.smooth(duration: 2.5, extraBounce: 0).delay(0.3)) {
                titleProgress = 1
            }
        }
        .onDisappear {
            timer.connect().cancel()
        }
    }

    @ViewBuilder
    private func AmbientBackground() -> some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                ForEach(cards) { card in
                    DownsizedImageView(image: UIImage(named: card.imageName), pixelSize: CGSize(width: 500, height: 500)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .ignoresSafeArea()
                            .frame(width: size.width, height: size.height)
                            .opacity(activeCard == card ? 1 : 0)
                    }
                }
                Rectangle()
                    .fill(.black.opacity(0.1))
                    .ignoresSafeArea()
            }
            .compositingGroup()
            .blur(radius: 30, opaque: true)
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func CarouselView() -> some View {
        VStack(spacing: 40) {
            InfiniteScrollView {
                HStack(spacing: 10) {
                    ForEach(cards) { card in
                        carouselCardView(card)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollPosition($scrollPostion)
            // get the scroll view's height * 0.45
            // second parameter is axis
            .containerRelativeFrame(.vertical) { value, _ in
                value * 0.45
            }
            // get the scroll phase
            .onScrollPhaseChange{ oldPhase, newPhase in
                scrollPhase = newPhase
            }
            .onScrollGeometryChange(for: CGFloat.self) { proxy in
                proxy.contentOffset.x + proxy.contentInsets.leading
            } action: { oldValue, newValue in
                currentScrollOffset = newValue
                // update active card only in interacting, idle phase
                if scrollPhase != .decelerating && scrollPhase != .animating {
                    let activeIndex = Int((currentScrollOffset / 220).rounded()) % cards.count
                    activeCard = cards[activeIndex]
                }
            }
            .onReceive(timer) { _ in
                // auto scroll
                currentScrollOffset += 0.35
                scrollPostion.scrollTo(x: currentScrollOffset)
            }
            .visualEffect { [initialAnimation] content, proxy in
                content
                    .offset(y: !initialAnimation ? -(proxy.size.height + 200) : 0)
            }

            welcomeText
            ceateEventButton

        }
        .safeAreaPadding(15)
        .scrollClipDisabled(true)
    }

    @ViewBuilder
    private func carouselCardView(_ card: Card) -> some View {
        GeometryReader { proxy in
            let size = proxy.size
            DownsizedImageView(image: UIImage(named: card.imageName), pixelSize: CGSize(width: 500, height: 500)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(.rect(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.4), radius: 10, x: 1, y: 0)
            }
        }
        .frame(width: 220, height: 350)
        .scrollTransition(.interactive.threshold(.centered), axis: .horizontal) { content, phase in
            content
                .offset(y: phase == .identity ? -10 : 0)
                .rotationEffect(.degrees(phase.value * 5), anchor: .bottom)
        }
    }

    var welcomeText: some View {
        VStack(spacing: 4) {
            Text("Welcome to")
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .blurOpacityEffect(initialAnimation)

            Text("Apple Invites")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .textRenderer(TitleTextRenderer(progress: titleProgress))
                .padding(.bottom, 12)

            Text("Explore the latest features and innovations from Apple. Swipe through our curated selection of cards to discover more.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.secondary)
                .blurOpacityEffect(initialAnimation)
        }
    }

    var ceateEventButton: some View {
        Button {
            // don't forget to cancel the timer
            timer.connect().cancel()
        } label: {
            Text("Create Event")
                .fontWeight(.semibold)
                .foregroundStyle(.black)
                .padding(.horizontal, 25)
                .padding(.vertical, 12)
                .background(.white, in: Capsule())
        }
        .blurOpacityEffect(initialAnimation)
    }
}


struct testView2: View {
    let fileURL2 = URL(string: "https://github.com/onevcat/Flower-Data-Set/raw/master/rose/rose-1.jpg")
    @State var progress: CGFloat = .zero
    var body: some View {
        VStack {
            Text("Apple Invites")
                .font(.largeTitle.bold())
                .foregroundStyle(.black)
                .textRenderer(TitleTextRenderer(progress: progress))
                .padding(.bottom, 12)

            Rectangle()
                .fill(.mainBackground1)
                .frame(width: 100, height: 100)
                .offset(y: 100)
//                .visualEffect { content, proxy in
//                    content
//                        .offset(y: 100)
//                }
                .background(.red)
            Rectangle()
                .fill(.blue)
                .frame(width: 100, height: 100)
        }
        .task {
            withAnimation(.smooth(duration: 2.5, extraBounce: 0).delay(0.3)) {
                progress = 1
            }
        }
    }
}

#Preview {
    IntroPageView()
}


extension View {
    func blurOpacityEffect(_ show: Bool) -> some View {
        self
            .blur(radius: show ? 0 : 2)
            .opacity(show ? 1 : 0)
            .scaleEffect(show ? 1 : 0.9)
    }
}
