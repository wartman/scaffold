package fixture;

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
