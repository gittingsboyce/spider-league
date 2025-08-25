# Firebase Schema Design - Spider League

## Overview
This document outlines the Firestore database structure for the Spider League iOS app, including collections, data models, and security rules.

## Collections Structure

### 1. Users Collection (`users`)
**Purpose**: Store user profiles and fight statistics

**Document ID**: `{userId}` (Firebase Auth UID)

**Fields**:
```typescript
{
  id: string,                    // Firebase Auth UID
  email: string,                 // User's email address
  fightName: string,             // User's chosen fight name
  wins: number,                  // Total wins count
  losses: number,                // Total losses count
  status: string,                // "Ready to Fight" | "Not Ready"
  town: string,                  // User's town (e.g., "Encinitas, CA")
  createdAt: timestamp,          // Account creation timestamp
  lastActive: timestamp,         // Last app activity timestamp
  profileImageUrl: string,       // Optional profile image URL
  isEmailVerified: boolean       // Email verification status
}
```

**Indexes**:
- `status` (for finding ready-to-fight users)
- `town` (for location-based matching)
- `status + town` (compound index for ready users in specific town)

### 2. Spiders Collection (`spiders`)
**Purpose**: Store registered spider information and images

**Document ID**: `{spiderId}` (auto-generated)

**Fields**:
```typescript
{
  id: string,                    // Auto-generated document ID
  userId: string,                // Reference to user who owns this spider
  species: string,               // Identified spider species
  deadlinessScore: number,       // Calculated deadliness score
  imageUrl: string,              // Stored image URL in Firebase Storage
  imageMetadata: {               // Image analysis data
    width: number,
    height: number,
    fileSize: number,
    takenAt: timestamp,          // When photo was taken (if available)
    location: {                  // GPS coordinates if available
      latitude: number,
      longitude: number
    }
  },
  geminiAnalysis: {              // Gemini API response data
    species: string,
    confidence: number,
    analysisTimestamp: timestamp
  },
  createdAt: timestamp,          // When spider was registered
  lastUsedInFight: timestamp,    // Last time this spider fought
  isActive: boolean              // Whether spider can still be used
}
```

**Indexes**:
- `userId` (for user's spider collection)
- `userId + createdAt` (for 24-hour cooldown enforcement)
- `deadlinessScore` (for fight calculations)

### 3. Challenges Collection (`challenges`)
**Purpose**: Store active challenges between users

**Document ID**: `{challengeId}` (auto-generated)

**Fields**:
```typescript
{
  id: string,                    // Auto-generated document ID
  challengerId: string,          // User ID of challenger
  challengedId: string,          // User ID of challenged user
  challengerSpiderId: string,    // Spider ID challenger wants to use
  status: string,                // "Pending" | "Accepted" | "Declined" | "Expired"
  expiresAt: timestamp,          // When challenge expires (24 hours)
  createdAt: timestamp,          // When challenge was created
  acceptedAt: timestamp,         // When challenge was accepted (if applicable)
  declinedAt: timestamp,         // When challenge was declined (if applicable)
  message: string                // Optional challenge message
}
```

**Indexes**:
- `challengerId` (for sent challenges)
- `challengedId` (for received challenges)
- `status` (for filtering active challenges)
- `expiresAt` (for cleanup of expired challenges)
- `challengedId + status` (for user's pending challenges)

### 4. Fights Collection (`fights`)
**Purpose**: Store completed fight results and history

**Document ID**: `{fightId}` (auto-generated)

**Fields**:
```typescript
{
  id: string,                    // Auto-generated document ID
  challengeId: string,           // Reference to original challenge
  challengerId: string,          // User ID of challenger
  challengedId: string,          // User ID of challenged user
  challengerSpiderId: string,    // Spider ID used by challenger
  challengedSpiderId: string,    // Spider ID used by challenged user
  winnerId: string,              // User ID of winner
  loserId: string,               // User ID of loser
  winnerSpiderId: string,        // Spider ID of winner
  loserSpiderId: string,         // Spider ID of loser
  outcome: {                     // Detailed fight outcome
    winnerScore: number,         // Winner's deadliness score
    loserScore: number,          // Loser's deadliness score
    winProbability: number,      // Calculated win probability
    modifiers: object            // Any scoring modifiers applied
  },
  completedAt: timestamp,        // When fight was completed
  isDraw: boolean,               // Whether fight resulted in draw
  rematchTriggered: boolean      // Whether rematch was triggered
}
```

**Indexes**:
- `challengerId` (for user's fight history)
- `challengedId` (for user's fight history)
- `winnerId` (for wins)
- `loserId` (for losses)
- `completedAt` (for chronological ordering)

## Security Rules Structure

### Basic Rules Pattern
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Users can read other users' basic profile info
    match /users/{userId} {
      allow read: if request.auth != null;
    }
    
    // Spiders belong to users
    match /spiders/{spiderId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Challenges have complex access rules
    match /challenges/{challengeId} {
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.challengerId || 
         request.auth.uid == resource.data.challengedId);
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.challengerId;
      allow update: if request.auth != null && 
        request.auth.uid == resource.data.challengedId;
    }
    
    // Fights are read-only after creation
    match /fights/{fightId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if false; // No updates allowed
    }
  }
}
```

## Data Relationships

### One-to-Many Relationships
- **User → Spiders**: A user can have multiple registered spiders
- **User → Challenges**: A user can send/receive multiple challenges
- **User → Fights**: A user can participate in multiple fights

### Many-to-One Relationships
- **Spider → User**: Each spider belongs to one user
- **Challenge → Users**: Each challenge involves two users
- **Fight → Users**: Each fight involves two users

### Referential Integrity
- All foreign key references use Firebase Auth UIDs for users
- Spider IDs are validated against the spiders collection
- Challenge IDs are validated against the challenges collection

## Performance Considerations

### Indexing Strategy
- Compound indexes for common query patterns
- Avoid deep nesting in documents
- Use array fields sparingly (prefer subcollections for large arrays)

### Query Optimization
- Limit query results with pagination
- Use composite indexes for complex filters
- Cache frequently accessed data locally

### Storage Optimization
- Compress images before upload
- Store image metadata separately from image data
- Use Firebase Storage for large binary files

## Future Considerations

### Scalability
- Consider sharding strategies for high-traffic scenarios
- Plan for geographic distribution of users
- Monitor query performance as data grows

### Analytics
- Add analytics fields for user behavior tracking
- Consider separate analytics collection for performance
- Plan for data export and backup strategies

### Advanced Features
- Real-time updates using Firestore listeners
- Offline support with local caching
- Push notification integration
- Advanced search and filtering capabilities
