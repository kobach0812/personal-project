import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif

enum FirebaseConfiguration {
    static func configure() {
        #if canImport(FirebaseCore)
        guard FirebaseApp.app() == nil else {
            return
        }

        FirebaseApp.configure()
        assert(
            FirebaseApp.app() != nil,
            "Firebase failed to initialize. Check GoogleService-Info.plist target membership."
        )
        #endif
    }
}
