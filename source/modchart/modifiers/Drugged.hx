package modchart.modifiers;

import modchart.core.util.ModchartUtil;
import flixel.math.FlxMath;
import modchart.core.util.Constants.Visuals;
import funkin.backend.system.Conductor;
import modchart.core.util.Constants.RenderParams;
import modchart.core.util.Constants.ArrowData;
import openfl.geom.Vector3D;

class Drugged extends Modifier
{
    override public function render(curPos:Vector3D, params:RenderParams)
    {
        var amplitude = 1.;
        var frequency = 1.;

        var x = (params.hDiff * 0.009) + (params.receptor * 0.125);
        var y = 0.;
        y = sin(x * frequency);
        var t = 0.01*(-Manager.PLUGIN.getSongPosition()*0.0025*130.0);
        y += sin(x*frequency*2.1 + t)*4.5;
        y += sin(x*frequency*1.72 + t*1.121)*4.0;
        y += sin(x*frequency*2.221 + t*0.437)*5.0;
        y += sin(x*frequency*3.1122+ t*4.269)*2.5;
        y *= amplitude*0.06;

        curPos.x += y * getPercent('drugged', params.field) * ARROW_SIZE * 0.8;

        return curPos;
    }
    override public function visuals(visuals:Visuals, params:RenderParams)
    {
        var drug = getPercent('drugged', params.field);

        var amplitude = 1.;
        var frequency = 1.;

        var x = (params.hDiff * 0.025) + (params.receptor * 0.3);
        var y = 0.;
        y = sin(x * frequency);
        var t = 0.01*(-Manager.PLUGIN.getSongPosition()*0.005*130.0);
        y += sin(x*frequency*2.1 + t)*4.5;
        y += sin(x*frequency*1.72 + t*1.121)*4.0;
        y += sin(x*frequency*2.221 + t*0.437)*5.0;
        y += sin(x*frequency*3.1122+ t*4.269)*2.5;
        y *= amplitude*0.06;

        y = -FlxMath.bound(y, -1, 1);

        var squishX = 1 + FlxMath.bound(y, -1, 0) * -1 * 0.6;
        var squishY = 1 + FlxMath.bound(y, 0, 1) * 0.6;

        visuals.scaleX *= squishX * drug;
        visuals.scaleY *= squishY * drug;

        var preproduct = Math.asin(y);
        var cosdY = cos(Math.asin(y));

        visuals.glow = y * -.7;
        visuals.glowR -= 0.5 + sin(preproduct * 1.4) * .5;
        visuals.glowG += 0.4 + cos(preproduct * 0.5) * .6;
        visuals.glowB -= 0.2 + tan(preproduct) * .8;

        return visuals;

        // curPos.x += y * getPercent('drugged', params.field);
    }
	override public function shouldRun(params:RenderParams):Bool
		return true;
}