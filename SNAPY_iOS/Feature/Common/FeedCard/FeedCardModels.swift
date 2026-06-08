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
    let type: String?

    init(frontImageUrl: String?, backImageUrl: String?, assetName: String?, type: String? = nil) {
        self.frontImageUrl = frontImageUrl
        self.backImageUrl = backImageUrl
        self.assetName = assetName
        self.type = type
    }

    var mealLabel: String? {
        guard let type else { return nil }
        switch type {
        case "MORNING": return "아침"
        case "LUNCH":   return "점심"
        case "DINNER":  return "저녁"
        case "FREE_1":  return "추가1"
        case "FREE_2":  return "추가2"
        default: return nil
        }
    }
}

struct HeartAnimation: Identifiable {
    let id = UUID()
    let position: CGPoint
    let rotation: Double = Double.random(in: -30...30)
    var size: CGFloat = 60
    var scale: CGFloat = 0.0
    var opacity: Double = 0.0
}
