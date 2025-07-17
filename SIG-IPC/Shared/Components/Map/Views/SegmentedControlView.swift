//
//  SegmentedControlView.swift
//  SIG-IPC
//
//  Created by jonathan calvin sutrisna on 17/07/25.
//

import SwiftUI

struct SegmentedControlView: View {
    @Binding var displayMode: DisplayModeEnum
    @Namespace private var animation
    var body: some View {
//        VStack {
//            Picker("Select DisplayMode", selection: $displayMode) {
//                ForEach(DisplayModeEnum.allCases) { displayMode in
//                    Text(displayMode.rawValue).tag(displayMode)
//                }
//            }
//            .pickerStyle(.segmented)
//            .padding()
//        }
        HStack(spacing: 0) {
            ForEach(DisplayModeEnum.allCases) { mode in
                ZStack {
                    if displayMode == mode {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .matchedGeometryEffect(id: "background", in: animation)
                            .padding(5)
                    }
                    
                    Text(mode.rawValue)
                        .fontWeight(.medium)
                        .font(.callout)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundColor(displayMode == mode ? .black : .primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .contentShape(Rectangle())
                }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        displayMode = mode
                    }
                }
            }
        }
        .frame(height: 36)
        .background(Color.gray.opacity(0.4))
        .clipShape(Capsule())
        .padding(.horizontal)
    }
}

#Preview {
    @Previewable @State var displayMode: DisplayModeEnum = .brand
    SegmentedControlView(displayMode: $displayMode)
}
