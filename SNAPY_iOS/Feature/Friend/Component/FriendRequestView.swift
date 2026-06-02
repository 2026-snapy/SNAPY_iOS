//
//  FriendRequestView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/13/26.
//

import SwiftUI

struct FriendRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FriendRequestViewModel()
    @StateObject private var friendVM = FriendViewModel()

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: 요청 섹션
                    if viewModel.requests.isEmpty {
                        // 요청 없음
                        VStack(spacing: 8) {
                            Text("들어온 친구 요청이 없습니다")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.customGray300)

                            Text("추천 친구에게 요청을 보내보세요!")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.mainYellow)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 30)
                        .padding(.bottom, 30)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        // 요청 있음
                        ForEach(viewModel.requests) { request in
                            FriendRequestRow(
                                request: request,
                                onAccept: { withAnimation(.easeInOut(duration: 0.3)) { viewModel.acceptRequest(request) } },
                                onReject: { withAnimation(.easeInOut(duration: 0.3)) { viewModel.rejectRequest(request) } }
                            )
                            .transition(.opacity.combined(with: .offset(x: -50)))
                        }
                        .padding(.top, 16)
                    }

                    // MARK: 추천 친구 섹션
                    Divider()
                        .background(Color.customGray500)
                        .padding(.top, 20)

                    Text("추천 친구")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textWhite)
                        .padding(.horizontal, 22)
                        .padding(.top, 20)
                        .padding(.bottom, 12)

                    if friendVM.isLoading {
                        FriendSkeletonList()
                    } else if friendVM.filteredFriends.isEmpty {
                        Text("추천 친구가 없습니다")
                            .font(.system(size: 14))
                            .foregroundColor(.customGray300)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                    } else {
                        ForEach(friendVM.filteredFriends) { friend in
                            SuggestedFriendRow(
                                friend: friend,
                                onAdd: { friendVM.sendRequest(to: friend) },
                                onCancel: { friendVM.cancelRequest(to: friend) },
                                onHide: { withAnimation(.easeInOut(duration: 0.3)) { friendVM.hideFriend(friend) } },
                                onStatusCheck: { handle in friendVM.refreshRequestStatus(handle: handle) }
                            )
                            .transition(.opacity.combined(with: .offset(x: -50)))
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 80 && abs(value.translation.height) < 100 {
                        dismiss()
                    }
                }
        )
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textWhite)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("친구 요청")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textWhite)
            }
        }
        .toolbarBackground(Color.backgroundBlack, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.loadRequests()
            await friendVM.loadRecommendedFriends()
        }
    }
}
