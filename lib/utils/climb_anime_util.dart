import 'package:dio/dio.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/filter.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:html/parser.dart';
import 'package:flutter/material.dart';

class ClimbAnimeUtil {
  // 刷新动漫封面
  static Future<String> climbCoverUrl(String keyword) async {
    String coverUrl = "";
    coverUrl = await sourceOfyhdm(keyword);

    return coverUrl;
  }

  static Future<String> sourceOfyhdm(String keyword) async {
    String url = "https://www.yhdmp.cc/s_all?ex=1&kw=$keyword";
    try {
      var response = await Dio().get(url);
      var document = parse(response.data);
      var elements = document.getElementsByClassName("lpic");
      String? coverUrl = elements[0]
          .children[0]
          .children[
              0] // 可能并没有元素，因此会提示：RangeError (index): Invalid value: Valid value range is empty: 0
          .children[0]
          .children[0]
          .attributes["src"];
      if (coverUrl != null && coverUrl.startsWith("//")) {
        coverUrl = "https:$coverUrl";
      }
      return coverUrl ?? ""; // 搜不到则返回空串
    } catch (e) {
      debugPrint(e.toString());
      return "";
    }
  }

  // 根据网址前缀来判断来源
  static String getSourceByAnimeUrl(String animeUrl) {
    if (animeUrl.isEmpty) {
      return "无来源";
    } else if (animeUrl.startsWith("https://www.yhdmp.cc")) {
      return "樱花动漫";
    } else {
      return "未知来源";
    }
  }

  // 根据过滤查询目录动漫
  static Future<List<Anime>> climbDirectory(Filter filter) async {
    List<Anime> directory = [];
    String selectedWebsite =
        SPUtil.getString("selectedWebsite", defaultValue: "樱花动漫");
    if (selectedWebsite == "樱花动漫") {
      directory = await climbDirectoryOfyhdm(filter);
    } else if (selectedWebsite == "OmoFun") {
      // directory = await climbDirectoryOfOmoFun(filter);
    } else {
      throw ("爬取的网站名错误: $selectedWebsite");
    }
    return directory;
  }

// 目录页和搜索页的结果一致，只是链接不一样，共用爬取片段
  static Future<List<Anime>> _climbOfyhdm(String baseUrl, String url) async {
    List<Anime> animes = [];
    try {
      var response = await Dio().get(url);
      var document = parse(response.data);
      var lpic = document.getElementsByClassName("lpic")[0];
      var lis = lpic.getElementsByTagName("li");
      for (var li in lis) {
        String desc = li.getElementsByTagName("p")[0].innerHtml;
        String episodeCntStr = li.getElementsByTagName("font")[0].innerHtml;
        int episodeCnt = -1;
        if (episodeCntStr == "[全集]") {
          episodeCnt = 1;
        } else {
          int episodeCntStartIndex = episodeCntStr.indexOf("第") + 1;
          int episodeCntEndIndex = episodeCntStr.indexOf("集"); // 不要-1
          if (episodeCntStartIndex < episodeCntEndIndex) {
            episodeCnt = int.parse(episodeCntStr.substring(
                episodeCntStartIndex, episodeCntEndIndex));
          }
        }
        String? coverUrl = li.getElementsByTagName("img")[0].attributes["src"];
        if (coverUrl != null && coverUrl.startsWith("//")) {
          coverUrl = "https:$coverUrl";
        }
        String? animeName = li.getElementsByTagName("img")[0].attributes["alt"];
        String animeUrl = baseUrl +
            (li.getElementsByTagName("a")[0].attributes["href"] ?? "");
        Anime anime = Anime(
          animeName: animeName ?? "", // 没有名字时返回空串
          animeEpisodeCnt: episodeCnt,
          animeDesc: desc,
          animeCoverUrl: coverUrl ?? "",
          animeUrl: animeUrl,
        );
        animes.add(anime);
        // 进入该动漫网址，获取详细信息(每个动漫都得获取，速度太慢了)
        // try {
        //   var response = await Dio().get(animeUrl);
        //   var document = parse(response.data);
        //   var animeInfo = document.getElementsByClassName("sinfo")[0];
        //   String premiereTime = animeInfo
        //       .getElementsByTagName("span")[0]
        //       .getElementsByTagName("a")[0]
        //       .innerHtml;
        //   String area = animeInfo
        //       .getElementsByTagName("span")[1]
        //       .getElementsByTagName("a")[0]
        //       .innerHtml;
        //   String category = animeInfo
        //       .getElementsByTagName("span")[4]
        //       .getElementsByTagName("a")[0]
        //       .innerHtml;
        //   String playStatus = animeInfo
        //       .getElementsByTagName("span")[4]
        //       .getElementsByTagName("a")[2]
        //       .innerHtml;
        //   Anime anime = Anime(
        //     animeName: animeName ?? "", // 没有名字时返回空串
        //     animeEpisodeCnt: episodeCnt,
        //     animeDesc: desc,
        //     animeCoverUrl: coverUrl ?? "",
        //     coverSource: "yhdm",
        //     animeUrl: animeUrl,
        //     premiereTime: premiereTime,
        //     area: area,
        //     category: category,
        //     playStatus: playStatus,
        //   );
        //   directory.add(anime);
        // } catch (e) {
        //   debugPrint(e.toString());
        // }
        // debugPrint(anime);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return animes;
  }

  static Future<List<Anime>> climbDirectoryOfyhdm(Filter filter) async {
    String baseUrl = "https://www.yhdmp.cc";
    String url = baseUrl +
        "/list/?region=${filter.region}&year=${filter.year}&season=${filter.season}&status=${filter.status}&label=${filter.label}&order=${filter.order}";

    List<Anime> directory = await _climbOfyhdm(baseUrl, url);
    return directory;
  }

  // 根据关键字爬取动漫
  static Future<List<Anime>> climbAnimesByKeyword(String keyword) async {
    List<Anime> allAnimeNameAndCoverUrl = [];

    String selectedWebsite =
        SPUtil.getString("selectedWebsite", defaultValue: "樱花动漫");
    if (selectedWebsite == "樱花动漫") {
      allAnimeNameAndCoverUrl = await climbAnimesByKeywordOfyhdm(keyword);
    } else if (selectedWebsite == "OmoFun") {
      allAnimeNameAndCoverUrl = await climbAnimesByKeywordOfOmoFun(keyword);
    } else {
      throw ("爬取的网站名错误: $selectedWebsite");
    }
    return allAnimeNameAndCoverUrl;
  }

  static Future<List<Anime>> climbAnimesByKeywordOfyhdm(String keyword) async {
    String baseUrl = "https://www.yhdmp.cc";
    String url = baseUrl + "/s_all?ex=1&kw=$keyword";
    return await _climbOfyhdm(baseUrl, url);
  }

  static Future<List<Anime>> climbAnimesByKeywordOfOmoFun(
      String keyword) async {
    String url = "https://omofun.tv/index.php/vod/search.html?wd=$keyword";
    List<Anime> allAnimeNameAndCoverUrl = [];
    try {
      var response = await Dio().get(url);
      var document = parse(response.data);
      var elements = document.getElementsByClassName("lazy lazyload");
      for (var element in elements) {
        String? coverUrl = element.attributes["data-src"];
        String? animeName = element.attributes["alt"];
        if (coverUrl != null) {
          if (coverUrl.startsWith("//")) coverUrl = "https:$coverUrl";
          allAnimeNameAndCoverUrl.add(Anime(
              animeName: animeName ?? "", // 没有名字时返回空串
              animeEpisodeCnt: 0,
              animeCoverUrl: coverUrl));
          debugPrint("爬取封面：$coverUrl");
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return allAnimeNameAndCoverUrl;
  }
}
