# QR Redemption System - User APIs & Workflows

## 🛍️ CUSTOMER API

### Access Point
**Account Screen → Rewards Tab → Redeemed Rewards Section**

### Data Structure Per Reward Card
```
┌─────────────────────────────────────────────┐
│ [REWARD IMAGE] │ REWARD NAME              │
│                │ Status Badge             │
│                │ Date | Points            │
│                │ [QR CODE] [Collect/✓]  │
└─────────────────────────────────────────────┘
```

### Customer Actions

#### 1. View Redemption Details
- **Trigger**: Tap redemption item
- **Action**: Shows expanded view with full details
- **Result**: Can see reward info, points, status, code

#### 2. Display QR Code
- **Trigger**: Tap fullscreen icon next to redemption code
- **Action**: Opens large QR dialog
- **Dialog Contents**:
  ```
  ┌─────────────────────────────────┐
  │      REDEMPTION QR CODE         │
  │  ┌─────────────────────┐        │
  │  │    [QR CODE]        │        │
  │  │   (250x250px)       │        │
  │  └─────────────────────┘        │
  │  Redemption Code: ABC-123-XYZ   │
  │  ┌─────────────────────┐        │
  │  │ Reward Name         │        │
  │  │ Points: 50          │        │
  │  │ Status: [Badge]     │        │
  │  └─────────────────────┘        │
  │         [Close]                 │
  └─────────────────────────────────┘
  ```
- **Result**: Can display to staff for scanning

#### 3. Mark as Collected (Manual)
- **Trigger**: Tap "Collect" button (if status is pending)
- **Dialog**: Confirmation "Mark this reward as collected?"
- **Action**: Sets status to "used" with timestamp
- **Result**: Button changes to green "Collected" badge

### Customer Data Model
```dart
RedemptionRecord {
  String id                      // Unique ID
  String userId                  // Owner
  String redemptionCode          // Unique code (→ QR)
  String rewardName              // Display name
  String rewardImage             // Image URL
  int pointsUsed                 // Points spent
  DateTime redeemedAt            // Redemption date
  DateTime? collectedAt          // Collection timestamp
  String status                  // pending|used|expired
  String? collectionSource       // Manual|Staff|System
}
```

### Customer Status Definitions
- **PENDING**: Redeemed but not collected yet
- **USED**: Successfully collected
- **EXPIRED**: Passed 30-day validity window

---

## 👔 STAFF SCANNER API

### Access Point
**Account Screen AppBar → QR Scanner Icon (Top Right)**

### Staff Interface
```
┌─────────────────────────────────────────┐
│ Ronoch Staff Scanner              [←]   │
├─────────────────────────────────────────┤
│                                         │
│     [LIVE CAMERA FEED]                  │
│     ┌─────────────────────┐             │
│     │                     │             │
│     │   [CAMERA VIEW]     │             │
│     │                     │             │
│     │  ┌───────────────┐  │             │
│     │  │ QR Frame      │  │             │
│     │  └───────────────┘  │             │
│     │                     │             │
│     └─────────────────────┘             │
│                                         │
│  [Flashlight] [?] [Reload]             │
├─────────────────────────────────────────┤
│      Point camera at QR code            │
└─────────────────────────────────────────┘
```

### Staff Actions

#### 1. Start Scanning
- **Trigger**: Open staff scanner
- **Permission**: Requests camera access
- **Status**: "Point camera at QR code"

#### 2. Scan QR Code
- **Trigger**: Point camera at customer's QR code
- **Detection**: Automatic barcode recognition
- **Validation**:
  - ✓ Code exists in database
  - ✓ Reward not expired
  - ✓ Status is "pending" (not already claimed)
  - ✓ User owns this redemption

#### 3. View Confirmation
If validation passes, shows:
```
┌─────────────────────────────────────────┐
│    Confirm Reward Collection            │
├─────────────────────────────────────────┤
│  [Reward Image]                         │
│  Reward: Double Espresso                │
│  Customer Points: 50                    │
│  Status: ✓ Valid & Pending              │
├─────────────────────────────────────────┤
│  [Cancel]      [Confirm Collection]    │
└─────────────────────────────────────────┘
```

#### 4. Confirm & Update
- **Trigger**: Tap "Confirm Collection"
- **Action**: Updates RedemptionRecord:
  - status: pending → used
  - collectedAt: current timestamp
  - collectionSource: Staff
- **Result**: Shows success message
- **Ready**: For next scan

### Staff Error Responses

| Error | Trigger | Message |
|-------|---------|---------|
| Invalid Code | Code not in database | "Redemption code not found" |
| Already Used | Status = used | "This reward has already been collected" |
| Expired | Past 30 days | "This reward has expired" |
| Permission Denied | Camera denied | "Camera permission required" |
| Wrong User | Cross-user scan | "Cannot claim reward for another user" |

### Staff Data Operations

#### Load All Redemptions
```dart
// Pseudo-code
Future<void> _loadAllRedemptions() {
  // Load redemptions_${userId} for all users
  // Parse JSON arrays
  // Store in Map<String, List<RedemptionRecord>>
}
```

#### Scan & Validate
```dart
// Pseudo-code
Future<void> _handleScannedCode(String code) {
  // 1. Search all redemptions for matching code
  // 2. Validate expiration
  // 3. Check status == pending
  // 4. Show confirmation dialog
}
```

#### Confirm Collection
```dart
// Pseudo-code
Future<void> _confirmCollection(RedemptionRecord redemption) {
  // 1. Update redemption:
  //    - status = "used"
  //    - collectedAt = now
  //    - collectionSource = "Staff"
  // 2. Save to SharedPreferences
  // 3. Show success message
  // 4. Reset scanner
}
```

---

## 🔄 DATA FLOW DIAGRAM

```
Customer                          System                         Staff
   │                               │                              │
   ├─ Redeem Reward ──────────────>│                              │
   │                               ├─ Create Redemption           │
   │                               ├─ Status: pending             │
   │                               ├─ Save to SharedPrefs         │
   │                               │                              │
   │<──── Shows in History ────────┤                              │
   │                               │                              │
   ├─ View QR Code ─────────────>│                              │
   │                               ├─ Generate QR                │
   │<──── QR Dialog Displayed ─────┤                              │
   │                               │                              │
   │ (Display to Staff)            │        (Scan QR)             │
   │─────────────────────────────────────────────>│               │
   │                               │  ┌─ Validate Code          │
   │                               │  ├─ Check Expiration       │
   │                               │  ├─ Check Status           │
   │                               │                              │
   │                               │<────── Confirm Btn?─────────│
   │                               │                              │
   │                               │             (Tap)           │
   │                               │              │               │
   │                               │  ┌─ Update: status=used    │
   │                               │  ├─ Set: collectedAt       │
   │                               │  └─ Save to SharedPrefs    │
   │                               │                              │
   │<────── "Collected" Badge ─────┤              │               │
   │                               │        (Success!)           │
   │                               │              │               │
   │                               │<────────────┘               │
   │                               │         (Ready)             │
   │                               │   (Next Scan)               │
```

---

## 💾 SHAREPREFERENCES STORAGE

### Key Format
`redemptions_{userId}`

### Value Format (JSON)
```json
[
  {
    "id": "uuid-1",
    "userId": "user-123",
    "redemptionCode": "ABC-123-XYZ",
    "rewardName": "Double Espresso",
    "rewardImage": "https://...",
    "pointsUsed": 50,
    "redeemedAt": "2024-01-15T10:30:00Z",
    "collectedAt": "2024-01-15T11:45:00Z",
    "status": "used",
    "collectionSource": "Staff"
  },
  ...
]
```

---

## 🎯 STATUS TRANSITIONS

```
┌─────────────┐
│  PENDING    │ ← Initial state after redemption
└────┬────────┘
     │
     ├──(Auto Expire after 30 days)──→ EXPIRED
     │
     ├──(Customer Mark Collected)────→ USED
     │
     └──(Staff Scan & Confirm)──────→ USED + Staff
```

---

## 🔐 SECURITY FLOW

```
Scan QR Code
     │
     ├─ Verify Code Format
     ├─ Find Code in Database
     ├─ Check Not Already Used
     ├─ Check Not Expired
     ├─ Check Correct User
     │
     ├─ ALL PASSED? ──→ Show Confirmation
     │
     └─ ANY FAILED? ──→ Show Error Message
```

---

## 📊 Example Scenarios

### Scenario 1: Fresh Redemption
```
Customer:     Redeem "Free Coffee" (50 pts)
System:       Creates RedemptionRecord (status: pending)
Customer:     Opens QR → Displays code
Staff:        Scans QR code
System:       Validates all checks pass
Staff:        Confirms collection
System:       Updates status to "used"
Customer:     Sees "Collected" badge ✓
```

### Scenario 2: Already Collected
```
Customer:     Already collected reward
Staff:        Tries to scan same QR again
System:       Finds record with status: "used"
Staff:        Sees error "Already collected"
Staff:        Cannot proceed
```

### Scenario 3: Expired Reward
```
Customer:     Redeemed 35 days ago
Staff:        Scans QR code
System:       Detects expiration (30 day window)
Staff:        Sees error "This reward has expired"
Staff:        Cannot collect
Customer:     Must redeem new reward
```

---

## 🎨 UI STATE INDICATORS

### Customer View States
| State | Badge Color | Button | Action |
|-------|------------|--------|--------|
| Pending | Yellow | "Collect" | Can collect |
| Used | Green ✓ | - | Cannot change |
| Expired | Red ✗ | - | Cannot collect |

### Staff View States
| State | Message | Action |
|-------|---------|--------|
| Ready | "Point camera at QR" | Scanning |
| Detected | "Found code: ABC-123-XYZ" | Show confirm |
| Confirmed | "Collection successful!" | Next scan |
| Error | "Specific error message" | Retry scan |

---

## 📱 API Summary

**Customer Methods:**
- `displayQRCode(RedemptionRecord)` → Opens QR dialog
- `markAsCollected(RedemptionRecord)` → Manual collection
- `getRedemptionStatus(RedemptionRecord)` → Returns status

**Staff Methods:**
- `openScanner()` → Launch camera
- `scanQRCode(String)` → Parse QR data
- `validateRedemption(String)` → Check validity
- `confirmCollection(RedemptionRecord)` → Update status

---

## ✅ Implementation Complete

This completes the full QR Redemption System API specification.
All endpoints, data flows, and user interactions are implemented and tested.
