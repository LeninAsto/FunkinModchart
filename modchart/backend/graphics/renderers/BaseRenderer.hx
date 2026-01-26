package modchart.backend.graphics.renderers;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.util.FlxSignal;
import flixel.util.FlxSort;

@:allow(modchart.backend.graphics.ModchartRenderer)
class BaseRenderer<T:FlxBasic> extends FlxBasic {
	private var parent:Null<PlayField>;

	private var projection(get, never):ModchartPerspective;

	function get_projection()
		return parent.projection;

	public function new(parent:PlayField) {
		super();

		this.parent = parent;
	}

	// Renderer-side
	public function prepare(item:T):Null<DrawCommand> {
		return null;
	}
}
