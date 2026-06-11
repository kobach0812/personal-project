import Foundation
import Testing
@testable import PlaySnapp

// MARK: - Fixture helpers

private let now = Date(timeIntervalSince1970: 1_750_000_000)

private func play(
    _ id: String,
    sender: String = "Alice",
    daysAgo: Double = 0,
    reactions: [String: Int] = [:]
) -> Play {
    Play(
        id: id,
        squadID: "sq1",
        senderID: sender.lowercased(),
        senderName: sender,
        mediaType: .photo,
        mediaURL: URL(string: "https://example.com/\(id).jpg")!,
        storagePath: nil,
        thumbnailURL: nil,
        caption: nil,
        durationSeconds: nil,
        reactionSummary: reactions,
        currentUserReaction: nil,
        createdAt: now.addingTimeInterval(-daysAgo * 86_400)
    )
}

private let squad = Squad(
    id: "sq1", name: "Tuesday Pickleball", createdBy: "u1",
    memberIDs: ["u1", "u2"], inviteCode: "ABC123", createdAt: now
)

// MARK: - Tests

struct SquadRecapBuilderTests {

    @Test
    func emptyFeed_producesZeroCountsAndNoTopPlay() {
        let recap = SquadRecapBuilder.build(plays: [], squad: squad, now: now)
        #expect(recap.playCount == 0)
        #expect(recap.reactionCount == 0)
        #expect(recap.topPlay == nil)
        #expect(recap.topPosterName == nil)
        #expect(recap.squadName == "Tuesday Pickleball")
    }

    @Test
    func playsOlderThanSevenDays_areExcluded() {
        let plays = [
            play("recent", daysAgo: 2),
            play("boundary", daysAgo: 6.9),
            play("old", daysAgo: 7.1),
        ]
        let recap = SquadRecapBuilder.build(plays: plays, squad: squad, now: now)
        #expect(recap.playCount == 2)
    }

    @Test
    func futureDatedPlays_areIgnored() {
        let plays = [play("today", daysAgo: 0), play("future", daysAgo: -1)]
        let recap = SquadRecapBuilder.build(plays: plays, squad: squad, now: now)
        #expect(recap.playCount == 1)
    }

    @Test
    func reactionCount_sumsAllEmojiTallies() {
        let plays = [
            play("a", reactions: ["🔥": 2, "💪": 1]),
            play("b", reactions: ["👏": 3]),
        ]
        let recap = SquadRecapBuilder.build(plays: plays, squad: squad, now: now)
        #expect(recap.reactionCount == 6)
    }

    @Test
    func topPlay_isThePlayWithMostReactions() {
        let plays = [
            play("a", reactions: ["🔥": 1]),
            play("b", reactions: ["🔥": 4]),
            play("c", reactions: ["💪": 2]),
        ]
        let recap = SquadRecapBuilder.build(plays: plays, squad: squad, now: now)
        #expect(recap.topPlay?.id == "b")
    }

    @Test
    func topPlay_reactionTie_breaksByNewest() {
        let plays = [
            play("older", daysAgo: 3, reactions: ["🔥": 2]),
            play("newer", daysAgo: 1, reactions: ["💪": 2]),
        ]
        let recap = SquadRecapBuilder.build(plays: plays, squad: squad, now: now)
        #expect(recap.topPlay?.id == "newer")
    }

    @Test
    func topPoster_isTheSenderWithMostPlays() {
        let plays = [
            play("a", sender: "Alice"),
            play("b", sender: "Bob"),
            play("c", sender: "Bob"),
        ]
        let recap = SquadRecapBuilder.build(plays: plays, squad: squad, now: now)
        #expect(recap.topPosterName == "Bob")
    }

    @Test
    func topPoster_tie_breaksByNameAscending() {
        let plays = [play("a", sender: "Zoe"), play("b", sender: "Alice")]
        let recap = SquadRecapBuilder.build(plays: plays, squad: squad, now: now)
        #expect(recap.topPosterName == "Alice")
    }

    @Test
    func window_isSevenDaysEndingNow() {
        let recap = SquadRecapBuilder.build(plays: [], squad: squad, now: now)
        #expect(recap.weekEnd == now)
        #expect(recap.weekStart == now.addingTimeInterval(-7 * 86_400))
    }
}
