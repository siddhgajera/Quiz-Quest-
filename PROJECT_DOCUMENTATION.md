# Quiz Quest - Complete Project Documentation

## 📱 Project Overview

**Quiz Quest** is a comprehensive mobile quiz application built with Flutter and Firebase, designed to provide an engaging learning experience through interactive quizzes with real-time leaderboards and performance tracking.

### Key Features
- 🎯 Interactive quiz system with multiple subjects and difficulty levels
- 📊 Real-time leaderboards (global and category-wise)
- 👥 Dual user roles: Regular Users and Administrators
- 📈 Performance analytics and progress tracking
- 🔐 Secure authentication with Firebase
- 💾 Cloud-based data storage with Firestore
- 🎨 Modern, intuitive user interface

---

## 🎯 Project Information

| Property | Details |
|----------|---------|
| **Project Name** | Quiz Quest |
| **Platform** | Flutter (Android/iOS) |
| **Backend** | Firebase (Auth, Firestore, Storage, Functions) |
| **Language** | Dart |
| **SDK Version** | ^3.8.1 |
| **State Management** | Provider |
| **Database** | Cloud Firestore (NoSQL) |
| **Authentication** | Firebase Authentication |

---

## 🏗️ System Architecture

### Technology Stack

#### Frontend
- **Framework:** Flutter 3.8.1+
- **Language:** Dart
- **UI Components:** Material Design 3
- **State Management:** Provider package
- **Image Handling:** image_picker, cached_network_image
- **Charts:** fl_chart for performance graphs

#### Backend
- **Authentication:** Firebase Authentication
- **Database:** Cloud Firestore
- **Storage:** Firebase Storage
- **Functions:** Cloud Functions (optional)
- **Hosting:** Firebase Hosting (for web version)

#### Key Dependencies
```yaml
firebase_core: ^3.6.0
firebase_auth: ^5.3.1
cloud_firestore: ^5.4.3
firebase_storage: ^12.3.2
provider: ^6.1.2
fl_chart: ^0.69.0
image_picker: ^1.0.7
cached_network_image: ^3.3.1
intl: ^0.19.0
```

---

## 📂 Project Structure

```
quiz_quest/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── firebase_options.dart              # Firebase configuration
│   ├── auth_wrapper.dart                  # Authentication wrapper
│   │
│   ├── services/                          # Business logic layer
│   │   ├── auth_service.dart              # Authentication operations
│   │   ├── score_service.dart             # Quiz scoring & leaderboards
│   │   ├── question_service.dart          # Question management
│   │   └── activity_service.dart          # Activity logging
│   │
│   ├── models/                            # Data models
│   │   ├── user_model.dart                # User entity
│   │   ├── question_model.dart            # Question entity
│   │   └── activity_model.dart            # Activity entity
│   │
│   ├── screens/                           # UI screens
│   │   ├── User Screens/
│   │   │   ├── home_screen.dart           # User home
│   │   │   ├── quiz_screen.dart           # Quiz interface
│   │   │   ├── result_screen.dart         # Quiz results
│   │   │   ├── profile_screen.dart        # User profile
│   │   │   └── leaderboard_screen.dart    # Rankings
│   │   │
│   │   └── Admin Screens/
│   │       ├── admin_dashboard.dart       # Admin overview
│   │       ├── question_management.dart   # Manage questions
│   │       ├── user_management.dart       # Manage users
│   │       └── activity_logs.dart         # View activities
│   │
│   ├── widgets/                           # Reusable components
│   │   ├── activity_widgets.dart          # Activity displays
│   │   ├── performance_graph_widget.dart  # Performance charts
│   │   ├── profile_stats_cards.dart       # Stats cards
│   │   └── quiz_performance_widget.dart   # Quiz metrics
│   │
│   └── providers/                         # State management
│       ├── admin_stats_provider.dart      # Admin statistics
│       └── activity_provider.dart         # Activity state
│
├── android/                               # Android configuration
├── ios/                                   # iOS configuration
├── web/                                   # Web configuration
├── images/                                # App assets
├── test/                                  # Unit tests
├── pubspec.yaml                           # Dependencies
└── README.md                              # Project readme
```

---

## 🗄️ Database Schema

### Firestore Collections

#### 1. **users** Collection
Stores user profiles and statistics.

```javascript
{
  uid: "string",                    // Primary Key
  email: "user@example.com",
  name: "John Doe",
  role: "user" | "admin",
  totalScore: 1500,
  quizzesCompleted: 25,
  averageScore: 60,
  highestScore: 95,
  profileImageUrl: "https://...",
  isActive: true,
  createdAt: Timestamp,
  lastActive: Timestamp
}
```

#### 2. **quizAttempts** Collection
Records all quiz attempts.

```javascript
{
  id: "string",                     // Auto-generated
  uid: "string",                    // Foreign Key → users
  subject: "Math",
  difficulty: "medium",
  totalQuestions: 10,
  correctAnswers: 7,
  score: 140,
  percentage: 70,
  timeTakenSeconds: 300,
  createdAt: Timestamp
}
```

#### 3. **questions** Collection
Stores quiz questions.

```javascript
{
  id: "string",
  subject: "Science",
  difficulty: "hard",
  questionText: "What is photosynthesis?",
  options: ["Option A", "Option B", "Option C", "Option D"],
  correctAnswer: 2,                 // Index of correct option
  explanation: "Detailed explanation...",
  createdAt: Timestamp
}
```

#### 4. **activities** Collection
Logs user activities for admin monitoring.

```javascript
{
  id: "string",
  uid: "string",
  type: "quizCompleted" | "userLogin" | "profileUpdated",
  title: "Quiz Completed",
  description: "Completed Math quiz with 80% score",
  metadata: {
    subject: "Math",
    score: 80
  },
  timestamp: Timestamp
}
```

#### 5. **users/{uid}/categoryStats** Subcollection
Tracks performance per subject.

```javascript
{
  subject: "Math",                  // Document ID
  attempts: 10,
  correct: 75,
  score: 1500,
  averageScore: 150,
  accuracy: 75,
  lastDifficulty: "medium",
  lastAttempt: Timestamp
}
```

---

## 👥 User Roles & Permissions

### Regular User
**Capabilities:**
- ✅ Take quizzes in various subjects
- ✅ View personal statistics and history
- ✅ Check leaderboard rankings
- ✅ Update profile information
- ✅ Change password
- ✅ View performance analytics

**Restrictions:**
- ❌ Cannot add/edit/delete questions
- ❌ Cannot manage other users
- ❌ Cannot access admin dashboard
- ❌ Cannot view system-wide analytics

### Administrator
**Capabilities:**
- ✅ All regular user capabilities
- ✅ Add, edit, delete quiz questions
- ✅ Manage users (promote/demote, activate/deactivate)
- ✅ View all user activities
- ✅ Access system-wide analytics
- ✅ Manage leaderboards
- ✅ View detailed statistics

---

## 🔐 Security & Authentication

### Firebase Security Rules

#### Authentication
- Email/password authentication
- Email verification required
- Password reset functionality
- Session management with automatic token refresh

#### Firestore Rules
```javascript
// Users can read/write their own data
match /users/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == userId || isAdmin();
}

// Quiz attempts - users can only create their own
match /quizAttempts/{attemptId} {
  allow read: if request.auth != null;
  allow create: if request.auth.uid == request.resource.data.uid;
}

// Questions - read-only for users, full access for admins
match /questions/{questionId} {
  allow read: if request.auth != null;
  allow write: if isAdmin();
}

// Activities - admin only
match /activities/{activityId} {
  allow read, write: if isAdmin();
}

function isAdmin() {
  return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

---

## 🎮 Core Features

### 1. Quiz System

#### Quiz Flow
1. User selects subject (Math, Science, History, etc.)
2. Chooses difficulty level (Easy, Medium, Hard)
3. System loads 10 random questions
4. User answers questions with timer
5. Submits quiz for scoring
6. Views results with correct answers and explanations

#### Scoring System
- **Easy:** 10 points per correct answer
- **Medium:** 20 points per correct answer
- **Hard:** 30 points per correct answer

### 2. Leaderboard System

#### Global Leaderboard
- Ranks all active users by total score
- Top 3 users get special badges (🥇🥈🥉)
- Real-time updates when scores change
- Shows: Rank, Name, Total Score, Quizzes Completed

#### Category Leaderboard
- Subject-specific rankings
- Filter by category
- Shows: Rank, Subject, Score, Accuracy

### 3. Performance Analytics

#### User Statistics
- Total quizzes completed
- Average score
- Highest score
- Total points earned
- Performance trends over time

#### Performance Graph
- Line chart showing last 10 quiz scores
- Color-coded performance levels:
  - 🟢 Green (80%+): Excellent
  - 🔵 Blue (60-79%): Good
  - 🟠 Orange (40-59%): Fair
  - 🔴 Red (<40%): Needs Work

### 4. Activity Logging

Tracks all user actions:
- User registration
- Login/logout
- Quiz completion
- Profile updates
- Password changes
- Admin actions (question management, user management)

---

## 🚀 Installation & Setup

### Prerequisites
- Flutter SDK 3.8.1 or higher
- Dart SDK
- Android Studio / VS Code
- Firebase account
- Git

### Step 1: Clone Repository
```bash
git clone <repository-url>
cd quiz_quest
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Firebase Setup
1. Create a Firebase project at https://console.firebase.google.com
2. Add Android/iOS apps to Firebase project
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Place configuration files in respective directories
5. Enable Firebase Authentication (Email/Password)
6. Create Firestore database
7. Deploy security rules from `firestore.rules`

### Step 4: Run Application
```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

---

## 📱 Build & Deployment

### Android

#### Debug Build
```bash
flutter build apk --debug
```

#### Release Build
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

#### App Bundle (Google Play)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

---

## 🧪 Testing

### Run Tests
```bash
# All tests
flutter test

# Specific test file
flutter test test/widget_test.dart

# With coverage
flutter test --coverage
```

### Code Analysis
```bash
flutter analyze
```

---

## 📊 Performance Optimization

### Implemented Optimizations
1. **Cached Network Images:** Profile images cached locally
2. **Pagination:** Leaderboards limited to top 100
3. **Real-time Streams:** Efficient Firebase listeners
4. **Lazy Loading:** Questions loaded on-demand
5. **Batch Writes:** Multiple Firestore updates in single transaction
6. **Index Optimization:** Firestore indexes for common queries

---

## 🐛 Known Issues & Solutions

### Issue: Deprecated API Warnings
**Status:** Non-critical  
**Impact:** None (warnings only)  
**Solution:** Will be resolved in future package updates

### Issue: Print Statements in Production
**Status:** Minor  
**Impact:** Minimal (auto-removed in release builds)  
**Solution:** Can be removed for cleaner logs

---

## 🔄 Future Enhancements

### Planned Features
- [ ] Multi-language support
- [ ] Dark mode theme
- [ ] Offline quiz mode
- [ ] Social sharing of achievements
- [ ] Timed quiz challenges
- [ ] Custom quiz creation by users
- [ ] Achievement badges system
- [ ] Push notifications
- [ ] Quiz categories expansion
- [ ] Export performance reports

---

## 👨‍💻 Development Team

### Roles
- **Developer:** [Your Name]
- **Project Type:** Academic/Personal Project
- **Development Period:** [Start Date] - [End Date]

---

## 📄 License

This project is developed for educational purposes.

---

## 📞 Support & Contact

For issues, questions, or contributions:
- **Email:** [your-email@example.com]
- **GitHub:** [repository-link]

---

## 📚 Additional Resources

### Documentation Files
- `Quiz_Quest_Documentation_Diagrams.html` - Visual diagrams and architecture
- `README.md` - Quick start guide
- `firestore.rules` - Database security rules
- `firebase.json` - Firebase configuration

### External Resources
- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Dart Documentation](https://dart.dev/guides)

---

## 🎯 Conclusion

Quiz Quest is a fully functional, production-ready quiz application demonstrating modern mobile development practices with Flutter and Firebase. The application showcases real-time data synchronization, secure authentication, role-based access control, and comprehensive analytics.

**Key Achievements:**
- ✅ Zero critical errors
- ✅ Clean architecture with separation of concerns
- ✅ Real-time features with Firebase
- ✅ Responsive and intuitive UI
- ✅ Comprehensive security implementation
- ✅ Scalable database design

---

*Last Updated: December 2025*
*Version: 1.0.0*
