//
//  CustomPopupView.swift
//  SIG-IPC
//
//  Created by jonathan calvin sutrisna on 18/07/25.
//

import SwiftUI
struct CustomPopupData {
    var title: String
    var subtitle: String
    var onClose: () -> Void
    var onClick: () -> Void
}
struct CustomPopupView: View {
    let data: CustomPopupData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(data.title)
                        .font(.headline)
                    Spacer()
                    Button(action: data.onClose) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
                
                Text(data.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                // Aksi visit brand
            }) {
                HStack {
                    Image(systemName: "doc.plaintext")
                    Text("Visit Brand Profile")
                        .font(.caption)
                }
                .padding(8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 175)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 6)
    }
}

#Preview {
    let data: CustomPopupData = CustomPopupData(
            title: "test", subtitle: "laa",
            onClose: {
                return
            },
            onClick: {
                return
            }
        )
    CustomPopupView(data: data)
}
