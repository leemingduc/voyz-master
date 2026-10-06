# Design Spec: In-App Destination Sharing with Friends

**Date:** 2026-10-06  
**Branch:** `feature/share-destination-with-friends`  
**Status:** Approved by User  

---

## 1. Overview & Goals
Enable users to share any travel destination directly with their friends inside the Voyz app. When tapping the Share button on a destination detail or saved trip, a glassmorphic `ShareWithFriendsBottomSheet` opens, allowing the user to select one or more accepted friends, type an optional personal note, and send the destination directly to the friend's chat conversation. In addition, `FriendChatScreen` will detect shared destination messages and render interactive destination cards with a direct "View Destination" navigation button.

---

## 2. Component Architecture & Data Flow

### 2.1 Share Destination Model / Helper (`lib/widgets/shared/share_destination_dialog.dart`)
Create reusable widget `ShareDestinationBottomSheet` that:
- Loads accepted friendships from `FriendsService.instance.getFriendships()`.
- Allows selecting one or multiple friends.
- Includes a personal note text field (e.g., `"Let's visit this place together!"`).
- Formats message body as structured share message containing destination title, location, category/rating, image or link format (`📍 [Địa điểm] ...`).
- Offers a quick "Copy Link / External Share" button fallback.
- Sends message via `FriendsService.instance.sendMessage(friendshipId, formattedText)`.

### 2.2 Integration Sites
1. **Destination Detail Screen (`lib/screens/destination_detail_screen.dart`)**:
   - Update `_onShare` to trigger `ShareDestinationBottomSheet` with `DestinationDetail` context (title, image, rating, address).
2. **Saved Trips Screen (`lib/screens/saved_screen.dart`)**:
   - Update `Share with` action chip to open `ShareDestinationBottomSheet` to share saved trips directly to friends' chats.

### 2.3 Interactive Destination Cards in Friend Chat (`lib/screens/friends_screen.dart`)
- Update `_ChatBubble` in `FriendChatScreen` to detect messages starting with `📍 [Địa điểm]` or destination share format.
- Render a styled destination card with:
  - Location Icon & Title
  - Personal note from sender
  - **"Xem chi tiết địa điểm"** button that navigates directly to `DestinationDetailScreen`.

---

## 3. Verification Plan
1. Static code analysis: `flutter analyze` passes with zero errors.
2. Unit / Widget testing: Write test verifying share bottom sheet loading and interactive chat bubble parsing.

---
