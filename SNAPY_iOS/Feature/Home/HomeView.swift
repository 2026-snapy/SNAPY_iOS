//
//  HomeView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

import SwiftUI

// MARK: - 네비게이션 목적지

enum HomeNavDestination: Hashable, Identifiable {
    case profile(handle: String, name: String, imageUrl: String?)

    var id: String {
        switch self {
        case .profile(let handle, _, _): return "profile_\(handle)"
        }
    }
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    // 프로필 이동
    @State private var profileDestination: HomeNavDestination? = nil
    // 스토리 전체화면 표시용
    @State private var singleStoryItem: StoryItem? = nil
    // Pull-to-refresh
    @State private var isRefreshing = false
    // 알림
    @State private var showNotification = false
    @State private var unreadNotificationCount: Int64 = 0
    // 게시하기
    @State private var showPublish = false
    // 최초 로드 여부
    @State private var hasLoaded = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.backgroundBlack.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 헤더
                        HomeHeader(showNotification: $showNotification, unreadCount: unreadNotificationCount)

                        // Pull-to-refresh 로딩바 (헤더 바로 아래)
                        if isRefreshing {
                            ProgressView()
                                .tint(.white)
                                .padding(.vertical, 12)
                        }

                        // 스토리
                        HomeStoryBar(
                            stories: viewModel.stories,
                            onStorySeen: { storyId in
                                viewModel.markStorySeen(storyId: storyId)
                            }
                        )

                        // 피드
                        if viewModel.feedPosts.isEmpty && viewModel.isLoadingFeed {
                            // 첫 로딩: 스켈레톤 UI
                            FeedSkeletonList()
                        } else {
                            LazyVStack(spacing: 30) {
                                ForEach(viewModel.feedPosts) { post in
                                    HomeFeedCard(
                                        post: post,
                                        onLike: { viewModel.toggleLike(for: post) },
                                        onProfileImageTap: {
                                            handleProfileImageTap(post: post)
                                        },
                                        onNameTap: {
                                            navigateToProfile(post: post)
                                        }
                                    )
                                    .onAppear {
                                        if post.id == viewModel.feedPosts.last?.id {
                                            Task { await viewModel.loadMoreFeed() }
                                        }
                                    }
                                }
                            }

                            // 다음 페이지 로딩
                            if viewModel.isLoadingFeed {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.vertical, 20)
                            }
                        }

                        // 피드 끝 메시지
                        if !viewModel.hasMoreFeed {
                            HomeFeedEndView()
                                .padding(.vertical, 40)
                        }
                    }
                    // 스크롤 위치 감지 → pull-to-refresh
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onChange(of: geo.frame(in: .global).minY) { _, newValue in
                                    if newValue > 140 && !isRefreshing {
                                        triggerRefresh()
                                    }
                                }
                        }
                    )
                }
                // 홈 화면 최초 진입 시 로드
                .onAppear {
                    guard !hasLoaded else { return }
                    hasLoaded = true

                    if UserDefaults.standard.string(forKey: "myHandle") == nil {
                        Task {
                            if let profile = try? await ProfileService.shared.fetchMyProfile() {
                                UserDefaults.standard.set(profile.handle, forKey: "myHandle")
                            }
                        }
                    }
                    if let deviceToken = UserDefaults.standard.string(forKey: "deviceToken") {
                        Task { await PushService.shared.registerToken(deviceToken) }
                    }
                    Task {
                        async let stories: () = viewModel.loadStories()
                        async let feed: () = viewModel.loadFeed()
                        _ = await (stories, feed)
                    }
                    Task {
                        unreadNotificationCount = (try? await NotificationService.shared.getUnreadCount()) ?? 0
                    }
                }
                .onChange(of: showNotification) { _, isShowing in
                    if !isShowing {
                        Task {
                            unreadNotificationCount = (try? await NotificationService.shared.getUnreadCount()) ?? 0
                        }
                    }
                }

                // 게시 버튼
                Button {
                    showPublish = true
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.backgroundBlack)
                        .frame(width: 56, height: 56)
                        .background(Color.white, in: Circle())
                        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
                }
                .padding(.trailing, 14)
                .padding(.bottom, 24)
            }
            // 프로필
            .navigationDestination(item: $profileDestination) { destination in
                if case .profile(let handle, let name, let imageUrl) = destination {
                    FriendProfileView(
                        name: name,
                        handle: handle,
                        profileImageUrl: imageUrl
                    )
                }
            }
            // 게시하기
            .fullScreenCover(isPresented: $showPublish) {
                NavigationStack {
                    PublishPreviewView(homeViewModel: viewModel)
                }
            }
            // 알림 화면
            .fullScreenCover(isPresented: $showNotification) {
                NavigationStack {
                    NotificationView()
                }
            }
            // 피드에서 탭한 유저의 스토리만 표시
            .fullScreenCover(item: $singleStoryItem) { story in
                StoryDetailView(
                    stories: [story],
                    initialIndex: 0,
                    onStorySeen: { storyId in
                        viewModel.markStorySeen(storyId: storyId)
                    }
                )
            }
        }
    }

    // MARK: - Pull-to-refresh

    private func triggerRefresh() {
        isRefreshing = true
        Task {
            async let stories: () = viewModel.loadStories()
            async let feed: () = viewModel.loadFeed()
            async let delay: () = Task.sleep(nanoseconds: 500_000_000)
            _ = try? await (stories, feed, delay)
            isRefreshing = false
        }
    }

    // MARK: - 프로필 사진 탭 (스토리 있으면 스토리, 없으면 프로필)

    private func handleProfileImageTap(post: HomeFeedPost) {
        if let story = viewModel.stories.first(where: { $0.username == post.handle }) {
            singleStoryItem = story
        } else {
            navigateToProfile(post: post)
        }
    }

    // MARK: - 이름 탭 (무조건 프로필)

    private func navigateToProfile(post: HomeFeedPost) {
        let imageUrl = post.profileImage.isEmpty ? nil : post.profileImage
        profileDestination = .profile(handle: post.handle, name: post.displayName, imageUrl: imageUrl)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
