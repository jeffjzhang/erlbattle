# erlbattle

erlbattle, 恶狼战役, 简称EB, 早期在googlecode上发展起来的开源项目, 是基于Erlang语言的实时技术学习平台

![image](https://raw.githubusercontent.com/jeffjzhang/erlbattle/master/doc/image/replay-pic-s.png)


## 代码目录使用说明
```
/ (https://github.com/jeffjzhang/erlbattle/)
├─doc             文档目录
├─core             核心组件
│  ├─engine         引擎目录|
├─army             战队代码目录; 除了erlang源代码和Makefile之外，不要放入其他任何文件
│  ├─evan.tao     以下是各人AI目录，如果你要新建中AI，建一个目录，写一个Makefile
│  ├─example_army
│  ├─hwh
│  ├─laofan
│  ├─maddog
│  └─neoedmund
├─ebin            beam输出目录
├─priv            erlang配置文件以及，一些命令行脚本
└─_fla            flash演示工具
```

## 安装和运行

1. 安装erl, 需要: erl-otp_R11B-5 以上， 下载地址[http://www.erlang.org/download.html]
2. 在/erlbattle 目录下， 进入Erlang shell
3. 编译代码: make:all([load]).
4. 启动游戏: erlbattle:start().
5. 系统就启动了. 并且在你反应过来之前就结束了。
6. 这是你观看的第一场战斗，发生在feardFarmers【恐惧的农民】 和englandArmy【英格兰卫兵】 之间的战斗。
7. 把输出的 warfield.txt用第一步下载的播放器播放这个战斗
8. 尝试运行 erlbattle:start(englandArmy,englandArmy) 让两个【英格兰卫兵】比赛
9. 把输出的 warfield.txt用第一步下载的播放器播放这个战斗


## 更多

[恶狼战役, 让智慧在战争中绽放!!!](https://github.com/jeffjzhang/erlbattle/wiki)

[系统设计](https://github.com/jeffjzhang/erlbattle/wiki/%E7%B3%BB%E7%BB%9F%E8%AE%BE%E8%AE%A1)

[接口说明](https://github.com/jeffjzhang/erlbattle/wiki/%E6%8E%A5%E5%8F%A3%E8%AF%B4%E6%98%8E)

[战场节拍和时序控制](https://github.com/jeffjzhang/erlbattle/wiki/EB%E6%88%98%E5%9C%BA%E8%8A%82%E6%8B%8D%E5%92%8C%E6%97%B6%E5%BA%8F%E6%8E%A7%E5%88%B6)

[战术动作研究](https://github.com/jeffjzhang/erlbattle/wiki/EB%E6%88%98%E6%9C%AF%E5%8A%A8%E4%BD%9C%E7%A0%94%E7%A9%B6)

[回放器](https://github.com/jeffjzhang/erlbattle/wiki/%E5%9B%9E%E6%94%BE%E5%99%A8)
