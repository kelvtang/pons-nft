import PonsUtils from 0xPONS

/*
	FlowUnits `scale ()` Test

	Verifies that `scale ()` from FlowUnits hold the expected properties, including being referentially transparent.
*/

pub fun main () : {String: AnyStruct} {

	// Compute and compare the values of `scale ()` with the expected values

	let ratio1 = PonsUtils .Ratio (0.2)
	let ratio2 = PonsUtils .Ratio (0.1)
	let fusdUnits = PonsUtils .FusdUnits (100.0)

	let fusdUnitsScaled1 = fusdUnits .scale (ratio: ratio1)
	let fusdUnitsScaled1Again = fusdUnits .scale (ratio: ratio1)

	let fusdUnitsScaled2 = fusdUnitsScaled1 .scale (ratio: ratio2)

	let pureScaling = (fusdUnitsScaled1 .fusdAmount == fusdUnitsScaled1Again .fusdAmount)

	let pass =
		pureScaling
		&& (fusdUnitsScaled1 .fusdAmount == PonsUtils .FusdUnits (20.0) .fusdAmount)
		&& (fusdUnitsScaled2 .fusdAmount == PonsUtils .FusdUnits (2.0) .fusdAmount)

	return {
		"verified": pass,

		"R1": ratio1,
		"R2": ratio2,
		"F1": fusdUnits .toString (),

		"Pure scalings": pureScaling,
		"S (R1) (F1)": fusdUnitsScaled1 .toString (),
		"S (R2) . S (R1) $ (F1)": fusdUnitsScaled2 .toString () } }
