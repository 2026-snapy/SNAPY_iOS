//
//  OAuthPhoneView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/7/26.
//

import SwiftUI

struct OAuthPhoneView: View {
    var onNext: () -> Void
    var onBack: (() -> Void)? = nil
    @StateObject private var viewModel = OAuthPhoneViewModel()
    @State private var phone = ""
    @State private var code = ""

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // 뒤로가기
                if let onBack {
                    HStack {
                        Button {
                            TokenStorage.clear()
                            onBack()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.textWhite)
                                .frame(width: 40, height: 40)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }

                // 헤더
                HStack(spacing: 12) {
                    Image("Login_Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 34)
                    Image("SNAPY_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 130, height: 28)
                }
                .padding(.top, onBack != nil ? 16 : 34)
                .padding(.horizontal, 24)

                Text("서비스 이용을 위해\n휴대폰 번호를 등록해주세요")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.textWhite)
                    .lineSpacing(6)
                    .padding(.top, 40)
                    .padding(.horizontal, 24)

                Text("친구 추천 및 연락처 동기화에 사용됩니다")
                    .font(.system(size: 14))
                    .foregroundColor(Color.customGray300)
                    .padding(.top, 12)
                    .padding(.horizontal, 24)

                VStack(spacing: 20) {
                    SnapyTextField(
                        label: "휴대폰 번호",
                        placeholder: "01012345678",
                        text: $phone,
                        keyboardType: .phonePad
                    )
                    .disabled(viewModel.codeSent)
                    .opacity(viewModel.codeSent ? 0.6 : 1.0)

                    if viewModel.codeSent {
                        SnapyTextField(
                            label: "인증번호",
                            placeholder: "6자리 인증번호 입력",
                            text: $code,
                            keyboardType: .numberPad
                        )

                        Button {
                            Task { await viewModel.requestCode(phone: phone) }
                        } label: {
                            Text("인증번호 재발송")
                                .font(.system(size: 13))
                                .foregroundColor(.MainYellow)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.top, 12)
                        .padding(.horizontal, 24)
                }

                Spacer()

                if viewModel.codeSent {
                    SnapyButton(title: viewModel.isLoading ? "확인 중..." : "확인", isEnabled: isValidCode && !viewModel.isLoading) {
                        Task {
                            let success = await viewModel.verifyAndRegister(phone: phone, code: code)
                            if success { onNext() }
                        }
                    }
                    .padding(.bottom, 24)
                } else {
                    SnapyButton(title: viewModel.isLoading ? "발송 중..." : "인증번호 받기", isEnabled: isValidPhone && !viewModel.isLoading) {
                        Task { await viewModel.requestCode(phone: phone) }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    private var isValidPhone: Bool {
        phone.filter { $0.isNumber }.count == 11
    }

    private var isValidCode: Bool {
        code.filter { $0.isNumber }.count == 6
    }

}

struct OAuthPhoneView_Previews: PreviewProvider {
    static var previews: some View {
        OAuthPhoneView(onNext: {})
    }
}
