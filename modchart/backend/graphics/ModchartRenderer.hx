package modchart.backend.graphics;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxSignal;
import flixel.util.FlxSort;
import haxe.ds.IntMap;
import haxe.ds.Vector;
import modchart.backend.graphics.renderers.*;
import openfl.display.BlendMode;

using StringTools;
using modchart.backend.util.SortUtil;
using modchart.backend.util.VectorUtil;

class ModchartRenderer {
	private var parent:Null<PlayField>;

	public var projection(get, never):ModchartPerspective;

	public var receptorRenderer:ArrowRenderer;
	public var arrowRenderer:ArrowRenderer;
	public var attachmentRenderer:ArrowRenderer;
	public var holdRenderer:HoldRenderer;
	public var pathRenderer:PathRenderer;

	public var onPreRender:FlxTypedSignal<ModchartRenderer->Void>;
	public var onPostRender:FlxTypedSignal<ModchartRenderer->Void>;

	function get_projection()
		return parent.projection;

	public function new(parent:PlayField) {
		this.parent = parent;

		receptorRenderer = new ArrowRenderer(parent);
		arrowRenderer = new ArrowRenderer(parent);
		attachmentRenderer = new ArrowRenderer(parent);

		holdRenderer = new HoldRenderer(parent);
		pathRenderer = new PathRenderer(parent);

		onPreRender = new FlxTypedSignal<ModchartRenderer->Void>();
		onPostRender = new FlxTypedSignal<ModchartRenderer->Void>();
	}

	var queue:Vector<DrawCommand>;
	var count:Int = 0;

	public function alloc(n:Int) {
		queue = new Vector<DrawCommand>(n);
		count = 0;
	}

	public function emitArrowCmd(item:FlxSprite) {
		final dc = arrowRenderer.prepare(item);
		if (dc != null)
			dc.zIndex = Std.int(item._z * 1000);
		return dc;
	}

	public function emitHoldCmd(item:FlxSprite) {
		final dc = holdRenderer.prepare(item);
		if (dc != null)
			dc.zIndex = Std.int(item._z * 1000);
		return dc;
	}

	public function emitPathCmd(item:FlxSprite) {
		final dc = pathRenderer.prepare(item);
		if (dc != null)
			dc.zIndex = Std.int(item._z * 1000);
		return dc;
	}

	var emptyVec:openfl.Vector<Int> = new openfl.Vector<Int>(8, true, [for (i in 0...8) 0]);

	public function emit(items:Array<Array<Array<FlxSprite>>>) {
		// used for preallocate
		var receptorLength = 0;
		var arrowLength = 0;
		var holdLength = 0;
		var attachmentLength = 0;

		for (i in 0...items.length) {
			final curItems = items[i];

			if (curItems == null || curItems.length == 0)
				continue;

			if (curItems[0] != null)
				receptorLength = receptorLength + curItems[0].length;
			if (curItems[1] != null)
				arrowLength = arrowLength + curItems[1].length;
			if (curItems[2] != null)
				holdLength = holdLength + curItems[2].length;
			if (curItems[3] != null)
				attachmentLength = attachmentLength + curItems[3].length;
		}

		alloc(arrowLength + receptorLength + attachmentLength + holdLength);

		// i is player index
		for (i in 0...items.length) {
			var curItems:Array<Array<FlxSprite>> = items[i];

			if (curItems == null || curItems.length == 0)
				continue;

			final drawHolds = () -> {
				if (holdLength > 0) {
					for (hold in curItems[2]) {
						if (!getVisibility(hold))
							continue;
						var _ = emitHoldCmd(hold);
						if (_ != null)
							this.append(_);
					}
				}
			};

			// holds (behind strums)
			if (Config.HOLDS_BEHIND_STRUM)
				drawHolds();

			// receptors
			if (receptorLength > 0) {
				for (receptor in curItems[0]) {
					if (!getVisibility(receptor))
						continue;

					var _ = emitArrowCmd(receptor);
					if (_ != null)
						this.append(_);
				}
			}

			// holds (infront of strums)
			if (!Config.HOLDS_BEHIND_STRUM)
				drawHolds();

			// tap arrow
			if (arrowLength > 0) {
				for (arrow in curItems[1]) {
					if (!getVisibility(arrow))
						continue;

					var _ = emitArrowCmd(arrow);
					if (_ != null)
						this.append(_);
				}
			}

			// attachments (splashes)
			if (attachmentLength > 0) {
				for (attachment in curItems[3]) {
					if (!getVisibility(attachment))
						continue;

					var _ = emitArrowCmd(attachment);

					if (_ != null)
						this.append(_);
				}
			}
		}

		queue.nullSort((a, b) -> return b.zIndex - a.zIndex);

		var i = 0;
		while (i < count) {
			var item = queue[i];
			for (camera in item.cameras) {
				var dc = camera.startTrianglesBatch(item.graphic, item.antialiasing, item.isColored, item.blend, item.hasColorOffsets, item.shader);
				@:privateAccess final cameraBounds = camera._bounds.set(camera.viewMarginLeft, camera.viewMarginTop, camera.viewWidth, camera.viewHeight);

				if (item.color != null)
					dc.addTriangles(item.vertices.toFloatFlash(), item.indices.toIntFlash(), item.uvs.toFloatFlash(), emptyVec, null, cameraBounds, item.color);
				else if (item.colors != null)
					dc.addGradientTriangles(item.vertices.toFloatFlash(), item.indices.toIntFlash(), item.uvs.toFloatFlash(), null, cameraBounds, item.colors);
			}
			i++;
		}
	}

	public function append(dc:DrawCommand)
		queue[count++] = dc;

	private function getVisibility(obj:flixel.FlxObject) {
		@:bypassAccessor obj.visible = false;
		return obj._fmVisible;
	}

	public function dispose() {}
}
