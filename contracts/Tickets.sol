// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Tickets is ERC1155, Ownable {
    uint256 public constant FLOOR_SEAT = 0; 
    uint256 public constant FRONT_SECTION = 1;
    uint256 public constant MIDDLE_SECTION = 2;
    uint256 public constant NOSEBLEED = 3;

    constructor() ERC1155("https://copper-impossible-nightingale-714.mypinata.cloud/ipfs/QmT3qNGpB4kAxzn2nNJZ75kqf29gBQ2TizQv4GXb8SBe9s/{id}.json") { 
    }

    function mint(address beneficiary, uint id, uint amount) public onlyOwner {
        require(id == 0 || id == 1 || id == 2 || id == 3, "Token does not exist");
        _mint(beneficiary, id, amount, "");
    }
}