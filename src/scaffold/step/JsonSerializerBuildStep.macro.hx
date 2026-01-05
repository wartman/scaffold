package scaffold.step;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.ds.Option;

using Lambda;
using haxe.macro.Tools;
using Scaffold;

typedef JsonSerializerBuildStepOptions = {
	public final ?constructorAccessor:Expr;
	public final ?returnType:ComplexType;
	public final ?customParser:(options:{
		name:String,
		type:ComplexType,
		parser:(access:Expr, name:String, t:ComplexType) -> JsonSerializerHook
	}) -> Option<JsonSerializerHook>;
}

typedef JsonSerializerHook = {
	public final serializer:Expr;
	public final deserializer:Expr;
}

class JsonSerializerBuildStep extends BuildStep {
	final options:JsonSerializerBuildStepOptions;

	public function new(?options) {
		this.options = options ?? {};
	}

	public function steps() return [];

	public function apply(context:BuildContext) {
		var constructor = switch findAncestorOfType(ConstructorBuildStep) {
			case Some(constructor):
				constructor;
			case None:
				Context.warning(
					'Attempting to use a JsonSerializerBuildStep outside of a ConstructorBuildStep.'
					+ ' This means that the BuildStep will have no effect, as it requires a ConstructorBuildStep'
					+ ' as a parent.',
					Context.currentPos()
				);
				return;
		}

		var ret = options.returnType ?? context.type.toComplexType();
		var fields = constructor.init.getProps();
		var serializer:Array<ObjectField> = [];
		var deserializer:Array<ObjectField> = [];

		for (field in fields) {
			var result = parseField(context, field);
			serializer.push({field: field.name, expr: result.serializer});
			deserializer.push({field: field.name, expr: result.deserializer});
		}

		var serializerExpr:Expr = {
			expr: EObjectDecl(serializer),
			pos: (macro null).pos
		};
		var deserializerExpr:Expr = {
			expr: EObjectDecl(deserializer),
			pos: (macro null).pos
		};

		var constructors = FieldCollection.ofTypeDefinition(switch options.constructorAccessor {
			case null:
				var clsTp = context.type.toTypePath();
				macro class {
					public static function fromJson(data:{}):$ret {
						return new $clsTp($deserializerExpr);
					}
				}
			case access:
				macro class {
					public static function fromJson(data:{}):$ret {
						return $access($deserializerExpr);
					}
				}
		});

		var clsParams = context.type.getClass().params.map(param -> ({
			name: param.name,
			constraints: switch param.t {
				case TInst(_, params): params.map(param -> param.toComplexType());
				default: [];
			}
		} : TypeParamDecl));
		var fromJson = (switch constructors.get('fromJson') {
			case Some(value): value;
			case None: throw 'assert';
		}).applyParameters(clsParams);

		context.fields
			.addField(fromJson)
			.add(macro class {
				public function toJson():Dynamic {
					return $serializerExpr;
				}
			});
	}

	function parseField(context:BuildContext, prop:Field):JsonSerializerHook {
		var field = switch context.fields.get(prop.name) {
			case Some(value): value;
			case None: prop;
		}
		var def = switch field.kind {
			case FVar(_, e) if (e != null): e;
			default: macro null;
		}

		return switch field.kind {
			case FVar(t, _) | FProp(_, _, t):
				var meta = switch field.meta.get(':json') {
					case Some(value): value;
					case None: null;
				}
				var name = field.name;
				var pos = field.pos;
				var access:Expr = macro this.$name;

				if (meta != null) return switch meta.params {
					case [macro to = ${to}, macro from = ${from}] | [macro from = ${from}, macro to = ${to}]:
						var serializer = macro {
							var value = $access;
							if (value == null) {
								null;
							} else {
								$to;
							}
						};
						var deserializer = switch t {
							case macro :Array<$_>:
								macro {
									var value:Array<Dynamic> = Reflect.field(data, $v{name});
									if (value == null) value = [];
									$from;
								};
							default:
								macro {
									var value:Dynamic = Reflect.field(data, $v{name});
									if (value == null) {
										$def;
									} else {
										${from};
									}
								};
						}

						{
							serializer: serializer,
							deserializer: deserializer
						};
					case []:
						Context.error('There is no need to mark fields with @:json unless you are defining how they should serialize/unserialize', meta.pos);
					default:
						Context.error('Invalid arguments', meta.pos);
				}

				if (options.customParser != null) switch options.customParser({
					name: name,
					type: t,
					parser: (access, name, t) -> parseExpr(access, name, t, pos)
				}) {
					case Some(hook): return hook;
					case None:
				}

				return parseExpr(macro this.$name, name, t, pos);
			default:
				Context.error('Invalid field for json serialization', field.pos);
		}
	}

	// @todo: keep working on this method
	function parseExpr(access:Expr, name:String, t:ComplexType, pos:Position):JsonSerializerHook {
		return switch t {
			case macro :Dynamic:
				{
					serializer: access,
					deserializer: macro Reflect.field(data, $v{name})
				};
			case t if (isScalar(t)):
				{
					serializer: access,
					deserializer: macro Reflect.field(data, $v{name})
				};
			case macro :Null<$t>:
				var path = switch t {
					case TPath(p): TypePathBuilder.of(p).toArray();
					default: Context.error('Could not resolve type', pos);
				}

				{
					serializer: macro @:pos(pos) $access?.toJson(),
					deserializer: macro {
						var value:Dynamic = Reflect.field(data, $v{name});
						if (value == null) {
							null;
						} else {
							@:pos(pos) $p{path}.fromJson(value);
						}
					}
				};
			case macro :Array<$t>:
				var path = switch t {
					case TPath(p): TypePathBuilder.of(p).toArray();
					default: Context.error('Could not resolve type', pos);
				}

				{
					serializer: macro $access.map(item -> @:pos(pos) item.toJson()),
					deserializer: macro {
						var values:Array<Dynamic> = Reflect.field(data, $v{name});
						if (values == null) {
							[];
						} else {
							values.map(@:pos(pos) $p{path}.fromJson);
						}
					}
				};
			default:
				var path = switch t {
					case TPath(p): TypePathBuilder.of(p).toArray();
					default: Context.error('Could not resolve type', pos);
				}

				{
					serializer: macro @:pos(pos) $access?.toJson(),
					deserializer: macro {
						var value:Dynamic = Reflect.field(data, $v{name});
						@:pos(pos) $p{path}.fromJson(value);
					}
				}
		}
	}

	// @todo: Find a more elegant way to do this?
	function isScalar(type:ComplexType) {
		return switch type {
			case macro :String: true;
			case macro :Int: true;
			case macro :Float: true;
			case macro :Bool: true;
			case macro :Array<$t>: isScalar(t);
			case macro :Null<$t>: isScalar(t);
			default:
				var t = type.toType();
				if (Context.unify(t, Context.getType('String'))) {
					return true;
				}
				if (Context.unify(t, Context.getType('Int'))) {
					return true;
				}
				if (Context.unify(t, Context.getType('Float'))) {
					return true;
				}
				if (Context.unify(t, Context.getType('Bool'))) {
					return true;
				}
				false;
		}
	}
}
