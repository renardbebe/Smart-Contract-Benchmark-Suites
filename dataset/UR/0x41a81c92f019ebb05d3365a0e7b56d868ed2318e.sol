 

pragma solidity 0.5.2;

 

 
interface KongERC20Interface {

  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function mint(uint256 mintedAmount, address recipient) external;
  function getMintingLimit() external returns(uint256);

}

 

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 

 
contract Register {
  using SafeMath for uint256;

   
  address public _owner;

   
  address public _kongERC20Address;

   
  uint256 public _totalMintable;

   
  mapping (address => bool) public _minters;

   
  mapping (address => uint256) public _mintingCaps;

   
  struct Device {
    bytes32 secondaryPublicKeyHash;
    bytes32 tertiaryPublicKeyHash;
    address contractAddress;
    bytes32 hardwareManufacturer;
    bytes32 hardwareModel;
    bytes32 hardwareSerial;
    bytes32 hardwareConfig;
    uint256 kongAmount;
    bool mintable;
  }

   
  mapping(bytes32 => Device) internal _devices;

   
  event Registration(
    bytes32 primaryPublicKeyHash,
    bytes32 secondaryPublicKeyHash,
    bytes32 tertiaryPublicKeyHash,
    address contractAddress,
    bytes32 hardwareManufacturer,
    bytes32 hardwareModel,
    bytes32 hardwareSerial,
    bytes32 hardwareConfig,
    uint256 kongAmount,
    bool mintable
  );

   
  event MinterAddition (
    address minter,
    uint256 mintingCap
  );

  event MinterRemoval (
    address minter
  );

   
  constructor() public {

     
    _owner = 0xAB35D3476251C6b614dC2eb36380D7AF1232D822;

     
    _kongERC20Address = 0x177F2aCE25f81fc50F9F6e9193aDF5ac758e8098;

     
    _mintingCaps[_owner] = (2 ** 25 + 2 ** 24 + 2 ** 23 + 2 ** 22) * 10 ** 18;

  }

   
  modifier onlyOwner() {
    require(_owner == msg.sender, 'Can only be called by owner.');
    _;
  }

   
  modifier onlyOwnerOrMinter() {
    require(_owner == msg.sender || _minters[msg.sender] == true, 'Can only be called by owner or minter.');
    _;
  }

   
  function delegateMintingRights(
    address newMinter,
    uint256 mintingCap
  )
    public
    onlyOwner
  {
     
    _mintingCaps[_owner] = _mintingCaps[_owner].sub(mintingCap);
    _mintingCaps[newMinter] = _mintingCaps[newMinter].add(mintingCap);

     
    _minters[newMinter] = true;

     
    emit MinterAddition(newMinter, _mintingCaps[newMinter]);
  }

   
  function removeMintingRights(
    address minter
  )
    public
    onlyOwner
  {
     
    require(_owner != minter, 'Cannot remove owner from minters.');

     
    _mintingCaps[_owner] = _mintingCaps[_owner].add(_mintingCaps[minter]);
    _mintingCaps[minter] = 0;

     
    _minters[minter] = false;

     
    emit MinterRemoval(minter);
  }

   
  function registerDevice(
    bytes32 primaryPublicKeyHash,
    bytes32 secondaryPublicKeyHash,
    bytes32 tertiaryPublicKeyHash,
    address contractAddress,
    bytes32 hardwareManufacturer,
    bytes32 hardwareModel,
    bytes32 hardwareSerial,
    bytes32 hardwareConfig,
    uint256 kongAmount,
    bool mintable
  )
    public
    onlyOwnerOrMinter
  {
     
    require(_devices[primaryPublicKeyHash].contractAddress == address(0), 'Already registered.');

     
    if (mintable) {

      uint256 _maxMinted = KongERC20Interface(_kongERC20Address).getMintingLimit();
      require(_totalMintable.add(kongAmount) <= _maxMinted, 'Exceeds cumulative limit.');

       
      _totalMintable += kongAmount;

       
      _mintingCaps[msg.sender] = _mintingCaps[msg.sender].sub(kongAmount);
    }

     
    _devices[primaryPublicKeyHash] = Device(
      secondaryPublicKeyHash,
      tertiaryPublicKeyHash,
      contractAddress,
      hardwareManufacturer,
      hardwareModel,
      hardwareSerial,
      hardwareConfig,
      kongAmount,
      mintable
    );

     
    emit Registration(
      primaryPublicKeyHash,
      secondaryPublicKeyHash,
      tertiaryPublicKeyHash,
      contractAddress,
      hardwareManufacturer,
      hardwareModel,
      hardwareSerial,
      hardwareConfig,
      kongAmount,
      mintable
    );
  }

   
  function mintKong(
    bytes32 primaryPublicKeyHash
  )
    external
    onlyOwnerOrMinter
  {
     
    Device memory d = _devices[primaryPublicKeyHash];

     
    require(d.mintable, 'Not mintable / already minted.');
    _devices[primaryPublicKeyHash].mintable = false;

     
    KongERC20Interface(_kongERC20Address).mint(d.kongAmount, d.contractAddress);
  }

   
  function getRegistrationDetails(
    bytes32 primaryPublicKeyHash
  )
    external
    view
    returns (bytes32, bytes32, address, bytes32, bytes32, bytes32, bytes32, uint256, bool)
  {
    Device memory d = _devices[primaryPublicKeyHash];

    return (
      d.secondaryPublicKeyHash,
      d.tertiaryPublicKeyHash,
      d.contractAddress,
      d.hardwareManufacturer,
      d.hardwareModel,
      d.hardwareSerial,
      d.hardwareConfig,
      d.kongAmount,
      d.mintable
    );
  }

   
  function getTertiaryKeyHash(
    bytes32 primaryPublicKeyHash
  )
    external
    view
    returns (bytes32)
  {
    Device memory d = _devices[primaryPublicKeyHash];

    return d.tertiaryPublicKeyHash;
  }

   
  function getKongAmount(
    bytes32 primaryPublicKeyHash
  )
    external
    view
    returns (uint)
  {
    Device memory d = _devices[primaryPublicKeyHash];

    return d.kongAmount;
  }

}