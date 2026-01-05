package scaffold;

import haxe.macro.Context;
import haxe.macro.Expr;

class Positions {
	public static function error(pos:Position, message:String) {
		return Context.error(message, pos);
	}
}
