## erlbattle

erlbattle, 恶狼战役, 简称EB, 早期在googlecode上发展起来的开源项目, 是基于Erlang语言的实时技术学习平台

![image](https://raw.githubusercontent.com/jeffjzhang/erlbattle/master/doc/image/replay-pic-s.png)

## 代码目录使用说明

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

