import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/fav_website.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:transparent_image/transparent_image.dart';

import '../modules/website_icon.dart';

class FavWebsiteListPage extends StatelessWidget {
  FavWebsiteListPage({Key? key}) : super(key: key);
  final List<FavWebsite> defaultList = [
    FavWebsite(
        url: "https://bgmlist.com/",
        icoUrl: "https://bgmlist.com/public/favicons/apple-touch-icon.png",
        name: "番组放送"),
  ];
  bool openWebInApp = SPUtil.getBool("openWebInApp", defaultValue: true);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text("网站导航"),
          style: ListTileStyle.drawer,
          trailing: _buildSettingButton(context),
        ),
        _buildListView(),
        // _buildGridView(),
      ],
    );
  }

  _buildListView() {
    return ListView.builder(
        // 解决报错问题
        shrinkWrap: true,
        //解决不滚动问题
        physics: const NeverScrollableScrollPhysics(),
        itemCount: defaultList.length,
        itemBuilder: (context, index) {
          FavWebsite favWebsite = defaultList[index];
          return ListTile(
            title: Text(favWebsite.name, textScaleFactor: ThemeUtil.smallScaleFactor,),
            leading: buildWebSiteIcon(url: favWebsite.icoUrl, size: 35),
            onTap: () => _launchUrl(favWebsite.url),
          );
        });
  }

  GridView _buildGridView() {
    return GridView.builder(
        // 解决报错问题
        shrinkWrap: true,
        //解决不滚动问题
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: Platform.isWindows ? 8 : 4),
        itemCount: defaultList.length,
        itemBuilder: (context, index) {
          FavWebsite favWebsite = defaultList[index];
          return Card(
            elevation: 0,
            child: MaterialButton(
              padding: const EdgeInsets.all(0),
              onPressed: () => _launchUrl(favWebsite.url),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildWebSiteIcon(url: favWebsite.icoUrl, size: 35),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(favWebsite.name, textScaleFactor: 0.8)
                ],
              ),
            ),
          );
        });
  }

  _launchUrl(String url) {
    LaunchUrlUtil.launch(url, inApp: openWebInApp);
  }

  IconButton _buildSettingButton(BuildContext context) {
    return IconButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (dialogContext) {
                // 返回有状态的builder，从而实现对话框内实时更新
                return StatefulBuilder(builder: (context, setState) {
                  return AlertDialog(
                    content: SingleChildScrollView(
                      child: Column(
                        children: [
                          ListTile(
                              title: const Text("应用内打开网页"),
                              subtitle: const Text("仅对Android端有效"),
                              trailing: openWebInApp
                                  ? const Icon(Icons.toggle_on,
                                      color: Colors.blue)
                                  : const Icon(Icons.toggle_off),
                              onTap: () {
                                setState(() {
                                  openWebInApp = !openWebInApp;
                                });
                                SPUtil.setBool("openWebInApp", openWebInApp);
                              })
                        ],
                      ),
                    ),
                  );
                });
              });
        },
        icon: const Icon(Icons.settings));
  }
}
