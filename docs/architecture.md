# NexTalk Architecture

This document organizes the current codebase into logical blocks. The app is now split into feature-oriented Dart part files under `lib/src`, while `lib/main.dart` stays small and owns imports, Firebase startup, and `runApp`.

## High-Level Block Diagram

```mermaid
flowchart TD
    App[NexTalk Flutter App]

    App --> Bootstrap[FirebaseBootstrap]
    App --> Auth[Authentication UI]
    App --> Home[HomeShell Tabs]
    App --> Repo[ChatRepository]
    App --> Shared[Shared UI Components]

    Bootstrap --> FirebaseCore[Firebase Core]

    Auth --> Login[Login Screen]
    Auth --> Signup[Create Account Screen]
    Auth --> VerifyEmail[Email Verification]
    Auth --> PhoneOtp[Phone OTP Screen]
    Auth --> Forgot[Forgot Password Screen]

    Home --> Messages[Messages Tab]
    Home --> Friends[Friends Tab]
    Home --> FindPeople[Find Friends Tab]
    Home --> Profile[Profile Tab]

    Messages --> Chat[Chat Screen]
    Chat --> TextMessage[Text Messages]
    Chat --> VoiceMessage[Voice Messages]
    Chat --> VoiceCall[Voice Call Screen]

    Repo --> AuthApi[Firebase Auth]
    Repo --> Firestore[Cloud Firestore]
    Repo --> Storage[Firebase Storage]
    Repo --> FCM[Firebase Messaging]
    VoiceCall --> Zego[ZegoCloud SDK]
```

## Data Flow

```mermaid
sequenceDiagram
    participant User
    participant UI as Flutter UI
    participant Repo as ChatRepository
    participant Auth as Firebase Auth
    participant DB as Firestore
    participant Store as Firebase Storage
    participant FCM as Firebase Messaging

    User->>UI: Sign up with email
    UI->>Repo: createAccount()
    Repo->>Auth: createUserWithEmailAndPassword()
    Repo->>Auth: sendEmailVerification()
    Repo->>DB: create users/{uid}

    User->>UI: Sign in
    UI->>Repo: signIn()
    Repo->>Auth: signInWithEmailAndPassword()
    Repo->>DB: update user online/profile
    Repo->>FCM: get notification token
    Repo->>DB: save token in users/{uid}

    User->>UI: Send text
    UI->>Repo: sendMessage()
    Repo->>DB: conversations/{id}/messages/{messageId}

    User->>UI: Hold mic and send voice
    UI->>Repo: sendVoiceMessage()
    Repo->>Store: upload audio file
    Repo->>DB: save message with audioUrl

    User->>UI: Start voice call
    UI->>Zego: join call room by conversation id
```

## Firebase Collections

```mermaid
erDiagram
    users {
        string uid
        string displayName
        string email
        string emailLower
        string phoneNumber
        boolean online
        array fcmTokens
    }

    connections {
        array participants
        map participantInfo
        timestamp updatedAt
    }

    conversations {
        array participants
        map participantInfo
        string lastMessage
        map unreadCounts
        timestamp updatedAt
    }

    messages {
        string senderId
        string type
        string text
        string audioUrl
        int audioDurationMs
        timestamp createdAt
    }

    friendRequests {
        string fromUid
        string toUid
        string status
        timestamp createdAt
    }

    notifications {
        string userId
        string title
        string body
        boolean read
        timestamp createdAt
    }

    conversations ||--o{ messages : contains
    users ||--o{ conversations : participates
    users ||--o{ friendRequests : sends
    users ||--o{ notifications : receives
```

## Current Code Blocks

| Block | Current Location | Main Classes |
| --- | --- | --- |
| App bootstrap | `lib/main.dart`, `lib/src/app/chat_app.dart`, `lib/src/core/firebase_bootstrap.dart` | `main`, `FirebaseBootstrap`, `ChatApp` |
| Theme/constants | `lib/src/core/theme.dart` | `AppColors`, `ZegoSettings`, `buildTheme` |
| Models | `lib/src/models/models.dart` | `AppUser`, `Conversation`, `ChatMessage`, `FriendRequest`, `AppNotification` |
| Repository/services | `lib/src/services/chat_repository.dart` | `ChatRepository` |
| Utilities/demo data | `lib/src/core/utils.dart`, `lib/src/demo/sample_data.dart` | date formatters, error helpers, sample data |
| Auth screens | `lib/src/features/auth/auth_screens.dart` | `LoginScreen`, `CreateAccountScreen`, `PhoneAuthScreen`, `ForgotPasswordScreen` |
| Main navigation | `lib/src/features/home/home_shell.dart` | `HomeShell` |
| Chat | `lib/src/features/chat/chat_screens.dart` | `MessagesScreen`, `ChatScreen`, `MessageBubble`, `VoiceMessageBubble` |
| Calls | `lib/src/features/chat/chat_screens.dart` | `VoiceCallScreen`, `CallControlButton` |
| Social | `lib/src/features/friends/friends_screens.dart` | `FriendsScreen`, `FindPeopleScreen`, `FriendRequestsScreen` |
| Notifications | `lib/src/features/notifications/notifications_screens.dart` | `NotificationsScreen`, `NotificationCard` |
| Profile | `lib/src/features/profile/profile_screens.dart` | `ProfileScreen`, `ChangePasswordScreen` |
| Shared widgets | `lib/src/shared/widgets.dart` | `AvatarCircle`, `PrimaryButton`, `SearchBox`, `UserCard`, etc. |

## Recommended Folder Structure

```text
lib/
  main.dart
  firebase_options.dart

  src/
    core/
      firebase_bootstrap.dart
      theme.dart
      utils.dart

    models/
      models.dart

    services/
      chat_repository.dart

    demo/
      sample_data.dart

    features/
      auth/
        auth_screens.dart

      home/
        home_shell.dart

      chat/
        chat_screens.dart

      friends/
        friends_screens.dart

      notifications/
        notifications_screens.dart

      profile/
        profile_screens.dart

    shared/
      widgets.dart
```

## Future File Split

The current implementation uses grouped part files to keep the refactor safe. Later, each grouped file can be split into smaller importable files:

```text
lib/features/chat/
  chat_screen.dart
  messages_screen.dart
  widgets/message_bubble.dart
  widgets/voice_message_bubble.dart

lib/shared/
    widgets/avatar_circle.dart
    widgets/buttons.dart
```

## Feature Blocks

```mermaid
flowchart LR
    AuthFeature[Auth Feature]
    ChatFeature[Chat Feature]
    VoiceFeature[Voice Messages]
    CallsFeature[Voice Calls]
    NotifyFeature[Notifications]

    AuthFeature --> FirebaseAuth[Firebase Auth]
    ChatFeature --> Firestore[Firestore]
    VoiceFeature --> Record[Record Package]
    VoiceFeature --> Storage[Firebase Storage]
    CallsFeature --> Zego[ZegoCloud SDK]
    NotifyFeature --> Messaging[FCM]

    Record --> Storage
    Storage --> Firestore
    Firestore --> ChatFeature
```

## Refactor Order

1. Keep the current part-file structure stable while adding features.
2. Extract grouped part files into importable libraries when a feature becomes too large.
3. Split `ChatRepository` into dedicated auth, chat, storage, notification, and call services.
4. Add tests around each service before splitting repository behavior.
