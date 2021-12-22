pragma solidity ^0.8.0;

interface IERC721 {

  function ownerOf(uint256 _tokenId) external view returns (address _owner);
  function exists(uint256 _tokenId) external view returns (bool _exists);
  
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

}