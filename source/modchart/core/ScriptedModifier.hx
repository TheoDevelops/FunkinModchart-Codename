package modchart.core;

import flixel.FlxG;
import funkin.game.PlayState;
import modchart.core.util.Constants.RenderParams;
import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.Visuals;
import openfl.geom.Vector3D;
import flixel.math.FlxMath;

class ScriptedModifier extends Modifier
{
	public var _render:(Vector3D, RenderParams) -> Vector3D = null;
	public var _visuals:(Visuals, RenderParams) -> Visuals = null;

	override public function render(a, b)
	{
		if (_render != null) 
			_render(a, b);

		return a;
	}
	override public function visuals(data:Visuals, params:RenderParams)
	{
		if (_visuals != null) 
			return _visuals(data, params);

		return data;
	}
	override public function shouldRun(params:RenderParams):Bool
		return true;
}