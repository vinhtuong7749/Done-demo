# Markdown Chat Rendering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render markdown formatting in bot messages của `ChatMessageWidget` thay vì hiển thị raw markdown text.

**Architecture:** Thêm `flutter_markdown` package, thay `Text()` bằng `MarkdownBody` chỉ cho bot messages (`isBot == true`), style qua `MarkdownStyleSheet` để match thiết kế hiện tại.

**Tech Stack:** Flutter, `flutter_markdown ^0.7.4`, `flutter_test` (widget tests)

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `pubspec.yaml` | Modify | Thêm `flutter_markdown` dependency |
| `lib/core/widgets/home/chat_message_widget.dart` | Modify | Thay `Text()` → `MarkdownBody` cho bot messages |
| `test/core/widgets/home/chat_message_widget_test.dart` | Create | Widget tests cho markdown rendering |

---

### Task 1: Thêm dependency `flutter_markdown`

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Thêm `flutter_markdown` vào pubspec.yaml**

Mở `pubspec.yaml`, tìm dòng:
```yaml
  intl: ^0.19.0
```
Thêm sau dòng đó:
```yaml
  flutter_markdown: ^0.7.4
```

- [ ] **Step 2: Chạy pub get**

```bash
cd d:/PjDai/ThuSrc/Done-demo
flutter pub get
```
Expected output: `Resolving dependencies...` rồi `Got dependencies!`

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add flutter_markdown dependency"
```

---

### Task 2: Viết widget test trước khi sửa code (TDD)

**Files:**
- Create: `test/core/widgets/home/chat_message_widget_test.dart`

- [ ] **Step 1: Tạo thư mục test nếu chưa có**

```bash
mkdir -p d:/PjDai/ThuSrc/Done-demo/test/core/widgets/home
```

- [ ] **Step 2: Viết failing tests**

Tạo file `test/core/widgets/home/chat_message_widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dngo/core/widgets/home/chat_message_widget.dart';
import 'package:dngo/feature/buyer/home/presentation/cubit/home_state.dart';

ChatMessage _botMessage(String text) => ChatMessage(
      message: text,
      isBot: true,
      timestamp: DateTime(2024),
    );

ChatMessage _userMessage(String text) => ChatMessage(
      message: text,
      isBot: false,
      timestamp: DateTime(2024),
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ChatMessageWidget - markdown rendering', () {
    testWidgets('bot message dùng MarkdownBody', (tester) async {
      await tester.pumpWidget(_wrap(ChatMessageWidget(
        message: _botMessage('**bold** text'),
        onOptionTap: (_) {},
      )));
      expect(find.byType(MarkdownBody), findsOneWidget);
    });

    testWidgets('user message dùng Text, không dùng MarkdownBody', (tester) async {
      await tester.pumpWidget(_wrap(ChatMessageWidget(
        message: _userMessage('hello'),
        onOptionTap: (_) {},
      )));
      expect(find.byType(MarkdownBody), findsNothing);
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('bot message render bold đúng', (tester) async {
      await tester.pumpWidget(_wrap(ChatMessageWidget(
        message: _botMessage('**bold**'),
        onOptionTap: (_) {},
      )));
      // MarkdownBody render bold thành RichText với FontWeight.bold
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasBold = richTexts.any((rt) {
        bool found = false;
        rt.text.visitChildren((span) {
          if (span is TextSpan && span.style?.fontWeight == FontWeight.bold) {
            found = true;
          }
          return true;
        });
        return found;
      });
      expect(hasBold, isTrue);
    });

    testWidgets('bot message render bullet list đúng', (tester) async {
      await tester.pumpWidget(_wrap(ChatMessageWidget(
        message: _botMessage('- item1\n- item2'),
        onOptionTap: (_) {},
      )));
      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.text('item1'), findsOneWidget);
      expect(find.text('item2'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 3: Chạy test để xác nhận FAIL**

```bash
cd d:/PjDai/ThuSrc/Done-demo
flutter test test/core/widgets/home/chat_message_widget_test.dart
```
Expected: FAIL với lỗi `MarkdownBody` not found (vì chưa sửa widget).

---

### Task 3: Sửa `ChatMessageWidget` để dùng `MarkdownBody`

**Files:**
- Modify: `lib/core/widgets/home/chat_message_widget.dart:1` (thêm import)
- Modify: `lib/core/widgets/home/chat_message_widget.dart:65-68` (thay Text bằng MarkdownBody)

- [ ] **Step 1: Thêm import `flutter_markdown`**

Tìm dòng đầu file `lib/core/widgets/home/chat_message_widget.dart`:
```dart
import 'package:flutter/material.dart';
```
Thêm sau đó:
```dart
import 'package:flutter_markdown/flutter_markdown.dart';
```

- [ ] **Step 2: Thay `Text()` bằng `MarkdownBody` cho bot messages**

Tìm đoạn code hiện tại (dòng 65-68):
```dart
                  child: Text(
                    message.message,
                    style: const TextStyle(fontFamily: 'Roboto', fontSize: 17, fontWeight: FontWeight.w300, height: 1.33, color: Colors.black),
                  ),
```

Thay bằng:
```dart
                  child: message.isBot
                      ? MarkdownBody(
                          data: message.message,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 17,
                              fontWeight: FontWeight.w300,
                              height: 1.33,
                              color: Colors.black,
                            ),
                            listBullet: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 17,
                              fontWeight: FontWeight.w300,
                              height: 1.33,
                              color: Colors.black,
                            ),
                          ),
                        )
                      : Text(
                          message.message,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 17,
                            fontWeight: FontWeight.w300,
                            height: 1.33,
                            color: Colors.black,
                          ),
                        ),
```

- [ ] **Step 3: Chạy tests để xác nhận PASS**

```bash
cd d:/PjDai/ThuSrc/Done-demo
flutter test test/core/widgets/home/chat_message_widget_test.dart
```
Expected: All tests PASS.

- [ ] **Step 4: Chạy toàn bộ test suite**

```bash
flutter test
```
Expected: Không có test nào bị broken mới.

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/home/chat_message_widget.dart \
        test/core/widgets/home/chat_message_widget_test.dart
git commit -m "feat: render markdown in bot chat messages"
```

---

## Self-Review Notes

- **Spec coverage**: 
  - ✅ `**bold**` → bold via MarkdownBody
  - ✅ `*italic*` → italic via MarkdownBody (handled by flutter_markdown natively)
  - ✅ `- item` → bullet list via MarkdownBody
  - ✅ `1. item` → numbered list via MarkdownBody (handled natively)
  - ✅ Font/màu/size không đổi → đặt trong `MarkdownStyleSheet`
  - ✅ User messages không bị ảnh hưởng → conditional `message.isBot`
- **No placeholders**: tất cả code đều hoàn chỉnh
- **Type consistency**: `MarkdownBody`, `MarkdownStyleSheet` dùng nhất quán trong cả plan và test
