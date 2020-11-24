 

pragma solidity ^0.4.24;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() public {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner(msg.sender));
    _;
  }

   
  function isOwner(address account) public view returns(bool) {
    return account == _owner;
  }

   
  function transferOwnership(address newOwner)
    public
    onlyOwner
  {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner)
    internal
  {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 

 
contract Pausable is Ownable {
  event Paused();
  event Unpaused();

  bool private _paused;

  constructor() public {
    _paused = false;
  }

   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

   
  modifier whenPaused() {
    require(_paused);
    _;
  }

   
  function pause()
    public
    onlyOwner
    whenNotPaused
  {
    _paused = true;
    emit Paused();
  }

   
  function unpause()
    public
    onlyOwner
    whenPaused
  {
    _paused = false;
    emit Unpaused();
  }
}

 

 
contract Operable is Pausable {
  event OperatorAdded(address indexed account);
  event OperatorRemoved(address indexed account);

  mapping (address => bool) private _operators;

  constructor() public {
    _addOperator(msg.sender);
  }

  modifier onlyOperator() {
    require(isOperator(msg.sender));
    _;
  }

  function isOperator(address account)
    public
    view
    returns (bool) 
  {
    require(account != address(0));
    return _operators[account];
  }

  function addOperator(address account)
    public
    onlyOwner
  {
    _addOperator(account);
  }

  function removeOperator(address account)
    public
    onlyOwner
  {
    _removeOperator(account);
  }

  function _addOperator(address account)
    internal
  {
    require(account != address(0));
    _operators[account] = true;
    emit OperatorAdded(account);
  }

  function _removeOperator(address account)
    internal
  {
    require(account != address(0));
    _operators[account] = false;
    emit OperatorRemoved(account);
  }
}

 

contract TimestampNotary is Operable {
  struct Time {
    uint32 declared;
    uint32 recorded;
  }
  mapping (bytes32 => Time) _hashTime;

  event Timestamp(
    bytes32 indexed hash,
    uint32 declaredTime,
    uint32 recordedTime
  );

   
  function addTimestamp(bytes32 hash, uint32 declaredTime)
    public
    onlyOperator
    whenNotPaused
    returns (bool)
  {
    _addTimestamp(hash, declaredTime);
    return true;
  }

   
  function _addTimestamp(bytes32 hash, uint32 declaredTime) internal {
    uint32 recordedTime = uint32(block.timestamp);
    _hashTime[hash] = Time(declaredTime, recordedTime);
    emit Timestamp(hash, declaredTime, recordedTime);
  }

   
  function verifyDeclaredTime(bytes32 hash)
    public
    view
    returns (uint32)
  {
    return _hashTime[hash].declared;
  }

   
  function verifyRecordedTime(bytes32 hash)
    public
    view
    returns (uint32)
  {
    return _hashTime[hash].recorded;
  }
}

 

contract LinkedTokenAbstract {
  function totalSupply() public view returns (uint256);
  function balanceOf(address account) public view returns (uint256);
}


contract LinkedToken is Pausable {
  address internal _token;
  event TokenChanged(address indexed token);
  
   
  function tokenAddress() public view returns (address) {
    return _token;
  }

   
  function setToken(address token) 
    public
    onlyOwner
    whenPaused
    returns (bool)
  {
    _setToken(token);
    emit TokenChanged(token);
    return true;
  }

   
  function _setToken(address token) internal {
    require(token != address(0));
    _token = token;
  }
}

 

contract AssetNotary is TimestampNotary, LinkedToken {
  using SafeMath for uint256;

  bytes8[] private _assetList;
  mapping (bytes8 => uint8) private _assetDecimals;
  mapping (bytes8 => uint256) private _assetBalances;

  event AssetBalanceUpdate(
    bytes8 indexed assetId,
    uint256 balance
  );

  function registerAsset(bytes8 assetId, uint8 decimals)
    public
    onlyOperator
    returns (bool)
  {
    require(decimals > 0);
    require(decimals <= 32);
    _assetDecimals[assetId] = decimals;
    _assetList.push(assetId);
    return true;
  }

  function assetList()
    public
    view
    returns (bytes8[])
  {
    return _assetList;
  }

  function getAssetId(string name)
    public
    pure
    returns (bytes8)
  {
    return bytes8(keccak256(abi.encodePacked(name)));
  }

  function assetDecimals(bytes8 assetId)
    public
    view
    returns (uint8)
  {
    return _assetDecimals[assetId];
  }

  function assetBalance(bytes8 assetId)
    public
    view
    returns (uint256)
  {
    return _assetBalances[assetId];
  }

  function updateAssetBalances(bytes8[] assets, uint256[] balances)
    public
    onlyOperator
    whenNotPaused
    returns (bool)
  {
    uint assetsLength = assets.length;
    require(assetsLength > 0);
    require(assetsLength == balances.length);
    
    for (uint i=0; i<assetsLength; i++) {
      require(_assetDecimals[assets[i]] > 0);
      _assetBalances[assets[i]] = balances[i];
      emit AssetBalanceUpdate(assets[i], balances[i]);
    }
    return true;
  }

  function verifyUserBalance(address user, string assetName)
    public
    view
    returns (uint256)
  {
    LinkedTokenAbstract token = LinkedTokenAbstract(_token);
    uint256 totalShares = token.totalSupply();
    require(totalShares > 0);
    uint256 userShares = token.balanceOf(user);
    bytes8 assetId = getAssetId(assetName);
    return _assetBalances[assetId].mul(userShares) / totalShares;
  }
}

 

contract XFTNotary is AssetNotary {
  string public constant name = 'XFT Asset Notary';
  string public constant version = '0.1';
  
   
  constructor(address token) public {
    _setToken(token);
  }
}