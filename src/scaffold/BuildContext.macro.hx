package scaffold;

import haxe.macro.Type;

using Lambda;

class BuildContext {
	public final type:Type;
	public final fields:FieldCollection;

	final steps:Array<BuildStep>;

	public function new(type, steps, fields) {
		this.type = type;
		this.fields = fields;
		this.steps = steps;
	}

	public function export() {
		for (step in steps) step.build(null, this);
		return fields.export();
	}
}
