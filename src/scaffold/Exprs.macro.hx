package scaffold;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;

class Exprs {
	public static function at(expr:Expr, pos:Position) {
		expr.pos = pos;
		return expr;
	}

	public static function replace(expr:Expr, def:ExprDef) {
		expr.expr = def;
		return expr;
	}

	public static inline function error(expr:Expr, message:String) {
		return Context.error(message, expr.pos);
	}

	public static function extractFunction(expr:Expr,):Function {
		return switch expr.expr {
			case EFunction(_, f): f;
			default: error(expr, 'Expected a function');
		}
	}

	public static function extractString(expr:Expr):String {
		return switch expr.expr {
			case EConst(CString(s, _)): s;
			default: error(expr, 'Expected a string');
		}
	}

	public static function extractInt(expr:Expr):Int {
		return switch expr.expr {
			case EConst(CInt(i)): Std.parseInt(i);
			default: error(expr, 'Expected a string');
		}
	}
}
