import PonsEscrowContract from 0xPONS

/* Terminate an Escrow */
transaction
( escrowStoragePath : StoragePath
) {
	prepare (account : AuthAccount) {

		PonsEscrowContract .terminateEscrow (
			account .borrow <&PonsEscrowContract.Escrow> (from: escrowStoragePath) ! ) } }
