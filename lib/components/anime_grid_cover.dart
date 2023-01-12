import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:get/get.dart';
import 'package:flutter_test_future/utils/log.dart';

import '../controllers/anime_display_controller.dart';
import 'common_image.dart';

// 网格状态下，用于显示一个完整的动漫封面
// 包括进度、第几次观看、名字
class AnimeGridCover extends StatelessWidget {
  final Anime _anime;
  final bool onlyShowCover; // 动漫详细页只显示封面
  final double coverWidth; // 传入固定宽度，用于水平列表
  final bool showProgress;
  final bool showReviewNumber;
  final bool isSelected;

  const AnimeGridCover(this._anime,
      {Key? key,
      this.onlyShowCover = false,
      this.showProgress = true,
      this.showReviewNumber = true,
      this.isSelected = false,
      this.coverWidth = 0})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AnimeDisplayController _animeDisplayController = Get.find();

    return onlyShowCover
        ? _buildCover(context, false)
        : Obx(() => Column(
              children: [
                // 封面
                Stack(
                  children: [
                    _buildCover(
                        context,
                        _animeDisplayController.showGridAnimeName.value &&
                            _animeDisplayController.showNameInCover.value),
                    if (showProgress)
                      _buildEpisodeState(_anime.isCollected() &&
                          _animeDisplayController.showGridAnimeProgress.value),
                    if (showReviewNumber)
                      _buildReviewNumber(_anime.isCollected() &&
                          _animeDisplayController.showReviewNumber.value &&
                          _anime.reviewNumber > 1)
                  ],
                ),
                // 名字
                _buildNameBelowCover(
                    _animeDisplayController.showNameBelowCover),
              ],
            ));
  }

  _buildCover(BuildContext context, bool showNameInCover) {
    return Container(
        width: coverWidth == 0 ? null : coverWidth,
        padding: const EdgeInsets.all(3.0),
        child: AspectRatio(
          // 固定宽高比
          aspectRatio: 198 / 275,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              children: [
                // 确保图片填充
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: CommonImage(_anime.getCommonCoverUrl()),
                ),
                // 被选中时，添加边框
                if (isSelected)
                  Container(
                    // child: Center(
                    //     child: Icon(Icons.check_circle_outline,
                    //         color: ThemeUtil.getPrimaryIconColor())),
                    decoration: BoxDecoration(
                      border: Border.all(
                          width: 4, color: ThemeUtil.getPrimaryIconColor()),
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.transparent.withOpacity(0.5),
                    ),
                  ),
                _buildNameInCover(showNameInCover)
              ],
            ),
          ),
        ));
  }

  _buildEpisodeState(bool show) {
    if (show) {
      return Positioned(
          left: 5,
          top: 5,
          child: Container(
            // height: 20,
            padding: const EdgeInsets.fromLTRB(3, 2, 3, 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: ThemeUtil.getPrimaryColor(),
            ),
            child: Text(
              "${_anime.checkedEpisodeCnt}/${_anime.animeEpisodeCnt}",
              textScaleFactor: 0.8,
              style: const TextStyle(color: Colors.white),
            ),
          ));
    } else {
      return Container();
    }
  }

  _buildReviewNumber(bool show) {
    if (show) {
      return Positioned(
          right: 5,
          top: 5,
          child: Container(
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3), color: Colors.orange),
            child: Text(" ${_anime.reviewNumber} ",
                textScaleFactor: 0.8,
                style: const TextStyle(color: Colors.white)),
          ));
    } else {
      return Container();
    }
  }

  _buildNameInCover(bool show) {
    if (!show) return Container();
    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: 80,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                    Colors.transparent,
                    Color.fromRGBO(0, 0, 0, 0.6)
                  ])),
            ),
          ],
        ),
        // 使用Align替换Positioned，可以保证在Stack下自适应父元素宽度
        Container(
          alignment: Alignment.bottomLeft,
          child: Container(
            padding: const EdgeInsets.fromLTRB(5, 0, 10, 5),
            child: _buildNameText(Colors.white),
          ),
        )
      ],
    );
  }

  String _getEllipsisMiddleAnimeName(String name, BoxConstraints constraints) {
    // return name;
    // Log.info(constraints.toString());
    if ((name.length > 3 && name[name.length - 3] == "第") ||
        name.endsWith("OVA")) {
      String testName = name;
      int endIdx = name.length - 3;

      while (!_notOverflow(testName, constraints)) {
        testName =
            "${name.substring(0, endIdx)}...${name.substring(name.length - 3)}";
        endIdx--;
      }
      return testName;
    } else {
      return name;
    }
  }

  // 检测方法参考自https://github.com/leisim/auto_size_text/blob/master/lib/src/auto_size_text.dart
  bool _notOverflow(String name, BoxConstraints constraints) {
    final textPainter = TextPainter(
        text: TextSpan(text: name),
        maxLines: 2,
        textDirection: TextDirection.ltr);
    textPainter.layout(maxWidth: constraints.maxWidth);
    if (textPainter.didExceedMaxLines) {
      Log.info("溢出：$name");
      return false;
    }
    return true;
  }

  _buildNameBelowCover(bool show) {
    return show
        ? Container(
            width: coverWidth == 0 ? null : coverWidth,
            padding: const EdgeInsets.only(top: 2, left: 3, right: 3),
            // 保证文字左对齐
            alignment: Alignment.centerLeft,
            child: _buildNameText(ThemeUtil.getFontColor()))
        : Container();
  }

  _buildNameText(Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Text(_getEllipsisMiddleAnimeName(_anime.animeName, constraints),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textScaleFactor: ThemeUtil.smallScaleFactor,
            style: TextStyle(color: color));
      },
    );
  }
}
