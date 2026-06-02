//
//  FeedCardModels.swift
//  SNAPY_iOS
//
//  Separated from FeedCardView.swift
//

import SwiftUI

enum ProfileImageSource {
    case url(String)
    case uiImage(UIImage)
    case asset(String)
    case none
}

struct FeedCardPhoto: Identifiable {
    let id = UUID()
    let frontImageUrl: String?
    let backImageUrl: String?
    let assetName: String?
}

struct HeartAnimation: Identifiable {
    let id = UUID()
    let position: CGPoint
    let rotation: Double = Double.random(in: -30...30)
    var size: CGFloat = 60
    var scale: CGFloat = 0.0
    var opacity: Double = 0.0
}
