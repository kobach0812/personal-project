import SwiftUI

/// Three-tab sheet for building a tournament roster from squad members, friends, or guest names.
struct PlayerPickerSheet: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    let squadMemberIDs: [String]
    /// Called with the final player list when the user taps Done.
    var onConfirm: ([TournamentPlayer]) -> Void

    @State private var tab = 0
    @State private var squadUsers: [AppUser] = []
    @State private var friends: [Friend] = []
    @State private var selectedUserIDs: Set<String> = []
    @State private var guestName = ""
    @State private var guests: [String] = []
    @State private var isLoading = false

    private var selectedCount: Int {
        selectedUserIDs.count + guests.count
    }

    // Build TournamentPlayer list from current selections.
    private func makePlayers() -> [TournamentPlayer] {
        var result: [TournamentPlayer] = []
        // Squad members (prefer squad user over friend if same ID)
        for user in squadUsers where selectedUserIDs.contains(user.id) {
            result.append(TournamentPlayer(
                id: UUID().uuidString, name: user.name, userID: user.id,
                played: 0, wins: 0, losses: 0, lastPlayedAt: 0
            ))
        }
        // Friends not already added via squad
        let addedUserIDs = Set(result.compactMap(\.userID))
        for friend in friends where selectedUserIDs.contains(friend.id) && !addedUserIDs.contains(friend.id) {
            result.append(TournamentPlayer(
                id: UUID().uuidString, name: friend.name, userID: friend.id,
                played: 0, wins: 0, losses: 0, lastPlayedAt: 0
            ))
        }
        // Guests (no linked user)
        for name in guests {
            result.append(TournamentPlayer(
                id: UUID().uuidString, name: name, userID: nil,
                played: 0, wins: 0, losses: 0, lastPlayedAt: 0
            ))
        }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $tab) {
                    Text("Squad").tag(0)
                    Text("Friends").tag(1)
                    Text("Guest").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                Divider()

                switch tab {
                case 0:  squadTab
                case 1:  friendsTab
                default: guestTab
                }
            }
            .navigationTitle(selectedCount == 0 ? "Add Players" : "Add Players (\(selectedCount))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onConfirm(makePlayers())
                        dismiss()
                    }
                }
            }
            .task { await loadData() }
        }
    }

    // MARK: - Squad tab

    @ViewBuilder
    private var squadTab: some View {
        if isLoading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if squadUsers.isEmpty {
            ContentUnavailableView(
                "No squad members",
                systemImage: "person.3",
                description: Text("Invite people to your squad first.")
            )
        } else {
            List(squadUsers) { user in
                selectableRow(id: user.id, name: user.name)
            }
        }
    }

    // MARK: - Friends tab

    @ViewBuilder
    private var friendsTab: some View {
        if friends.isEmpty {
            ContentUnavailableView(
                "No friends yet",
                systemImage: "person.2",
                description: Text("Add friends from the Friends tab in your profile.")
            )
        } else {
            List(friends) { friend in
                selectableRow(id: friend.id, name: friend.name)
            }
        }
    }

    // MARK: - Guest tab

    @ViewBuilder
    private var guestTab: some View {
        List {
            Section {
                HStack {
                    TextField("Guest name", text: $guestName)
                        .onSubmit { addGuest() }
                    Button("Add") { addGuest() }
                        .disabled(guestName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            if !guests.isEmpty {
                Section("Guests") {
                    ForEach(guests, id: \.self) { name in
                        HStack {
                            Text(name)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                    .onDelete { guests.remove(atOffsets: $0) }
                }
            }
        }
    }

    // MARK: - Helpers

    private func selectableRow(id: String, name: String) -> some View {
        HStack {
            Text(name)
            Spacer()
            Image(systemName: selectedUserIDs.contains(id) ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(selectedUserIDs.contains(id) ? Color.orange : Color.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if selectedUserIDs.contains(id) {
                selectedUserIDs.remove(id)
            } else {
                selectedUserIDs.insert(id)
            }
        }
    }

    private func addGuest() {
        let name = guestName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        guests.append(name)
        guestName = ""
    }

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        async let users = try? env.userProfileService.fetchUsers(ids: squadMemberIDs)
        async let loadedFriends = try? env.friendService.fetchFriends()
        squadUsers = await users ?? []
        friends = await loadedFriends ?? []
    }
}
