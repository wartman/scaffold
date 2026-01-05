package scaffold;

import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;

class ClassTypes {
	public static function getTypeParamDecls(type:ClassType):Array<TypeParamDecl> {
		return type.params.map(p -> ({
			name: p.name,
			constraints: switch p.t {
				case TInst(ref, _): switch ref.get().kind {
						case KTypeParameter(constraints): constraints.map(t -> t.toComplexType());
						default: [];
					}
				default: [];
			}
		} : TypeParamDecl));
	}
}
