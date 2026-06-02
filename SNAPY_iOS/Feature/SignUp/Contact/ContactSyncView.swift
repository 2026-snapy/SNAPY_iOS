//
//  ContactSyncView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/14/26.
//

import SwiftUI
import Kingfisher

struct ContactSyncView: View {
    var onDoneTap: () -> Void
    @StateObject private var viewModel = ContactSyncViewModel()

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            if !viewModel.synced {
                syncPromptView
            } else {
                contactResultView
            }
        }
    }

    // MARK: - 동기화 전

    private var syncPromptView: some View {
        VStack(alignment: .leading, spacing: 0) {
            logoHeader

            VStack(alignment: .leading, spacing: 8) {
                Text("친구들에게 SNAPY를 공유하고")
                Text("함께 더 재미있게 즐겨보세요!")
            }
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(Color.textWhite)
            .padding(.top, 16).padding(.horizontal, 24)

            Spacer()

            HStack {
                Spacer()
                Image("Contact_icon").resizable().scaledToFit().frame(width: 180, height: 180)
                Spacer()
            }

            Spacer()

            Text("연락처의 전화번호는 친구 추천 목적으로만 서버에 전송되며,\n제3자에게 공유되지 않습니다.")
                .font(.system(size: 12)).foregroundColor(.customGray300)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                .padding(.horizontal, 24).padding(.bottom, 16)

            SnapyButton(title: viewModel.isSyncing ? "동기화 중..." : "연락처 연동하기", isEnabled: !viewModel.isSyncing) {
                viewModel.requestContactAccess(onDenied: onDoneTap)
            }
            .padding(.bottom, 10)

            Button { onDoneTap() } label: {
                Text("건너뛰기").font(.system(size: 14, weight: .medium))
                    .foregroundColor(.customGray300).frame(maxWidth: .infinity).padding(.top, 16)
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - 동기화 후

    private var contactResultView: some View {
        VStack(alignment: .leading, spacing: 0) {
            logoHeader

            if viewModel.contactUsers.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Text("연락처에 SNAPY를 사용하는\n친구가 아직 없어요")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.customGray300)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                Text("내 연락처에서 SNAPY를 사용하는 친구")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textWhite)
                    .padding(.top, 24).padding(.horizontal, 24).padding(.bottom, 12)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.contactUsers) { user in
                            contactRow(user: user)
                        }
                    }
                }
            }

            Spacer()

            SnapyButton(title: "시작하기") { onDoneTap() }
                .padding(.bottom, 24)
        }
    }

    // MARK: - 로고 헤더

    private var logoHeader: some View {
        HStack(spacing: 12) {
            Image("Login_Logo").resizable().scaledToFit().frame(width: 40, height: 40)
            Text("SNAPY").font(.system(size: 28, weight: .bold)).foregroundColor(.textWhite)
        }
        .padding(.top, 60).padding(.horizontal, 24)
    }

    // MARK: - 연락처 Row

    @ViewBuilder
    private func contactRow(user: ContactUserData) -> some View {
        let isRequested = viewModel.requestedHandles.contains(user.handle)

        HStack(spacing: 12) {
            if let url = user.profileImageUrl, let imgUrl = URL(string: url) {
                KFImage(imgUrl).resizable()
                    .placeholder { Image("Profile_img").resizable().scaledToFill() }
                    .scaledToFill().frame(width: 44, height: 44).clipShape(Circle())
            } else {
                Image("Profile_img").resizable().scaledToFill()
                    .frame(width: 44, height: 44).clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(user.username).font(.system(size: 15, weight: .semibold)).foregroundColor(.textWhite)
                Text("@\(user.handle)").font(.system(size: 13)).foregroundColor(.customGray300)
            }

            Spacer()

            if isRequested {
                Text("요청됨").font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.customGray300)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.customDarkGray).cornerRadius(6)
            } else {
                Button { viewModel.sendFriendRequest(handle: user.handle) } label: {
                    Text("친구 추가").font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.backgroundBlack)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.MainYellow).cornerRadius(6)
                }
            }
        }
        .padding(.horizontal, 24).padding(.vertical, 10)
    }
}

#Preview {
    ContactSyncView(onDoneTap: {})
}
