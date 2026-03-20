import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_constants.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';

class JoinGroupPage extends StatefulWidget {
  const JoinGroupPage({super.key});

  @override
  State<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入邀请码'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final auth = context.read<AuthService>();
    final success = await context.read<GroupService>().joinGroup(code, auth.user?.token);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加入成功'), behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加入失败，请检查邀请码是否正确'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('加入小组'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textMain,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '邀请码',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
            ),
            const SizedBox(height: 12),
            Container(
              alignment: Alignment.centerLeft, // 强制容器内容靠左
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: TextField(
                controller: _codeController,
                textAlign: TextAlign.start, // 显式设置文本靠左
                decoration: const InputDecoration(
                  hintText: '请输入 6 位小组邀请码',
                  hintStyle: TextStyle(color: AppColors.textLightGrey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), // 统一内边距
                ),
                autofocus: true,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '加入后您将可以实时查看小组成员共享的日程，并同步自己的日程。',
              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('立即加入', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
