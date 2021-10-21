// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface ICA24Auction {
  function createReserveAuction(
    uint256 tokenId,
    address seller,
    uint256 reservePrice
  ) external;
}
