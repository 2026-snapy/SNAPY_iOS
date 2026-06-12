//
//  AlbumPhotoCard.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/29/26.
//

import SwiftUI
import Kingfisher

struct AlbumPhotoCard: View {
    let photo: PhotoData

    @State private var isSwapped = false

    var body: some View {
        VStack(spacing: 8) {
            // 듀얼캠 사진
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    // 풀사이즈: back 이미지
                    KFImage(URL(string: photo.backImageUrl ?? ""))
                        .resizable()
                        .placeholder {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(white: 0.15))
                                .overlay(ProgressView().tint(.white))
                        }
                        .fade(duration: 0.2)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .opacity(isSwapped ? 0 : 1)

                    // 풀사이즈: front 이미지 (스왑 시 표시)
                    KFImage(URL(string: photo.frontImageUrl ?? ""))
                        .resizable()
                        .placeholder {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(white: 0.15))
                                .overlay(ProgressView().tint(.white))
                        }
                        .fade(duration: 0.2)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .opacity(isSwapped ? 1 : 0)

                    // PIP: 양쪽 이미지를 겹쳐서 크로스페이드
                    if photo.frontImageUrl != nil && photo.backImageUrl != nil {
                        DraggablePIP(
                            containerSize: geo.size,
                            pipWidth: 120,
                            pipHeight: 160,
                            padding: 12
                        ) {
                            ZStack {
                                KFImage(URL(string: photo.frontImageUrl ?? ""))
                                    .resizable()
                                    .placeholder { Color(white: 0.2).overlay(ProgressView().tint(.white)) }
                                    .fade(duration: 0.2)
                                    .aspectRatio(contentMode: .fill)
                                    .opacity(isSwapped ? 0 : 1)
                                KFImage(URL(string: photo.backImageUrl ?? ""))
                                    .resizable()
                                    .placeholder { Color(white: 0.2).overlay(ProgressView().tint(.white)) }
                                    .fade(duration: 0.2)
                                    .aspectRatio(contentMode: .fill)
                                    .opacity(isSwapped ? 1 : 0)
                            }
                        } onTap: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.15, dampingFraction: 1)) {
                                isSwapped.toggle()
                            }
                        }
                    } else if photo.frontImageUrl != nil {
                        DraggablePIP(
                            containerSize: geo.size,
                            pipWidth: 120,
                            pipHeight: 160,
                            padding: 12
                        ) {
                            KFImage(URL(string: photo.frontImageUrl ?? ""))
                                .resizable()
                                .placeholder { Color(white: 0.2).overlay(ProgressView().tint(.white)) }
                                .fade(duration: 0.2)
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                }
            }
            .frame(width: 330, height: 430)

            Text(photo.capturedTimeText ?? (photo.albumSlot?.name ?? photo.type))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.customGray300)
                .padding(.top, 14)
        }
    }
}
