import SwiftUI

struct SuccessToast: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(12)
        .background(Color.statusSuccess)
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}
