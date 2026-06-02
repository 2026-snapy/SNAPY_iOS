//
//  CommentViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬
//

import Foundation
import SwiftUI
import PhotosUI
import Combine

@MainActor
final class CommentViewModel: ObservableObject {
    let albumId: Int

    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var hasMore = true

    private var nextCursor: Int? = nil
    let myHandle = UserDefaults.standard.string(forKey: "myHandle") ?? ""

    init(albumId: Int) {
        self.albumId = albumId
    }

    // MARK: - 댓글 로드

    func loadComments() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await CommentService.shared.fetchComments(albumId: albumId)
            comments = result.content.map { Comment(from: $0) }
            nextCursor = result.nextCursor
            hasMore = result.hasNext
        } catch {
            print("[Comment] 댓글 로드 실패: \(error)")
        }
    }

    func loadMore() async {
        guard hasMore, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await CommentService.shared.fetchComments(albumId: albumId, cursor: nextCursor)
            comments.append(contentsOf: result.content.map { Comment(from: $0) })
            nextCursor = result.nextCursor
            hasMore = result.hasNext
        } catch {
            print("[Comment] 댓글 더보기 실패: \(error)")
        }
    }

    // MARK: - 이미지 댓글

    func uploadImage(item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            print("[Comment] 이미지 로드 실패")
            return
        }
        let temp = Comment(profileImageUrl: nil, handle: myHandle, type: .image(url: ""))
        comments.append(temp)
        do {
            _ = try await CommentService.shared.uploadImage(albumId: albumId, image: image)
            await loadComments()
        } catch {
            print("[Comment] 이미지 댓글 실패: \(error)")
            comments.removeAll { $0.id == temp.id }
        }
    }

    // MARK: - 이모지 댓글

    func uploadEmoji(_ emoji: String) async {
        let temp = Comment(profileImageUrl: nil, handle: myHandle, type: .emoji(emoji))
        comments.append(temp)
        do {
            _ = try await CommentService.shared.uploadEmoji(albumId: albumId, emoji: emoji)
            await loadComments()
        } catch {
            print("[Comment] 이모지 댓글 실패: \(error)")
            comments.removeAll { $0.id == temp.id }
        }
    }

    // MARK: - 음성 댓글

    func uploadAudio(url: URL) async {
        let temp = Comment(profileImageUrl: nil, handle: myHandle, type: .voice(url: url.absoluteString, duration: 4))
        comments.append(temp)
        do {
            _ = try await CommentService.shared.uploadAudio(albumId: albumId, audioURL: url)
            await loadComments()
        } catch {
            print("[Comment] 음성 댓글 실패: \(error)")
            comments.removeAll { $0.id == temp.id }
        }
    }

    // MARK: - 댓글 삭제

    func deleteComment(_ comment: Comment) async {
        comments.removeAll { $0.id == comment.id }
        do {
            try await CommentService.shared.deleteComment(commentId: comment.id)
        } catch {
            print("[Comment] 댓글 삭제 실패: \(error)")
            await loadComments()
        }
    }
}
