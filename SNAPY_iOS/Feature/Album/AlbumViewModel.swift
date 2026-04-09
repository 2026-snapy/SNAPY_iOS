//
//  AlbumViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

import Foundation
import SwiftUI
import Combine

// 빈 슬롯의 상태
enum EmptySlotState {
    case canTake
    case missed
}

@MainActor
final class AlbumViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var currentPage: Int = TimeSlot.current.rawValue
    @Published var slideDirection: SlideDirection = .none

    enum SlideDirection {
        case none, left, right
    }

    var dateString: String {
        selectedDate.albumDateString
    }

    /// 오늘 앨범에서 해당 슬롯의 사진 (서버 응답 기반)
    func photo(for slot: AlbumSlot) -> PhotoData? {
        guard Calendar.current.isDateInToday(selectedDate) else { return nil }
        return PhotoStore.shared.todayPhoto(for: slot)
    }

    var streakCount: Int {
        guard Calendar.current.isDateInToday(selectedDate) else { return 0 }
        return min(PhotoStore.shared.todayPhotoCount, 5)
    }

    /// 찍을 수 있냐 없냐 여부
    func emptySlotState(for slot: AlbumSlot) -> EmptySlotState {
        let isToday = Calendar.current.isDateInToday(selectedDate)

        // 과거 날짜 missed
        if !isToday {
            return .missed
        }

        let currentSlot = TimeSlot.current

        switch slot {
        case .morning:
            return currentSlot == .morning ? .canTake : .missed
        case .afternoon:
            return currentSlot == .evening ? .missed : .canTake
        case .evening:
            return .canTake
        case .extra1, .extra2:
            let count = PhotoStore.shared.todayPhotoCount
            return count < 5 ? .canTake : .missed
        }
    }

    func goToPreviousDay() {
        slideDirection = .right
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        }
    }

    func goToNextDay() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        if tomorrow <= Date() {
            slideDirection = .left
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedDate = tomorrow
            }
        }
    }

    /// 화면 진입 / 새로고침 시 호출 — 오늘 앨범을 서버에서 다시 받아온다.
    func refreshToday() async {
        await PhotoStore.shared.loadToday()
    }
}
