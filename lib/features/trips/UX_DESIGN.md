R# Trip / Outing Feature - Frontend UX Design

## Design Philosophy

**Trips are optional, lightweight, and contextual.** They should enhance expense tracking without adding friction. When active, they're visible; when inactive, they're invisible.

---

## Core UX Principles

1. **Optional by Default**: Trips never block expense entry
2. **Contextual Visibility**: Show Trip UI only when relevant
3. **Lightweight Creation**: Minimal friction to start a Trip
4. **Persistent Awareness**: Active Trips are always visible
5. **Silent When Inactive**: No Trip UI when no Trip is active

---

## Screen-by-Screen UX Flow

### 1. HOME SCREEN - No Active Trip

**State**: No active Trip exists

**UI Elements**:
- Standard home screen layout
- No Trip-related UI visible
- Expense entry buttons work normally

**Microcopy**: None (Trip UI is invisible)

**Rationale**: Users shouldn't be reminded of a feature they're not using.

---

### 2. HOME SCREEN - Active Trip

**State**: One or more active Trips exist

**UI Elements**:

#### A. Active Trip Banner (Top of Screen)
```
┌─────────────────────────────────────────┐
│ 🧳 Restaurant – Terra Kulture          │
│ Active Trip                              │
│ [View Trip] [End Trip]                  │
└─────────────────────────────────────────┘
```

**Design Specs**:
- Position: Below app bar, above spending summary
- Background: Subtle gradient (primary color with 10% opacity)
- Height: 60-70px
- Padding: 16px horizontal, 12px vertical
- Border radius: 12px
- Shadow: Subtle elevation

**Components**:
- Trip icon (🧳 or custom icon)
- Trip name (bold, 16px)
- "Active Trip" label (secondary text, 12px)
- Two action buttons:
  - "View Trip" (primary action, outlined button)
  - "End Trip" (secondary action, text button)

**Microcopy**:
- Banner title: "{Trip Name}"
- Subtitle: "Active Trip"
- Primary action: "View Trip"
- Secondary action: "End Trip"

**Interactions**:
- Tap "View Trip" → Navigate to Trip Details Screen
- Tap "End Trip" → Show confirmation dialog → Close Trip
- Tap banner (non-button area) → Navigate to Trip Details Screen

**Rationale**: 
- Always visible when active (principle #4)
- Quick actions without navigation
- Clear visual hierarchy

---

#### B. Expense Entry Context Indicator

**Location**: Near expense entry buttons (Add Expense, Scan Receipt, Voice Input)

**UI Elements**:
```
┌─────────────────────────────────────────┐
│ [➕ Add Expense]                       │
│ Adding to: Restaurant – Terra Kulture  │
└─────────────────────────────────────────┘
```

**Design Specs**:
- Position: Below expense entry buttons
- Text style: Secondary text, 13px, italic
- Color: Theme secondary text color with 70% opacity
- Icon: Small trip icon (12px) before text

**Microcopy**: "Adding to: {Trip Name}"

**Rationale**: 
- Subtle reminder without being intrusive
- Confirms auto-attachment behavior
- Non-blocking (doesn't require action)

---

### 3. EXPENSE ENTRY SCREENS - Active Trip

**State**: Trip is active during expense creation

**UI Elements**:

#### A. Add Expense Screen (Step 2 - Details)

**Location**: After "Payment Method" field

**UI Elements**:
```
┌─────────────────────────────────────────┐
│ Trip / Outing                            │
│ Restaurant – Terra Kulture  [Change]    │
└─────────────────────────────────────────┘
```

**Design Specs**:
- Same styling as other input fields (Date, Payment Method)
- Pre-filled with active Trip name
- "Change" button allows:
  - Switch to another active Trip
  - Remove Trip (set to "None")
  - Create new Trip

**Microcopy**:
- Label: "Trip / Outing"
- Value: "{Trip Name}" or "None"
- Change button: "Change"

**Interactions**:
- Tap field → Show Trip selection modal
- Modal options:
  - Current Trip (selected, disabled)
  - Other active Trips (if multiple)
  - "None" (removes Trip)
  - "Create New Trip" (bottom of list)

**Rationale**:
- Consistent with existing form fields
- Allows override if needed
- Non-mandatory (can be removed)

---

#### B. Scan Receipt Screen

**State**: Trip is active

**UI Elements**:
- Same context indicator as Home Screen
- Trip auto-attached to scanned expense
- Option to change Trip in review step

**Microcopy**: "Adding to: {Trip Name}" (subtle text below scan button)

---

#### C. Voice Input Screen

**State**: Trip is active

**UI Elements**:
- Same context indicator as Home Screen
- Trip auto-attached to voice expense
- Option to change Trip in review step

**Microcopy**: "Adding to: {Trip Name}" (subtle text below voice button)

---

### 4. TRIP DETAILS SCREEN

**Purpose**: View and manage a Trip

**UI Elements**:

#### Header Section
```
┌─────────────────────────────────────────┐
│ 🧳 Restaurant – Terra Kulture          │
│ Started: Jan 15, 2024 at 2:30 PM       │
│ Status: Active                         │
│ [End Trip] [Share Trip]                │
└─────────────────────────────────────────┘
```

**Design Specs**:
- Trip icon and name (large, prominent)
- Start time (secondary text)
- Status badge (Active/Closed)
- Action buttons (End Trip, Share Trip)

#### Expenses List Section
```
┌─────────────────────────────────────────┐
│ Expenses (5)                             │
│ ─────────────────────────────────────── │
│ • Lunch at Restaurant    $45.00         │
│ • Drinks                  $12.00         │
│ • Appetizers              $18.00         │
│ • Dessert                 $8.00          │
│ • Tax & Tip              $7.00          │
│ ─────────────────────────────────────── │
│ Total: $90.00                           │
└─────────────────────────────────────────┘
```

**Design Specs**:
- List of expenses linked to Trip
- Each expense shows: title, amount
- Tap expense → Navigate to Expense Details
- Total at bottom (bold, larger font)

#### Messages Section (if shared)
```
┌─────────────────────────────────────────┐
│ Messages                                │
│ ─────────────────────────────────────── │
│ System: Trip started                    │
│ John: This expense was for appetizers   │
│ System: Sarah joined the trip           │
└─────────────────────────────────────────┘
```

**Design Specs**:
- Collapsible section
- System messages (gray, italic)
- User messages (normal text)
- Timestamp for each message

#### Participants Section (if shared)
```
┌─────────────────────────────────────────┐
│ Participants (3)                         │
│ ─────────────────────────────────────── │
│ 👤 You (Owner)                           │
│ 👤 John Doe                              │
│ 👤 Sarah Smith                            │
└─────────────────────────────────────────┘
```

**Design Specs**:
- List of participants
- Owner badge for trip creator
- Invite button (if owner)

#### Actions Section
```
┌─────────────────────────────────────────┐
│ [End Trip]                              │
│ [Share Trip] (if private)                │
│ [Add Message] (if shared)                │
└─────────────────────────────────────────┘
```

**Microcopy**:
- "End Trip" → Confirmation: "End this trip? You can't add more expenses after closing."
- "Share Trip" → Opens participant invitation flow
- "Add Message" → Opens message input

---

### 5. TRIPS LIST SCREEN

**Purpose**: View all Trips (active and closed)

**Access**: 
- From Home Screen: Tap "View Trip" in banner
- From Navigation: "Trips" menu item (secondary)

**UI Elements**:

#### Active Trips Section
```
┌─────────────────────────────────────────┐
│ Active Trips                            │
│ ─────────────────────────────────────── │
│ 🧳 Restaurant – Terra Kulture          │
│    Started: Jan 15, 2:30 PM             │
│    5 expenses • $90.00                  │
│    [View] [End]                          │
│                                          │
│ 🧳 Weekend Grocery Shopping             │
│    Started: Jan 15, 10:00 AM             │
│    3 expenses • $125.50                  │
│    [View] [End]                          │
└─────────────────────────────────────────┘
```

**Design Specs**:
- Card-based layout
- Each Trip shows:
  - Icon and name
  - Start time
  - Expense count and total
  - Quick actions (View, End)
- Tap card → Navigate to Trip Details

#### Closed Trips Section
```
┌─────────────────────────────────────────┐
│ Past Trips                             │
│ ─────────────────────────────────────── │
│ 🧳 Restaurant – Terra Kulture          │
│    Jan 10, 2024 • 2:00 PM - 4:30 PM   │
│    8 expenses • $150.00                │
│    [View Summary]                       │
└─────────────────────────────────────────┘
```

**Design Specs**:
- Same card layout
- Shows date range (start - end)
- Read-only (no edit actions)
- "View Summary" button

#### Empty State
```
┌─────────────────────────────────────────┐
│                                        │
│         🧳                              │
│                                        │
│    No trips yet                        │
│    Start a trip to group expenses      │
│                                        │
│    [Start Trip]                        │
│                                        │
└─────────────────────────────────────────┘
```

**Microcopy**:
- Title: "No trips yet"
- Subtitle: "Start a trip to group expenses"
- Action: "Start Trip"

---

### 6. TRIP CREATION FLOW

#### A. Explicit Creation

**Trigger**: "Start Trip" button (from Trips List or Home)

**UI Flow**:
1. Show bottom modal:
```
┌─────────────────────────────────────────┐
│ Start Trip                              │
│ ─────────────────────────────────────── │
│ Trip Name                               │
│ [___________________________]          │
│                                         │
│ e.g., "Restaurant – Terra Kulture"     │
│                                         │
│ [Cancel]              [Start Trip]      │
└─────────────────────────────────────────┘
```

**Design Specs**:
- Modal height: 40% of screen
- Single text input (Trip name)
- Placeholder: Example name
- Validation: Name is optional (can be empty)
- Actions: Cancel (left), Start Trip (right, primary)

**Microcopy**:
- Title: "Start Trip"
- Input label: "Trip Name"
- Placeholder: "e.g., Restaurant – Terra Kulture"
- Cancel: "Cancel"
- Primary action: "Start Trip"

**Rationale**:
- Minimal friction (only name required)
- Optional name (can be auto-generated)
- Quick modal (no full screen)

---

#### B. Implicit Creation (After First Expense)

**Trigger**: User adds expense when no Trip is active

**UI Flow**:
1. After expense is saved, show bottom sheet:
```
┌─────────────────────────────────────────┐
│ Group this expense?                     │
│ ─────────────────────────────────────── │
│ Create a trip to group related expenses │
│                                         │
│ Trip Name                               │
│ [___________________________]          │
│                                         │
│ [Skip]              [Create Trip]       │
└─────────────────────────────────────────┘
```

**Design Specs**:
- Appears after expense save success
- Non-blocking (can be dismissed)
- Auto-fills Trip name from expense title
- "Skip" dismisses without creating Trip
- "Create Trip" creates Trip and links expense

**Microcopy**:
- Title: "Group this expense?"
- Subtitle: "Create a trip to group related expenses"
- Skip: "Skip"
- Primary action: "Create Trip"

**Rationale**:
- Discoverable (shows after first expense)
- Non-intrusive (can be skipped)
- Helpful (suggests grouping)

---

### 7. TRIP SELECTION MODAL

**Purpose**: Change Trip for an expense

**UI Elements**:
```
┌─────────────────────────────────────────┐
│ Select Trip / Outing                    │
│ ─────────────────────────────────────── │
│ ☑️ Restaurant – Terra Kulture          │
│    (Current)                             │
│                                          │
│ ○ Weekend Grocery Shopping              │
│                                          │
│ ○ None                                  │
│    (Don't link to a trip)                │
│                                          │
│ ─────────────────────────────────────── │
│ [Create New Trip]                        │
└─────────────────────────────────────────┘
```

**Design Specs**:
- Radio button selection
- Current Trip is pre-selected
- "None" option always available
- "Create New Trip" at bottom (separated)

**Microcopy**:
- Title: "Select Trip / Outing"
- Current indicator: "(Current)"
- None option: "Don't link to a trip"
- Create action: "Create New Trip"

---

## Component Structure

### Core Components

1. **ActiveTripBanner**
   - Location: Home Screen (top)
   - Props: `trip: TripEntity`, `onView: () => void`, `onEnd: () => void`
   - State: None (stateless)

2. **TripContextIndicator**
   - Location: Expense entry areas
   - Props: `trip: TripEntity?`
   - State: None (stateless, hidden if trip is null)

3. **TripSelectionField**
   - Location: Add Expense Screen
   - Props: `selectedTrip: TripEntity?`, `onChange: (TripEntity?) => void`
   - State: Modal open/closed

4. **TripDetailsScreen**
   - Location: Full screen
   - Props: `tripId: String`
   - State: Trip data, expenses, messages, participants

5. **TripsListScreen**
   - Location: Full screen
   - Props: None
   - State: Active trips, closed trips

6. **CreateTripModal**
   - Location: Bottom sheet
   - Props: `onCreate: (name: String?) => void`, `onCancel: () => void`
   - State: Trip name input

7. **EndTripConfirmationDialog**
   - Location: Dialog
   - Props: `trip: TripEntity`, `onConfirm: () => void`, `onCancel: () => void`
   - State: None

---

## UI States

### State 1: No Active Trip
- **Home Screen**: No Trip UI visible
- **Expense Entry**: Normal flow, no Trip field
- **Trips List**: Shows "Start Trip" empty state or past trips only

### State 2: Single Active Trip
- **Home Screen**: Active Trip banner visible
- **Expense Entry**: Context indicator visible, Trip field pre-filled
- **Trips List**: Shows active Trip + past trips

### State 3: Multiple Active Trips
- **Home Screen**: Active Trip banner shows most recent (or allow switching)
- **Expense Entry**: Trip selection shows all active Trips
- **Trips List**: Shows all active Trips + past trips

### State 4: Trip Closing
- **Confirmation**: Dialog appears
- **After Close**: Banner disappears, Trip moves to "Past Trips"
- **Summary**: Read-only summary generated

---

## Microcopy Library

### Home Screen
- Active Trip Banner: "Active Trip"
- View Action: "View Trip"
- End Action: "End Trip"
- Context Indicator: "Adding to: {Trip Name}"

### Expense Entry
- Trip Field Label: "Trip / Outing"
- Change Button: "Change"
- None Option: "None"

### Trip Details
- Header: "{Trip Name}"
- Start Time: "Started: {Date} at {Time}"
- Status: "Active" / "Closed"
- Expenses Section: "Expenses ({count})"
- Total: "Total: {amount}"
- Messages Section: "Messages"
- Participants Section: "Participants ({count})"
- End Trip: "End Trip"
- Share Trip: "Share Trip"
- Add Message: "Add Message"

### Trip Creation
- Explicit: "Start Trip"
- Implicit: "Group this expense?"
- Input Label: "Trip Name"
- Placeholder: "e.g., Restaurant – Terra Kulture"
- Skip: "Skip"
- Create: "Create Trip" / "Start Trip"

### Trip Selection
- Title: "Select Trip / Outing"
- Current: "(Current)"
- None: "Don't link to a trip"
- Create New: "Create New Trip"

### Trip Closing
- Confirmation Title: "End Trip?"
- Confirmation Message: "End this trip? You can't add more expenses after closing."
- Confirm: "End Trip"
- Cancel: "Cancel"
- Success: "Trip closed successfully"

### Empty States
- No Trips: "No trips yet"
- No Trips Subtitle: "Start a trip to group expenses"
- No Expenses in Trip: "No expenses yet"
- No Expenses Subtitle: "Add expenses to this trip"

---

## Edge Case Handling

### 1. Multiple Active Trips

**UX Solution**:
- Home banner shows most recent Trip
- Banner includes indicator: "1 of 3 active"
- "View Trip" opens Trips List (shows all active)
- Expense entry shows all active Trips in selection

**Microcopy**: "1 of 3 active" (small text in banner)

---

### 2. User Forgets to Close Trip

**UX Solution**:
- Trip remains active indefinitely
- Banner stays visible (reminder)
- No automatic closure
- User can close anytime

**Rationale**: User control, no forced actions

---

### 3. Expense Added to Wrong Trip

**UX Solution**:
- Allow reassignment in Expense Details Screen
- Show "Trip" field (editable)
- Can change Trip or remove Trip link
- Only for ACTIVE trips

**Microcopy**: "Trip: {Trip Name} [Change]"

---

### 4. Voice Input with Active Trip

**UX Solution**:
- Show context indicator before voice input
- Auto-attach to active Trip
- Allow change in review step
- Voice confirmation: "Adding to {Trip Name}"

**Microcopy**: "Adding to: {Trip Name}" (spoken + displayed)

---

## Design Rationale

### Why Banner on Home Screen?
- **Always visible** when active (principle #4)
- **Non-intrusive** (doesn't block content)
- **Quick actions** (view/end without navigation)

### Why Context Indicator?
- **Subtle reminder** without being pushy
- **Confirms behavior** (auto-attachment)
- **Non-blocking** (doesn't require action)

### Why Optional Trip Field?
- **Flexibility** (can remove if needed)
- **Override capability** (switch trips)
- **Non-mandatory** (principle #1)

### Why Implicit Creation?
- **Discoverability** (shows after first expense)
- **Non-intrusive** (can be skipped)
- **Helpful suggestion** (groups related expenses)

### Why Separate Trips List?
- **Secondary feature** (not primary navigation)
- **Full management** (view all, create new)
- **Historical access** (closed trips)

### Why No Trip UI When Inactive?
- **Principle #5**: Silent when inactive
- **Reduces clutter** (only show when relevant)
- **Focuses on core** (expense tracking)

---

## Implementation Priority

### Phase 1: Core Experience
1. Active Trip Banner (Home Screen)
2. Trip selection in Add Expense Screen
3. Trip auto-attachment
4. Basic Trip Details Screen

### Phase 2: Management
5. Trips List Screen
6. Trip creation (explicit + implicit)
7. Trip closing flow

### Phase 3: Advanced
8. Shared Trips (participants, messages)
9. Expense splitting UI
10. Trip summaries

---

## Accessibility Considerations

- **Screen readers**: Announce "Active Trip: {Trip Name}"
- **Color contrast**: Banner meets WCAG AA standards
- **Touch targets**: All buttons minimum 44x44px
- **Keyboard navigation**: Full support for all actions
- **Focus management**: Clear focus indicators

---

## Success Metrics

- **Adoption**: % of users who create at least one Trip
- **Engagement**: Average expenses per Trip
- **Retention**: % of users who create multiple Trips
- **Friction**: Time to create Trip (target: < 10 seconds)
- **Clarity**: % of users who understand Trip concept (survey)

---

This design ensures Trips feel **optional, lightweight, and contextual** while providing powerful grouping capabilities when needed.
