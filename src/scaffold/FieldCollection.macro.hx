package scaffold;

import haxe.macro.Expr;
import haxe.ds.Option;

using Lambda;

class FieldCollection {
	public static function ofTypeDefinition(t:TypeDefinition) {
		return new FieldCollection(t.fields);
	}

	final fields:Array<Field>;
	var newFields:Array<Field> = [];

	public function new(fields) {
		this.fields = fields;
	}

	public function getFields() {
		return fields;
	}

	public function add(t:TypeDefinition) {
		mergeFields(t.fields);
		return this;
	}

	public function addField(f:Field) {
		newFields.push(f);
		return this;
	}

	public function mergeFields(fields:Array<Field>) {
		newFields = newFields.concat(fields);
		return this;
	}

	public function merge(collection:FieldCollection) {
		mergeFields(collection.newFields);
		return this;
	}

	public function get(name:String):Option<Field> {
		return switch fields.find(f -> f.name == name) {
			case null: None;
			case field: Some(field);
		}
	}

	public function select() {
		return new FieldSelection(fields);
	}

	public function export():Array<Field> {
		return fields.concat(newFields);
	}
}
