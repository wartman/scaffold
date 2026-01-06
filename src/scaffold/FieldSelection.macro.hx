package scaffold;

import haxe.ds.Option;
import haxe.macro.Expr;

using Lambda;

@:forward(iterator)
abstract FieldSelection(Array<Field>) from Array<Field> {
	public function new(fields) {
		this = fields;
	}

	public inline function pick<T>(selector:(field:Field) -> Option<T>):Array<T> {
		var out:Array<T> = [];
		for (field in this) switch selector(field) {
			case Some(value): out.push(value);
			case None:
		}
		return out;
	}

	public inline function byMeta(name:String):FieldSelection {
		return this.filter(f -> f.meta.exists(m -> m.name == name));
	}

	public inline function byName(name:String):FieldSelection {
		return this.filter(f -> f.name == name);
	}

	public inline function apply(applicator:(field:Field) -> Void) {
		for (field in this) applicator(field);
		return abstract;
	}
}
