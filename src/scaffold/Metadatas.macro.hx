package scaffold;

import haxe.ds.Option;
import haxe.macro.Expr;

using Lambda;
using scaffold.Positions;

class Metadatas {
	public static inline function get(metadata:Metadata, name:String):Option<MetadataEntry> {
		return switch metadata.find(entry -> entry.name == name) {
			case null: None;
			case value: Some(value);
		}
	}

	public static function options(metadata:Metadata, name:String, ?allowed:Array<String>) {
		return switch get(metadata, name) {
			case Some(metadata):
				function validate(name:String, pos:Position) {
					if (allowed == null) return;
					if (!allowed.contains(name)) pos.error('Invalid option');
				}

				var entires:Map<String, Expr> = [];

				for (expr in metadata.params) switch expr {
					case macro $nameExpr = $expr:
						var name = switch nameExpr.expr {
							case EConst(CIdent(s)) | EConst(CString(s, _)): s;
							default: nameExpr.pos.error('Expected an identifier or a string');
						}
						validate(name, nameExpr.pos);
						entires.set(name, expr);
					default:
						expr.pos.error('Invalid expression');
				}

				Some(entires);
			case None:
				None;
		}
	}
}
