//
//  ProfileHeaderView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/7/26.
//

import SwiftUI
import PhotosUI
import Kingfisher

struct ProfileHeaderView: View {
    @ObservedObject var viewModel: ProfileViewModel

    @State private var showBannerViewer = false
    @State private var showProfileViewer = false
    @State private var showFriendList = false
    @State private var showStreakSheet = false
    @State private var shareImage: UIImage? = nil
    @State private var showStory = false

    var body: some View {
        VStack(spacing: 0) {
            bannerSection
            profileInfoSection
        }
        .fullScreenCover(isPresented: $showBannerViewer) {
            ImageViewerView(image: viewModel.bannerImage, imageUrl: viewModel.bannerImageUrl, assetName: "Banner_img", isCircle: false)
        }
        .fullScreenCover(isPresented: $showProfileViewer) {
            ImageViewerView(image: viewModel.profileImage, imageUrl: viewModel.profileImageUrl, assetName: "Profile_img", isCircle: true)
        }
        .fullScreenCover(isPresented: $showStory) {
            if let story = viewModel.myStory {
                StoryDetailView(stories: [story], initialIndex: 0)
            }
        }
        .task { await viewModel.loadMyStory() }
        .navigationDestination(isPresented: $showFriendList) {
            FriendListView(handle: viewModel.handle)
        }
        .sheet(isPresented: $showStreakSheet) {
            StreakSheet(currentStreak: viewModel.streakCount, maxStreak: viewModel.maxStreak)
                .presentationDetents([.fraction(0.3)])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - 배너

    private var bannerSection: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showBannerViewer = true
        } label: {
            Color.clear
                .frame(maxWidth: .infinity).frame(height: 200)
                .overlay(bannerImage)
                .clipShape(Rectangle())
        }
    }

    @ViewBuilder
    private var bannerImage: some View {
        if let img = viewModel.bannerImage {
            Image(uiImage: img).resizable().scaledToFill()
        } else if let url = viewModel.bannerImageUrl, let imgUrl = URL(string: url) {
            KFImage(imgUrl).resizable().placeholder { Color.customDarkGray }.fade(duration: 0.2).scaledToFill()
        } else {
            Color.customDarkGray
        }
    }

    // MARK: - 프로필 정보

    private var profileInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            profileImageAndStats

            if !viewModel.mutualFriendsText.isEmpty {
                Text(viewModel.mutualFriendsText)
                    .font(.system(size: 13, weight: .medium)).foregroundColor(.textWhite)
            }

            Text("@\(viewModel.handle)")
                .font(.system(size: 14, weight: .semibold)).foregroundColor(.textWhite)

            actionButtons
        }
        .padding(.top, 48).padding(.horizontal, 20)
    }

    // MARK: - 프로필 이미지 + 통계

    private var profileImageAndStats: some View {
        HStack(alignment: .center) {
            profileImageView
                .frame(width: 96, height: 96).clipShape(Circle()).padding(5)
                .overlay(storyRingOverlay)
                .onTapGesture {
                    if let story = viewModel.myStory {
                        showStory = true; SeenStoryStore.markSeen(story.storyIds)
                    } else { showProfileViewer = true }
                }
                .onLongPressGesture(minimumDuration: 0.2) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showProfileViewer = true
                }

            Spacer().frame(width: 30)

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.username).font(.system(size: 16, weight: .bold)).foregroundColor(.textWhite)
                HStack(spacing: 65) {
                    statItem(value: viewModel.postCount, label: "게시물")
                    Button { showFriendList = true } label: { statItem(value: viewModel.friendCount, label: "친구") }
                    Button { showStreakSheet = true } label: {
                        VStack(spacing: 6) {
                            Image(viewModel.streakCount >= 5 ? "Strick_sequence_fire" : "Strick_fire")
                                .resizable().scaledToFit().frame(height: 26)
                            Text("\(viewModel.streakCount)")
                                .font(.system(size: 18, weight: .bold)).foregroundColor(.textWhite)
                        }.padding(.bottom, 8)
                    }
                }
            }.padding(.top, 10)
        }
    }

    @ViewBuilder
    private var profileImageView: some View {
        if let img = viewModel.profileImage {
            Image(uiImage: img).resizable().scaledToFill()
        } else if let url = viewModel.profileImageUrl, let imgUrl = URL(string: url) {
            KFImage(imgUrl).resizable().placeholder { Color.customDarkGray }.fade(duration: 0.2).scaledToFill()
        } else { Color.customDarkGray }
    }

    @ViewBuilder
    private var storyRingOverlay: some View {
        if let story = viewModel.myStory {
            Circle().stroke(
                story.storyIds.allSatisfy({ SeenStoryStore.isSeen($0) })
                    ? AnyShapeStyle(Color.customGray500)
                    : AnyShapeStyle(LinearGradient(
                        colors: [Color(hex: "FFC83D"), Color(hex: "FF9F1C")],
                        startPoint: .topLeading, endPoint: .bottomTrailing)),
                lineWidth: 2.5)
        }
    }

    // MARK: - 액션 버튼

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button { viewModel.startEdit() } label: {
                Text("프로필 수정").font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity).frame(height: 36)
                    .background(.customDarkGray).foregroundColor(.textWhite).cornerRadius(8)
            }
            Button {
                Task {
                    if let image = await viewModel.shareProfile() {
                        let shareURL = "https://snapy.krafte.net/share/profile/\(viewModel.handle)"
                        let text = "SNAPY 프로필: @\(viewModel.handle)\n\nSNAPY에서 당신의 일상을 공유해보세요!\n\n\(shareURL)"
                        presentShareSheet(items: [image, text])
                    }
                }
            } label: {
                Text("프로필 공유").font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity).frame(height: 36)
                    .background(.customDarkGray).foregroundColor(.textWhite).cornerRadius(8)
            }
        }.padding(.top, 4)
    }

    private func statItem(value: Int, label: String) -> some View {
        VStack(spacing: 6) {
            Text(label).font(.system(size: 12)).foregroundColor(.customGray300)
            Text("\(value)").font(.system(size: 18, weight: .bold)).foregroundColor(.textWhite)
        }
    }
}

#Preview {
    ScrollView {
        ProfileHeaderView(viewModel: {
            let vm = ProfileViewModel()
            vm.username = "김은찬"
            vm.handle = "eunchan"
            vm.postCount = 42
            vm.friendCount = 128
            vm.streakCount = 7
            return vm
        }())
    }
    .background(Color.backgroundBlack)
}
