package modchart.standalone;

import flixel.FlxCamera;
import flixel.FlxSprite;
import funkin.game.Strum;
import funkin.game.Note;
import funkin.game.PlayState;
import funkin.options.Options;
import funkin.backend.system.Conductor;

class CodenameAdapter
{
    private var __fCrochet:Float = 0;

    public function new() {}

    public function onModchartingInitialization()
    {
        __fCrochet = Conductor.crochet;

        for (strumLine in PlayState.instance.strumLines.members)
		{
			strumLine.forEach(strum -> {
				strum.extra.set('field', strumLine.ID);
				// i guess ???
				strum.extra.set('lane', strumLine.members.indexOf(strum));
			});
		}
    }
    
    public function isTapNote(sprite:FlxSprite)
    {
        return sprite is Note;
    }
    // Song related
    public function getSongPosition():Float
    {
        return Conductor.songPosition;
    }
    public function getCurrentBeat():Float
    {
        return Conductor.curBeatFloat;
    }
    public function getStaticCrochet():Float
    {
        return __fCrochet;
    }

    public function arrowHitted(arrow:FlxSprite)
    {
        if (arrow is Note)
            return cast(arrow, Note).wasGoodHit;
        return false;
    }

    public function isHoldEnd(arrow:FlxSprite)
    {
        if (arrow is Note)
            return cast(arrow, Note).nextSustain == null;
        return false;
    }
    
    public function getLaneFromArrow(arrow:FlxSprite)
	{
		if (arrow is Note)
			return cast(arrow, Note).strumID;
		else if (arrow is Strum)
			return cast(arrow, Strum).extra.get('lane') ?? 0;

		return 0;
	}
	public function getPlayerFromArrow(arrow:FlxSprite)
	{
		if (arrow is Note)
			return cast(arrow, Note).strumLine.ID;
		else if (arrow is Strum)
			return cast(arrow, Strum).extra.get('field') ?? 0;

		return 0;
	}

	public function getKeycount(field:Int = 0):Int
	{
		return (PlayState?.instance?.strumLines?.members[field]?.members?.length) ?? 4;
	}
	public function getPlayercount():Int
	{
		return (PlayState?.instance?.strumLines?.length) ?? 2;
	}

	public function getTimeFromArrow(arrow:FlxSprite)
	{
		if (arrow is Note)
			return cast(arrow, Note).strumTime;

		return 0;
	}

	public function getHoldSubdivitions():Int
	{
		return Std.int(Math.max(1, Options?.hold_subs ?? 1));
	}
	public function getDefaultReceptorX(lane:Int, field:Int):Float
	{
        @:privateAccess
		return PlayState.instance.strumLines.members[field].startingPos.x + ((Manager.ARROW_SIZE) * lane);
	}
	public function getDefaultReceptorY(lane:Int, field:Int):Float
	{
        @:privateAccess
		return PlayState.instance.strumLines.members[field].startingPos.y;
	}

    public function getArrowCamera():Array<FlxCamera>
        return [PlayState.instance.camHUD];

    public function getCurrentScrollSpeed():Float
    {
        return PlayState.instance.scrollSpeed;
    }

    // 0 receptors
    // 1 tap arrows
    // 2 hold arrows
    public function getArrowItems()
    {
        var pspr:Array<Array<Array<FlxSprite>>> = [];

        for (i in 0...PlayState.instance.strumLines.members.length)
        {
            final sl = PlayState.instance.strumLines.members[i];

            pspr[i] = [];
            pspr[i][0] = cast sl.members.copy();
            pspr[i][1] = [];
            pspr[i][2] = [];

            sl.notes.forEachAlive((spr) -> pspr[i][spr.isSustainNote ? 2 : 1].push(spr));
        }

        return pspr;
    }
}