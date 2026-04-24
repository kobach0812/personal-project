import Combine
import SwiftUI

// MARK: - ViewModel

@MainActor
final class FriendsViewModel: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var pendingRequests: [FriendRequest] = []
    @Published var searchQuery = ""
    @Published var searchResults: [AppUser] = []
    @Published var isLoading = false
    @Published var isSendingRequest = false
    @Published var sentRequestUserIDs: Set<String> = []
    @Published var errorMessage: String?

    func load(friendService: FriendServicing) async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            async let loadedFriends = friendService.fetchFriends()
            async let loadedRequests = friendService.fetchPendingIncomingRequests()
            friends = try await loadedFriends
            pendingRequests = try await loadedRequests
        } catch {
            errorMessage = "Could not load friends."
        }
    }

    func search(friendService: FriendServicing) async {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        do {
            searchResults = try await friendService.searchUsers(query: query)
            errorMessage = nil
        } catch {
            searchResults = []
            errorMessage = "Search failed: \(error.localizedDescription)"
        }
    }

    func sendRequest(to user: AppUser, currentUserName: String, friendService: FriendServicing) async {
        isSendingRequest = true
        defer { isSendingRequest = false }
        do {
            try await friendService.sendFriendRequest(to: user.id, fromName: currentUserName)
            sentRequestUserIDs.insert(user.id)
        } catch FriendServiceError.requestAlreadyExists {
            sentRequestUserIDs.insert(user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func accept(_ request: FriendRequest, friendService: FriendServicing) async {
        do {
            try await friendService.acceptFriendRequest(request.id)
            pendingRequests.removeAll { $0.id == request.id }
            friends.append(Friend(id: request.fromUserID, name: request.fromUserName, avatarURL: nil))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func decline(_ request: FriendRequest, friendService: FriendServicing) async {
        do {
            try await friendService.declineFriendRequest(request.id)
            pendingRequests.removeAll { $0.id == request.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - View

struct FriendsView: View {
    @EnvironmentObject private var env: AppEnvironment
    @StateObject private var vm = FriendsViewModel()
    @State private var currentUserName: String = ""

    private var isSearchActive: Bool { !vm.searchQuery.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        List {
            if let error = vm.errorMessage {
                Section {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }
            }

            if isSearchActive {
                searchResultsSection
            } else {
                requestsSection
                friendsSection
            }
        }
        .navigationTitle("Friends")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $vm.searchQuery, placement: .navigationBarDrawer, prompt: "Search players")
        .onChange(of: vm.searchQuery) { _, _ in
            Task { await vm.search(friendService: env.friendService) }
        }
        .task {
            // Grab the user's display name for use in friend request sends.
            if let user = try? await env.userProfileService.fetchCurrentUser() {
                currentUserName = user.name
            }
            await vm.load(friendService: env.friendService)
        }
    }

    // MARK: Search results

    @ViewBuilder
    private var searchResultsSection: some View {
        if vm.searchResults.isEmpty {
            Section {
                Text("No players found.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        } else {
            Section("Results") {
                ForEach(vm.searchResults) { user in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.name).font(.body)
                        }
                        Spacer()
                        if vm.sentRequestUserIDs.contains(user.id) ||
                            vm.friends.contains(where: { $0.id == user.id }) {
                            Text("Added")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Button("Add") {
                                Task {
                                    await vm.sendRequest(
                                        to: user,
                                        currentUserName: currentUserName,
                                        friendService: env.friendService
                                    )
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(.orange)
                            .disabled(vm.isSendingRequest)
                        }
                    }
                }
            }
        }
    }

    // MARK: Pending requests

    @ViewBuilder
    private var requestsSection: some View {
        if !vm.pendingRequests.isEmpty {
            Section("Requests (\(vm.pendingRequests.count))") {
                ForEach(vm.pendingRequests) { request in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(request.fromUserName).font(.body)
                            Text(request.createdAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Accept") {
                            Task { await vm.accept(request, friendService: env.friendService) }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.orange)

                        Button("Decline") {
                            Task { await vm.decline(request, friendService: env.friendService) }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.secondary)
                    }
                }
            }
        }
    }

    // MARK: Friends list

    @ViewBuilder
    private var friendsSection: some View {
        if vm.isLoading {
            Section {
                HStack { Spacer(); ProgressView(); Spacer() }
            }
        } else if vm.friends.isEmpty {
            Section {
                ContentUnavailableView(
                    "No friends yet",
                    systemImage: "person.2",
                    description: Text("Search for players above to add them.")
                )
            }
        } else {
            Section("Friends (\(vm.friends.count))") {
                ForEach(vm.friends) { friend in
                    Text(friend.name)
                }
            }
        }
    }
}
