pub contract PonsCertificationContract {

	pub resource PonsCertification {}

	access(account) fun makePonsCertification () : @PonsCertification {
		return <- create PonsCertification () } }
