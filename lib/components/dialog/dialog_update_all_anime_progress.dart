import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../controllers/update_record_controller.dart';

dialogUpdateAllAnimeProgress(parentContext) {
  final UpdateRecordController updateRecordController = Get.find();

  showDialog(
      context: parentContext,
      builder: (context) {
        return AlertDialog(
          title: const Text("动漫更新"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Obx(
                  () {
                    int updateOkCnt = updateRecordController.updateOkCnt.value;
                    int needUpdateCnt =
                        updateRecordController.needUpdateCnt.value;
                    // 更新完毕后自动退出对话框
                    if (updateOkCnt == needUpdateCnt) {
                      Navigator.of(context).pop();
                    }

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                      child: LinearPercentIndicator(
                        barRadius: const Radius.circular(15),
                        // 圆角
                        animation: false,
                        lineHeight: 20.0,
                        animationDuration: 1000,
                        percent: needUpdateCnt > 0
                            ? (updateOkCnt / needUpdateCnt)
                            : 0,
                        center: Text("$updateOkCnt / $needUpdateCnt"),
                        progressColor: Colors.greenAccent,
                      ),
                    );
                  },
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                  child: const Text(
                    "小提示：更新时会跳过已完结动漫",
                    style: TextStyle(color: Colors.grey),
                    textScaleFactor: 0.8,
                  ),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("关闭"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      });
}
