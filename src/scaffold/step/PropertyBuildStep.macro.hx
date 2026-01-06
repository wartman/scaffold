package scaffold.step;

import haxe.macro.Expr;

using Scaffold;

class PropertyBuildStep extends BuildStep {
	public function new() {}

	public function steps() return [];

	public function apply(context:BuildContext) {
		context.fields
			.select()
			.byMeta(':prop')
			.apply(field -> parseField(context, field));
	}

	function parseField(context:BuildContext, field:Field) {
		switch field.kind {
			case FVar(t, e):
				if (e != null) {
					e.pos.error('Expressions are not allowed in :prop fields');
				}

				var name = field.name;
				var getterName = 'get_$name';
				var setterName = 'set_$name';
				var meta = switch field.meta.get(':prop') {
					case Some(value): value;
					case None: throw 'assert';
				}

				switch meta?.params {
					case [macro get = $expr]:
						field.kind = FProp('get', 'never', t);
						context.fields.add(macro class {
							function $getterName():$t return $expr;
						});
					case [macro set = $expr]:
						field.kind = FProp('never', 'set', t);
						context.fields.add(macro class {
							function $setterName(value : $t):$t return $expr;
						});
					case [macro get = $getter, macro set = $setter] | [macro set = $setter, macro get = $getter]:
						field.kind = FProp('get', 'set', t);
						context.fields.add(macro class {
							function $getterName():$t return $getter;

							function $setterName(value : $t):$t return $setter;
						});
					case []:
						field.pos.error('Expected a getter and/or setter');
					default:
						field.pos.error('Invalid arguments for :prop');
				}
			default:
				field.pos.error('Invalid field for :prop');
		}
	}
}
