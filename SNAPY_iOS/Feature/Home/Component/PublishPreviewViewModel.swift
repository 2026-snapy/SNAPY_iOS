//
//  PublishPreviewViewModel.swift
//  SNAPY_iOS
//
//  Separated from PublishPreviewView.swift
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class PublishPreviewViewModel: ObservableObject {
    @Published var isPublishing = false
    @Published var errorMessage: String?

    private let photoStore = PhotoStore.shared

    var todayPhotos: [PhotoData] {
        photoStore.todayAlbum?.photos ?? []
    }

    var todayAlbumId: Int? {
        photoStore.todayAlbum?.albumId
    }

    var isAlreadyPublished: Bool {
        guard let albumId = todayAlbumId else { return false }
        return photoStore.hasPublished(albumId: albumId)
    }

    /// 아직 지나지 않은 식사 슬롯
    var upcomingMealSlots: [String] {
        let hour = Calendar.current.component(.hour, from: Date())
        var result: [String] = []
        if hour < 6  { result.append("아침") }
        if hour < 12 { result.append("점심") }
        if hour < 17 { result.append("저녁") }
        return result
    }

    var upcomingSlotWarningMessage: String {
        let names = upcomingMealSlots
        guard !names.isEmpty else { return "" }
        return "지금 게시하면 \(names.joined(separator: ", ")) 게시물은 올라가지 않아요.\n그래도 게시할까요?"
    }

    // MARK: - 로드

    func loadToday() async {
        await photoStore.loadToday()
    }

    // MARK: - 게시

    /// 게시 가능 여부 확인 후 true면 바로 게시, false면 확인 다이얼로그 필요
    func shouldShowConfirmDialog() -> Bool {
        guard let albumId = todayAlbumId, !isPublishing else { return false }
        if photoStore.hasPublished(albumId: albumId) {
            errorMessage = "오늘은 이미 게시했어요!\n내일 다시 만나요"
            return false
        }
        return !upcomingMealSlots.isEmpty
    }

    func publish(homeViewModel: HomeViewModel, onDismiss: @escaping () -> Void) {
        guard let albumId = todayAlbumId, !isPublishing else { return }
        isPublishing = true
        errorMessage = nil

        let photosToPost = todayPhotos

        Task {
            do {
                _ = try await AlbumService.shared.publish(albumId: albumId)
                photoStore.markPublished(albumId: albumId)
                homeViewModel.prependPublishedPost(photos: photosToPost)
                NotificationCenter.default.post(name: .didPublishAlbum, object: nil)
                isPublishing = false
                onDismiss()
            } catch let error as AlbumError {
                if let desc = error.errorDescription, desc.contains("이미") {
                    photoStore.markPublished(albumId: albumId)
                }
                errorMessage = error.errorDescription
                isPublishing = false
            } catch {
                errorMessage = error.localizedDescription
                isPublishing = false
            }
        }
    }
}
