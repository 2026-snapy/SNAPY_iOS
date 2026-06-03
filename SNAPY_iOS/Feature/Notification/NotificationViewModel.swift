//
//  NotificationViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/7/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class NotificationViewModel: ObservableObject {
    @Published var notifications: [NotificationData] = []
    @Published var unreadCount: Int64 = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    // 네비게이션 상태
    @Published var storyToShow: StoryItem? = nil
    @Published var feedPost: FeedPost? = nil
    @Published var feedHandle: String = ""
    @Published var feedName: String = ""
    @Published var feedProfileUrl: String? = nil
    @Published var showFeedDetail = false
    @Published var expiredAlertMessage = ""
    @Published var showExpiredAlert = false

    private let service = NotificationService.shared
    private var currentPage = 0
    private var hasNext = true

    // MARK: - 알림 목록

    func loadNotifications() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        currentPage = 0
        do {
            let data = try await service.getNotifications(page: 0, size: 20)
            notifications = data.items
            hasNext = data.hasNext
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard !isLoading, hasNext else { return }
        isLoading = true
        let nextPage = currentPage + 1
        do {
            let data = try await service.getNotifications(page: nextPage, size: 20)
            notifications.append(contentsOf: data.items)
            hasNext = data.hasNext
            currentPage = nextPage
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - 읽음 처리

    func fetchUnreadCount() async {
        do { unreadCount = try await service.getUnreadCount() }
        catch { print("[Notification] unread count 실패: \(error)") }
    }

    func markAsRead(_ notification: NotificationData) async {
        guard !notification.read else { return }
        do {
            try await service.markAsRead(id: notification.id)
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index] = NotificationData(
                    id: notification.id, senderId: notification.senderId,
                    senderHandle: notification.senderHandle, senderUsername: notification.senderUsername,
                    senderProfileImageUrl: notification.senderProfileImageUrl,
                    type: notification.type, referenceId: notification.referenceId,
                    referenceType: notification.referenceType, read: true, createdAt: notification.createdAt
                )
            }
            if unreadCount > 0 { unreadCount -= 1 }
        } catch { print("[Notification] 읽음 처리 실패: \(error)") }
    }

    func markAllAsRead() async {
        do {
            try await service.markAllAsRead()
            notifications = notifications.map { n in
                NotificationData(
                    id: n.id, senderId: n.senderId,
                    senderHandle: n.senderHandle, senderUsername: n.senderUsername,
                    senderProfileImageUrl: n.senderProfileImageUrl,
                    type: n.type, referenceId: n.referenceId,
                    referenceType: n.referenceType, read: true, createdAt: n.createdAt
                )
            }
            unreadCount = 0
        } catch { errorMessage = error.localizedDescription }
    }

    // MARK: - 알림 메시지

    func message(for notification: NotificationData) -> AttributedString {
        let name = notification.senderUsername ?? notification.senderHandle ?? "알 수 없음"
        let suffix: String
        switch notification.type {
        case .storyLike:        suffix = "님이 스토리에 좋아요를 눌렀습니다."
        case .feedLike:         suffix = "님이 게시물에 좋아요를 눌렀습니다."
        case .friendRequest:    suffix = "님이 친구 요청을 보냈습니다."
        case .friendAccepted:   suffix = "님이 친구 요청을 수락했습니다."
        case .albumPublished:   suffix = "님의 앨범이 발행되었습니다."
        case .newStory:         suffix = "님이 새 스토리를 올렸습니다."
        case .feedComment:      suffix = "님이 댓글을 남겼습니다."
        case .guestbookCreated: suffix = "님이 방명록을 남겼습니다."
        case .albumPhotoUploadReminder:
            var text = AttributedString("앨범에 사진을 올려주세요!")
            text.font = .system(size: 14, weight: .regular)
            return text
        }
        var boldName = AttributedString(name)
        boldName.font = .system(size: 14, weight: .bold)
        var rest = AttributedString(suffix)
        rest.font = .system(size: 14, weight: .regular)
        return boldName + rest
    }

    // MARK: - 컨텐츠 탭 처리

    func handleContentTap(_ notification: NotificationData, dismiss: DismissAction) {
        switch notification.type {
        case .friendRequest, .friendAccepted:
            break // View에서 네비게이션 처리

        case .storyLike:
            guard let storyId = notification.referenceId else { return }
            loadAndShowStory(storyId: Int(storyId), photoType: notification.referenceType)

        case .newStory:
            guard let handle = notification.senderHandle else { return }
            loadAndShowUserStory(handle: handle)

        case .feedLike, .feedComment:
            guard let albumIdStr = notification.referenceType, let albumId = Int(albumIdStr) else { return }
            loadAndShowFeed(albumId: albumId, handle: UserDefaults.standard.string(forKey: "myHandle") ?? "", name: "나", profileUrl: nil)

        case .albumPublished:
            let albumId: Int? = {
                if let r = notification.referenceType, let id = Int(r) { return id }
                if let r = notification.referenceId { return Int(r) }
                return nil
            }()
            guard let albumId, let handle = notification.senderHandle else { return }
            loadAndShowFeed(albumId: albumId, handle: handle, name: notification.senderUsername ?? "", profileUrl: notification.senderProfileImageUrl)

        case .guestbookCreated:
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                NotificationCenter.default.post(name: .switchToProfileTab, object: nil)
            }

        case .albumPhotoUploadReminder:
            if let date = NotificationDateParser.parse(notification.createdAt), Calendar.current.isDateInToday(date) {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    NotificationCenter.default.post(name: .openCamera, object: nil)
                }
            } else {
                expiredAlertMessage = "오늘의 앨범만 촬영할 수 있습니다."
                showExpiredAlert = true
            }
        }
    }

    // MARK: - 스토리 로드

    private func loadAndShowStory(storyId: Int, photoType: String? = nil) {
        Task {
            do {
                let detail = try await StoryService.shared.fetchDetail(storyId: storyId)
                let photos = detail.photos.map { p -> StoryPhotoSet in
                    var photo = p; photo.ownerStoryId = storyId; return photo
                }
                var startIndex = 0
                if let photoType, let idx = photos.firstIndex(where: { $0.type == photoType }) { startIndex = idx }
                storyToShow = StoryItem(
                    storyId: storyId, storyIds: [storyId],
                    profileImage: detail.profileImageUrl ?? "", bannerImage: "",
                    displayName: detail.username, username: detail.handle,
                    photos: photos, createdAt: detail.createdAt, isSeen: true, unseenStartIndex: startIndex
                )
            } catch {
                expiredAlertMessage = "스토리는 24시간 이내에만 확인할 수 있습니다."
                showExpiredAlert = true
            }
        }
    }

    private func loadAndShowUserStory(handle: String) {
        Task {
            do {
                let list = try await StoryService.shared.fetchStories()
                let userStories = list.filter { $0.handle == handle }
                guard !userStories.isEmpty else { return }
                var allPhotos: [StoryPhotoSet] = []
                var latest = userStories[0]
                for story in userStories.sorted(by: { $0.storyId < $1.storyId }) {
                    if let detail = try? await StoryService.shared.fetchDetail(storyId: story.storyId) {
                        let photos = detail.photos.map { p -> StoryPhotoSet in
                            var photo = p; photo.ownerStoryId = story.storyId; return photo
                        }
                        allPhotos.append(contentsOf: photos)
                        if story.storyId > latest.storyId { latest = story }
                    }
                }
                guard !allPhotos.isEmpty else { return }
                storyToShow = StoryItem(
                    storyId: latest.storyId, profileImage: latest.profileImageUrl ?? "",
                    bannerImage: latest.thumbnailUrl ?? "", displayName: latest.username,
                    username: handle, photos: allPhotos, createdAt: latest.createdAt, isSeen: false
                )
            } catch {
                expiredAlertMessage = "스토리는 24시간 이내에만 확인할 수 있습니다."
                showExpiredAlert = true
            }
        }
    }

    // MARK: - 피드 로드

    private func loadAndShowFeed(albumId: Int, handle: String, name: String, profileUrl: String?) {
        Task {
            do {
                // 앨범 로드 + 프로필 정보 보충 병렬 처리
                async let albumTask = AlbumService.shared.fetchAlbumAsDaily(albumId: albumId)
                async let profileTask = loadProfileIfNeeded(handle: handle, name: name, profileUrl: profileUrl)

                let detail = try await albumTask
                let (resolvedName, resolvedProfileUrl) = await profileTask

                guard !detail.photos.isEmpty else { return }
                feedPost = FeedPost(
                    id: albumId, thumbnailImage: detail.photos.first?.backImageUrl ?? "",
                    photos: detail.photos, date: detail.albumDate, rawDate: detail.albumDate,
                    isLiked: detail.liked ?? false, likeCount: detail.likeCount ?? 0
                )
                feedHandle = handle
                feedName = resolvedName
                feedProfileUrl = resolvedProfileUrl
                showFeedDetail = true
            } catch {
                expiredAlertMessage = "게시물을 찾을 수 없습니다."
                showExpiredAlert = true
            }
        }
    }

    private func loadProfileIfNeeded(handle: String, name: String, profileUrl: String?) async -> (String, String?) {
        // 프로필 URL이 이미 있고 이름도 유효하면 그대로 사용
        if profileUrl != nil && !name.isEmpty && name != "나" {
            return (name, profileUrl)
        }
        do {
            let profile = try await ProfileService.shared.fetchUserProfile(handle: handle)
            return (profile.username, profile.profileImageUrl)
        } catch {
            return (name, profileUrl)
        }
    }

    // MARK: - 그룹핑

    struct NotificationSection {
        let title: String
        let items: [NotificationData]
        var isOlder: Bool = false
    }

    func groupedNotifications() -> [NotificationSection] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!
        let weekAgoStart = calendar.date(byAdding: .day, value: -7, to: todayStart)!

        var today: [NotificationData] = [], yesterday: [NotificationData] = []
        var recent: [NotificationData] = [], older: [NotificationData] = []

        for n in notifications {
            let d = NotificationDateParser.parse(n.createdAt) ?? .distantPast
            if d >= todayStart { today.append(n) }
            else if d >= yesterdayStart { yesterday.append(n) }
            else if d >= weekAgoStart { recent.append(n) }
            else { older.append(n) }
        }

        var sections: [NotificationSection] = []
        if !today.isEmpty { sections.append(.init(title: "오늘", items: today)) }
        if !yesterday.isEmpty { sections.append(.init(title: "어제", items: yesterday)) }
        if !recent.isEmpty { sections.append(.init(title: "최근 7일", items: recent)) }
        if !older.isEmpty { sections.append(.init(title: "이전", items: older, isOlder: true)) }
        return sections
    }
}
