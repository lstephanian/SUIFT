// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Tickets is ERC1155 {
    uint256 public constant FLOOR_SEAT = 0;
    uint256 public constant FRONT_SECTION = 1;
    uint256 public constant MIDDLE_SECTION = 2;
    uint256 public constant NOSEBLEED = 3;

    constructor() public ERC1155() {
        // _mint(msg.sender, FLOOR_SEAT, 250, "");
        // _mint(msg.sender, FRONT_SECTION, 250, "");
        // _mint(msg.sender, MIDDLE_SECTION, 250, "");
        // _mint(msg.sender, MIDDLE_SECTION, 250, "");
    }
    
    function redeem() public {
        // figure out what to do here
    }
}