// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FxBaseChildTunnel.sol";
import "./IERC721Receiver.sol";
import "./Initializable.sol";
import "./TransparentUpgradeableProxy.sol";
import "./FxERC721FxManager.sol";

contract FxERC721ChildTunnel is
    Initializable,
    FxBaseChildTunnelUpgradeable,
    IERC721ReceiverUpgradeable
{
    // maybe DEPOSIT can be reduced to bytes4
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");

    // child proxy address
    address public childFxManagerProxy;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _fxChild, address _childFxManagerProxy) public initializer {
        __FxBaseChildTunnel_init(_fxChild);

        require(
            _isContract(_childFxManagerProxy),
            "Proxy address is not contract"
        );

        require(
            childFxManagerProxy == address(0x0),
            "FxERC721ChildTunnel: Child fx manager proxy address already set"
        );

        childFxManagerProxy = _childFxManagerProxy;
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    //To mint tokens on child chain
    function mintToken(uint256 tokenId, bytes memory data) public {
        FxERC721FxManager childFxManagerProxyContract = FxERC721FxManager(childFxManagerProxy);

        //mint token
        childFxManagerProxyContract.mintToken(msg.sender, tokenId, data);
    }

    function withdraw(
        uint256 tokenId,
        string memory tokenUri,
        address royaltyReceiver,
        uint96 royaltyNumerator
    ) public {
        FxERC721FxManager childFxManagerProxyContract = FxERC721FxManager(childFxManagerProxy);

        // withdraw tokens
        childFxManagerProxyContract.burnToken(msg.sender, tokenId);

        bytes memory syncData = abi.encode(
            tokenUri,
            royaltyReceiver,
            royaltyNumerator
        );
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
    ) internal override validateSender(sender) {
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

    function syncDeposit(address sender, bytes memory syncData) public {
        _processMessageFromRoot(0, sender, syncData);
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
