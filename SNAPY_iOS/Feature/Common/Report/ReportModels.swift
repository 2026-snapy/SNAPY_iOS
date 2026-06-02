//
//  ReportModels.swift
//  SNAPY_iOS
//
//  Separated from ReportView.swift
//

import Foundation

// MARK: - 신고 타입

enum ReportType: String, CaseIterable {
    case FEED
    case STORY
    case COMMENT
    case USER

    var serverKey: String {
        switch self {
        case .FEED:    return "FEED"
        case .STORY:   return "STORY"
        case .COMMENT: return "FEED"
        case .USER:    return "PROFILE"
        }
    }
}

// MARK: - 신고 사유

enum ReportReason: String, CaseIterable, Identifiable {
    case spam = "스팸 또는 사기"
    case nudity = "나체 또는 성적 콘텐츠"
    case hateSpeech = "혐오 발언 또는 상징"
    case violence = "폭력 또는 위험한 단체"
    case falseInfo = "거짓 정보"
    case bullying = "따돌림 또는 괴롭힘"
    case intellectual = "지식재산권 침해"
    case other = "기타"

    var id: String { rawValue }

    var serverKey: String {
        switch self {
        case .spam:         return "SPAM_OR_SCAM"
        case .nudity:       return "NUDITY_OR_SEXUAL_CONTENT"
        case .hateSpeech:   return "HATE_SPEECH_OR_SYMBOL"
        case .violence:     return "VIOLENCE_OR_DANGEROUS_ORGANIZATION"
        case .falseInfo:    return "FALSE_INFORMATION"
        case .bullying:     return "BULLYING_OR_HARASSMENT"
        case .intellectual: return "INTELLECTUAL_PROPERTY_INFRINGEMENT"
        case .other:        return "OTHER"
        }
    }
}
