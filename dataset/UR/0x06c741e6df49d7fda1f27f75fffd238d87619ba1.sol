 

pragma solidity 0.4.24;

 

 
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

 

 
interface IKODAV2Controls {
  function mint(address _to, uint256 _editionNumber) external returns (uint256);

  function editionActive(uint256 _editionNumber) external view returns (bool);

  function artistCommission(uint256 _editionNumber) external view returns (address _artistAccount, uint256 _artistCommission);

  function updatePriceInWei(uint256 _editionNumber, uint256 _priceInWei) external;
}

 
contract ArtistEditionControls is Ownable, Pausable {
  using SafeMath for uint256;

   
  IKODAV2Controls public kodaAddress;

  event PriceChanged(
    uint256 indexed _editionNumber,
    address indexed _artist,
    uint256 _priceInWei
  );

  constructor(IKODAV2Controls _kodaAddress) public {
    kodaAddress = _kodaAddress;
  }

   
  function gift(address _receivingAddress, uint256 _editionNumber)
  external
  whenNotPaused
  returns (uint256)
  {
    require(_receivingAddress != address(0), "Unable to send to zero address");

    address artistAccount;
    uint256 artistCommission;
    (artistAccount, artistCommission) = kodaAddress.artistCommission(_editionNumber);
    require(msg.sender == artistAccount || msg.sender == owner, "Only from the edition artist account");

    bool isActive = kodaAddress.editionActive(_editionNumber);
    require(isActive, "Only when edition is active");

    return kodaAddress.mint(_receivingAddress, _editionNumber);
  }

   
  function updateEditionPrice(uint256 _editionNumber, uint256 _priceInWei)
  external
  whenNotPaused
  returns (bool)
  {
    address artistAccount;
    uint256 artistCommission;
    (artistAccount, artistCommission) = kodaAddress.artistCommission(_editionNumber);
    require(msg.sender == artistAccount || msg.sender == owner, "Only from the edition artist account");

    bool isActive = kodaAddress.editionActive(_editionNumber);
    require(isActive, "Only when edition is active");

    kodaAddress.updatePriceInWei(_editionNumber, _priceInWei);

    emit PriceChanged(_editionNumber, msg.sender, _priceInWei);

    return true;
  }

   
  function setKodavV2(IKODAV2Controls _kodaAddress) onlyOwner public {
    kodaAddress = _kodaAddress;
  }
}