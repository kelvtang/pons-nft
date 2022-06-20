import React from "react"
import * as fcl_api from "@onflow/fcl"
import * as rlp from "rlp"
import { known_account_ } from "./utils/flow.mjs"
import { send_transaction_, sign_ } from "./utils/flow-api.mjs"
import Card from './components/Card'


const transactionCode = 'transaction () {prepare (artistAccount : AuthAccount, ponsAccount : AuthAccount) {} }'

const getSignature = async (signable) => {

  const decoded = rlp.decode(Buffer.from(signable.message.slice(64), 'hex'));
  console.log(decoded);

  const cadence = decoded[0][0].toString();
  const args = decoded[0][1].toString();

  //if (transactionCode.replace(/\s/g, "") === cadence.replace(/\s/g, "")) {
    const signature = sign_('9ee8ce3e6524d45962e79f3cca4b18cc7bb8ce8c302d94ec2f1d61b675dace0c')(signable.message);
    return signature
  //} else {
  //  console.log("error")
  //}
  // const response = await fetch(`${API}/sign`, {
  //   method: "POST",
  //   headers: { "Content-Type": "application/json" },
  //   body: JSON.stringify({ signable })
  // });

  // const signed = await response.json();
  // return signed.signature;
}

export const serverAuthorization = async (account) => {

  const addr = "0x0bbf3f167706608b";
  const keyId = 0;

  return {
    ...account,
    tempId: `${addr}-${keyId}`,
    addr: fcl_api.sansPrefix(addr),
    keyId: Number(keyId),
    signingFunction: async (signable) => {

      const signature = await getSignature(signable);

      return {
        addr: fcl_api.withPrefix(addr),
        keyId: Number(keyId),
        signature
      }
    }
  }
}

const CurrentUser = () => {
  // const [user, setUser] = useState({})

  const handleClick = async () => {

    // var _client_authorizer = async accountData => {
    // const authorization_obj = fcl_api.authz().then(x => x.resolve())
    // console.log(authorization_obj)
    // return (
    //   fcl_api.authz
    // ...accountData
    //, tempId: '0bbf3f167706608b' + '-' + '0'
    // , addr: '0bbf3f167706608b'
    // , keyId: 0
    // , signingFunction: _signing_data => fcl_api.authz().then(e => e.signingFunction(_signing_data))
    // , sequenceNum: 
    // , signingFunction: _signing_data => {
    //   return fcl_api.authz({})
    //     .then(x => x.resolve({}))
    //     .then(_accounts =>
    //       _accounts
    //         .filter(({ addr }) => addr === '0bbf3f167706608b')
    //         .filter(({ keyId }) => keyId === 0)
    //       [0])
    //     .then(_authorizer => _authorizer.signingFunction(_signing_data))
    // }
    //   )
    // }

    // var _transaction_response = await
    //   send_transaction_
    //     (known_account_('0xPROPOSER'))
    //     (known_account_('0xPROPOSER'))
    //     ([_client_authorizer, known_account_('0xPROPOSER')])
    //     ('transaction () {prepare (artistAccount : AuthAccount, ponsAccount : AuthAccount) {} }')
    //     ([])

    var _transaction_response = await
      send_transaction_
        (serverAuthorization)
        (serverAuthorization)
        ([fcl_api.authz, serverAuthorization])
        ('transaction () {prepare (artistAccount : AuthAccount, ponsAccount : AuthAccount) {} }')
        ([])
    console.log(_transaction_response)
  }

  return (
    <Card>
      <button onClick={handleClick}>Click me</button>
    </Card>
  )
}

export default CurrentUser
