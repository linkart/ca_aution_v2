pragma solidity >= 0.8.0;

import "./interfaces/ITokenMarketplace.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IAccessControl.sol";

contract NFTMarketplace is ITokenMarketplace {

  event UpdatePlatformPercentageFee(uint256 _oldPercentage, uint256 _newPercentage);

  struct Offer {
    address bidder;
    uint256 offer;
  }

  // Min increase in bid amount
  uint256 public minBidAmount = 0.02 ether;

  IAccessControl public immutable accessControl;

  // account which can receive commission
  address payable public treasury;

  uint256 public platformFeePercentage = 30;

  // Token ID to Offer mapping
  mapping(address => mapping(uint256 => Offer)) offers;

  // Explicitly disable sales for specific tokens
  mapping(address => mapping(uint256 => bool)) disabledTokens;

  ///////////////
  // Modifiers //
  ///////////////

  modifier onlyWhenOfferOwner(address nft, uint256 _tokenId) {
    require(offers[nft][_tokenId].bidder == msg.sender, "Not offer maker");
    _;
  }

  modifier onlyWhenBidOverMinAmount(address nft, uint256 _tokenId) {
    require(msg.value >= offers[nft][_tokenId].offer + minBidAmount, "Offer not enough");
    _;
  }

  modifier onlyWhenTokenAuctionEnabled(address nft, uint256 _tokenId) {
    require(!disabledTokens[nft][_tokenId], "Token not enabled for offers");
    _;
  }

  modifier onlyCAAdmin(address user) {
    require(accessControl.isCAAdmin(user), "CAAdminRole: caller does not have the Admin role");
    _;
  }

  /////////////////
  // Constructor //
  /////////////////

  // Set the caller as the default KO account
  constructor(IAccessControl access, address payable _treasury) public {
    require(_treasury != address(0), "Address not zero");
    accessControl = access;
    treasury = _treasury;
  }

  //////////////////
  // User Actions //
  //////////////////

  function placeBid(address nft, uint256 _tokenId) public override  payable
  onlyWhenBidOverMinAmount(nft, _tokenId)
  onlyWhenTokenAuctionEnabled(nft, _tokenId)
  {
    _refundHighestBidder(nft, _tokenId);

    offers[nft][_tokenId] = Offer(msg.sender, msg.value);

    address currentOwner = IERC721(nft).ownerOf(_tokenId);

    emit BidPlaced(nft, _tokenId, currentOwner, msg.sender, msg.value);
  }

  function withdrawBid(address nft, uint256 _tokenId) public override onlyWhenOfferOwner(nft, _tokenId) {
    _refundHighestBidder(nft, _tokenId);
    emit BidWithdrawn(nft, _tokenId, msg.sender);
  }

  function rejectBid(address nft, uint256 _tokenId) public override {
    address currentOwner = IERC721(nft).ownerOf(_tokenId);
    require(currentOwner == msg.sender, "Not token owner");

    uint256 currentHighestBiddersAmount = offers[nft][_tokenId].offer;
    require(currentHighestBiddersAmount > 0, "No offer open");

    address currentHighestBidder = offers[nft][_tokenId].bidder;

    _refundHighestBidder(nft, _tokenId);

    emit BidRejected(nft, _tokenId, currentOwner, currentHighestBidder, currentHighestBiddersAmount);
  }

  function acceptBid(address nft, uint256 _tokenId) public override {
    address currentOwner = IERC721(nft).ownerOf(_tokenId);
    require(currentOwner == msg.sender, "Not token owner");

    uint256 winningOffer = offers[nft][_tokenId].offer;
    require(winningOffer > 0, "No offer open");

    address winningBidder = offers[nft][_tokenId].bidder;

    delete offers[nft][_tokenId];

    _handleFunds(winningOffer, currentOwner);

    IERC721(nft).safeTransferFrom(msg.sender, winningBidder, _tokenId);

    emit BidAccepted(nft, _tokenId, currentOwner, winningBidder, winningOffer);

  }

  function _refundHighestBidder(address nft, uint256 _tokenId) internal {
    // Get current highest bidder
    address currentHighestBidder = offers[nft][_tokenId].bidder;

    // Get current highest bid amount
    uint256 currentHighestBiddersAmount = offers[nft][_tokenId].offer;

    if (currentHighestBidder != address(0) && currentHighestBiddersAmount > 0) {

      // Clear out highest bidder
      delete offers[nft][_tokenId];

      // Refund it
      payable(currentHighestBidder).transfer(currentHighestBiddersAmount);
    }
  }

  function _handleFunds(uint256 _offer, address _currentOwner) internal {
    // Send current owner majority share of the offer
    uint256 koCommission = _offer * platformFeePercentage / 1000;
    uint256 totalToSendToOwner = _offer - koCommission;

    payable(_currentOwner).transfer(totalToSendToOwner);
    treasury.transfer(koCommission);
  }


  ///////////////////
  // Query Methods //
  ///////////////////

  function tokenOffer(address nft, uint256 _tokenId) external view returns (address _bidder, uint256 _offer, address _owner, bool _enabled) {
    Offer memory offer = offers[nft][_tokenId];
    return (offer.bidder,
    offer.offer,
    IERC721(nft).ownerOf(_tokenId),
    !disabledTokens[nft][_tokenId]);
  }

  function determineSaleValues(address nft, uint256 _tokenId) external view returns (uint256 _sellerTotal, uint256 _platformFee) {
    Offer memory offer = offers[nft][_tokenId];
    uint256 offerValue = offer.offer;
    uint256 fee = offerValue * platformFeePercentage / 1000;

    return (offer.offer - fee, fee);
  }

  ///////////////////
  // Admin Actions //
  ///////////////////

  function disableAuction(address nft, uint256 _tokenId)
  public override 
  onlyCAAdmin(msg.sender)
  {
    _refundHighestBidder(nft, _tokenId);

    disabledTokens[nft][_tokenId] = true;

    emit AuctionDisabled(nft, _tokenId, msg.sender);
  }

  function enableAuction(address nft, uint256 _tokenId)  public override
  onlyCAAdmin(msg.sender)
  {
    _refundHighestBidder(nft, _tokenId);

    disabledTokens[nft][_tokenId] = false;

    emit AuctionEnabled(nft, _tokenId, msg.sender);
  }

  function setMinBidAmount(uint256 _minBidAmount) onlyCAAdmin(msg.sender) public {
    minBidAmount = _minBidAmount;
  }

  function setCATreasury(address payable  _treasury) public onlyCAAdmin(msg.sender) {
    require(_treasury != address(0), "Invalid address");
    treasury = _treasury;
  }

  function setPlatformPercentage(uint256 _platformFeePercentage) public onlyCAAdmin(msg.sender) {
    emit UpdatePlatformPercentageFee(platformFeePercentage, _platformFeePercentage);
    platformFeePercentage = _platformFeePercentage;
  }
}
