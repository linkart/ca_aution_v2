// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;


import "../interfaces/ICAAsset.sol";
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
    uint32 artistPoints,
    uint32 sellerPoints,
    uint32 auctionAwardPoints,
    uint32 sharePoints
  );

  ICAAsset immutable caAsset;
  uint32 private caPoints;
  uint32 private sharePoints;
  uint32 private artistPoints;
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
  constructor(
    ICAAsset _caAsset,
    address payable _treasury) {
    require(_treasury != address(0), "NFTMarketFees: Address not zero");
    caAsset = _caAsset;
    treasury = _treasury;

    caPoints = 150;
    sharePoints = 100;
    artistPoints = 1000;
    sellerPoints = 8250;
    auctionAwardPoints = 500;

    withdrawThreshold = 1 ether;
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

  function getArtist(uint256 tokenId) public view returns (address artist) {
      uint256 editionNumber = caAsset.editionOfTokenId(tokenId);
      (artist,) = caAsset.artistCommission(editionNumber);
  }


  /**
   * @notice Returns how funds will be distributed for a sale at the given price point.
   * @dev This could be used to present exact fee distributing on listing or before a bid is placed.
   */
  function getFees(uint tokenId, uint256 price)
    public
    view
    returns (
      uint256 caFee,
      uint256 artistFee,
      uint256 sellerFee,
      uint256 auctionFee,
      uint256 shareFee
    )
  {
    sellerFee = sellerPoints * price / BASIS_POINTS;
    // 首次拍卖的时候，作家即卖家，联名者需参与分成
    if (!nftContractToTokenIdToFirstSaleCompleted[tokenId]) {
        caFee = (caPoints + artistPoints) * price / BASIS_POINTS;
        artistFee = sellerFee;
        sellerFee = 0;
    } else {
        caFee = caPoints * price / BASIS_POINTS;
        artistFee = artistPoints * price / BASIS_POINTS;
    }

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
  function _distributeFunds(
    uint256 tokenId,
    address seller,
    address shareUser,
    uint256 price
  ) internal {
    (uint caFee, uint artistFee, uint sellerFee, ,uint shareFee) = getFees(tokenId, price);
    
    if (shareUser == address(0)) {
      _sendValueWithFallbackWithdrawWithLowGasLimit(treasury, caFee + shareFee);
    } else {
      _sendValueWithFallbackWithdrawWithLowGasLimit(treasury, caFee);
      awards[shareUser] += shareFee;

      emit ShareAwardUpdated(shareUser, shareFee);
    }

      uint256 editionNumber = caAsset.editionOfTokenId(tokenId);
      (address artist, uint256 artistRate) = caAsset.artistCommission(editionNumber);
      (uint256 optionalRate, address optionalRecipient) = caAsset.editionOptionalCommission(editionNumber);
    
      if (optionalRecipient == address(0)) { 
        if (artist == seller) {
          _sendValueWithFallbackWithdrawWithMediumGasLimit(seller, artistFee + sellerFee);
        } else {
          _sendValueWithFallbackWithdrawWithMediumGasLimit(seller, sellerFee);
          _sendValueWithFallbackWithdrawWithMediumGasLimit(artist, artistFee);
        }
      } else {
        uint optionalFee = artistFee * optionalRate / (optionalRate + artistRate);
        if (optionalFee > 0) {
          _sendValueWithFallbackWithdrawWithMediumGasLimit(optionalRecipient, optionalFee);
        }

        if (artist == seller) {
          _sendValueWithFallbackWithdrawWithMediumGasLimit(seller, artistFee + sellerFee - optionalFee);
        } else {
          _sendValueWithFallbackWithdrawWithMediumGasLimit(seller, sellerFee);
          _sendValueWithFallbackWithdrawWithMediumGasLimit(artist, artistFee - optionalFee);
        }
      }

    // Anytime fees are distributed that indicates the first sale is complete,
    // which will not change state during a secondary sale.
    // This must come after the `getFees` call above as this state is considered in the function.
    nftContractToTokenIdToFirstSaleCompleted[tokenId] = true;
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
      uint32 ,
      uint32) {
    return (caPoints, artistPoints, sellerPoints, auctionAwardPoints, sharePoints);
  }


  /**
   * @notice Allows CA to change the market fees.
   */
  function _updateMarketFees(
    uint32 _caPoints,
    uint32 _artistPoints,
    uint32 _sellerPoints,
    uint32 _auctionAwardPoints,
    uint32 _sharePoints
  ) internal {
    require(_caPoints + _artistPoints + _sellerPoints + _auctionAwardPoints + _sharePoints < BASIS_POINTS, "NFTMarketFees: Fees >= 100%");

    caPoints = caPoints;
    artistPoints = _artistPoints;
    sellerPoints = _sellerPoints;
    auctionAwardPoints = _auctionAwardPoints;
    sharePoints = _sharePoints;

    emit MarketFeesUpdated(
      _caPoints,
      _artistPoints,
      _sellerPoints,
      _auctionAwardPoints,
      _sharePoints
    );
  }

}