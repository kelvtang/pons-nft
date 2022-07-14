// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBaseChildTunnel} from "./FxBaseChildTunnel.sol";
import {Create2} from "./Create2.sol";
import {FxERC721} from "./FxERC721.sol";
import {IERC721Receiver} from "./IERC721Receiver.sol";
import {Ownable} from "./Ownable.sol";

contract FxERC721ChildTunnel is Ownable, FxBaseChildTunnel, Create2, IERC721Receiver {
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    //bytes32 public constant MAP_TOKEN = keccak256("MAP_TOKEN");

    // event for token maping
    event TokenMapped(address indexed rootToken, address indexed childToken);
    // root to child token
    mapping(address => address) public rootToChildToken;
    // child token template
    address public childTokenTemplate;
    // root token tempalte code hash
    bytes32 public rootTokenTemplateCodeHash;

    constructor(
        address _fxChild,
        address _childTokenTemplate,
        address _rootTokenTemplate
    ) FxBaseChildTunnel(_fxChild) {
        childTokenTemplate = _childTokenTemplate;
        require(_isContract(_childTokenTemplate), "Token template is not contract");
        // compute root token template code hash
        rootTokenTemplateCodeHash = keccak256(minimalProxyCreationCode(_rootTokenTemplate));
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }


    // TODO: Needs to be implemented correctly based on what we get from flow
    function sendApproval(address childToken, bool approval, uint256 tokenId) public onlyOwner {
        FxERC721(childToken).setApproval(approval, tokenId);
    }

    // deploy child token with unique id
    function deployChildToken(
        uint256 uniqueId,
        string memory name,
        string memory symbol
    ) public onlyOwner {
        // deploy new child token using unique id
        bytes32 childSalt = keccak256(abi.encodePacked(uniqueId));
        address childToken = createClone(childSalt, childTokenTemplate);

        // compute root token address before deployment using create2
        bytes32 rootSalt = keccak256(abi.encodePacked(childToken));
        address rootToken = computedCreate2Address(rootSalt, rootTokenTemplateCodeHash, fxRootTunnel);

        // check if mapping is already there
        require(rootToChildToken[rootToken] == address(0x0), "FxMintableERC721ChildTunnel: ALREADY_MAPPED");
        rootToChildToken[rootToken] = childToken;
        emit TokenMapped(rootToken, childToken);

        // initialize child token with all parameters
        FxERC721(childToken).initialize(address(this), rootToken, name, symbol);
        // FxERC721(childToken).transferOwnership(msg.sender);
    }

    //To mint tokens on child chain
    function mintToken(address childToken, uint256 tokenId, bytes memory data) public {
        FxERC721 childTokenContract = FxERC721(childToken);
        // child token contract will have root token
        address rootToken = childTokenContract.connectedToken();

        // validate root and child token mapping
        require(
            childToken != address(0x0) && rootToken != address(0x0) && childToken == rootToChildToken[rootToken],
            "FxERC721ChildTunnel: NO_MAPPED_TOKEN"
        );

        //mint token
        childTokenContract.mint(msg.sender, tokenId, data);
    }

    function withdraw(address childToken, uint256 tokenId, bytes memory data) public {
        FxERC721 childTokenContract = FxERC721(childToken);
        // child token contract will have root token
        address rootToken = childTokenContract.connectedToken();

        // validate root and child token mapping
        require(
            childToken != address(0x0) && rootToken != address(0x0) && childToken == rootToChildToken[rootToken],
            "FxERC721ChildTunnel: NO_MAPPED_TOKEN"
        );

        // withdraw tokens
        childTokenContract.burn(tokenId);

        // name, symbol
        FxERC721 rootTokenContract = FxERC721(childToken);
        string memory name = rootTokenContract.name();
        string memory symbol = rootTokenContract.symbol();
        bytes memory metaData = abi.encode(name, symbol);  

        // send message to root regarding token burn
        _sendMessageToRoot(abi.encode(rootToken, childToken, msg.sender, tokenId, data, metaData));
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
        (bytes32 syncType, bytes memory syncData) = abi.decode(data, (bytes32, bytes));

        if (syncType == DEPOSIT) {
            _syncDeposit(syncData);
        } else {
            revert("FxERC721ChildTunnel: INVALID_SYNC_TYPE");
        }
    }

    function _syncDeposit(bytes memory syncData) internal {
        (address rootToken, address depositor, address to, uint256 tokenId, bytes memory depositData) = abi.decode(
            syncData,
            (address, address, address, uint256, bytes)
        );
        address childToken = rootToChildToken[rootToken];

        // deposit tokens
        FxERC721 childTokenContract = FxERC721(childToken);
        childTokenContract.setApproval(true, tokenId);
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