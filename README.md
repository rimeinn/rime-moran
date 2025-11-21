[English](README-en.md)

<h1 align="center">魔然 Rime 輸入方案</h1>

<p align="center">
<a href="https://github.com/rimeinn/rime-moran/issues"><img src="https://img.shields.io/badge/%E6%AD%A1%E8%BF%8E-%E5%8F%83%E8%88%87%E8%B2%A2%E7%8D%BB-1dd3b0?style=for-the-badge&logo=github"/></a>
<a href="https://zrmfans.cn/demo/"><img src="https://img.shields.io/badge/Fcitx5-線上試用-1dd3b0?style=for-the-badge&logo=github"/></a>
</p>

授權協議：方案主體依 [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) 協議發佈，除非對應文件中另有說明。

---

配方：℞ `rimeinn/rime-moran@trad` 傳承字版 ([線上試用](https://zrmfans.cn/demo/))

配方：℞ `rimeinn/rime-moran@simp` 簡化字版 ([線上試用](https://zrmfans.cn/zh-Hans/demo/))

本項目爲基於自然碼（雙拼和輔助碼）的傳承字優先的 Rime 方案，簡稱「魔然」。具有[多種模式](https://github.com/rimeinn/rime-moran/wiki/%E5%90%84%E8%BC%B8%E5%85%A5%E6%A8%A1%E5%BC%8F%E8%AA%AA%E6%98%8E)、[五重反查](https://github.com/rimeinn/rime-moran/wiki/%E6%95%99%E7%A8%8B#%E5%85%B6%E4%BA%94%E6%9B%B0%E4%BA%94%E9%87%8D%E5%8F%8D%E6%9F%A5)、八萬字、百萬詞庫和多種快捷輸入功能。詳情請參閱[本項目維基](https://github.com/rimeinn/rime-moran/wiki)。

> [!TIP]
> 如果您對其他音碼或其他輔助碼感興趣，可參閱 [魔龍（rime-molong）](https://github.com/rimeinn/rime-molong) 項目。

魔然是開放的、[社區維護](https://zrmfans.cn/book/misc/acknowledgement.html)的項目。歡迎參與！

- [瞭解更多](https://zrmfans.cn)

| 簡快碼                              | 整句輔助模式                             |
|-------------------------------------|------------------------------------------|
| ![簡快碼](./etc/screenshot-bql.png) | ![整句輔助碼](./etc/screenshot-poem.png) |

**輔助碼篩選模式**

https://github.com/user-attachments/assets/ca8a8c1f-d076-47de-94b0-4e935a99a516

# 方案維護

master 分支可使用如下命令進行日常維護：

```bash
make quick                           # 快速更新單字信息
make dict                            # 更新詞庫中的輔助碼
make dist                            # 產生純淨方案到 ./dist 目錄下
make dist DESTDIR=~/Library/Rime     # 將方案拷貝到 DESTDIR
make test                            # 執行單元測試
./make_simp_dist.sh                  # 產生簡體版方案到 ./dist 目錄下
```

注意：master 分支必須首先 `make quick` 後才能部署。
