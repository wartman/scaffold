package scaffold.step;

import haxe.ds.Option;
import haxe.macro.Expr;

using Scaffold;

typedef ConstructorBuildStepOptions = {
	public final ?children:Array<BuildStep>;
	public final ?privateConstructor:Bool;
	public final ?customParser:(options:{
		context:BuildContext,
		props:ComplexType,
		previousExpr:Option<Expr>,
		hasInits:Bool,
		inits:Expr,
		hasLateInits:Bool,
		lateInits:Expr
	}) -> Function;
}

typedef ConstructorBuildHookProp = {
	public final name:String;
	public final type:ComplexType;
	public final ?doc:String;
	public final optional:Bool;
}

class ConstructorBuildHook {
	var exprs:Array<Expr> = [];
	var props:Array<Field> = [];

	public function new() {}

	public function addExpr(...newExprs:Expr) {
		exprs = exprs.concat(newExprs);
		return this;
	}

	public function addProp(...newProps:ConstructorBuildHookProp) {
		var pos = (macro null).pos;
		var fields:Array<Field> = newProps.toArray().map(f -> ({
			name: f.name,
			kind: FVar(f.type),
			doc: f.doc,
			meta: f.optional ? [{name: ':optional', pos: pos}] : [],
			pos: pos
		} : Field));
		props = props.concat(fields);
		return this;
	}

	public function getExprs() {
		return exprs;
	}

	public function getProps() {
		return props;
	}
}

class ConstructorBuildStep extends BuildStep {
	public final init = new ConstructorBuildHook();
	public final late = new ConstructorBuildHook();

	final options:ConstructorBuildStepOptions;

	public function new(?options) {
		this.options = options ?? {};
	}

	public function steps():Array<BuildStep> {
		return options.children ?? [];
	}

	function apply(context:BuildContext) {
		var props = init.getProps().concat(late.getProps());
		var inits = init.getExprs();
		var lateInits = late.getExprs();
		var propsType:ComplexType = TAnonymous(props);
		var currentConstructor = context.fields.get('new');
		var previousConstructorExpr:Option<Expr> = switch currentConstructor {
			case Some(field): switch field.kind {
					case FFun(f):
						if (f.args.length > 0) {
							field.pos.error(
								'You cannot pass arguments to this constructor -- it can only'
								+ ' be used to run code at initialization.'
							);
						}

						if (options.privateConstructor == true && field.access.contains(APublic)) {
							field.pos.error('Constructor must be private (remove the `public` keyword)');
						}

						Some(f.expr);
					default:
						throw 'assert';
				}
			case None:
				None;
		}
		var func:Function = switch options.customParser {
			case null:
				(macro function(props:$propsType) {
					@:mergeBlock $b{inits};
					@:mergeBlock $b{lateInits};
					${switch previousConstructorExpr {
						case Some(expr): expr;
						case None: macro null;
					}}
				}).extractFunction();
			case custom:
				custom({
					context: context,
					props: propsType,
					previousExpr: previousConstructorExpr,
					hasInits: inits.length > 0,
					inits: macro @:mergeBlock $b{inits},
					hasLateInits: lateInits.length > 0,
					lateInits: macro @:mergeBlock $b{lateInits},
				});
		}

		switch currentConstructor {
			case Some(field):
				field.kind = FFun(func);
			case None:
				context.fields.addField({
					name: 'new',
					access: if (options.privateConstructor) [APrivate] else [APublic],
					kind: FFun(func),
					pos: (macro null).pos
				});
		}
	}
}
