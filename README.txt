erlbattle
=========

erlbattle, ����ս��, ���EB, ������googlecode�Ϸ�չ�����Ŀ�Դ��Ŀ, �ǻ���Erlang���Ե�ʵʱ����ѧϰƽ̨

![image](https://raw.githubusercontent.com/jeffjzhang/erlbattle/master/doc/image/replay-pic-s.png)

����Ŀ¼ʹ��˵��
----------------

/ (http://erlbattle.googlecode.com/svn/trunk/)
����doc             �ĵ�Ŀ¼
����core             �������
��  ����engine         ����Ŀ¼|
����army             ս�Ӵ���Ŀ¼; ����erlangԴ�����Makefile֮�⣬��Ҫ���������κ��ļ�
��  ����evan.tao     �����Ǹ���AIĿ¼�������Ҫ�½���AI����һ��Ŀ¼��дһ��Makefile
��  ����example_army
��  ����hwh
��  ����laofan
��  ����maddog
��  ����neoedmund
����ebin            beam���Ŀ¼
����priv            erlang�����ļ��Լ���һЩ�����нű�
����_fla            flash��ʾ����

��װ������
----------

��Ҫ: erl-otp_R11B-5 ���ϣ� ���ص�ַ[http://www.erlang.org/download.html]

1����װerl
2����/erlbattle Ŀ¼�£� ����Erlang shell
3���������: make:all([load]).
4��������Ϸ: erlbattle:start().
5��ϵͳ��������. �������㷴Ӧ����֮ǰ�ͽ����ˡ�
6��������ۿ��ĵ�һ��ս����������feardFarmers���־��ũ�� ��englandArmy��Ӣ���������� ֮���ս����
7��������� warfield.txt�õ�һ�����صĲ������������ս��
8���������� erlbattle:start(englandArmy,englandArmy) ��������Ӣ��������������
9��������� warfield.txt�õ�һ�����صĲ������������ս��

