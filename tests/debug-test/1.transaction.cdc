import TestUtils from 0xPONS

transaction () {

	prepare (ponsAccount : AuthAccount) {

		// TODO -- file issue

		var testNestedResource <- TestUtils .makeTestNestedResource ()

		var testRef = & (testNestedResource .testResources [0]) as &TestUtils.TestResource

		TestUtils .log ("owner: " .concat (testRef .owner ?.address ?.toString () ?? "null"))

		ponsAccount .save (<- testNestedResource, to: /storage/test)

		TestUtils .log ("owner: " .concat (testRef .owner ?.address ?.toString () ?? "null"))

		var testNestedResource2 <- ponsAccount .load <@TestUtils.TestNestedResource> (from: /storage/test) !

		TestUtils .log ("owner: " .concat (testRef .owner ?.address ?.toString () ?? "null"))

		var testResource <- testNestedResource2 .testResources .remove (at: 0)

		TestUtils .log ("owner: " .concat (testRef .owner ?.address ?.toString () ?? "null"))

		destroy testResource

		destroy testNestedResource2 !

//		var testResources <- [ <- TestUtils .makeTestResource () ]
//
//		var testRef = & (testResources [0]) as &TestUtils.TestResource
//
//		TestUtils .log ("owner: " .concat (testRef .owner ?.address ?.toString () ?? "null"))
//
//		ponsAccount .save (<- testResources, to: /storage/test)
//
//		TestUtils .log ("owner: " .concat (testRef .owner ?.address ?.toString () ?? "null"))
//
//		var testResources2 <- ponsAccount .load <@[TestUtils.TestResource]> (from: /storage/test) !
//
//		TestUtils .log ("owner: " .concat (testRef .owner ?.address ?.toString () ?? "null"))
//
//		var testResource <- testResources2 .remove (at: 0)
//
//		TestUtils .log ("owner: " .concat (testRef .owner ?.address ?.toString () ?? "null"))
//
//		destroy testResource
//
//		destroy testResources2

		 } }
