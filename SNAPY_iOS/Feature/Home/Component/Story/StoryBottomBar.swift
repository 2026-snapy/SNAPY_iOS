//
//  StoryBottomBar.swift
//  SNAPY_iOS
//
//  Separated from StoryDetailView.swift
//

import SwiftUI
import Kingfisher

struct StoryBottomBar: View {
    @ObservedObject var viewModel: StoryDetailViewModel
    var onShowLikeSheet: () -> Void

    private var story: StoryItem { viewModel.currentStory }
    private var isMyStory: Bool { story.username == viewModel.myHandle }

    var body: some View {
        if isMyStory {
            myStoryButtons
        } else {
            otherStoryButtons
        }
    }

    // MARK: - 내 스토리

    private var myStoryButtons: some View {
        HStack(spacing: 14) {
            if !viewModel.likeUsers.isEmpty {
                Button {
                    viewModel.isPaused = true
                    onShowLikeSheet()
                } label: {
                    HStack(spacing: 0) {
                        let displayUsers = Array(viewModel.likeUsers.prefix(5))
                        ForEach(Array(displayUsers.enumerated()), id: \.element.id) { index, user in
                            ZStack(alignment: .bottomTrailing) {
                                likeUserAvatar(user: user)
                                if index == displayUsers.count - 1 {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.red)
                                        .offset(x: 3, y: 3)
                                }
                            }
                            .offset(x: CGFloat(-index * 14))
                        }
                    }
                    .padding(.leading, CGFloat(min(viewModel.likeUsers.count, 5) - 1) * 14)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button {
                viewModel.shareStory()
            } label: {
                Image(systemName: "paperplane")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 30)
    }

    // MARK: - 다른 사람 스토리

    private var otherStoryButtons: some View {
        HStack(spacing: 20) {
            Spacer()

            Button {
                viewModel.triggerLike()
            } label: {
                ZStack {
                    if viewModel.showHeartPop {
                        Image("Heart_img")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.2).combined(with: .opacity),
                                removal: .opacity.combined(with: .offset(y: -20))
                            ))
                            .offset(y: -50)
                    }

                    Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 28))
                        .foregroundColor(viewModel.isLiked ? .red : .white)
                }
                .frame(width: 48, height: 48)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                viewModel.shareStory()
            } label: {
                Image(systemName: "paperplane")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 30)
    }

    @ViewBuilder
    private func likeUserAvatar(user: StoryLikeUserData) -> some View {
        if let url = user.profileImageUrl, let imgUrl = URL(string: url) {
            KFImage(imgUrl)
                .resizable()
                .placeholder { Image("Profile_img").resizable().scaledToFill() }
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
        } else {
            Image("Profile_img")
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
        }
    }
}
