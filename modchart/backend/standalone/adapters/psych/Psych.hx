package modchart.backend.standalone.adapters.psych;

#if (FM_ENGINE_VERSION == "1.0" || FM_ENGINE_VERSION == "0.7")
import backend.ClientPrefs;
import backend.Conductor;
import objects.Note;
import objects.NoteSplash;
import objects.StrumNote as Strum;
import states.PlayState;
#if LUA_ALLOWED
import backend.Song;
import llua.Lua.Lua_helper;
import psychlua.FunkinLua;
import psychlua.LuaUtils;
#end
#else
import ClientPrefs;
import Conductor;
import Note;
import PlayState;
import StrumNote as Strum;
#if LUA_ALLOWED
import FunkinLua;
import LuaUtils;
import Song;
import llua.Lua.Lua_helper;
#end
#end
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import modchart.Manager;
import modchart.backend.standalone.IAdapter;

class Psych implements IAdapter {
	private var __fCrochet:Float = 0;
	private var __holdSubdivisions:Int = 4;

	public function new() {
		try {
			setupLuaFunctions();
		} catch (e) {
			trace('[FunkinModchart Psych Adapter] Failed while adding lua functions: $e');
		}
	}

	public function onModchartingDispose() {}

	public function onModchartingInitialization() {
		__fCrochet = (Conductor.crochet + 8) / 4;
	}

	private function setupLuaFunctions() {
		#if LUA_ALLOWED
		final luaArray = PlayState.instance?.luaArray;
		if (luaArray == null || luaArray.length == 0) return;
		for (funkinLua in luaArray) {
			@:privateAccess final lua = funkinLua.lua;
			final _fl = funkinLua;
			if (lua == null) continue;

			Lua_helper.add_callback(lua, 'addManager', function() {
				if (Manager.instance == null)
					Manager.instance = new Manager();
			});

			Lua_helper.add_callback(lua, 'setPercent', function(name:String, value:Float, ?player:Int = -1, ?field:Int = -1) {
				if (Manager.instance != null)
					Manager.instance.setPercent(name, value, player, field);
			});
			Lua_helper.add_callback(lua, 'getPercent', function(name:String, ?player:Int = 0, ?field:Int = 0):Float {
				if (Manager.instance != null)
					return Manager.instance.getPercent(name, player, field);
				return 0.;
			});
			Lua_helper.add_callback(lua, 'addModifier', function(name:String, ?field:Int = -1) {
				if (Manager.instance != null)
					Manager.instance.addModifier(name, field);
			});
			Lua_helper.add_callback(lua, 'setHoldSubdivisions', function(value:Int) {
				setHoldSubdivisions(value);
			});
			Lua_helper.add_callback(lua, 'getHoldSubdivisions', function():Int {
				return getHoldSubdivisions(null);
			});
			Lua_helper.add_callback(lua, 'setConfig', function(key:String, value:Dynamic) {
				switch (key.toLowerCase()) {
					case 'columnspecificmodifiers': Config.COLUMN_SPECIFIC_MODIFIERS = value;
					case 'optimizeholds': Config.OPTIMIZE_HOLDS = value;
					case 'renderpaths': Config.RENDER_ARROW_PATHS = value;
					case 'holdsbehindstrum': Config.HOLDS_BEHIND_STRUM = value;
					case 'zscale': Config.Z_SCALE = value;
				}
			});

			// Set modifier value at a specific beat
			Lua_helper.add_callback(lua, 'set', function(nameOrMods:Dynamic, beat:Float, ?value:Dynamic, ?player:Int = -1, ?field:Int = -1) {
				if (Manager.instance == null)
					return;
				if (Std.isOfType(nameOrMods, String)) {
					Manager.instance.set(cast nameOrMods, beat, cast value, player, field);
				} else {
					final actualPlayer:Int = value != null ? Std.int(cast value) : -1;
					final actualField:Int = player;
					for (modName in Reflect.fields(nameOrMods))
						Manager.instance.set(modName, beat, Reflect.field(nameOrMods, modName), actualPlayer, actualField);
				}
			});

			// Ease modifier to value over length beats
			Lua_helper.add_callback(lua, 'ease', function(nameOrMods:Dynamic, beat:Float, length:Float, ?value:Dynamic, ?easeName:String, ?player:Int = -1, ?field:Int = -1) {
				if (Manager.instance == null)
					return;
				if (Std.isOfType(nameOrMods, String)) {
					Manager.instance.ease(cast nameOrMods, beat, length, cast value, __getEase(easeName), player, field);
				} else {
					final actualEaseName:String = cast value;
					final actualPlayer:Int = easeName != null ? Std.parseInt(easeName) : -1;
					final actualField:Int = player;
					for (modName in Reflect.fields(nameOrMods))
						Manager.instance.ease(modName, beat, length, Reflect.field(nameOrMods, modName), __getEase(actualEaseName), actualPlayer, actualField);
				}
			});

			// Add modifier value with easing over length beats
			Lua_helper.add_callback(lua, 'add', function(nameOrMods:Dynamic, beat:Float, length:Float, ?value:Dynamic, ?easeName:String, ?player:Int = -1, ?field:Int = -1) {
				if (Manager.instance == null)
					return;
				if (Std.isOfType(nameOrMods, String)) {
					Manager.instance.add(cast nameOrMods, beat, length, cast value, __getEase(easeName), player, field);
				} else {
					final actualEaseName:String = cast value;
					final actualPlayer:Int = easeName != null ? Std.parseInt(easeName) : -1;
					final actualField:Int = player;
					for (modName in Reflect.fields(nameOrMods))
						Manager.instance.add(modName, beat, length, Reflect.field(nameOrMods, modName), __getEase(actualEaseName), actualPlayer, actualField);
				}
			});

			// Set modifier to (current + value) at a specific beat
			Lua_helper.add_callback(lua, 'setAdd', function(nameOrMods:Dynamic, beat:Float, ?value:Dynamic, ?player:Int = -1, ?field:Int = -1) {
				if (Manager.instance == null)
					return;
				if (Std.isOfType(nameOrMods, String)) {
					Manager.instance.setAdd(cast nameOrMods, beat, cast value, player, field);
				} else {
					final actualPlayer:Int = value != null ? Std.int(cast value) : -1;
					final actualField:Int = player;
					for (modName in Reflect.fields(nameOrMods))
						Manager.instance.setAdd(modName, beat, Reflect.field(nameOrMods, modName), actualPlayer, actualField);
				}
			});

			// --- "Now" variants: use current beat automatically ---
			Lua_helper.add_callback(lua, 'setNow', function(nameOrMods:Dynamic, ?value:Dynamic, ?player:Int = -1, ?field:Int = -1) {
				if (Manager.instance == null)
					return;
				final beat:Float = Conductor.songPosition / Conductor.crochet;
				if (Std.isOfType(nameOrMods, String)) {
					Manager.instance.set(cast nameOrMods, beat, cast value, player, field);
				} else {
					final actualPlayer:Int = value != null ? Std.int(cast value) : -1;
					final actualField:Int = player;
					for (modName in Reflect.fields(nameOrMods))
						Manager.instance.set(modName, beat, Reflect.field(nameOrMods, modName), actualPlayer, actualField);
				}
			});

			Lua_helper.add_callback(lua, 'easeNow', function(nameOrMods:Dynamic, length:Float, ?value:Dynamic, ?easeName:String, ?player:Int = -1, ?field:Int = -1) {
				if (Manager.instance == null)
					return;
				final beat:Float = Conductor.songPosition / Conductor.crochet;
				if (Std.isOfType(nameOrMods, String)) {
					Manager.instance.ease(cast nameOrMods, beat, length, cast value, __getEase(easeName), player, field);
				} else {
					final actualEaseName:String = cast value;
					final actualPlayer:Int = easeName != null ? Std.parseInt(easeName) : -1;
					final actualField:Int = player;
					for (modName in Reflect.fields(nameOrMods))
						Manager.instance.ease(modName, beat, length, Reflect.field(nameOrMods, modName), __getEase(actualEaseName), actualPlayer, actualField);
				}
			});

			Lua_helper.add_callback(lua, 'addNow', function(nameOrMods:Dynamic, length:Float, ?value:Dynamic, ?easeName:String, ?player:Int = -1, ?field:Int = -1) {
				if (Manager.instance == null)
					return;
				final beat:Float = Conductor.songPosition / Conductor.crochet;
				if (Std.isOfType(nameOrMods, String)) {
					Manager.instance.add(cast nameOrMods, beat, length, cast value, __getEase(easeName), player, field);
				} else {
					final actualEaseName:String = cast value;
					final actualPlayer:Int = easeName != null ? Std.parseInt(easeName) : -1;
					final actualField:Int = player;
					for (modName in Reflect.fields(nameOrMods))
						Manager.instance.add(modName, beat, length, Reflect.field(nameOrMods, modName), __getEase(actualEaseName), actualPlayer, actualField);
				}
			});

			Lua_helper.add_callback(lua, 'setAddNow', function(nameOrMods:Dynamic, ?value:Dynamic, ?player:Int = -1, ?field:Int = -1) {
				if (Manager.instance == null)
					return;
				final beat:Float = Conductor.songPosition / Conductor.crochet;
				if (Std.isOfType(nameOrMods, String)) {
					Manager.instance.setAdd(cast nameOrMods, beat, cast value, player, field);
				} else {
					final actualPlayer:Int = value != null ? Std.int(cast value) : -1;
					final actualField:Int = player;
					for (modName in Reflect.fields(nameOrMods))
						Manager.instance.setAdd(modName, beat, Reflect.field(nameOrMods, modName), actualPlayer, actualField);
				}
			});

			// --- Conductor helpers ---
			Lua_helper.add_callback(lua, 'getCurrentBeat', function():Float {
				return Conductor.songPosition / Conductor.crochet;
			});
			Lua_helper.add_callback(lua, 'getCurrentStep', function():Float {
				return Conductor.songPosition / Conductor.stepCrochet;
			});
			Lua_helper.add_callback(lua, 'getSongPosition', function():Float {
				return Conductor.songPosition;
			});
			Lua_helper.add_callback(lua, 'getBPM', function():Float {
				return Conductor.bpm;
			});

			// --- Manager size constants ---
			Lua_helper.add_callback(lua, 'getHoldSize', function():Float { return Manager.HOLD_SIZE; });
			Lua_helper.add_callback(lua, 'getHoldSizeDiv2', function():Float { return Manager.HOLD_SIZEDIV2; });
			Lua_helper.add_callback(lua, 'getArrowSize', function():Float { return Manager.ARROW_SIZE; });
			Lua_helper.add_callback(lua, 'getArrowSizeDiv2', function():Float { return Manager.ARROW_SIZEDIV2; });

			// --- Playfield helpers ---
			Lua_helper.add_callback(lua, 'getPlayerCount', function():Int {
				return getPlayerCount();
			});
			Lua_helper.add_callback(lua, 'addPlayfield', function() {
				if (Manager.instance != null)
					Manager.instance.addPlayfield();
			});
			Lua_helper.add_callback(lua, 'alias', function(name:String, aliasName:String, ?field:Int = -1) {
				if (Manager.instance != null)
					Manager.instance.alias(name, aliasName, field);
			});

			// --- Event scheduling ---
			Lua_helper.add_callback(lua, 'callback', function(beat:Float, funcName:String, ?field:Int = -1) {
				if (Manager.instance != null)
					Manager.instance.callback(beat, function(_) _fl.call(funcName, []), field);
			});
			Lua_helper.add_callback(lua, 'scheduleCallback', function(beat:Float, funcName:String, ?field:Int = -1) {
				if (Manager.instance != null)
					Manager.instance.scheduleCallback(beat, function(_) _fl.call(funcName, []), field);
			});
			Lua_helper.add_callback(lua, 'repeater', function(beat:Float, length:Float, funcName:String, ?field:Int = -1) {
				if (Manager.instance != null)
					Manager.instance.repeater(beat, length, function(_) _fl.call(funcName, []), field);
			});

			// --- Chart data ---
			Lua_helper.add_callback(lua, 'getChartNotes', function(chartName:String, ?songName:String):Dynamic {
				if (songName == null || songName.length == 0)
					songName = PlayState.SONG != null ? PlayState.SONG.song.toLowerCase() : '';
				var swagSong = Song.loadFromJson(chartName.toLowerCase(), songName.toLowerCase());
				if (swagSong == null)
					return null;
				var result:Array<Dynamic> = [];
				if (swagSong.notes != null) {
					for (section in swagSong.notes) {
						if (section == null || section.sectionNotes == null)
							continue;
						for (noteData in section.sectionNotes) {
							var time:Float = noteData[0];
							var type:Int = Std.int(noteData[1]) % 4;
							var step:Float = time / Conductor.stepCrochet;
							result.push({step: step, type: type, time: time});
						}
					}
				}
				result.sort(function(a, b) return a.step < b.step ? -1 : (a.step > b.step ? 1 : 0));
				return result;
			});
		}
		#end
	}

	public function isTapNote(sprite:FlxSprite) {
		return sprite is Note;
	}

	// Song related
	public function getSongPosition():Float {
		return Conductor.songPosition;
	}

	public function getCurrentBeat():Float {
		@:privateAccess
		return PlayState.instance.curDecBeat;
	}

	public function getCurrentCrochet():Float {
		return Conductor.crochet;
	}

	public function getBeatFromStep(step:Float)
		return step * .25;

	public function arrowHit(arrow:FlxSprite) {
		if (arrow is Note)
			return cast(arrow, Note).wasGoodHit;
		return false;
	}

	public function isHoldEnd(arrow:FlxSprite) {
		if (arrow is Note) {
			final castedNote = cast(arrow, Note);

			if (castedNote.nextNote != null)
				return !castedNote.nextNote.isSustainNote;
		}
		return false;
	}

	public function getLaneFromArrow(arrow:FlxSprite) {
		if (arrow is Note)
			return cast(arrow, Note).noteData;
		else if (arrow is Strum) @:privateAccess
			return cast(arrow, Strum).noteData;
		#if (FM_ENGINE_VERSION >= "1.0")
		if (arrow is NoteSplash) @:privateAccess
			return cast(arrow, NoteSplash).babyArrow.noteData;
		#end

		return 0;
	}

	public function getPlayerFromArrow(arrow:FlxSprite) {
		if (arrow is Note)
			return cast(arrow, Note).mustPress ? 1 : 0;
		if (arrow is Strum) @:privateAccess
			return cast(arrow, Strum).player;
		#if (FM_ENGINE_VERSION >= "1.0")
		if (arrow is NoteSplash) @:privateAccess
			return cast(arrow, NoteSplash).babyArrow.player;
		#end
		return 0;
	}

	public function getKeyCount(?player:Int = 0):Int {
		return 4;
	}

	public function getPlayerCount():Int {
		return 2;
	}

	public function getTimeFromArrow(arrow:FlxSprite) {
		if (arrow is Note)
			return cast(arrow, Note).strumTime;

		return 0;
	}

	public function getHoldSubdivisions(hold:FlxSprite):Int {
		return __holdSubdivisions;
	}

	public function setHoldSubdivisions(value:Int):Void {
		__holdSubdivisions = value;
	}

	public function getHoldLength(item:FlxSprite):Float
		return __fCrochet;

	public function getHoldParentTime(arrow:FlxSprite) {
		final note:Note = cast arrow;
		return note.parent.strumTime;
	}

	public function getDownscroll():Bool {
		#if (FM_ENGINE_VERSION >= "0.7")
		return ClientPrefs.data.downScroll;
		#else
		return ClientPrefs.downScroll;
		#end
	}

	inline function getStrumFromInfo(lane:Int, player:Int) {
		var group = player == 0 ? PlayState.instance.opponentStrums : PlayState.instance.playerStrums;
		var strum = null;
		group.forEach(str -> {
			@:privateAccess
			if (str.noteData == lane)
				strum = str;
		});
		return strum;
	}

	public function getDefaultReceptorX(lane:Int, player:Int):Float {
		return getStrumFromInfo(lane, player).x;
	}

	public function getDefaultReceptorY(lane:Int, player:Int):Float {
		return getDownscroll() ? FlxG.height - getStrumFromInfo(lane, player).y - Note.swagWidth : getStrumFromInfo(lane, player).y;
	}

	public function getArrowCamera():Array<FlxCamera>
		return [PlayState.instance.camHUD];

	public function getCurrentScrollSpeed():Float {
		return PlayState.instance.songSpeed * .45;
	}

	// 0 receptors
	// 1 tap arrows
	// 2 hold arrows
	public function getArrowItems() {
		var pspr:Array<Array<Array<FlxSprite>>> = [[[], [], [], []], [[], [], [], []]];

		@:privateAccess
		PlayState.instance.strumLineNotes.forEachAlive(strumNote -> {
			if (pspr[strumNote.player] == null)
				pspr[strumNote.player] = [];

			pspr[strumNote.player][0].push(strumNote);
		});
		PlayState.instance.notes.forEachAlive(strumNote -> {
			final player = Adapter.instance.getPlayerFromArrow(strumNote);
			if (pspr[player] == null)
				pspr[player] = [];

			pspr[player][strumNote.isSustainNote ? 2 : 1].push(strumNote);
		});
		#if (FM_ENGINE_VERSION >= "1.0")
		PlayState.instance.grpNoteSplashes.forEachAlive(splash -> {
			@:privateAccess
			if (splash.babyArrow != null && splash.active) {
				final player = splash.babyArrow.player;
				if (pspr[player] == null)
					pspr[player] = [];

				pspr[player][3].push(splash);
			}
		});
		#end

		return pspr;
	}

	#if LUA_ALLOWED
	private static inline function __getEase(name:String) {
		return LuaUtils.getTweenEaseByString(name);
	}
	#end
}
