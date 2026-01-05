package scaffold;

import haxe.ds.Option;

using Lambda;

enum BuildStepStatus {
	Pending;
	Active(parent:Null<BuildStep>, children:Array<BuildStep>);
}

abstract class BuildStep {
	public var parent(get, never):Option<BuildStep>;

	function get_parent():Option<BuildStep> {
		return switch status {
			case Active(null, _): None;
			case Active(parent, _): Some(parent);
			default: None;
		}
	}

	public var children(get, never):Array<BuildStep>;

	function get_children():Array<BuildStep> {
		return switch status {
			case Active(_, children): children;
			default: [];
		}
	}

	var status:BuildStepStatus = Pending;

	abstract function steps():Array<BuildStep>;

	abstract function apply(context:BuildContext):Void;

	public function build(parent:Null<BuildStep>, context:BuildContext) {
		if (status != Pending) return;

		var children = steps();

		status = Active(parent, children);

		for (child in children) {
			child.build(this, context);
		}

		apply(context);
	}

	public function findAncestor(match:(parent:BuildStep) -> Bool):Option<BuildStep> {
		return switch parent {
			case Some(parent) if (match(parent)): Some(parent);
			case Some(parent): parent.findAncestor(match);
			case None: None;
		}
	}

	public function findAncestorOfType<T:BuildStep>(kind:Class<T>):Option<T> {
		return switch findAncestor(child -> Std.isOfType(child, kind)) {
			case Some(value): Some(cast value);
			case None: None;
		}
	}

	public function findChild(match:(child:BuildStep) -> Bool, ?options:{recursive:Bool}):Option<BuildStep> {
		return switch children.find(match) {
			case null if (options?.recursive == true):
				for (child in children) switch child.findChild(match, {recursive: true}) {
					case Some(child): return Some(child);
					case None:
				}
				None;
			case null:
				None;
			case child:
				Some(child);
		}
	}

	public function findChildOfType<T:BuildStep>(kind:Class<T>, ?options):Option<T> {
		return switch findChild(child -> Std.isOfType(child, kind), options) {
			case Some(value): Some(cast value);
			case None: None;
		}
	}
}
