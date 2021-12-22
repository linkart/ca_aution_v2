// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./Constants.sol";
import "./SendValueWithFallbackWithdraw.sol";

/**
 * @notice A mixin to distribute funds when an NFT is sold.
 */
abstract contract NFTMarketFees is
  Constants,
  SendValueWithFallbackWithdraw
{

  event MarketFeesUpdated(
    uint32 caPoints,
    uint32 sellerPoints,
    uint32 auctionAwardPoints,
    uint32 sharePoints
  );

  uint32 private caPoints;
  uint32 private sharePoints;
  uint32 private sellerPoints;
  uint32 private auctionAwardPoints;
  
  uint256 public withdrawThreshold;

  address payable private treasury;


  mapping(address => uint256) public awards;

  mapping(uint256 => bool) private nftContractToTokenIdToFirstSaleCompleted;


  event AuctionAwardUpdated(uint256 indexed auctionId, address indexed bidder, uint256 award);
  event ShareAwardUpdated(address indexed share, uint256 award);

  /**
   * @dev Called once after the initial deployment to set the CART treasury address.
   */
  constructor(address payable _treasury) {
    require(_treasury != address(0), "NFTMarketFees: Address not zero");
    treasury = _treasury;

    caPoints = 150;
    sharePoints = 100;
    sellerPoints = 9250;
    auctionAwardPoints = 500;

    withdrawThreshold = 0.1 ether;
  }

  function setCATreasury(address payable _treasury) external {
    require(_treasury != msg.sender, "NFTMarketFees: no permission");
    require(_treasury != address(0), "NFTMarketFees: Address not zero");
    treasury = _treasury;
  }

  /**
   * @notice Returns the address of the CART treasury.
   */
  function getCATreasury() public view returns (address payable) {
    return treasury;
  }

  /**
   * @notice Returns true if the given NFT has not been sold in this market previously and is being sold by the creator.
   */
  function getIsPrimary(uint256 tokenId) public view returns (bool) {
    return !nftContractToTokenIdToFirstSaleCompleted[tokenId];
  }

  /**
   * @notice Returns how funds will be distributed for a sale at the given price point.
   * @dev This could be used to present exact fee distributing on listing or before a bid is placed.
   */
  function getFees(uint256 price)
    public
    view
    returns (
      uint256 caFee,
      uint256 sellerFee,
      uint256 auctionFee,
      uint256 shareFee
    )
  {
    sellerFee = sellerPoints * price / BASIS_POINTS;
    caFee = caPoints * price / BASIS_POINTS;
    auctionFee = auctionAwardPoints * price / BASIS_POINTS;
    shareFee = sharePoints * price / BASIS_POINTS;
  }

  function withdrawFunds(address to) external {
    require(awards[msg.sender] >= withdrawThreshold, "NFTMarketFees: under withdrawThreshold");
    uint wdAmount= awards[msg.sender];
    awards[msg.sender] = 0;
    _sendValueWithFallbackWithdrawWithMediumGasLimit(to, wdAmount);
  }

  function _distributeBidFunds(
      uint256 lastPrice,
      uint256 auctionId,
      uint256 price,
      address bidder
  ) internal {
      uint award = auctionAwardPoints * (price - lastPrice) / BASIS_POINTS;
      awards[bidder] += award;

      emit AuctionAwardUpdated(auctionId, bidder, award);
  }

  /**
   * @dev Distributes funds to foundation, creator, and NFT owner after a sale.
   */
  function _distributeFunds(address seller,
    address shareUser,
    uint256 price
  ) internal {
    (uint caFee, uint sellerFee, , uint shareFee) = getFees(price);
    
    if (shareUser == address(0)) {
      _sendValueWithFallbackWithdrawWithLowGasLimit(treasury, caFee + shareFee);
    } else {
      _sendValueWithFallbackWithdrawWithLowGasLimit(treasury, caFee);
      awards[shareUser] += shareFee;

      emit ShareAwardUpdated(shareUser, shareFee);
    }

    _sendValueWithFallbackWithdrawWithMediumGasLimit(seller, sellerFee);
  }


  /**
   * @notice Returns the current fee configuration in basis points.
   */
  function getFeeConfig()
    public
    view
    returns (
      uint32 ,
      uint32 ,
      uint32 ,
      uint32) {
    return (caPoints, sellerPoints, auctionAwardPoints, sharePoints);
  }

  function _updateWithdrawThreshold(uint256 _withdrawalThreshold) internal {
    withdrawThreshold = _withdrawalThreshold;
  }

  /**
   * @notice Allows CA to change the market fees.
   */
  function _updateMarketFees(
    uint32 _caPoints,
    uint32 _sellerPoints,
    uint32 _auctionAwardPoints,
    uint32 _sharePoints
  ) internal {
    require(_caPoints + _sellerPoints + _auctionAwardPoints + _sharePoints < BASIS_POINTS, "NFTMarketFees: Fees >= 100%");

    caPoints = caPoints;
    sellerPoints = _sellerPoints;
    auctionAwardPoints = _auctionAwardPoints;
    sharePoints = _sharePoints;

    emit MarketFeesUpdated(
      _caPoints,
      _sellerPoints,
      _auctionAwardPoints,
      _sharePoints
    );
  }

}