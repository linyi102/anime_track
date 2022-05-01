import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/history_plus.dart';
import 'package:flutter_test_future/classes/record.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_uint.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/anime_detail.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:oktoast/oktoast.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  Map<int, List<HistoryPlus>> yearHistory = {};
  Map<int, bool> yearLoadOk = {};
  int curYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadData(curYear);
  }

  _loadData(int year) async {
    debugPrint("加载$year年数据中...");
    Future(() {
      return SqliteUtil.getAllHistoryByYear(year);
    }).then((value) {
      debugPrint("$year年数据加载完成");
      yearHistory[year] = value;
      yearLoadOk[year] = true;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "历史",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
          // 下拉刷新
          onRefresh: () async {
            _loadData(curYear);
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: !yearLoadOk.containsKey(curYear)
                ? Container(
                    key: UniqueKey(),
                    // color: Colors.white,
                  )
                : _showHistory(),
          )),
    );
  }

  Widget _showHistory() {
    // if (historyPlus.isEmpty) {
    //   return ListView(
    //     // 必须是ListView，不然向下滑不会有刷新
    //     children: const [],
    //   );
    // }
    return Stack(children: [
      Column(
        children: [
          _showOpYearButton(),
          yearHistory[curYear]!.isEmpty
              ? Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text("暂无相关记录"),
                  ),
                )
              : Expanded(
                  child: Scrollbar(
                      child: (ListView.separated(
                    itemCount: yearHistory[curYear]!.length,
                    itemBuilder: (BuildContext context, int index) {
                      // debugPrint("$index");
                      return ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                        title: ListTile(
                          title: Text(
                            yearHistory[curYear]![index].date,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        subtitle: Column(
                          children: _showRecord(index),
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return const Divider();
                    },
                  ))),
                ),
        ],
      ),
      // Container(
      //   alignment: Alignment.bottomCenter,
      //   child: Card(
      //     elevation: 0,
      //     shape: const RoundedRectangleBorder(
      //         borderRadius: BorderRadius.all(Radius.circular(15))), // 圆角
      //     clipBehavior: Clip.antiAlias, // 设置抗锯齿，实现圆角背景
      //     color: const Color.fromRGBO(0, 118, 243, 0.1),
      //     margin: const EdgeInsets.fromLTRB(50, 20, 50, 20),
      //     child: _showOpYearButton(),
      //   ),
      // ),
    ]);
  }

  List<Widget> _showRecord(int index) {
    List<Widget> listWidget = [];
    List<Record> records = yearHistory[curYear]![index].records;
    for (var record in records) {
      listWidget.add(
        ListTile(
          // visualDensity: const VisualDensity(vertical: -1),
          title: Text(
            record.anime.animeName,
            overflow: TextOverflow.ellipsis,
            textScaleFactor: 0.9,
          ),
          leading: AnimeListCover(record.anime,
              showReviewNumber: true, reviewNumber: record.reviewNumber),
          trailing: Text(
            record.startEpisodeNumber == record.endEpisodeNumber
                ? "${record.startEpisodeNumber}"
                : "${record.startEpisodeNumber}-${record.endEpisodeNumber}",
            textScaleFactor: 0.9,
          ),
          onTap: () {
            Navigator.of(context)
                .push(
              // MaterialPageRoute(
              //   builder: (context) => AnimeDetailPlus(record.anime.animeId),
              // ),
              FadeRoute(
                transitionDuration: const Duration(milliseconds: 0),
                builder: (context) {
                  return AnimeDetailPlus(record.anime.animeId);
                },
              ),
            )
                .then((value) {
              _loadData(curYear);
            });
          },
        ),
      );
    }
    return listWidget;
  }

  Widget _showOpYearButton() {
    return Row(
      children: [
        Expanded(
          child: IconButton(
              onPressed: () {
                curYear--;
                // 没有加载过，才去查询数据库
                if (!yearLoadOk.containsKey(curYear)) {
                  debugPrint("之前未查询过$curYear年，现查询");
                  _loadData(curYear);
                } else {
                  // 加载过，直接更新状态
                  debugPrint("查询过$curYear年，直接更新状态");
                  setState(() {});
                }
              },
              icon: const Icon(
                Icons.chevron_left_rounded,
                // size: 20,
                color: Colors.black,
              )),
        ),
        Expanded(
          child: TextButton(
              onPressed: () {
                // _dialogSelectYear();
                dialogSelectUint(context, "选择年份",
                        initialValue: curYear, maxValue: curYear + 2)
                    .then((value) {
                  if (value == null) {
                    debugPrint("未选择，直接返回");
                    return;
                  }
                  debugPrint("选择了$value");
                  curYear = value;
                  _loadData(curYear);
                });
              },
              child: Text(
                "$curYear",
                textScaleFactor: 1.2,
                style: const TextStyle(color: Colors.black),
              )),
        ),
        Expanded(
          child: IconButton(
              onPressed: () {
                if (curYear + 1 > DateTime.now().year + 2) {
                  showToast("前面的区域，以后再来探索吧！");
                  return;
                }
                curYear++;
                // 没有加载过，才去查询数据库
                if (!yearLoadOk.containsKey(curYear)) {
                  debugPrint("之前未查询过$curYear年，现查询");
                  _loadData(curYear);
                } else {
                  // 加载过，直接更新状态
                  debugPrint("查询过$curYear年，直接更新状态");
                  setState(() {});
                }
              },
              icon: const Icon(
                Icons.chevron_right_rounded,
                // size: 20,
                color: Colors.black,
              )),
        ),
      ],
    );
  }
}
