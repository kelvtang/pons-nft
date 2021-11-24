import PonsUtils from 0xPONS

pub fun main () : {String: AnyStruct} {
	let ratio1 = PonsUtils .Ratio (0.2)
	let ratio2 = PonsUtils .Ratio (0.1)
	let flowUnits = PonsUtils .FlowUnits (100.0)

	let flowUnitsScaled1 = flowUnits .scale (ratio: ratio1)
	let flowUnitsScaled1Again = flowUnits .scale (ratio: ratio1)

	let flowUnitsScaled2 = flowUnitsScaled1 .scale (ratio: ratio2)

	let idempotentScaling = (flowUnitsScaled1 .flowAmount == flowUnitsScaled1Again .flowAmount)

	let pass =
		idempotentScaling
		&& (flowUnitsScaled1 .flowAmount == PonsUtils .FlowUnits (20.0) .flowAmount)
		&& (flowUnitsScaled2 .flowAmount == PonsUtils .FlowUnits (2.0) .flowAmount)

	return {
		"verified": pass,

		"R1": ratio1,
		"R2": ratio2,
		"F1": flowUnits .toString (),

		"Idempotent scalings": idempotentScaling,
		"S (R1) (F1)": flowUnitsScaled1 .toString (),
		"S (R2) . S (R1) $ (F1)": flowUnitsScaled2 .toString () } }
