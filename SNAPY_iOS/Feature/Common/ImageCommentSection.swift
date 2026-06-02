//
//  ImageCommentSection.swift
//  SNAPY_iOS
//
//  Separated from FeedCardView.swift
//

import SwiftUI
import Kingfisher
import PhotosUI

struct ImageCommentSection: View {
    let albumId: Int
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var imageUrls: [String] = []
    @State private var isUploading = false

    var body: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Circle()
                    .stroke(Color.customGray300, style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Group {
                            if isUploading {
                                ProgressView()
                                    .tint(.customGray300)
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.customGray300)
                            }
                        }
                    )
            }
            .disabled(isUploading)
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task { await uploadPickedImage(item: newItem) }
                selectedPhotoItem = nil
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(imageUrls, id: \.self) { urlString in
                        if let url = URL(string: urlString) {
                            KFImage(url)
                                .resizable()
                                .placeholder { Color.customDarkGray }
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                        }
                    }
                }
            }
        }
        .onAppear {
            Task { await loadImageComments() }
        }
    }

    private func uploadPickedImage(item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        isUploading = true
        do {
            _ = try await CommentService.shared.uploadImage(albumId: albumId, image: image)
            await loadImageComments()
        } catch {
            print("[ImageCommentSection] 업로드 실패: \(error)")
        }
        isUploading = false
    }

    private func loadImageComments() async {
        guard albumId > 0 else { return }
        do {
            let result = try await CommentService.shared.fetchComments(albumId: albumId, size: 20)
            imageUrls = result.content
                .filter { $0.type == "IMAGE" }
                .compactMap { $0.imageUrl }
        } catch {
            print("[ImageCommentSection] 로드 실패: \(error)")
        }
    }
}
