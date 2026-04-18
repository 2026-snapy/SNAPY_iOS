//
//  HomeStoryBar.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/16/26.
//

import SwiftUI

private struct StoryPresentation: Identifiable {
    let id = UUID()
    let index: Int
}

struct HomeStoryBar: View {
    let stories: [StoryItem]
    @State private var storyPresentation: StoryPresentation?

    private var sortedStories: [StoryItem] {
        stories.sorted { !$0.isSeen && $1.isSeen }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 13) {
                ForEach(Array(sortedStories.enumerated()), id: \.element.id) { index, story in
                    Button {
                        storyPresentation = StoryPresentation(index: index)
                    } label: {
                        storyCard(story: story)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .fullScreenCover(item: $storyPresentation) { presentation in
            StoryDetailView(
                stories: sortedStories,
                initialIndex: presentation.index
            )
        }
    }

    @ViewBuilder
    private func storyCard(story: StoryItem) -> some View {
        let borderColors: [Color] = story.isSeen
            ? [.customGray500, .customGray300]
            : [Color(hex: "FFC83D"), Color(hex: "FF9F1C")]

        VStack(spacing: 6) {
            ZStack {
                // 배너 배경
                Image(story.bannerImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // 어두운 오버레이
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 60, height: 100)

                // 프로필 사진
                Image(story.profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.backgroundBlack, lineWidth: 1)
                    )
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(
                        LinearGradient(
                            colors: borderColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.7
                    )
            )

            // 유저네임 (카드 밖)
            Text(story.username)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 66)
                .padding(.top, 5)
        }
    }
}

struct HomeFeed_Previews: PreviewProvider {
    static var previews: some View {
        HomeStoryBar(
            stories: [
                StoryItem(profileImage: "Profile_img", bannerImage: "Mock_img1", displayName: "은찬", username: "eunchan", images: ["Mock_img1", "Mock_img2"], isSeen: false),
                StoryItem(profileImage: "Profile_img", bannerImage: "Mock_img2", displayName: "민수", username: "user_02", images: ["Mock_img2"], isSeen: true),
                StoryItem(profileImage: "Profile_img", bannerImage: "Mock_img3", displayName: "지현", username: "user_03", images: ["Mock_img3", "Mock_img4"], isSeen: false),
            ]
        )
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}
