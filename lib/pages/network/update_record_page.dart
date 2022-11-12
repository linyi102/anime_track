import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/models/vo/update_record_vo.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/time_show_util.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../utils/theme_util.dart';

class UpdateRecordPage extends StatelessWidget {
  UpdateRecordPage({Key? key}) : super(key: key);
  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final UpdateRecordController updateRecordController = Get.find();

    return Obx(
      () => RefreshIndicator(
        onRefresh: () async {
          // 如果返回false，则不会弹出更新进度消息
          ClimbAnimeUtil.updateAllAnimesInfo().then((value) {
            if (value) {
              dialogUpdateAllAnimeProgress(context);
            }
          });
        },
        child: updateRecordController.updateRecordVos.isEmpty
            ? _buildEmptyDataPage(context)
            : Column(
                children: [
                  // _buildUpdateProgress(),
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: _buildUpdateRecordList(updateRecordController),
                  )),
                ],
              ),
      ),
    );
  }

  _buildUpdateRecordList(UpdateRecordController updateRecordController) {
    List<String> dateList = [];
    Map<String, List<UpdateRecordVo>> map = {};
    for (var updateRecordVo in updateRecordController.updateRecordVos) {
      String key = updateRecordVo.manualUpdateDate();
      if (!map.containsKey(key)) {
        map[key] = [];
        dateList.add(key);
      }
      map[key]!.add(updateRecordVo);
    }

    return Scrollbar(
      controller: scrollController,
      child: ListView.builder(
          controller: scrollController,
          // 解决item太小无法下拉
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: dateList.length,
          itemBuilder: (context, index) {
            // debugPrint("$index");
            String date = dateList[index];
            PageParams pageParams = updateRecordController.pageParams;
            if (index + 2 == (pageParams.pageIndex + 1) * pageParams.pageSize) {
              updateRecordController.loadMore();
            }

            return Card(
              elevation: 0,
              child: Column(
                children: [
                  ListTile(
                      title: Text(
                          TimeShowUtil.getHumanReadableDateTimeStr(date,
                              showTime: false),
                          textScaleFactor: ThemeUtil.smallScaleFactor)),
                  Column(children: _buildRecords(context, map[date]!)),
                  // 避免最后一项太靠近卡片底部，因为标题没有紧靠顶部，所以会导致不美观
                  const SizedBox(height: 5)
                ],
              ),
            );
          }),
    );
  }

  _buildRecords(context, List<UpdateRecordVo> records) {
    List<Widget> recordsWidget = [];
    for (var record in records) {
      recordsWidget.add(ListTile(
        leading: AnimeListCover(record.anime),
        subtitle: Text("更新至${record.newEpisodeCnt}集",
            textScaleFactor: ThemeUtil.tinyScaleFactor),
        title: Text(
          record.anime.animeName,
          // textScaleFactor: ThemeUtil.smallScaleFactor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // subtitle: Text(updateRecordVo.anime.getAnimeSource()),
        onTap: () {
          Navigator.of(context).push(FadeRoute(
            builder: (context) {
              return AnimeDetailPlus(record.anime);
            },
          ));
        },
      ));
    }
    return recordsWidget;
  }

  _buildEmptyDataPage(BuildContext context) {
    return ListView(
      // 解决无法下拉刷新
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          // 不能用无限高度(因为是ListView可以滚动)，只能通过下面方式获取高度
          height: MediaQuery.of(context).size.height -
              MediaQueryData.fromWindow(window).padding.top -
              kToolbarHeight -
              kBottomNavigationBarHeight -
              kMinInteractiveDimension,
          // color: Colors.red,
          child: emptyDataHint("尝试下拉更新动漫"),
        )
      ],
      key: UniqueKey(),
    );
  }

  // _buildUpdateProgress() {
  //   final UpdateRecordController updateRecordController = Get.find();
  //   int updateOkCnt = updateRecordController.updateOkCnt.value;
  //   int needUpdateCnt = updateRecordController.needUpdateCnt.value;
  //   bool updateOk = updateRecordController.updateOk;

  //   return Obx(() => ListTile(
  //         title: Text("待更新的动漫数量：$needUpdateCnt"),
  //       ));
  // }

  /// 全局更新动漫
  dialogUpdateAllAnimeProgress(parentContext) {
    final UpdateRecordController updateRecordController = Get.find();

    showDialog(
        context: parentContext,
        builder: (context) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Column(
                children: [
                  Obx(
                    () {
                      int updateOkCnt =
                          updateRecordController.updateOkCnt.value;
                      int needUpdateCnt =
                          updateRecordController.needUpdateCnt.value;
                      // if (needUpdateCnt > 0 && updateOkCnt == needUpdateCnt) {
                      //   showToast("动漫更新完毕！");
                      // }

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                        child: Column(
                          children: [
                            Center(
                                child: Text(
                                    updateOkCnt < needUpdateCnt
                                        ? "更新动漫中..."
                                        : "更新完毕！",
                                    textScaleFactor:
                                        ThemeUtil.smallScaleFactor)),
                            const SizedBox(height: 15),
                            LinearPercentIndicator(
                              barRadius: const Radius.circular(15),
                              animation: false,
                              lineHeight: 20.0,
                              animationDuration: 1000,
                              percent:
                                  _getUpdatePercent(updateOkCnt, needUpdateCnt),
                              center: Text("$updateOkCnt / $needUpdateCnt",
                                  style:
                                      const TextStyle(color: Colors.black54)),
                              progressColor: Colors.greenAccent,
                              // linearGradient: const LinearGradient(colors: [Colors.greenAccent, Colors.green]),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                    child: const Text(
                      "提示：\n更新时会跳过已完结动漫\n关闭该对话框不影响更新",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                      textScaleFactor: 0.8,
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  double _getUpdatePercent(int updateOkCnt, int needUpdateCnt) {
    if (needUpdateCnt == 0) {
      return 0;
    } else if (updateOkCnt > needUpdateCnt) {
      debugPrint(
          "error: updateOkCnt=$updateOkCnt, needUpdateCnt=$needUpdateCnt");
      return 1;
    } else {
      return updateOkCnt / needUpdateCnt;
    }
  }
}
