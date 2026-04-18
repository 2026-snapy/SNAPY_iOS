//
//  StoryDetailView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/18/26.
//

import SwiftUI

struct StoryDetailView: View {
    let stories: [StoryItem]
    let initialIndex: Int

    @Environment(\.dismiss) private var dismiss

    // 현재 유저 스토리 인덱스
    @State private var currentUserIndex: Int = 0
    // 현재 사진 인덱스
    @State private var currentImageIndex: Int = 0
    // 타이머 진행률 (0.0 ~ 1.0)
    @State private var progress: CGFloat = 0.0
    // 타이머 일시정지
    @State private var isPaused: Bool = false
    // 핀치 줌 스케일
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    // 드래그로 유저 전환
    @State private var dragOffset: CGFloat = 0.0
    // UI 숨기기 (꾹 누를 때)
    @State private var hideUI: Bool = false
    // 좋아요
    @State private var isLiked: Bool = false

    // 타이머
    @State private var timer: Timer?

    private let autoAdvanceInterval: TimeInterval = 10.0
    private let timerTickInterval: TimeInterval = 0.05

    var currentStory: StoryItem {
        stories[currentUserIndex]
    }

    var currentImages: [String] {
        currentStory.images
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                // 스토리 이미지
                storyImageView(size: geo.size)
                    .scaleEffect(scale)
                    .gesture(pinchGesture)

                // UI 오버레이
                if !hideUI {
                    VStack(spacing: 0) {
                        // 상단 영역
                        topOverlay
                            .padding(.top, geo.safeAreaInsets.top)

                        Spacer()

                        // 하단 버튼
                        bottomBar
                            .padding(.bottom, geo.safeAreaInsets.bottom + 20)
                    }
                }

                // 좌우 탭 영역
                HStack(spacing: 0) {
                    // 왼쪽 탭 → 이전
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { goToPrevious() }
                        .frame(width: geo.size.width * 0.3)

                    Spacer()

                    // 오른쪽 탭 → 다음
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { goToNext() }
                        .frame(width: geo.size.width * 0.3)
                }
            }
            .ignoresSafeArea()
            // 꾹 누르기 제스처
            .simultaneousGesture(longPressGesture)
            // 유저 전환 드래그
            .gesture(horizontalDragGesture)
            .offset(x: dragOffset)
        }
        .statusBarHidden()
        .onAppear {
            currentUserIndex = initialIndex
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - 스토리 이미지

    @ViewBuilder
    private func storyImageView(size: CGSize) -> some View {
        let imageName = currentImages[currentImageIndex]
        if imageName.isImageURL, let url = URL(string: imageName) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure, .empty:
                    Color.customGray500
                @unknown default:
                    Color.customGray500
                }
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        } else {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
        }
    }

    // MARK: - 상단 오버레이

    private var topOverlay: some View {
        VStack(spacing: 10) {
            // 프로그레스 바
            HStack(spacing: 4) {
                ForEach(0..<currentImages.count, id: \.self) { index in
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // 배경 바
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 2.5)

                            // 진행 바
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white)
                                .frame(
                                    width: barWidth(for: index, totalWidth: geo.size.width),
                                    height: 2.5
                                )
                        }
                    }
                    .frame(height: 2.5)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)

            // 프로필 정보
            HStack(spacing: 12) {
                // 프로필 이미지
                profileImage
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                // 이름 + 아이디 (세로)
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentStory.displayName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)

                    Text(currentStory.username)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                Text("6시간")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()
            }
            .padding(.horizontal, 14)
        }
    }

    @ViewBuilder
    private var profileImage: some View {
        if currentStory.profileImage.isImageURL, let url = URL(string: currentStory.profileImage) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Color.customGray500
                }
            }
        } else {
            Image(currentStory.profileImage)
                .resizable()
                .scaledToFill()
        }
    }

    // MARK: - 하단 바

    private var bottomBar: some View {
        HStack(spacing: 20) {
            Spacer()

            // 하트 버튼
            Button {
                isLiked.toggle()
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 28))
                    .foregroundColor(isLiked ? .red : .white)
            }

            // 공유 버튼
            Button {
                // 공유 액션
            } label: {
                Image(systemName: "paperplane")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 프로그레스 바 너비 계산

    private func barWidth(for index: Int, totalWidth: CGFloat) -> CGFloat {
        if index < currentImageIndex {
            return totalWidth // 이미 본 것
        } else if index == currentImageIndex {
            return totalWidth * progress // 현재 진행 중
        } else {
            return 0 // 아직 안 본 것
        }
    }

    // MARK: - 타이머

    private func startTimer() {
        stopTimer()
        progress = 0
        timer = Timer.scheduledTimer(withTimeInterval: timerTickInterval, repeats: true) { _ in
            Task { @MainActor in
                guard !isPaused else { return }

                progress += timerTickInterval / autoAdvanceInterval
                if progress >= 1.0 {
                    goToNext()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - 이전/다음 네비게이션

    private func goToNext() {
        if currentImageIndex < currentImages.count - 1 {
            // 같은 유저의 다음 사진
            currentImageIndex += 1
            progress = 0
        } else if currentUserIndex < stories.count - 1 {
            // 다음 유저 스토리
            currentUserIndex += 1
            currentImageIndex = 0
            progress = 0
            isLiked = false
        } else {
            // 마지막 → 닫기
            dismiss()
        }
    }

    private func goToPrevious() {
        if currentImageIndex > 0 {
            // 같은 유저의 이전 사진
            currentImageIndex -= 1
            progress = 0
        } else if currentUserIndex > 0 {
            // 이전 유저 스토리의 마지막 사진
            currentUserIndex -= 1
            currentImageIndex = stories[currentUserIndex].images.count - 1
            progress = 0
            isLiked = false
        }
    }

    // MARK: - 유저 전환 (드래그)

    private func goToNextUser() {
        if currentUserIndex < stories.count - 1 {
            currentUserIndex += 1
            currentImageIndex = 0
            progress = 0
            isLiked = false
            startTimer()
        } else {
            dismiss()
        }
    }

    private func goToPreviousUser() {
        if currentUserIndex > 0 {
            currentUserIndex -= 1
            currentImageIndex = 0
            progress = 0
            isLiked = false
            startTimer()
        }
    }

    // MARK: - 제스처

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.2)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                switch value {
                case .second(true, _):
                    isPaused = true
                    hideUI = true
                default:
                    break
                }
            }
            .onEnded { _ in
                isPaused = false
                hideUI = false
                // 줌 해제
                if scale != 1.0 {
                    withAnimation(.easeOut(duration: 0.2)) {
                        scale = 1.0
                        lastScale = 1.0
                    }
                }
            }
    }

    private var pinchGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                isPaused = true
                hideUI = true
                scale = lastScale * value.magnification
            }
            .onEnded { _ in
                lastScale = scale
                if scale < 1.0 {
                    withAnimation(.easeOut(duration: 0.2)) {
                        scale = 1.0
                        lastScale = 1.0
                    }
                }
                isPaused = false
                hideUI = false
            }
    }

    private var horizontalDragGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { value in
                // 줌 중에는 드래그 무시
                guard scale <= 1.0 else { return }
                dragOffset = value.translation.width
            }
            .onEnded { value in
                guard scale <= 1.0 else {
                    dragOffset = 0
                    return
                }

                let threshold: CGFloat = 80
                withAnimation(.easeOut(duration: 0.25)) {
                    if value.translation.width < -threshold {
                        // 왼쪽으로 스와이프 → 다음 유저
                        dragOffset = 0
                        goToNextUser()
                    } else if value.translation.width > threshold {
                        // 오른쪽으로 스와이프 → 이전 유저
                        dragOffset = 0
                        goToPreviousUser()
                    } else {
                        dragOffset = 0
                    }
                }
            }
    }
}

// MARK: - Preview

#Preview("StoryDetail") {
    StoryDetailView(
        stories: [
            StoryItem(profileImage: "Profile_img", bannerImage: "Mock_img1", displayName: "은찬", username: "silver_c_Id", images: ["Mock_img1", "Mock_img2", "Mock_img3"], isSeen: false),
            StoryItem(profileImage: "Mock_img1", bannerImage: "Mock_img2", displayName: "민수", username: "user_02", images: ["Mock_img2", "Mock_img4"], isSeen: false),
        ],
        initialIndex: 0
    )
}
