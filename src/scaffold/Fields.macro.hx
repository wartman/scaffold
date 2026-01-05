package scaffold;

import haxe.macro.Expr;

class Fields {
	public static function at(field:Field, pos:Position) {
		field.pos = pos;
		return field;
	}

	public static function applyParameters(field:Field, params:Array<TypeParamDecl>) {
		switch field.kind {
			case FFun(f):
				f.params = params;
			default:
				// todo
		}
		return field;
	}
}
