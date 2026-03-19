//
//  SNAPYButton.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/17/26.
//

import SwiftUI

struct SignUpButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isEnabled ? Color.textWhite : Color.customGray500)
                .foregroundColor(isEnabled ? Color.backgroundBlack : Color.textWhite)
                .cornerRadius(28)
        }
        .disabled(!isEnabled)
        .padding(.horizontal, 24)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

struct SignUpButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            SignUpButton(title: "확인", action: {})
        }
    }
}
