import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 用来控制开关的状态变量
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    // 获取当前主题的颜色和字体样式
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium;
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600);
    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
       backgroundColor: const Color(0xFFE1F5FE), 
      body: ListView(
        children: [
          // --- 通用设置分组 ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
            child: Text('General', style: headerStyle),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text('Notification', style: titleStyle),
            subtitle: Text('Enable push notifications', style: subtitleStyle),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
              // 这里可以添加开启/关闭通知的逻辑
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: Text('Dark Mode', style: titleStyle),
            subtitle: Text('Swith to dark mode', style: subtitleStyle),
            value: _darkModeEnabled,
            onChanged: (bool value) {
              setState(() {
                _darkModeEnabled = value;
              });
              // 这里可以添加切换主题的逻辑
            },
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text('Language', style: titleStyle),
            subtitle: Text('English', style: subtitleStyle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // 导航到语言选择页面
            },
          ),

          const Divider(indent: 16, endIndent: 16, height: 32),

          // --- 账户设置分组 ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: Text('Account', style: headerStyle),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text('Edit Profile', style: titleStyle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // 导航到个人资料编辑页面
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text('Update Password', style: titleStyle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // 导航到修改密码页面
            },
          ),

          const Divider(indent: 16, endIndent: 16, height: 32),

          // --- 关于分组 ---
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('About Us', style: titleStyle),
            onTap: () {
              // 显示“关于我们”对话框或页面
            },
          ),
        ],
      ),
    );
  }
}