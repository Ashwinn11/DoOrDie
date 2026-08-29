import SwiftUI

/// Loops the exercise's 3 pose frames like a GIF — used wherever we want the
/// movement itself to read at a glance instead of a single static pose.
struct CyclingSVGView: View {
    let frameImageNames: [String]
    var interval: Double = 0.45

    @State private var index = 0

    var body: some View {
        Image(frameImageNames[index % frameImageNames.count])
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(interval))
                    withAnimation(.easeInOut(duration: 0.15)) {
                        index = (index + 1) % frameImageNames.count
                    }
                }
            }
    }
}
