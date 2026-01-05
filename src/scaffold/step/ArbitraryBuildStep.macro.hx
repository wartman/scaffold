package scaffold.step;

class ArbitraryBuildStep extends BuildStep {
	final applicator:(context:BuildContext) -> Void;

	public function new(applicator) {
		this.applicator = applicator;
	}

	public function steps():Array<BuildStep> return [];

	public function apply(context:BuildContext) {
		return applicator(context);
	}
}
