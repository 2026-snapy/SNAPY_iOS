//
//  SNAPY_iOSApp.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/17/26.
//

import SwiftUI
import GoogleSignIn

@main
struct SNAPY_iOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // URLCache 크기 확대 → AsyncImage 이미지 캐싱 성능 개선
        URLCache.shared = URLCache(
            memoryCapacity: 50 * 1024 * 1024,   // 50MB 메모리
            diskCapacity: 200 * 1024 * 1024,     // 200MB 디스크
            diskPath: "image_cache"
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .environmentObject(DeepLinkRouter.shared)
                .onOpenURL { url in
                    // Google Sign-In 처리
                    if GIDSignIn.sharedInstance.handle(url) { return }
                    // Universal Links / 딥링크 처리
                    DeepLinkRouter.shared.handleURL(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    // Universal Links (Safari에서 앱으로 전환)
                    if let url = activity.webpageURL {
                        DeepLinkRouter.shared.handleURL(url)
                    }
                }
        }
    }
}
