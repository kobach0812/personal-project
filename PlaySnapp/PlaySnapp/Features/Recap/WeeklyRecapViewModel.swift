import Combine
import UIKit

@MainActor
final class WeeklyRecapViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case empty
        case ready(SquadRecap)
        case error
    }

    @Published var state: State = .loading
    /// Top play photo, pre-loaded because `AsyncImage` never resolves inside `ImageRenderer`.
    @Published var heroImage: UIImage?

    func load(playService: PlayServicing, squadService: SquadServicing) async {
        state = .loading
        heroImage = nil
        do {
            guard let squad = try await squadService.fetchCurrentSquad() else {
                state = .error
                return
            }
            let plays = try await playService.fetchFeed()
            let recap = SquadRecapBuilder.build(plays: plays, squad: squad)
            guard recap.playCount > 0 else {
                state = .empty
                return
            }
            state = .ready(recap)
            await loadHeroImage(for: recap.topPlay)
        } catch {
            state = .error
        }
    }

    /// Best-effort — a missing photo falls back to the card's gradient hero.
    private func loadHeroImage(for play: Play?) async {
        guard let url = play?.thumbnailURL ?? play?.mediaURL else { return }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }
        heroImage = UIImage(data: data)
    }
}
