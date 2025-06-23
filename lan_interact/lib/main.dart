import 'package:flutter/material.dart';

import 'upper/cast_page.dart';
import 'upper/combat_page.dart';
import 'upper/home_page.dart';
import 'upper/prepare_page.dart';
import 'upper/status_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Navigation Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/prepare': (context) {
          // 从路由参数中获取数据
          final args = ModalRoute.of(context)?.settings.arguments as Map;
          return PreparePage(
            roomInfo: args['roomInfo'],
            userName: args['userName'],
          );
        },
        '/status': (context) {
          // 从路由参数中获取数据
          final args = ModalRoute.of(context)?.settings.arguments as Map;
          return StatusPage(elemental: args['elemental']);
        },
        '/cast': (context) {
          // 从路由参数中获取数据
          final args = ModalRoute.of(context)?.settings.arguments as Map;
          return CastPage(totalPoints: args['totalPoints']);
        },
        '/combat': (context) {
          // 从路由参数中获取数据
          final args = ModalRoute.of(context)?.settings.arguments as Map;
          return CombatPage(gameManager: args['gameManager']);
        },
        '/test': (context) => const TestPage(),
      },
    );
  }
}

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('TestPage')));
  }
}
