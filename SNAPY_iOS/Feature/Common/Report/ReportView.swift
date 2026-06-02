//
//  ReportView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/8/26.
//

import SwiftUI

struct ReportView: View {
    var onDismiss: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ReportViewModel

    init(reportType: ReportType, targetId: String, onDismiss: (() -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: ReportViewModel(reportType: reportType, targetId: targetId))
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    if viewModel.isSubmitted {
                        closeButton
                        submittedView
                    } else {
                        headerView
                        policyText
                        reasonListView
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - 헤더

    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                Text(viewModel.titleText)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.textWhite)
                    .padding(.top, 20)
                Spacer()
                Button { dismiss(); onDismiss?() } label: {
                    Image(systemName: "xmark").font(.system(size: 20, weight: .medium)).foregroundColor(.textWhite)
                }
            }
            .padding(.horizontal, 22).padding(.top, 20).padding(.bottom, 12)
        }
    }

    private var policyText: some View {
        VStack(spacing: 0) {
            Text("신고는 익명으로 처리되며, 신고 내용은 상대방에게 전달되지 않습니다. 허위 신고 시 이용이 제한될 수 있습니다.")
                .font(.system(size: 13)).foregroundColor(.customGray300)
                .lineSpacing(6).frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22).padding(.top, 8).padding(.bottom, 16)

            Divider().background(Color.customGray500)
                .padding(.horizontal, 22).padding(.bottom, 10)
        }
    }

    private var closeButton: some View {
        HStack {
            Spacer()
            Button { dismiss(); onDismiss?() } label: {
                Image(systemName: "xmark").font(.system(size: 20, weight: .medium)).foregroundColor(.textWhite)
            }
        }
        .padding(.horizontal, 22).padding(.top, 20)
    }

    // MARK: - 사유 리스트

    private var reasonListView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(ReportReason.allCases) { reason in
                        Button {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                viewModel.submitReport(reason: reason)
                            }
                        } label: {
                            HStack {
                                Text(reason.rawValue).font(.system(size: 16)).foregroundColor(.textWhite)
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 14, weight: .medium)).foregroundColor(.customGray300)
                            }
                            .padding(.horizontal, 22).padding(.vertical, 20)
                        }
                    }
                }
            }
            Spacer()
        }
    }

    // MARK: - 접수 완료

    private var submittedView: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 56)).foregroundColor(.MainYellow)
                Text("신고가 접수되었습니다").font(.system(size: 20, weight: .bold)).foregroundColor(.textWhite)
                Text("검토 후 적절한 조치를 취하겠습니다.\n소중한 의견 감사합니다.")
                    .font(.system(size: 14)).foregroundColor(.customGray300)
                    .multilineTextAlignment(.center).lineSpacing(4)
            }
            Spacer()
            Button { dismiss(); onDismiss?() } label: {
                Text("확인").font(.system(size: 16, weight: .bold)).foregroundColor(.backgroundBlack)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(Color.MainYellow).cornerRadius(12)
            }
            .padding(.horizontal, 22).padding(.bottom, 34)
        }
    }
}

#Preview("Feed") { ReportView(reportType: .FEED, targetId: "123") }
#Preview("User") { ReportView(reportType: .USER, targetId: "user_handle") }
