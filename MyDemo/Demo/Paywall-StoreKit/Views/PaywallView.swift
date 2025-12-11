//
//  PaywallView.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/12/11.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @State private var isLoaded: Bool = false
    @State private var titleProgress: CGFloat = 0

    static var productIDs = ["pro_weekly", "pro_yearly", "pro_monthly"]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let isSmalleriPhone = size.height < 700

            VStack(spacing: 0) {
                // Subscription UI with custom marketing content
                subscriptionsView(isSmalleriPhone)
                termAndPolicyView
                    .padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(isLoaded ? 1 : 0)
            .background(backdropView)
            .overlay {
                if !isLoaded {
                    ProgressView()
                        .font(.largeTitle)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: isLoaded)
            // Load products and trigger title animation on success
            .storeProductsTask(for: Self.productIDs) { @MainActor collection in
                if let products = collection.products, products.count > 0 {
                    try? await Task.sleep(for: .seconds(0.1))
                    isLoaded = true
                    withAnimation(.easeInOut(duration: 3.0)) {
                        titleProgress = 1
                    }
                }
            }
            .colorScheme(.dark)
            .tint(.white)
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }

    func subscriptionsView(_ isSmalleriPhone: Bool) -> some View {
        // SubscriptionStoreView provides subscription UI and logic
        // customMarketingView is the developer-provided marketing content
        Group {
            if isSmalleriPhone {
                SubscriptionStoreView(productIDs: Self.productIDs) {
                    customMarketingView
                }
                .subscriptionStoreControlStyle(.compactPicker, placement: .bottomBar)
            } else {
                SubscriptionStoreView(productIDs: Self.productIDs) {
                    customMarketingView
                }
                .subscriptionStoreControlStyle(.pagedProminentPicker, placement: .bottomBar)
            }
        }
        .subscriptionStorePickerItemBackground(.ultraThinMaterial)
        // setup resotre button
        .storeButton(.visible, for: .restorePurchases)
        // handle purchase start
        .onInAppPurchaseStart { product in
            print("Show Loading Screen")
            print("Purchasing \(product.displayName)")
        }
        // handle the purchase result
        .onInAppPurchaseCompletion { product, result in
            switch result {
            case .success(let result):
                switch result {
                case .success(_): print("Success and verifying purchase...")
                case .userCancelled: print("User Cancelled")
                case .pending: print("Pending Action")
                @unknown default:
                    fatalError()
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
            print("Hide Loading Screen")
        }
        .subscriptionStatusTask(for: "E7EFC468") { status in
            if let result = status.value {
                let premiumUser = !result.filter { subsState in
                    subsState.state == .subscribed
                }.isEmpty
                print("User Subscribed = \(premiumUser)")
            }
        }
    }

    var termAndPolicyView: some View {
        HStack(spacing: 3) {
            Link("Terms of Services", destination: URL(string: "https://apple.com")!)
            Text("And")
            Link("Privacy Policy", destination: URL(string: "https://apple.com")!)
        }
        .font(.caption2)
    }

    var backdropView: some View {
        GeometryReader { proxy in
            let size = proxy.size

            Image(.miniSkytree)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .scaleEffect(1.3)
                .blur(radius: 40, opaque: true)
                .overlay {
                    Rectangle()
                        .fill(.black.opacity(0.2))
                }
                .ignoresSafeArea()
        }
    }

    var customMarketingView: some View {
        VStack(spacing: 15) {
            HStack(spacing: 25) {
                ScreenshotView(content: [.iPhone1, .iPhone4, .iPhone9], offset: -200)
                ScreenshotView(content: [.iPhone8, .iPhone10, .iPhone3], offset: -350)
                ScreenshotView(content: [.iPhone6, .iPhone2, .iPhone5], offset: -250)
                    .overlay(alignment: .trailing) {
                        ScreenshotView(content: [.iPhone9, .iPhone3, .iPhone7], offset: -150)
                            .visualEffect { content, proxy in
                                content
                                    .offset(x: proxy.size.width + 25)
                            }
                    }
            }
            .frame(maxHeight: .infinity)
            .offset(x: 20)
            .mask {
                LinearGradient(colors: [
                    .white,
                    .white.opacity(0.9),
                    .white.opacity(0.7),
                    .white.opacity(0.4),
                    .clear
                ], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .padding(.bottom, -40)
            }

            VStack(spacing: 6) {
                Text("App")
                    .font(.title3)

                Text("Membership")
                    .font(.largeTitle.bold())
                    // Custom text renderer for gradient animation
                    .textRenderer(TitleTextRenderer(progress: titleProgress))

                Text("Unlimited Access To Our App Features")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.white)
            .padding(.top, 15)
            .padding(.bottom, 10)
            .padding(.horizontal, 15)
        }
    }
}

#Preview {
    PaywallView()
}
