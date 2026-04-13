//
//  FriendProfileView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/13/26.
//

import SwiftUI

struct FriendProfileView: View {
    @Environment(\.dismiss) private var dismiss

    let name: String
    let handle: String
    let profileImageUrl: String?

    // 목 데이터
    private let postCount = 5
    private let friendCount = 13
    private let streakCount = 2

    // 친구 추가 상태
    @State private var isFriendRequested = false

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // MARK: 배너
                    Color.customDarkGray
                        .frame(height: 200)

                    // MARK: 프로필 정보
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .center) {
                            // 프로필 이미지
                            Group {
                                if let url = profileImageUrl {
                                    AsyncImage(url: URL(string: url)) { phase in
                                        switch phase {
                                        case .success(let img): img.resizable().scaledToFill()
                                        default: Color.customDarkGray
                                        }
                                    }
                                } else {
                                    Image("Profile_img")
                                        .resizable()
                                        .scaledToFill()
                                }
                            }
                            .frame(width: 96, height: 96)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.backgroundBlack, lineWidth: 3))

                            Spacer().frame(width: 30)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.textWhite)

                                HStack(spacing: 65) {
                                    statItem(value: postCount, label: "게시물")
                                    statItem(value: friendCount, label: "친구")

                                    VStack(spacing: 6) {
                                        Image("Strick_fire")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 26)
                                        Text("\(streakCount)")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.textWhite)
                                    }
                                    .padding(.bottom, 8)
                                }
                            }
                            .padding(.top, 10)
                        }

                        // @handle
                        Text("@\(handle)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textWhite)

                        // 친구 추가 / 취소 버튼
                        Button {
                            isFriendRequested.toggle()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isFriendRequested ? "clock" : "person.badge.plus")
                                    .font(.system(size: 14, weight: .medium))
                                Text(isFriendRequested ? "요청됨" : "친구 추가")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .foregroundColor(isFriendRequested ? .customGray300 : .textWhite)
                            .background(.customDarkGray)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.top, 28)
                    .padding(.horizontal, 22)

                    // MARK: 공개 프로필 안내
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.textWhite)

                        Text("친구 공개 프로필입니다")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.textWhite)

                        Text("지금 친구 추가하고 친구의 SNAP을 만나보세요.")
                            .font(.system(size: 14))
                            .foregroundColor(.customGray300)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textWhite)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: "SNAPY 프로필: @\(handle)\nhttps://snapy.app/@\(handle)") {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textWhite)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
        }
        .toolbarBackground(Color.clear, for: .navigationBar)
    }

    private func statItem(value: Int, label: String) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.customGray300)
            Text("\(value)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textWhite)
        }
    }
}
