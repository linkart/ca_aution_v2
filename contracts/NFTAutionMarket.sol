
// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;
pragma abicoder v2; // solhint-disable-line

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./aution/SendValueWithFallbackWithdraw.sol";
import "./aution/NFTMarketFees.sol";
import "./aution/NFTMarketAuction.sol";
import "./aution/NFTMarketReserveAuction.sol";


/**
 * @title A market for NFTs on CA.
 * @dev This top level file holds no data directly to ease future upgrades.
 */
contract NFTAutionMarket is
  ReentrancyGuard,
  SendValueWithFallbackWithdraw,
  NFTMarketFees,
  NFTMarketAuction,
  NFTMarketReserveAuction
{
  /**
   * @notice Called once to configure the contract after the initial deployment.
   * @dev This farms the initialize call out to inherited contracts as needed.
   */
  constructor (IAccessControl access,
    address payable treasury)
    NFTMarketFees(treasury)
    NFTMarketReserveAuction(access) {
  }


  /**
   * @notice Allows Foundation to update the market configuration.
   */
  function adminUpdateConfig(
    uint32 minPercentIncrementInBasisPoints,
    uint32 duration,
    uint32 _caPoints,
    uint32 _sellerPoints,
    uint32 _auctionAwardPoints,
    uint32 _sharePoints
  ) public onlyCAAdmin(msg.sender) {
    _updateReserveAuctionConfig(minPercentIncrementInBasisPoints, duration);
    _updateMarketFees(_caPoints, _sellerPoints, _auctionAwardPoints, _sharePoints);
  }

  function adminUpdateWithdrawThreshold(uint256 _withdrawalThreshold) public onlyCAAdmin(msg.sender) {
    _updateWithdrawThreshold(_withdrawalThreshold);
  }

    /**
   * @dev Allows for the ability to extract stuck ether
   * @dev Only callable from owner
   */
  function withdrawStuckEther(address _withdrawalAccount) onlyCAAdmin(msg.sender) public {
    require(_withdrawalAccount != address(0), "Invalid address provided");
    payable(_withdrawalAccount).transfer(address(this).balance);
  }

}