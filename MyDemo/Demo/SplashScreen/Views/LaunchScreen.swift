//
//  LaunchScreen.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/12/11.
//

import SwiftUI

// How it works:
// 1. Add a new window to the active scene on app launch
// 2. Configure the desired animation in the window
// 3. Destroy the splash window after animation completes

struct LaunchScreen<RootView: View, Logo: View>: Scene {
    var config: LaunchScreenConfig = .init()
    @ViewBuilder var logo: () -> Logo
    @ViewBuilder var rootContent: RootView
    var body: some Scene {
        WindowGroup {
            rootContent
                .launchScreen(config: config, logo: logo)
        }
    }
}

struct LaunchScreenViewDemo<Content: View, Logo: View>: View {
    var config: LaunchScreenConfig = .init()
    @ViewBuilder var logo: () -> Logo
    @ViewBuilder var content: Content
    var body: some View {
        content
            .launchScreen(config: config, logo: logo)
    }
}

fileprivate struct LaunchScreenModifier<Logo: View>: ViewModifier {
    var config: LaunchScreenConfig
    @ViewBuilder var logo: Logo
    @Environment(\.scenePhase) private var scenePhase
    @State private var splashWindow: UIWindow?

    func body(content: Content) -> some View {
        content
            .onAppear{
                setupSplashWindow()
            }
    }

    // Step 1: Find the active scene and add a splash window
    func setupSplashWindow() {
        let scenes = UIApplication.shared.connectedScenes
        for scene in scenes {
            guard let windowScene = scene as? UIWindowScene,
                  checkStates(state: scene.activationState),
                  config.forceShow || !windowScene.windows.contains(where: { $0.tag == 1009 })
            else {
                print("Already have a splash window for this scene")
                continue
            }

            let window = UIWindow(windowScene: windowScene)
            window.backgroundColor = .clear
            window.isHidden = false
            window.isUserInteractionEnabled = true
            // Bridge SwiftUI view to UIKit using UIHostingController
            let rootViewController = UIHostingController(rootView: LaunchScreenView(config: config) {
                logo
            } isCompleted: {
                // Hide splash window after animation completes
                // Note: window will not remain in hierarchy
                window.isHidden = true
                window.isUserInteractionEnabled = false
            })
            // Tag the window to prevent duplicate splash in multi-scene scenarios
            window.tag = 1009
            rootViewController.view.backgroundColor = .clear
            window.rootViewController = rootViewController
            self.splashWindow = window
            print("Splash Window Added")
        }
    }

    // Match scene activation state to find the current active scene
    func checkStates(state: UIWindowScene.ActivationState) -> Bool {
        switch scenePhase {
        case .background: return state == .background
        case .inactive: return state == .foregroundInactive
        case .active: return state == .foregroundActive
        default: return state.hashValue == scenePhase.hashValue
        }
    }
}

fileprivate extension View {
    func launchScreen<Logo: View>(
        config: LaunchScreenConfig,
        @ViewBuilder logo: @escaping () -> Logo
    ) -> some View {
        modifier(LaunchScreenModifier(config: config, logo: logo))
    }
}

struct LaunchScreenConfig {
    // Delay before animation starts (for logo display)
    var initalDelay: Double = 0.35
    // Splash background color
    var backgroundColor: Color = .mainBackground2
    // Logo background color
    var logoBackgroundColor: Color = .white
    // Scale factor for expansion animation
    var scaling: CGFloat = 4
    var forceHideLogo: Bool = false
    // Animation configuration
    var animation: Animation = .smooth(duration: 1, extraBounce: 0)
    // For demo: bypass tag check to show splash every time
    var forceShow: Bool = false
}

fileprivate struct LaunchScreenView<Logo: View>: View {
    var config: LaunchScreenConfig
    @ViewBuilder var logo: Logo
    var isCompleted: () -> ()

    @State private var scaledDown: Bool = false
    @State private var scaledUp: Bool = false

    var body: some View {
        Rectangle()
            .fill(config.backgroundColor)
            // Step 2: Configure animation with mask
            .mask {
                GeometryReader { proxy in
                    Rectangle()
                        .overlay {
                            let size = proxy.size.applying(.init(scaleX: config.scaling, y: config.scaling))
                            logo
                                .blur(radius: config.forceHideLogo ? 0 : (scaledUp ? 15 : 0))
                                .blendMode(.destinationOut)
                                .animation(.smooth(duration: 0.3, extraBounce: 0)) { content in
                                    content
                                        .scaleEffect(scaledDown ? 0.8 : 1)
                                }
                                .visualEffect { [scaledUp] content, proxy in
                                    let scaleX: CGFloat = size.width / proxy.size.width
                                    let scaleY: CGFloat = size.height / proxy.size.height
                                    let maxScale = max(scaleX, scaleY)
                                    return content
                                        .scaleEffect(scaledUp ? maxScale : 1)
                                }
                        }
                }
            }
            .opacity(config.forceHideLogo ? 1 : (scaledUp ? 0 : 1))
            .background {
                Rectangle()
                    .fill(config.logoBackgroundColor)
                    .opacity(scaledUp ? 0 : 1)
            }
            .ignoresSafeArea()
            // Start animation when splash window appears
            .task {
                guard !scaledDown else { return }
                // Phase 1: Scale down slightly to display logo
                try? await Task.sleep(for: .seconds(config.initalDelay))
                scaledDown = true
                // Phase 2: Scale up, fade out, then destroy
                try? await Task.sleep(for: .seconds(0.1))
                withAnimation(config.animation, completionCriteria: .logicallyComplete) {
                    scaledUp = true
                } completion: {
                    // Step 3: Destroy splash window after animation
                    isCompleted()
                }
            }
    }
}

#Preview {
    SplashScreenDemo()
}
