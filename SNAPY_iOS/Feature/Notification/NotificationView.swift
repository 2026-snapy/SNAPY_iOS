//
//  NotificationView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/7/26.
//

import SwiftUI

struct NotificationView: View {
    @StateObject private var viewModel = NotificationViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showOlderSection = false

    @State private var navProfileHandle: String? = nil
    @State private var navProfileName: String = ""
    @State private var navProfileImage: String? = nil
    @State private var showFriendRequest = false

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                Divider().background(Color.white.opacity(0.1))

                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    Spacer(); ProgressView().tint(Color.textWhite); Spacer()
                } else if viewModel.notifications.isEmpty {
                    Spacer()
                    Text("알림이 없습니다").font(.system(size: 20)).foregroundColor(Color.customGray300)
                    Spacer()
                } else {
                    notificationList
                }
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { navProfileHandle != nil },
            set: { if !$0 { navProfileHandle = nil } }
        )) {
            if let handle = navProfileHandle {
                FriendProfileView(name: navProfileName, handle: handle, profileImageUrl: navProfileImage)
            }
        }
        .navigationDestination(isPresented: $showFriendRequest) { FriendRequestView() }
        .navigationDestination(isPresented: $viewModel.showFeedDetail) {
            if let post = viewModel.feedPost {
                FeedDetailView(
                    posts: [post], initialPostId: post.id,
                    displayName: viewModel.feedName, handle: viewModel.feedHandle,
                    profileImage: nil, profileImageUrl: viewModel.feedProfileUrl, profileAsset: "Profile_img"
                )
            }
        }
        .fullScreenCover(item: $viewModel.storyToShow) { story in
            StoryDetailView(stories: [story], initialIndex: 0)
        }
        .alert("알림", isPresented: $viewModel.showExpiredAlert) {
            Button("확인", role: .cancel) {}
        } message: { Text(viewModel.expiredAlertMessage) }
        .toolbar(.hidden, for: .navigationBar)
        .gesture(DragGesture().onEnded { v in
            if v.translation.width > 80 && abs(v.translation.height) < 100 { dismiss() }
        })
        .task {
            await viewModel.loadNotifications()
            await viewModel.markAllAsRead()
        }
    }

    // MARK: - 헤더

    private var headerBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.textWhite)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            Spacer()
            Text("알림").font(.system(size: 18, weight: .bold)).foregroundColor(Color.textWhite)
            Spacer()
            Button { showFriendRequest = true } label: {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.textWhite)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - 목록

    private var notificationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.groupedNotifications(), id: \.title) { section in
                    if section.isOlder {
                        olderSection(section)
                    } else {
                        recentSection(section)
                    }
                }
                if viewModel.isLoading {
                    ProgressView().tint(Color.textWhite).padding(.vertical, 20)
                }
            }
        }
    }

    @ViewBuilder
    private func recentSection(_ section: NotificationViewModel.NotificationSection) -> some View {
        sectionHeader(section.title)
        ForEach(section.items) { n in notificationRow(n) }
    }

    @ViewBuilder
    private func olderSection(_ section: NotificationViewModel.NotificationSection) -> some View {
        if !showOlderSection {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) { showOlderSection = true }
            } label: {
                HStack {
                    Text("이전 알림 더보기").font(.system(size: 14, weight: .semibold)).foregroundColor(Color.customGray300)
                    Image(systemName: "chevron.down").font(.system(size: 12, weight: .semibold)).foregroundColor(Color.customGray300)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 16)
            }
        }
        if showOlderSection {
            sectionHeader(section.title)
            ForEach(section.items) { n in notificationRow(n) }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title).font(.system(size: 14, weight: .bold)).foregroundColor(Color.textWhite)
            Spacer()
        }
        .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 8)
    }

    @ViewBuilder
    private func notificationRow(_ notification: NotificationData) -> some View {
        NotificationRow(
            notification: notification,
            message: viewModel.message(for: notification),
            onProfileTap: {
                guard let handle = notification.senderHandle else { return }
                navProfileName = notification.senderUsername ?? ""
                navProfileImage = notification.senderProfileImageUrl
                navProfileHandle = handle
            },
            onContentTap: {
                if notification.type == .friendRequest {
                    showFriendRequest = true
                } else if notification.type == .friendAccepted {
                    guard let handle = notification.senderHandle else { return }
                    navProfileName = notification.senderUsername ?? ""
                    navProfileImage = notification.senderProfileImageUrl
                    navProfileHandle = handle
                } else {
                    viewModel.handleContentTap(notification, dismiss: dismiss)
                }
            }
        )
        .onAppear {
            if notification.id == viewModel.notifications.last?.id {
                Task { await viewModel.loadMore() }
            }
        }

        Divider().background(Color.white.opacity(0.06))
    }
}

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View { NotificationView() }
}
