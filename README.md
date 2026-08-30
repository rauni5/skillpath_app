# SkillPath – Flutter Application

SkillPath is a Flutter-based career development application designed to help students and early-career developers build skills, explore career paths, manage projects, and connect with other learners.

The Flutter application provides the user-facing mobile experience, including authentication, personalized career guidance, skill tracking, roadmaps, project collaboration, notifications, and an AI-powered learning assistant.

---

## Features

*  User authentication
*  Personalized dashboard
*  User profile management
*  Skill management and tracking
*  Career goal selection
*  Personalized learning roadmaps
*  Project discovery and management
*  Project collaboration and team features
*  Project discussions
*  Notifications
*  AI learning/career assistant
*  Skeleton loading states for improved user experience
*  Light and dark theme support

---

## Technologies

### Frontend

* Flutter
* Dart
* Material Design

### State Management

* Provider

### Navigation

* GoRouter

### Networking

* Dio
* REST API
* Firebase Authentication

### UI & UX

* Custom reusable widgets
* Skeleton loading
* Light/Dark themes
* Form validation

### Development Tools

* Git
* GitHub
* Android Studio & VS Code
* Flutter DevTools

---

## Architecture

The application follows a feature-oriented architecture to keep the code organized and maintainable.

```text
lib/
├── core/
│   ├── constants/
│   ├── network/
│   ├── services/
│   ├── theme/
│   └── ...
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── profile/
│   ├── roadmap/
│   ├── projects/
│   ├── notifications/
│   └── assistant/
│
├── shared/
│   ├── widgets/
│   └── ...
│
└── main.dart
```

The project separates reusable application infrastructure from individual feature modules, making it easier to maintain and extend the application.

---

## Requirements

Before running the project, install:

* Flutter SDK
* Dart SDK
* Android Studio or VS Code
* Android emulator/device or a supported web browser

Verify your Flutter installation with:

```bash
flutter doctor
```

---

## Installation

Clone the repository:

```bash
git clone https://github.com/rauni5/skillpath_app
```

Navigate into the Flutter project:

```bash
cd skillpath_app
```

Install dependencies:

```bash
flutter pub get
```

---

## Running the Application

### Android

Connect an Android device or start an emulator:

```bash
flutter devices
```

Then run:

```bash
flutter run
```

---

## Backend Connection

The Flutter application communicates with the SkillPath backend through REST APIs.

Before running the application, make sure the backend server is running and that the API base URL configured in the Flutter project points to the correct backend environment.

```text
Flutter Application
        │
        │ REST API
        ▼
Spring Boot Backend
        │
        ▼
     Database
```

---

## Loading Experience

The application uses reusable skeleton loading components for major screens.

Instead of displaying a blank screen or a generic loading indicator while data is being retrieved, the UI displays placeholders that follow the structure of the actual screen.

This provides a smoother user experience and makes loading states feel more consistent with the application's design.

---

## Themes

SkillPath supports both:

* Light mode
* Dark mode

The UI components and loading states adapt to the active application theme.

---

## Project Structure

The application is organized around individual features rather than keeping all screens and logic in a single directory.

This makes it easier to:

* Add new features
* Maintain existing functionality
* Reuse common components
* Separate UI and application logic
* Scale the application as functionality grows

---

## Development

Install dependencies after cloning:

```bash
flutter pub get
```

Run static analysis:

```bash
flutter analyze
```

Run the application:

```bash
flutter run
```

Build a release APK:

```bash
flutter build apk --release
```

---

## Author

**Raunit Giri**

Computing Undergraduate
Islington College, Kathmandu, Nepal

---
