package scaffold;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import scaffold.step.*;

abstract BuildFactory(Array<BuildStep>) {
	public inline static function ofSteps(steps) {
		return new BuildFactory(steps);
	}

	public function new(?steps:Array<BuildStep>) {
		this = steps ?? [];
	}

	public function withStep(step:BuildStep) {
		this.push(step);
		return abstract;
	}

	public inline function pipe(applicator) {
		return withStep(new ArbitraryBuildStep(applicator));
	}

	public function build(type:Type, fields:Array<Field>) {
		var build = new BuildContext(type, this, new FieldCollection(fields));
		return build.export();
	}

	public function buildFromContext() {
		return build(Context.getLocalType(), Context.getBuildFields());
	}
}
