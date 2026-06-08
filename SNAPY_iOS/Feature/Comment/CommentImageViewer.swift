//
//  CommentImageViewer.swift
//  SNAPY_iOS
//
//  Separated from CommentSheetView.swift
//

import SwiftUI

struct CommentImageViewer: View {
    let imageUrl: String

    var body: some View {
        ImageViewerView(
            image: nil,
            imageUrl: imageUrl,
            assetName: "Profile_img",
            isFreeForm: true
        )
    }
}

struct IdentifiableString: Identifiable {
    let value: String
    var id: String { value }
}
