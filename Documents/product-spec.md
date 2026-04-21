# PlaySnap MVP Product Spec

## 1. Purpose

PlaySnap is an iPhone app for sports players to instantly share real moments with their squad. The MVP is focused on one loop:

Capture a play -> send it to your squad -> squad sees it immediately -> squad reacts -> user posts again.

## 2. Product goal

Prove that players will use PlaySnap daily to share moments with a small private squad.

## 3. Core promise

PlaySnap makes a sports player's latest moment appear on their squadmates' home screens instantly, with one tap and no phone storage used.

## 4. MVP scope

### In scope

- Sign in with Apple (production target; email/phone used as workaround during development)
- Basic profile creation
- Create or join one squad
- Capture photo or short video
- Background media upload
- Squad feed
- Emoji reactions
- Push notifications
- Home screen widget showing the latest squad post

### Out of scope

- Discovery map
- Open invites to strangers
- Comments
- Direct messaging
- Public profiles
- Multiple squads
- Editing tools and filters
- Long-form media or stats tracking

## 5. Primary user

The main MVP user is a player who already has a regular crew and wants a faster, more personal way to share training and game moments.

## 6. Success criteria

- Users complete onboarding and join or create a squad
- Users post at least one moment in their first session
- Users post again within the first week
- Squadmates react to posts
- Users keep the widget enabled on their home screen

## 7. App structure

Main areas of the MVP:

1. Onboarding
2. Camera
3. Feed
4. Notifications
5. Profile and settings

Default tab after onboarding:

- Camera opens first

## 8. Screen specs

### 8.1 Launch / Auth

Purpose:
- Let the user enter the app with minimal friction

Content:
- App logo
- One-line value proposition
- "Continue with Apple" button (production intent)
- Terms and privacy links

Primary actions:
- Sign in with Apple (production)

Rules:
- If user already has a valid session, skip this screen

> **Current implementation note**: Sign in with Apple requires a paid Apple Developer account
> and is temporarily parked. The current auth screen offers email/password and phone number
> sign-in as a working substitute. The routing logic after sign-in is identical.
> Restore Apple Sign In before TestFlight by enabling the capability and wiring
> `AppleSignInProvider.swift` into `FirebaseAuthService`.

Next step:
- If profile is incomplete, go to Create Profile
- If profile is complete and squad exists, go to Camera
- If profile is complete but no squad exists, go to Squad Setup

### 8.2 Create Profile

Purpose:
- Capture the minimum identity needed for squad sharing

Content:
- Name field
- Sport picker
- Optional profile photo

Primary actions:
- Save profile

Validation:
- Name is required
- One sport selection is required

Next step:
- Go to Squad Setup

### 8.3 Create Squad or Join Squad

Purpose:
- Get the user into a private group as fast as possible

Content:
- Create squad option
- Join by invite link or invite code option

Create squad flow:
- Enter squad name
- Generate invite link

Join squad flow:
- Accept invite link
- Confirm squad name before joining

Rules:
- One squad per user in MVP
- Squad membership is required before posting

Next step:
- Show Widget Setup Help
- Then go to Camera

### 8.4 Widget Setup Help

Purpose:
- Help users install the widget early, because it is the differentiator

Content:
- Simple explanation of why the widget matters
- Short step-by-step widget setup instructions
- Preview of widget UI
- "Continue to app" button

Rules:
- User can skip
- Show once during onboarding, accessible later in settings

Next step:
- Go to Camera

### 8.5 Camera

Purpose:
- Act as the default home screen and fastest path to posting

Content:
- Live camera preview on launch
- Capture button
- Camera switch button
- Media mode indicator: photo or video
- Shortcut to Feed
- Shortcut to Notifications
- Shortcut to Profile

Primary actions:
- Capture photo
- Hold or tap to record short video up to 15 seconds

Rules:
- Camera should be ready immediately after app opens
- User should not need to navigate through a feed before posting
- Captured media is temporary until upload completes

Next step:
- Go to Post Review / Send

### 8.6 Post Review / Send

Purpose:
- Let the user confirm and send with minimal friction

Content:
- Media preview
- Optional short caption field
- Sport label if needed
- "Send to squad" button
- Cancel / retake action

Primary actions:
- Send to squad
- Retake

Rules:
- Keep metadata minimal in MVP
- Upload should continue in background after send
- Local copy is deleted after successful upload and remote confirmation

Next step:
- Return user to Camera
- Show lightweight send confirmation

System actions after send:
- Create post record
- Upload media
- Notify squad
- Refresh feed data
- Trigger widget reload

### 8.7 Squad Feed

Purpose:
- Let users catch up on the latest posts from their squad

Content:
- Reverse chronological list of squad posts
- Each item shows media preview, poster name, timestamp, reaction count

Primary actions:
- Open a post
- React with emoji
- Pull to refresh

Rules:
- No algorithmic ranking
- No comments in MVP
- Feed is limited to the user's single squad

Next step:
- Open Full-Screen Post Viewer

### 8.8 Full-Screen Post Viewer

Purpose:
- Provide focused viewing for one post

Content:
- Full-screen photo or video
- Poster name
- Timestamp
- Caption if present
- Emoji reactions

Primary actions:
- Add or remove reaction
- Swipe to dismiss

Rules:
- Fast load is critical
- If network is weak, cached preview should appear first when possible

### 8.9 Notifications

Purpose:
- Show recent app activity in one place

Content:
- New squad post notifications
- Reaction notifications

Primary actions:
- Tap notification to open relevant post

Rules:
- No complex inbox system in MVP
- Notifications should also exist as push notifications outside the app

### 8.10 Profile / Settings

Purpose:
- Let users manage their identity and account basics

Content:
- Profile photo
- Name
- Sport
- Squad name
- Invite squadmates action
- Widget help entry
- Notification preferences
- Sign out

Primary actions:
- Edit profile
- Copy or share invite link
- Open widget help
- Sign out

Rules:
- Keep settings minimal

## 9. Primary user flows

### 9.1 New user onboarding

1. Open app
2. Sign in with Apple
3. Create profile
4. Create squad or join existing squad
5. See widget setup help
6. Land on Camera

### 9.2 First post flow

1. User lands on Camera
2. Captures photo or short video
3. Reviews media
4. Taps "Send to squad"
5. Upload starts in background
6. User returns to Camera
7. Squad receives push notification
8. Widget updates with latest post

### 9.3 Squadmate reaction flow

1. Squadmate receives push notification or sees widget update
2. Opens app to Feed or Post Viewer
3. Reacts with emoji
4. Original poster receives reaction notification

### 9.4 Returning user flow

1. Open app
2. App opens directly to Camera
3. User either posts immediately or checks Feed

## 10. Navigation rules

- Camera is the default landing screen after onboarding
- Feed, Notifications, and Profile must always be reachable from Camera
- Posting must take fewer steps than browsing
- The widget is treated as part of the core product, not an optional afterthought

## 11. Functional requirements

- Apple sign-in must persist the user session
- Users must belong to a squad before they can post
- Posts must support either photo or video
- Video length must be capped at 15 seconds
- Feed updates must appear quickly after a successful upload
- Widget data must reflect the latest squad post
- Push notifications must be sent for new posts and reactions

## 12. Non-functional requirements

- App launch should feel fast
- Camera readiness is a top priority
- Upload must be resilient to poor connection
- Media should not remain stored on-device after successful upload
- Widget content should remain lightweight and reliable

## 13. MVP risks

- Widget updates may be constrained by iOS widget refresh behavior
- Cloud-only storage adds failure cases during upload and deletion
- Camera startup speed can make or break the product feel
- Push delivery timing must feel near real time for the loop to work

## 14. Open questions

- Will the MVP support both photo and video on day one, or ship with photo first if camera scope slips?
- Will captions be included in v1, or should the MVP ship with media plus reactions only?
- How much widget history is needed beyond "latest squad moment"?

## 15. Next document to create

After this spec, the next artifact should be a technical design covering:

- Firestore collections
- Storage paths
- Auth model
- Media upload pipeline
- Widget data sync
- Notification trigger logic
