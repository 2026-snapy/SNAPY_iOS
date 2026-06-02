//
//  CommentRow.swift
//  SNAPY_iOS
//
//  Separated from CommentSheetView.swift
//

import SwiftUI
import Kingfisher

struct CommentRow: View {
    let comment: Comment
    var isMine: Bool = false
    var onDelete: (() -> Void)? = nil
    var onImageTap: ((String) -> Void)? = nil

    @StateObject private var audioPlayer = AudioCommentPlayer()
    @State private var showProfile = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 프로필
            Button {
                showProfile = true
            } label: {
                profileImage
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 8) {
                Button {
                    showProfile = true
                } label: {
                    Text(comment.handle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textWhite)
                }

                commentContent
            }

            Spacer()

            if isMine {
                Button {
                    onDelete?()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.customGray300)
                }
            }
        }
        .fullScreenCover(isPresented: $showProfile) {
            let myHandle = UserDefaults.standard.string(forKey: "myHandle") ?? ""
            if comment.handle == myHandle {
                ZStack(alignment: .topLeading) {
                    NavigationStack {
                        ProfileView()
                    }
                    Button { showProfile = false } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color.primary)
                            .padding(2)
                    }
                    .buttonStyle(.glass)
                    .padding(.leading, 16)
                    .padding(.top, 10)
                }
            } else {
                NavigationStack {
                    FriendProfileView(name: "", handle: comment.handle, profileImageUrl: comment.profileImageUrl)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button { showProfile = false } label: {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(.glass)
                            }
                        }
                }
            }
        }
    }

    @ViewBuilder
    private var profileImage: some View {
        if let url = comment.profileImageUrl, let imgUrl = URL(string: url) {
            KFImage(imgUrl)
                .resizable()
                .placeholder { Color.customDarkGray }
                .scaledToFill()
        } else {
            Image("Profile_img")
                .resizable()
                .scaledToFill()
        }
    }

    @ViewBuilder
    private var commentContent: some View {
        switch comment.type {
        case .image(let url):
            imageComment(url: url)
        case .voice(let url, _):
            voiceComment(url: url)
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: 48))
        }
    }

    // MARK: - 이미지 댓글

    @ViewBuilder
    private func imageComment(url: String) -> some View {
        if url.isImageURL, let imgUrl = URL(string: url) {
            KFImage(imgUrl)
                .resizable()
                .placeholder { Color.customDarkGray }
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: 200, maxHeight: 240, alignment: .leading)
                .onTapGesture {
                    onImageTap?(url)
                }
        } else {
            Image(url)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: 200, maxHeight: 240, alignment: .leading)
        }
    }

    // MARK: - 음성 댓글

    private func voiceComment(url: String) -> some View {
        HStack(spacing: 12) {
            Button {
                audioPlayer.togglePlayback(urlString: url)
            } label: {
                Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.black)
            }

            HStack(spacing: 2) {
                ForEach(0..<30, id: \.self) { index in
                    let isActive = audioPlayer.isPlaying && Double(index) / 30.0 <= audioPlayer.progress
                    RoundedRectangle(cornerRadius: 1)
                        .fill(isActive ? Color.black : Color.black.opacity(0.3))
                        .frame(width: 2.5, height: audioPlayer.waveformHeights[index])
                }
            }

            Text(formatDuration(audioPlayer.isPlaying ? audioPlayer.currentTime : audioPlayer.duration))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.MainYellow, in: RoundedRectangle(cornerRadius: 16))
        .onAppear {
            audioPlayer.loadDuration(urlString: url)
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
