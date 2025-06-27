import 'package:flutter/material.dart';

import 'middleware/front_end.dart';
import 'upper/animal_chess_local/chess_page.dart';
import 'upper/chat_room/chat_page.dart';
import 'upper/elemental_battle/upper/combat_page.dart';
import 'upper/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Treasure',
      theme: globalTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),

        '/animal_chess': (context) {
          return ChessPage();
        },

        '/chat_room': (context) {
          // 从路由参数中获取数据
          final args = ModalRoute.of(context)?.settings.arguments as Map;
          return ChatPage(
            roomInfo: args['roomInfo'],
            userName: args['userName'],
          );
        },

        '/elemental_battle': (context) {
          // 从路由参数中获取数据
          final args = ModalRoute.of(context)?.settings.arguments as Map;
          return CombatPage(
            roomInfo: args['roomInfo'],
            userName: args['userName'],
          );
        },

        // '/status': (context) {
        //   // 从路由参数中获取数据
        //   final args = ModalRoute.of(context)?.settings.arguments as Map;
        //   return StatusPage(elemental: args['elemental']);
        // },
        // '/cast': (context) {
        //   // 从路由参数中获取数据
        //   final args = ModalRoute.of(context)?.settings.arguments as Map;
        //   return CastPage(totalPoints: args['totalPoints']);
        // },
        // '/combat': (context) {
        //   // 从路由参数中获取数据
        //   final args = ModalRoute.of(context)?.settings.arguments as Map;
        //   return CombatPage(_combatManager: args['_combatManager']);
        // },
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
