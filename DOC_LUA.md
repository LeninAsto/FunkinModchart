## Modcharting Functions Only for Psych and PSlice
```lua
/* `instance` = the FunkinModchart Manager instance. */

/* Manager Section */
/*
 * Initializes the FunkinModchart Manager.
 * Must be called before using any other modchart function.
*/
addManager();

/* Modifiers Section */
/*
 * Adds a modifier to all playfields or a specific one.
 *
 * name:String  The modifier name string.
 * field:Int    The playfield number (-1 by default, applies to all).
*/
addModifier(name, field);
/*
 * Sets the percent for a specific modifier for all playfields or a specific one.
 *
 * name:String  The modifier name string.
 * value:Float  The percent value to set.
 * player:Int   The player to target (-1 by default, applies to all).
 * field:Int    The playfield number (-1 by default, applies to all).
*/
setPercent(name, value, player, field);
/*
 * Gets the percent for a specific modifier.
 *
 * name:String  The modifier name string.
 * player:Int   The player to target (0 by default).
 * field:Int    The playfield number (0 by default).
 *
 * returns: Float
*/
getPercent(name, player, field);
/*
 * Configures a modchart option.
 *
 * key:String    The config key. Available keys:
 *               "columnspecificmodifiers", "optimizeholds",
 *               "renderpaths", "holdsbehindstrum", "zscale".
 * value:Dynamic The value to assign to the config key.
*/
setConfig(key, value);
/*
 * Sets the number of subdivisions used to render hold arrows.
 *
 * value:Int  The number of subdivisions.
*/
setHoldSubdivisions(value);
/*
 * Returns the current number of hold subdivisions.
 *
 * returns: Int
*/
getHoldSubdivisions();

/* Events Section */
/*
 * Sets a specific modifier value at a certain beat.
 * The first argument can also be a table of modifiers: { modName = value, ... }
 *
 * name:String  The modifier name string.
 * beat:Float   The beat number where the event will be executed.
 * value:Float  The value to set.
 * player:Int   The player/strumline number (-1 by default).
 * field:Int    The playfield number (-1 by default).
*/
set(name, beat, value, player, field);
/*
 * Applies easing to a modifier from its current value to `value`
   over the specified duration.
 * The first argument can also be a table of modifiers: { modName = value, ... }
 *
 * name:String   The modifier name string.
 * beat:Float    The beat number where the easing starts.
 * length:Float  The tween duration in beats.
 * value:Float   The target value after easing.
 * ease:String   The ease function name (e.g. "linear", "quadIn").
 * player:Int    The player/strumline number (-1 by default).
 * field:Int     The playfield number (-1 by default).
*/
ease(name, beat, length, value, ease, player, field);
/*
 * Tweens a modifier by adding `value` to its current value over the specified duration.
 * The first argument can also be a table of modifiers: { modName = value, ... }
 *
 * name:String   The modifier name string.
 * beat:Float    The beat number where the easing starts.
 * length:Float  The tween duration in beats.
 * value:Float   The value to add after easing.
 * ease:String   The ease function name (e.g. "linear", "quadIn").
 * player:Int    The player/strumline number (-1 by default).
 * field:Int     The playfield number (-1 by default).
*/
add(name, beat, length, value, ease, player, field);
/*
 * Sets a modifier to (current percent + value) at a certain beat.
 * The first argument can also be a table of modifiers: { modName = value, ... }
 *
 * name:String  The modifier name string.
 * beat:Float   The beat number where the event will be executed.
 * value:Float  The value to add to the current percent.
 * player:Int   The player/strumline number (-1 by default).
 * field:Int    The playfield number (-1 by default).
*/
setAdd(name, beat, value, player, field);
/*
 * Same as `set` but uses the current beat automatically.
 * The first argument can also be a table of modifiers: { modName = value, ... }
 *
 * name:String  The modifier name string.
 * value:Float  The value to set.
 * player:Int   The player/strumline number (-1 by default).
 * field:Int    The playfield number (-1 by default).
*/
setNow(name, value, player, field);
/*
 * Same as `ease` but uses the current beat automatically.
 * The first argument can also be a table of modifiers: { modName = value, ... }
 *
 * name:String   The modifier name string.
 * length:Float  The tween duration in beats.
 * value:Float   The target value after easing.
 * ease:String   The ease function name (e.g. "linear", "quadIn").
 * player:Int    The player/strumline number (-1 by default).
 * field:Int     The playfield number (-1 by default).
*/
easeNow(name, length, value, ease, player, field);
/*
 * Same as `add` but uses the current beat automatically.
 * The first argument can also be a table of modifiers: { modName = value, ... }
 *
 * name:String   The modifier name string.
 * length:Float  The tween duration in beats.
 * value:Float   The value to add after easing.
 * ease:String   The ease function name (e.g. "linear", "quadIn").
 * player:Int    The player/strumline number (-1 by default).
 * field:Int     The playfield number (-1 by default).
*/
addNow(name, length, value, ease, player, field);
/*
 * Same as `setAdd` but uses the current beat automatically.
 * The first argument can also be a table of modifiers: { modName = value, ... }
 *
 * name:String  The modifier name string.
 * value:Float  The value to add to the current percent.
 * player:Int   The player/strumline number (-1 by default).
 * field:Int    The playfield number (-1 by default).
*/
setAddNow(name, value, player, field);
/*
 * Executes the given Lua function when the specified beat is reached.
 *
 * beat:Float      The beat number where the event will be executed.
 * funcName:String The name of the Lua function to call.
 * field:Int       The playfield number (-1 by default).
*/
callback(beat, funcName, field);
/*
 * Same as `callback`. Schedules a Lua function to be called at the specified beat.
 *
 * beat:Float      The beat number where the event will be executed.
 * funcName:String The name of the Lua function to call.
 * field:Int       The playfield number (-1 by default).
*/
scheduleCallback(beat, funcName, field);
/*
 * Repeats the execution of the given Lua function for the specified duration,
   starting at the given beat.
 *
 * beat:Float      The beat number where the repeater starts.
 * length:Float    The repeater duration in beats.
 * funcName:String The name of the Lua function to call on each repeat.
 * field:Int       The playfield number (-1 by default).
*/
repeater(beat, length, funcName, field);
/*
 * Creates an alias for a given modifier.
 *
 * name:String      The original modifier name.
 * aliasName:String The alias name.
 * field:Int        The playfield number (-1 by default).
*/
alias(name, aliasName, field);

/* Playfield Section */
/*
 * Creates and adds a new playfield to the Manager.
 *
 * WARNING: If you add a playfield after adding modifiers, you will have to add them again to the new playfield.
*/
addPlayfield();

/* Info Section */
/*
 * Returns the current beat based on song position.
 *
 * returns: Float
*/
getCurrentBeat();
/*
 * Returns the current step based on song position.
 *
 * returns: Float
*/
getCurrentStep();
/*
 * Returns the current song position in milliseconds.
 *
 * returns: Float
*/
getSongPosition();
/*
 * Returns the current BPM.
 *
 * returns: Float
*/
getBPM();
/*
 * Returns the number of players in the current play state.
 *
 * returns: Int
*/
getPlayerCount();
/*
 * Returns the hold arrow size constant.
 *
 * returns: Float
*/
getHoldSize();
/*
 * Returns half the hold arrow size constant.
 *
 * returns: Float
*/
getHoldSizeDiv2();
/*
 * Returns the tap arrow size constant.
 *
 * returns: Float
*/
getArrowSize();
/*
 * Returns half the tap arrow size constant.
 *
 * returns: Float
*/
getArrowSizeDiv2();
/*
 * Returns the notes from a given chart.
 * Each note entry contains: { step:Float, type:Int, time:Float }
 *
 * chartName:String The chart difficulty name (e.g. "hard").
 * songName:String  The song folder name. Uses the current song if not provided.
 *
 * returns: Array<{ step:Float, type:Int, time:Float }>
*/
getChartNotes(chartName, songName);
```