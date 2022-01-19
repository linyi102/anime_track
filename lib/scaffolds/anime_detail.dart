import 'dart:io';

import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/episode_note.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/error_image_builder.dart';
import 'package:flutter_test_future/components/image_grid_item.dart';
import 'package:flutter_test_future/components/image_grid_view.dart';
import 'package:flutter_test_future/components/select_uint_dialog.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/anime_climb.dart';
import 'package:flutter_test_future/scaffolds/episode_note_sf.dart';
import 'package:flutter_test_future/scaffolds/tabs.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/classes/episode.dart';
import 'package:flutter_test_future/utils/tags.dart';

class AnimeDetailPlus extends StatefulWidget {
  final int animeId;
  const AnimeDetailPlus(this.animeId, {Key? key}) : super(key: key);

  @override
  _AnimeDetailPlusState createState() => _AnimeDetailPlusState();
}

class _AnimeDetailPlusState extends State<AnimeDetailPlus> {
  late Anime _anime;
  List<Episode> _episodes = [];
  bool _loadOk = false;
  List<EpisodeNote> episodeNotes = [];

  FocusNode blankFocusNode = FocusNode(); // 空白焦点
  FocusNode animeNameFocusNode = FocusNode(); // 动漫名字输入框焦点
  // FocusNode descFocusNode = FocusNode(); // 描述输入框焦点

  // 多选
  Map<int, bool> mapSelected = {};
  bool multiSelected = false;
  Color multiSelectedColor = Colors.blueAccent.withOpacity(0.25);

  bool hideNoteInAnimeDetail =
      SPUtil.getBool("hideNoteInAnimeDetail", defaultValue: false);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    Future(() {
      return SqliteUtil.getAnimeByAnimeId(widget.animeId); // 一定要return，value才有值
    }).then((value) async {
      _anime = value;
      debugPrint(value.toString());
      _episodes = await SqliteUtil.getAnimeEpisodeHistoryById(_anime);
      _sortEpisodes(SPUtil.getString("episodeSortMethod",
          defaultValue: sortMethods[0])); // 排序，默认升序，兼容旧版本
      for (var episode in _episodes) {
        EpisodeNote episodeNote = EpisodeNote(
            anime: _anime,
            episode: episode,
            relativeLocalImages: [],
            imgUrls: []);
        if (episode.isChecked()) {
          // 如果该集完成了，就去获取该集笔记（内容+图片）
          episodeNote =
              await SqliteUtil.getEpisodeNoteByAnimeIdAndEpisodeNumber(
                  episodeNote);
          // debugPrint(
          //     "第${episodeNote.episode.number}集的图片数量: ${episodeNote.relativeLocalImages.length}");
        }
        episodeNotes.add(episodeNote);
      }
    }).then((value) {
      _loadOk = true;
      setState(() {});
    });
  }

  // 用于传回到动漫列表页
  void _refreshAnime() {
    for (var episode in _episodes) {
      if (episode.isChecked()) _anime.checkedEpisodeCnt++;
    }
    SqliteUtil.updateDescByAnimeId(_anime.animeId, _anime.animeDesc);
    SqliteUtil.updateAnimeNameByAnimeId(_anime.animeId, _anime.animeName);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        debugPrint("按返回键，返回anime");
        _refreshAnime();
        Navigator.pop(context, _anime);
        debugPrint("返回true");
        return true;
      },
      child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
                onPressed: () {
                  debugPrint("按返回按钮，返回anime");
                  _refreshAnime();
                  Navigator.pop(context, _anime);
                },
                tooltip: "返回上一级",
                icon: const Icon(Icons.arrow_back_rounded)),
            title: !_loadOk
                ? Container()
                : ListTile(
                    title: Row(
                      children: [
                        Text(_anime.tagName),
                        const SizedBox(
                          width: 10,
                        ),
                        const Icon(Icons.expand_more_rounded),
                      ],
                    ),
                    onTap: () {
                      _dialogSelectTag();
                    },
                  ),
            actions: [
              IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      // MaterialPageRoute(
                      //   builder: (context) => AnimeClimb(
                      //     animeId: _anime.animeId,
                      //     keyword: _anime.animeName,
                      //   ),
                      // ),
                      FadeRoute(
                        builder: (context) {
                          return AnimeClimb(
                            animeId: _anime.animeId,
                            keyword: _anime.animeName,
                          );
                        },
                      ),
                    ).then((value) async {
                      _loadData();
                    });
                  },
                  tooltip: "搜索封面",
                  icon: const Icon(Icons.image_search_rounded)),
              IconButton(
                  onPressed: () {
                    _dialogDeleteAnime();
                  },
                  tooltip: "删除动漫",
                  icon: const Icon(Icons.delete)),
            ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: !_loadOk
                ? Container(
                    key: UniqueKey(),
                  )
                : Stack(children: [
                    ListView(
                      children: [
                        _displayAnimeInfo(),
                        const SizedBox(
                          height: 10,
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(15, 0, 15, 10),
                          child: Divider(
                            thickness: 1,
                          ),
                        ),
                        // _displayEpisode(),
                        _displayButtonsAboutEpisode(),
                        _displayEpisodePlus(),
                      ],
                    ),
                    _showBottomButton(),
                  ]),
          )),
    );
  }

  _displayAnimeInfo() {
    final imageProvider = Image.network(_anime.animeCoverUrl).image;
    return Stack(
      children: [
        // SizedBox(
        //   width: 999999999,
        //   height: 200,
        //   child: Opacity(
        //     opacity: 0.2,
        //     child: CachedNetworkImage(
        //       imageUrl: _anime.animeCoverUrl,
        //       fit: BoxFit.fitWidth,
        //     ),
        //   ),
        // ),
        Flex(
          direction: Axis.horizontal,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 20, 0, 15),
              child: SizedBox(
                width: 110,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: MaterialButton(
                    padding: const EdgeInsets.all(0),
                    onPressed: () {
                      showImageViewer(context, imageProvider, immersive: false);
                    },
                    child: AnimeGridCover(_anime),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _displayAnimeName(),
                  // _displayDesc(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  _displayAnimeName() {
    var animeNameTextEditingController = TextEditingController();
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
      child: TextField(
        focusNode: animeNameFocusNode,
        maxLines: null, // 加上这个后，回车不会调用onEditingComplete
        controller: animeNameTextEditingController..text = _anime.animeName,
        style: const TextStyle(
          fontSize: 17,
          overflow: TextOverflow.ellipsis,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
        onTap: () {},
        // 情况1：改完名字直接返回，此时需要onChanged来时刻监听输入的值，并改变_anime.animeName，然后在返回键和返回按钮中更新数据库并传回
        onChanged: (value) {
          _anime.animeName = value;
        },
        // 情况2：改完名字后回车，会直接保存到_anime.animeName和数据库中
        onEditingComplete: () {
          String newAnimeName = animeNameTextEditingController.text;
          debugPrint("失去焦点，动漫名称为：$newAnimeName");
          _anime.animeName = newAnimeName;
          SqliteUtil.updateAnimeNameByAnimeId(_anime.animeId, newAnimeName);
          FocusScope.of(context).requestFocus(blankFocusNode); // 焦点传给空白焦点
        },
      ),
    );
  }

  _displayDesc() {
    var descTextEditingController = TextEditingController();
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
      child: TextField(
        // focusNode: descFocusNode,
        maxLines: null,
        controller: descTextEditingController..text = _anime.animeDesc,
        decoration: const InputDecoration(
          hintText: "描述",
          border: InputBorder.none,
        ),
        style: const TextStyle(height: 1.5, fontSize: 16),
        onChanged: (value) {
          _anime.animeDesc = value;
        },
        // 因为设置的是无限行(可以回车换行)，所以怎样也不会执行onEditingComplete
        // onEditingComplete: () {
        //   debugPrint("失去焦点，动漫名称为：${descTextEditingController.text}");
        //   FocusScope.of(context).requestFocus(blankFocusNode); // 焦点传给空白焦点
        // },
      ),
    );
  }

  _displayEpisodePlus() {
    List<Widget> list = [];
    for (int episodeIndex = 0;
        episodeIndex < _episodes.length;
        ++episodeIndex) {
      list.add(
        ListTile(
          selectedTileColor: multiSelectedColor,
          selected: mapSelected.containsKey(episodeIndex),
          selectedColor: Colors.black,
          // visualDensity: const VisualDensity(vertical: -2),
          // contentPadding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          title: Text(
            "第 ${_episodes[episodeIndex].number} 集",
            style: TextStyle(
              color: _episodes[episodeIndex].isChecked()
                  ? Colors.black54
                  : Colors.black,
            ),
          ),
          // subtitle: Text(_episodes[i].getDate()),
          // enabled: !_episodes[i].isChecked(), // 完成后会导致无法长按设置日期
          // style: ListTileStyle.drawer,
          trailing: Text(
            _episodes[episodeIndex].getDate(),
            style: const TextStyle(color: Colors.black54),
          ),
          leading: IconButton(
            // iconSize: 20,
            visualDensity: VisualDensity.compact, // 缩小leading
            hoverColor: Colors.transparent, // 悬停时的颜色
            highlightColor: Colors.transparent, // 长按时的颜色
            splashColor: Colors.transparent, // 点击时的颜色
            onPressed: () async {
              if (_episodes[episodeIndex].isChecked()) {
                _dialogRemoveDate(
                  _episodes[episodeIndex].number,
                  _episodes[episodeIndex].dateTime,
                ); // 这个函数执行完毕后，在执行下面的setState并不会更新页面，因此需要在该函数中使用setState
              } else {
                String date = DateTime.now().toString();
                SqliteUtil.insertHistoryItem(
                    _anime.animeId, _episodes[episodeIndex].number, date);
                _episodes[episodeIndex].dateTime = date;
                // 同时插入空笔记，记得获取最新插入的id，否则进入的是笔记0，会造成修改笔记无效
                EpisodeNote episodeNote = EpisodeNote(
                    anime: _anime,
                    episode: _episodes[episodeIndex],
                    relativeLocalImages: [],
                    imgUrls: []);

                // 如果存在，恢复之前做的笔记。(完成该集并添加笔记后，又完成该集，需要恢复笔记)
                episodeNotes[episodeIndex] =
                    await SqliteUtil.getEpisodeNoteByAnimeIdAndEpisodeNumber(
                        episodeNote);
                // 不存在，则添加新笔记。因为获取笔记的函数中也实现了没有则添加新笔记，因此就不需要这个了
                // episodeNote.episodeNoteId =
                //     await SqliteUtil.insertEpisodeNote(episodeNote);
                // episodeNotes[i] = episodeNote; // 更新
                _moveToLastIfSet(episodeIndex);
                setState(() {});
              }
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              // transitionBuilder: (Widget child, Animation<double> animation) {
              //   //执行缩放动画
              //   return ScaleTransition(child: child, scale: animation);
              // },
              child: _episodes[episodeIndex].isChecked()
                  ? Icon(
                      Icons.check_box_outlined,
                      // Icons.check_rounded,
                      color: Colors.black54,
                      key: Key("$episodeIndex"), // 不能用unique，否则同状态的按钮都会有动画
                    )
                  : const Icon(
                      Icons.check_box_outline_blank_rounded,
                      color: Colors.black54,
                    ),
            ),
          ),
          onTap: () {
            onpress(episodeIndex);
          },
          onLongPress: () async {
            // pickDate(episodeIndex);
            onLongPress(episodeIndex);
          },
        ),
      );
      // 显示笔记
      if (!hideNoteInAnimeDetail && _episodes[episodeIndex].isChecked()) {
        list.add(Padding(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          child: episodeNotes[episodeIndex].relativeLocalImages.isEmpty &&
                  episodeNotes[episodeIndex].noteContent.isEmpty
              ? Container()
              : Card(
                  elevation: 0,
                  child: MaterialButton(
                    padding: episodeNotes[episodeIndex].noteContent.isEmpty
                        ? const EdgeInsets.fromLTRB(0, 0, 0, 0)
                        : const EdgeInsets.fromLTRB(0, 10, 0, 0),
                    onPressed: () {
                      Navigator.of(context).push(
                        // MaterialPageRoute(
                        //     builder: (context) =>
                        //         EpisodeNoteSF(episodeNotes[episodeIndex])),
                        FadeRoute(
                          builder: (context) {
                            return EpisodeNoteSF(episodeNotes[episodeIndex]);
                          },
                        ),
                      ).then((value) {
                        episodeNotes[episodeIndex] = value; // 更新修改
                        setState(() {});
                      });
                    },
                    child: Column(
                      children: [
                        episodeNotes[episodeIndex].noteContent.isEmpty
                            ? Container()
                            : ListTile(
                                title: Text(
                                  episodeNotes[episodeIndex].noteContent,
                                  maxLines: 10,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: ListTileStyle.drawer,
                              ),
                        episodeNotes[episodeIndex].relativeLocalImages.length ==
                                1
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(5), // 圆角
                                child: Image.file(
                                  File(ImageUtil.getAbsoluteImagePath(
                                      episodeNotes[episodeIndex]
                                          .relativeLocalImages[0]
                                          .path)),
                                  fit: BoxFit.fitHeight,
                                  errorBuilder: errorImageBuilder(
                                      episodeNotes[episodeIndex]
                                          .relativeLocalImages[0]
                                          .path),
                                ),
                              )
                            : showImageGridView(
                                episodeNotes[episodeIndex]
                                    .relativeLocalImages
                                    .length, (BuildContext context, int index) {
                                return ImageGridItem(
                                    relativeImagePath:
                                        episodeNotes[episodeIndex]
                                            .relativeLocalImages[index]
                                            .path);
                              })
                      ],
                    ),
                  ),
                ),
        ));
      }
    }
    return Column(
      children: list,
    );
  }

  void pickDate(i) async {
    DateTime defaultDateTime = DateTime.now();
    if (_episodes[i].isChecked()) {
      defaultDateTime = DateTime.parse(_episodes[i].dateTime as String);
    }
    String dateTime = await _showDatePicker(defaultDateTime: defaultDateTime);

    if (dateTime.isEmpty) return; // 没有选择日期，则直接返回

    // 选择日期后，如果之前有日期，则更新。没有则直接插入
    // 注意：对于_episodes[i]，它是第_episodes[i].number集
    int episodeNumber = _episodes[i].number;
    if (_episodes[i].isChecked()) {
      SqliteUtil.updateHistoryItem(_anime.animeId, episodeNumber, dateTime);
    } else {
      SqliteUtil.insertHistoryItem(_anime.animeId, episodeNumber, dateTime);
    }
    // 更新页面
    setState(() {
      // 改的是i，而不是episodeNumber
      _episodes[i].dateTime = dateTime;
    });
  }

  void onpress(episodeIndex) {
    // 多选
    if (multiSelected) {
      if (mapSelected.containsKey(episodeIndex)) {
        mapSelected.remove(episodeIndex); // 选过，再选就会取消
        // 如果取消后一个都没选，就自动退出多选状态
        if (mapSelected.isEmpty) {
          multiSelected = false;
        }
      } else {
        mapSelected[episodeIndex] = true;
      }
      setState(() {});
    } else {
      FocusScope.of(context).requestFocus(blankFocusNode); // 焦点传给空白焦点
      if (_episodes[episodeIndex].isChecked()) {
        Navigator.of(context).push(
          // MaterialPageRoute(
          //     builder: (context) => EpisodeNoteSF(episodeNotes[i])),
          FadeRoute(
            builder: (context) {
              return EpisodeNoteSF(episodeNotes[episodeIndex]);
            },
          ),
        ).then((value) {
          episodeNotes[episodeIndex] = value; // 更新修改
          setState(() {});
        });
      }
    }
  }

  void onLongPress(index) {
    // 非多选状态下才需要进入多选状态
    if (multiSelected == false) {
      multiSelected = true;
      mapSelected[index] = true;
      setState(() {}); // 添加操作按钮
    }
  }

  Future<String> _showDatePicker({DateTime? defaultDateTime}) async {
    var picker = await showDatePicker(
        context: context,
        initialDate: defaultDateTime ?? DateTime.now(), // 没有给默认时间时，设置为今天
        firstDate: DateTime(1986),
        lastDate: DateTime(DateTime.now().year + 2),
        locale: const Locale("zh"));
    return picker == null ? "" : picker.toString();
  }

  _showBottomButton() {
    return !multiSelected
        ? Container()
        : Container(
            alignment: Alignment.bottomCenter,
            child: Card(
              elevation: 4,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15))), // 圆角
              clipBehavior: Clip.antiAlias, // 设置抗锯齿，实现圆角背景
              color: Colors.white,
              margin: const EdgeInsets.fromLTRB(50, 20, 50, 20),
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: IconButton(
                      onPressed: () {
                        if (mapSelected.length == _episodes.length) {
                          // 全选了，点击则会取消全选
                          mapSelected.clear();
                        } else {
                          // 其他情况下，全选
                          for (int j = 0; j < _episodes.length; ++j) {
                            mapSelected[j] = true;
                          }
                        }
                        setState(() {});
                      },
                      icon: const Icon(Icons.select_all_rounded),
                      color: Colors.black,
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed: () async {
                        DateTime defaultDateTime = DateTime.now();
                        String dateTime = await _showDatePicker(
                            defaultDateTime: defaultDateTime);
                        if (dateTime.isNotEmpty) {
                          mapSelected.forEach((episodeIndex, value) {
                            int episodeNumber = _episodes[episodeIndex].number;
                            if (_episodes[episodeIndex].isChecked()) {
                              SqliteUtil.updateHistoryItem(
                                  _anime.animeId, episodeNumber, dateTime);
                            } else {
                              SqliteUtil.insertHistoryItem(
                                  _anime.animeId, episodeNumber, dateTime);
                              // 同时插入空笔记，记得获取最新插入的id，否则进入的是笔记0，会造成修改笔记无效
                              EpisodeNote episodeNote = EpisodeNote(
                                  anime: _anime,
                                  episode: _episodes[episodeIndex],
                                  relativeLocalImages: [],
                                  imgUrls: []);

                              // 如果存在，恢复之前做的笔记。(完成该集并添加笔记后，又完成该集，需要恢复笔记)
                              () async {
                                episodeNotes[episodeIndex] = await SqliteUtil
                                    .getEpisodeNoteByAnimeIdAndEpisodeNumber(
                                        episodeNote);
                              }(); // 只让恢复笔记作为异步，如果让forEach中的函数作为异步，则可能会在改变所有时间前退出多选模式
                            }
                            _episodes[episodeIndex].dateTime = dateTime;
                          });
                        } // 遍历选中的下标
                        // 退出多选模式
                        _quitMultiSelectState();
                      },
                      icon: const Icon(Icons.date_range),
                      color: Colors.black,
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed: () {
                        _quitMultiSelectState();
                      },
                      icon: const Icon(Icons.exit_to_app_outlined),
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  void _quitMultiSelectState() {
    // 清空选择的动漫(注意在修改数量之后)，并消除多选状态
    multiSelected = false;
    mapSelected.clear();
    setState(() {});
  }

  void _dialogRemoveDate(int episodeNumber, String? date) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('提示'),
          content: const Text('是否撤销日期?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('否'),
            ),
            TextButton(
              onPressed: () {
                SqliteUtil.deleteHistoryItemByAnimeIdAndEpisodeNumber(
                    _anime.animeId, episodeNumber);
                // 根据episodeNumber找到对应的下标
                int findIndex = _getEpisodeIndexByEpisodeNumber(episodeNumber);
                _episodes[findIndex].cancelDateTime();
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('是'),
            ),
          ],
        );
      },
    );
  }

  void _dialogSelectTag() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<Widget> radioList = [];
        for (int i = 0; i < tags.length; ++i) {
          radioList.add(
            ListTile(
              title: Text(tags[i]),
              leading: tags[i] == _anime.tagName
                  ? const Icon(
                      Icons.radio_button_on_outlined,
                      color: Colors.blue,
                    )
                  : const Icon(
                      Icons.radio_button_off_outlined,
                    ),
              onTap: () {
                _anime.tagName = tags[i];
                SqliteUtil.updateTagByAnimeId(_anime.animeId, _anime.tagName);
                debugPrint("修改标签为${_anime.tagName}");
                setState(() {});
                Navigator.pop(context);
              },
            ),
          );
        }
        return AlertDialog(
          title: const Text('选择标签'),
          content: SingleChildScrollView(
            child: Column(
              children: radioList,
            ),
          ),
        );
      },
    );
  }

  List<String> sortMethods = [
    "sortByEpisodeNumberAsc",
    "sortByEpisodeNumberDesc",
    "sortByUnCheckedFront"
  ];

  List<String> sortMethodsName = ["集数升序", "集数倒序", "未完成在前"];

  void _dialogSelectSortMethod() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<Widget> radioList = [];
        for (int i = 0; i < sortMethods.length; ++i) {
          radioList.add(
            ListTile(
              title: Text(sortMethodsName[i]),
              leading: sortMethods[i] == SPUtil.getString("episodeSortMethod")
                  ? const Icon(
                      Icons.radio_button_on_outlined,
                      color: Colors.blue,
                    )
                  : const Icon(
                      Icons.radio_button_off_outlined,
                    ),
              onTap: () {
                debugPrint("修改排序方式为${sortMethods[i]}");
                _sortEpisodes(sortMethods[i]);
                setState(() {});
                Navigator.pop(context);
              },
            ),
          );
        }
        return AlertDialog(
          title: const Text('排序方式'),
          content: SingleChildScrollView(
            child: Column(
              children: radioList,
            ),
          ),
        );
      },
    );
  }

  _dialogDeleteAnime() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("警告！"),
            content: const Text("确认删除该动漫吗？"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("取消")),
              TextButton(
                  onPressed: () {
                    SqliteUtil.deleteAnimeByAnimeId(_anime.animeId);
                    // 直接返回到主页
                    Navigator.of(context).pushAndRemoveUntil(
                      // MaterialPageRoute(builder: (context) => const Tabs()),
                      FadeRoute(
                        builder: (context) {
                          return const Tabs();
                        },
                      ),
                      (route) => false,
                    ); // 返回false就没有左上角的返回按钮了
                  },
                  child: const Text(
                    "确认",
                    style: TextStyle(color: Colors.red),
                  )),
            ],
          );
        });
  }

  _displayButtonsAboutEpisode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      // direction: Axis.horizontal,
      children: [
        // Row(children: [
        //   Padding(
        //       padding: const EdgeInsets.only(left: 15),
        //       child: Text(
        //         "共 ${_episodes.length} 集",
        //         // style: const TextStyle(fontSize: 20),
        //       )),
        // ]),
        Expanded(child: Container()),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
                onPressed: () {
                  if (hideNoteInAnimeDetail) {
                    // 原先隐藏，则设置为false，表示显示
                    SPUtil.setBool("hideNoteInAnimeDetail", false);
                    hideNoteInAnimeDetail = false;
                  } else {
                    SPUtil.setBool("hideNoteInAnimeDetail", true);
                    hideNoteInAnimeDetail = true;
                  }
                  setState(() {});
                },
                tooltip: hideNoteInAnimeDetail ? "显示笔记" : "隐藏笔记",
                icon: hideNoteInAnimeDetail
                    ? const Icon(Icons.fullscreen_rounded)
                    : const Icon(Icons.fullscreen_exit_rounded)),
            IconButton(
                onPressed: () {
                  // _dialogUpdateEpisodeCnt();
                  dialogSelectUint(context, "修改集数",
                          defaultValue: _anime.animeEpisodeCnt)
                      .then((value) {
                    if (value == null) {
                      debugPrint("未选择，直接返回");
                      return;
                    }
                    int episodeCnt = value;
                    SqliteUtil.updateEpisodeCntByAnimeId(
                        _anime.animeId, episodeCnt);

                    _anime.animeEpisodeCnt = episodeCnt;
                    // 少了就删除，多了就添加
                    var len = _episodes
                        .length; // 因为添加或删除时_episodes.length会变化，所以需要保存到一个变量中
                    if (len > episodeCnt) {
                      for (int i = 0; i < len - episodeCnt; ++i) {
                        // 还应该删除history表里的记录，否则会误判完成过的集数
                        SqliteUtil.deleteHistoryItemByAnimeIdAndEpisodeNumber(
                            _anime.animeId, _episodes.last.number);
                        // 注意顺序
                        _episodes.removeLast();
                      }
                    } else {
                      int number = _episodes.last.number;
                      for (int i = 0; i < episodeCnt - len; ++i) {
                        _episodes.add(Episode(number + i + 1));
                      }
                    }
                    setState(() {});
                  });
                },
                tooltip: "更改集数",
                icon: const Icon(Icons.add)),
            IconButton(
                onPressed: () {
                  _dialogSelectSortMethod();
                },
                tooltip: "排序方式",
                icon: const Icon(Icons.sort)),
          ],
        ),
      ],
    );
  }

  void _sortEpisodes(String sortMethod) {
    if (sortMethod == "sortByEpisodeNumberAsc") {
      _sortByEpisodeNumberAsc(sortMethod);
    } else if (sortMethod == "sortByEpisodeNumberDesc") {
      _sortByEpisodeNumberDesc(sortMethod);
    } else if (sortMethod == "sortByUnCheckedFront") {
      _sortByUnCheckedFront(sortMethod);
    } else {
      throw "不可能的排序方式";
    }
    SPUtil.setString("episodeSortMethod", sortMethod);
  }

  void _sortByEpisodeNumberAsc(String sortMethod) {
    _episodes.sort((a, b) {
      return a.number.compareTo(b.number);
    });
  }

  void _sortByEpisodeNumberDesc(String sortMethod) {
    _episodes.sort((a, b) {
      return b.number.compareTo(a.number);
    });
  }

  // 未完成的靠前，完成的按number升序排序
  void _sortByUnCheckedFront(String sortMethod) {
    _sortByEpisodeNumberAsc(sortMethod); // 先按number升序排序
    _episodes.sort((a, b) {
      int ac, bc;
      ac = a.isChecked() ? 1 : 0;
      bc = b.isChecked() ? 1 : 0;
      return ac.compareTo(bc);
    });
  }

  // 如果设置了未完成的靠前，则完成某集后移到最后面
  void _moveToLastIfSet(int index) {
    // 先不用移到最后面吧
    // // 先移除，再添加
    // if (SPUtil.getBool("sortByUnCheckedFront")) {
    //   Episode episode = _episodes[index];
    //   _episodes.removeAt(index);
    //   _episodes.add(episode); // 不应该直接在后面添加，而是根据number插入到合适的位置。但还要注意越界什么的
    // }
  }
  // 如果取消了日期，还需要移到最前面。好麻烦...还得插入到合适的位置

  int _getEpisodeIndexByEpisodeNumber(int episodeNumber) {
    return _episodes.indexWhere((element) => element.number == episodeNumber);
  }
}
