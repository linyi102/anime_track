import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/relative_local_image.dart';
import 'package:flutter_test_future/components/error_image_builder.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/pages/modules/image_viewer.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:transparent_image/transparent_image.dart';

// 网格的单个笔记图片构建
// 使用：笔记列表页
class NoteImgItem extends StatelessWidget {
  final List<RelativeLocalImage>
      relativeLocalImages; // 传入该网格的所有图片，是因为需要点击该图片(传入的下标)后能够进入图片浏览页面
  final int initialIndex; // 传入多个图片的起始下标
  final int imageRemainCount; // 笔记列表页：第9张图显示剩余图片数量
  const NoteImgItem(
      {required this.relativeLocalImages,
      this.initialIndex = 0,
      this.imageRemainCount = 0,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String relativeImagePath = relativeLocalImages[initialIndex].path;
    String imageLocalPath =
        ImageUtil.getAbsoluteNoteImagePath(relativeImagePath);

    FileImage? fileImage;
    try {
      // FileImage中final Uint8List bytes = await file.readAsBytes();
      // 如果找不到图片，会出现异常，但这里捕获不到
      fileImage = FileImage(File(imageLocalPath));
    } catch (e) {
      debugPrint(e.toString());
    }

    return MaterialButton(
      padding: const EdgeInsets.all(0),
      onPressed: () {
        Navigator.push(
            context,
            FadeRoute(
                // 因为里面的浏览器切换图片时自带了过渡效果，所以取消这个过渡
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                builder: (context) {
                  // 点击图片进入图片浏览页面
                  return ImageViewer(
                    relativeLocalImages: relativeLocalImages,
                    initialIndex: initialIndex,
                  );
                }));
      },
      child: Stack(children: [
        AspectRatio(
          aspectRatio: 1, // 正方形
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5), // 圆角
            // 增加过渡效果，否则突然显示会很突兀
            child: fileImage != null
                ? FadeInImage(
                    placeholder: MemoryImage(kTransparentImage),
                    image: fileImage,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 100),
                    imageErrorBuilder: errorImageBuilder(relativeImagePath),
                  )
                : Container(),
          ),
        ),
        imageRemainCount > 0
            ? Container(
                color: const Color.fromRGBO(0, 0, 0, 0.2),
                child: Center(
                  child: Text(
                    "+$imageRemainCount",
                    textScaleFactor: 2,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              )
            : Container()
      ]),
    );
  }
}
