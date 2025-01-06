package modchart.core.graphics;

import funkin.game.PlayState;
import openfl.display.Shape;
import funkin.backend.system.Conductor;
import flixel.math.FlxAngle;
import modchart.core.util.Constants.ArrowData;
import openfl.Vector;
import flixel.FlxSprite;
import flixel.FlxCamera;
import modchart.core.util.ModchartUtil;
import modchart.core.util.Constants.Visuals;
import openfl.geom.Vector3D;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import flixel.FlxObject;
import flixel.FlxBasic;
import flixel.FlxG;
import openfl.display.GraphicsPathCommand;

import funkin.game.Note;
import funkin.game.Strum;

import openfl.Vector;

var rotationVector = new Vector3D();
var helperVector = new Vector3D();
var __matrix:Matrix = new Matrix();
var pathVector = new Vector3D();

class ModchartRenderer<T:FlxBasic> extends FlxBasic
{
    private var instance:Null<PlayField>;
    private var queue:Array<FMDrawInstruction>;

    public function new(instance:PlayField)
    {
        super();

        this.instance = instance;
    }

    public function prepare(item:T) {}

    public function shift():Void {}

    public function dispose() {}
    // public function render(times:Null<Int>):Void {}
}

class ModchartHoldRenderer extends ModchartRenderer<FlxSprite>
{
    private var __lastHoldSubs:Int = -1;

    var _indices:Null<Vector<Int>> = new Vector<Int>();

    /**
	 * Returns the normal points along the hold path at specific time.
     * 
     * Based on schmovin' hold system
	 * @param basePos The hold position per default
	 */
     @:noCompletion
	private function getHoldQuads(basePos:Vector3D, params:ArrowData):Array<Dynamic>
	{
		final output1 = instance.modifiers.getPath(basePos.clone(), params);
		final output2 = instance.modifiers.getPath(basePos.clone(), params, 1);

		var curPoint = ModchartUtil.applyVectorZoom(output1.pos, output1.visuals.zoom);
		var nextPoint = ModchartUtil.applyVectorZoom(output2.pos, output2.visuals.zoom);

		var zScale:Float = curPoint.z != 0 ? (1 / curPoint.z) : 1;
		curPoint.z = nextPoint.z = 0;
		
		// normalized points difference (from 0-1)
		var unit = nextPoint.subtract(curPoint);
		unit.normalize();

		var size = Manager.HOLD_SIZEDIV2 * output1.visuals.scaleX * zScale * output1.visuals.zoom;
    
		var quads = [
			new Vector3D(-unit.y * size, unit.x * size),
			new Vector3D(unit.y * size, -unit.x * size)
		];
		@:privateAccess
		for (i in 0...2)
		{
			var visuals = [output1.visuals, output2.visuals][i];

			var translated = ModchartUtil.rotate3DVector(quads[i], visuals.angleX * instance.getPercent('rotateHoldX', params.field), visuals.angleY * instance.getPercent('rotateHoldY', params.field), visuals.angleZ * instance.getPercent('rotateHoldZ', params.field));
			translated.z *= 0.001;
			var rotOutput = ModchartUtil.perspective(translated, new Vector3D());

			rotationVector.copyFrom(rotOutput);

			if (visuals.skewX != 0 || visuals.skewY != 0)
			{
				__matrix.b = ModchartUtil.fastTan(visuals.skewY * FlxAngle.TO_RAD);
				__matrix.c = ModchartUtil.fastTan(visuals.skewX * FlxAngle.TO_RAD);

                rotOutput.x = __matrix.__transformX(rotationVector.x, rotationVector.y);
                rotOutput.y = __matrix.__transformY(rotationVector.x, rotationVector.y);
                
                __matrix.identity();
			}

			quads[i] = rotOutput;
		}
		return [
			[
				curPoint.add(quads[0]),
				curPoint.add(quads[1]),
				curPoint.add(new Vector3D(0, 0,  1 + (1 - zScale) * 0.001))
			],
			output1.visuals
		];
	}

    @:noCompletion
    private function updateIndices()
	{
        final HOLD_SUBDIVITIONS = Manager.PLUGIN.getHoldSubdivitions();

		_indices.length = (HOLD_SUBDIVITIONS * 6);
		for (sub in 0...HOLD_SUBDIVITIONS)
		{
			var vert = sub * 4;
			var count = sub * 6;

			_indices[count] = _indices[count + 3] = vert;
			_indices[count + 2] = _indices[count + 5] = vert + 3;
			_indices[count + 1] = vert + 1;
			_indices[count + 4] = vert + 2;
		}
	}
    override public function prepare(item:FlxSprite):Void
    {
        if (queue == null)
            queue = [];

        final arrow:FlxSprite = item;
        final newInstruction:FMDrawInstruction = {};
        final HOLD_SUBDIVITIONS = Manager.PLUGIN.getHoldSubdivitions();

        if (__lastHoldSubs != HOLD_SUBDIVITIONS)
            updateIndices();

        if (__lastHoldSubs == -1)
            __lastHoldSubs = Manager.PLUGIN.getHoldSubdivitions();

        var player = Manager.PLUGIN.getPlayerFromArrow(item);
        var lane = Manager.PLUGIN.getLaneFromArrow(item);

        var basePos = new Vector3D(
            Manager.PLUGIN.getDefaultReceptorX(lane, player),
            Manager.PLUGIN.getDefaultReceptorY(lane, player)
        ).add(ModchartUtil.getHalfPos());

        var vertTotal:Array<Float> = [];
        var transfTotal:Array<ColorTransform> = [];

        var lastVis:Visuals = null;
        var lastQuad:Array<Vector3D> = null;
        var lastData:ArrowData = null;

        var arrowQuads:Array<Vector3D> = null;
        var arrowVisuals:Visuals = null;

        var alphaTotal = 0.;

        Manager.HOLD_SIZE = arrow.width;
        Manager.HOLD_SIZEDIV2 = arrow.width * .5;

        var subCr = ((Manager.PLUGIN.getStaticCrochet() * .25) * ((Manager.PLUGIN.isHoldEnd(item)) ? 0.6 : 1)) / HOLD_SUBDIVITIONS;
        for (sub in 0...HOLD_SUBDIVITIONS)
        {
            var subOff = subCr * sub;

            var out1:Array<Dynamic> = [lastQuad, lastVis];
            if (lastQuad == null)
                out1 = getHoldQuads(basePos, lastData ?? getArrowParams(arrow, subOff));
            var out2 = getHoldQuads(basePos, (lastData = getArrowParams(arrow, subOff + subCr)));

            var topQuads:Array<Vector3D> = out1[0];
            var topVisuals:Visuals = out1[1];

            var bottomQuads:Array<Vector3D> = out2[0];
            var bottomVisuals:Visuals = out2[1];

            vertTotal = vertTotal.concat(ModchartUtil.getHoldVertex(topQuads, bottomQuads));

            lastVis = bottomVisuals;
            lastQuad = bottomQuads;

            if (arrowQuads == null) {
                arrowQuads = topQuads;
                arrowVisuals = topVisuals;
            }

            alphaTotal += arrowVisuals.alpha;

            transfTotal.push(new ColorTransform(
                1 - topVisuals.glow,
                1 - topVisuals.glow,
                1 - topVisuals.glow,
                topVisuals.alpha * 0.6,
                Math.round(topVisuals.glowR * topVisuals.glow * 255),
                Math.round(topVisuals.glowG * topVisuals.glow * 255),
                Math.round(topVisuals.glowB * topVisuals.glow * 255)
            ));
        }
    
        arrow._z = arrowQuads[2].z * 1000;

        newInstruction.item = item;
        newInstruction.vertices = new openfl.Vector<Float>(vertTotal.length, true, vertTotal);
        newInstruction.indices = _indices.copy();
        newInstruction.uvt = ModchartUtil.getHoldUVT(arrow, HOLD_SUBDIVITIONS);
        newInstruction.colorData = transfTotal;
        newInstruction.extra = [alphaTotal];

        queue.push(newInstruction);

        __lastHoldSubs = Manager.PLUGIN.getHoldSubdivitions();
    }
    override public function shift()
    {
        __drawInstruction(queue.shift());
    }

    /*
    override public function render(times:Null<Int>):Void
    {
        if (times == null)
            times = queue.length;

        var iterator = queue.iterator();
        var count = 0;

        @:privateAccess do {
            __drawInstruction(iterator.next());

            count++;
        } while (count < times && iterator.hasNext());

        queue = queue.splice(count, queue.length);
    }*/

    private function __drawInstruction(instruction:FMDrawInstruction)
    {
        if (cast(instruction.extra[0], Float) <= 0)
            return;
        
        final item:Note = cast instruction.item;

        @:privateAccess for (camera in (item._cameras ?? item.strumLine.cameras))
        {
            var item = camera.startTrianglesBatch(item.graphic, false, true, item.blend, true, item.shader);
            item.addGradientTriangles(instruction.vertices, instruction.indices, instruction.uvt, new openfl.Vector<Int>(), null, camera._bounds, instruction.colorData);
        }
    }

    private function getArrowParams(arrow:FlxSprite, posOff:Float = 0):ArrowData
	{
        final player = Manager.PLUGIN.getPlayerFromArrow(arrow);
        final lane = Manager.PLUGIN.getLaneFromArrow(arrow);

		final centered2 = instance.getPercent('centered2', player);
		final timeC2 = flixel.FlxG.height * 0.25 * centered2;
        final time = Manager.PLUGIN.getTimeFromArrow(arrow);

		var pos = (time - Manager.PLUGIN.getSongPosition()) + posOff;

		// clip rect
		if (Manager.PLUGIN.arrowHitted(arrow) && pos < 0)
			pos = 0;

		pos += timeC2;

		return {
			time: time + posOff + timeC2,
			hDiff: pos,
			receptor: lane,
			field: player,
			arrow: true
		};
	}
}

class ModchartArrowRenderer extends ModchartRenderer<FlxSprite>
{
    override public function prepare(arrow:FlxSprite)
    {
        if (queue == null)
            queue = [];

        final player = Manager.PLUGIN.getPlayerFromArrow(arrow);

        // setup the position
        var arrowTime = Manager.PLUGIN.getTimeFromArrow(arrow);
        var arrowDiff = arrowTime - Manager.PLUGIN.getSongPosition();

        // apply centered 2 (aka centered path)
        if (Manager.PLUGIN.isTapNote(arrow))
        {
            arrowDiff += FlxG.height * 0.25 * instance.getPercent('centered2', player);
        } else {
            arrowTime = Manager.PLUGIN.getSongPosition() + (FlxG.height * 0.25 * instance.getPercent('centered2', player));
            arrowDiff = arrowTime - Manager.PLUGIN.getSongPosition();
        }

        var arrowData:ArrowData = {
            time: arrowTime,
            hDiff: arrowDiff,
            receptor: Manager.PLUGIN.getLaneFromArrow(arrow),
            field: player,
            arrow: true
        };

        helperVector.setTo(
            Manager.PLUGIN.getDefaultReceptorX(arrowData.receptor, arrowData.field) + Manager.ARROW_SIZEDIV2,
            Manager.PLUGIN.getDefaultReceptorY(arrowData.receptor, arrowData.field) + Manager.ARROW_SIZEDIV2, 0
        );

		final output = instance.modifiers.getPath(helperVector, arrowData);
        helperVector = ModchartUtil.applyVectorZoom(output.pos.clone(), output.visuals.zoom);

		arrow._z = helperVector.z * 1000;

		// internal mods
		final orient = instance.getPercent('orient', arrowData.field);
		if (orient != 0)
		{
			final nextOutput = instance.modifiers.getPath(
                new Vector3D(
                    Manager.PLUGIN.getDefaultReceptorX(arrowData.receptor, arrowData.field) + Manager.ARROW_SIZEDIV2,
                    Manager.PLUGIN.getDefaultReceptorY(arrowData.receptor, arrowData.field) + Manager.ARROW_SIZEDIV2
                ),
                arrowData,
                1
            );
			final thisPos = ModchartUtil.applyVectorZoom(output.pos, output.visuals.zoom);
			final nextPos = ModchartUtil.applyVectorZoom(nextOutput.pos, nextOutput.visuals.zoom);

			output.visuals.angleZ += (-90 + (Math.atan2(nextPos.y - thisPos.y, nextPos.x - thisPos.x) * FlxAngle.TO_DEG)) * orient;
		}

        // prepare the instruction for drawing
        var zScale = 1 / helperVector.z;
		var arrowWidth = arrow.frame.frame.width * arrow.scale.x * .5;
		var arrowHeight = arrow.frame.frame.width * arrow.scale.y * .5;

		var arrowQuads = [
			// top left
			-arrowWidth, -arrowHeight,
			// top right
			arrowWidth, -arrowHeight,
			// bottom left
			-arrowWidth, arrowHeight,
			// bottom right
			arrowWidth, arrowHeight
		];

		var vertPos = 0;
		@:privateAccess do {
			rotationVector.setTo(arrowQuads[vertPos], arrowQuads[vertPos + 1], 0);
			
			var translated = ModchartUtil.rotate3DVector(rotationVector, output.visuals.angleX, output.visuals.angleY, output.visuals.angleZ);
			translated.z *= 0.001;
			var rotOutput = ModchartUtil.perspective(translated, new Vector3D(FlxG.width / 2, FlxG.height / 2));

			rotOutput.x *= zScale * output.visuals.zoom * output.visuals.scaleX;
			rotOutput.y *= zScale * output.visuals.zoom * output.visuals.scaleY;

			rotationVector.copyFrom(rotOutput);

			if (output.visuals.skewX != 0 || output.visuals.skewY != 0)
			{
				__matrix.b = ModchartUtil.fastTan(output.visuals.skewY * FlxAngle.TO_RAD);
				__matrix.c = ModchartUtil.fastTan(output.visuals.skewX * FlxAngle.TO_RAD);
			}

			rotOutput.x = __matrix.__transformX(rotationVector.x, rotationVector.y);
			rotOutput.y = __matrix.__transformY(rotationVector.x, rotationVector.y);
			
			__matrix.identity();

			arrowQuads[vertPos] = rotOutput.x + helperVector.x;
			arrowQuads[vertPos+1] = rotOutput.y + helperVector.y;

			vertPos += 2;
			
		} while (vertPos < arrowQuads.length);

		var vertices = new Vector<Float>(12, true, [
			arrowQuads[0], arrowQuads[1],
			arrowQuads[2], arrowQuads[3],
			arrowQuads[6], arrowQuads[7],
			arrowQuads[0], arrowQuads[1],
			arrowQuads[4], arrowQuads[5],
			arrowQuads[6], arrowQuads[7]
		]);
		var uvData = new Vector<Float>(12, true, [
			arrow.frame.uv.x,     arrow.frame.uv.y,
		    arrow.frame.uv.width, arrow.frame.uv.y,
		    arrow.frame.uv.width, arrow.frame.uv.height,
		    arrow.frame.uv.x,     arrow.frame.uv.y,
		    arrow.frame.uv.x, 	   arrow.frame.uv.height,
		    arrow.frame.uv.width, arrow.frame.uv.height
	   ]);

	   var color = new ColorTransform(
			1 - output.visuals.glow,
			1 - output.visuals.glow,
			1 - output.visuals.glow,
			output.visuals.alpha,
			Math.round(output.visuals.glowR * output.visuals.glow * 255),
			Math.round(output.visuals.glowG * output.visuals.glow * 255),
			Math.round(output.visuals.glowB * output.visuals.glow * 255)
		);

        // make the instruction
        var newInstruction:FMDrawInstruction = {};
        newInstruction.item = arrow;
        newInstruction.vertices = vertices;
        newInstruction.uvt = uvData;
        newInstruction.indices = new Vector<Int>(vertices.length, true, [for (i in 0...vertices.length) i]);
        newInstruction.colorData = [color];
        
        queue.push(newInstruction);
    }
    override public function shift()
    {
        __drawInstruction(queue.shift());
    }
    /*
    override public function render(times:Null<Int>):Void
    {
        if (times == null)
            times = queue.length;

        var iterator = queue.iterator();
        var count = 0;

        @:privateAccess do {
            __drawInstruction(iterator.next());

            count++;
        } while (count < times && iterator.hasNext());

        queue = queue.splice(count, queue.length);
    }*/
    private function __drawInstruction(instruction:FMDrawInstruction)
    {
        if (instruction.colorData[0].alphaMultiplier <= 0)
            return;

        final item = instruction.item;
        
        @:privateAccess for (camera in (item._cameras ?? Manager.PLUGIN.getArrowCamera()))
        {
			camera.drawTriangles(
                item.graphic,
                instruction.vertices,
                instruction.indices,
                instruction.uvt,
                new Vector<Int>(),
                null,
                item.blend,
                false,
                false,
                instruction.colorData[0],
                item.shader
            );
        }
    }
}

class ModchartArrowPath extends ModchartRenderer<FlxSprite>
{
    var __shape:Shape = new Shape();
    var __display:FlxSprite = new FlxSprite();
    var __queuedPoints:Array<Array<Float>> = [];
    var __pathPoints:Vector<Float> = new Vector<Float>();
	var __pathCommands:Vector<Int> = new Vector<Int>();

    public function new(instance:PlayField)
    {
        super(instance);

        __display.makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF);
    }

    // the entry sprite should be A RECEPTOR / STRUM !!
    override public function prepare(item:FlxSprite)
    {
        if (queue == null)
            queue = [];

        final lane = Manager.PLUGIN.getLaneFromArrow(item);
        final fn = Manager.PLUGIN.getPlayerFromArrow(item);

        final alpha = instance.getPercent('arrowPathAlpha', fn);
        final thickness = 1 + Math.round(instance.getPercent('arrowPathThickness', fn));

        if (alpha <= 0 || thickness <= 0)
            return;

        final divitions = Math.round(80 / Math.max(1, instance.getPercent('arrowPathDivitions', fn)));
        final limit = 1500 * (1 + instance.getPercent('arrowPathLength', fn));
        final invertal = limit / divitions;

        var moved = false;

        pathVector.setTo(Manager.PLUGIN.getDefaultReceptorX(lane, fn), Manager.PLUGIN.getDefaultReceptorY(lane, fn), 0);
        pathVector.incrementBy(ModchartUtil.getHalfPos());

        var pointData:Array<Array<Dynamic>> = [];

        for (sub in 0...divitions)
        {
            var time = -500 + invertal * sub;

            var output = instance.modifiers.getPath(pathVector.clone(), {
                time: Manager.PLUGIN.getSongPosition() + time,
                hDiff: time,
                receptor: lane,
                field: fn,
                arrow: true,
                __holdParentTime: -1,
                __holdLength: -1
            }, 0, false, true);
            final position = output.pos;

            /**
             * So it seems that if the lines are too far from the screen
             causes HORRIBLE memory leaks (from 60mb to 3gb-5gb in 2 seconds WHAT THE FUCK)
            */
            if ((position.x <= 0 - thickness - ARROW_PATH_BOUNDARY_OFFSET) || (position.x >= __display.pixels.rect.width + ARROW_PATH_BOUNDARY_OFFSET) ||
                (position.y <= 0 - thickness - ARROW_PATH_BOUNDARY_OFFSET) || (position.y >= __display.pixels.rect.height + ARROW_PATH_BOUNDARY_OFFSET))
                continue;

            pointData.push([!moved, position.x, position.y]);

            moved = true;
        }

        var newInstruction:FMDrawInstruction = {};
        newInstruction.mapedExtra = [
            'style' => [thickness, 0xFFFFFFFF, alpha],
            'position' => pointData,
            'lane' => lane
        ];

        queue.push(newInstruction);
    }
    override public function shift()
    {
        __pathPoints.splice(0, __pathPoints.length);
		__pathCommands.splice(0, __pathCommands.length);
		__shape.graphics.clear();
		__display.cameras = Manager.PLUGIN.getArrowCamera();

        final iterator = queue.iterator();
        var lastLane = -1;

        do {
            final instruction = iterator.next();
            final thisLane = instruction.mapedExtra.get('lane');
            
            if (lastLane != thisLane)
            {
                final style = instruction.mapedExtra.get('style');
				__shape.graphics.lineStyle(style[0], style[1], style[2], false, NORMAL, ROUND, ROUND);
            }

            final steps = instruction.mapedExtra.get('position').iterator();

            while (steps.hasNext())
            {
                final thisStep = steps.next();

                final needsToMove:Bool = cast thisStep[0];
                final posX:Float = cast thisStep[1];
                final posY:Float = cast thisStep[2];
    
                __pathCommands.push(needsToMove ? GraphicsPathCommand.MOVE_TO : GraphicsPathCommand.LINE_TO);
                __pathPoints.push(posX);
                __pathPoints.push(posY);
            }

            lastLane = thisLane;
        } while (iterator.hasNext());

		__shape.graphics.drawPath(__pathCommands, __pathPoints);

		// then drawing the path pixels into the sprite pixels
		__display.pixels.fillRect(__display.pixels.rect, 0x00FFFFFF);
		__display.pixels.draw(__shape);
		// draw the sprite to the cam
		__display.draw();

        queue.splice(0, queue.length);
    }

    override function dispose()
    {
        __display.destroy();
		__shape.graphics.clear();
		__pathPoints.splice(0, __pathPoints.length);
		__pathCommands.splice(0, __pathCommands.length);
    }
	inline static final ARROW_PATH_BOUNDARY_OFFSET:Float = 75;
}

// TODO: fix this shit, i have this class in private cuz it sucks and doesnt even draw anything
// also should i call this actor frame ?
class ModchartProxyRenderer extends ModchartRenderer<FlxCamera>
{
    override public function prepare(cam:FlxCamera):Void
    {

    }
}

// we better not use this, it could cause problems in the future (when we make the standalone system)
// abstract StandartArrow(Dynamic) from Note from Strum to Note to Strum {}

@:publicFields
@:structInit
class FMDrawInstruction
{
	var item:FlxSprite;
	var vertices:openfl.Vector<Float>;
	var uvt:openfl.Vector<Float>;
	var indices:openfl.Vector<Int>;
    var colorData:Array<ColorTransform>;
    
    var extra:Array<Dynamic>;
    var mapedExtra:Map<String, Dynamic>;

    public function new() {}
}