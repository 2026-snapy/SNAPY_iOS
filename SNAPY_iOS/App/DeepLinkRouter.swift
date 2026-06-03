import Foundation
import Combine

@MainActor
final class DeepLinkRouter: ObservableObject {
    static let shared = DeepLinkRouter()

    enum Destination: Equatable {
        case album(id: Int, handle: String?)
        case story(id: Int)
        case profile(handle: String)
    }

    @Published var pendingDestination: Destination?

    /// Universal Link 또는 커스텀 URL Scheme을 파싱하여 목적지 설정
    /// Universal Link: https://snapy.krafte.net/share/album/138
    /// Custom Scheme:  messiofcoding://share/album/138
    ///                 messiofcoding://story/132
    ///                 messiofcoding://album/329
    ///                 messiofcoding://profile/kwonjh
    func handleURL(_ url: URL) {
        print("[DeepLink] handleURL 호출: \(url.absoluteString)")
        // host가 path 역할을 하는 경우 (messiofcoding://story/132)
        // → host = "story", path = "/132"
        // host가 도메인인 경우 (https://snapy.krafte.net/share/album/138)
        // → host = "snapy.krafte.net", path = "/share/album/138"

        var pathComponents: [String]

        if url.scheme == "messiofcoding" {
            // 커스텀 스킴: messiofcoding://story/132 또는 messiofcoding://share/story/132
            let host = url.host ?? ""
            let pathParts = url.path.split(separator: "/").map(String.init)
            pathComponents = [host] + pathParts
        } else {
            // Universal Link: https://snapy.krafte.net/share/album/138
            pathComponents = url.path.split(separator: "/").map(String.init)
        }

        // share/album/{id}?handle=xxx
        if let idx = pathComponents.firstIndex(of: "album"),
           idx + 1 < pathComponents.count,
           let id = Int(pathComponents[idx + 1]) {
            let handle = URLComponents(string: url.absoluteString)?
                .queryItems?.first(where: { $0.name == "handle" })?.value
            print("[DeepLink] 앨범 딥링크 → albumId=\(id), handle=\(handle ?? "nil")")
            pendingDestination = .album(id: id, handle: handle)
            return
        }

        // share/story/{id}
        if let idx = pathComponents.firstIndex(of: "story"),
           idx + 1 < pathComponents.count,
           let id = Int(pathComponents[idx + 1]) {
            pendingDestination = .story(id: id)
            return
        }

        // profile/{handle}
        if let idx = pathComponents.firstIndex(of: "profile"),
           idx + 1 < pathComponents.count {
            pendingDestination = .profile(handle: pathComponents[idx + 1])
            return
        }
    }

    func clearDestination() {
        pendingDestination = nil
    }
}
