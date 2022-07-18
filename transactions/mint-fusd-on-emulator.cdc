import FungibleToken from 0xFUNGIBLETOKEN
import FUSD from 0xFUSD

transaction(amount: UFix64, to: Address) {
    
    
    let tokenMinter: &FUSD.MinterProxy
    let tokenReceiver: &{FungibleToken.Receiver}

    prepare(minterAccount: AuthAccount) {

        self.tokenMinter = minterAccount
            .borrow<&FUSD.MinterProxy>(from: FUSD.MinterProxyStoragePath)
            ?? panic("No minter available")

        self.tokenReceiver = getAccount(to)
            .getCapability(/public/fusdReceiver)!
            .borrow<&{FungibleToken.Receiver}>()
            ?? panic("Unable to borrow receiver reference")
    }

    execute {
        let mintedVault <- self.tokenMinter.mintTokens(amount: amount)

        self.tokenReceiver.deposit(from: <-mintedVault)
    }
}