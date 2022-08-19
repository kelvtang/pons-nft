// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FxBaseRootTunnel.sol";
import "./FxERC721.sol";
import "./IERC721Receiver.sol";
import "./OwnableUpgradeable.sol";

/**
* @title FxERC721RootTunnel
*/
contract FxERC721RootTunnel is FxBaseRootTunnelUpgradeable, IERC721ReceiverUpgradeable, OwnableUpgradeable {
    // maybe DEPOSIT can be reduced to bytes4
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");

    address public rootFxTokenProxy;

    constructor() {
        _disableInitializers();
    }

    /** 
    * @dev public function that is called when the proxy contract managing this contract is deployed through the {_data} variable
    * This function can only be called once and cannot be called again later on, even when the contract is upgraded.
    * See {ERC1967Proxy-constructor}.
    * 
    * @param _checkpointManager address representing the already deployed verified checkpointManager contract
    * @param _fxRoot address representing the already deployed and verified fxRoot contract
    */
    function initialize(address _checkpointManager, address _fxRoot) public initializer {
        __Context_init();
        __Ownable_init();
        __FxBaseRootTunnel_init(_checkpointManager, _fxRoot);
    }

    /**
    * @dev public function that can be only called by the deployer of the contract when {rootFxTokenProxy} is not set
    *
    * @param _rootProxy address representing the FxERC721 contract proxy deployed
    */
    function setTokenProxy(address _rootProxy) public onlyOwner {
        require(_isContract(_rootProxy), "Root proxy address is not contract");

        require(
            rootFxTokenProxy == address(0x0),
            "FxERC721RootTunnel: Root Proxy address already set"
        );

        rootFxTokenProxy = _rootProxy;
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
    * @dev public function that the user calls to transfer a token from ethereum to polygon
    * The user has to be prompted first to approve this contract as an approved address  
    * This can be done through the {FxERC721Proxy.approve(tunnelProxyAddress, tokenId)}
    * Approval is needed to allow the contract to transfer the token from the user's account to the contract's address
    *
    * @param user address representing the polygon address the token should be deposited to
    * @param tokenId uint256 representing the Id of the token the user wants to have to transferred to polygon
    */
    function deposit(address user, uint256 tokenId) public {
        FxERC721 fxTokenProxyContract = FxERC721(rootFxTokenProxy);

        address _connectedFxChildProxy = fxTokenProxyContract.connectedToken();

        // validate root and child token mapping
        require(
            rootFxTokenProxy != address(0x0) && _connectedFxChildProxy != address(0x0),
            "FxERC721RootTunnel: NO_MAPPED_TOKEN"
        );

        // bytes memory data = fxTokenProxyContract.getNftDataDetails(tokenId);
        (address royaltyAddress, uint96 royaltyFraction) = fxTokenProxyContract.getRoyaltyDetails(tokenId);
        
        bytes memory data = abi.encode(
            fxTokenProxyContract.getTokenURI(tokenId),
            fxTokenProxyContract.getPolygonArtistAddress(tokenId),
            fxTokenProxyContract.getArtistId(tokenId),
            royaltyAddress,
            royaltyFraction
        );

        // transfer from depositor to this contract
        fxTokenProxyContract.safeTransferFrom(
            msg.sender, // depositor
            address(this),
            tokenId,
            data
        );

        // DEPOSIT, encode(rootToken, depositor, user, tokenId, extra data)
        bytes memory message = abi.encode(
            DEPOSIT,
            abi.encode(user, tokenId, data)
        );

        _sendMessageToChild(message);
    }

    // exit processor
    function _processMessageFromChild(bytes memory data) internal override {
        (address to, uint256 tokenId, bytes memory syncData) = abi.decode(
            data,
            (address, uint256, bytes)
        );

        // validate root and child token mapping
        require(
            rootFxTokenProxy != address(0x0),
            "FxERC721RootTunnel: NO_MAPPED_TOKEN"
        );

        FxERC721 fxTokenProxyContract = FxERC721(rootFxTokenProxy);

        if (!fxTokenProxyContract.exists(tokenId)) {
            fxTokenProxyContract.mint(to, tokenId, syncData);
        } else {
            fxTokenProxyContract.safeTransferFrom(
                address(this),
                to,
                tokenId,
                syncData
            );
        }
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