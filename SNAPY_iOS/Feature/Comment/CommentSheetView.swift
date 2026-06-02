//
//  CommentSheetView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/22/26.
//

import SwiftUI
import PhotosUI

struct CommentSheetView: View {
    @Binding var commentCount: Int
    @StateObject private var viewModel: CommentViewModel
    @State private var showEmojiBar = false
    @State private var showVoiceRecorder = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var deleteTarget: Comment? = nil
    @State private var showDeleteAlert = false
    @State private var viewerImageUrl: IdentifiableString? = nil

    private let emojis = ["💕", "🔥", "🤩", "😍", "😢", "😡", "💀"]

    init(albumId: Int, commentCount: Binding<Int>) {
        self._commentCount = commentCount
        self._viewModel = StateObject(wrappedValue: CommentViewModel(albumId: albumId))
    }

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.customGray300)
                    .frame(width: 40, height: 4)
                    .padding(.top, 10)

                Text("댓글")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.textWhite)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                if viewModel.isLoading && viewModel.comments.isEmpty {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else if viewModel.comments.isEmpty {
                    emptyView
                } else {
                    commentListView
                }

                Spacer()

                if showEmojiBar { emojiBarView }

                inputBar
            }
        }
        .sheet(isPresented: $showVoiceRecorder) {
            VoiceRecorderSheet { recordedURL in
                Task {
                    await viewModel.uploadAudio(url: recordedURL)
                    commentCount = viewModel.comments.count
                }
            }
            .presentationDetents([.fraction(0.55)])
            .presentationDragIndicator(.hidden)
        }
        .onAppear {
            Task {
                await viewModel.loadComments()
                commentCount = viewModel.comments.count
            }
        }
        .alert("댓글 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) { deleteTarget = nil }
            Button("삭제", role: .destructive) {
                if let target = deleteTarget {
                    Task {
                        await viewModel.deleteComment(target)
                        commentCount = viewModel.comments.count
                    }
                    deleteTarget = nil
                }
            }
        } message: {
            Text("이 댓글을 삭제하시겠습니까?")
        }
        .fullScreenCover(item: $viewerImageUrl) { item in
            CommentImageViewer(imageUrl: item.value)
        }
    }

    // MARK: - 빈 상태

    private var emptyView: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("텅 비었네요...")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.textWhite)
            Text("사용자가 당신의 댓글을 기다리고 있어요!")
                .font(.system(size: 14))
                .foregroundColor(.customGray300)
            Spacer()
        }
    }

    // MARK: - 댓글 목록

    private var commentListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(viewModel.comments) { comment in
                    CommentRow(
                        comment: comment,
                        isMine: comment.handle == viewModel.myHandle,
                        onDelete: {
                            deleteTarget = comment
                            showDeleteAlert = true
                        },
                        onImageTap: { url in
                            viewerImageUrl = IdentifiableString(value: url)
                        }
                    )
                }

                if viewModel.hasMore && !viewModel.isLoading {
                    Button {
                        Task { await viewModel.loadMore() }
                    } label: {
                        Text("더보기")
                            .font(.system(size: 14))
                            .foregroundColor(.customGray300)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                }

                if viewModel.isLoading && !viewModel.comments.isEmpty {
                    ProgressView().tint(.white)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    // MARK: - 이모지 바

    private var emojiBarView: some View {
        HStack(spacing: 16) {
            ForEach(emojis, id: \.self) { emoji in
                Button {
                    Task {
                        await viewModel.uploadEmoji(emoji)
                        commentCount = viewModel.comments.count
                    }
                    showEmojiBar = false
                } label: {
                    Text(emoji)
                        .font(.system(size: 32))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - 하단 입력 바

    private var inputBar: some View {
        HStack(spacing: 0) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.customDarkGray, in: Circle())
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    await viewModel.uploadImage(item: newItem)
                    commentCount = viewModel.comments.count
                }
                selectedPhotoItem = nil
            }

            Spacer()

            Button {
                showVoiceRecorder = true
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(Color.red, in: Circle())
            }

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showEmojiBar.toggle()
                }
            } label: {
                if showEmojiBar {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.red)
                        .frame(width: 52, height: 52)
                        .background(Color.customDarkGray, in: Circle())
                } else {
                    Text("😊")
                        .font(.system(size: 28))
                        .frame(width: 52, height: 52)
                        .background(Color.customDarkGray, in: Circle())
                }
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 30)
        .padding(.top, 10)
    }
}

#Preview("댓글 있음") {
    CommentSheetView(albumId: 1, commentCount: .constant(0))
}
