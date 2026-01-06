package fixture;

import scaffold.step.*;

using Scaffold;

function build() {
	return BuildFactory
		.ofSteps([
			new ConstructorBuildStep({
				children: [
					new AutoInitializedFieldBuildStep({meta: ':auto'}),
					new JsonSerializerBuildStep()
				]
			}),
			new PropertyBuildStep()
		])
		.buildFromContext();
}
