-- encoding: utf-8
--- charset filter
local charset = {
   ["[基本]"] = { first = 0x4e00, last = 0x9fff },
   ["[擴A]"] = { first = 0x3400, last = 0x4dbf },
   ["[擴B]"] = { first = 0x20000, last = 0x2a6df },
   ["[擴C]"] = { first = 0x2a700, last = 0x2b73f },
   ["[擴D]"] = { first = 0x2b740, last = 0x2b81f },
   ["[擴E]"] = { first = 0x2b820, last = 0x2ceaf },
   ["[擴F]"] = { first = 0x2ceb0, last = 0x2ebef },
   ["[擴G]"] = { first = 0x30000, last = 0x3134f },
   ["[擴H]"] = { first = 0x31350, last = 0x323af },
   ["[擴I]"] = { first = 0x2ebf0, last = 0x2ee5f },
   ["[擴J]"] = { first = 0x323B0, last = 0x3347f },
   ["[筆畫]"] = { first = 0x31c0, last = 0x31ef },
   ["[部首補充]"] = { first = 0x2e80, last = 0x2eff },
   ["[康熙部首]"] = { first = 0x2f00, last = 0x2fdf },
   ["[兼容]"] = { first = 0xf900, last = 0xfadf },
   ["[兼補]"] = { first = 0x2f800, last = 0x2fa1f },
   ["[漢字結構]"] = { first = 0x2ff0, last = 0x2fff },
   ["[注音]"] = { first = 0x3100, last = 0x312f },
   ["[注音擴展]"] = { first = 0x31a0, last = 0x31bf },
---漢字部分↑
   ["[拉丁文]"] = { first = 0x0000, last = 0x007f },
   ["[拉丁文補充]"] = { first = 0x0080, last = 0x00ff },
   ["[拉丁語擴展-A]"] = { first = 0x0100, last = 0x017f },
   ["[拉丁語擴展-B]"] = { first = 0x0180, last = 0x024f },
   ["[國際音標擴展]"] = { first = 0x0250, last = 0x02af },
   ["[間距修飾符]"] = { first = 0x02b0, last = 0x02ff },
   ["[組合變音標記]"] = { first = 0x0300, last = 0x036f },
   ["[希臘文]"] = { first = 0x0370, last = 0x03ff },
   ["[西里爾文]"] = { first = 0x0400, last = 0x04ff },
   ["[西里爾文增補]"] = { first = 0x0500, last = 0x052f },
   ["[亞美尼亞語]"] = { first = 0x0530, last = 0x058f },
   ["[希伯來文]"] = { first = 0x0590, last = 0x05ff },
   ["[阿拉伯語]"] = { first = 0x0600, last = 0x06ff },
   ["[敘利亞文]"] = { first = 0x0700, last = 0x074f },
   ["[阿拉伯語增補]"] = { first = 0x0750, last = 0x077f },
   ["[它拿字母]"] = { first = 0x0780, last = 0x07bf },
   ["[西非書面文字]"] = { first = 0x07c0, last = 0x07ff },
   ["[撒瑪利亞字母]"] = { first = 0x0800, last = 0x083f },
   ["[曼達文]"] = { first = 0x0840, last = 0x085f },
   ["[敘利亞文增補]"] = { first = 0x0860, last = 0x086f },
   ["[阿拉伯語擴展‐B]"] = { first = 0x0870, last = 0x089f },
   ["[阿拉伯語擴展-A]"] = { first = 0x08a0, last = 0x08ff },
   ["[梵文]"] = { first = 0x0900, last = 0x097f },
   ["[孟加拉語]"] = { first = 0x0980, last = 0x09ff },
   ["[古木基文]"] = { first = 0x0a00, last = 0x0a7f },
   ["[古吉拉特文]"] = { first = 0x0a80, last = 0x0aff },
   ["[奧里亞語]"] = { first = 0x0b00, last = 0x0b7f },
   ["[泰米爾語]"] = { first = 0x0b80, last = 0x0bff },
   ["[泰盧固語]"] = { first = 0x0c00, last = 0x0c7f },
   ["[卡納達語]"] = { first = 0x0c80, last = 0x0cff },
   ["[馬拉雅拉姆語]"] = { first = 0x0d00, last = 0x0d7f },
   ["[僧伽羅語]"] = { first = 0x0d80, last = 0x0dff },
   ["[泰語]"] = { first = 0x0e00, last = 0x0e7f },
   ["[老撾語]"] = { first = 0x0e80, last = 0x0eff },
   ["[藏文]"] = { first = 0x0f00, last = 0x0fff },
   ["[緬甸語]"] = { first = 0x1000, last = 0x109f },
   ["[格魯吉亞語]"] = { first = 0x10a0, last = 0x10ff },
   ["[韓文字母]"] = { first = 0x1100, last = 0x11ff },
   ["[阿姆哈拉語]"] = { first = 0x1200, last = 0x137f },
   ["[阿姆哈拉語增補]"] = { first = 0x1380, last = 0x139f },
   ["[切羅基語]"] = { first = 0x13a0, last = 0x13ff },
   ["[統一加拿大原住民音節]"] = { first = 0x1400, last = 0x167f },
   ["[歐甘字母]"] = { first = 0x1680, last = 0x169f },
   ["[盧恩字母]"] = { first = 0x16a0, last = 0x16ff },
   ["[他加祿語]"] = { first = 0x1700, last = 0x171f },
   ["[哈努諾文]"] = { first = 0x1720, last = 0x173f },
   ["[布希德文]"] = { first = 0x1740, last = 0x175f },
   ["[塔格巴努亞文]"] = { first = 0x1760, last = 0x177f },
   ["[高棉語]"] = { first = 0x1780, last = 0x17ff },
   ["[蒙古語]"] = { first = 0x1800, last = 0x18af },
   ["[統一加拿大原住民音節擴展]"] = { first = 0x18b0, last = 0x18ff },
   ["[林布語]"] = { first = 0x1900, last = 0x194f },
   ["[德宏傣文]"] = { first = 0x1950, last = 0x197f },
   ["[傣仂語]"] = { first = 0x1980, last = 0x19df },
   ["[高棉符號]"] = { first = 0x19e0, last = 0x19ff },
   ["[布吉語]"] = { first = 0x1a00, last = 0x1a1f },
   ["[老傣文]"] = { first = 0x1a20, last = 0x1aaf },
   ["[結合變音符號擴展]"] = { first = 0x1ab0, last = 0x1aff },
   ["[巴釐語]"] = { first = 0x1b00, last = 0x1b7f },
   ["[巽他語]"] = { first = 0x1b80, last = 0x1bbf },
   ["[巴塔克語]"] = { first = 0x1bc0, last = 0x1bff },
   ["[絨巴文]"] = { first = 0x1c00, last = 0x1c4f },
   ["[桑塔利語字母]"] = { first = 0x1c50, last = 0x1c7f },
   ["[西里爾文擴展-C]"] = { first = 0x1c80, last = 0x1c8f },
   ["[格魯吉亞文擴展]"] = { first = 0x1c90, last = 0x1cbf },
   ["[巽他文增補]"] = { first = 0x1cc0, last = 0x1ccf },
   ["[吠陀擴展]"] = { first = 0x1cd0, last = 0x1cff },
   ["[國際音標擴展]"] = { first = 0x1d00, last = 0x1d7f },
   ["[國際音標增補]"] = { first = 0x1d80, last = 0x1dbf },
   ["[結合變音標記增補]"] = { first = 0x1dc0, last = 0x1dff },
   ["[拉丁語擴展附加]"] = { first = 0x1e00, last = 0x1eff },
   ["[希臘語擴展]"] = { first = 0x1f00, last = 0x1fff },
   ["[常用標點]"] = { first = 0x2000, last = 0x206f },
   ["[上標和下標]"] = { first = 0x2070, last = 0x209f },
   ["[貨幣符號]"] = { first = 0x20a0, last = 0x20cf },
   ["[組合符號變音符號]"] = { first = 0x20d0, last = 0x20ff },
   ["[類字母符號]"] = { first = 0x2100, last = 0x214f },
   ["[數字]"] = { first = 0x2150, last = 0x218f },
   ["[箭頭]"] = { first = 0x2190, last = 0x21ff },
   ["[數運]"] = { first = 0x2200, last = 0x22ff },
   ["[雜項技術符號]"] = { first = 0x2300, last = 0x23ff },
   ["[控制圖片]"] = { first = 0x2400, last = 0x243f },
   ["[光學字符識別]"] = { first = 0x2440, last = 0x245f },
   ["[帶圈數字]"] = { first = 0x2460, last = 0x24ff },
   ["[製表符]"] = { first = 0x2500, last = 0x257f },
   ["[方塊元素]"] = { first = 0x2580, last = 0x259f },
   ["[幾何]"] = { first = 0x25a0, last = 0x25ff },
   ["[雜項]"] = { first = 0x2600, last = 0x26ff },
   ["[裝飾]"] = { first = 0x2700, last = 0x27bf },
   ["[雜項數學符號-A]"] = { first = 0x27c0, last = 0x27ef },
   ["[補充箭頭-A]"] = { first = 0x27f0, last = 0x27ff },
   ["[盲文]"] = { first = 0x2800, last = 0x28ff },
   ["[補充箭頭-B]"] = { first = 0x2900, last = 0x297f },
   ["[雜項數學符號-B]"] = { first = 0x2980, last = 0x29ff },
   ["[數學運算補充]"] = { first = 0x2a00, last = 0x2aff },
   ["[其他符號和箭頭]"] = { first = 0x2b00, last = 0x2bff },
   ["[格拉哥里字母]"] = { first = 0x2c00, last = 0x2c5f },
   ["[拉丁語擴展-C]"] = { first = 0x2c60, last = 0x2c7f },
   ["[科普特文]"] = { first = 0x2c80, last = 0x2cff },
   ["[格魯吉亞文增補]"] = { first = 0x2d00, last = 0x2d2f },
   ["[提非納字母]"] = { first = 0x2d30, last = 0x2d7f },
   ["[阿姆哈拉語擴展]"] = { first = 0x2d80, last = 0x2ddf },
   ["[西里爾文擴展-A]"] = { first = 0x2de0, last = 0x2dff },
   ["[補充標點符號]"] = { first = 0x2e00, last = 0x2e7f },
   ["[中日韓符號和標點]"] = { first = 0x3000, last = 0x303f },
   ["[平假名]"] = { first = 0x3040, last = 0x309f },
   ["[片假名]"] = { first = 0x30a0, last = 0x30ff },
   ["[韓文兼容字母]"] = { first = 0x3130, last = 0x318f },
   ["[漢文訓讀]"] = { first = 0x3190, last = 0x319f },
   ["[假名擴展]"] = { first = 0x31f0, last = 0x31ff },
   ["[中日韓弧圈字符]"] = { first = 0x3200, last = 0x32ff },
   ["[兼容單位]"] = { first = 0x3300, last = 0x33ff },
   ["[易經六十四卦符號]"] = { first = 0x4dc0, last = 0x4dff },
   ["[彝族音節]"] = { first = 0xa000, last = 0xa48f },
   ["[彝族部首]"] = { first = 0xa490, last = 0xa4cf },
   ["[傈僳語]"] = { first = 0xa4d0, last = 0xa4ff },
   ["[瓦伊語]"] = { first = 0xa500, last = 0xa63f },
   ["[西里爾文擴展-B]"] = { first = 0xa640, last = 0xa69f },
   ["[巴姆穆語]"] = { first = 0xa6a0, last = 0xa6ff },
   ["[聲調修飾符]"] = { first = 0xa700, last = 0xa71f },
   ["[拉丁語擴展-D]"] = { first = 0xa720, last = 0xa7ff },
   ["[錫爾赫特文]"] = { first = 0xa800, last = 0xa82f },
   ["[常用印度數字形式]"] = { first = 0xa830, last = 0xa83f },
   ["[八思巴字]"] = { first = 0xa840, last = 0xa87f },
   ["[索拉什特拉語]"] = { first = 0xa880, last = 0xa8df },
   ["[天城文擴展]"] = { first = 0xa8e0, last = 0xa8ff },
   ["[克耶字母]"] = { first = 0xa900, last = 0xa92f },
   ["[拉讓語]"] = { first = 0xa930, last = 0xa95f },
   ["[韓文字母擴展-A]"] = { first = 0xa960, last = 0xa97f },
   ["[爪哇語]"] = { first = 0xa980, last = 0xa9df },
   ["[緬甸語擴展-B]"] = { first = 0xa9e0, last = 0xa9ff },
   ["[佔語]"] = { first = 0xaa00, last = 0xaa5f },
   ["[緬甸語擴展-A]"] = { first = 0xaa60, last = 0xaa7f },
   ["[傣文]"] = { first = 0xaa80, last = 0xaadf },
   ["[曼尼普爾語擴展]"] = { first = 0xaae0, last = 0xaaff },
   ["[阿姆哈拉語擴展-A]"] = { first = 0xab00, last = 0xab2f },
   ["[拉丁文擴展-E]"] = { first = 0xab30, last = 0xab6f },
   ["[切羅基語增補]"] = { first = 0xab70, last = 0xabbf },
   ["[曼尼普爾語]"] = { first = 0xabc0, last = 0xabff },
   ["[韓文音節]"] = { first = 0xac00, last = 0xd7af },   
   ["[韓文字母擴展-B]"] = { first = 0xd7b0, last = 0xd7ff },
   ["[高位替代區]"] = { first = 0xd800, last = 0xdb7f },
   ["[高位專用替代]"] = { first = 0xdb80, last = 0xdbff },
   ["[低位替代區]"] = { first = 0xdc00, last = 0xdfff }, 
   ["[私用區]"] = { first = 0xe000, last = 0xf8ff },
   ["[字母連寫形式]"] = { first = 0xfb00, last = 0xfb4f },
   ["[阿拉伯語表現形式-A]"] = { first = 0xfb50, last = 0xfdff },
   ["[變體選擇器]"] = { first = 0xfe00, last = 0xfe0f },
   ["[豎排形式]"] = { first = 0xfe10, last = 0xfe1f },
   ["[組合用半符號]"] = { first = 0xfe20, last = 0xfe2f },
   ["[中日韓兼容形式]"] = { first = 0xfe30, last = 0xfe4f },
   ["[小型變體形式]"] = { first = 0xfe50, last = 0xfe6f },
   ["[阿拉伯語表現形式-B]"] = { first = 0xfe70, last = 0xfeff },
   ["[字符]"] = { first = 0xff00, last = 0xffef },
   ["[特殊字符]"] = { first = 0xfff0, last = 0xffff },
   ["[線形文字B音節]"] = { first = 0x10000, last = 0x1007f },
   ["[線形文字B表意文字]"] = { first = 0x10080, last = 0x100ff },
   ["[愛琴海數字]"] = { first = 0x10100, last = 0x1013f },
   ["[古希臘數字]"] = { first = 0x10140, last = 0x1018f },
   ["[古羅馬符號]"] = { first = 0x10190, last = 0x101cf },
   ["[斐斯托斯圓盤古文字]"] = { first = 0x101d0, last = 0x101ff },
   ["[呂基亞語]"] = { first = 0x10280, last = 0x1029f },
   ["[卡里亞字母]"] = { first = 0x102a0, last = 0x102df },
   ["[科普特閏餘數字]"] = { first = 0x102e0, last = 0x102ff },
   ["[古意大利字母]"] = { first = 0x10300, last = 0x1032f },
   ["[哥特字母]"] = { first = 0x10330, last = 0x1034f },
   ["[古彼爾姆文]"] = { first = 0x10350, last = 0x1037f },
   ["[烏加里特語]"] = { first = 0x10380, last = 0x1039f },
   ["[古波斯語]"] = { first = 0x103a0, last = 0x103df },
   ["[德瑟雷特字母]"] = { first = 0x10400, last = 0x1044f },
   ["[蕭伯納字母]"] = { first = 0x10450, last = 0x1047f },
   ["[奧斯曼亞字母]"] = { first = 0x10480, last = 0x104af },
   ["[歐塞奇字母]"] = { first = 0x104b0, last = 0x104ff },
   ["[愛爾巴桑字母]"] = { first = 0x10500, last = 0x1052f },   
   ["[高加索阿爾巴尼亞語言]"] = { first = 0x10530, last = 0x1056f },
   ["[維斯庫奇語]"] = { first = 0x10570, last = 0x105bf },
   ["[線性文字A]"] = { first = 0x10600, last = 0x1077f },
   ["[拉丁語擴展-F]"] = { first = 0x10780, last = 0x107bf },
   ["[塞浦路斯語音節]"] = { first = 0x10800, last = 0x1083f },
   ["[帝國阿拉姆語]"] = { first = 0x10840, last = 0x1085f },
   ["[巴爾米拉字母]"] = { first = 0x10860, last = 0x1087f },
   ["[納巴泰字母]"] = { first = 0x10880, last = 0x108af },
   ["[哈特蘭字母]"] = { first = 0x108e0, last = 0x108ff },
   ["[腓尼基字母]"] = { first = 0x10900, last = 0x1091f },   
   ["[呂底亞語]"] = { first = 0x10920, last = 0x1093f },
   ["[麥羅埃象形文字]"] = { first = 0x10980, last = 0x1099f },
   ["[麥羅埃文草體字]"] = { first = 0x109a0, last = 0x109ff },
   ["[佉盧文]"] = { first = 0x10a00, last = 0x10a5f },
   ["[古南部阿拉伯語]"] = { first = 0x10a60, last = 0x10a7f },
   ["[古北部阿拉伯語]"] = { first = 0x10a80, last = 0x10a9f },
   ["[摩尼字母]"] = { first = 0x10ac0, last = 0x10aff }, 
   ["[阿維斯陀字母]"] = { first = 0x10b00, last = 0x10b3f },
   ["[碑刻帕提亞文]"] = { first = 0x10b40, last = 0x10b5f },
   ["[碑刻巴列維文]"] = { first = 0x10b60, last = 0x10b7f },
   ["[詩篇巴列維文]"] = { first = 0x10b80, last = 0x10baf },
   ["[古代突厥語]"] = { first = 0x10c00, last = 0x10c4f },
   ["[古匈牙利字母]"] = { first = 0x10c80, last = 0x10cff },
   ["[哈乃斐羅興亞文字]"] = { first = 0x10d00, last = 0x10d3f },
   ["[魯米數字符號]"] = { first = 0x10e60, last = 0x10e7f },   
   ["[雅慈迪文字]"] = { first = 0x10e80, last = 0x10ebf },
   ["[古粟特字母]"] = { first = 0x10f00, last = 0x10f2f },
   ["[粟特字母]"] = { first = 0x10f30, last = 0x10f6f },
   ["[舊維吾爾語]"] = { first = 0x10f70, last = 0x10faf },
   ["[花剌子模文字]"] = { first = 0x10fb0, last = 0x10fdf },
   ["[以利買字母]"] = { first = 0x10fe0, last = 0x10fff },
   ["[婆羅米文]"] = { first = 0x11000, last = 0x1107f },
   ["[凱提文]"] = { first = 0x11080, last = 0x110cf },
   ["[索拉僧平文字]"] = { first = 0x110d0, last = 0x110ff },
   ["[查克馬語]"] = { first = 0x11100, last = 0x1114f },
   ["[馬哈雅尼文]"] = { first = 0x11150, last = 0x1117f },
   ["[夏拉達文]"] = { first = 0x11180, last = 0x111df },
   ["[古僧伽羅文數字]"] = { first = 0x111e0, last = 0x111ff },
   ["[和卓文]"] = { first = 0x11200, last = 0x1124f },
   ["[木爾坦文]"] = { first = 0x11280, last = 0x112af },
   ["[庫達瓦迪文]"] = { first = 0x112b0, last = 0x112ff },
   ["[古蘭塔文]"] = { first = 0x11300, last = 0x1137f },
   ["[尼瓦爾語]"] = { first = 0x11400, last = 0x1147f },
   ["[提爾胡塔文]"] = { first = 0x11480, last = 0x114df },
   ["[悉曇文字]"] = { first = 0x11580, last = 0x115ff },
   ["[莫迪文]"] = { first = 0x11600, last = 0x1165f },
   ["[蒙古語增補]"] = { first = 0x11660, last = 0x1167f },
   ["[塔克裏文]"] = { first = 0x11680, last = 0x116cf },
   ["[阿洪姆語]"] = { first = 0x11700, last = 0x1174f },
   ["[多格拉語]"] = { first = 0x11800, last = 0x1184f },
   ["[瓦蘭齊地文]"] = { first = 0x118a0, last = 0x118ff },
   ["[迪維希文字]"] = { first = 0x11900, last = 0x1195f },
   ["[南迪城文]"] = { first = 0x119a0, last = 0x119ff },
   ["[札那巴札爾方形字母]"] = { first = 0x11a00, last = 0x11a4f },
   ["[索永布字母]"] = { first = 0x11a50, last = 0x11aaf },
   ["[加拿大統一原住民音節擴展‐A]"] = { first = 0x11ab0, last = 0x11abf },
   ["[包欽豪文]"] = { first = 0x11ac0, last = 0x11aff },
   ["[拜克舒基文]"] = { first = 0x11c00, last = 0x11c6f },
   ["[瑪欽文]"] = { first = 0x11c70, last = 0x11cbf },
   ["[馬薩拉姆貢德文字]"] = { first = 0x11d00, last = 0x11d5f },
   ["[貢賈拉貢德文]"] = { first = 0x11d60, last = 0x11daf },
   ["[望加錫文]"] = { first = 0x11ee0, last = 0x11eff },
   ["[傈僳文字補充]"] = { first = 0x11fb0, last = 0x11fbf },
   ["[泰米爾文增補]"] = { first = 0x11fc0, last = 0x11fff },
   ["[楔形文字]"] = { first = 0x12000, last = 0x123ff },
   ["[楔形文字數字和標點符號]"] = { first = 0x12400, last = 0x1247f },
   ["[古代楔形文字]"] = { first = 0x12480, last = 0x1254f },
   ["[賽伯樂-米諾語]"] = { first = 0x12f90, last = 0x12fff },
   ["[埃及聖書體]"] = { first = 0x13000, last = 0x1342f },
   ["[埃及聖書體格式控制]"] = { first = 0x13430, last = 0x1343f },
   ["[安納托利亞象形文字]"] = { first = 0x14400, last = 0x1467f },
   ["[巴姆穆文字增補]"] = { first = 0x16800, last = 0x16a3f },
   ["[默祿文]"] = { first = 0x16a40, last = 0x16a6f },
   ["[唐山語]"] = { first = 0x16a70, last = 0x16acf },
   ["[巴薩哇文字]"] = { first = 0x16ad0, last = 0x16aff },
   ["[帕哈苗文]"] = { first = 0x16b00, last = 0x16b8f },
   ["[梅德法伊德林文]"] = { first = 0x16e40, last = 0x16e9f },
   ["[柏格理苗文]"] = { first = 0x16f00, last = 0x16f9f },
   ["[表意符號和標點符號]"] = { first = 0x16fe0, last = 0x16fff },
   ["[西夏文]"] = { first = 0x17000, last = 0x187ff },
   ["[西夏文部首]"] = { first = 0x18800, last = 0x18aff },
   ["[契丹小字]"] = { first = 0x18b00, last = 0x18cff },
   ["[西夏文字補充]"] = { first = 0x18d00, last = 0x18d8f },
   ["[加納文擴展-B]"] = { first = 0x1aff0, last = 0x1afff },
   ["[假名補充]"] = { first = 0x1b000, last = 0x1b0ff },
   ["[假名擴展A]"] = { first = 0x1b100, last = 0x1b12f },
   ["[小型日文假名擴展]"] = { first = 0x1b130, last = 0x1b16f },
   ["[女書]"] = { first = 0x1b170, last = 0x1b2ff },
   ["[杜普雷速記]"] = { first = 0x1bc00, last = 0x1bc9f },
   ["[速記格式控制符]"] = { first = 0x1bca0, last = 0x1bcaf },
   ["[Znamenny音樂記譜法]"] = { first = 0x1cf00, last = 0x1cfcf },
   ["[拜占庭音樂符號]"] = { first = 0x1d000, last = 0x1d0ff },
   ["[音樂符號]"] = { first = 0x1d100, last = 0x1d1ff },
   ["[古希臘音樂記號]"] = { first = 0x1d200, last = 0x1d24f },
   ["[瑪雅數字]"] = { first = 0x1d2e0, last = 0x1d2ff },
   ["[太玄經符號]"] = { first = 0x1d300, last = 0x1d35f },
   ["[算籌]"] = { first = 0x1d360, last = 0x1d37f },
   ["[字母和數字符號]"] = { first = 0x1d400, last = 0x1d7ff },
   ["[薩頓書寫符號]"] = { first = 0x1d800, last = 0x1daaf },
   ["[拉丁語擴展-G]"] = { first = 0x1df00, last = 0x1dfff },
   ["[格拉哥里字母增補]"] = { first = 0x1e000, last = 0x1e02f },
   ["[尼亞坑普阿綽苗文]"] = { first = 0x1e100, last = 0x1e14f },
   ["[Toto]"] = { first = 0x1e290, last = 0x1e2bf },
   ["[文喬字母]"] = { first = 0x1e2c0, last = 0x1e2ff },
   ["[埃塞俄比亞語擴展-B]"] = { first = 0x1e7e0, last = 0x1e7ff },
   ["[門德基卡庫文]"] = { first = 0x1e800, last = 0x1e8df },
   ["[阿德拉姆字母]"] = { first = 0x1e900, last = 0x1e95f },
   ["[印度西亞格數字]"] = { first = 0x1ec70, last = 0x1ecbf },
   ["[奧斯曼西亞克數字]"] = { first = 0x1ed00, last = 0x1ed4f },
   ["[阿拉伯字母數字符號]"] = { first = 0x1ee00, last = 0x1eeff },
   ["[麻將牌]"] = { first = 0x1f000, last = 0x1f02f },
   ["[多米諾骨牌]"] = { first = 0x1f030, last = 0x1f09f },
   ["[撲克牌]"] = { first = 0x1f0a0, last = 0x1f0ff },
   ["[帶圈字母補充]"] = { first = 0x1f100, last = 0x1f1ff },
   ["[方框字補充]"] = { first = 0x1f200, last = 0x1f2ff },
   ["[雜符]"] = { first = 0x1f300, last = 0x1f5ff },
   ["[表情]"] = { first = 0x1f600, last = 0x1f64f },
   ["[裝飾符號]"] = { first = 0x1f650, last = 0x1f67f },
   ["[交通和地圖符號]"] = { first = 0x1f680, last = 0x1f6ff },
   ["[鍊金術符號]"] = { first = 0x1f700, last = 0x1f77f },
   ["[幾何擴]"] = { first = 0x1f780, last = 0x1f7ff },
   ["[追加箭頭-C]"] = { first = 0x1f800, last = 0x1f8ff },
   ["[符號補]"] = { first = 0x1f900, last = 0x1f9ff },
   ["[象棋]"] = { first = 0x1fa00, last = 0x1fa6f },
   ["[符號和象形文字擴展-A]"] = { first = 0x1fa70, last = 0x1faff },
   ["[傳統計算機符號]"] = { first = 0x1fb00, last = 0x1fbff },
   ["[標籤]"] = { first = 0xe0000, last = 0xe007f },
   ["[變化選擇器補充]"] = { first = 0xe0100, last = 0xe01ef },
   ["[私用區補充A]"] = { first = 0xf0000, last = 0xffff },
   ["[私用區補充B]"] = { first = 0x100000, last = 0x10ffff },
   ["[Compat]"] = { first = 0x2F8000, last = 0x2FA1FF } }

local function exists(single_filter, text)
  for i in utf8.codes(text) do
     local c = utf8.codepoint(text, i)
     if (not single_filter(c)) then
	return false
     end
  end
  return true
end

local function is_charset(s)
   return function (c)
      return c >= charset[s].first and c <= charset[s].last
   end
end

local function is_cjk_ext(c)
   return is_charset("中日韓統一漢字擴展A")(c) or is_charset("中日韓統一漢字擴展B")(c) or
      is_charset("中日韓統一漢字擴展C")(c) or is_charset("中日韓統一漢字擴展D")(c) or
      is_charset("中日韓統一漢字擴展E")(c) or is_charset("中日韓統一漢字擴展F")(c) or
      is_charset("中日韓統一漢字擴展G")(c) or is_charset("中日韓統一漢字")(c) or
      is_charset("中日韓漢字部首補充")(c) or is_charset("康熙部首")(c) or
      is_charset("中日韓兼容漢字")(c) or is_charset("中日韓兼容漢字補充")(c) or
      is_charset("中日韓漢字筆畫")(c) or is_charset("結構")(c) or
      is_charset("注音符號")(c) or is_charset("注音擴展")(c) or
      is_charset("基本拉丁文字")(c) or is_charset("拉丁文字西歐語言補充")(c) or
      is_charset("拉丁文字擴展A")(c) or is_charset("拉丁文字擴展B")(c) or
      is_charset("國際音標擴展")(c) or is_charset("佔位修飾符")(c) or
      is_charset("組合附加記號")(c) or is_charset("希臘文字和科普特文字")(c) or
      is_charset("西里爾文")(c) or is_charset("西里爾文補充")(c) or
      is_charset("亞美尼亞文")(c) or is_charset("希伯萊文")(c) or
      is_charset("阿拉伯文")(c) or is_charset("敘利亞文")(c) or
      is_charset("阿拉伯文補充")(c) or is_charset("它拿文")(c) or
      is_charset("西非書面文字")(c) or is_charset("撒馬利亞文字")(c) or
      is_charset("曼達安文字")(c) or is_charset("敘利亞文補充")(c) or
      is_charset("阿拉伯文補充")(c) or is_charset("天城文")(c) or
      is_charset("孟加拉文")(c) or is_charset("古木基文")(c) or
      is_charset("古吉拉特文")(c) or is_charset("奧里亞文")(c) or
      is_charset("泰米爾文")(c) or is_charset("泰盧固文")(c) or
      is_charset("卡納達文")(c) or is_charset("馬拉雅拉姆文")(c) or
      is_charset("僧伽羅文")(c) or is_charset("泰文")(c) or
      is_charset("老撾文")(c) or is_charset("藏文")(c) or
      is_charset("緬甸文")(c) or is_charset("格魯吉亞文")(c) or
      is_charset("諺文字母")(c) or is_charset("埃塞俄比亞文")(c) or
      is_charset("埃塞俄比亞文補充")(c) or is_charset("切羅基文")(c) or
      is_charset("統一加拿大原住民音節文字")(c) or is_charset("歐甘文字")(c) or
      is_charset("盧恩文字")(c) or is_charset("他加祿文")(c) or
      is_charset("哈努諾文")(c) or is_charset("布希德文")(c) or
      is_charset("塔格巴努瓦文")(c) or is_charset("高綿文")(c) or
      is_charset("蒙古文")(c) or is_charset("統一加拿大原住民音節文字擴展")(c) or
      is_charset("林布文")(c) or is_charset("德宏傣文")(c) or
      is_charset("西雙版納新傣文")(c) or is_charset("高綿文符號")(c) or
      is_charset("布吉文字")(c) or is_charset("西雙版納老傣文")(c) or
      is_charset("組合附加記號擴展")(c) or is_charset("巴釐文字")(c) or
      is_charset("巽他文字")(c) or is_charset("巴塔克文")(c) or
      is_charset("雷布查文")(c) or is_charset("桑塔利文")(c) or
      is_charset("西里爾文擴展C")(c) or is_charset("格魯吉亞文")(c) or
      is_charset("巽他文字補充")(c) or is_charset("吠陀文字補充")(c) or
      is_charset("音標擴展")(c) or is_charset("音標擴展補充")(c) or
      is_charset("組合附加記號補充")(c) or is_charset("拉丁文附加擴展")(c) or
      is_charset("希臘文擴展")(c) or is_charset("通用標點符號")(c) or
      is_charset("上標和下標")(c) or is_charset("貨幣符號")(c) or
      is_charset("符號用組合附加記號")(c) or is_charset("類字母符號")(c) or
      is_charset("數字形式")(c) or is_charset("緬箭頭")(c) or
      is_charset("數學運算符")(c) or is_charset("雜類技術符號")(c) or
      is_charset("控制符圖形")(c) or is_charset("光學字符訣別符號")(c) or
      is_charset("包圍式字母與數字符號")(c) or is_charset("製表符")(c) or
      is_charset("方塊元素")(c) or is_charset("幾何形狀")(c) or
      is_charset("雜類符號")(c) or is_charset("印刷符號")(c) or
      is_charset("雜類數學符號A")(c) or is_charset("補充箭頭A")(c) or
      is_charset("盲文點字")(c) or is_charset("補充箭頭B")(c) or
      is_charset("雜類數學符號B")(c) or is_charset("補充數學運算符")(c) or
      is_charset("雜類標誌與箭頭")(c) or is_charset("格拉哥里文字")(c) or
      is_charset("拉丁文字擴展C")(c) or is_charset("科普特文")(c) or
      is_charset("格魯吉亞文補充")(c) or is_charset("提非納文字")(c) or
      is_charset("埃塞俄比亞文擴展")(c) or is_charset("西里爾文擴展A")(c) or
      is_charset("補充標點符號")(c) or is_charset("表意文字描述字符")(c) or
      is_charset("中日韓符號和標點")(c) or is_charset("平假名")(c) or
      is_charset("片假名")(c) or is_charset("諺文兼容字母")(c) or
      is_charset("漢文記號")(c) or is_charset("注音符號擴展")(c) or
      is_charset("片假名音標擴展")(c) or is_charset("包圍式中日韓字符與月份")(c) or
      is_charset("中日韓兼容全角字符")(c) or is_charset("易經六十四卦符號")(c) or
      is_charset("彝文")(c) or is_charset("彝文部首")(c) or
      is_charset("老傈僳文")(c) or is_charset("卡瓦伊文")(c) or
      is_charset("西里爾文擴展B")(c) or is_charset("巴姆穆文")(c) or
      is_charset("聲調修飾符號")(c) or is_charset("拉丁文字擴展D")(c) or
      is_charset("錫爾赫特城文字")(c) or is_charset("通用印度數學")(c) or
      is_charset("八思巴文")(c) or is_charset("索拉什特拉文字")(c) or
      is_charset("天城文擴展")(c) or is_charset("克耶裏文")(c) or
      is_charset("勒姜文")(c) or is_charset("諺文字母擴展A")(c) or
      is_charset("爪哇文")(c) or is_charset("緬甸文擴展B")(c) or
      is_charset("佔文")(c) or is_charset("緬甸文擴展A")(c) or
      is_charset("越南傣文")(c) or is_charset("曼尼普爾文擴展")(c) or
      is_charset("埃塞俄比亞文擴展A")(c) or is_charset("拉丁文字擴展E")(c) or
      is_charset("切羅基文字補充")(c) or is_charset("曼尼普爾文")(c) or
      is_charset("諺文")(c) or is_charset("諺文字母擴展B")(c) or
      is_charset("私用區")(c) or is_charset("字母變體")(c) or
      is_charset("阿拉伯文變體A")(c) or is_charset("異體選擇符")(c) or
      is_charset("豎排標點符號")(c) or is_charset("組合用半記號")(c) or
      is_charset("中日韓兼容標點符號")(c) or is_charset("小型標點符號")(c) or
      is_charset("阿拉伯文變體B")(c) or is_charset("半角與全角符號")(c) or
      is_charset("特殊字符")(c) or is_charset("線形文字B音節文字")(c) or
      is_charset("線形文字B表意文字")(c) or is_charset("愛琴數學")(c) or
      is_charset("古希臘數學")(c) or is_charset("古代符號")(c) or
      is_charset("費斯托斯圓盤符號")(c) or is_charset("呂基亞文")(c) or
      is_charset("卡利亞文")(c) or is_charset("科普特閏餘數字")(c) or
      is_charset("古意大利文")(c) or is_charset("哥特文")(c) or
      is_charset("古彼爾姆文")(c) or is_charset("烏加里特文")(c) or
      is_charset("古波斯楔形文")(c) or is_charset("德塞雷特文")(c) or
      is_charset("蕭伯納文")(c) or is_charset("奧斯曼亞文")(c) or
      is_charset("歐塞奇文")(c) or is_charset("愛爾巴桑文")(c) or
      is_charset("高加索愛爾巴尼亞文")(c) or is_charset("線形文字A")(c) or
      is_charset("塞浦路斯音節文字A")(c) or is_charset("皇家亞拉姆文字")(c) or
      is_charset("帕爾邁拉文字")(c) or is_charset("納巴泰文")(c) or
      is_charset("哈特拉文")(c) or is_charset("腓尼基文")(c) or
      is_charset("呂底亞文")(c) or is_charset("麥羅埃象形文字")(c) or
      is_charset("麥羅埃草書文字")(c) or is_charset("佉盧蝨吒文")(c) or
      is_charset("古南阿拉伯文")(c) or is_charset("古北阿拉伯文")(c) or
      is_charset("摩尼文")(c) or is_charset("阿維斯陀文")(c) or
      is_charset("帕提亞碑銘體文字")(c) or is_charset("巴列維碑銘體文字")(c) or
      is_charset("巴列維聖詩體文字")(c) or is_charset("古突厥文")(c) or
      is_charset("古匈牙利文")(c) or is_charset("哈乃斐羅興亞文")(c) or
      is_charset("魯米數學符號")(c) or is_charset("雅茲迪文")(c) or
      is_charset("古粟特文")(c) or is_charset("粟特文")(c) or
      is_charset("花剌子模文字")(c) or is_charset("婆羅米文字")(c) or
      is_charset("凱提文")(c) or is_charset("索拉僧平文")(c) or
      is_charset("查克馬文")(c) or is_charset("馬哈佳尼文")(c) or
      is_charset("夏拉達文")(c) or is_charset("僧伽羅古代數學")(c) or
      is_charset("克吉奇文")(c) or is_charset("穆爾塔尼文")(c) or
      is_charset("信德文")(c) or is_charset("格蘭塔文")(c) or
      is_charset("尼瓦文")(c) or is_charset("提爾胡塔文")(c) or
      is_charset("悉曇文")(c) or is_charset("莫迪文")(c) or
      is_charset("蒙古文補充")(c) or is_charset("泰克裏文")(c) or
      is_charset("阿洪姆文")(c) or is_charset("多格拉文")(c) or
      is_charset("瓦蘭齊地文")(c) or is_charset("迪維希文")(c) or
      is_charset("喜城文")(c) or is_charset("札那巴札爾方形文字")(c) or
      is_charset("索永布文")(c) or is_charset("包欽毫文")(c) or
      is_charset("拜克舒基文")(c) or is_charset("瑪欽文")(c) or
      is_charset("馬薩拉姆貢德文")(c) or is_charset("貢賈拉貢德文")(c) or
      is_charset("望加錫文")(c) or is_charset("傈僳文補充")(c) or
      is_charset("泰米爾文補充")(c) or is_charset("楔形文字補充")(c) or
      is_charset("楔形文字數字和標點符號")(c) or is_charset("早期王朝楔形文字")(c) or
      is_charset("埃及象形文字")(c) or is_charset("埃及象形文字格式控制符")(c) or
      is_charset("安納托利亞象形文字")(c) or is_charset("巴姆穆文補充")(c) or
      is_charset("木如文")(c) or is_charset("巴薩文")(c) or
      is_charset("楊松錄苗文")(c) or is_charset("梅德法伊德林文字")(c) or
      is_charset("柏格理苗文")(c) or is_charset("表意文字符號及標點")(c) or
      is_charset("西夏文")(c) or is_charset("西夏文部首")(c) or
      is_charset("契丹小字")(c) or is_charset("西夏文補充")(c) or
      is_charset("假名補充")(c) or is_charset("假名擴展A")(c) or
      is_charset("小寫假名擴展")(c) or is_charset("女書")(c) or
      is_charset("杜普雷速記文字")(c) or is_charset("速記格式控制符")(c) or
      is_charset("拜占庭樂譜符號")(c) or is_charset("樂譜符號")(c) or
      is_charset("古希臘樂譜記號")(c) or is_charset("瑪雅數字")(c) or
      is_charset("太玄經符號")(c) or is_charset("算籌數字")(c) or
      is_charset("數學字母數字符號")(c) or is_charset("薩頓手語符號")(c) or
      is_charset("格拉哥里文字補充")(c) or is_charset("花布苗文")(c) or
      is_charset("萬卻文字")(c) or is_charset("門德基卡庫文字")(c) or
      is_charset("阿德拉姆文字")(c) or is_charset("印度西亞克數字")(c) or
      is_charset("奧斯曼西亞克數字")(c) or is_charset("阿拉伯數學用字母符號")(c) or
      is_charset("麻將牌")(c) or is_charset("多米諾骨牌")(c) or
      is_charset("撲克牌")(c) or is_charset("包圍式字母數字補充")(c) or
      is_charset("包圍式表意文字補充")(c) or is_charset("雜類符號與圖形標記")(c) or
      is_charset("表情符號")(c) or is_charset("裝飾印刷符號")(c) or
      is_charset("交通與印刷符號")(c) or is_charset("鍊金術符號")(c) or
      is_charset("幾何形狀擴展")(c) or is_charset("補充箭頭C")(c) or
      is_charset("補充符號與圖形標記")(c) or is_charset("棋類符號")(c) or
      is_charset("符號及圖形標記擴展A")(c) or is_charset("傳統計算機符號")(c) or
      is_charset("標籤")(c) or is_charset("異體選擇符補充")(c) or
      is_charset("補充私用區A")(c) or is_charset("補充私用區B")(c) or
      is_charset("Compat")(c)
end

local function charset_filter(input)
   for cand in input:iter() do
      if (not exists(is_cjk_ext, cand.text))
      then
	 yield(cand)
      end
   end
end


--- charset comment filter
local function charset_comment_filter(input,env)
  local b = env.engine.context:get_option("unicode_comment")--開關狀態
  for cand in input:iter() do
    if b then
     for s, r in pairs(charset) do
       if (exists(is_charset(s), cand.text)) then
         cand:get_genuine().comment = cand.comment .. " " .. s
         break
       end--if
      end--for
     end--if
      yield(cand)
   end
end


return charset_comment_filter
