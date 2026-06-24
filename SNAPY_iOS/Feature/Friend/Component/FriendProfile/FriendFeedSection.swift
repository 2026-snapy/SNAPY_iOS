//
//  FriendFeedSection.swift
//  SNAPY_iOS
//
//  친구 프로필 피드 섹션 (이번 달 + 과거 달 펼치기)
//  ProfileFeedSection과 동일한 UX
//

import SwiftUI
import Kingfisher

struct FriendFeedSection: View {
    @ObservedObject var viewModel: FriendProfileViewModel

    @State private var expandedMonths: Set<Int> = []
    @State private var monthPosts: [Int: [FeedPost]] = [:]
    @State private var loadingMonths: Set<Int> = []

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            // 이번 달 피드
            ForEach(viewModel.feedPosts) { post in
                NavigationLink(destination: FeedDetailView(
                    posts: viewModel.feedPosts,
                    initialPostId: post.id,
                    displayName: viewModel.name,
                    handle: viewModel.handle,
                    profileImage: nil,
                    profileImageUrl: viewModel.profileImageUrl,
                    profileAsset: "Profile_img"
                )) {
                    feedThumbnail(post.thumbnailImage, likeCount: post.likeCount)
                }
            }

            // 과거 달 카드
            ForEach(viewModel.pastMonths) { summary in
                Button {
                    toggleMonth(summary)
                } label: {
                    PastMonthCard(summary: summary)
                }
            }
        }

        // 펼쳐진 달 그리드
        ForEach(viewModel.pastMonths) { summary in
            if expandedMonths.contains(summary.id) {
                VStack(spacing: 0) {
                    HStack {
                        Text("\(summary.month)월 게시물")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.textWhite)
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                _ = expandedMonths.remove(summary.id)
                            }
                        } label: {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.customGray300)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    if loadingMonths.contains(summary.id) {
                        ProgressView().tint(.white)
                            .frame(height: 100)
                    } else if let posts = monthPosts[summary.id], !posts.isEmpty {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(posts) { post in
                                NavigationLink(destination: FeedDetailView(
                                    posts: posts,
                                    initialPostId: post.id,
                                    displayName: viewModel.name,
                                    handle: viewModel.handle,
                                    profileImage: nil,
                                    profileImageUrl: viewModel.profileImageUrl,
                                    profileAsset: "Profile_img"
                                )) {
                                    feedThumbnail(post.thumbnailImage, likeCount: post.likeCount)
                                }
                            }
                        }
                    } else {
                        Text("게시물이 없습니다")
                            .font(.system(size: 14))
                            .foregroundColor(.customGray300)
                            .frame(height: 80)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - 썸네일

    @ViewBuilder
    private func feedThumbnail(_ url: String, likeCount: Int) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                if url.hasPrefix("http"), let imgUrl = URL(string: url) {
                    KFImage(imgUrl)
                        .resizable()
                        .placeholder { Color(white: 0.15) }
                        .fade(duration: 0.2)
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                        .clipped()
                } else if !url.isEmpty {
                    Image(url).resizable().scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                        .clipped()
                } else {
                    Color(white: 0.15)
                }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.45)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                    Text("\(likeCount)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.leading, 8)
                .padding(.bottom, 8)
            }
        }
        .aspectRatio(3.0/4.0, contentMode: .fit)
    }

    // MARK: - 토글

    private func toggleMonth(_ summary: PastMonthSummary) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedMonths.contains(summary.id) {
                _ = expandedMonths.remove(summary.id)
            } else {
                expandedMonths.insert(summary.id)
                if monthPosts[summary.id] == nil {
                    loadingMonths.insert(summary.id)
                    Task {
                        let posts = await viewModel.loadMonthFeed(month: summary.month)
                        monthPosts[summary.id] = posts
                        loadingMonths.remove(summary.id)
                    }
                }
            }
        }
    }
}
