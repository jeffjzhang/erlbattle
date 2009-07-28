# -*- coding: utf-8 -*-
'''eb0replay.py
    v9.07.28 init.
'''

VERSION = "eb0replay.py v9.07.28"

import os,sys,time,datetime
#from fnmatch import *
import urwid.curses_display
import urwid

import logging
daylog = "%s"%(time.strftime("%y%m%d",time.localtime()))
logging.basicConfig(level=logging.DEBUG,
                   format='[%(asctime)s]%(levelname)-8s"%(message)s"',
                    datefmt='%Y-%m-%d %a %H:%M:%S',
                    filename='logs/ebreplay-%s.log'%daylog,
                    filemode='a+')
#logging.info("%s::due mapping all %s into xml done..."% (VERSION,fname))

class replayer:
    """main class zip all done
    """
    def __init__(self,warlog):
        """ini all
        """
        self.grid = 15
        self.showmetre = 0.5
        ##tpl for soldier point
        self.ebsp = " %s%s" # self+action code
        #eb0 read soldier: #math code ∧ ∨
        self.ebrs={"w":"<"
            ,"e":">"
            ,"s":"∨"
            ,"n":"∧"
            }
        #eb0 blue soldier: ← ↑ → ↓
        self.ebbs={"w":"←"
            ,"e":"→"
            ,"s":"↓"
            ,"n":"↑"
            }
        #eb0 soldier turn: ↖ ↗ ↘ ↙ turnWest, turnEast, turnSouth, turnNorth
        self.ebst={"turnWest":"↖"
            ,"turnEast":"↗"
            ,"turnSouth":"↘"
            ,"turnNorth":"↗"
            }
        #eb0 soldier fight:▲►▼◄
        self.ebsf={"w":"◄"
            ,"e":"►"
            ,"s":"▼"
            ,"n":"▲"
            }
        #eb0 soldier act:walk stand status fight back plan
        self.ebsa={"walk":"."
            ,"stand":"_"
            ,"status":"!"
            ,"back":"r"
            ,"plan":"?"
            }
        self.ui = urwid.curses_display.Screen()
        self.ui.register_palette( [
            ('banner', 'black', 'light gray', ('standout', 'underline')),
            ('streak', 'black', 'dark red', 'standout'),
            ('bg', 'black', 'dark blue'),
            ] )
        self.ebf  = []
        self.ebfp = "   "
        self.ebfe = " ~ "*self.grid+"\n"
        self.init_ebf()
        #print self.ebf
        #print self.exp_ebf()
        self.war = open(warlog).readlines()
        #print self.war


    def init_ebf(self):
        """init ebf dict for replay
        """
        self.ebf  = []
        for i in range(self.grid):
            self.ebf.append([self.ebfp for j in range(self.grid)])
        pass
        #return self.ebf

    def exp_ebf(self):
        """export ebf list as string...
        """
        exp = "%s\n%s"%(VERSION,self.ebfe)
        for line in self.ebf:
            exp += "".join(line)
            exp += "\n"
            exp += self.ebfe

        return exp

    def _rewar(self,metrefl):
        """re understand EB war
            - metre fight list
        """
        attack_is = ""
        trun_is = ""
        other_is = ""
        self.init_ebf()
        for act in metrefl:
            al = act.split(",")
            move=al[1]
            y=int(al[2])
            x=int(al[3])
            sid=al[4]
            face=al[5]
            #print len(self.ebf[2])        
            if "fight"==move:
                attack_is = self.ebsf[face]
            elif "turn" in move:
                trun_is = self.ebst[move]
            else:
                other_is =self.ebsa[move]
            action=attack_is+trun_is+other_is
            if 10<int(sid):
                #blue team fight
                #print x,y
                self.ebf[x][y]=self.ebsp%(self.ebrs[face],action)
            else:
                #red team
                self.ebf[x][y]=self.ebsp%(self.ebbs[face],action)

    def play(self):
        """replay all
        """
        self.ui.run_wrapper(self.run)


    def run2(self):
        """replay all
        """	
        cols, rows = self.ui.get_cols_rows()
    	txt = urwid.Text(self.ebf, align="center")
    	fill = urwid.Filler( txt )
        canvas = fill.render( (cols, rows) )
        #txt = urwid.Text(('banner', self.ebf), align="center")
    	#wrap1 = urwid.AttrWrap( txt, 'streak' )
    	#fill = urwid.Filler( wrap1 )
    	#bg color
        #wrap2 = urwid.AttrWrap( fill, 'bg' )
    	#canvas = wrap2.render( (cols, rows) )

        self.ui.draw_screen( (cols, rows), canvas )

    	while not self.ui.get_input():
    		pass



    def run(self):
        """replay all
        """	
        cols, rows = self.ui.get_cols_rows()

        metrefl = []
        metre = "0"
        loop = 0
        for act in self.war:
            al = act.split(",")
            #print al[0]
            if "plan"==al[0]:
                pass
            else:
                if metre == al[0]:
                    metrefl.append(act)
                else:
                    #print len(metrefl)
                    self._rewar(metrefl)
                    #print self.exp_ebf()
                    ptxt = self.exp_ebf()
                    self._draw_screen(ptxt)
                    ## next metre show
                    time.sleep(self.showmetre)
                    if 0==loop%2:
                        self.init_ebf()
                    else:
                        pass
                    loop += 1
                    metre = al[0]
                    metrefl = []
                    metrefl.append(act)

    	while not self.ui.get_input():
    		pass



    def _draw_screen(self,ptxt):
        """replay all
        """	
        cols, rows = self.ui.get_cols_rows()
    	txt = urwid.Text(ptxt, align="center")
    	fill = urwid.Filler( txt )
    	canvas = fill.render( (cols, rows) )
    	self.ui.draw_screen( (cols, rows), canvas )



    def run0(self):
        """replay all
        """
        canvas = urwid.TextCanvas(["Hello World"])
    	self.ui.draw_screen( (20, 1), canvas )

    	while not self.ui.get_input():
    		pass




if __name__ == '__main__':
    """base usage
    """
    if 2 != len(sys.argv):
        print """ %s usage::
        $ python eb0replayer.py 'path/to/warfield.txt' 
        """ % VERSION
    else:
        warlog = sys.argv[1]
        rep = replayer(warlog)
        rep.play()
    ## for google...
    #mappingyk.mapall()
    #mappingyk.genidx()
    #mappingyk.gzipall()




