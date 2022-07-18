import PonsUtils from 0xPONS


/*
	FlowUnits `isAtLeast ()` Test

	Verifies that `isAtLeast ()` of FlowUtils holds the expected properties, including being reflexive and transitive.
*/
pub fun main () : {String: AnyStruct} {

	// Compute and compare values of `isAtLeast ()` with the expected values

	let fusdUnits1 = PonsUtils .FusdUnits (50.0)
	let fusdUnits2 = PonsUtils .FusdUnits (50.0)
	let fusdUnits3 = PonsUtils .FusdUnits (100.0)

	let is1AtLeast1 = fusdUnits1 .isAtLeast (fusdUnits1)
	let is1AtLeast2 = fusdUnits1 .isAtLeast (fusdUnits2)
	let is1AtLeast3 = fusdUnits1 .isAtLeast (fusdUnits3)
	let is2AtLeast1 = fusdUnits2 .isAtLeast (fusdUnits1)
	let is2AtLeast2 = fusdUnits2 .isAtLeast (fusdUnits2)
	let is2AtLeast3 = fusdUnits2 .isAtLeast (fusdUnits3)
	let is3AtLeast1 = fusdUnits3 .isAtLeast (fusdUnits1)
	let is3AtLeast2 = fusdUnits3 .isAtLeast (fusdUnits2)
	let is3AtLeast3 = fusdUnits3 .isAtLeast (fusdUnits3)

	let pass =
		(is1AtLeast1 == true)
		&& (is1AtLeast2 == true)
		&& (is1AtLeast3 == false)
		&& (is2AtLeast1 == true)
		&& (is2AtLeast2 == true)
		&& (is2AtLeast3 == false)
		&& (is3AtLeast1 == true)
		&& (is3AtLeast2 == true)
		&& (is3AtLeast3 == true)

	return {
		"verified": pass,

		"F1": fusdUnits1 .toString (),
		"F2": fusdUnits2 .toString (),
		"F3": fusdUnits3 .toString (),

		"F1 >= F1": is1AtLeast1,
		"F1 >= F2": is1AtLeast2,
		"F1 >= F3": is1AtLeast3,
		"F2 >= F1": is2AtLeast1,
		"F2 >= F2": is2AtLeast2,
		"F2 >= F3": is2AtLeast3,
		"F3 >= F1": is3AtLeast1,
		"F3 >= F2": is3AtLeast2,
		"F3 >= F3": is3AtLeast3 } }
