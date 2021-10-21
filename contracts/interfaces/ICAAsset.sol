// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface ICAAsset {

  function ownerOf(uint256 _tokenId) external view returns (address _owner);
  function exists(uint256 _tokenId) external view returns (bool _exists);
  
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from , address _to, uint256 _tokenId, bytes memory _data) external;

  function editionOfTokenId(uint256 _tokenId) external view returns (uint256 tokenId);

  function artistCommission(uint256 _tokenId) external view returns (address _artistAccount, uint256 _artistCommission);

  function editionOptionalCommission(uint256 _tokenId) external view returns (uint256 _rate, address _recipient);

  function mint(address _to, uint256 _editionNumber) external returns (uint256);

  function approve(address _to, uint256 _tokenId) external;



  function createActiveEdition(
    uint256 _editionNumber,
    bytes32 _editionData,
    uint256 _editionType,
    uint256 _startDate,
    uint256 _endDate,
    address _artistAccount,
    uint256 _artistCommission,
    uint256 _priceInWei,
    string memory _tokenUri,
    uint256 _totalAvailable
  ) external returns (bool);

  function artistsEditions(address _artistsAccount) external returns (uint256[] memory _editionNumbers);

  function totalAvailableEdition(uint256 _editionNumber) external returns (uint256);

  function highestEditionNumber() external returns (uint256);

  function updateOptionalCommission(uint256 _editionNumber, uint256 _rate, address _recipient) external;

  function updateStartDate(uint256 _editionNumber, uint256 _startDate) external;

  function updateEndDate(uint256 _editionNumber, uint256 _endDate) external;

  function updateEditionType(uint256 _editionNumber, uint256 _editionType) external;
}
