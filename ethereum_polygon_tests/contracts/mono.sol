// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract mono{
    address public owner;
    constructor (){
        owner = 0x07eC6512C66617fc0Dea66eF8A0622E648481149;
    }
    function getOwner() public view returns (address){
        return owner;
    }
}