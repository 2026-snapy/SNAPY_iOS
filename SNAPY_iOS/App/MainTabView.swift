//
//  MainTabView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/17/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var showCamera: Bool = false
    @State private var toastMessage: String?
    @State private var deepLinkAlbumId: Int?
    @StateObject private var cameraVM = CameraViewModel()
    @ObservedObject private var photoStore = PhotoStore.shared
    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image("Home_icon")
                        .renderingMode(.template)
                    Text("홈")
                }
                .tag(0)

            FriendView()
                .tabItem {
                    Image("Friend_icon")
                        .renderingMode(.template)
                    Text("친구")
                }
                .tag(1)

            // 카메라 호출
            Color.clear
                .tabItem {
                    Image("Camera_icon")
                }
                .tag(2)

            NavigationStack {
                AlbumView(onOpenCamera: { tryOpenCamera() })
            }
            .tabItem {
                Image("Album_icon")
                    .renderingMode(.template)
                Text("앨범")
            }
            .tag(3)

            ProfileView()
                .tabItem {
                    Image("Profile_icon")
                        .renderingMode(.template)
                    Text("프로필")
                }
                .tag(4)
        }
        .tint(.white)
        .overlay(alignment: .bottom) {
            if let message = toastMessage {
                toastView(message: message)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 100)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: toastMessage)
        .onChange(of: selectedTab) {
            if selectedTab == 2 {
                tryOpenCamera()
                selectedTab = 0
            }
        }
        .fullScreenCover(isPresented: $showCamera, onDismiss: {
            cameraVM.resetCamera()
        }) {
            CameraView()
                .environmentObject(cameraVM)
        }
        .onChange(of: cameraVM.shouldDismiss) {
            if cameraVM.shouldDismiss {
                showCamera = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openCamera)) { _ in
            tryOpenCamera()
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToProfileTab)) { _ in
            selectedTab = 4
        }
        .onChange(of: deepLinkRouter.pendingDestination) { _, destination in
            guard let destination else { return }
            switch destination {
            case .album(let id):
                selectedTab = 0  // 홈 탭으로 이동
                deepLinkAlbumId = id
            case .story(let id):
                selectedTab = 0
                deepLinkAlbumId = id
            case .profile:
                selectedTab = 4  // 프로필 탭
            }
            deepLinkRouter.clearDestination()
        }
        .sheet(item: Binding(
            get: { deepLinkAlbumId.map { DeepLinkAlbumItem(id: $0) } },
            set: { deepLinkAlbumId = $0?.id }
        )) { item in
            NavigationStack {
                DeepLinkAlbumView(albumId: item.id)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private func tryOpenCamera() {
        Task {
            // 최신 todayAlbum을 서버에서 가져온 뒤 슬롯 체크
            await photoStore.loadToday()
            if let message = photoStore.cannotTakePhotoMessage() {
                showToast(message)
            } else {
                showCamera = true
            }
        }
    }

    private func showToast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            toastMessage = nil
        }
    }

    @ViewBuilder
    private func toastView(message: String) -> some View {
        Text(message)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 딥링크 앨범 아이템

struct DeepLinkAlbumItem: Identifiable {
    let id: Int
}

// MARK: - 딥링크 앨범 뷰

struct DeepLinkAlbumView: View {
    let albumId: Int
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("앨범을 불러오는 중...")
                        .foregroundColor(.customGray300)
                }
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.customGray300)
                    Text(error)
                        .foregroundColor(.customGray300)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundColor(.customGray300)
                    Text("앨범 #\(albumId)")
                        .font(.title3.bold())
                    Text("앨범 상세 화면")
                        .foregroundColor(.customGray300)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .navigationTitle("공유된 앨범")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("닫기") { dismiss() }
                    .foregroundColor(.white)
            }
        }
        .task {
            // TODO: 앨범 상세 API 호출하여 실제 데이터 로드
            try? await Task.sleep(for: .seconds(0.5))
            isLoading = false
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
