//
//  FriendRequestViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/28/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class FriendRequestViewModel: ObservableObject {
    @Published var requests: [ReceivedFriendRequest] = []
    @Published var isLoading = false

    func loadRequests() async {
        isLoading = true
        do {
            requests = try await FriendService.shared.getReceivedRequests()
        } catch {
            print("[FriendRequestView] 받은 요청 로드 실패: \(error)")
        }
        isLoading = false
    }

    func acceptRequest(_ request: ReceivedFriendRequest) {
        Task {
            do {
                try await FriendService.shared.processRequest(requestId: request.requestId, action: .approve)
                withAnimation(.easeInOut(duration: 0.3)) {
                    requests.removeAll { $0.id == request.id }
                }
            } catch {
                print("[FriendRequestView] 수락 실패: \(error)")
            }
        }
    }

    func rejectRequest(_ request: ReceivedFriendRequest) {
        Task {
            do {
                try await FriendService.shared.processRequest(requestId: request.requestId, action: .reject)
                withAnimation(.easeInOut(duration: 0.3)) {
                    requests.removeAll { $0.id == request.id }
                }
            } catch {
                print("[FriendRequestView] 거절 실패: \(error)")
            }
        }
    }
}
