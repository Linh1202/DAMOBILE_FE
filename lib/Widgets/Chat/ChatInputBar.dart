import 'package:flutter/material.dart';
import '../../Utils/Constants/AppColors.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttachment;
  final VoidCallback onEmoji;
  final VoidCallback onVoice;

  const ChatInputBar({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.onAttachment,
    required this.onEmoji,
    required this.onVoice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.emoji_emotions_outlined, color: AppColors.textSecondary),
              onPressed: onEmoji,
              padding: EdgeInsets.all(8),
              constraints: BoxConstraints(),
            ),
            IconButton(
              icon: Icon(Icons.attach_file, color: AppColors.textSecondary),
              onPressed: onAttachment,
              padding: EdgeInsets.all(8),
              constraints: BoxConstraints(),
            ),
            SizedBox(width: 4),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Nhập tin nhắn...",
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.mic_outlined, color: AppColors.textSecondary),
              onPressed: onVoice,
              padding: EdgeInsets.all(8),
              constraints: BoxConstraints(),
            ),
            Container(
              width: 40,
              height: 40,
              child: ElevatedButton(
                onPressed: onSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: CircleBorder(),
                  padding: EdgeInsets.zero,
                  elevation: 0,
                ),
                child: Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
