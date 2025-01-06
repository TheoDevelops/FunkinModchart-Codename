package modchart;

import modchart.core.PlayField;
import flixel.group.FlxGroup.FlxTypedGroup;
import modchart.core.graphics.ModchartGraphics.ModchartRenderer;
import modchart.core.graphics.ModchartGraphics.ModchartArrowPath;
import modchart.core.graphics.ModchartGraphics.ModchartHoldRenderer;
import modchart.core.graphics.ModchartGraphics.ModchartArrowRenderer;
import flixel.util.FlxColor;
import format.abc.Data.ABCData;
import flixel.math.FlxAngle;
import funkin.backend.system.Logs;
import funkin.game.Note;
import funkin.game.Strum;
import funkin.game.StrumLine;
import funkin.game.PlayState;
import funkin.backend.utils.CoolUtil;
import funkin.backend.system.Conductor;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.system.FlxAssets.FlxShader;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import flixel.graphics.tile.FlxDrawTrianglesItem;

import openfl.Vector;

import openfl.geom.Matrix;
import openfl.geom.Vector3D;
import openfl.geom.ColorTransform;

import openfl.display.Shape;
import openfl.display.BitmapData;
import openfl.display.GraphicsPathCommand;

import modchart.modifiers.*;
import modchart.events.*;
import modchart.events.types.*;
import modchart.core.util.ModchartUtil;
import modchart.core.ModifierGroup;
import modchart.core.util.Constants.RenderParams;
import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.Visuals;
import modchart.standalone.CodenameAdapter;

final rotationVector = new Vector3D();
final emptyVector = new Vector3D();

// @:build(modchart.core.macros.Macro.buildModifiers())
@:allow(modchart.core.ModifierGroup)
@:allow(modchart.core.graphics.ModchartGraphics)
class Manager extends FlxBasic
{
	// @:dox(hide)
	// public static var __loopField:PlayField;

	public static final PLUGIN:CodenameAdapter = new CodenameAdapter();

    public static var instance:Manager;

	// turn on if u wanna arrow paths
	public var renderArrowPaths:Bool = false;

	public var playfields:Array<PlayField> = [];

    public function new()
    {
        super();
        
        instance = this;

		PLUGIN.onModchartingInitialization();

		addPlayfield();
    }

	public function registerModifier(name:String, mod:Class<Modifier>)
		forEachPlayfield((pf) -> pf.registerModifier(name, mod));

	public function addModifier(name:String, field:Int = -1)
	{
		if (field != -1)
			playfields[field]?.addModifier(name);
		else
			forEachPlayfield((pf) -> pf.addModifier(name));
	}
	public function setPercent(name:String, value:Float, player:Int = -1, field:Int = -1)
	{
		if (field != -1)
			playfields[field]?.setPercent(name, value, player);
		else
			forEachPlayfield((pf) -> pf.setPercent(name, value, player));
	}
	public function getPercent(name:String, player:Int = -1, field:Int = -1)
	{
		return playfields[field]?.getPercent(name, player);
	}

	@:noCompletion
	private function forEachPlayfield(func:PlayField->Void)
	{
		for (pf in playfields)
			func(pf);
	}

	public function addEvent(event:Event, field:Int = -1)
	{
		if (field != -1)
			playfields[field]?.addEvent(event);
		else
			forEachPlayfield((pf) -> pf.addEvent(event));
	}
    public function set(name:String, beat:Float, value:Float, player:Int = -1, field:Int = -1):Void
    {
		if (field != -1)
			playfields[field]?.set(name, beat, value, player);
		else
			forEachPlayfield((pf) -> pf.set(name, beat, value, player));
    }
    public function ease(name:String, beat:Float, length:Float, value:Float = 1, easeFunc:EaseFunction, player:Int = -1, field:Int = -1):Void
    {	
		if (field != -1)
			playfields[field]?.ease(name, beat, length, value, easeFunc, player);
		else
			forEachPlayfield((pf) -> pf.ease(name, beat, length, value, easeFunc, player));
    }
	public function repeater(beat:Float, length:Float, callback:Event->Void, field:Int = -1):Void
	{
		if (field != -1)
			playfields[field]?.repeater(beat, length, callback);
		else
			forEachPlayfield((pf) -> pf.repeater(beat, length, callback));
	}

	public function callback(beat:Float, callback:Event->Void, field:Int = -1):Void
	{
		if (field != -1)
			playfields[field]?.callback(beat, callback);
		else
			forEachPlayfield((pf) -> pf.callback(beat, callback));
	}

	public function addPlayfield()
	{
		playfields.push(new PlayField());

		// default mods
		addModifier('reverse', playfields.length - 1);
		addModifier('stealth', playfields.length - 1);
		addModifier('confusion', playfields.length - 1);
		addModifier('skew', playfields.length - 1);

		setPercent('arrowPathAlpha', 1, playfields.length - 1);
		setPercent('arrowPathThickness', 1, playfields.length - 1);
		setPercent('arrowPathDivitions', 1, playfields.length - 1);
		setPercent('rotateHoldY', 1, playfields.length - 1);
	}
    override function update(elapsed:Float):Void
    {
		super.update(elapsed);

		forEachPlayfield(pf -> pf.update(elapsed));
    }

	override function draw():Void
    {
		var drawQueue:Array<{callback:Void->Void, z:Float}> = [];

		forEachPlayfield(pf -> {
			pf.draw();

			@:privateAccess
			drawQueue = drawQueue.concat(pf.drawCB);
		});

		drawQueue.sort((a, b) -> {
			return Math.round(b.z - a.z);
		});

		for (item in drawQueue) item.callback();
    }

	override function destroy():Void
	{
		super.destroy();

		forEachPlayfield(pf -> pf.destroy());
	}

	// for some reazon is 50 instead of 44 in cne
    public static var HOLD_SIZE:Float = 50 * 0.7;
    public static var HOLD_SIZEDIV2:Float = (50 * 0.7) * 0.5;
    public static var ARROW_SIZE:Float = 160 * 0.7;
    public static var ARROW_SIZEDIV2:Float = (160 * 0.7) * 0.5;
}