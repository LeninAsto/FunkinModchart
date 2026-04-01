package modchart.engine.modifiers.list;

import modchart.backend.core.ArrowData;
import modchart.backend.core.ModifierParameters;
import modchart.backend.core.VisualParameters;

class Scale extends Modifier {
	// Pre-computed IDs indexed by axisIdx (0='', 1='x', 2='y') to avoid Std.string(lane) allocations.
	static final AXES_S = ['', 'x', 'y'];

	var scaleIDs:Array<Int>;
	var scaleLaneIDs:Array<Array<Int>>;
	var tinyIDs:Array<Int>;
	var tinyLaneIDs:Array<Array<Int>>;

	public function new(pf) {
		super(pf);

		setPercent('scale', 1, -1);
		setPercent('scaleX', 1, -1);
		setPercent('scaleY', 1, -1);

		final maxKeys = 16;
		scaleIDs = [for (a in AXES_S) findID('scale' + a)];
		scaleLaneIDs = [for (a in AXES_S) [for (l in 0...maxKeys) findID('scale' + a + l)]];
		tinyIDs = [for (a in AXES_S) findID('tiny' + a)];
		tinyLaneIDs = [for (a in AXES_S) [for (l in 0...maxKeys) findID('tiny' + a + l)]];
	}

	// axisIdx: 0='' 1='x' 2='y'; realAxisIdx: 0=both 1=x 2=y
	private inline function applyScale(vis:VisualParameters, params:ModifierParameters, axisIdx:Int, realAxisIdx:Int) {
		final lane = params.lane;
		final player = params.player;

		var scaleV = getUnsafe(scaleIDs[axisIdx], player);
		var tinyV = getUnsafe(tinyIDs[axisIdx], player);
		if (Config.COLUMN_SPECIFIC_MODIFIERS) {
			scaleV += getUnsafe(scaleLaneIDs[axisIdx][lane], player);
			tinyV += getUnsafe(tinyLaneIDs[axisIdx][lane], player);
		}

		var scale = scaleV;
		scale *= 1 - tinyV * 0.5;

		if (realAxisIdx == 1) vis.scaleX *= scale;
		else if (realAxisIdx == 2) vis.scaleY *= scale;
		else { vis.scaleX *= scale; vis.scaleY *= scale; }
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters) {
		applyScale(data, params, 0, 0); // '' → both
		applyScale(data, params, 1, 1); // 'x' → x
		applyScale(data, params, 2, 2); // 'y' → y

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}