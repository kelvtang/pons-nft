// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBaseRootTunnel} from "./FxBaseRootTunnel.sol";
import {Create2} from "./Create2.sol";
import {FxERC721} from "./FxERC721.sol";
import {IERC721Receiver} from "./IERC721Receiver.sol";
/**
 * @title FxERC721RootTunnel
 */
contract FxERC721RootTunnel is FxBaseRootTunnel, Create2, IERC721Receiver {
    // maybe DEPOSIT and MAP_TOKEN can be reduced to bytes4
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    //bytes32 public constant MAP_TOKEN = keccak256("MAP_TOKEN");

    mapping(address => address) public rootToChildTokens;
    address public rootTokenTemplate;
    bytes32 public childTokenTemplateCodeHash;

    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _rootTokenTemplate
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
        rootTokenTemplate = _rootTokenTemplate;
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
        address rootToken,
        address user,
        uint256 tokenId,
        bytes memory data
    ) public {
        // map token if not mapped
        require(rootToChildTokens[rootToken] != address(0x0), "FxMintableERC721RootTunnel: NO_MAPPING_FOUND");

        // transfer from depositor to this contract
        FxERC721(rootToken).safeTransferFrom(
            msg.sender, // depositor
            address(this), // manager contract
            tokenId,
            data
        );
  
        // DEPOSIT, encode(rootToken, depositor, user, tokenId, extra data)
        bytes memory message = abi.encode(DEPOSIT, abi.encode(rootToken, msg.sender, user, tokenId, data));
        _sendMessageToChild(message);
    }

    // exit processor
    function _processMessageFromChild(bytes memory data) internal override {
        (address rootToken, address childToken, address to, uint256 tokenId, bytes memory syncData, bytes memory metaData) = abi.decode(
            data,
            (address, address, address, uint256, bytes, bytes)
        );

        // if root token is not available, create it
        if (!_isContract(rootToken) && rootToChildTokens[rootToken] == address(0x0)) {
            (string memory name, string memory symbol) = abi.decode(metaData, (string, string));

            address _createdToken = _deployRootToken(childToken, name, symbol);
            require(_createdToken == rootToken, "FxMintableERC721RootTunnel: ROOT_TOKEN_CREATION_MISMATCH");
        }

        // validate mapping for root to child
        require(rootToChildTokens[rootToken] == childToken, "FxERC721RootTunnel: INVALID_MAPPING_ON_EXIT");

        FxERC721 tokenObj = FxERC721(rootToken);

        //approve token transfer
        if (!tokenObj.exists(tokenId)) {
            FxERC721(rootToken).setApproval(true, tokenId);
            tokenObj.mint(to, tokenId, syncData);
        } else {
            // transfer from tokens
            tokenObj.safeTransferFrom(
                address(this),
                to,
                tokenId,
                syncData
            );
        }
    }

    function _deployRootToken(
        address childToken,
        string memory name,
        string memory symbol
    ) internal returns (address) {
        // deploy new root token
        bytes32 salt = keccak256(abi.encodePacked(childToken));
        address rootToken = createClone(salt, rootTokenTemplate);
        FxERC721(rootToken).initialize(address(this), rootToken, name, symbol);
        // FxERC721(rootToken).transferOwnership(msg.sender);

        // add into mapped tokens
        rootToChildTokens[rootToken] = childToken;

        return rootToken;
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