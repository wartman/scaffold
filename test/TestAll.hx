import fixture.Name;
import utest.Test;

using utest.Assert;

class TestAll extends Test {
	function testAutomaticConstructorArgs() {
		var name = new Name({first: 'Guy', last: 'Manly'});
		name.first.equals('Guy');
		name.last.equals('Manly');
	}

	function testFieldIntoProperty() {
		var name = new Name({first: 'Guy', last: 'Manly'});
		name.full.equals('Guy Manly');
	}
}
