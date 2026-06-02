//
//  StreakSheet.swift
//  SNAPY_iOS
//
//  Separated from ProfileHeaderView.swift
//

import SwiftUI

struct StreakSheet: View {
    let currentStreak: Int
    let maxStreak: Int

    var body: some View {
        VStack(spacing: 50) {
            Spacer().frame(height: 10)

            Text("스트릭")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.textWhite)

            HStack(spacing: -20) {
                VStack(spacing: 16) {
                    Text("현재 스트릭")
                        .font(.system(size: 15))
                        .foregroundColor(.customGray300)
                    HStack(spacing: 10) {
                        Image(currentStreak >= 5 ? "Strick_sequence_fire" : "Strick_fire")
                            .resizable().scaledToFit().frame(height: 42)
                        Text("\(currentStreak)일")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.textWhite)
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 16) {
                    Text("최대 스트릭")
                        .font(.system(size: 15))
                        .foregroundColor(.customGray300)
                    HStack(spacing: 10) {
                        Image(maxStreak >= 5 ? "Strick_sequence_fire" : "Strick_fire")
                            .resizable().scaledToFit().frame(height: 42)
                        Text("\(maxStreak)일")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.textWhite)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
