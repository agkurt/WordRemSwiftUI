import SwiftUI
import Lottie

struct MascotAnimationViewTest: View {
    @State private var dotLottieFile: DotLottieFile?

    var body: some View {
        Group {
            if let dotLottieFile = dotLottieFile {
                LottieView(dotLottie: dotLottieFile)
                    .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
            } else {
                Color.clear
                    .onAppear {
                        DotLottieFile.named("reeny_waving") { result in
                            if case .success(let file) = result {
                                self.dotLottieFile = file
                            }
                        }
                    }
            }
        }
    }
}
