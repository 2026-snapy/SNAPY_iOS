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
    @State private var deepLinkAlbumHandle: String?
    @State private var deepLinkStoryId: Int?
    @State private var deepLinkProfileHandle: String?
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
            case .album(let id, let handle):
                selectedTab = 0
                deepLinkAlbumId = id
                deepLinkAlbumHandle = handle
            case .story(let id):
                selectedTab = 0
                deepLinkStoryId = id
            case .profile(let handle):
                let myHandle = UserDefaults.standard.string(forKey: "myHandle") ?? ""
                if handle == myHandle {
                    selectedTab = 4  // 내 프로필 탭으로 이동
                } else {
                    deepLinkProfileHandle = handle
                }
            }
            deepLinkRouter.clearDestination()
        }
        // 앨범 딥링크
        .fullScreenCover(item: Binding(
            get: { deepLinkAlbumId.map { DeepLinkItem(id: $0) } },
            set: { deepLinkAlbumId = $0?.id; if $0 == nil { deepLinkAlbumHandle = nil } }
        )) { item in
            DeepLinkAlbumView(albumId: item.id, handle: deepLinkAlbumHandle)
        }
        // 스토리 딥링크
        .fullScreenCover(item: Binding(
            get: { deepLinkStoryId.map { DeepLinkItem(id: $0) } },
            set: { deepLinkStoryId = $0?.id }
        )) { item in
            DeepLinkStoryView(storyId: item.id)
        }
        // 프로필 딥링크
        .fullScreenCover(item: Binding(
            get: { deepLinkProfileHandle.map { DeepLinkStringItem(value: $0) } },
            set: { deepLinkProfileHandle = $0?.value }
        )) { item in
            DeepLinkProfileView(handle: item.value, onDismiss: { deepLinkProfileHandle = nil })
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

// MARK: - 딥링크 아이템

struct DeepLinkItem: Identifiable {
    let id: Int
}

struct DeepLinkStringItem: Identifiable {
    let value: String
    var id: String { value }
}

// MARK: - 딥링크 앨범 뷰

struct DeepLinkAlbumView: View {
    let albumId: Int
    let handle: String?
    @Environment(\.dismiss) private var dismiss
    @State private var albumData: DailyAlbumData?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isLiked = false
    @State private var likeCount = 0
    @State private var commentCount = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("불러오는 중...")
                        .foregroundColor(.customGray300)
                }
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.customGray300)
                    Text(error)
                        .foregroundColor(.customGray300)
                    Button("닫기") { dismiss() }
                        .foregroundColor(.white)
                        .padding(.top, 12)
                }
            } else if let album = albumData {
                ZStack(alignment: .topLeading) {
                    ScrollView {
                        VStack(spacing: 0) {
                            Spacer().frame(height: 56)

                            FeedCardView(
                                albumId: album.albumId,
                                profileImageSource: .asset("Profile_img"),
                                displayName: "",
                                handle: handle ?? "",
                                date: album.albumDate,
                                photos: album.photos.map { photo in
                                    FeedCardPhoto(
                                        frontImageUrl: photo.frontImageUrl,
                                        backImageUrl: photo.backImageUrl,
                                        assetName: nil
                                    )
                                },
                                isLiked: $isLiked,
                                likeCount: $likeCount,
                                commentCount: $commentCount
                            )
                        }
                    }

                    // 뒤로가기 버튼
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color.primary)
                            .padding(2)
                    }
                    .buttonStyle(.glass)
                    .padding(.leading, 16)
                    .padding(.top, 12)
                }
            }
        }
        .task {
            do {
                let data = try await AlbumService.shared.fetchAlbumAsDaily(albumId: albumId)
                isLiked = data.liked ?? false
                likeCount = data.likeCount ?? 0
                albumData = data
            } catch {
                errorMessage = "앨범을 불러올 수 없습니다."
            }
            isLoading = false
        }
    }
}

// MARK: - 딥링크 프로필 뷰

struct DeepLinkProfileView: View {
    let handle: String
    let onDismiss: () -> Void

    var body: some View {
        let myHandle = UserDefaults.standard.string(forKey: "myHandle") ?? ""
        let isMyProfile = handle == myHandle

        ZStack {
            Color.black.ignoresSafeArea()

            if isMyProfile {
                // 내 프로필 → ProfileView로
                NavigationStack {
                    ProfileView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button { onDismiss() } label: {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                }
            } else {
                // 친구 프로필
                NavigationStack {
                    FriendProfileView(name: "", handle: handle, profileImageUrl: nil)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button { onDismiss() } label: {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                }
            }
        }
    }
}

// MARK: - 딥링크 스토리 뷰

struct DeepLinkStoryView: View {
    let storyId: Int
    @Environment(\.dismiss) private var dismiss
    @State private var storyItem: StoryItem?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("스토리를 불러오는 중...")
                        .foregroundColor(.customGray300)
                }
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.customGray300)
                    Text(error)
                        .foregroundColor(.customGray300)
                    Button("닫기") { dismiss() }
                        .foregroundColor(.white)
                        .padding(.top, 12)
                }
            } else if let story = storyItem {
                StoryDetailView(
                    stories: [story],
                    initialIndex: 0,
                    onStorySeen: nil
                )
            }
        }
        .task {
            await loadStory()
        }
    }

    private func loadStory() async {
        do {
            let detail = try await StoryService.shared.fetchDetail(storyId: storyId)
            let photos = detail.photos.map { photo -> StoryPhotoSet in
                var p = photo
                p.ownerStoryId = detail.storyId
                return p
            }
            storyItem = StoryItem(
                storyId: detail.storyId,
                profileImage: detail.profileImageUrl ?? "",
                bannerImage: "",
                displayName: detail.username,
                username: detail.handle,
                photos: photos,
                createdAt: detail.createdAt,
                isSeen: true
            )
        } catch {
            errorMessage = "스토리를 불러올 수 없습니다."
        }
        isLoading = false
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
