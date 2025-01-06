import modchart.Manager;

var m:Manager;

function postCreate()
{
	m = new Manager(PlayState.instance);
	m.HOLD_SUBDIVITIONS = 4;
	m.renderArrowPaths = true;
	add(m);

	m.setPercent('orient', 1);
	m.setPercent('arrowPathThickness', 2);

	m.addModifier('transform');
	m.addModifier('tornado');
	m.addModifier('beat');
	m.addModifier('drunk');
	m.addModifier('bumpy');
	m.addModifier('tipsy');
	m.addModifier('scale');
	m.addModifier('opponentSwap');
	m.addModifier('vibrate');
	m.addModifier('infinite');
	m.addModifier('centerRotate');
	m.addModifier('rotate');

	player.cpu = true;
	m.setPercent('bumpyPeriod', 5);
	m.setPercent('infinite', 1);

	// setup();
}
var patt = [0, 1, 2, 3, 4, 5, 6, 7, 7.5];
var t = 1;
function setup()
{
	m.setPercent('bumpyPeriod', 5);

	m.ease('opponentSwap', 0, 16, 0.5, FlxEase.cubeOut);
	m.ease('xOffset', 0, 16, -1000, FlxEase.cubeOut, 0);
	m.ease('alpha', 0, 16, 0, FlxEase.cubeOut, 0);

	m.ease('bumpy', 0, 16, 10, FlxEase.quintIn);
	m.ease('scrollSpeed', 14, 2, 2, FlxEase.quintOut);
	m.ease('beatZ', 0, 16, 1, FlxEase.cubeOut);
	m.ease('scrollSpeed', 15.75, .25, 0);

	m.ease('scale', 15, .25, 3, FlxEase.cubeOut);
	m.ease('bumpy', 15, .25, 3, FlxEase.cubeOut);
	m.ease('scale', 15.5, .25, 1, FlxEase.cubeOut);
	m.ease('bumpy', 15.5, .25, 0, FlxEase.cubeOut);
	m.ease('z', 15.5, .25, -100, FlxEase.cubeOut);
	m.ease('z', 15.75, .25, 0, FlxEase.cubeOut);

	m.ease('bumpyPeriod', 16, 2, 2);
	m.ease('bumpyX', 16, 2, 1);

	m.ease('centerRotateY', 16, 2, 360 * 2, FlxEase.quartOut);
	m.ease('bumpy', 16, 1, 10, FlxEase.quartOut);
	m.set('bumpy', 16 + 2, 0);
	m.set('centerRotateY', 16 + 2, 0);

	for (x in 0...4)
	{
		t = 1;

		for (j in patt)
		{
			var i = 16 + j + 8 * x;

			m.set('bumpyY', i, t * 2);
			m.ease('bumpyY', i, 2, 0, FlxEase.quartOut);
			m.set('tipsy', i, t);
			m.ease('tipsy', i, 2, 0, FlxEase.quartOut);
			m.set('x', i, 50 * t);
			m.ease('x', i, 2, 0, FlxEase.quartOut);
			m.set('tiny', i, -t * 0.25);
			m.ease('tiny', i, 2, 0, FlxEase.quartOut);

			t *= -1;
		}
	}

	m.ease('centerRotateX', 16 + 4, 2, 360 - 80, FlxEase.quartOut);
	m.ease('centerRotateX', 22, 2, 0, FlxEase.quartOut);
	m.ease('centerRotateZ', 24, 1, 25, FlxEase.quartOut);
	m.ease('centerRotateZ', 25, 1, -25, FlxEase.quartOut);
	m.ease('centerRotateZ', 26, 0.5, 25, FlxEase.quartOut);
	m.ease('reverse', 26.5, 0.5, 1, FlxEase.quartOut);
	m.ease('centerRotateZ', 26.5, 0.5, -25, FlxEase.quartOut);
	m.ease('centerRotateZ', 27, 0.5, 25, FlxEase.quartOut);
	m.ease('centerRotateZ', 27.5, 0.5, 0, FlxEase.quartOut);
	m.ease('reverse', 27.5, 0.5, 0, FlxEase.quartOut);

	m.ease('invert', 28, 1, 1, FlxEase.quartOut);

	m.ease('invert', 29, 1, 0, FlxEase.quartOut);
	m.ease('flip', 29, 1, 1, FlxEase.quartOut);

	m.ease('invert', 30, 1, -0.75, FlxEase.quartOut);
	m.ease('flip', 30, 1, 0.25, FlxEase.quartOut);

	m.ease('invert', 30.5, .5, 0.75, FlxEase.quartOut);
	m.ease('flip', 30.5, .5, 0.75, FlxEase.quartOut);

	m.ease('invert', 31, .5, 0, FlxEase.quartOut);
	m.ease('flip', 31, .5, 0.5, FlxEase.quartOut);
	
	m.ease('flip', 31.5, .5, 0, FlxEase.quartOut);
	m.ease('drunk', 31.5, .5, 1, FlxEase.quartOut);
	m.ease('vibrate', 31.5, .5, 2, FlxEase.quartOut);
	m.ease('scale', 31.5, .5, 2.5, FlxEase.quartOut);

	m.ease('flip', 32, .25, 0, FlxEase.quartOut);
	m.ease('vibrate', 32, .25, 0, FlxEase.quartOut);
	m.ease('scale', 32, .25, 1, FlxEase.quartOut);

	m.ease('bumpyX', 32, .25, 0, FlxEase.quartOut);
	m.ease('drunk', 32, .25, 1, FlxEase.quartOut);
}