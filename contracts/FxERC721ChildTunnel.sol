// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FxBaseChildTunnel.sol";
import "./IERC721Receiver.sol";
import "./Initializable.sol";
import "./FxERC721FxManager.sol";

contract FxERC721ChildTunnel is Initializable, FxBaseChildTunnelUpgradeable, IERC721ReceiverUpgradeable {
    // maybe DEPOSIT can be reduced to bytes4
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");

    address public childFxManagerProxy;


    constructor() {
        _disableInitializers();
    }

    /** 
    * @dev public function that is called when the proxy contract managing this contract is deployed through the {_data} variable
    * This function can only be called once and cannot be called again later on, even when the contract is upgraded.
    * See {ERC1967Proxy-constructor}.
    * 
    * @param _fxChild address representing the already deployed and verified fxChild contract
    * @param _childFxManagerProxy address representing the FxManager Proxy Contract deployed on polygon
    */
    function initialize(address _fxChild, address _childFxManagerProxy) public initializer {

        require(
            _isContract(_childFxManagerProxy),
            "Proxy address is not contract"
        );

        require(
            childFxManagerProxy == address(0x0),
            "FxERC721ChildTunnel: Child fx manager proxy address already set"
        );

        childFxManagerProxy = _childFxManagerProxy;
        __FxBaseChildTunnel_init(_fxChild);
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        bytes calldata /* data */
    ) 
        external 
        pure 
        override 
        returns (bytes4) 
    {
        return this.onERC721Received.selector;
    }

    /**
    * @dev public function that can be called to mint a token using {FxERC721FxManager.mintToken}
    * Only succeeds if the tunnel is an approved address to use FxERC721FxManager's functions
    * 
    * @param tokenId uint256 representing the Id of the token the user wants to have to transferred to ethereum
    * @param data bytes representing the extra information needed for the mint to happen
    */
    // function mintToken(uint256 tokenId, bytes memory data) public {
    //     FxERC721FxManager childFxManagerProxyContract = FxERC721FxManager(childFxManagerProxy);

    //     //mint token
    //     childFxManagerProxyContract.mintToken(msg.sender, tokenId, data);
    // }

    /**
    * @dev public function that the user calls to transfer a token from polygon to his account address on ethereum
    * Need to wait for token to be checkpointed before generating a burn proof
    * When token gets checkpointed, user needs to generate a burn proof using the withdraw transaction hash
    * The user then feeds the burn proof to {RootTunnelProxy.receiveMessage(proof)} to claim the token on ethereum
    *
    * @param tokenId uint256 representing the Id of the token the user wants to have to transferred to ethereum
    */
    function withdraw(uint256 tokenId) public {
        FxERC721FxManager childFxManagerProxyContract = FxERC721FxManager(childFxManagerProxy);

        bytes memory syncData = childFxManagerProxyContract.getNftDataDetails(tokenId);
        
        // withdraw tokens
        childFxManagerProxyContract.burnToken(msg.sender, tokenId);

        // send message to root regarding token burn
        _sendMessageToRoot(
            abi.encode(msg.sender, tokenId, syncData)
        );
    }

    //
    // Internal methods
    //

    function _processMessageFromRoot(
        uint256, /* stateId */
        address sender,
        bytes memory data
    ) 
        internal 
        override 
        validateSender(sender) 
    {
        // decode incoming data
        (bytes32 syncType, bytes memory syncData) = abi.decode(
            data,
            (bytes32, bytes)
        );

        if (syncType == DEPOSIT) {
            _syncDeposit(syncData);
        } else {
            revert("FxERC721ChildTunnel: INVALID_SYNC_TYPE");
        }
    }

    function _syncDeposit(bytes memory syncData) internal {
        (
            address to,
            uint256 tokenId,
            bytes memory depositData
        ) = abi.decode(syncData, (address, uint256, bytes));

        FxERC721FxManager childFxManagerProxyContract = FxERC721FxManager(childFxManagerProxy);

        //mint token
        childFxManagerProxyContract.mintToken(to, tokenId, depositData);
    }

    // check if address is contract
    function _isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[48] private __gap;
}
