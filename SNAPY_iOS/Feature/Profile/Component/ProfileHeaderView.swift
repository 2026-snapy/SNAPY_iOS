//
//  ProfileHeaderView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/7/26.
//

import SwiftUI
import PhotosUI

struct ProfileHeaderView: View {
    @ObservedObject var viewModel: ProfileViewModel

    @State private var showBannerViewer = false
    @State private var showProfileViewer = false

    var body: some View {
        VStack(spacing: 0) {
            // 배너 + 프로필 이미지
            ZStack(alignment: .bottomLeading) {
                // 배너 (탭하면 확대 보기)
                Button {
                    showBannerViewer = true
                } label: {
                    if let bannerImage = viewModel.bannerImage {
                        Image(uiImage: bannerImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .clipped()
                    } else {
                        Image("Banner_img")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .clipped()
                    }
                }

                // 프로필 이미지 (탭하면 확대 보기)
                Button {
                    showProfileViewer = true
                } label: {
                    Group {
                        if let profileImage = viewModel.profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image("Profile_img")
                                .resizable()
                                .scaledToFill()
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.backgroundBlack, lineWidth: 3))
                }
                .offset(x: 16, y: 40)
            }

            // 프로필 정보
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.username)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.textWhite)
                    }

                    Spacer()

                    HStack(spacing: 20) {
                        statItem(value: viewModel.postCount, label: "게시물")
                        statItem(value: viewModel.friendCount, label: "친구")

                        VStack(spacing: 2) {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                                Text("\(viewModel.streakCount)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.textWhite)
                            }
                        }
                    }
                }

                Text(viewModel.mutualFriendsText)
                    .font(.system(size: 12))
                    .foregroundColor(.customGray300)
                    .lineLimit(1)

                Text("@\(viewModel.handle)")
                    .font(.system(size: 14))
                    .foregroundColor(.customGray300)

                HStack(spacing: 12) {
                    Button {
                        viewModel.startEdit()
                    } label: {
                        Text("프로필 수정")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color(white: 0.2))
                            .foregroundColor(.textWhite)
                            .cornerRadius(8)
                    }

                    ShareLink(item: "SNAPY 프로필: @\(viewModel.handle)\nhttps://snapy.app/@\(viewModel.handle)") {
                        Text("프로필 공유")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color(white: 0.2))
                            .foregroundColor(.textWhite)
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 4)
            }
            .padding(.top, 48)
            .padding(.horizontal, 16)
        }
        // 배너 확대 보기
        .fullScreenCover(isPresented: $showBannerViewer) {
            ImageViewerView(
                image: viewModel.bannerImage,
                assetName: "Banner_img"
            )
        }
        // 프로필 확대 보기
        .fullScreenCover(isPresented: $showProfileViewer) {
            ImageViewerView(
                image: viewModel.profileImage,
                assetName: "Profile_img"
            )
        }
    }

    private func statItem(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.textWhite)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.customGray300)
        }
    }
}
