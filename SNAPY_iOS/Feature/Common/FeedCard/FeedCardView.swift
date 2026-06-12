//
//  FeedCardView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/29/26.
//

import SwiftUI
import Kingfisher

struct FeedCardView: View {
    let albumId: Int
    let profileImageSource: ProfileImageSource
    let displayName: String
    let handle: String
    let date: String
    let photos: [FeedCardPhoto]

    var hasStory: Bool = false
    var isStorySeen: Bool = true

    @Binding var isLiked: Bool
    @Binding var likeCount: Int
    @Binding var commentCount: Int

    var onLike: (() -> Void)? = nil
    var onProfileImageTap: (() -> Void)? = nil
    var onNameTap: (() -> Void)? = nil

    @StateObject private var viewModel: FeedCardViewModel
    @State private var currentPage = 0
    @State private var showComments = false
    @State private var showLikeList = false
    @State private var showReport = false
    @State private var swappedPhotoIDs: Set<UUID> = []

    private var isMyPost: Bool {
        let myHandle = UserDefaults.standard.string(forKey: "myHandle") ?? ""
        return !myHandle.isEmpty && myHandle == handle
    }

    init(albumId: Int, profileImageSource: ProfileImageSource, displayName: String,
         handle: String, date: String, photos: [FeedCardPhoto],
         hasStory: Bool = false, isStorySeen: Bool = true,
         isLiked: Binding<Bool>, likeCount: Binding<Int>, commentCount: Binding<Int>,
         onLike: (() -> Void)? = nil, onProfileImageTap: (() -> Void)? = nil, onNameTap: (() -> Void)? = nil) {
        self.albumId = albumId
        self.profileImageSource = profileImageSource
        self.displayName = displayName
        self.handle = handle
        self.date = date
        self.photos = photos
        self.hasStory = hasStory
        self.isStorySeen = isStorySeen
        self._isLiked = isLiked
        self._likeCount = likeCount
        self._commentCount = commentCount
        self.onLike = onLike
        self.onProfileImageTap = onProfileImageTap
        self.onNameTap = onNameTap
        self._viewModel = StateObject(wrappedValue: FeedCardViewModel(albumId: albumId, handle: handle))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            profileHeader
            photoSlider
            pageIndicator
            actionButtons

            ImageCommentSection(albumId: albumId)
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
        }
        .sheet(isPresented: $showComments) {
            CommentSheetView(albumId: albumId, commentCount: $commentCount)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .fullScreenCover(isPresented: $showReport) {
            ReportView(reportType: .FEED, targetId: "\(albumId)")
        }
        .sheet(isPresented: $showLikeList) {
            LikeListSheet(albumId: albumId)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            guard albumId > 0, commentCount == 0 else { return }
            Task { commentCount = await viewModel.loadCommentCount() }
        }
    }

    // MARK: - 프로필 헤더

    private var profileHeader: some View {
        HStack(spacing: 14) {
            Button { onProfileImageTap?() } label: {
                profileImage
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .padding(3)
                    .overlay(storyRing)
            }

            Button { onNameTap?() } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    Text(handle).font(.system(size: 12)).foregroundColor(.customGray300)
                }
            }

            Spacer()
            Text(date).font(.system(size: 13)).foregroundColor(.customGray300)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    @ViewBuilder
    private var storyRing: some View {
        if hasStory {
            Circle().stroke(
                isStorySeen
                    ? AnyShapeStyle(Color.customGray500)
                    : AnyShapeStyle(LinearGradient(
                        colors: [Color(hex: "FFC83D"), Color(hex: "FF9F1C")],
                        startPoint: .topLeading, endPoint: .bottomTrailing)),
                lineWidth: 1.5)
        }
    }

    // MARK: - 사진 슬라이더

    private var photoSlider: some View {
        ZStack {
            TabView(selection: $currentPage) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                    draggablePhotoView(for: photo).tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            ForEach(viewModel.heartAnimations) { heart in
                Image("Heart_img").resizable().scaledToFit()
                    .frame(width: heart.size, height: heart.size)
                    .rotationEffect(.degrees(heart.rotation))
                    .scaleEffect(heart.scale).opacity(heart.opacity)
                    .position(heart.position)
            }
        }
        .frame(height: 540).contentShape(Rectangle())
        .onTapGesture(count: 2) { location in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            viewModel.triggerHeartAnimation(at: location)
            if !isLiked { isLiked = true; likeCount += 1; onLike?() }
        }
    }

    // MARK: - 페이지 인디케이터

    private var pageIndicator: some View {
        HStack(spacing: 5) {
            if photos.count > 1 {
                ForEach(0..<photos.count, id: \.self) { index in
                    Circle().fill(index == currentPage ? Color.MainYellow : Color.customGray300)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .frame(maxWidth: .infinity).frame(height: 6).padding(.vertical, 14)
    }

    // MARK: - 액션 버튼

    private var actionButtons: some View {
        HStack(spacing: 18) {
            HStack(spacing: 6) {
                Button {
                    if !isLiked { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                    isLiked.toggle(); likeCount += isLiked ? 1 : -1; onLike?()
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 24)).foregroundColor(isLiked ? .red : .white)
                }
                Button { showLikeList = true } label: {
                    Text("\(likeCount)").font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                }
            }

            HStack(spacing: 6) {
                Button { showComments = true } label: {
                    Image("Chat_icon").resizable().frame(width: 24, height: 24)
                }
                Text("\(commentCount)").font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
            }

            Button {
                let photo = photos.indices.contains(currentPage) ? photos[currentPage] : photos.first
                viewModel.shareFeed(profileImageSource: profileImageSource, displayName: displayName, date: date, photo: photo)
            } label: {
                Image(systemName: "paperplane").font(.system(size: 20)).foregroundColor(.white)
            }

            Spacer()

            // TODO: 임시 처리 — 내 피드에서는 메뉴 숨김. 피드 비활성화 API 추가 시 메뉴에 비활성화 옵션 넣을 예정
            if !isMyPost {
                Menu {
                    Button("신고", role: .destructive) { showReport = true }
                } label: {
                    Image(systemName: "ellipsis").font(.system(size: 20)).foregroundColor(.customGray300)
                }
            }
        }
        .padding(.horizontal, 14).padding(.bottom, 20)
    }

    // MARK: - 프로필 이미지

    @ViewBuilder
    private var profileImage: some View {
        switch profileImageSource {
        case .url(let urlString):
            if let url = URL(string: urlString) {
                KFImage(url).resizable()
                    .downsampling(size: CGSize(width: 72, height: 72))
                    .loadDiskFileSynchronously().cacheOriginalImage()
                    .placeholder { Color.customGray500 }.fade(duration: 0.15).scaledToFill()
            } else { defaultProfileImage }
        case .uiImage(let image):
            Image(uiImage: image).resizable().scaledToFill()
        case .asset(let name):
            Image(name).resizable().scaledToFill()
        case .none:
            defaultProfileImage
        }
    }

    private var defaultProfileImage: some View {
        Image("Profile_img").resizable().scaledToFill()
    }

    // MARK: - 사진

    @ViewBuilder
    private func draggablePhotoView(for photo: FeedCardPhoto) -> some View {
        let isSwapped = swappedPhotoIDs.contains(photo.id)

        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // 풀사이즈: back 이미지
                backImageView(photo.backImageUrl, asset: photo.assetName)
                    .frame(width: geo.size.width, height: geo.size.height).clipped()
                    .opacity(isSwapped ? 0 : 1)

                // 풀사이즈: front 이미지 (스왑 시 표시)
                if let frontUrl = photo.frontImageUrl, let url = URL(string: frontUrl) {
                    KFImage(url).resizable()
                        .downsampling(size: CGSize(width: 390, height: 540))
                        .placeholder { Color.customGray500 }.fade(duration: 0.15)
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height).clipped()
                        .opacity(isSwapped ? 1 : 0)
                }

                // PIP: 양쪽 이미지를 겹쳐서 크로스페이드
                if let frontUrl = photo.frontImageUrl, let fUrl = URL(string: frontUrl),
                   let backUrl = photo.backImageUrl, let bUrl = URL(string: backUrl) {
                    DraggablePIP(containerSize: geo.size, pipWidth: 120, pipHeight: 160, padding: 12) {
                        ZStack {
                            KFImage(fUrl).resizable().placeholder { Color(white: 0.2) }.fade(duration: 0.2).scaledToFill()
                                .opacity(isSwapped ? 0 : 1)
                            KFImage(bUrl).resizable().placeholder { Color(white: 0.2) }.fade(duration: 0.2).scaledToFill()
                                .opacity(isSwapped ? 1 : 0)
                        }
                    } onTap: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.15, dampingFraction: 1)) {
                            if swappedPhotoIDs.contains(photo.id) {
                                swappedPhotoIDs.remove(photo.id)
                            } else {
                                swappedPhotoIDs.insert(photo.id)
                            }
                        }
                    }
                } else if let frontUrl = photo.frontImageUrl, let url = URL(string: frontUrl) {
                    DraggablePIP(containerSize: geo.size, pipWidth: 120, pipHeight: 160, padding: 12) {
                        KFImage(url).resizable().placeholder { Color(white: 0.2) }.fade(duration: 0.2).scaledToFill()
                    }
                }

                // 시간대 라벨
                if let label = photo.mealLabel {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(label)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.ultraThinMaterial, in: Capsule())
                            .padding(12)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func backImageView(_ urlString: String?, asset: String?) -> some View {
        if let backUrl = urlString, let url = URL(string: backUrl) {
            KFImage(url).resizable()
                .downsampling(size: CGSize(width: 390, height: 540))
                .placeholder { Color.customGray500 }.fade(duration: 0.15)
                .scaledToFill().frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
        } else if let asset, !asset.isEmpty {
            Image(asset).resizable().scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
        } else {
            Color.customGray500
        }
    }
}
