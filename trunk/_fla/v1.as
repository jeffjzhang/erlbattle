fscommand("allowscale", false);
// our map is 2-dimensional array
myMap1 = [
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
];
// declare game object that holds info
game = {tileW:40, tileH:40};
// walkable tile
game.Tile0 = function () { };
game.Tile0.prototype.walkable = true;
game.Tile0.prototype.frame = 1;
// wall tile
game.Tile1 = function () { };
game.Tile1.prototype.walkable = false;
game.Tile1.prototype.frame = 2;
// building the world
function buildMap(map) {
	// attach mouse cursor
	//_root.attachMovie("mouse", "mouse", 2);
	// attach empty mc to hold all the tiles and char
	//_root.attachMovie("empty", "tiles", 1);
	// attach empty mc to hold background tiles
	_root.tiles.attachMovie("empty", "back", 0);
	_root.tiles._xscale = 85;
	_root.tiles._yscale = 85;
	// declare clip in the game object
	game.clip = _root.tiles;
	game.clip._x = 460;
	game.clip._y = 80;
	// get map dimensions
	var mapWidth = map[0].length;
	var mapHeight = map.length;
	// loop to place tiles on stage
	for (var i = 0; i<mapHeight; ++i) {
		for (var j = 0; j<mapWidth; ++j) {
			// name of new tile
			var name = "t_"+i+"_"+j;
			// make new tile object in the game
			game[name] = new game["Tile"+map[i][j]]();
			if (game[name].walkable) {
				var clip = game.clip.back;
			} else {
				var clip = game.clip;
			}
			// calculate depth
			game[name].depth = (j+i)*game.tileW/2*300+(j-i)*game.tileW+1;
			// attach tile mc and place it
			clip.attachMovie("tile", name, game[name].depth);
			clip[name]._x = (j-i)*game.tileW;
			clip[name]._y = (j+i)*game.tileW/2;
			// send tile mc to correct frame
			clip[name].gotoAndStop(randRange(1,10));
		}
	}
	for (var i = 1 ; i < 11 ; i++){
		var o = {
			lib_name:"red",
			dir:"_d",
			scale:80,
			id:i,
			xtile:i-1,
			ytile:0
		}
		addChar(o);
	}
	for (var i = 1 ; i < 11 ; i++){
		var o = {
			lib_name:"blue",
			dir:"_l",
			scale:-80,
			id:i+10,
			xtile:i-1,
			ytile:9
		}
		addChar(o);
	}
	
}
function addChar(_o){
	// declare char object, xtile and ytile are tile where chars center is
	var ob = {xtile:0, ytile:0, speed:4, moving:false, width:40, height:40, targetx:6,  targety:1, action:"stand", dir:"_d", id:0, face:"w"};
	// calculate starting position
	ob.x = _o.xtile*game.tileW;
	ob.y = _o.ytile*game.tileW;
	ob.targetx = _o.xtile;
	ob.targety = _o.ytile;
	// calculate position in isometric view
	ob.xiso = ob.x-ob.y;
	ob.yiso = (ob.x+ob.y)/2;
	// calculate depth
	ob.depthshift = (game.tileW-ob.height)/2;
	ob.depth = (ob.yiso-ob.depthshift)*300+ob.xiso+1+_o.id;
	// add the character mc
	game.clip.attachMovie(_o.lib_name, "id" + _o.id, ob.depth);
	// declare clip in the game object
	ob.clip = game.clip["id" + _o.id];
	// place char mc
	//ob.clip._x = ob.xiso + ob.width;
	//ob.clip._y = ob.yiso + ob.height/2;
	ob.clip._x = -10000;
	ob.clip._y = -10000;
	ob.dir = "";
	ob.action = "stand";
	ob.clip.mc._xscale = _o.scale;
	ob.clip.id.text = _o.id;
	if (_o.id > 10) ob.clip.id.text = _o.id - 10;
	ob.clip.mc.gotoAndPlay(ob.action + _o.dir);
	ob.clip.blood.gotoAndStop(100);
	ob.id = _o.id;
	sprit.push(ob);
}
function set_to_current_place(ob){
	ob.x = ob.xtile*game.tileW;
	ob.y = ob.ytile*game.tileW;
	// calculate position in isometric view
	ob.xiso = ob.x-ob.y;
	ob.yiso = (ob.x+ob.y)/2;
	// update char position
	ob.clip._x = ob.xiso + ob.width;
	ob.clip._y = ob.yiso + ob.height/2;
	// calculate depth
	ob.depth = (ob.yiso-ob.depthshift)*300+(ob.xiso)+1;
	ob.clip.swapDepths(ob.depth);
}
function moveChar(ob) {
	// is char in the center of tile
	if ((ob.x)%game.tileW == 0 and (ob.y)%game.tileW == 0) {
		var _dir = "";
		// calculate the tile where chars center is
		ob.xtile = Math.floor(ob.x/game.tileW);
		ob.ytile = Math.floor(ob.y/game.tileH);
		// choose direction
		// right
		if (game["t_"+ob.ytile+"_"+(ob.xtile+1)].walkable and ob.targetx>ob.xtile) {
			ob.dirx = 1;
			ob.diry = 0;
			_dir = "_d";
			ob.clip.mc._xscale = -80;
			// left
		} else if (game["t_"+ob.ytile+"_"+(ob.xtile-1)].walkable and ob.targetx<ob.xtile) {
			ob.dirx = -1;
			ob.diry = 0;
			_dir = "_l";
			ob.clip.mc._xscale = 80;
			// up
		} else if (game["t_"+(ob.ytile+1)+"_"+ob.xtile].walkable and ob.targety>ob.ytile) {
			ob.dirx = 0;
			ob.diry = 1;
			_dir = "_d";
			ob.clip.mc._xscale = 80;
			// down
		} else if (game["t_"+(ob.ytile-1)+"_"+ob.xtile].walkable and ob.targety<ob.ytile) {
			ob.dirx = 0;
			ob.diry = -1;
			_dir = "_l";
			ob.clip.mc._xscale = -80;
			// none
		} else {
			ob.moving = false;
			moving = false;	
			//trace(ob.action);
			if (ob.action == "back") {
				switch(ob.face){
					case "n":
						ob.dir = "_l";
						ob.clip.mc._xscale = -80;
						break;
					case "e":
						ob.dir = "_d";
						ob.clip.mc._xscale = -80;
						break;
					case "s":
						ob.dir = "_d";
						ob.clip.mc._xscale = 80;
						break;
					case "w":
						ob.dir = "_l";
						ob.clip.mc._xscale = 80;
						break;
				}
			}
			ob.action = "stand";
			ob.clip.mc.gotoAndStop(ob.action + ob.dir);
			//trace("id="+ob.id);
			if (player == "play")	_root.actions = "next";
			return;
		}
		//trace(ob.action + ob.dir);
		if (ob.dir != _dir) {
			ob.dir = _dir;
			ob.clip.mc.gotoAndPlay(ob.action + ob.dir);
		}
		//trace(ob.action + _dir);
	}
	//trace("move");
	// move
	ob.y += ob.speed*ob.diry;
	ob.x += ob.speed*ob.dirx;
	// calculate position in isometric view
	ob.xiso = ob.x-ob.y;
	ob.yiso = (ob.x+ob.y)/2;
	// update char position
	ob.clip._x = ob.xiso + ob.width;
	ob.clip._y = ob.yiso + ob.height/2;
	// calculate depth
	ob.depth = (ob.yiso-ob.depthshift)*300+(ob.xiso)+1;
	ob.clip.swapDepths(ob.depth);
	// face the direction
	return (true);
}
/**
* 循环移动 map.sprit 数组中的精灵的位置
*/
function loop_move_char(){
	if (walk_sprit == null) return;
	walk_sprit.moving = true;
	//trace(walk_sprit.action);
	moveChar(walk_sprit);
}
function randRange(min:Number, max:Number):Number {
    var randomNum:Number = Math.floor(Math.random() * (max - min + 1)) + min;
    return randomNum;
}
function work() {
	if (actions == "next"){
		pt++;
		next_step()
	}
	if(	_root.actions == "pause_next"){
		pt++;
		next_step();
	}
	if (moving) loop_move_char();
}
function next_step(){
		//trace(pt)
	if (moving) {
		return ;
	}
	if (player == "pause" && actions != "pause_next")  {
		return ;
	}
	if (pt >= command.length)  {
		return ;
	}
	_root.actions = "";
	var step_com = command[pt].split(",");
	//忽略 plan 值
	while (step_com[0] == "plan"){
		pt++;
		step_com = command[pt].split(",");
	}
	var round = step_com[0];
	var action = step_com[1];
	var xtile = step_com[2];
	var ytile = step_com[3];
	var id = step_com[4];
	var dir = step_com[5];
	var blood = Number(step_com[6]);
	var del_blood = Number(step_com[7]);
	
	//胜利，结束
	if (round == "result") {
		step_txt.text += action + "\n";
		step_txt.vPosition = step_txt.maxVPosition;
		pt++;
		return;
	}
	var ob = null;
	for(var i = 0 ; i < sprit.length ; i++){
		if (sprit[i].id == Number(id)){
			ob = sprit[i];					
		}
	}
	if (ob == null){
		return;
	}
	ob.targetx = xtile;
	ob.targety = ytile;
	ob.action = action;
	if (action == "stand" || action == "status" || action == "turnWest" || action == "turnEast" || action == "turnSouth" || action == "turnNorth"  || action == "status" )  ob.action = "stand";
	if (action == "fight") ob.action = "fight1";
	ob.face = dir;
	switch(dir){
		case "n":
			ob.dir = "_l";
			ob.clip.mc._xscale = -80;
			break;
		case "e":
			ob.dir = "_d";
			ob.clip.mc._xscale = -80;
			break;
		case "s":
			ob.dir = "_d";
			ob.clip.mc._xscale = 80;
			break;
		case "w":
			ob.dir = "_l";
			ob.clip.mc._xscale = 80;
			break;
	}
	if (ob.action == "back") {
		switch(dir){
			case "s":
				ob.dir = "_d";
				ob.clip.mc._xscale = 80;
				break;
			case "e":
				ob.dir = "_l";
				ob.clip.mc._xscale = 80;
				break;
			case "n":
				ob.dir = "_l";
				ob.clip.mc._xscale = -80;
				break;
			case "w":
				ob.dir = "_d";
				ob.clip.mc._xscale = -80;
				break;
		}
	}
	if (action == "status") {
		ob.clip.mc.gotoAndPlay(action + ob.dir);
	}else{
		//播放mc，针对stand，fight
		ob.clip.mc.gotoAndPlay(ob.action + ob.dir);
	}
	//ob.clip.mc.gotoAndPlay(ob.action + ob.dir);
	//trace(ob.id);
	//血量减少显示
	ob.clip.blood.gotoAndStop(Number(blood));
	//信息窗口显示
	step_txt.text += "r"+round+":  c:"+action+"  id:"+id+"(x:"+xtile+",y:"+ytile+")  face("+dir+") ";
	if (del_blood == 0){
		step_txt.text += " hp("+blood+") \n";
	}else{
		step_txt.text += " hp("+blood+"="+String(blood+del_blood)+"-"+del_blood+") \n";
	}
	step_txt.vPosition = step_txt.maxVPosition;

	round_txt.text = "ROUND "+ round + " ["+player+"]";
	break_loop++;
	walk_sprit = null;
	if (ob.action == "stand" || ob.action == "fight1") {
		ob.xtile = xtile;
		ob.ytile = ytile;
		set_to_current_place(ob);
	}
	if (ob.action == "walk") {
		walk_sprit = ob;
		moving = true;
	}
	if (ob.action == "back") {
		walk_sprit = ob;
		moving = true;
	}
	if (blood == 0){
		ob.clip._visible = false;
	}
	if (( ob.action == "stand") && player == "play" && action != "status") next_step2();
}
function next_step2(){
	if (player == "play") _root.actions = "next";
	return;
}
//init
var sprit = new Array();
var walk_sprit = null;
var command = new Array();
var step = 0;
var player = "pause"; //play, pause, next_round
var pt = -1
var actions = "";
var moving = false;
// make the map

buildMap(_root["myMap1"]);
var my_lv:LoadVars = new LoadVars();
my_lv.onData = function(src:String) {
    if (src == undefined) {
        trace("Error loading content.");
        return;
    }
	_root.command = src.split("\r").join("").split("\n");
    //trace(command.length);
	//_root.next_step();
};
my_lv.load("warfield.txt", my_lv, "GET");
stop();
