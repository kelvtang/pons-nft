pub contract TestUtils {

	pub resource TestResource {}
	pub resource TestNestingResource {
		pub let testResources : @[TestResource]

		init () {
			self .testResources <- [ <- create TestResource () ] }
		destroy () {
			destroy self .testResources } }
	pub fun makeTestResource () : @TestResource {
		return <- create TestResource () }
	pub fun makeTestNestingResource () : @TestNestingResource {
		return <- create TestNestingResource () }

	pub event Log (info : String)

	pub event TestInfo (key : String, value : String)

	pub fun log (_ info : String) : Void {
		emit Log (info: info) }

	pub fun testInfo (_ key : String, _ value : String) : Void {
		emit TestInfo (key: key, value: value) }

	pub fun substring (_ substring : String, in : String) : Bool {
		let possibleStarts = in .length - substring .length + 1

		var start = 0
		while start < possibleStarts {
			if substring == in .slice (from: start, upTo: start + substring .length) {
				return true }
			start = start + 1 }

		return false }

	pub fun startsWith (substring : String, _ string : String) : Bool {
		return (string .length >= substring .length)
			&& (string .slice (from: 0, upTo: substring .length) == substring) }

	pub fun endsWith (substring : String, _ string : String) : Bool {
		return (string .length >= substring .length)
			&& (string .slice (from: string .length - substring .length, upTo: string .length) == substring) }

	pub fun typeEvents (_ type : String, _ events : [{String: String}]) : [{String: String}] {
		var typeEvents : [{String: String}] = []
		var index = 0
		while index < events .length {
			if TestUtils .endsWith (substring: type, events [index] ["type"] !) {
				typeEvents .append (events [index]) }
			index = index + 1 }
		return typeEvents }

	pub fun dropInfoPrefix (_ prefix : String, _ events : [{String: String}]) : [String] {
		var infos : [String] = []
		var index = 0
		while index < events .length {
			if TestUtils .startsWith (substring: prefix, events [index] ["info"] !) {
				infos .append (events [index] ["info"] ! .slice (from: prefix .length, upTo: events [index] ["info"] ! .length)) }
			index = index + 1 }
		return infos } }
