//
//  RootView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/17/26.
//

import SwiftUI

enum AppScreen {
    case splash
    case login
    case snapyLogin
    case onboarding
    case main
}

struct RootView: View {
    @StateObject private var authVM = AuthViewModel()
    @State private var screen: AppScreen = .splash

    var body: some View {
        ZStack {
            switch screen {
            case .splash:
                SplashView()

            case .login:
                LoginView(onSnapyTap: {
                    screen = .snapyLogin
                })
                .environmentObject(authVM)

            case .snapyLogin:
                SnapyLoginView(title: "SNAPY 로그인", onLoginTap: {
                    screen = .onboarding
                })
                .environmentObject(authVM)

            case .onboarding:
                OnboardingView(onStartTap: {
                    screen = .main
                })

            case .main:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: screen)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                screen = .login
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
