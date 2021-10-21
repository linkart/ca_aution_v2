// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Interface for OperatorRole which wraps a role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface IAccessControl {

  function isCAAdmin(address _operator) external view returns (bool);
  function hasRole(address _operator, uint8 _role) external view returns (bool);
  function canPlayRole(address _operator, uint8 _role) external view returns (bool);
}