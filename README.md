# 🚀 LeetCode Dashboard Widget

A cross-platform mobile application that provides real-time LeetCode profile statistics, problem of the day tracking, contest notifications, and intelligent reminders.

**Live on:** Android (Samsung Galaxy S20 FE) | iOS Ready | Windows Ready | Web Ready

---

## 📋 Table of Contents

- [Problem Statement](#problem-statement)
- [Proposed Solution](#proposed-solution)
- [Key Features](#key-features)
- [Technology Stack](#technology-stack)
- [Development Process](#development-process)
- [Architecture](#architecture)
- [Installation & Setup](#installation--setup)
- [How to Use](#how-to-use)
- [Project Structure](#project-structure)
- [Future Enhancements](#future-enhancements)

---

## 🎯 Problem Statement

### The Challenge

Competitive programmers face several pain points when tracking their LeetCode progress:

1. **Fragmented Experience**: Need to visit LeetCode website repeatedly to check progress
2. **No Intelligent Reminders**: No way to get smart notifications for daily problems
3. **Poor Mobile Experience**: Website is not optimized for mobile devices
4. **Manual Contest Tracking**: Must manually track upcoming contests and set reminders
5. **Difficult Status Detection**: Hard to know if you've already solved today's problem

### Real-world Impact

- **Problem**: A competitive programmer needs to check their daily problem 5+ times a day
- **Current Solution**: Visit LeetCode.com each time (takes 2+ minutes per visit)
- **Inefficiency**: ~10+ minutes wasted daily on status checking
- **Our Solution**: One-tap dashboard with smart reminders that auto-stop when solved

---

## 💡 Proposed Solution

### LeetCode Dashboard Widget

A **lightweight, intelligent mobile app** that:

1. **Fetches Live Data** from LeetCode's GraphQL API in real-time
2. **Provides Intelligent Reminders** with smart problem status detection
3. **Integrates with Phone Ecosystem** (calendar, notifications, alarms)
4. **Works Offline** with cached data
5. **Cross-Platform** (Android, iOS, Windows, Web)

### Key Innovation: Smart Problem Detection

```
User enables reminder for daily problem
    ↓
App checks multiple data sources:
    • API user status field
    • Recent submissions list
    • Submission calendar heatmap
    ↓
If problem already solved:
    • Auto-stop reminders
    • Show success confirmation
    • Update UI immediately
    ↓
If not solved:
    • Send 2-hour interval reminders
    • Auto-cancel when solved
    • No manual intervention needed
```

---

## ✨ Key Features

### 1. **Real-time Dashboard** 📊

- User profile with avatar and statistics
- Easy/Medium/Hard problem counts and progress bars
- Contest ratings and global rankings
- Achievement badges display

### 2. **Problem of the Day** 🎯

- Daily challenge from LeetCode
- Solve status detection (3-point validation)
- Difficulty level indicator
- Direct link to solve on LeetCode
- Smart reminder bell (only shows if unsolved)

### 3. **Intelligent Reminder System** 🔔

- **2-Hour Recurring Reminders**: 8AM, 10AM, 12PM, 2PM, 4PM, 6PM, 8PM, 10PM
- **Smart Status Detection**: Checks if problem is already solved before notifying
- **Auto-Stop Feature**: Automatically cancels reminders when problem is completed
- **Visual Feedback**: Orange bell for active, gray for inactive
- **Persistent State**: Settings survive app restart

### 4. **Contest Management** 🏆

- Upcoming contests with countdown timers
- IST timezone support (8AM weekly, 8PM biweekly)
- Multi-level reminders (24h, 1h, 15 minutes before)
- "Add to Calendar" integration
- Native phone alarm support

### 5. **Interactive Heatmap Calendar** 📅

- Submission frequency visualization
- Monthly navigation
- Hover tooltips with submission details
- Streak tracking and statistics
- Mobile-responsive design

### 6. **Offline Support** 📱

- Cached user data
- Local storage with SharedPreferences
- Persistent reminder preferences
- Works without internet connection

---

## 🛠️ Technology Stack

### **Frontend Framework**

- **Flutter** (v3.8.1+) - Cross-platform UI framework
- **Dart** - Programming language

### **Backend & API**

- **GraphQL** - Query language for LeetCode API
- **GraphQL Flutter** (v5.1.2) - GraphQL client
- **HTTP** (v1.2.1) - Backup HTTP requests

### **Data Management**

- **SharedPreferences** (v2.2.2) - Local persistent storage
- **Hive** - Local database for cache
- **JSON** - Data serialization

### **Notifications & Scheduling**

- **flutter_local_notifications** (v17.2.3) - Push notifications
- **Android Notification Channels** - Native Android notifications

### **Platform Integration**

- **add_2_calendar** (v3.0.1) - Calendar event creation
- **android_intent_plus** (v4.0.3) - Android intent handling
- **url_launcher** (v6.2.5) - Browser and app opening

### **UI & Visualization**

- **flutter_heatmap_calendar** (v1.0.5) - Heatmap calendar widget
- **Material Design 3** - Modern UI design system
- **device_preview** (v1.3.1) - Multi-device testing (dev only)

### **Development Tools**

- **Flutter SDK** - Framework runtime
- **Android SDK** (API 33+) - Android build tools
- **Gradle** - Android build system
- **Git** - Version control
- **VS Code/Android Studio** - IDEs

---

## 📈 Development Process

### Phase 1: Planning & Design (Week 1)

- Identified the problem through personal experience
- Designed user flows and wireframes
- Planned API integration strategy
- Selected technology stack

### Phase 2: Core Development (Weeks 2-3)

```
✅ Set up Flutter project
✅ Implement GraphQL client
✅ Create responsive UI widgets
✅ Build dashboard page
✅ Design state management
```

### Phase 3: Feature Implementation (Weeks 4-6)

```
✅ Notification service
✅ Reminder system (2-hour intervals)
✅ Smart problem detection
✅ Calendar integration
✅ Heatmap visualization
```

### Phase 4: Testing & Optimization (Week 7)

```
✅ Device testing (Samsung Galaxy S20 FE)
✅ UI/UX refinement
✅ Performance optimization
✅ Bug fixes and edge cases
```

### Phase 5: Production Release (Week 8)

```
✅ Remove development tools (device preview)
✅ Final testing on device
✅ GitHub repository setup
✅ Comprehensive documentation
```

---

## 🏗️ Architecture

### **System Architecture**

```
┌─────────────────────────────────────────────────────┐
│                 Flutter UI Layer                    │
│  (Widgets, Pages, Components, Responsive Design)    │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│            Business Logic Layer                     │
│  (Services: Notification, GraphQL, Storage)         │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│              Data Layer                             │
│  ┌──────────────┬──────────────┬────────────────┐   │
│  │ LeetCode API │ SharedPrefs  │ Device Storage │   │
│  │  (GraphQL)   │  (Local DB)  │ (Calendar)     │   │
│  └──────────────┴──────────────┴────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### **Data Flow**

```
1. User Input (Username)
         ↓
2. GraphQL Query to LeetCode API
         ↓
3. Receive User Data + Problem of Day + Contests
         ↓
4. Store in SharedPreferences (Cache)
         ↓
5. Render Dashboard with Live Data
         ↓
6. User Enables Reminders
         ↓
7. Notification Service Checks Problem Status
         ↓
8. Send Smart Reminders (Auto-stop if solved)
```

### **Notification Flow**

```
User Taps Bell Icon
         ↓
Check Problem Solved Status (3-point validation)
    • API status field
    • Recent submissions list
    • Submission calendar
         ↓
If Solved → Show "Already solved" message
If Unsolved → Start 2-hour reminders
         ↓
Every 2 hours (8AM-10PM):
    1. Check if problem still unsolved
    2. Send notification if unsolved
    3. Auto-cancel if solved
         ↓
User solves problem on LeetCode
         ↓
Next app load → Detect as solved → Auto-stop reminders
```

---

## 🚀 Installation & Setup

### **Prerequisites**

- Flutter SDK (v3.8.1+)
- Dart SDK
- Android SDK (API 33+) or iOS SDK
- Git
- VS Code or Android Studio

### **Step 1: Clone Repository**

```bash
git clone https://github.com/vskr-23/leetcodewidget.git
cd leetcodewidget
```

### **Step 2: Install Dependencies**

```bash
flutter clean
flutter pub get
```

### **Step 3: Run on Device**

**Android:**

```bash
# Connect Android device via USB
flutter devices  # Verify device is detected
flutter run -d <device-id>
```

**Windows:**

```bash
flutter run -d windows
```

**iOS:**

```bash
flutter run -d ios
```

**Web:**

```bash
flutter run -d chrome
```

### **Step 4: Setup LeetCode Username**

1. Open the app on your device
2. Enter your LeetCode username
3. Tap "Get Profile"
4. Dashboard loads with your live data!

---

## 📱 How to Use

### **Viewing Your Dashboard**

1. Open app → Enter LeetCode username
2. See your profile stats, badges, and progress
3. Scroll to view heatmap calendar and recent submissions

### **Setting Daily Reminders**

1. Look for "Problem of the Day" card
2. Tap the bell icon (🔔) next to the problem
3. Allow notifications when prompted
4. Receive reminders every 2 hours
5. Reminders auto-stop when you solve the problem

### **Adding Contests to Calendar**

1. Find "Upcoming Contests" section
2. Tap "Add to Calendar" button
3. Contest event added to your phone's calendar
4. Receive native phone reminders before contest

### **Viewing Your Activity**

1. Scroll to "Heatmap Calendar"
2. See your submission frequency (green intensity)
3. Hover/tap days to see submission count
4. View total streak and active days

---

## 📁 Project Structure

```
leetcodewidget/
├── lib/
│   ├── main.dart                      # App entry point & theme
│   ├── landing_page.dart              # Authentication/login
│   ├── dashboard_page.dart            # Main dashboard (★ CORE)
│   │
│   ├── services/
│   │   └── notification_service.dart  # Notification system (★ KEY)
│   │
│   ├── widgets/
│   │   ├── profile_card.dart          # User profile display
│   │   ├── problem_of_the_day.dart    # Daily problem widget (★ UNIQUE)
│   │   ├── upcoming_contest.dart      # Contest scheduler
│   │   ├── custom_heatmap.dart        # Interactive heatmap
│   │   ├── recent_submissions.dart    # Submission history
│   │   ├── stat_cards.dart            # Statistics display
│   │   ├── badges_section.dart        # Achievement badges
│   │   └── contest_stats.dart         # Competition stats
│   │
│   └── leetcode_profile_query.graphql # GraphQL queries
│
├── android/                           # Android-specific code
│   └── app/src/main/AndroidManifest.xml
│
├── ios/                               # iOS-specific code
├── windows/                           # Windows-specific code
├── web/                               # Web version
│
├── pubspec.yaml                       # Dependencies
├── pubspec.lock                       # Locked versions
├── PROJECT_SHOWCASE.md                # Portfolio documentation
└── README.md                          # This file
```

---

## 🎓 Implementation Details

### **GraphQL Query Example**

```graphql
query getUserProfile($username: String!) {
  matchedUser(username: $username) {
    username
    profile {
      realName
      userAvatar
      countryName
    }
    submitStats {
      acSubmissionNum {
        difficulty
        count
      }
    }
    userCalendar {
      submissionCalendar # Heatmap data
      streak # Current streak
    }
  }
  recentSubmissions(limit: 15) {
    title
    statusDisplay
    timestamp
  }
  activeDailyCodingChallengeQuestion {
    question {
      title
      difficulty
    }
    userStatus
  }
}
```

### **Notification Service Architecture**

```dart
NotificationService (Singleton)
├── initialize()                    # Setup channels
├── requestPermissions()            # OS permissions
├── startRecurringDailyReminders()  # Enable 2-hour reminders
├── isDailyProblemSolved()         # Smart detection
├── markDailyProblemAsSolved()     # Auto-stop logic
├── scheduleContestReminder()      # Contest alerts
└── addContestToCalendar()         # Calendar integration
```

### **Smart Problem Detection (3-Point Validation)**

```dart
Future<bool> isDailyProblemSolved() {
  // Check 1: API user status field
  if (userStatus == 'Finish' || userStatus == 'ac') return true;

  // Check 2: Recent submissions list
  if (recentSubmissions.any((s) =>
      s.titleSlug == dailyProblem.titleSlug &&
      s.status == 'Accepted')) return true;

  // Check 3: Submission calendar
  if (submissionCalendar[todayTimestamp] > 0) return true;

  return false;
}
```

---

## 📊 Key Metrics

| Metric                    | Value                            |
| ------------------------- | -------------------------------- |
| **Lines of Code**         | 2500+                            |
| **Dart Files**            | 15+                              |
| **Dependencies**          | 9 main packages                  |
| **API Integration**       | GraphQL (1 comprehensive query)  |
| **Platforms Supported**   | 4 (Android, iOS, Windows, Web)   |
| **Features**              | 6 major + 20+ sub-features       |
| **Mobile Devices Tested** | 1 physical + multiple emulations |

---

## 🔒 Security & Permissions

### **Required Android Permissions**

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.READ_CALENDAR" />
<uses-permission android:name="android.permission.WRITE_CALENDAR" />
```

### **Data Privacy**

- ✅ No user data stored on servers (except what LeetCode provides)
- ✅ Local storage only via SharedPreferences
- ✅ All API calls go directly to LeetCode
- ✅ No authentication tokens stored insecurely

---

## 🚀 Future Enhancements

1. **Analytics Dashboard**

   - Problem-solving trends
   - Performance metrics over time
   - Category-wise progress

2. **Social Features**

   - Compare stats with friends
   - Leaderboards
   - Challenge suggestions

3. **Advanced Scheduling**

   - Custom reminder times
   - Difficulty-based reminders
   - Streak-based notifications

4. **AI Integration**

   - Problem recommendations
   - Difficulty prediction
   - Interview preparation planning

5. **Offline Support**
   - Full offline mode
   - Sync when online
   - Cached problem statements

---

## 🤝 Contributing

This is a personal project for portfolio purposes. However, you can:

1. Fork the repository
2. Create a feature branch
3. Make improvements
4. Submit a pull request

---

## 📝 License

This project is open-sourced under the MIT License.

---

## 👨‍💻 Author

**Sai Kiran Reddy**

- GitHub: [@vskr-23](https://github.com/vskr-23)
- Email: vskr.cs.23@nitj.ac.in

---

## 🙏 Acknowledgments

- **LeetCode** - For providing the GraphQL API
- **Flutter Community** - For amazing libraries and support
- **Open Source** - For inspiration and tools

---

## 📞 Contact & Support

For questions, suggestions, or issues:

1. Create an issue on GitHub
2. Email: vskr.cs.23@nitj.ac.in
3. Check the PROJECT_SHOWCASE.md for detailed documentation

---

**Last Updated**: December 2025  
**Status**: ✅ Production Ready  
**Version**: 1.0.0  
**Device**: Samsung Galaxy S20 FE (Tested & Working)
