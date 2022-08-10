import React, { useEffect, useState } from "react";
import MetaMaskOnboarding from '@metamask/onboarding';
import { ethers } from "ethers";
import Web3 from "web3";
import { flow_sdk_api } from "../../pons-nft/config.mjs";
import fcl_api from '@onflow/fcl'
import flow_types from '@onflow/types'
import { send_transaction_ } from "../../pons-nft/utils/flow-api.mjs";


const Connect = () => {
    const dappUrl = ""; // TODO enter your dapp URL. For example: https://uniswap.exchange. (don't enter the "https://")
    const metamaskAppDeepLink = "https://metamask.app.link/dapp/" + dappUrl;
    return (
      <a href={metamaskAppDeepLink}>
        <button>
          Open in MetaMask
        </button>
      </a>
    );
  }
  
  function App() {
  
    const [shouldPoll, setShouldPoll] = useState(false)
  
  
    const poll = async ({ tokenId }) => {
  
  
      // Make user the signer and payer
      const provider = new ethers.providers.Web3Provider(window.ethereum)
      await provider.send("eth_requestAccounts", []);
      const signer = provider.getSigner()
  
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
  
      // TODO: Edit hardcoded values
      const marketplaceInstance = new ethers.Contract(MARKETPLACE_ADDRESS, MARKETPLACE_ABI, signer)
  
      const executePoll = async (resolve, reject) => {
  
        const result = await marketplaceInstance.getPrice(tokenId);
  
        if (result !== 0) {
          // if user rejects the purchase transaction, revert everything
          marketplaceInstance.purchase(tokenId)
            .then(_ => {
              return resolve(true); // Could add anything that we want to return and use after this function runs if needed instead of just resolving with true
            })
            .catch(_ => {
              // TODO: Based on actual path
              fetch(`/revert/${tokenId}`, { method: 'GET' })
            })
        } else {
          setTimeout(executePoll, 1000, resolve, reject);
        }
      };
  
      return new Promise(executePoll);
    };
  
    useEffect(() => {
  
      if (shouldPoll) {
        let params = (new URL(document.location)).searchParams;
        // TODO: Change depending on the name of the actual query
        const tokenId = params.get("tokenId");
  
        await send_transaction_
          (authorizer_(address)(key_id)(private_key)) // TODO: Edit hardcoded values
          (authorizer_(address)(key_id)(private_key)) // TODO: Edit hardcoded values
          ([authorizer_(address)(key_id)(private_key)]) // TODO: Edit hardcoded values
          (`import PonsTunnelContract from 0xPONS
            transaction(polygonRecepientAddress: String, nftSerialId: UInt64) {
            prepare (ponsAccount : AuthAccount){
               PonsTunnelContract .sendNftThroughTunnelUsingSerialId(nftSerialId: nftSerialId, ponsAccount : ponsAccount, ponsHolderAccount : ponsAccount, tunnelUserAccount : ponsAccount, polygonAddress: polygonRecepientAddress);
            }`)
          ([flow_sdk_api.arg(POLYGON_RECEPIENT_ADDRESS, flow_types.String), // TODO: Edit hardcoded values
          flow_sdk_api.arg(tokenId, flow_types.UInt64)])
  
        poll({ tokenId: tokenId })
          .then(async _ => {
            setShouldPoll(_ => false)
          });
      }
    }, [shouldPoll])
  
    return (
      window.ethereum ?
        <button onClick={() => setShouldPoll(_ => true)} disabled={shouldPoll}>Buy on Polygon</button> :
        <Connect />
    )
  
  }
  
  export default App;