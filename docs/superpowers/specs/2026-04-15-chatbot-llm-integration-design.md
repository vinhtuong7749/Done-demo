# Chatbot LLM Direct Integration & Message UI Refactor

**Date:** 2026-04-15  
**Status:** Draft

## Overview

Refactor chatbot trên Home screen để gọi trực tiếp LLM API (port 8001) thay vì qua Backend, đồng thời tách giao diện tin nhắn để chỉ hiển thị tin nhắn với người bán.

## Goals

1. Home chatbot gọi trực tiếp LLM API không qua Backend
2. Màn hình tin nhắn chỉ hiển thị seller conversations (bỏ tab Chatbot)
3. Conversation list styling: bold cho unread, normal cho read
4. Session chatbot persist đến khi app reload hoàn toàn

## Non-Goals

- Không thêm field "Bạn:" prefix cho tin nhắn cuối (đã bỏ qua)
- Không thay đổi LLM API backend
- Không thay đổi seller chat logic (ChatService, ChatRoomCubit)

## Architecture

### Before

```
HomeScreen → HomeCubit → ChatAIService → Backend (/api/chat/chat)

ChatHubScreen → Tab "Người bán" → ChatInboxCubit
              → Tab "Chatbot" → LlmChatbotCubit → LLM API
```

### After

```
HomeScreen → HomeCubit → LlmChatbotService → LLM API (port 8001)

ChatHubScreen → Seller conversations only (no tabs)
```

## Detailed Changes

### 1. HomeCubit Modifications

**File:** `lib/feature/buyer/home/presentation/cubit/home_cubit.dart`

**Changes:**
- Replace `ChatAIService` with `LlmChatbotService`
- Add history tracking for conversation context
- Map `LlmChatResponse` to existing `ChatMessage` format

**Response Mapping:**

| LLM Response Field | ChatMessage Field |
|-------------------|-------------------|
| `reply` | `message` |
| `session_id` | `conversationId` |
| `dishes[]` | `monAnSuggestions` (requires format adaptation) |
| `shops[]` | Display in message text or new field |
| `intent` | Store for logging/debugging |

**LLM Response Dishes (via `LlmDishSuggestion`):**
```dart
LlmDishSuggestion(
  title: String,       // from ten_mon_an or dish_name
  description: String?, 
  raw: Map,           // contains dish_id, dish_name, cook_time, etc.
)
```

**Current ChatMessage MonAnSuggestion Format:**
```dart
MonAnSuggestion(
  maMonAn: String,    // required
  tenMonAn: String,   // required  
  hinhAnh: String,    // required (use empty string if not available)
)
```

**Mapping Implementation:**
```dart
final monAnSuggestions = response.dishes.map((dish) => MonAnSuggestion(
  maMonAn: (dish.raw['dish_id'] ?? '').toString(),
  tenMonAn: dish.title,
  hinhAnh: (dish.raw['image'] ?? dish.raw['hinh_anh'] ?? '').toString(),
)).toList();
```

### 2. HomeState Modifications

**File:** `lib/feature/buyer/home/presentation/cubit/home_state.dart`

**Changes:**
- Add `history` field to track conversation for LLM context (type: `List<LlmChatHistoryItem>`)

```dart
// Add to HomeState
final List<LlmChatHistoryItem> history;

// In HomeCubit, maintain history:
// After user sends: history.add(LlmChatHistoryItem(role: 'user', content: text))
// After bot replies: history.add(LlmChatHistoryItem(role: 'assistant', content: reply))
```

### 3. ChatHubScreen Modifications

**File:** `lib/feature/chat/presentation/screen/chat_hub_screen.dart`

**Changes:**
- Remove `DefaultTabController`, `TabBar`, `TabBarView`
- Use `_BuyerSellerTab` content directly as body
- Update AppBar title to "Tin nhắn với người bán"

**Before:**
```dart
DefaultTabController(
  length: 2,
  child: Scaffold(
    appBar: AppBar(
      title: Text('Tin nhắn'),
      bottom: TabBar(tabs: [...]),
    ),
    body: TabBarView(children: [_BuyerSellerTab(), _ChatbotTab()]),
  ),
)
```

**After:**
```dart
Scaffold(
  appBar: AppBar(title: Text('Tin nhắn với người bán')),
  body: _BuyerSellerTabContent(),
)
```

### 4. Conversation List Styling

**File:** `lib/feature/chat/presentation/screen/chat_hub_screen.dart`

**Changes to ListTile in `_BuyerSellerTab`:**

```dart
ListTile(
  tileColor: conversation.unread > 0 
      ? const Color(0xFFF5F5F5)  // Light gray background for unread
      : Colors.white,
  title: Text(
    title,
    style: TextStyle(
      fontWeight: conversation.unread > 0 
          ? FontWeight.bold 
          : FontWeight.normal,
    ),
  ),
  subtitle: Text(
    conversation.tinNhanCuoi ?? 'Nhấn để bắt đầu trò chuyện',
    style: TextStyle(
      fontWeight: conversation.unread > 0 
          ? FontWeight.w500 
          : FontWeight.normal,
      color: conversation.unread > 0 
          ? Colors.black87 
          : Colors.grey,
    ),
  ),
  // Keep existing trailing badge for unread count
)
```

### 5. Session Persistence

**No changes needed.** `HomeStateService` already implements singleton pattern:

```dart
class HomeStateService {
  static HomeCubit? _homeCubit;
  
  static HomeCubit getOrCreateHomeCubit() {
    _homeCubit ??= HomeCubit()..initializeHome();
    return _homeCubit!;
  }
  
  static void reset() {
    _homeCubit?.close();
    _homeCubit = null;
  }
}
```

Session persists until:
- App is fully reloaded (hot restart, app kill)
- User logs out (calls `HomeStateService.reset()`)

### 6. UserScreen Menu Update

**File:** `lib/feature/user/presentation/screen/user_screen.dart`

**Change menu label:**
```dart
// Before
label: 'Tin nhắn và Chatbot'

// After
label: 'Tin nhắn với người bán'
```

## Files to Modify

| File | Change Type |
|------|-------------|
| `lib/feature/buyer/home/presentation/cubit/home_cubit.dart` | Major - service replacement |
| `lib/feature/buyer/home/presentation/cubit/home_state.dart` | Minor - add history field |
| `lib/feature/chat/presentation/screen/chat_hub_screen.dart` | Major - remove tabs, update styling |
| `lib/feature/user/presentation/screen/user_screen.dart` | Minor - update label |

## Files to Delete

| File | Reason |
|------|--------|
| `lib/feature/chat/presentation/cubit/llm_chatbot_cubit.dart` | No longer needed (HomeCubit handles LLM) |

*Note: Keep `LlmChatbotService` and `llm_chat_models.dart` as they are reused by HomeCubit.*

## Testing Plan

1. **Home Chatbot:**
   - Verify messages sent to LLM API (check network tab)
   - Verify response displays correctly with dishes/shops
   - Verify session persists across navigation (go to other screens and back)
   - Verify session resets on app reload

2. **Seller Messages:**
   - Verify conversation list loads
   - Verify unread conversations display bold
   - Verify read conversations display normal
   - Verify tapping opens chat room

3. **Navigation:**
   - Verify "Tin nhắn với người bán" from UserScreen opens correct screen
   - Verify no chatbot tab exists

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| LLM API response format mismatch | Careful mapping with fallbacks |
| Session data loss on navigation | Already handled by HomeStateService singleton |
| Breaking existing seller chat | No changes to ChatService/ChatRoomCubit |

## Dependencies

- LLM API running on port 8001
- `LlmChatbotService` already registered in DI container
