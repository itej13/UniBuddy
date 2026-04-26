# UniBuddy

UniBuddy is a native macOS app for tracking college attendance and Google Classroom submissions in one place. It is built with SwiftUI and Swift Package Manager, stores data locally on your Mac, and uses Google Sign-In to read your own Classroom courses, coursework, and submission status.

## Features

- Google Sign-In for college accounts.
- Google Classroom sync for courses, coursework, due dates, and submission state.
- Subject setup with subject name, code, credits, and optional Classroom course linking.
- Timetable builder with multi-day class slots and a tabular weekly view.
- Attendance logging per subject and date.
- Dashboard summaries for today’s classes, pending submissions, and attendance percentages.
- Local notifications for upcoming submissions and attendance prompts.
- Local-only app data stored under macOS Application Support.

## Requirements

- macOS 14 or later.
- Swift 6 toolchain / Xcode Command Line Tools.
- A Google Cloud OAuth client configured for native sign-in.
- Google Classroom API enabled in the Google Cloud project.

## Setup

Clone the repository and create a local OAuth config:

```bash
cp .env.example .env.local
```

Update `.env.local`:

```bash
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_REVERSED_CLIENT_ID=com.googleusercontent.apps.your-client-id
GOOGLE_HOSTED_DOMAIN=
```

`GOOGLE_HOSTED_DOMAIN` is optional. You can leave it blank, or set it to your college Google Workspace domain if you want Google’s account chooser to prefer that domain.

## Google Cloud Configuration

1. Open Google Cloud Console.
2. Enable the **Google Classroom API** for the project.
3. Create an OAuth client:
   - Application type: `iOS`
   - Bundle ID: `com.tejasdas.UniBuddy`
4. Copy the client ID and reversed client ID into `.env.local`.

Do not put a client secret in this app. Native desktop/mobile OAuth clients use the client ID and redirect URL scheme; embedding a client secret in an app bundle would expose it.

## Run

```bash
./script/build_and_run.sh
```

The script:

- resolves Swift Package Manager dependencies,
- applies a local macOS keychain compatibility patch for Google Sign-In,
- builds the SwiftPM executable,
- stages `dist/UniBuddy.app`, and
- launches the app as a foreground macOS bundle.

Useful run modes:

```bash
./script/build_and_run.sh --verify
./script/build_and_run.sh --logs
./script/build_and_run.sh --telemetry
```

## Project Structure

```text
Sources/
  App/          App entry point and macOS app delegate
  Models/       Codable app and Classroom models
  Services/     Google auth, Classroom API, notifications
  Stores/       Local JSON persistence and sync coordination
  Support/      Formatting and analytics helpers
  Views/        SwiftUI dashboard, subjects, timetable, attendance, settings
script/         Build and run entrypoint
```

## Privacy

UniBuddy has no backend. Subjects, timetable slots, attendance records, synced Classroom metadata, and profile details are stored locally on your Mac. Google access is limited to read-only Classroom scopes for your own courses, coursework, and submissions.

## Troubleshooting

If sync reports that the Classroom API is disabled, enable it here for your project:

```text
https://console.developers.google.com/apis/api/classroom.googleapis.com/overview
```

After enabling the API, wait a few minutes and press **Sync** again.
