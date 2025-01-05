package modchart;

import flixel.FlxG;
import funkin.game.PlayState;
import modchart.core.util.Constants.RenderParams;
import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.Visuals;
import openfl.geom.Vector3D;
import flixel.math.FlxMath;

using StringTools;

class Modifier
{
    public function new() {}
    
    public function render(curPos:Vector3D, params:RenderParams)
    {
        return curPos;
    }
	public function visuals(data:Visuals, params:RenderParams):Visuals
	{
		return data;
	}
	public function shouldRun(params:RenderParams):Bool
		return false;

    public function setPercent(name:String, value:Float, field:Int = -1)
    {
        Manager?.instance?.modifiers?.setPercent(name, value, field);
    }
	public function getPercent(name:String, field:Int):Float
    {
        return Manager?.instance?.modifiers?.getPercent(name, field);
    }
    
	private function getKeycount(field:Int = 0):Int
	{
		return (PlayState?.instance?.strumLines?.members[field]?.members?.length) ?? 4;
	}
	private function getPlayercount():Int
	{
		return (PlayState?.instance?.strumLines?.length) ?? 2;
	}
    // Helpers Functions
    private function getScrollSpeed():Float
        return PlayState?.instance?.scrollSpeed ?? 1;
    public function getReceptorY(lane:Int, field:Int)
        @:privateAccess return PlayState?.instance?.strumLines.members[field]?.startingPos?.y;
    public function getReceptorX(lane:Int, field:Int)
        @:privateAccess return PlayState?.instance?.strumLines.members[field]?.startingPos?.x + ((ARROW_SIZE) * lane);

	public function getManager():Manager
		return Manager.instance;

    private var WIDTH:Float = FlxG.width;
    private var HEIGHT:Float = FlxG.height;
    private var ARROW_SIZE(get, default):Float;
    private var ARROW_SIZEDIV2(get, default):Float;
	private function get_ARROW_SIZE():Float
		return Manager.ARROW_SIZE;
	private function get_ARROW_SIZEDIV2():Float
		return Manager.ARROW_SIZEDIV2;

    private var PI:Float = Math.PI;

    // no way guys, regular sinus is faster than fastSin :surprised:
    // (in hl fastSin is still faster than regular sin)
    // https://github.com/HaxeFlixel/flixel/issues/3215#issuecomment-2226858302
    // https://try.haxe.org/#847eac2B
    private function sin(num:Float)
        return #if !hl Math.sin(num) #else FlxMath.fastSin(num) #end;
    private function cos(num:Float)
        return #if !hl Math.cos(num) #else FlxMath.fastCos(num) #end;
    private function tan(num:Float)
        return #if !hl Math.tan(num) #else sin(num) / cos(num) #end;

    public function toString():String {
        var classn:String = Type.getClassName(Type.getClass(this));
        classn = classn.substring(classn.lastIndexOf('.') + 1);
        return 'Modifier[$classn]';
    }
}