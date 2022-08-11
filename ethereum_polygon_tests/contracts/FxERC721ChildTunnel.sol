// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FxBaseChildTunnel.sol";
import "./FxERC721.sol";
import "./IERC721Receiver.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./TransparentUpgradeableProxy.sol";

contract FxERC721ChildTunnel is
    Initializable,
    OwnableUpgradeable,
    FxBaseChildTunnelUpgradeable,
    IERC721ReceiverUpgradeable
{
    // maybe DEPOSIT can be reduced to bytes4
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");

    // child proxy address
    address public childProxy;
    // root proxy address
    address public rootProxy;

    event FlowDeposit(bytes data);

    constructor() {
        _disableInitializers();
    }

    function initialize(address _fxChild) public initializer {
        __Context_init();
        __Ownable_init();
        __FxBaseChildTunnel_init(_fxChild);
    }

    function setProxyAddresses(address _childProxy, address _rootProxy)
        public
        onlyOwner
    {
        require(
            _isContract(_childProxy),
            "Child proxy address is not contract"
        );

        require(
            childProxy == address(0x0),
            "FxERC721ChildTunnel: Child Proxy address already set"
        );
        require(
            rootProxy == address(0x0),
            "FxERC721ChildTunnel: Root Proxy address already set"
        );

        childProxy = _childProxy;
        rootProxy = _rootProxy;
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
        FxERC721 childTokenContract = FxERC721(childProxy);
        // child token contract will have root token
        address _rootProxy = childTokenContract.connectedToken();

        // validate root and child token mapping
        require(
            childProxy != address(0x0) && _rootProxy != address(0x0),
            "FxERC721ChildTunnel: NO_MAPPED_TOKEN"
        );

        //mint token
        childTokenContract.mint(msg.sender, tokenId, data);
    }

    function withdraw(
        uint256 tokenId,
        string memory tokenUri,
        address royaltyReceiver,
        uint96 royaltyNumerator
    ) public {
        FxERC721 childTokenContract = FxERC721(childProxy);

        require(
            msg.sender == childTokenContract.ownerOf(tokenId),
            "Caller not owner of token"
        );
        // withdraw tokens
        childTokenContract.burn(tokenId);

<<<<<<< HEAD
        // name, symbol
        FxERC721 rootTokenContract = FxERC721(childToken);
        string memory name = rootTokenContract.name();
        string memory symbol = rootTokenContract.symbol();
        bytes memory metaData = abi.encode(name, symbol);

=======
        bytes memory syncData = abi.encode(
            tokenUri,
            royaltyReceiver,
            royaltyNumerator
        );
>>>>>>> Ethereum-polygon-solidity-contracts
        // send message to root regarding token burn
        _sendMessageToRoot(
            abi.encode(rootProxy, childProxy, msg.sender, tokenId, syncData)
        );
    }

    function processMessageFromFLow(bytes memory data) public {
        (
            address to,
            uint64 flowTokenId,
            bytes memory depositData // royalty receiver should be sent from the relay and not the user
        ) = abi.decode(data, (address, uint64, bytes));

        uint256 tokenId = uint256(flowTokenId);
        // deposit tokens
        FxERC721 childTokenContract = FxERC721(childProxy);

        address _rootProxy = childTokenContract.connectedToken();

        // validate root and child token mapping
        require(
            childProxy != address(0x0) && _rootProxy != address(0x0),
            "FxERC721ChildTunnel: NO_MAPPED_TOKEN"
        );

        // childTokenContract.setApproval(true, tokenId);
        childTokenContract.mint(to, tokenId, depositData);
    }

    function withdrawToFlow(address to, uint256 tokenId) public {
        FxERC721 childTokenContract = FxERC721(childProxy);

        // childTokenContract.setApproval(true, tokenId);
        childTokenContract.burn(tokenId);

        bytes memory message = abi.encode(to, tokenId);

        emit FlowDeposit(message);
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
            address _rootProxy,
            address _childProxy,
            address to,
            uint256 tokenId,
            bytes memory depositData
        ) = abi.decode(syncData, (address, address, address, uint256, bytes));

        // validate root and child token mapping
        require(
            childProxy == _childProxy && rootProxy == _rootProxy,
            "FxERC721ChildTunnel: NO_MAPPED_TOKEN"
        );

        // deposit tokens
        FxERC721 childTokenContract = FxERC721(childProxy);
        // childTokenContract.setApproval(true, tokenId);
        childTokenContract.mint(to, tokenId, depositData);
    }

    // check if address is contract
    function _isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}
