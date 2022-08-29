import React, { useEffect, useState } from "react";
// import MetaMaskOnboarding from '@metamask/onboarding';
import { ethers } from "ethers";
import { Oval } from 'react-loader-spinner';
import Web3 from "web3";
import { make_known_ad_hoc_account_, cadencify_object_, send_proposed_transaction_ } from './utils/flow.mjs';
import { flow_sdk_api, address_of_names, pons_artist_id_of_names } from './config.mjs';
import * as flow_types from '@onflow/types'
import { v4 } from 'uuid'


const MARKETPLACE_ABI = 
const MARKETPLACE_PROXY_ADDRESS = ""

function App() {
  const [tokenId, setTokenId] = useState(null)
  const [pollInfo, setpollInfo] = useState({
    poll: false,
    message: '',
    error: '',
    polled: false
  })

  const poll = async (tokenId) => {
    // Make user the signer and payer
    const provider = new ethers.providers.Web3Provider(window.ethereum)
    await provider.send("eth_requestAccounts", []);
    const signer = provider.getSigner()

    // for testing
    // const prov = new ethers.providers.JsonRpcProvider("")
    // const signer = new ethers.Wallet("", prov)

    const polygonChainId = Web3.utils.toHex(137)

    // Check if user is on polygon network and switch if they are not on it or add the chain if it is not added and switch to it
    try {
      await provider.send('wallet_switchEthereumChain', [{ chainId: polygonChainId }])
    } catch (switchError) {

      if (switchError.data?.originalError?.code === 4902) {
        await provider.send('wallet_addEthereumChain', [{
          chainId: polygonChainId,
          chainName: "Polygon Mainnet",
          nativeCurrency: {
            name: "MATIC",
            symbol: "MATIC",
            decimals: 18,
          },
          rpcUrls: ["https://polygon-rpc.com"],
          blockExplorerUrls: ["https://www.polygonscan.com"],
        }])
      }

    }
    const marketplaceInstance = new ethers.Contract(MARKETPLACE_PROXY_ADDRESS, MARKETPLACE_ABI, signer)

    const executePoll = async (resolve, reject) => {
      const result = await marketplaceInstance.tokenExists(tokenId);

      if (result) {
        // if user rejects the purchase transaction, revert everything
        const price = await marketplaceInstance.getPrice(tokenId)
        marketplaceInstance.purchase(tokenId, { value: ethers.utils.parseEther(price.toString()) })
          .then(_ => {
            // TODO: Change location or display msg
            return resolve({ message: "Purcahsed successfully" }); // Could add anything that we want to return and use after this function runs if needed instead of just resolving with true
          })
          .catch(async e => {
            // console.log(e)
            // TODO: Based on actual path
            const resp = await fetch(`http://localhost:3010/market/revert`,
              {
                method: 'POST',
                body: JSON.stringify({ tokenId: tokenId }),
                headers: {
                  "content-type": "application/json",
                },
              })
            reject(await resp.json())
          })
      } else {
        setTimeout(executePoll, 1000, resolve, reject);
      }
    };

    return new Promise(executePoll);
  };

  useEffect(() => {

    if (pollInfo.poll) {
      let params = (new URL(document.location)).searchParams;
      // TODO: Change depending on the name of the actual query
      const tokenId = params.get("tokenId");


      // TODO: Based on actual path
      fetch("http://localhost:3010/market/flowPurchase", {
        method: "POST",
        body: JSON.stringify({ tokenId: tokenId }),
        headers: {
          "content-type": "application/json",
        },
      })
        .then(res => {
          if (res.status === 200) {
            poll(tokenId)
              .then(async r => {
                setpollInfo(prev => ({ ...prev, poll: false, message: r.message }))
              })
              .catch(async e => {
                setpollInfo(prev => ({ ...prev, poll: false, message: "", error: e.message }))
              })
          } else {
            setpollInfo(prev => ({ ...prev, poll: false, message: "", error: "Something went wrong while purchasing on flow" }))
          }
        })
        .catch(_ => {
          setpollInfo(prev => ({ ...prev, poll: false, message: "", error: "Something went wrong while sending request" }))
        })
    }
  }, [pollInfo])


  // FOR TESTING ONLY
  //   const setupInfo = async () => {
  //     await make_known_ad_hoc_account_('0xARTIST_1')
  //     await send_proposed_transaction_
  //       (['0xARTIST_1'])
  //       (`
  //     import FungibleToken from 0xFUNGIBLETOKEN
  // import FUSD from 0xPONS

  // transaction {

  //   prepare(signer: AuthAccount) {

  //     // It's OK if the account already has a Vault, but we don't want to replace it
  //     if(signer.borrow<&FUSD.Vault>(from: /storage/fusdVault) != nil) {
  //       return
  //     }

  //     // Create a new FUSD Vault and put it in storage
  //     signer.save(<-FUSD.createEmptyVault(), to: /storage/fusdVault)

  //     // Create a public capability to the Vault that only exposes
  //     // the deposit function through the Receiver interface
  //     signer.link<&FUSD.Vault{FungibleToken.Receiver}>(
  //       /public/fusdReceiver,
  //       target: /storage/fusdVault
  //     )

  //     // Create a public capability to the Vault that only exposes
  //     // the balance field through the Balance interface
  //     signer.link<&FUSD.Vault{FungibleToken.Balance}>(
  //       /public/fusdBalance,
  //       target: /storage/fusdVault
  //     )
  //   }
  // }`)
  //       ([])

  //     await send_proposed_transaction_
  //       (['0xPONS'])
  //       (`
  //   import FungibleToken from 0xFUNGIBLETOKEN
  // import PonsNftContract from 0xPONS
  // // import PonsUsage from 0xPONS
  // import TestUtils from 0xPONS

  // transaction 
  // ( artistAuthorityStoragePath : StoragePath
  // , ponsArtistId : String
  // , ponsArtistAddress : Address
  // , metadata : {String: String}
  // ) {

  // prepare (ponsAccount : AuthAccount) {

  // // Recognises the Pons artist with the provided data

  // let artistAuthorityRef = ponsAccount .borrow <&PonsNftContract.PonsArtistAuthority> (from: artistAuthorityStoragePath) !
  // let artistAccount = getAccount (ponsArtistAddress)

  // let artistAccountBalanceRefFlow = artistAccount .getCapability <&{FungibleToken.Balance}> (/public/flowTokenBalance) .borrow () !
  // let artistAccountBalanceRefFusd = artistAccount .getCapability <&{FungibleToken.Balance}> (/public/fusdBalance) .borrow () !

  // artistAuthorityRef .recognisePonsArtist (
  //   ponsArtistId: ponsArtistId,
  //   metadata : metadata,
  //   ponsArtistAddress,
  //   artistAccount .getCapability <&{FungibleToken.Receiver}> (/public/flowTokenReceiver),
  //   artistAccount .getCapability <&{FungibleToken.Receiver}> (/public/fusdReceiver) )


  // TestUtils .log ("Recognized artist")

  // TestUtils .log ("Artist Flow balance: " .concat (artistAccountBalanceRefFlow .balance .toString ()))
  // TestUtils .log ("Artist Fusd balance: " .concat (artistAccountBalanceRefFusd .balance .toString ()))
  // } }
  //   `)
  //       ([flow_sdk_api.arg({ domain: 'storage', identifier: 'ponsArtistAuthority' }, flow_types.Path)
  //         , flow_sdk_api.arg(pons_artist_id_of_names['0xARTIST_1'], flow_types.String)
  //         , flow_sdk_api.arg(address_of_names['0xARTIST_1'], flow_types.Address)
  //         , flow_sdk_api.arg
  //         (cadencify_object_(
  //           {
  //             first_name: 'Artist'
  //             , last_name: 'One'
  //             , url: 'pons://artist-1'
  //           })
  //           , flow_types.Dictionary({ key: flow_types.String, value: flow_types.String }))])

  //     await send_proposed_transaction_
  //       (['0xARTIST_1'])
  //       (`import PonsNftContract from 0xPONS

  //   import TestUtils from 0xPONS
  //   import PonsUsage from 0xPONS

  //   transaction () {

  //     prepare (artistAccount : AuthAccount) {
  //       var artistCertificate <- PonsUsage .makePonsArtistCertificateDirectly (artist: artistAccount)
  //       TestUtils .log ("artistCertificate id: " .concat (artistCertificate .ponsArtistId))
  //       destroy artistCertificate } }
  //     `)
  //       ([])

  //     const x = await send_proposed_transaction_
  //       (['0xPONS', '0xARTIST_1'])
  //       (`
  //         import PonsUtils from 0xPONS
  //         import PonsNftMarketContract from 0xPONS
  //         import PonsNftContract_v1 from 0xPONS

  //         import TestUtils from 0xPONS
  //         import PonsUsage from 0xPONS

  //         /*
  //           Mint for Sale Test
  //           Verifies that artists can mint NFTs for sale.
  //         */
  //         transaction 
  //         ( minterStoragePath : StoragePath
  //         , mintIds : [String]
  //         , metadata : {String: String}
  //         , quantity: Int
  //         , basePriceAmount : UFix64
  //         , incrementalPriceAmount : UFix64
  //         , royaltyRatioAmount : UFix64
  //         ) {

  //           prepare (ponsAccount : AuthAccount, artistAccount : AuthAccount) {

  //             let minterRef = ponsAccount .borrow <&PonsNftContract_v1.NftMinter_v1> (from: minterStoragePath) !

  //             minterRef .refillMintIds (mintIds: mintIds)

  //             let basePrice = PonsUtils.FlowUnits (basePriceAmount)
  //             let incrementalPrice = PonsUtils.FlowUnits (incrementalPriceAmount)
  //             let royalty = PonsUtils.Ratio (royaltyRatioAmount)

  //             let nftIds =
  //               PonsUsage .mintForSaleFlow (
  //                 minter: artistAccount,
  //                 metadata: metadata,
  //                 quantity: quantity,
  //                 basePrice: basePrice,
  //                 incrementalPrice: incrementalPrice,
  //                 royalty ) } }
  //     `)
  //       ([flow_sdk_api.arg({ domain: 'storage', identifier: 'ponsMinter' }, flow_types.Path)
  //         , flow_sdk_api.arg([v4()], flow_types.Array(flow_types.String))
  //         , flow_sdk_api.arg
  //         (cadencify_object_(
  //           {
  //             first_name: 'Artist'
  //             , last_name: 'One'
  //             , url: 'pons://artist-1'
  //             , title: 'Hello'
  //             , description: 'Testing functions'
  //           })
  //           , flow_types.Dictionary({ key: flow_types.String, value: flow_types.String }))
  //         , flow_sdk_api.arg('1', flow_types.Int)
  //         , flow_sdk_api.arg('10.1', flow_types.UFix64)
  //         , flow_sdk_api.arg('0.10', flow_types.UFix64)
  //         , flow_sdk_api.arg('0.10', flow_types.UFix64)])
  //     setTokenId(_ => x.events[0].data.serialNumber)
  //   }

  const isMobile = () => {
    if (/(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|ipad|iris|kindle|Android|Silk|lge |maemo|midp|mmp|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows (ce|phone)|xda|xiino/i.test(navigator.userAgent)
      || /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(navigator.userAgent.substr(0, 4))) {
      return true
    } else {
      return false
    }
  }

  if (window.ethereum && isMobile() && !pollInfo.polled) {
    setpollInfo(prev => ({ ...prev, poll: true, message: "Purchasing on flow and transferring to polygon", polled: true }))
  } else if (!window.ethereum && isMobile()) {
    return (
      <page>
        // TODO: Add link
        <button onClick={() => window.location.assign('')} disabled={pollInfo.poll}>
          Buy on Polygon
        </button>
      </page>
    )
  } else {
    return (
      pollInfo.poll ?
        <page>
          <Oval color="#5C5C5C" height={50} width={50} />
          <hint _for="loading-text">{pollInfo.message}</hint>
        </page>
        : pollInfo.message || pollInfo.error
          ?
          <page>
            // TODO: Redirect back to app here
            <hint _for="redirection-text">{pollInfo.error ? pollInfo.error : pollInfo.message}</hint>
          </page>
          :
          <page>
            {/* FOr testing */}
            {/* <button onClick={() => setupInfo()} disabled={pollInfo.poll}>
              Set up artist and mint
            </button> */}
            <button onClick={() => setpollInfo(prev => ({ ...prev, poll: true, message: "Purchasing on flow and transferring to polygon", polled: true }))} disabled={pollInfo.poll}>
              Buy on Polygon
            </button>
          </page>
    )
  }
}

export default App;