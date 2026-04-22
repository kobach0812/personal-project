# PlaySnap

## Product summary

PlaySnap is a sports social app for players, not spectators. It lets players capture a play, drill, or game moment and instantly share it with their squad, with the latest moment appearing on teammates' home screen widgets.

## Problem

Players have no simple product for sharing real sports moments with their actual crew in real time. Existing tools are fragmented across camera rolls, messaging apps, and public social media, which creates too much friction for something that should feel instant and personal.

## Target users

- Regular players who train with the same squad every week
- Solo players who moved to a new city and need to find games later
- Casual players who need to fill a team
- Serious athletes documenting progress for coaches and friends

## Platform

- iPhone app
- Swift + SwiftUI
- App Store distribution

## Core feature

PlaySnap must do one thing better than anything else: make a sports player's latest moment appear on their squadmates' home screens instantly, with one tap and no phone storage used.

## Product principle

Build squad sharing first. Discovery comes later.

Reason:
- Squad sharing depends on trust and intimacy
- Discovery depends on openness and network scale
- Trying to build both equally from day one will split focus and weaken the product

## MVP goal

Answer one question:

Will sports players share moments with their squad and come back daily?

## MVP features

### In scope

1. Auth
- Sign in with Apple
- Optional Google sign in later if needed
- Basic profile: name, sport, avatar

2. Camera and upload
- App opens directly to camera
- Capture photo or short video up to 15 seconds
- Background upload to cloud storage
- Local copy removed after successful upload
- No filters or editing

3. Squads
- Create a squad or join by invite link
- A user can belong to multiple squads; one is active at a time (see plan M12)
- Keep each squad small and private

4. Squad feed
- Reverse chronological feed
- Full-screen play view
- Emoji reactions only

5. Home screen widget
- Shows latest squad play
- Updates automatically when someone posts

6. Push notifications
- Notify when a squadmate posts
- Notify when someone reacts

### Out of scope

- Discovery map
- Open game invites (to strangers)
- Comments
- Stats and history beyond the per-squad leaderboard
- Advanced sport tagging
- In-app messaging

## Core loop

1. User opens app
2. Camera is ready immediately
3. User records a play
4. Upload runs in background
5. Squad gets a push notification
6. Widget updates with the new play
7. Squad reacts
8. Original poster gets notified
9. User wants to post again

## Success signals

- Users post more than once in the first week
- Users keep the widget on their home screen after day 3
- Squadmates react to posts
- Invite links are shared organically
- Day 7 retention is strong enough to justify expansion

## Suggested tech stack

- UI: SwiftUI
- Camera: AVFoundation
- Auth: Firebase Auth
- Storage: Firebase Storage
- Database: Firestore
- Notifications: Firebase Cloud Messaging
- Widget: WidgetKit + App Groups

## Build order

1. Auth and profile
2. Camera capture and upload
3. Squad creation and invite flow
4. Feed and reactions
5. Widget
6. Push notifications
7. TestFlight beta

## What you need next

The idea is defined well enough. The next step is not more brainstorming.

You now need:

1. A product spec
- Exact screens
- Exact user flows
- What each screen does

2. A data model
- Users
- Squads
- Posts
- Reactions
- Invites

3. A technical architecture
- Firebase structure
- Media upload flow
- Widget update flow
- Notification triggers

4. A build plan
- MVP milestones
- What to build first
- What to postpone

## Immediate next step

Design the MVP screens before coding anything.

Initial screen list:
- Launch / auth
- Create profile
- Create squad or join squad
- Camera
- Post review / send
- Squad feed
- Full-screen post viewer
- Notifications
- Profile / settings
- Widget configuration help
