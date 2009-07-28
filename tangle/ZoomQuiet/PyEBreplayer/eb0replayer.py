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
    def __init__(self):
        """ini all
        """
        self.ui = urwid.curses_display.Screen()
        self.ui.register_palette( [
            ('banner', 'black', 'light gray', ('standout', 'underline')),
            ('streak', 'black', 'dark red', 'standout'),
            ('bg', 'black', 'dark blue'),
            ] )

        self.ebfp = " ."
        self.ebfl = self.ebfp*15*3+"\n"
        self.ebf = self.ebfl*15
        #print self.ebf

    def play(self):
        """replay all
        """
        self.ui.run_wrapper(self.run)


    def run(self):
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



    def run1(self):
        """replay all
        """	
        cols, rows = self.ui.get_cols_rows()

    	txt = urwid.Text(self.ebf, align="center")
    	fill = urwid.Filler( txt )

    	canvas = fill.render( (cols, rows) )
    	self.ui.draw_screen( (cols, rows), canvas )

    	while not self.ui.get_input():
    		pass



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
    rep = replayer()
    ## for Baidu ...
    rep.play()
    ## for google...
    #mappingyk.mapall()
    #mappingyk.genidx()
    #mappingyk.gzipall()




