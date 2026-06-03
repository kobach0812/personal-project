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
            List {
                statusSection

                if let live = vm.bracket {
                    ForEach(live.groups) { group in
                        GroupSection(
                            group: group,
                            vm: vm,
                            onEnterScore: { match in
                                scoreEntry = ScoreEntryContext(group: group, match: match)
                            }
                        )
                    }
                }

                footerSection
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var statusSection: some View {
        Section {
            HStack {
                Image(systemName: vm.groupStageComplete ? "checkmark.circle.fill" : "circle.dashed")
                    .foregroundStyle(vm.groupStageComplete ? .green : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Group Stage")
                        .font(.headline)
                    Text("\(vm.groupMatchesPlayed) / \(vm.groupMatchesTotal) matches played")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var footerSection: some View {
        if vm.groupStageComplete, vm.isOrganizer {
            Section {
                Button {
                    showConfigureKnockout = true
                } label: {
                    HStack {
                        Text("Configure Knockout")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                Text("Pick how many teams advance from each group, then generate the knockout bracket.")
            }
        }
    }
}

// MARK: - Group section

private struct GroupSection: View {
    let group: BracketGroup
    @ObservedObject var vm: BracketDetailViewModel
    let onEnterScore: (GroupMatch) -> Void

    var body: some View {
        Section {
            // Standings table
            ForEach(Array(vm.groupStandings(for: group).enumerated()), id: \.element.id) { idx, team in
                HStack {
                    Text("\(idx + 1).")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 24, alignment: .leading)
                    Text(team.name)
                        .font(.subheadline)
                    Spacer()
                    Text("\(vm.wins(team.id, in: group))–\(vm.losses(team.id, in: group))")
                        .font(.subheadline.monospacedDigit())
                    let diff = vm.pointDiff(team.id, in: group)
                    Text(diff >= 0 ? "+\(diff)" : "\(diff)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }

            // Matches
            ForEach(group.matches) { match in
                MatchRow(
                    match: match,
                    teamAName: vm.teamName(match.teamAID, in: group),
                    teamBName: vm.teamName(match.teamBID, in: group),
                    isOrganizer: vm.isOrganizer,
                    onEnterScore: { onEnterScore(match) }
                )
            }
        } header: {
            Text("Group \(group.name)")
        }
    }
}

// MARK: - Match row

private struct MatchRow: View {
    let match: GroupMatch
    let teamAName: String
    let teamBName: String
    let isOrganizer: Bool
    let onEnterScore: () -> Void

    var body: some View {
        if let a = match.scoreA, let b = match.scoreB, match.winnerTeamID != nil {
            HStack {
                Text(teamAName)
                    .fontWeight(match.winnerTeamID == match.teamAID ? .semibold : .regular)
                Spacer()
                Text("\(a) – \(b)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(teamBName)
                    .fontWeight(match.winnerTeamID == match.teamBID ? .semibold : .regular)
                    .multilineTextAlignment(.trailing)
            }
        } else if isOrganizer {
            Button(action: onEnterScore) {
                HStack {
                    Text("\(teamAName) vs \(teamBName)")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("Enter Score")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.tint)
                }
            }
        } else {
            HStack {
                Text("\(teamAName) vs \(teamBName)")
                Spacer()
                Text("Awaiting result")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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
