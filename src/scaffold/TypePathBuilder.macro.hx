package scaffold;

import haxe.macro.Context;
import haxe.macro.Expr;

@:forward
abstract TypePathBuilder(TypePath) to TypePath {
	@:from public static inline function of(path) {
		return new TypePathBuilder(path);
	}

	public inline function new(path) {
		this = path;
	}

	public function exists() {
		try {
			return Context.getType(toString()) != null;
		} catch (e:String) {
			return false;
		}
	}

	public function withPack(pack) {
		return new TypePathBuilder({
			pack: pack,
			name: this.name,
			sub: this.sub,
			params: this.params
		});
	}

	public function withName(name) {
		return new TypePathBuilder({
			pack: this.pack,
			name: name,
			sub: this.sub,
			params: this.params
		});
	}

	public function withSub(sub) {
		return new TypePathBuilder({
			pack: this.pack,
			name: this.name,
			sub: sub,
			params: this.params
		});
	}

	public function withoutSub() {
		return new TypePathBuilder({
			pack: this.pack,
			name: this.name,
			params: this.params
		});
	}

	public function withParams(params) {
		return new TypePathBuilder({
			pack: this.pack,
			name: this.name,
			sub: this.sub,
			params: params
		});
	}

	public function withoutParams() {
		return new TypePathBuilder({
			pack: this.pack,
			name: this.name,
			sub: this.sub
		});
	}

	@:to public function toArray():Array<String> {
		return this.pack.concat([this.name, this.sub]).filter(s -> s != null);
	}

	@:to public function toString():String {
		return toArray().join('.');
	}
}
