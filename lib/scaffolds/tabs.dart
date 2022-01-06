import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/pages/anime_list_page.dart';
import 'package:flutter_test_future/pages/history_page.dart';
import 'package:flutter_test_future/pages/note_list_page.dart';
import 'package:flutter_test_future/pages/setting_page.dart';
import 'package:flutter_test_future/scaffolds/search.dart';
import 'package:flutter_test_future/utils/clime_cover_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:oktoast/oktoast.dart';

class Tabs extends StatefulWidget {
  const Tabs({Key? key}) : super(key: key);

  @override
  _TabsState createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  final List<Widget> _list = [
    const AnimeListPage(),
    const HistoryPage(),
    const NoteListPage(),
    const SettingPage(),
  ];
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _list[_currentIndex],
      // body: IndexedStack(
      //   // 新方法，可以保持页面状态。注：从详细中改变标签返回无法实时更新
      //   index: _currentIndex,
      //   children: _list,
      // ),

      // bottomNavigationBar: SalomonBottomBar(
      //   currentIndex: _currentIndex,
      //   onTap: (int index) {
      //     setState(() => _currentIndex = index);
      //   },
      //   items: [
      //     // SalomonBottomBarItem(
      //     //     icon: const SizedBox(
      //     //       width: 50,
      //     //       child: Icon(Icons.book),
      //     //     ),
      //     //     title: const Text("动漫")),
      //     // SalomonBottomBarItem(
      //     //     icon: const SizedBox(
      //     //       width: 50,
      //     //       child: Icon(Icons.history_rounded),
      //     //     ),
      //     //     title: const Text("历史")),
      //     // SalomonBottomBarItem(
      //     //   icon: const SizedBox(width: 50, child: Icon(Icons.more_horiz)),
      //     //   title: const Text("更多"),
      //     // ),
      //     SalomonBottomBarItem(
      //         icon: const Icon(Icons.book), title: const Text("动漫")),
      //     SalomonBottomBarItem(
      //         icon: const Icon(Icons.history_rounded), title: const Text("历史")),
      //     SalomonBottomBarItem(
      //         icon: const Icon(Icons.note_alt_outlined),
      //         title: const Text("笔记")),
      //     SalomonBottomBarItem(
      //         icon: const Icon(Icons.more_horiz), title: const Text("更多")),
      //   ],
      // ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 当item数量超过3个，则会显示空白，此时需要设置该属性
        currentIndex: _currentIndex,
        // elevation: 0,
        backgroundColor: const Color.fromRGBO(254, 254, 254, 1),
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "动漫",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: "历史",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_alt_outlined),
            label: "笔记",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: "更多",
          ),
        ],
      ),
    );
  }
}
