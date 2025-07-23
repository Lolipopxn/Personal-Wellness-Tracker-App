import 'package:flutter/material.dart';

import 'package:personal_wellness_tracker/app/auth_service.dart';
import 'package:personal_wellness_tracker/pages/app_loading_page.dart';
import 'package:personal_wellness_tracker/pages/profile_widget.dart';
import 'package:personal_wellness_tracker/pages/welcome_page.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, this.pageIfNotConnected});

  final Widget? pageIfNotConnected;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: authService,
      builder: (context, authService, child) {
        return StreamBuilder(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            Widget widget;
            if (snapshot.connectionState == ConnectionState.waiting) {
              widget = AppLoadingPage();
            } else if (snapshot.hasData) {
              widget = const ProfileWidget();
            } else {
              widget = pageIfNotConnected ?? const WelcomePage();
            }
            return widget;
          },
        );
      },
    );
  }
}
