//
//  StoryDetailViewModel.swift
//  SNAPY_iOS
//
//  Separated from StoryDetailView.swift
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class StoryDetailViewModel: ObservableObject {
    let stories: [StoryItem]
    let initialIndex: Int
    var onStorySeen: ((Int) -> Void)?

    @Published var currentUserIndex: Int = 0
    @Published var currentImageIndex: Int = 0
    @Published var progress: CGFloat = 0.0
    @Published var isPaused: Bool = false
    @Published var hideUI: Bool = false
    @Published var isLiked: Bool = false
    @Published var showHeartPop: Bool = false
    @Published var shareImage: UIImage? = nil
    @Published var likeUsers: [StoryLikeUserData] = []

    private var isLikeToggling = false
    private var timer: Timer?
    let autoAdvanceInterval: TimeInterval = 10.0
    private let timerTickInterval: TimeInterval = 0.05

    let myHandle = UserDefaults.standard.string(forKey: "myHandle") ?? ""

    var currentStory: StoryItem { stories[currentUserIndex] }
    var currentPhotos: [StoryPhotoSet] { currentStory.photos }

    init(stories: [StoryItem], initialIndex: Int, onStorySeen: ((Int) -> Void)?) {
        self.stories = stories
        self.initialIndex = initialIndex
        self.onStorySeen = onStorySeen
    }

    // MARK: - 초기화

    func onAppear(dismiss: DismissAction) {
        guard !stories.isEmpty, initialIndex < stories.count else { return }
        currentUserIndex = initialIndex
        currentImageIndex = stories[initialIndex].unseenStartIndex
        startTimer()
        onStorySeen?(stories[initialIndex].storyId)
        loadLikeStatus()
        loadLikesForMyStory()
    }

    func onDisappear() {
        stopTimer()
    }

    // MARK: - 타이머

    func startTimer() {
        stopTimer()
        progress = 0
        timer = Timer.scheduledTimer(withTimeInterval: timerTickInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, !self.isPaused else { return }
                self.progress += self.timerTickInterval / self.autoAdvanceInterval
                if self.progress >= 0.7 {
                    self.goToNext()
                }
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - 네비게이션

    var shouldDismiss = false

    func goToNext() {
        if currentImageIndex < currentPhotos.count - 1 {
            currentImageIndex += 1
            progress = 0
            loadLikeStatus()
        } else if currentUserIndex < stories.count - 1 {
            withAnimation(.easeInOut(duration: 0.35)) {
                currentUserIndex += 1
            }
            currentImageIndex = 0
            progress = 0
            onStorySeen?(stories[currentUserIndex].storyId)
            startTimer()
            loadLikeStatus()
        } else {
            shouldDismiss = true
        }
    }

    func goToPrevious() {
        if currentImageIndex > 0 {
            currentImageIndex -= 1
            progress = 0
            loadLikeStatus()
        } else if currentUserIndex > 0 {
            withAnimation(.easeInOut(duration: 0.35)) {
                currentUserIndex -= 1
            }
            currentImageIndex = stories[currentUserIndex].photos.count - 1
            progress = 0
            startTimer()
            loadLikeStatus()
        }
    }

    // MARK: - 프로그레스 바

    func barWidth(for index: Int, totalWidth: CGFloat) -> CGFloat {
        if index < currentImageIndex {
            return totalWidth
        } else if index == currentImageIndex {
            return totalWidth * progress
        }
        return 0
    }

    // MARK: - 좋아요

    func triggerLike() {
        guard !isLikeToggling else { return }

        let story = currentStory
        let photos = story.photos
        guard currentImageIndex < photos.count,
              let type = photos[currentImageIndex].albumType else { return }
        let storyId = photos[currentImageIndex].ownerStoryId ?? story.storyId

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        isLikeToggling = true
        let wasLiked = isLiked
        isLiked = !wasLiked

        if !wasLiked {
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    self.showHeartPop = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeOut(duration: 0.2)) {
                    self.showHeartPop = false
                }
            }
        }

        Task {
            do {
                let result = try await StoryService.shared.toggleLike(storyId: storyId, type: type)
                isLiked = result.liked
                StoryLikeCache.set(storyId: storyId, type: type.rawValue, liked: result.liked)
                isLikeToggling = false
            } catch {
                print("[StoryDetail] 좋아요 실패: \(error)")
                isLiked = wasLiked
                isLikeToggling = false
            }
        }
    }

    func loadLikeStatus() {
        isLikeToggling = false
        let story = currentStory
        let photos = story.photos
        guard currentImageIndex < photos.count,
              let type = photos[currentImageIndex].albumType else {
            isLiked = false
            return
        }
        let storyId = photos[currentImageIndex].ownerStoryId ?? story.storyId
        isLiked = StoryLikeCache.get(storyId: storyId, type: type.rawValue) ?? false
    }

    func loadLikesForMyStory() {
        let story = currentStory
        guard story.username == myHandle else { likeUsers = []; return }
        let photos = story.photos
        guard currentImageIndex < photos.count,
              let type = photos[currentImageIndex].albumType else { likeUsers = []; return }
        let storyId = photos[currentImageIndex].ownerStoryId ?? story.storyId

        Task {
            do {
                let users = try await StoryService.shared.fetchLikes(storyId: storyId, type: type)
                likeUsers = users.sorted { ($0.likedAt ?? "") > ($1.likedAt ?? "") }
            } catch {
                print("[StoryDetail] 좋아요 목록 조회 실패: \(error)")
            }
        }
    }

    // MARK: - 공유

    func shareStory() {
        let story = currentStory
        let photos = story.photos
        guard currentImageIndex < photos.count else { return }
        let photo = photos[currentImageIndex]

        isPaused = true
        Task {
            async let profileImg = downloadImage(from: story.profileImage.isImageURL ? story.profileImage : nil)
            async let backImg = downloadImage(from: photo.backImageUrl)
            async let frontImg = downloadImage(from: photo.frontImageUrl)

            let card = StoryShareCard(
                profileImage: await profileImg,
                displayName: story.displayName,
                handle: story.username,
                backImage: await backImg,
                frontImage: await frontImg
            )
            if let image = renderShareImage(card) {
                shareImage = image
            }
        }
    }

    // MARK: - 시간 텍스트

    func currentPhotoTimeText(for story: StoryItem, imageIndex: Int) -> String? {
        let photos = story.photos
        guard imageIndex < photos.count else { return story.relativeTimeText }
        let dateStr = photos[imageIndex].createdAt ?? story.createdAt
        guard let dateStr, !dateStr.isEmpty else { return nil }
        return relativeTime(from: dateStr)
    }

    private func relativeTime(from dateStr: String) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = iso.date(from: dateStr)
            ?? ISO8601DateFormatter().date(from: dateStr)
            ?? parseFlexible(dateStr)
        guard let date else { return "" }

        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "방금 전" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)분 전" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)시간 전" }
        let days = hours / 24
        return "\(days)일 전"
    }

    private func parseFlexible(_ str: String) -> Date? {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(identifier: "Asia/Seoul")
        for format in ["yyyy-MM-dd'T'HH:mm:ss.SSSSSS", "yyyy-MM-dd'T'HH:mm:ss"] {
            fmt.dateFormat = format
            if let d = fmt.date(from: str) { return d }
        }
        return nil
    }
}
