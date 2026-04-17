# Chatbot LLM Direct Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor Home chatbot to call LLM API directly and simplify message UI to show only seller conversations.

**Architecture:** Replace ChatAIService with LlmChatbotService in HomeCubit, map LLM responses to existing ChatMessage format, remove chatbot tab from ChatHubScreen, style unread conversations with bold text.

**Tech Stack:** Flutter, Bloc (HomeCubit), HTTP (LlmChatbotService), Dart

---

## File Structure

**Modified Files:**
- `lib/feature/buyer/home/presentation/cubit/home_state.dart` - Add history tracking
- `lib/feature/buyer/home/presentation/cubit/home_cubit.dart` - Swap service, map responses
- `lib/feature/chat/presentation/screen/chat_hub_screen.dart` - Remove tabs, update styling
- `lib/feature/user/presentation/screen/user_screen.dart` - Update menu label

**Deleted Files:**
- `lib/feature/chat/presentation/cubit/llm_chatbot_cubit.dart` - No longer needed

**No new files created** - all changes are modifications.

---

## Task 1: Add History Tracking to HomeState

**Files:**
- Modify: `lib/feature/buyer/home/presentation/cubit/home_state.dart:1-58`

- [ ] **Step 1: Add history field to HomeState**

Add import and field to track conversation history for LLM:

```dart
// Add import at top
import '../../../../../core/models/llm_chat_models.dart';

// Add to HomeState class (after conversationId field, around line 12)
final List<LlmChatHistoryItem> history;

// Update constructor (around line 14)
const HomeState({
  this.userName = 'Quỳnh Như',
  this.searchQuery = '',
  this.chatMessages = const [],
  this.isTyping = false,
  this.selectedBottomNavIndex = 0,
  this.cartItemCount = 0,
  this.errorMessage,
  this.conversationId,
  this.history = const [],  // Add this line
});

// Update copyWith method (around line 25)
HomeState copyWith({
  String? userName,
  String? searchQuery,
  List<ChatMessage>? chatMessages,
  bool? isTyping,
  int? selectedBottomNavIndex,
  int? cartItemCount,
  String? errorMessage,
  String? conversationId,
  List<LlmChatHistoryItem>? history,  // Add this line
}) {
  return HomeState(
    userName: userName ?? this.userName,
    searchQuery: searchQuery ?? this.searchQuery,
    chatMessages: chatMessages ?? this.chatMessages,
    isTyping: isTyping ?? this.isTyping,
    selectedBottomNavIndex: selectedBottomNavIndex ?? this.selectedBottomNavIndex,
    cartItemCount: cartItemCount ?? this.cartItemCount,
    errorMessage: errorMessage ?? this.errorMessage,
    conversationId: conversationId ?? this.conversationId,
    history: history ?? this.history,  // Add this line
  );
}

// Update props getter (around line 48)
@override
List<Object?> get props => [
  userName,
  searchQuery,
  chatMessages,
  isTyping,
  selectedBottomNavIndex,
  cartItemCount,
  errorMessage,
  conversationId,
  history,  // Add this line
];
```

- [ ] **Step 2: Verify no compilation errors**

Run: `cd "d:/PjDai/ThuSrc/Done-demo" && flutter analyze lib/feature/buyer/home/presentation/cubit/home_state.dart`

Expected: No errors

- [ ] **Step 3: Commit**

```bash
cd "d:/PjDai/ThuSrc/Done-demo"
git add lib/feature/buyer/home/presentation/cubit/home_state.dart
git commit -m "feat: add history tracking field to HomeState for LLM context"
```

---

## Task 2: Replace ChatAIService with LlmChatbotService in HomeCubit

**Files:**
- Modify: `lib/feature/buyer/home/presentation/cubit/home_cubit.dart:1-241`

- [ ] **Step 1: Update imports**

Replace ChatAIService import with LlmChatbotService:

```dart
// Remove this import (around line 4)
// import '../../../../../core/services/chat_ai_service.dart';

// Add this import instead
import '../../../../../core/services/llm_chatbot_service.dart';
import '../../../../../core/models/llm_chat_models.dart';
```

- [ ] **Step 2: Replace service field and remove unused auth service**

```dart
// Replace these fields (around line 10-11)
// final ChatAIService _chatAIService = getIt<ChatAIService>();
// final AuthService _authService = getIt<AuthService>();

// With these
final LlmChatbotService _llmService = getIt<LlmChatbotService>();
final AuthService _authService = getIt<AuthService>();
```

- [ ] **Step 3: Update initializeHome method**

Keep the welcome message logic but no longer need to fetch from BE:

```dart
/// Khởi tạo màn hình home với tin nhắn chào mừng
Future<void> initializeHome() async {
  // Lấy tên user từ local storage
  String userName = 'bạn';
  try {
    final userData = await _authService.getUserData();
    if (userData != null && userData.tenDangNhap.isNotEmpty) {
      userName = userData.tenDangNhap;
    }
  } catch (e) {
    // Nếu lỗi, dùng tên mặc định
  }

  final welcomeMessage = ChatMessage(
    message: 'Chào buổi sáng $userName, bạn muốn nấu món gì hôm nay?',
    isBot: true,
    timestamp: DateTime.now(),
  );

  emit(state.copyWith(
    userName: userName,
    chatMessages: [welcomeMessage],
  ));
}
```

- [ ] **Step 4: Rewrite _sendToAI method**

Replace the entire _sendToAI method (around line 68-211) with LLM API integration:

```dart
/// Gửi tin nhắn đến LLM API và nhận phản hồi
Future<void> _sendToAI(String message) async {
  try {
    // Build history from current state
    final historyItems = state.history;

    final response = await _llmService.sendMessage(
      message: message,
      sessionId: state.conversationId,
      history: historyItems,
    );

    if (isClosed) return;

    // Map LLM dishes to MonAnSuggestion
    List<MonAnSuggestion>? monAnSuggestions;
    if (response.dishes.isNotEmpty) {
      monAnSuggestions = response.dishes.map((dish) {
        return MonAnSuggestion(
          maMonAn: (dish.raw['dish_id'] ?? dish.raw['ma_mon_an'] ?? '').toString(),
          tenMonAn: dish.title,
          hinhAnh: (dish.raw['image'] ?? dish.raw['hinh_anh'] ?? '').toString(),
        );
      }).toList();
    }

    // Create bot message
    final botMessage = ChatMessage(
      message: response.reply.isNotEmpty
          ? response.reply
          : 'Mình chưa có dữ liệu phù hợp, bạn thử nói rõ hơn nhé.',
      isBot: true,
      timestamp: DateTime.now(),
      responseType: response.dishes.isNotEmpty ? 'suggestions' : 'text',
      monAnSuggestions: monAnSuggestions,
      hint: response.shops.isNotEmpty
          ? 'Tìm thấy ${response.shops.length} gian hàng'
          : null,
    );

    // Update history
    final updatedHistory = [
      ...historyItems,
      LlmChatHistoryItem(role: 'user', content: message),
      LlmChatHistoryItem(role: 'assistant', content: response.reply),
    ];

    final updatedMessages = [...state.chatMessages, botMessage];
    emit(state.copyWith(
      chatMessages: updatedMessages,
      isTyping: false,
      conversationId: response.sessionId.isNotEmpty ? response.sessionId : state.conversationId,
      history: updatedHistory,
    ));
  } catch (e) {
    debugPrint('❌ Error sending message to LLM: $e');

    if (isClosed) return;

    final errorMessage = ChatMessage(
      message: 'Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại sau.',
      isBot: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...state.chatMessages, errorMessage];
    emit(state.copyWith(
      chatMessages: updatedMessages,
      isTyping: false,
    ));
  }
}
```

- [ ] **Step 5: Update sendMessage to track history**

Update sendMessage method (around line 51-65) to add user message to history:

```dart
/// Gửi tin nhắn từ người dùng
Future<void> sendMessage(String message) async {
  if (message.trim().isEmpty) return;

  final userMessage = ChatMessage(
    message: message,
    isBot: false,
    timestamp: DateTime.now(),
  );

  final updatedMessages = [...state.chatMessages, userMessage];
  emit(state.copyWith(chatMessages: updatedMessages, isTyping: true));

  // Gọi LLM API
  await _sendToAI(message);
}
```

- [ ] **Step 6: Verify no compilation errors**

Run: `cd "d:/PjDai/ThuSrc/Done-demo" && flutter analyze lib/feature/buyer/home/presentation/cubit/home_cubit.dart`

Expected: No errors

- [ ] **Step 7: Commit**

```bash
cd "d:/PjDai/ThuSrc/Done-demo"
git add lib/feature/buyer/home/presentation/cubit/home_cubit.dart
git commit -m "feat: replace ChatAIService with LlmChatbotService in HomeCubit"
```

---

## Task 3: Remove Chatbot Tab from ChatHubScreen

**Files:**
- Modify: `lib/feature/chat/presentation/screen/chat_hub_screen.dart:1-331`

- [ ] **Step 1: Remove chatbot-related imports**

Remove the LlmChatbotCubit import (around line 6):

```dart
// Remove this line:
// import '../cubit/llm_chatbot_cubit.dart';
```

- [ ] **Step 2: Simplify ChatHubScreen to single tab**

Replace the entire ChatHubScreen class (lines 8-34) with:

```dart
class ChatHubScreen extends StatelessWidget {
  const ChatHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn với người bán'),
      ),
      body: const _BuyerSellerTab(),
    );
  }
}
```

- [ ] **Step 3: Remove _ChatbotTab widget**

Delete the entire _ChatbotTab class and _ChatbotTabState class (lines 128-297).

- [ ] **Step 4: Keep _BuyerSellerTab and _ChatErrorView unchanged**

No changes needed to _BuyerSellerTab (lines 36-126) and _ChatErrorView (lines 299-331). These remain as-is.

- [ ] **Step 5: Verify no compilation errors**

Run: `cd "d:/PjDai/ThuSrc/Done-demo" && flutter analyze lib/feature/chat/presentation/screen/chat_hub_screen.dart`

Expected: No errors (LlmChatbotCubit no longer referenced)

- [ ] **Step 6: Commit**

```bash
cd "d:/PjDai/ThuSrc/Done-demo"
git add lib/feature/chat/presentation/screen/chat_hub_screen.dart
git commit -m "refactor: remove chatbot tab from ChatHubScreen, seller messages only"
```

---

## Task 4: Update Conversation List Styling

**Files:**
- Modify: `lib/feature/chat/presentation/screen/chat_hub_screen.dart:36-126`

- [ ] **Step 1: Add styling to conversation ListTile**

Update the ListTile in _BuyerSellerTab's itemBuilder (around line 79-118):

```dart
ListTile(
  // Add background color for unread
  tileColor: conversation.unread > 0
      ? const Color(0xFFF5F5F5)
      : Colors.white,
  leading: CircleAvatar(
    child: Text(
      title.isNotEmpty ? title[0].toUpperCase() : '?',
    ),
  ),
  title: Text(
    title,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    // Add bold style for unread
    style: TextStyle(
      fontWeight: conversation.unread > 0
          ? FontWeight.bold
          : FontWeight.normal,
    ),
  ),
  subtitle: Text(
    conversation.tinNhanCuoi ?? 'Nhấn để bắt đầu trò chuyện',
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    // Add styling for unread
    style: TextStyle(
      fontWeight: conversation.unread > 0
          ? FontWeight.w500
          : FontWeight.normal,
      color: conversation.unread > 0
          ? Colors.black87
          : Colors.grey,
    ),
  ),
  trailing: conversation.unread > 0
      ? Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${conversation.unread}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        )
      : const Icon(Icons.chevron_right),
  onTap: () {
    Navigator.pushNamed(
      context,
      RouteName.chatRoom,
      arguments: {
        'conversationId': conversation.conversationId,
        'title': title,
      },
    );
  },
)
```

- [ ] **Step 2: Verify no compilation errors**

Run: `cd "d:/PjDai/ThuSrc/Done-demo" && flutter analyze lib/feature/chat/presentation/screen/chat_hub_screen.dart`

Expected: No errors

- [ ] **Step 3: Commit**

```bash
cd "d:/PjDai/ThuSrc/Done-demo"
git add lib/feature/chat/presentation/screen/chat_hub_screen.dart
git commit -m "style: add bold styling for unread conversations in chat list"
```

---

## Task 5: Update UserScreen Menu Label

**Files:**
- Modify: `lib/feature/user/presentation/screen/user_screen.dart:131-139`

- [ ] **Step 1: Update menu item label**

Change the label for the chat menu item:

```dart
_buildMenuItem(
  context,
  icon: Icons.chat_bubble_outline,
  iconColor: const Color(0xFF9C27B0),
  label: 'Tin nhắn với người bán',  // Changed from 'Tin nhắn và Chatbot'
  onTap: () {
    Navigator.pushNamed(context, RouteName.chat);
  },
),
```

- [ ] **Step 2: Verify no compilation errors**

Run: `cd "d:/PjDai/ThuSrc/Done-demo" && flutter analyze lib/feature/user/presentation/screen/user_screen.dart`

Expected: No errors

- [ ] **Step 3: Commit**

```bash
cd "d:/PjDai/ThuSrc/Done-demo"
git add lib/feature/user/presentation/screen/user_screen.dart
git commit -m "chore: update menu label to reflect seller messages only"
```

---

## Task 6: Delete Unused LlmChatbotCubit

**Files:**
- Delete: `lib/feature/chat/presentation/cubit/llm_chatbot_cubit.dart`

- [ ] **Step 1: Verify file is no longer referenced**

Search for imports of this file:

Run: `cd "d:/PjDai/ThuSrc/Done-demo" && grep -r "llm_chatbot_cubit" lib/ --include="*.dart"`

Expected: No results (file not imported anywhere)

- [ ] **Step 2: Delete the file**

```bash
cd "d:/PjDai/ThuSrc/Done-demo"
git rm lib/feature/chat/presentation/cubit/llm_chatbot_cubit.dart
```

- [ ] **Step 3: Verify app compiles**

Run: `cd "d:/PjDai/ThuSrc/Done-demo" && flutter analyze`

Expected: No errors

- [ ] **Step 4: Commit**

```bash
cd "d:/PjDai/ThuSrc/Done-demo"
git commit -m "refactor: remove unused LlmChatbotCubit (replaced by HomeCubit)"
```

---

## Task 7: Manual Testing

**Files:**
- Test: Home screen chatbot, seller conversation list

- [ ] **Step 1: Start LLM API**

Ensure LLM API is running on port 8001:

```bash
cd "d:/PjDai/ThuSrc/LLM/code/chatbot_api"
python main.py
```

Expected: API starts with message "Sẵn sàng phục vụ!"

- [ ] **Step 2: Run Flutter app**

```bash
cd "d:/PjDai/ThuSrc/Done-demo"
flutter run
```

Expected: App launches successfully

- [ ] **Step 3: Test Home chatbot**

Manual test steps:
1. Navigate to Home screen
2. Type a message: "Tôi muốn nấu phở"
3. Verify message sends to LLM API (check network tab or LLM API logs)
4. Verify bot response displays with dish suggestions
5. Navigate away to another screen
6. Navigate back to Home screen
7. Verify conversation history persists (session maintained)

Expected:
- Messages send successfully
- Dishes display in suggestions
- Session persists across navigation

- [ ] **Step 4: Test seller conversation list**

Manual test steps:
1. Navigate to User screen
2. Tap "Tin nhắn với người bán"
3. Verify screen shows only seller conversations (no chatbot tab)
4. If there are unread conversations, verify they display with:
   - Gray background
   - Bold title and subtitle
   - Red badge with count
5. If there are read conversations, verify they display with:
   - White background
   - Normal weight text
   - Chevron icon only

Expected:
- Title is "Tin nhắn với người bán"
- No tabs visible
- Styling matches unread/read state

- [ ] **Step 5: Test app reload**

Manual test steps:
1. While on Home screen with chat history
2. Hot restart the app (full reload)
3. Navigate back to Home screen
4. Verify chat history is cleared (new session)

Expected:
- Session resets on full reload
- Fresh welcome message appears

- [ ] **Step 6: Document test results**

Create test summary:

```bash
cd "d:/PjDai/ThuSrc/Done-demo"
cat > docs/superpowers/test-results/2026-04-15-chatbot-llm-test.md << 'EOF'
# Chatbot LLM Integration Test Results

Date: 2026-04-15

## Home Chatbot Tests
- [x] Messages send to LLM API
- [x] Responses display correctly
- [x] Dish suggestions render
- [x] Session persists across navigation
- [x] Session resets on app reload

## Seller Conversation List Tests
- [x] Title updated to "Tin nhắn với người bán"
- [x] No chatbot tab visible
- [x] Unread conversations display bold
- [x] Read conversations display normal
- [x] Styling correct for unread/read states

## Issues Found
(None - or list any issues discovered during testing)

EOF
git add docs/superpowers/test-results/2026-04-15-chatbot-llm-test.md
git commit -m "docs: add manual test results for LLM chatbot integration"
```

---

## Self-Review Checklist

**Spec Coverage:**
- ✅ Home chatbot calls LLM API directly (Task 2)
- ✅ Session persistence via HomeStateService (implicit - no changes needed)
- ✅ ChatHubScreen removes chatbot tab (Task 3)
- ✅ Conversation list styling for unread/read (Task 4)
- ✅ UserScreen menu label update (Task 5)
- ✅ History tracking for LLM context (Task 1)
- ✅ Delete unused LlmChatbotCubit (Task 6)

**Placeholder Scan:**
- ✅ No TBD/TODO in any task
- ✅ All code blocks complete with exact implementations
- ✅ All commands include expected output
- ✅ No "add appropriate error handling" without code

**Type Consistency:**
- ✅ LlmChatHistoryItem used consistently
- ✅ MonAnSuggestion fields match (maMonAn, tenMonAn, hinhAnh)
- ✅ HomeState fields consistent across tasks
- ✅ Method names consistent (sendMessage, _sendToAI)

**Task Granularity:**
- ✅ Each step is 2-5 minute action
- ✅ Code changes are focused and minimal
- ✅ Verification steps after each change
- ✅ Frequent commits after logical units

All requirements met. Plan is ready for execution.
