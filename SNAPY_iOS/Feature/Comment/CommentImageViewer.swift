//
//  CommentImageViewer.swift
//  SNAPY_iOS
//
//  Separated from CommentSheetView.swift
//

import SwiftUI
import Kingfisher

struct CommentImageViewer: View {
    let imageUrl: String
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black
                .opacity(1.0 - min(abs(dragOffset.height) / 300.0, 0.5))
                .ignoresSafeArea()

            KFImage(URL(string: imageUrl))
                .resizable()
                .placeholder {
                    ProgressView().tint(.white)
                }
                .fade(duration: 0.2)
                .scaledToFit()
                .scaleEffect(scale)
                .offset(x: offset.width, y: offset.height + dragOffset.height)
                .opacity(1.0 - min(abs(dragOffset.height) / 300.0, 0.5))
                .gesture(
                    MagnifyGesture()
                        .onChanged { value in
                            scale = lastScale * value.magnification
                        }
                        .onEnded { _ in
                            lastScale = scale
                            if scale < 1.0 {
                                withAnimation(.spring()) {
                                    scale = 1.0
                                    lastScale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            if scale > 1.0 {
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            } else {
                                dragOffset = value.translation
                            }
                        }
                        .onEnded { _ in
                            if scale > 1.0 {
                                lastOffset = offset
                            } else {
                                if abs(dragOffset.height) > 120 {
                                    dismiss()
                                } else {
                                    withAnimation(.spring()) {
                                        dragOffset = .zero
                                    }
                                }
                            }
                        }
                )
                .simultaneousGesture(
                    TapGesture(count: 2)
                        .onEnded {
                            withAnimation(.spring()) {
                                if scale > 1.0 {
                                    scale = 1.0
                                    lastScale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2.5
                                    lastScale = 2.5
                                }
                            }
                        }
                )
        }
    }
}

struct IdentifiableString: Identifiable {
    let value: String
    var id: String { value }
}
