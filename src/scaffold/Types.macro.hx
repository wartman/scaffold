package scaffold;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.crypto.Md5;

using StringTools;
using haxe.macro.Tools;

class Types {
	public static function unify(type:Type, other:Type):Bool {
		return Context.unify(type, other);
	}

	// @todo: This is not correct and cannot deal with sub paths. Also only works
	// on Class builds.
	public static function toTypePath(type:Type):TypePathBuilder {
		var cls = type.getClass();
		return ({
			pack: cls.pack,
			name: cls.name
		} : TypePath);
	}

	public static function toClassName(type:Type):String {
		return switch type {
			// Attempt to use human-readable names if possible
			case TInst(_, []) | TEnum(_, []) | TAbstract(_, []):
				type.toString().replace('.', '_');
			case TInst(_.toString() => name, params) | TAbstract(_.toString() => name, params) | TEnum(_.toString() => name, params):
				name.replace('.', '_') + '__' + params
					.map(param -> toClassName(param))
					.join('__');
			case TLazy(f):
				toClassName(f());
			default:
				// Fallback to using a hash.
				Md5.encode(type.toString());
		}
	}
}
