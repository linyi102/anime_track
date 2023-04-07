import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_animated_switcher.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/dao/update_record_dao.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/models/vo/update_record_vo.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/pages/network/update/need_update_anime_list.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:flutter_test_future/utils/time_util.dart';
import 'package:get/get.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:oktoast/oktoast.dart';

class UpdateRecordPage extends StatelessWidget {
  UpdateRecordPage({Key? key}) : super(key: key);
  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final UpdateRecordController updateRecordController = Get.find();

    return Obx(
      () => RefreshIndicator(
        onRefresh: () async {
          ClimbAnimeUtil.updateAllAnimesInfo();
        },
        // ListView嵌套ListView，那么内部LV会需要加上shrinkWrap: true，但这样会导致懒加载实现
        // 所以改用Column
        child: Column(
          children: [
            _buildUpdateProgress(context),
            Expanded(
                child: FadeAnimatedSwitcher(
                    loadOk: updateRecordController.loadOk.value,
                    destWidget: updateRecordController.updateRecordVos.isEmpty
                        ? _buildEmptyDataPage()
                        : _buildUpdateRecordList(updateRecordController))),
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
          itemCount: dateList.length,
          itemBuilder: (context, index) {
            String date = dateList[index];
            PageParams pageParams = updateRecordController.pageParams;
            Log.info("$index, ${pageParams.getQueriedSize()}");
            if (index + 2 == pageParams.getQueriedSize()) {
              updateRecordController.loadMore();
            }

            return Card(
              elevation: 0,
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      TimeUtil.getHumanReadableDateTimeStr(date,
                          showTime: false, showDayOfWeek: true
                          // chineseDelimiter: true,
                          ),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      "${map[date]!.length}个动漫",
                      textScaleFactor: 0.8,
                      style: TextStyle(color: ThemeUtil.getCommentColor()),
                    ),
                  ),
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
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) {
              return AnimeDetailPage(record.anime);
            },
          ));
        },
        onLongPress: () {
          // 提供删除操作
          _showDialogAboutRecordItem(context, record, records);
        },
      ));
    }
    return recordsWidget;
  }

  _showDialogAboutRecordItem(
      context, UpdateRecordVo record, List<UpdateRecordVo> records) async {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          children: [
            SimpleDialogOption(
              onPressed: () async {
                // 删除数据库数据
                bool deleteOk = await UpdateRecordDao.delete(record.id);
                if (deleteOk) {
                  // 删除内存数据
                  // records.remove(record); // 错误
                  UpdateRecordController.to.updateRecordVos
                      .remove(record); // 应删除控制器中的数据
                  // 关闭对话框
                  Navigator.pop(dialogContext);
                  // 提示
                  showToast("删除成功");
                } else {
                  showToast("删除失败");
                }
              },
              child: const Text("删除该更新记录"),
            )
          ],
        );
      },
    );
  }

  _buildEmptyDataPage() {
    return ListView(
      children: [emptyDataHint()],
    );
  }

  _buildUpdateProgress(context) {
    final UpdateRecordController updateRecordController = Get.find();
    int updateOkCnt = updateRecordController.updateOkCnt.value;
    int needUpdateCnt = updateRecordController.needUpdateCnt.value;

    return GestureDetector(
      onTap: () {
        Log.info("进入页面");
        Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          return const NeedUpdateAnimeList();
        }));
      },
      child: Card(
        child: Container(
          height: 60,
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: ThemeUtil.getCardColor()),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Container()),
                  Text(
                    "更新进度：$updateOkCnt/$needUpdateCnt",
                    textScaleFactor: ThemeUtil.smallScaleFactor,
                    // style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text("查看未完结动漫",
                      textScaleFactor: ThemeUtil.tinyScaleFactor,
                      style: TextStyle(color: ThemeUtil.getCommentColor())),
                  Expanded(child: Container()),
                ],
              ),
              TextButton(
                onPressed: () {
                  ClimbAnimeUtil.updateAllAnimesInfo();
                },
                style: ButtonStyle(
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)))),
                child: const Text(
                  "立即更新",
                  textScaleFactor: ThemeUtil.smallScaleFactor,
                  style: TextStyle(color: Colors.white),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  double _getUpdatePercent(int updateOkCnt, int needUpdateCnt) {
    if (needUpdateCnt == 0) {
      return 0;
    } else if (updateOkCnt > needUpdateCnt) {
      Log.info("error: updateOkCnt=$updateOkCnt, needUpdateCnt=$needUpdateCnt");
      return 1;
    } else {
      return updateOkCnt / needUpdateCnt;
    }
  }
}
