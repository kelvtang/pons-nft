import PonsUtils from 0xPONS

/*
	FlowUnits `scale ()` Test

	Verifies that `scale ()` from FlowUnits hold the expected properties, including being referentially transparent.
*/

pub fun main () : {String: AnyStruct} {

	// Compute and compare the values of `scale ()` with the expected values

	let ratio1 = PonsUtils .Ratio (0.2)
	let ratio2 = PonsUtils .Ratio (0.1)
	let flowUnits = PonsUtils .FlowUnits (100.0, "Flow Token")

	let flowUnitsScaled1 = flowUnits .scale (ratio: ratio1)
	let flowUnitsScaled1Again = flowUnits .scale (ratio: ratio1)

	let flowUnitsScaled2 = flowUnitsScaled1 .scale (ratio: ratio2)

	let pureScaling = (flowUnitsScaled1 .flowAmount == flowUnitsScaled1Again .flowAmount)

	let pass =
		pureScaling
		&& (flowUnitsScaled1 .flowAmount == PonsUtils .FlowUnits (20.0, "Flow Token") .flowAmount)
		&& (flowUnitsScaled2 .flowAmount == PonsUtils .FlowUnits (2.0, "Flow Token") .flowAmount)

	return {
		"verified": pass,

		"R1": ratio1,
		"R2": ratio2,
		"F1": flowUnits .toString (),

		"Pure scalings": pureScaling,
		"S (R1) (F1)": flowUnitsScaled1 .toString (),
		"S (R2) . S (R1) $ (F1)": flowUnitsScaled2 .toString () } }
