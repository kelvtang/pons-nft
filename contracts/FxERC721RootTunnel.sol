// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FxBaseRootTunnel.sol";
import "./FxERC721.sol";
import "./IERC721Receiver.sol";
import "./OwnableUpgradeable.sol";
import "./TransparentUpgradeableProxy.sol";

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

    function initialize(
        address _checkpointManager,
        address _fxRoot
    ) initializer public {
        __Context_init();
        __Ownable_init();
        __FxBaseRootTunnel_init(_checkpointManager, _fxRoot);
    }

    function setTokenProxy(
        address _rootProxy
    ) public onlyOwner {
        
        require(
            _isContract(_rootProxy),
            "Root proxy address is not contract"
        );

        require(rootFxTokenProxy == address(0x0), "FxERC721RootTunnel: Root Proxy address already set");

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

    // before calling, need to prompt user to accept adding us as approved owner from js 
    function deposit(
        address user,
        uint256 tokenId,
        string memory tokenUri, 
        address royaltyReceiver,
        uint96 royaltyNumerator
    ) public {
        FxERC721 fxTokenProxyContract = FxERC721(rootFxTokenProxy);
        
        address _connectedFxChildProxy = fxTokenProxyContract.connectedToken();

        // validate root and child token mapping
        require(
                rootFxTokenProxy != address(0x0) && _connectedFxChildProxy != address(0x0),
            "FxERC721RootTunnel: NO_MAPPED_TOKEN"
        );

        bytes memory data = abi.encode(tokenUri, royaltyReceiver, royaltyNumerator);
        // transfer from depositor to this contract
        fxTokenProxyContract.safeTransferFrom(
            msg.sender, // depositor
            address(this), // manager contract
            tokenId,
            data
        );
        
        // DEPOSIT, encode(rootToken, depositor, user, tokenId, extra data)
        bytes memory message = abi.encode(DEPOSIT, abi.encode(user, tokenId, data));
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

        //approve token transfer
        if (!fxTokenProxyContract.exists(tokenId)) {
            fxTokenProxyContract.mint(to, tokenId, syncData);
        } else {
            // transfer from tokens
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