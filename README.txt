= EB:代码目录使用说明 =

属主:
版本:
    090801 houmingyuan 创建;ZoomQuiet 格式增补


== 目录约定 ==
/ (http://erlbattle.googlecode.com/svn/trunk/)
├─doc             文档目录
│  ├─docpicture
│  ├─kongfu
│  └─logo
+--core             核心组件
|  +-engine         引擎目录|
├─army             战队代码目录; 除了erlang源代码和Makefile之外，不要放入其他任何文件
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


== 运行EB ==
需要: erl-otp_R11B-5 以上， 下载地址[http://www.erlang.org/download.html]

@Windows
基于: nmake, 下载地址[http://erlbattle.googlecode.com/files/nmake.exe]
执行下面两个命令
D:\erlbattle>configure
D:\erlbattle>nmake
或是执行以下命令
>make.bat

@Linux
基干:gnu make (一般都自带0\)
#./configure
#make.sh

最快速启动,命令行直调:
   erl -nologo -noshell -pz ebin -s erlbattle start

=== 在erl shell 中 ===
# 启动erl
>erl

# 加载ebin路径
    .beam文件，也就是erlang代码所编译出来的字节码
    ebin目录包含了所有这些beam文件
    要运行这些文件首先erl需要在知道这些文件在那
    可以在erl环境下使用
1>code:add_pathz("ebin").
    加载我们的代码（.是erlang语句的结束符不能少.
    检查是否成功追加路径:
    在erl交互环境下输入
2>code:get_path().
    可以看到当前系统所加载的代码目录.
    如果太多有[..|..] 的结尾，是说明没有都显示出来，就可以用:
3>io:format("~p", [code:get_path()]).
    完全展示.

# 启动erlbattle
3>erlbattle:start().
    战斗结果直接输出 , 并同时保存于warfield.txt

# 观看结果(windows)
3>os:cmd("copy warfield.txt _fla").
4>os:cmd("_fla\\Index.html").


= others =
更加详细的入门指南[http://code.google.com/p/erlbattle/wiki/EbStepByStep]


