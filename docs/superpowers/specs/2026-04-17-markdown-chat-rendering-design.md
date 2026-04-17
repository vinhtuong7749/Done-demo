# Design: Markdown Rendering cho Bot Messages trong Chat UI

**Date:** 2026-04-17  
**Status:** Approved

## Problem

Hiện tại `ChatMessageWidget` render tin nhắn bot (`isBot == true`) bằng `Text()` thuần (`chat_message_widget.dart:65-68`). AI response (`response.reply`) từ `LlmChatbotService` trả về text có thể chứa markdown formatting (`**bold**`, `*italic*`, `- list`, v.v.), khiến ký tự markdown hiển thị raw thay vì được format.

## Solution

Dùng package `flutter_markdown` (official Flutter team) để render bot messages dưới dạng markdown. User messages giữ nguyên `Text()` thuần.

## Approach

**Package:** `flutter_markdown: ^0.7.4`

Lý do chọn: official package của Flutter team, well-maintained, hỗ trợ đầy đủ CommonMark spec, có `MarkdownStyleSheet` để style match design hiện tại.

## Changes

### 1. `pubspec.yaml`
Thêm dependency:
```yaml
flutter_markdown: ^0.7.4
```

### 2. `lib/core/widgets/home/chat_message_widget.dart`
- Thay thế `Text(message.message, ...)` (dòng 65-68) bằng conditional:
  - Khi `message.isBot == true`: dùng `MarkdownBody` với `MarkdownStyleSheet` match style hiện tại
  - Khi `message.isBot == false`: giữ nguyên `Text()`
- `MarkdownStyleSheet` cần match: font Roboto, fontSize 17, fontWeight w300, height 1.33, color Colors.black

## Out of Scope

- Không thay đổi `HomeState`, `HomeCubit`, model, các card suggestion widget
- Không xử lý link tap (url_launcher đã có trong project nhưng không cần thiết cho phạm vi này trừ khi AI trả về URL)
- Không render markdown cho user messages

## Success Criteria

- Bot messages hiển thị `**text**` thành **text** (bold)
- Bot messages hiển thị `*text*` thành *text* (italic)  
- Bot messages hiển thị `- item` thành bullet list
- Bot messages hiển thị `1. item` thành numbered list
- Font, màu, kích thước chữ không thay đổi so với hiện tại
- User messages không bị ảnh hưởng
