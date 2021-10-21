// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "./rbac/RBAC.sol";


/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";


  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }


  function addAddressToWhitelist(address _operator)
    public
    onlyOwner
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev getter to determine if address is in whitelist
   */
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

  function addAddressesToWhitelist(address[] memory _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

  function removeAddressFromWhitelist(address _operator)
    public
    onlyOwner
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

  function removeAddressesFromWhitelist(address[] memory _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}
