package modchart.modifiers.false_paradise;

import modchart.core.util.Constants.RenderParams;
import modchart.core.util.Constants.ArrowData;
import openfl.geom.Vector3D;
import funkin.backend.system.Conductor;
import modchart.core.util.ModchartUtil;

class CounterClockWise extends Modifier
{
    override public function render(curPos:Vector3D, params:RenderParams)
    {
		var strumTime = params.sPos + params.hDiff;
		var centerX = WIDTH * .5;
		var centerY = HEIGHT * .5;
		var radiusOffset = ARROW_SIZE * (params.receptor - 1.5);
		var radius = 200 + radiusOffset * cos(strumTime / Conductor.stepCrochet / 16 * PI);
		var outX = centerX + cos(strumTime / Conductor.crochet / 4 * PI) * radius;
		var outY = centerY + sin(strumTime / Conductor.crochet / 4 * PI) * radius;

		return ModchartUtil.lerpVector3D(curPos, new Vector3D(outX, outY, 0, 0), getPercent('counterClockWise', params.field));
    }
	override public function shouldRun(params:RenderParams):Bool
		return getPercent('counterclockwise', params.field) != 0;
}