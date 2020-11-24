 

 

pragma solidity ^0.4.24;


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

pragma solidity ^0.4.24;



 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 

pragma solidity ^0.4.24;


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

pragma solidity 0.4.24;




interface IKODAV2SelfServiceEditionCuration {

  function createActiveEdition(
    uint256 _editionNumber,
    bytes32 _editionData,
    uint256 _editionType,
    uint256 _startDate,
    uint256 _endDate,
    address _artistAccount,
    uint256 _artistCommission,
    uint256 _priceInWei,
    string _tokenUri,
    uint256 _totalAvailable
  ) external returns (bool);

  function artistsEditions(address _artistsAccount) external returns (uint256[1] _editionNumbers);

  function totalAvailableEdition(uint256 _editionNumber) external returns (uint256);

  function highestEditionNumber() external returns (uint256);
}

interface IKODAAuction {
  function setArtistsControlAddressAndEnabledEdition(uint256 _editionNumber, address _address) external;
}

contract SelfServiceEditionCuration is Ownable, Pausable {
  using SafeMath for uint256;

  event SelfServiceEditionCreated(
    uint256 indexed _editionNumber,
    address indexed _creator,
    uint256 _priceInWei,
    uint256 _totalAvailable,
    bool _enableAuction
  );

   
  IKODAV2SelfServiceEditionCuration public kodaV2;
  IKODAAuction public auction;

   
  uint256 public artistCommission = 85;

   
  bool public openToAllArtist = false;

   
  mapping(address => bool) public allowedArtists;

   
  uint256 public maxEditionSize = 100;

   
  bool public disableInvocationCheck = false;

   
  uint256 public maxInvocations = 3;

   
  uint256 public maxInvocationsTimePeriod = 1 days;

   
  mapping(address => uint256) public invocationsInTimePeriod;

   
  mapping(address => uint256) public timeOfFirstInvocationInPeriod;

   
  constructor(IKODAV2SelfServiceEditionCuration _kodaV2, IKODAAuction _auction) public {
    kodaV2 = _kodaV2;
    auction = _auction;
  }

   
  function createEdition(
    uint256 _totalAvailable,
    uint256 _priceInWei,
    uint256 _startDate,
    string _tokenUri,
    bool _enableAuction
  )
  public
  whenNotPaused
  returns (uint256 _editionNumber)
  {
    validateInvocations();
    return _createEdition(msg.sender, _totalAvailable, _priceInWei, _startDate, _tokenUri, _enableAuction);
  }

   
  function createEditionFor(
    address _artist,
    uint256 _totalAvailable,
    uint256 _priceInWei,
    uint256 _startDate,
    string _tokenUri,
    bool _enableAuction
  )
  public
  onlyOwner
  returns (uint256 _editionNumber)
  {
    return _createEdition(_artist, _totalAvailable, _priceInWei, _startDate, _tokenUri, _enableAuction);
  }

   
  function _createEdition(
    address _artist,
    uint256 _totalAvailable,
    uint256 _priceInWei,
    uint256 _startDate,
    string _tokenUri,
    bool _enableAuction
  )
  internal
  returns (uint256 _editionNumber){

     
    require(_totalAvailable > 0, "Must be at least one available in edition");
    require(_totalAvailable <= maxEditionSize, "Must not exceed max edition size");


     
    if (msg.sender != owner) {

       
      if (!openToAllArtist) {
        require(allowedArtists[_artist], "Only allowed artists can create editions for now");
      }
    }

     
    uint256 editionNumber = getNextAvailableEditionNumber();

     
    require(
      _createNewEdition(editionNumber, _artist, _totalAvailable, _priceInWei, _startDate, _tokenUri),
      "Failed to create new edition"
    );

     
    if (_enableAuction) {
      auction.setArtistsControlAddressAndEnabledEdition(editionNumber, _artist);
    }

     
    emit SelfServiceEditionCreated(editionNumber, _artist, _priceInWei, _totalAvailable, _enableAuction);

    return editionNumber;
  }

   
  function _createNewEdition(
    uint256 _editionNumber,
    address _artist,
    uint256 _totalAvailable,
    uint256 _priceInWei,
    uint256 _startDate,
    string _tokenUri
  )
  internal
  returns (bool) {
    return kodaV2.createActiveEdition(
      _editionNumber,
      0x0,  
      1,  
      _startDate,
      0,  
      _artist,
      artistCommission,
      _priceInWei,
      _tokenUri,
      _totalAvailable
    );
  }

  function validateInvocations() internal {
    if (disableInvocationCheck) {
      return;
    }
    uint256 invocationPeriodStart = timeOfFirstInvocationInPeriod[msg.sender];

     
    if (invocationPeriodStart != 0) {

       
      uint256 timePassedInPeriod = block.timestamp - invocationPeriodStart;

       
      if (timePassedInPeriod < maxInvocationsTimePeriod) {

        uint256 invocations = invocationsInTimePeriod[msg.sender];

         
        require(invocations <= maxInvocations, "Exceeded max invocations for time period");

         
        invocationsInTimePeriod[msg.sender] = invocations + 1;

      } else {
         
        invocationsInTimePeriod[msg.sender] = 1;
        timeOfFirstInvocationInPeriod[msg.sender] = block.number;
      }

    } else {
       
      invocationsInTimePeriod[msg.sender] = 1;
      timeOfFirstInvocationInPeriod[msg.sender] = block.number;
    }
  }

   
  function getNextAvailableEditionNumber()
  internal
  returns (uint256 editionNumber) {

     
    uint256 highestEditionNumber = kodaV2.highestEditionNumber();
    uint256 totalAvailableEdition = kodaV2.totalAvailableEdition(highestEditionNumber);

     
    uint256 nextAvailableEditionNumber = highestEditionNumber.add(totalAvailableEdition).add(1);

     
    return ((nextAvailableEditionNumber + maxEditionSize - 1) / maxEditionSize) * maxEditionSize;
  }

   
  function setKodavV2(IKODAV2SelfServiceEditionCuration _kodaV2) onlyOwner public {
    kodaV2 = _kodaV2;
  }

   
  function setAuction(IKODAAuction _auction) onlyOwner public {
    auction = _auction;
  }

   
  function setArtistCommission(uint256 _artistCommission) onlyOwner public {
    artistCommission = _artistCommission;
  }

   
  function setOpenToAllArtist(bool _openToAllArtist) onlyOwner public {
    openToAllArtist = _openToAllArtist;
  }

   
  function setAllowedArtist(address _artist, bool _allowed) onlyOwner public {
    allowedArtists[_artist] = _allowed;
  }

   
  function setMaxEditionSize(uint256 _maxEditionSize) onlyOwner public {
    maxEditionSize = _maxEditionSize;
  }

   
  function setMaxInvocations(uint256 _maxInvocations) onlyOwner public {
    maxInvocations = _maxInvocations;
  }

   
  function setDisableInvocationCheck(bool _disableInvocationCheck) onlyOwner public {
    disableInvocationCheck = _disableInvocationCheck;
  }

   
  function canCreateAnotherEdition(address account) public view returns (bool) {
    return isEnabledForAccount(account) && invocationsInTimePeriod[account] <= maxInvocations;
  }

   
  function isEnabledForAccount(address account) public view returns (bool) {
    if (openToAllArtist) {
      return true;
    }
    return allowedArtists[account];
  }

   
  function withdrawStuckEther(address _withdrawalAccount) onlyOwner public {
    require(_withdrawalAccount != address(0), "Invalid address provided");
    _withdrawalAccount.transfer(address(this).balance);
  }
}