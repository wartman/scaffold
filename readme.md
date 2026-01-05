# Scaffold

Composable macro build steps for Haxe.

# Usage

Compose a BuildFactory using Scaffold's built-in steps or ones you create:

```haxe
// In `ObjectBuilder.macro.hx`
import scaffold.step.*;

using Scaffold;

function build() {
	return BuildFactory
		.ofSteps([
			new ConstructorBuildStep({
				children: [
					new AutoInitializedFieldBuildStep({meta: 'auto'}),
					new JsonSerializerBuildStep()
				]
			}),
			new PropertyBuildStep()
		])
		.buildFromContext();
}
```

Use `:autoBuild` or `:build` to apply your macro:

```haxe
@:autoBuild(ObjectBuilder.build())
interface Object {}
```

Use it on a class:

```haxe
class Name implements Object {
	/**
		The first prop.
	**/
	@:auto public final first:String;

	/**
		The second prop.
	**/
	@:auto public final last:String;

	@:prop(get = first + ' ' + last) public final full:String;
}
```

> Coming soon: some explanation of what's going on here.
