import SwiftUI

struct CompanionFloatingButton: View {
    @State private var showCompanion = false
    @State private var isPulsing = false

    var body: some View {
        Button {
            showCompanion = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color.appPrimary)
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.appPrimary.opacity(0.4), radius: 8, y: 4)

                Circle()
                    .stroke(Color.appPrimary.opacity(0.3), lineWidth: 2)
                    .frame(width: 56, height: 56)
                    .scaleEffect(isPulsing ? 1.3 : 1.0)
                    .opacity(isPulsing ? 0 : 1)

                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }
        }
        .sheet(isPresented: $showCompanion) {
            CompanionView()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGray6)
            .ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()
                CompanionFloatingButton()
                    .padding(.trailing, 16)
                    .padding(.bottom, 90)
            }
        }
    }
}
