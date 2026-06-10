import SwiftUI

struct BracketDetailView: View {
    let bracket: BracketTournament
    let currentUser: AppUser?

    @EnvironmentObject private var env: AppEnvironment
    @StateObject private var vm = BracketDetailViewModel()
    @State private var scoreEntry: ScoreEntryContext?
    @State private var setEntry: SetEntryContext?
    @State private var showConfigureKnockout = false

    var body: some View {
        content
        .tint(ThemeColor.primary)
        .navigationTitle(bracket.title.isEmpty ? "Bracket" : bracket.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            vm.start(bracket: bracket,
                     currentUser: currentUser,
                     service: env.bracketTournamentService)
        }
        .onDisappear { vm.cancel() }
        .sheet(item: $scoreEntry) { ctx in
            GroupScoreEntrySheet(
                teamAName: vm.teamName(ctx.match.teamAID, in: ctx.group),
                teamBName: vm.teamName(ctx.match.teamBID, in: ctx.group)
            ) { a, b in
                Task { await vm.recordResult(
                    groupID: ctx.group.id,
                    matchID: ctx.match.id,
                    scoreA: a, scoreB: b
                ) }
            }
        }
        .sheet(isPresented: $showConfigureKnockout) {
            if let live = vm.bracket {
                ConfigureKnockoutSheet(groups: live.groups) { advanceCounts, bestOf in
                    Task { await vm.configureKnockout(advanceCounts: advanceCounts, bestOf: bestOf) }
                }
            }
        }
        .sheet(item: $setEntry) { ctx in
            KnockoutSetEntrySheet(
                teamAName: vm.teamName(ctx.match.teamAID),
                teamBName: vm.teamName(ctx.match.teamBID),
                existingSets: ctx.match.sets,
                setsToWin: vm.setsToWin
            ) { set in
                Task { await vm.recordKnockoutSet(matchID: ctx.match.id, set: set) }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if vm.knockoutConfigured {
            BracketKnockoutView(vm: vm) { match in
                setEntry = SetEntryContext(match: match)
            }
        } else {
            BracketGroupStageView(
                vm: vm,
                onEnterScore: { group, match in
                    scoreEntry = ScoreEntryContext(group: group, match: match)
                },
                onConfigureKnockout: { showConfigureKnockout = true }
            )
        }
    }
}

// MARK: - Sheet context

private struct ScoreEntryContext: Identifiable {
    let group: BracketGroup
    let match: GroupMatch
    var id: String { match.id }
}

private struct SetEntryContext: Identifiable {
    let match: KnockoutMatch
    var id: String { match.id }
}
