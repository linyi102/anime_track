import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/climb_website.dart';
import 'package:flutter_test_future/components/anime_horizontal_cover.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/anime_climb.dart';
import 'package:flutter_test_future/utils/climb_anime_util.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';

class AnimeClimbAllWebsite extends StatefulWidget {
  final int animeId;
  final String keyword;
  const AnimeClimbAllWebsite({this.animeId = 0, this.keyword = "", Key? key})
      : super(key: key);

  @override
  _AnimeClimbAllWebsiteState createState() => _AnimeClimbAllWebsiteState();
}

class _AnimeClimbAllWebsiteState extends State<AnimeClimbAllWebsite> {
  var inputKeywordController = TextEditingController();
  FocusNode blankFocusNode = FocusNode(); // 空白焦点
  bool ismigrate = false;

  String addDefaultTag = tags[0];
  String lastInputName = "";
  Map<String, List<Anime>> websiteClimbAnimes = {};
  Map<String, bool> websiteClimbSearchOk = {}; // true时显示搜索结果
  Map<String, bool> websiteClimbSearching = {}; // true时显示进度圈

  @override
  void initState() {
    super.initState();
    ismigrate = widget.animeId > 0 ? true : false;
    lastInputName = widget.keyword;

    for (var climbWebsite in climbWebsites) {
      websiteClimbSearchOk[climbWebsite.name] = false;
      websiteClimbSearching[climbWebsite.name] = false;
    }

    // TODO：去除delay报错
    Future.delayed(Duration.zero).then((value) {
      if (ismigrate) {
        _climbAnime(keyword: widget.keyword);
      }
    });
  }

  _climbAnime({String keyword = ""}) {
    FocusScope.of(context).requestFocus(blankFocusNode);
    // 先全部清除数据
    for (var climbWebsite in climbWebsites) {
      websiteClimbSearchOk[climbWebsite.name] = false;
      websiteClimbSearching[climbWebsite.name] = false;
    }

    debugPrint("开始爬取动漫封面");
    for (var climbWebsite in climbWebsites) {
      Future(() async {
        // 正在搜索，用于显示加载圈
        websiteClimbSearching[climbWebsite.name] = true;
        setState(() {});

        return ClimbAnimeUtil.climbAnimesByKeywordInWebSiteName(
            keyword, climbWebsite.name);
      }).then((value) async {
        websiteClimbAnimes[climbWebsite.name] = value;
        websiteClimbSearchOk[climbWebsite.name] = true;
        // 根据动漫网址查询是否已经添加了该动漫
        // 需要等更新为数据库动漫完毕后才显示，否则提前显示时，可以迁移到已添加的动漫
        _updateDBAnimesToClimbAnimes(climbWebsite)
            .then((value) => setState(() {}));
        // websiteClimbAnimes["自定义"]!.insert(
        //     0,
        //     Anime(
        //       animeName: keyword,
        //       animeEpisodeCnt: 0,
        //       animeCoverUrl: "",
        //     ));
      });
    }
  }

  Future<bool> _updateDBAnimesToClimbAnimes(ClimbWebStie climbWebsite) async {
    for (var i = 0; i < websiteClimbAnimes[climbWebsite.name]!.length; i++) {
      websiteClimbAnimes[climbWebsite.name]![i] =
          await SqliteUtil.getAnimeByAnimeUrl(
              websiteClimbAnimes[climbWebsite.name]![i]);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus:
              widget.keyword.isEmpty ? true : false, // 自动弹出键盘，如果是修改封面，则为false
          controller: inputKeywordController..text = lastInputName,
          decoration: InputDecoration(
              hintText: ismigrate ? "迁移动漫" : "添加动漫",
              border: InputBorder.none,
              suffixIcon: IconButton(
                  onPressed: () {
                    inputKeywordController.clear();
                  },
                  icon: const Icon(Icons.close, color: Colors.black))),
          onEditingComplete: () async {
            String text = inputKeywordController.text;
            // 如果输入的名字为空，则不再爬取
            if (text.isEmpty) {
              return;
            }
            lastInputName = text; // 更新上一次输入的名字
            _climbAnime(keyword: text);
          },
          onChanged: (inputStr) {
            lastInputName = inputStr;
            // 避免输入好后切换搜索源后，清空了输入的内容
          },
        ),
      ),
      body: ListView.builder(
        itemCount: () {
          // 定义匿名函数
          int count = 0;
          // 统计开启的搜索源数量
          for (var climbWebsite in climbWebsites) {
            if (climbWebsite.enable) count++;
          }
          return count; // +1是因为要添加自定义动漫
        }(), // ()执行该函数
        itemBuilder: (context, index) {
          String websiteName = climbWebsites[index].name;
          // 如果关闭了，则不显示
          if (!climbWebsites[index].enable) return Container();

          return ListView(
            shrinkWrap: true, //解决无限高度问题
            physics: const NeverScrollableScrollPhysics(), //禁用滑动事件
            children: [
              ListTile(
                title: Text(websiteName),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  // 进入详细搜索页
                  Navigator.of(context).push(FadeRoute(builder: (context) {
                    return AnimeClimb(
                      animeId: widget.animeId, // 进入详细搜索页迁移动漫，也需要传入动漫id
                      keyword: lastInputName,
                      climbWebStie: climbWebsites[index],
                    );
                  })).then((value) {
                    // 如果是进入详细页迁移后，则直接返回到动漫详细页
                    if (ismigrate) {
                      Navigator.of(context).pop();
                    } else {
                      // 可能进入详细搜索页后修改了数据库动漫，因此也需要重新搜索数据库(只搜索该搜索源下爬取的动漫网址)
                      // 小问题：进入动漫详细页后，迁移到了其他搜索源的动漫，animeUrl发生变化，此时该函数会通过animeUrl从数据库找到相应的动漫，并赋值，因此会出现原搜索源下面出现了一个其它搜索源的动漫
                      // 无法修复，因为迁移到其他搜索源后，animeUrl发生了变化，不再是原搜素源
                      _updateDBAnimesToClimbAnimes(climbWebsites[index])
                          .then((value) => setState(() {}));
                    }
                  });
                },
              ),
              websiteClimbSearchOk[websiteName] ?? false
                  ? AnimeHorizontalCover(
                      animes: websiteClimbAnimes[websiteName] ?? [],
                      ismigrate: ismigrate,
                      animeId: widget.animeId,
                    ) // 查询好后显示结果
                  : websiteClimbSearching[websiteName] ?? false
                      ? const SizedBox(
                          // 每个搜索结果的显示高度(封面+名字高度)
                          height: 137 + 60,
                          child: Center(
                            // 固定宽高的指示器
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ) // 搜索时显示加载圈
                      : Container() // 没有搜索则什么都不显示
            ],
          );
        },
      ),
    );
  }
}
