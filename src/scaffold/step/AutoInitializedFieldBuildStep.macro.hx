package scaffold.step;

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using Scaffold;

typedef AutoInitializedFieldBuildStepOption = {
	public final meta:String;
	public final ?late:Bool;
};

class AutoInitializedFieldBuildStep extends BuildStep {
	final options:AutoInitializedFieldBuildStepOption;

	public function new(options) {
		this.options = options;
	}

	public function steps():Array<BuildStep> return [];

	public function apply(context:BuildContext) {
		switch findAncestorOfType(ConstructorBuildStep) {
			case Some(constructor):
				context.fields
					.select()
					.byMeta(options.meta)
					.apply(field -> parseField(constructor, field));
			case None:
				Context.warning(
					'Attempting to use an AutoInitializedFieldBuildStep outside of a ConstructorBuildStep.'
					+ ' This means that the BuildStep will have no effect, as it requires a ConstructorBuildStep'
					+ ' as a parent.',
					Context.currentPos()
				);
		}
	}

	function parseField(constructor:ConstructorBuildStep, field:Field) {
		switch field.kind {
			case FVar(t, e):
				var name = field.name;
				var hook = options.late == true ? constructor.late : constructor.init;
				hook
					.addProp({
						name: name,
						type: t,
						doc: field.doc,
						optional: e != null
					})
					.addExpr(if (e == null) {
						macro this.$name = props.$name;
					} else {
						macro if (props.$name != null) this.$name = props.$name;
					});
			default:
				field.pos.error('Invalid field for ${options.meta}');
		}
	}
}
