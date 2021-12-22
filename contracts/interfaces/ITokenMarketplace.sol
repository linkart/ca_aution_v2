pragma solidity >=0.8.0;

interface ITokenMarketplace {

  event BidPlaced(
    address indexed nft,
    uint256 indexed _tokenId,
    address indexed _bidder,
    address _currentOwner,
    uint256 _amount
  );

  event BidWithdrawn(
    address indexed nft,
    uint256 indexed _tokenId,
    address indexed _bidder
  );

  event BidAccepted(
    address indexed nft,
    uint256 indexed _tokenId,
    address indexed _bidder,
    address _currentOwner,
    uint256 _amount
  );

  event BidRejected(
    address indexed nft,
    uint256 indexed _tokenId,
    address indexed _bidder,
    address _currentOwner,
    uint256 _amount
  );

  event AuctionEnabled(
    address indexed nft,
    uint256 indexed _tokenId,
    address indexed _auctioneer
  );

  event AuctionDisabled(
    address indexed nft,
    uint256 indexed _tokenId,
    address indexed _auctioneer
  );

  function placeBid(address nft, uint256 _tokenId)  external payable;

  function withdrawBid(address nft, uint256 _tokenId) external;

  function acceptBid(address nft, uint256 _tokenId) external;

  function rejectBid(address nft, uint256 _tokenId) external;

  function enableAuction(address nft, uint256 _tokenId) external;
  function disableAuction(address nft, uint256 _tokenId) external;
}
