// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";

contract Box is Initializable {
    uint256 public x;

    function initialize(uint256 _x) public initializer {
        
        x = _x;
    }
}