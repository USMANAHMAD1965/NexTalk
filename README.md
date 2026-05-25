# NexTalk

A Flutter chat app UI with Firebase Auth and Cloud Firestore integration points. The screens follow the provided reference: splash, sign in, create account, forgot password, messages, chat, friends, find people, friend requests, notifications, profile, and change password.

## Run

```bash
flutter pub get
flutter run
```

The app can run without Firebase project files. In that case it uses demo data so the UI is still easy to preview.

## Firebase Setup

1. Create a Firebase project.
2. Enable Authentication with the Email/Password and Phone providers.
3. Enable Cloud Firestore.
4. Add your Android and iOS apps in Firebase.
5. Add Firebase config with the FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

The project already includes a placeholder `lib/firebase_options.dart`. Running `flutterfire configure` will replace it with your real Firebase project values. Until then, the app stays in demo mode.

Firestore collections used by the app:

- `users`
- `connections`
- `conversations`
- `conversations/{conversationId}/messages`
- `friendRequests`
- `notifications`

## Chat Between Two Devices

1. Run `flutterfire configure` and make sure `lib/firebase_options.dart` contains real Firebase values.
2. In Firebase Console, enable Authentication > Email/Password and Phone.
3. In Firebase Console, enable Cloud Firestore.
4. For email signup, verify the email link before signing in.
5. For phone signup, enter phone number with country code and verify the OTP.
6. Run the app on device A and create account A.
7. Run the app on device B and create account B.
8. On device A, open the Find Friends tab.
9. Enter account B's email in Start chat by email and tap the chat button.
10. Send a message. Device B will see the conversation in the Messages tab.

For development, your Firestore rules must allow signed-in users to read/write the chat collections.

## Verify

```bash
flutter analyze
flutter test
```
