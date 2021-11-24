import PonsUtils from 0xPONS

pub fun main () : {String: AnyStruct} {
	let flowUnits1 = PonsUtils .FlowUnits (50.0)
	let flowUnits2 = PonsUtils .FlowUnits (50.0)
	let flowUnits3 = PonsUtils .FlowUnits (100.0)

	let is1AtLeast1 = flowUnits1 .isAtLeast (flowUnits1)
	let is1AtLeast2 = flowUnits1 .isAtLeast (flowUnits2)
	let is1AtLeast3 = flowUnits1 .isAtLeast (flowUnits3)
	let is2AtLeast1 = flowUnits2 .isAtLeast (flowUnits1)
	let is2AtLeast2 = flowUnits2 .isAtLeast (flowUnits2)
	let is2AtLeast3 = flowUnits2 .isAtLeast (flowUnits3)
	let is3AtLeast1 = flowUnits3 .isAtLeast (flowUnits1)
	let is3AtLeast2 = flowUnits3 .isAtLeast (flowUnits2)
	let is3AtLeast3 = flowUnits3 .isAtLeast (flowUnits3)

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

		"F1": flowUnits1 .toString (),
		"F2": flowUnits2 .toString (),
		"F3": flowUnits3 .toString (),

		"F1 >= F1": is1AtLeast1,
		"F1 >= F2": is1AtLeast2,
		"F1 >= F3": is1AtLeast3,
		"F2 >= F1": is2AtLeast1,
		"F2 >= F2": is2AtLeast2,
		"F2 >= F3": is2AtLeast3,
		"F3 >= F1": is3AtLeast1,
		"F3 >= F2": is3AtLeast2,
		"F3 >= F3": is3AtLeast3 } }
