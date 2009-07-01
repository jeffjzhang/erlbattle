= ErlBattle =
恶狼战役 ~ Erlang 学玩游戏平台工程

 版本::
  * 090624 ZoomQuiet 增补掺合新目录结构

== 工程约定 ==
`约定这一中文版文档工程的相关协同事务`

=== 工程环境 ===
 SVN: http://erlbattle.googlecode.com/svn/ 目录结构
{{{
/
    +-- branches  分支版本
    +-- release   发布版本
    +-- tangle    自由分支
    +-- tasks     任务分支
    +-- trunk     主干代码
    +-- wiki      工程维基
    +-- svn.ignore  SVN属性忽略文件类型聲明
    \-- readme.txt  本文
}}}

= Others =
文件类型过滤 ::
 文件类型限制声明: source:/svn.ignore
  * 对想进行文件提交类型过滤的目录进行应用此文件！
{{{
$ svn propset svn:ignore -F svn.ignore -R path/to/dir
递归设置属性 “svn:ignore” 于 “.”
}}}
 * 参考:忽略未版本控制的条目
  * http://www.subversion.org.cn/svnbook/1.4/svn.advanced.props.special.ignore.html

