//
//  ReportViewModel.swift
//  SNAPY_iOS
//
//  Separated from ReportView.swift
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ReportViewModel: ObservableObject {
    let reportType: ReportType
    let targetId: String

    @Published var selectedReason: ReportReason? = nil
    @Published var isSubmitted = false

    init(reportType: ReportType, targetId: String) {
        self.reportType = reportType
        self.targetId = targetId
    }

    var titleText: String {
        switch reportType {
        case .FEED:    return "이 게시물을 신고하는 이유"
        case .STORY:   return "이 스토리를 신고하는 이유"
        case .COMMENT: return "이 댓글을 신고하는 이유"
        case .USER:    return "이 사용자를 신고하는 이유"
        }
    }

    func submitReport(reason: ReportReason) {
        selectedReason = reason
        Task {
            do {
                if reportType == .USER {
                    try await ReportService.shared.report(
                        targetType: reportType.serverKey,
                        userHandle: targetId,
                        reason: reason.serverKey
                    )
                } else {
                    guard let id = Int64(targetId) else { return }
                    try await ReportService.shared.report(
                        targetType: reportType.serverKey,
                        targetId: id,
                        reason: reason.serverKey
                    )
                }
            } catch {
                print("[Report] 신고 접수 실패: \(error)")
            }
            withAnimation(.easeInOut(duration: 0.3)) {
                isSubmitted = true
            }
        }
    }
}
