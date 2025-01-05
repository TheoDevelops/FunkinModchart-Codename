package modchart;

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

final rotationVector = new Vector3D();
final emptyVector = new Vector3D();

// @:build(modchart.core.macros.Macro.buildModifiers())
@:allow(modchart.core.ModifierGroup)
@:allow(modchart.core.graphics.ModchartGraphics)
class Manager extends FlxBasic
{
	// @:dox(hide)
	// public static var __loopField:PlayField;

    public static var instance:Manager;

	public static var DEFAULT_HOLD_SUBDIVITIONS:Int = 1;

	public var HOLD_SUBDIVITIONS(default, set):Int;

	// turn on if u wanna arrow paths
	public var renderArrowPaths:Bool = false;

	function set_HOLD_SUBDIVITIONS(divs:Int)
		return HOLD_SUBDIVITIONS = Std.int(Math.max(1, divs));

    public var game:PlayState;
    public var events:EventManager;
	public var modifiers:ModifierGroup;

	private var _crochet:Float;

	private var arrowRenderer:ModchartArrowRenderer;
	private var receptorRenderer:ModchartArrowRenderer;
	private var holdRenderer:ModchartHoldRenderer;
	private var pathRenderer:ModchartArrowPath;

    public function new(game:PlayState)
    {
        super();
        
        instance = this;

        this.game = game;
		this.cameras = [game.camHUD];
        this.events = new EventManager();
		this.modifiers = new ModifierGroup();

		for (strumLine in game.strumLines)
		{
			strumLine.forEach(strum -> {
				strum.extra.set('field', strumLine.ID);
				// i guess ???
				strum.extra.set('lane', strumLine.members.indexOf(strum));
			});
		}
		HOLD_SUBDIVITIONS = DEFAULT_HOLD_SUBDIVITIONS;

		// setup the renderers
		arrowRenderer = new ModchartArrowRenderer(this);
		receptorRenderer = new ModchartArrowRenderer(this);
		holdRenderer = new ModchartHoldRenderer(this);
		pathRenderer = new ModchartArrowPath(this);

		// no bpm changes
		_crochet = Conductor.stepCrochet;

		// default mods
		addModifier('reverse');
		addModifier('stealth');
		addModifier('confusion');
		addModifier('skew');

		setPercent('arrowPathAlpha', 1, -1);
		setPercent('arrowPathThickness', 1, -1);
		setPercent('arrowPathDivitions', 1, -1);
		setPercent('rotateHoldY', 1, -1);
    }

	public function registerModifier(name:String, mod:Class<Modifier>)   return modifiers.registerModifier(name, mod);
    public function setPercent(name:String, value:Float, field:Int = -1) return modifiers.setPercent(name, value, field);
    public function getPercent(name:String, field:Int)    				 return modifiers.getPercent(name, field);
    public function addModifier(name:String)		 	 				 return modifiers.addModifier(name);

	public function addEvent(event:Event)
	{
		events.add(event);
	}
    public function set(name:String, beat:Float, value:Float, field:Int = -1):Void
    {
		if (field == -1)
		{
			for (curField in 0...2)
				set(name, beat, value, curField);
			return;
		}

        addEvent(new SetEvent(name.toLowerCase(), beat, value, field, events));
    }
    public function ease(name:String, beat:Float, length:Float, value:Float = 1, easeFunc:EaseFunction, field:Int = -1):Void
    {	
		if (field == -1)
		{
			for (curField in 0...2)
				ease(name, beat, length, value, easeFunc, curField);
			return;
		}

        addEvent(new EaseEvent(name, beat, length, value, easeFunc, field, events));
    }
	public function repeater(beat:Float, length:Float, callback:Event->Void):Void
		addEvent(new RepeaterEvent(beat, length, callback, events));

	public function callback(beat:Float, callback:Event->Void):Void
		addEvent(new Event(beat, callback, events));

    override function update(elapsed:Float):Void
    {
        // Update Event Timeline
        events.update(Conductor.curBeatFloat);
    }

	override function draw():Void
	{
		super.draw();

		var drawCB = [];
        for (strumLine in game.strumLines)
		{
			strumLine.notes.visible = strumLine.visible = false;
			ModchartUtil.updateViewMatrix(
				// View Position
				new Vector3D(
					getPercent('viewX', strumLine.ID),
					getPercent('viewY', strumLine.ID),
					getPercent('viewZ', strumLine.ID) + -0.71
				),
				// View Point
				new Vector3D(
					getPercent('viewLookX', strumLine.ID),
					getPercent('viewLookY', strumLine.ID),
					getPercent('viewLookZ', strumLine.ID)
				),
				// up
				new Vector3D(
					getPercent('viewUpX', strumLine.ID),
					1 + getPercent('viewUpY', strumLine.ID),
					getPercent('viewUpZ', strumLine.ID)
				)
			);

			strumLine.notes.forEach(arrow -> @:privateAccess {
				if (!arrow.isSustainNote) {
					arrowRenderer.prepare(arrow);
					drawCB.push({						
						callback: () -> {
							arrowRenderer.shift();
						},
						z: arrow._z - 2
					});
				} else {
					holdRenderer.prepare(arrow);
					drawCB.push({
						callback: () -> {
							//holdRenderer.render(1);
							holdRenderer.shift();
						},
						z: arrow._z - 1
					});
				}
			});

			strumLine.forEach(receptor -> {
				@:privateAccess
				receptorRenderer.prepare(receptor);
				if (renderArrowPaths)
					pathRenderer.prepare(receptor);

				drawCB.push({
					callback: () -> {
						receptorRenderer.shift();
					},
					z: receptor._z
				});
			});
		}

		drawCB.sort((a, b) -> {
			return Math.round(b.z - a.z);
		});

		if (renderArrowPaths)
			pathRenderer.shift();
		
		for (item in drawCB) item.callback();
	}

	override function destroy():Void
	{
		super.destroy();

		for (renderer in [arrowRenderer, receptorRenderer, holdRenderer, pathRenderer])
			renderer.dispose();
	}

    // HELPERS
    private function getScrollSpeed():Float return game.scrollSpeed;
    public function getReceptorY(lane:Float, field:Int)
        @:privateAccess
        return game.strumLines.members[field].startingPos.y;
    public function getReceptorX(lane:Float, field:Int)
        @:privateAccess
        return game.strumLines.members[field].startingPos.x + ((ARROW_SIZE) * lane);
		
	// for some reazon is 50 instead of 44 in cne
    public static var HOLD_SIZE:Float = 50 * 0.7;
    public static var HOLD_SIZEDIV2:Float = (50 * 0.7) * 0.5;
    public static var ARROW_SIZE:Float = 160 * 0.7;
    public static var ARROW_SIZEDIV2:Float = (160 * 0.7) * 0.5;
    public static var PI:Float = Math.PI;
}

