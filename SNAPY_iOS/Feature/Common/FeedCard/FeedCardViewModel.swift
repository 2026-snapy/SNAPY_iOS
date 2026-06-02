//
//  FeedCardViewModel.swift
//  SNAPY_iOS
//
//  Separated from FeedCardView.swift
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class FeedCardViewModel: ObservableObject {
    let albumId: Int
    let handle: String

    @Published var shareImage: UIImage? = nil
    @Published var heartAnimations: [HeartAnimation] = []

    private var heartTapCount: Int = 0

    init(albumId: Int, handle: String) {
        self.albumId = albumId
        self.handle = handle
    }

    // MARK: - 공유 URL

    var shareURL: String {
        "https://snapy.krafte.net/share/album/\(albumId)?handle=\(handle)"
    }

    // MARK: - 공유 이미지 생성

    func shareFeed(
        profileImageSource: ProfileImageSource,
        displayName: String,
        date: String,
        photo: FeedCardPhoto?
    ) {
        Task {
            let profileImg: UIImage? = {
                switch profileImageSource {
                case .uiImage(let image): return image
                default: return nil
                }
            }()

            let profileUrl: String? = {
                switch profileImageSource {
                case .url(let url): return url
                default: return nil
                }
            }()

            let downloadedProfileImg = await downloadImage(from: profileUrl)
            let finalProfileImg = profileImg ?? downloadedProfileImg
            async let backImg = downloadImage(from: photo?.backImageUrl)
            async let frontImg = downloadImage(from: photo?.frontImageUrl)

            let card = FeedShareCard(
                profileImage: finalProfileImg,
                displayName: displayName,
                handle: handle,
                date: date,
                backImage: await backImg,
                frontImage: await frontImg
            )
            if let image = renderShareImage(card) {
                shareImage = image
            }
        }
    }

    // MARK: - 댓글 수 로드

    func loadCommentCount() async -> Int {
        guard albumId > 0 else { return 0 }
        do {
            let result = try await CommentService.shared.fetchComments(albumId: albumId, size: 100)
            return result.content.count
        } catch {
            return 0
        }
    }

    // MARK: - 하트 애니메이션

    func triggerHeartAnimation(at location: CGPoint) {
        heartTapCount += 1
        let size: CGFloat = 60 + CGFloat(heartTapCount - 1) * 2
        let heart = HeartAnimation(position: location, size: min(size, 120))
        heartAnimations.append(heart)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            if let idx = heartAnimations.firstIndex(where: { $0.id == heart.id }) {
                heartAnimations[idx].scale = 1.2
                heartAnimations[idx].opacity = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) {
                if let idx = self?.heartAnimations.firstIndex(where: { $0.id == heart.id }) {
                    self?.heartAnimations[idx].scale = 1.6
                    self?.heartAnimations[idx].opacity = 0
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.heartAnimations.removeAll { $0.id == heart.id }
        }
    }
}
