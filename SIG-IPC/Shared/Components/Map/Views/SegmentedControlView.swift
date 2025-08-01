import SwiftUI

struct SegmentedControlView: View {
    @Binding var displayMode: DisplayModeEnum
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(DisplayModeEnum.allCases) { mode in
                ZStack {
                    if displayMode == mode {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.white)
                            .matchedGeometryEffect(id: "background", in: animation)
                            .padding(5)
                    }
                    
                    Text(mode.rawValue)
                        .fontWeight(.medium)
                        .font(.callout)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(displayMode == mode ? .black : .primary)
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
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .padding(.horizontal)
    }
}

#Preview {
    @Previewable @State var displayMode: DisplayModeEnum = .brand
    SegmentedControlView(displayMode: $displayMode)
}
