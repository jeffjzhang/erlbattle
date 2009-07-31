1 目录说明
root
├─doc             文档目录
│  ├─docpicture
│  ├─kongfu
│  └─logo
+--core
|  +-engine       引擎目录
|
├─army             源代码目录，除了erlang源代码和Makefile之外，不要放入其他任何文件
│  ├─evan.tao     以下是各人AI目录，如果你要新建中AI，建一个目录，写一个Makefile
│  ├─example_army
│  ├─hwh
│  ├─laofan
│  ├─maddog
│  └─neoedmund
├─ebin            beam输出目录
├─make            Makefile相关脚本
├─priv            erlang配置文件以及，一些命令行脚本
└─_fla            flash演示工具

2 编译
需要: erl-otpR12B-5， 下载地址[http://www.erlang.org/download.html]

2.1 Windows
需要: nmake, 下载地址[http://erlbattle.googlecode.com/files/nmake.exe]
执行下面两个命令
D:\erlbattle>configure
D:\erlbattle>nmake

2.2 Linux
需要gnumake
#./configure
#make 

3 运行
3.0 最快速启动
   erl -nologo -noshell -pz ebin -s erlbattle start
3.1 启动erl
>erl

3.2 加载ebin路径
.beam文件，也就是erlang代码所编译出来的字节码
ebin目录包含了所有这些beam文件
要运行这些文件首先erl需要在知道这些文件在那
可以在erl环境下使用
1>code:add_pathz("ebin").
加载我们的代码（.是erlang语句的结束符不能少.

在erl交互环境下输入code:getpath().可以看到当前系统所加载的代码目录.

3.3 启动erlbattle
2>erlbattle:start().
战斗结果或保存于warfield.txt

3.4 观看结果(windows)
3>os:cmd("copy warfield.txt _fla").
4>os:cmd("_fla\\Index.html").

更加详细的入门指南[http://code.google.com/p/erlbattle/wiki/EbStepByStep]


