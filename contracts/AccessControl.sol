// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./access/rbac/Roles.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Based on OpenZeppelin Whitelist & RBCA contracts
 * @dev The AccessControl contract provides different access for addresses, and provides basic authorization control functions.
 */
contract AccessControl is Ownable {

  using Roles for Roles.Role;

  uint8 public constant ROLE_CA_ADMIN = 1;
  uint8 public constant ROLE_CA_OPERATOR = 2;

  event RoleAdded(address indexed operator, uint8 role);
  event RoleRemoved(address indexed operator, uint8 role);


  mapping(uint8 => Roles.Role) private roles;



  constructor() Ownable() {
  }

  ////////////////////////////////////
  // Whitelist/RBCA Derived Methods //
  ////////////////////////////////////

  function addAddressToAccessControl(address _operator, uint8 _role)
  public
  onlyOwner
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

  function removeAddressFromAccessControl(address _operator, uint8 _role)
  public
  onlyOwner
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

  function checkRole(address _operator, uint8 _role)
  public
  view
  {
    roles[_role].check(_operator);
  }

  function hasRole(address _operator, uint8 _role)
  public
  view
  returns (bool)
  {
    return roles[_role].has(_operator);
  }

  function isCAAdmin(address _operator) external view returns (bool) {
    if(_operator == owner() || hasRole(_operator, ROLE_CA_ADMIN)) {
      return true;
    }
    return false;
  }

  function canPlayRole(address _operator, uint8 _role) public
  view
  returns (bool)
  {
    if (_operator == owner() || hasRole(_operator, ROLE_CA_ADMIN) || hasRole(_operator, _role)) {
      return true;
    }
    return false;
  }


}
