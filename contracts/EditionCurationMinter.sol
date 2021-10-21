// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./access/Whitelist.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/ICAAsset.sol";
import "./interfaces/ICA24Auction.sol";
import "./interfaces/ISelfServiceAccessControls.sol";
import "./interfaces/ISelfServiceFrequencyControls.sol";


// One invocation per time-period
contract EditionCurationMinter is Whitelist, Pausable {

  // Calling address
  ICAAsset public caAsset;
  ICA24Auction public auction;
  ISelfServiceAccessControls public accessControls;
  ISelfServiceFrequencyControls public frequencyControls;

  // Config which enforces editions to not be over this size
  uint256 public maxEditionSize = 100;

  // Config the minimum price per edition
  uint256 public minPricePerEdition = 0; // 0.01 ether;

  /**
   * @dev Construct a new instance of the contract
   */
  constructor(
    ICAAsset _caAsset,
    ICA24Auction _auction,
    ISelfServiceAccessControls _accessControls,
    ISelfServiceFrequencyControls _frequencyControls
  ) {
    super.addAddressToWhitelist(msg.sender);

    caAsset = _caAsset;
    auction = _auction;
    accessControls = _accessControls;
    frequencyControls = _frequencyControls;
  }

  /**
   * @dev Called by artists, create new edition on the CA platform
   */
  function createEditionFor24Auction(
    address _optionalSplitAddress,
    uint256 _optionalSplitRate,
    uint256 _totalAvailable,
    uint256 _priceInWei,
    uint256 _startDate,
    uint256 _endDate,
    uint256 _artistCommission,
    uint256 _editionType,
    string memory _tokenUri
  )
  public
  whenNotPaused
  returns (uint256 _editionNumber, uint _tokenId)
  {
    address artists = msg.sender;

    require(frequencyControls.canCreateNewEdition(artists), "Sender currently frozen out of creation");
    require((_artistCommission + _optionalSplitRate) <= 100, "Total commission exceeds 100");

    _editionNumber = _createEdition(
      artists,
      [_totalAvailable, _priceInWei, _startDate, _endDate, _artistCommission, _editionType],
      _tokenUri
    );

    if (_optionalSplitRate > 0 && _optionalSplitAddress != address(0)) {
      caAsset.updateOptionalCommission(_editionNumber, _optionalSplitRate, _optionalSplitAddress);
    }

    frequencyControls.recordSuccessfulMint(artists, _totalAvailable, _priceInWei);


    _tokenId = caAsset.mint(address(this), _editionNumber);

    caAsset.approve(address(auction), _tokenId);

    auction.createReserveAuction(_tokenId, artists, _priceInWei);

  }

  /**
   * @dev Internal function for edition creation
   */
  function _createEdition(
    address _artist,
    uint256[6] memory _params,
    string memory _tokenUri
  )
  internal
  returns (uint256 _editionNumber) {

    uint256 _totalAvailable = _params[0];
    uint256 _priceInWei = _params[1];

    address owner = owner();

    // Enforce edition size
    require(msg.sender == owner || (_totalAvailable > 0 && _totalAvailable <= maxEditionSize), "Invalid edition size");

    // Enforce min price
    require(msg.sender == owner || _priceInWei >= minPricePerEdition, "Invalid price");

    // If we are the owner, skip this artists check
    require(msg.sender == owner || accessControls.isEnabledForAccount(_artist), "Not allowed to create edition");

    // Find the next edition number we can use
    uint256 editionNumber = getNextAvailableEditionNumber();

    require(
      caAsset.createActiveEdition(
        editionNumber,
        0x0, // _editionData - no edition data
        _params[5], //_editionType,
        _params[2], // _startDate,
        _params[3], //_endDate,
        _artist,
        _params[4], // _artistCommission - defaults to artistCommission if optional commission split missing
        _priceInWei,
        _tokenUri,
        _totalAvailable
      ),
      "Failed to create new edition"
    );


    return editionNumber;
  }

  /**
   * @dev Internal function for dynamically generating the next KODA edition number
   */
  function getNextAvailableEditionNumber() internal returns (uint256 editionNumber) {

    // Get current highest edition and total in the edition
    uint256 highestEditionNumber = caAsset.highestEditionNumber();
    uint256 totalAvailableEdition = caAsset.totalAvailableEdition(highestEditionNumber);

    // Add the current highest plus its total, plus 1 as tokens start at 1 not zero
    uint256 nextAvailableEditionNumber = highestEditionNumber + totalAvailableEdition + 1;

    // Round up to next 100, 1000 etc based on max allowed size
    return ((nextAvailableEditionNumber + maxEditionSize - 1) / maxEditionSize) * maxEditionSize;
  }

  /**
   * @dev Sets the KODA address
   * @dev Only callable from owner
   */
  function setCAAsset(ICAAsset _caAsset) onlyIfWhitelisted(msg.sender) public {
    caAsset = _caAsset;
  }

  /**
   * @dev Sets the KODA auction
   * @dev Only callable from owner
   */
  function setAuction(ICA24Auction _auction) onlyIfWhitelisted(msg.sender) public {
    auction = _auction;
  }

  /**
   * @dev Sets the max edition size
   * @dev Only callable from owner
   */
  function setMaxEditionSize(uint256 _maxEditionSize) onlyIfWhitelisted(msg.sender) public {
    maxEditionSize = _maxEditionSize;
  }

  /**
   * @dev Sets minimum price per edition
   * @dev Only callable from owner
   */
  function setMinPricePerEdition(uint256 _minPricePerEdition) onlyIfWhitelisted(msg.sender) public {
    minPricePerEdition = _minPricePerEdition;
  }

  /**
   * @dev Checks to see if the account is currently frozen out
   */
  function isFrozen(address account) public view returns (bool) {
    return frequencyControls.canCreateNewEdition(account);
  }

  /**
   * @dev Checks to see if the account can create editions
   */
  function isEnabledForAccount(address account) public view returns (bool) {
    return accessControls.isEnabledForAccount(account);
  }

  /**
   * @dev Checks to see if the account can create editions
   */
  function canCreateAnotherEdition(address account) public view returns (bool) {
    if (!accessControls.isEnabledForAccount(account)) {
      return false;
    }
    return frequencyControls.canCreateNewEdition(account);
  }

  /**
   * @dev Allows for the ability to extract stuck ether
   * @dev Only callable from owner
   */
  function withdrawStuckEther(address _withdrawalAccount) onlyIfWhitelisted(msg.sender) public {
    require(_withdrawalAccount != address(0), "Invalid address provided");
    payable(_withdrawalAccount).transfer(address(this).balance);
  }
}
