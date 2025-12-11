//
//  SplashScreenDemo.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/12/11.
//

import SwiftUI

struct SplashScreenDemo: View {
    @State private var selectedLogo: LogoOption = .playstation
    @State private var refreshID = UUID()

    enum LogoOption: String, CaseIterable {
        case playstation = "PlayStation"
        case xbox = "Xbox"
        case apple = "Apple"

        var image: Image {
            switch self {
            case .playstation: Image(.playstationLogo)
            case .xbox: Image(.xboxLogo)
            case .apple: Image(.appleLogo)
            }
        }
    }

    var body: some View {
        LaunchScreenViewDemo(config: .init(forceShow: true)) {
            selectedLogo.image
        } content: {
            VStack(spacing: 20) {
                Text("Splash Screen Demo")
                    .font(.title2.bold())

                Picker("Logo", selection: $selectedLogo) {
                    ForEach(LogoOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Button("Replay Splash") {
                    refreshID = UUID()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .id(refreshID)
    }
}

#Preview {
    SplashScreenDemo()
}
