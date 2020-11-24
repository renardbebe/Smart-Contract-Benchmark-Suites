 

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

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 
contract AccessByGame is Pausable, Claimable {
  mapping(address => bool) internal contractAccess;

  modifier onlyAccessByGame {
    require(!paused && (msg.sender == owner || contractAccess[msg.sender] == true));
    _;
  }

  function grantAccess(address _address)
    onlyOwner
    public
  {
    contractAccess[_address] = true;
  }

  function revokeAccess(address _address)
    onlyOwner
    public
  {
    contractAccess[_address] = false;
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract ERC827 is ERC20 {
  function approveAndCall(
    address _spender,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool);

  function transferAndCall(
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool);

  function transferFromAndCall(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool);
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract ERC827Caller {
  function makeCall(address _target, bytes _data) external payable returns (bool) {
     
    return _target.call.value(msg.value)(_data);
  }
}

 
contract ERC827Token is ERC827, StandardToken {
  ERC827Caller internal caller_;

  constructor() public {
    caller_ = new ERC827Caller();
  }

   
  function approveAndCall(
    address _spender,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool)
  {
    require(_spender != address(this));

    super.approve(_spender, _value);

     
    require(caller_.makeCall.value(msg.value)(_spender, _data));

    return true;
  }

   
  function transferAndCall(
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool)
  {
    require(_to != address(this));

    super.transfer(_to, _value);

     
    require(caller_.makeCall.value(msg.value)(_to, _data));
    return true;
  }

   
  function transferFromAndCall(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  )
    public payable returns (bool)
  {
    require(_to != address(this));

    super.transferFrom(_from, _to, _value);

     
    require(caller_.makeCall.value(msg.value)(_to, _data));
    return true;
  }

   
  function increaseApprovalAndCall(
    address _spender,
    uint _addedValue,
    bytes _data
  )
    public
    payable
    returns (bool)
  {
    require(_spender != address(this));

    super.increaseApproval(_spender, _addedValue);

     
    require(caller_.makeCall.value(msg.value)(_spender, _data));

    return true;
  }

   
  function decreaseApprovalAndCall(
    address _spender,
    uint _subtractedValue,
    bytes _data
  )
    public
    payable
    returns (bool)
  {
    require(_spender != address(this));

    super.decreaseApproval(_spender, _subtractedValue);

     
    require(caller_.makeCall.value(msg.value)(_spender, _data));

    return true;
  }

}

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 
 
contract EverGold is ERC827Token, MintableToken, AccessByGame {
  string public constant name = "Ever Gold";
  string public constant symbol = "EG";
  uint8 public constant decimals = 0;

 
  function mint(
    address _to,
    uint256 _amount
  )
    onlyAccessByGame
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }
  function transfer(address _to, uint256 _value)
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value)
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value)
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function approveAndCall(
    address _spender,
    uint256 _value,
    bytes _data
  )
    public
    payable
    whenNotPaused
    returns (bool)
  {
    return super.approveAndCall(_spender, _value, _data);
  }

  function transferAndCall(
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    payable
    whenNotPaused
    returns (bool)
  {
    return super.transferAndCall(_to, _value, _data);
  }

  function transferFromAndCall(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    payable
    whenNotPaused
    returns (bool)
  {
    return super.transferFromAndCall(_from, _to, _value, _data);
  }

  function increaseApprovalAndCall(
    address _spender,
    uint _addedValue,
    bytes _data
  )
    public
    payable
    whenNotPaused
    returns (bool)
  {
    return super.increaseApprovalAndCall(_spender, _addedValue, _data);
  }

  function decreaseApprovalAndCall(
    address _spender,
    uint _subtractedValue,
    bytes _data
  )
    public
    payable
    whenNotPaused
    returns (bool)
  {
    return super.decreaseApprovalAndCall(_spender, _subtractedValue, _data);
  }
}

library StringLib {
  function generateName(bytes16 _s, uint256 _len, uint256 _n)
    public
    pure
    returns (bytes16 ret)
  {
    uint256 v = _n;
    bytes16 num = 0;
    while (v > 0) {
      num = bytes16(uint(num) / (2 ** 8));
      num |= bytes16(((v % 10) + 48) * 2 ** (8 * 15));
      v /= 10;
    }
    ret = _s | bytes16(uint(num) / (2 ** (8 * _len)));
    return ret;
  }
}

 
contract ERC721Basic {
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

 
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}


 
contract ERC721Metadata is ERC721Basic {
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

 
contract ERC721Receiver {
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  function onERC721Received(
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

 
contract ERC721BasicToken is ERC721Basic {
  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256) internal ownedTokensCount;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

   
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(owner, _to, _tokenId);
    }
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
     
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
     
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

   
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
     
     
     
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
      emit Approval(_owner, address(0), _tokenId);
    }
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

   
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

 
contract ERC721Token is ERC721, ERC721BasicToken {
   
  string internal name_;

   
  string internal symbol_;

   
  mapping(address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  mapping(uint256 => string) internal tokenURIs;

   
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;
  }

   
  function name() public view returns (string) {
    return name_;
  }

   
  function symbol() public view returns (string) {
    return symbol_;
  }

   
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

   
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

   
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

   
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

   
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

     
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

     
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}

contract CastleToken is ERC721Token, AccessByGame {
  string constant NAME = "Crypto Ninja Game Castle";
  string constant SYMBOL = "CNC";

  uint256 constant MAX_WIDTH = 10;

  uint8 constant LOG_SET = 0;
  uint8 constant LOG_RESET = 1;
  uint8 constant LOG_WIN = 2;
  uint8 constant LOG_LOSS = 3;

  struct Castle {
    bytes16 name;
    uint16 level;
    uint32 exp;
    uint8 width;
    uint8 depth;
    uint32 readyTime;
    uint16 tryCount;
    uint16 winCount;
    uint16 lossCount;
    uint8 levelPoint;
    uint16 reward;
  }

  mapping (uint256 => bytes) internal traps;
  mapping (uint256 => bytes32[]) internal logs;

  EverGold internal goldToken;

  uint8 public initWidth = 5;
  uint8 public initDepth = 8;

  uint256 public itemsPerPage = 10;

  uint8 internal expOnSuccess = 3;
  uint8 internal expOnFault = 1;
  uint8 internal leveupExp = 10;

  uint256 internal cooldownTime = 5 minutes;

  Castle[] internal castles;

  uint16 public price = 1000;

  event NewCastle(uint256 castleid, uint256 width, uint256 depth);
  event SetTraps(uint256 castleid);
  event ResetTraps(uint256 castleid);
  event UseTrap(uint256 castleid, uint256 path, uint256 trapIndex, uint256 power);

  event AddLog(uint8 id, uint32 datetime, uint256 castleid, uint256 ninjaid, uint8 x, uint8 y, bool win);

  constructor()
    public
    ERC721Token(NAME, SYMBOL)
  {
    castles.push(Castle({
      name: "DUMMY", level: 0, exp: 0,
      width: 0, depth: 0,
      readyTime: 0,
      tryCount: 0, winCount: 0, lossCount: 0,
      levelPoint: 0,
      reward: 0}));
  }

  function mint(address _beneficiary)
    public
    whenNotPaused
    onlyAccessByGame
    returns (bool)
  {
    require(_beneficiary != address(0));
    return _create(_beneficiary, initWidth, initDepth);
  }

  function setTraps(
    uint256 _castleid,
    uint16 _reward,
    bytes _traps)
    public
    whenNotPaused()
    onlyAccessByGame
    returns (bool)
  {
    require((_castleid > 0) && (_castleid < castles.length));
    require(_reward > 0);
    Castle storage castle = castles[_castleid];
    castle.reward = _reward;
    traps[_castleid] = _traps;

    logs[_castleid].push(_generateLog(uint32(now), LOG_SET, 0, 0, 0, 0));

    emit SetTraps(_castleid);

    return true;
  }

  function resetTraps(uint256 _castleid)
    public
    onlyAccessByGame
    returns (bool)
  {
    require((_castleid > 0) && (_castleid < castles.length));
    Castle storage castle = castles[_castleid];
    for (uint256 i = 0; i < castle.width * castle.depth; i++) {
      traps[_castleid][i] = byte(0);
    }
    castle.reward = 0;
    logs[_castleid].push(_generateLog(uint32(now), LOG_RESET, 0, 0, 0, 0));

    emit ResetTraps(_castleid);

    return true;
  }

  function win(
    uint256 _castleid, uint256 _ninjaid, uint256 _path, bytes _steps, uint256 _count)
    public
    onlyAccessByGame
    returns (bool)
  {
    require((_castleid > 0) && (_castleid < castles.length));
    uint8 width = getWidth(_castleid);
    for (uint256 i = 0; i < _count; i++) {
      traps[_castleid][uint256(_steps[i])] = byte(0);
    }
    Castle storage castle = castles[_castleid];
    castle.winCount++;
    castle.exp += expOnSuccess;
    castle.levelPoint += expOnSuccess;
    _levelUp(castle);
    logs[_castleid].push(
      _generateLog(
        uint32(now), LOG_WIN, uint32(_ninjaid),
        uint8(_path % width), uint8(_path / width), 1
      )
    );

    _triggerCooldown(_castleid);

    return true;
  }

  function lost(uint256 _castleid, uint256 _ninjaid)
    public
    onlyAccessByGame
    returns (bool)
  {
    require((_castleid > 0) && (_castleid < castles.length));
    Castle storage castle = castles[_castleid];
    castle.reward = 0;
    castle.lossCount++;
    castle.exp += expOnFault;
    castle.levelPoint += expOnFault;
    _levelUp(castle);

    logs[_castleid].push(_generateLog(uint32(now), LOG_LOSS, uint32(_ninjaid), 0, 0, 0));

    resetTraps(_castleid);

    _triggerCooldown(_castleid);

    return true;
  }

  function setName(uint256 _castleid, bytes16 _newName)
    external
    onlyOwnerOf(_castleid)
  {
    castles[_castleid].name = _newName;
  }

  function setGoldContract(address _goldTokenAddress)
    public
    onlyOwner
  {
    require(_goldTokenAddress != address(0));

    goldToken = EverGold(_goldTokenAddress);
  }

  function setFee(uint16 _price)
    external
    onlyOwner
  {
    price = _price;
  }

  function setItemPerPage(uint16 _amount)
    external
    onlyOwner
  {
    itemsPerPage = _amount;
  }

  function setMaxCoordinate(uint256 _cooldownTime)
    public
    onlyOwner
  {
    cooldownTime = _cooldownTime;
  }

  function _create(address _beneficiary, uint8 _width, uint8 _depth)
    internal
    onlyAccessByGame
    returns (bool)
  {
    require(_beneficiary != address(0));
    require((_width > 0) && (_depth > 0));
    uint256 tokenid = castles.length;
    bytes16 name = StringLib.generateName("CASTLE#", 7, tokenid);

    uint256 id = castles.push(Castle({
      name: name, level: 1, exp: 0,
      width: _width, depth: _depth,
      readyTime: uint32(now + cooldownTime),
      tryCount: 0, winCount: 0, lossCount: 0,
      levelPoint: 0,
      reward: 0})) - 1;

    traps[id] = new bytes(_width * _depth);
    _mint(_beneficiary, id);
    emit NewCastle(id, _width, _depth);

    return true;
  }

  function _levelUp(Castle storage _castle)
    internal
    onlyAccessByGame
  {
    if (_castle.levelPoint >= leveupExp) {
      _castle.levelPoint -= leveupExp;
      _castle.level++;
    }
  }

  function _triggerCooldown(uint256 _castleid)
    internal
    onlyAccessByGame
  {
    require((_castleid > 0) && (_castleid < castles.length));
    Castle storage castle = castles[_castleid];
    castle.readyTime = uint32(now + cooldownTime);
  }

  function getAll()
    external
    view
    returns (uint256[] result)
  {
    return allTokens;
  }

  function getOpen(uint256 _startIndex)
    external
    view
    returns (uint256[] result)
  {
    uint256 n = 0;
    uint256 i = 0;
    for (i = _startIndex; i < castles.length; i++) {
      Castle storage castle = castles[i];
      if ((castle.reward > 0) &&
          (ownerOf(i) != msg.sender)) {
        n++;
        if (n >= _startIndex) {
          break;
        }
      }
    }
    uint256[] memory castleids = new uint256[](itemsPerPage + 1);
    n = 0;
    while (i < castles.length) {
      castle = castles[i];
      if ((castle.reward > 0) &&
          (ownerOf(i) != msg.sender)) {
        castleids[n++] = i;
        if (n > itemsPerPage) {
          break;
        }
      }
      i++;
    }
    return castleids;
  }

  function getByOwner(address _owner)
    external
    view
    returns (uint256[] result)
  {
    return ownedTokens[_owner];
  }

  function getInfo(uint256 _castleid)
    external
    view
    returns (bytes16, uint16, uint32,
      uint8, uint8, uint16, uint16,
      uint16)
  {
    require((_castleid > 0) && (_castleid < castles.length));
    Castle storage castle = castles[_castleid];
    return (
      castle.name,
      castle.level,
      castle.exp,
      castle.width,
      castle.depth,
      castle.winCount,
      castle.lossCount,
      castle.reward);
  }

  function getLevel(uint256 _castleid)
    external
    view
    returns (uint16)
  {
    Castle storage castle = castles[_castleid];
    return castle.level;
  }

  function getLogs(uint256 _castleid)
    external
    view
    returns (bytes32[])
  {
    require((_castleid > 0) && (_castleid < castles.length));
    return logs[_castleid];
  }

  function getTrapInfo(uint256 _castleid)
    external
    view
    returns (bytes)
  {
    require((ownerOf(_castleid) == msg.sender) || (contractAccess[msg.sender] == true));
    return traps[_castleid];
  }

  function isReady(uint256 _castleid)
    public
    view
    returns (bool)
  {
    require((_castleid > 0) && (_castleid < castles.length));
    Castle storage castle = castles[_castleid];
    return (castle.readyTime <= now);
  }

  function getReward(uint256 _castleid)
    public
    view
    returns (uint16)
  {
    require((_castleid > 0) && (_castleid < castles.length));
    Castle storage castle = castles[_castleid];
    return castle.reward;
  }

  function getWidth(uint256 _castleid)
    public
    view
    returns (uint8)
  {
    require((_castleid > 0) && (_castleid < castles.length));
    Castle storage castle = castles[_castleid];
    return castle.width;
  }

  function getTrapid(uint256 _castleid, uint8 _path)
    public
    onlyAccessByGame
    view
    returns (uint8)
  {
    return uint8(traps[_castleid][_path]);
  }

  function getPrice()
    public
    view
    returns (uint256)
  {
    return price;
  }

  function _generateLog(
    uint32 _datetime,
    uint8 _id,
    uint32 _ninjaid,
    uint8 _x,
    uint8 _y,
    uint8 _win)
    internal
    pure
    returns (bytes32)
  {
    return
      bytes32(
        (uint256(_datetime) * (2 ** (8 * 28))) |
        (uint256(_id) * (2 ** (8 * 24))) |
        (uint256(_ninjaid) * (2 ** (8 * 20))) |
        (uint256(_x) * (2 ** (8 * 16))) |
        (uint256(_y) * (2 ** (8 * 12))) |
        (uint256(_win) * (2 ** (8 * 8))));
  }
}

contract ItemToken is AccessByGame {
  struct Item {
    bytes16 name;
    uint16 price;
    uint16 power;
    bool enabled;
  }

  EverGold internal goldToken;

  Item[] private items;

  uint8 public itemKindCount = 0;

  mapping (address => mapping (uint256 => uint256)) private ownedItems;

  event NewItem(bytes32 name, uint16 price, uint16 power);
  event UseItem(uint256 itemid, uint256 amount);

  constructor()
    public
  {
    addItem("None", 0, 0, false);
    addItem("Arrow", 10, 10, true);
    addItem("Tiger", 30, 20, true);
    addItem("Spear", 50, 30, true);
    addItem("Wood", 50, 20, true);
    addItem("Fire", 50, 20, true);
    addItem("Earth", 50, 20, true);
    addItem("Metal", 50, 20, true);
    addItem("Water", 50, 20, true);
  }

  function setGoldContract(address _goldTokenAddress)
    public
    onlyOwner
  {
    require(_goldTokenAddress != address(0));

    goldToken = EverGold(_goldTokenAddress);
  }

  function buy(address _to, uint256 _itemid, uint256 _amount)
    public
    onlyAccessByGame
    whenNotPaused
    returns (bool)
  {
    require(_amount > 0);
    require(_itemid > 0 && _itemid < itemKindCount);
    ownedItems[_to][_itemid] += _amount;

    return true;
  }

  function useItem(address _owner, uint256 _itemid, uint256 _amount)
    public
    onlyAccessByGame
    whenNotPaused
    returns (bool)
  {
    require(_amount > 0);
    require((_itemid > 0) && (_itemid < itemKindCount));
    require(_amount <= ownedItems[_owner][_itemid]);

    ownedItems[_owner][_itemid] -= _amount;

    emit UseItem(_itemid, _amount);

    return true;
  }

  function addItem(bytes16 _name, uint16 _price, uint16 _power, bool _enabled)
    public
    onlyOwner()
    returns (bool)
  {
    require(_name != 0x0);
    items.push(Item({
      name:_name,
      price: _price,
      power: _power,
      enabled: _enabled
      }));
    itemKindCount++;

    emit NewItem(_name, _price, _power);
    return true;
  }

  function setItemAvailable(uint256 _itemid, bool _enabled)
    public
    onlyOwner()
  {
    require(_itemid > 0 && _itemid < itemKindCount);

    items[_itemid].enabled = _enabled;
  }

  function getItemCounts()
    public
    view
    returns (uint256[])
  {
    uint256[] memory itemCounts = new uint256[](itemKindCount);
    for (uint256 i = 0; i < itemKindCount; i++) {
      itemCounts[i] = ownedItems[msg.sender][i];
    }
    return itemCounts;
  }

  function getItemCount(uint256 _itemid)
    public
    view
    returns (uint256)
  {
    require(_itemid > 0 && _itemid < itemKindCount);
    return ownedItems[msg.sender][_itemid];
  }

  function getItemKindCount()
    public
    view
    returns (uint256)
  {
    return itemKindCount;
  }

  function getItem(uint256 _itemid)
    public
    view
    returns (bytes16 name, uint16 price, uint16 power, bool enabled)
  {
    require(_itemid < itemKindCount);
    return (items[_itemid].name, items[_itemid].price, items[_itemid].power, items[_itemid].enabled);
  }

  function getPower(uint256 _itemid)
    public
    view
    returns (uint16 power)
  {
    require(_itemid < itemKindCount);
    return items[_itemid].power;
  }

  function getPrice(uint256 _itemid)
    public
    view
    returns (uint16)
  {
    require(_itemid < itemKindCount);
    return items[_itemid].price;
  }
}

contract NinjaToken is ERC721Token, AccessByGame {
  string public constant NAME = "Crypto Ninja Game Ninja";
  string public constant SYMBOL = "CNN";

  event NewNinja(uint256 ninjaid, bytes16 name, bytes32 pattern);

  struct Ninja {
    bytes32 pattern;
    bytes16 name;
    uint16 level;
    uint32 exp;
    uint8 dna1;
    uint8 dna2;
    uint32 readyTime;
    uint16 winCount;
    uint8 levelPoint;
    uint16 lossCount;
    uint16 reward;
    uint256 lastAttackedCastleid;
  }

  mapping (uint256 => bytes) private paths;

  mapping (uint256 => bytes) private steps;

  EverGold internal goldToken;

  uint8 internal expOnSuccess = 3;
  uint8 internal expOnFault = 1;
  uint8 internal leveupExp = 10;

  uint256 internal cooldownTime = 5 minutes;

  uint256 internal maxCoordinate = 12;

  Ninja[] internal ninjas;

  uint256 private randNonce = 0;

  uint8 public kindCount = 2;
  uint32[] public COLORS = [
    0xD7003A00,
    0xF3980000,
    0x00552E00,
    0x19448E00,
    0x543F3200,
    0xE7609E00,
    0xFFEC4700,
    0x68BE8D00,
    0x0095D900,
    0xE9DFE500,
    0xEE836F00,
    0xF2F2B000,
    0xAACF5300,
    0x0A3AF00,
    0xF8FBF800,
    0xF4B3C200,
    0x928C3600,
    0xA59ACA00,
    0xABCED800,
    0x30283300,
    0xFDEFF200,
    0xDDBB9900,
    0x74539900,
    0xAA4C8F00
  ];

  uint256 public price = 1000;

  constructor()
      public
      ERC721Token(NAME, SYMBOL)
  {
    ninjas.push(Ninja({
      pattern: 0, name: "DUMMY", level: 0, exp: 0,
      dna1: 0, dna2: 0,
      readyTime: 0,
      winCount: 0, lossCount: 0,
      levelPoint:0, reward: 0,
      lastAttackedCastleid: 0 }));
  }

  function mint(address _beneficiary)
    public
    whenNotPaused
    onlyAccessByGame
    returns (bool)
  {
    require(_beneficiary != address(0));
    return _create(_beneficiary, 0, 0);
  }

  function burn(uint256 _tokenId) external onlyOwnerOf(_tokenId) {
    super._burn(msg.sender, _tokenId);
  }

  function setPath(
    uint256 _ninjaid,
    uint256 _castleid,
    bytes _path,
    bytes _steps)
    public
    onlyAccessByGame
  {
    Ninja storage ninja = ninjas[_ninjaid];
    ninja.lastAttackedCastleid = _castleid;
    paths[_ninjaid] = _path;
    steps[_ninjaid] = _steps;
  }

  function win(uint256 _ninjaid)
    public
    onlyAccessByGame
    returns (bool)
  {
    Ninja storage ninja = ninjas[_ninjaid];
    ninja.winCount++;
    ninja.exp += expOnSuccess;
    ninja.levelPoint += expOnSuccess;
    _levelUp(ninja);

    _triggerCooldown(_ninjaid);

    return true;
  }

  function lost(uint256 _ninjaid)
    public
    onlyAccessByGame
    returns (bool)
  {
    Ninja storage ninja = ninjas[_ninjaid];
    ninja.lossCount++;
    ninja.exp += expOnFault;
    ninja.levelPoint += expOnFault;
    _levelUp(ninja);

    _triggerCooldown(_ninjaid);

    return true;
  }

  function setName(uint256 _ninjaid, bytes16 _newName)
    external
    onlyOwnerOf(_ninjaid)
  {
    ninjas[_ninjaid].name = _newName;
  }

  function setGoldContract(address _goldTokenAddress)
    public
    onlyOwner
  {
    require(_goldTokenAddress != address(0));

    goldToken = EverGold(_goldTokenAddress);
  }

  function setNinjaKindCount(uint8 _kindCount)
    public
    onlyOwner
  {
    kindCount = _kindCount;
  }

  function setPrice(uint16 _price)
    public
    onlyOwner
  {
    price = _price;
  }

  function setMaxCoordinate(uint16 _maxCoordinate)
    public
    onlyOwner
  {
    maxCoordinate = _maxCoordinate;
  }

  function setMaxCoordinate(uint256 _cooldownTime)
    public
    onlyOwner
  {
    cooldownTime = _cooldownTime;
  }

  function _create(address _beneficiary, uint8 _dna1, uint8 _dna2)
    private
    returns (bool)
  {
    bytes32 pattern = _generateInitialPattern();
    uint256 tokenid = ninjas.length;
    bytes16 name = StringLib.generateName("NINJA#", 6, tokenid);

    uint256 id = ninjas.push(Ninja({
      pattern: pattern, name: name, level: 1, exp: 0,
      dna1: _dna1, dna2: _dna2,
      readyTime: uint32(now + cooldownTime),
      winCount: 0, lossCount: 0,
      levelPoint:0, reward: 0,
      lastAttackedCastleid: 0})) - 1;
    super._mint(_beneficiary, id);

    emit NewNinja(id, name, pattern);

    return true;
  }

  function _triggerCooldown(uint256 _ninjaid)
    internal
    onlyAccessByGame
  {
    Ninja storage ninja = ninjas[_ninjaid];
    ninja.readyTime = uint32(now + cooldownTime);
  }

  function _levelUp(Ninja storage _ninja)
    internal
    onlyAccessByGame
  {
    if (_ninja.levelPoint >= leveupExp) {
      _ninja.levelPoint -= leveupExp;
      _ninja.level++;
      if (_ninja.level == 2) {
        _ninja.dna1 = uint8(_getRandom(6));
      } else if (_ninja.level == 5) {
        _ninja.dna2 = uint8(_getRandom(6));
      }
    }
  }

  function getByOwner(address _owner)
    external
    view
    returns(uint256[] result)
  {
    return ownedTokens[_owner];
  }

  function getInfo(uint256 _ninjaid)
    external
    view
    returns (bytes16, uint32, uint16, uint16, bytes32, uint8, uint8)
  {
    Ninja storage ninja = ninjas[_ninjaid];
    return (ninja.name, ninja.level, ninja.winCount, ninja.lossCount, ninja.pattern,
      ninja.dna1, ninja.dna2);
  }

  function getHp(uint256 _ninjaid)
    public
    view
    returns (uint32)
  {
    Ninja storage ninja = ninjas[_ninjaid];
    return uint32(100 + (ninja.level - 1) * 10);
  }

  function getDna1(uint256 _ninjaid)
    public
    view
    returns (uint8)
  {
    Ninja storage ninja = ninjas[_ninjaid];
    return ninja.dna1;
  }

  function getDna2(uint256 _ninjaid)
    public
    view
    returns (uint8)
  {
    Ninja storage ninja = ninjas[_ninjaid];
    return ninja.dna2;
  }

  function isReady(uint256 _ninjaid)
    public
    view
    returns (bool)
  {
    Ninja storage ninja = ninjas[_ninjaid];
    return (ninja.readyTime <= now);
  }

  function getReward(uint256 _ninjaid)
    public
    view
    onlyOwnerOf(_ninjaid)
    returns (uint16)
  {
    Ninja storage ninja = ninjas[_ninjaid];
    return ninja.reward;
  }

  function getPath(uint256 _ninjaid)
    public
    view
    onlyOwnerOf(_ninjaid)
    returns (bytes path)
  {
    return paths[_ninjaid];
  }

  function getLastAttack(uint256 _ninjaid)
    public
    view
    onlyOwnerOf(_ninjaid)
    returns (uint256 castleid, bytes path)
  {
    Ninja storage ninja = ninjas[_ninjaid];
    return (ninja.lastAttackedCastleid, paths[_ninjaid]);
  }

  function getAttr(bytes32 _pattern, uint256 _n)
    internal
    pure
    returns (bytes4)
  {
    require(_n < 8);
    uint32 mask = 0xffffffff;
    return bytes4(uint256(_pattern) / (2 ** ((7 - _n) * 8)) & mask);
  }

  function _getRandom(uint256 _modulus)
    internal
    onlyAccessByGame
    returns(uint32)
  {
    randNonce = randNonce.add(1);
    return uint32(uint256(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % _modulus);
 
  }

  function _generateInitialPattern()
    internal
    onlyAccessByGame
    returns (bytes32)
  {
    uint256 pattern = 0;

    uint32 color = COLORS[(_getRandom(COLORS.length))];
    for (uint256 i = 0; i < 8; i++) {
      uint32 temp = color;
      if (i == 1) {
        temp |= _getRandom(2);
      } else {
        temp |= _getRandom(maxCoordinate);
      }
      pattern = pattern | (temp * 2 ** (8 * 4 * (7 - i)));
    }
    return bytes32(pattern);
  }

  function getPrice()
    public
    view
    returns (uint256)
  {
    return price;
  }
}

contract UserToken is AccessByGame {
  struct User {
    string name;
    uint32 registeredDate;
  }

  string constant public DEFAULT_NAME = "NONAME";

  User[] private users;

  uint256 public userCount = 0;

  mapping (address => uint256) private ownerToUser;

  constructor()
    public
  {
    mint(msg.sender, "OWNER");
  }

  function mint(address _beneficiary, string _name)
    public
    onlyAccessByGame
    whenNotPaused()
    returns (bool)
  {
    require(_beneficiary != address(0));
    require(ownerToUser[_beneficiary] == 0);

    User memory user = User({
      name: _name,
      registeredDate: uint32(now)
    });

    uint256 id = users.push(user) - 1;

    ownerToUser[_beneficiary] = id;

    userCount++;

    return true;
  }

  function setName(string _name)
    public
    whenNotPaused()
    returns (bool)
  {
    require(bytes(_name).length > 1);
    require(ownerToUser[msg.sender] != 0);

    uint256 userid = ownerToUser[msg.sender];
    users[userid].name = _name;

    return true;
  }

  function getUserid(address _owner)
    external
    view
    onlyAccessByGame
    returns(uint256 result)
  {
    if (ownerToUser[_owner] == 0) {
      return 0;
    }
    return ownerToUser[_owner];
  }

  function getUserInfo()
    public
    view
    returns (uint256, string, uint32)
  {
    uint256 userid = ownerToUser[msg.sender];
    return getUserInfoById(userid);
  }

  function getUserInfoById(uint256 _userid)
    public
    view
    returns (uint256, string, uint32)
  {
    User storage user = users[_userid];
    return (_userid, user.name, user.registeredDate);
  }
}

 
contract TokenDestructible is Ownable {

  constructor() public payable { }

   
  function destroy(address[] tokens) onlyOwner public {

     
    for (uint256 i = 0; i < tokens.length; i++) {
      ERC20Basic token = ERC20Basic(tokens[i]);
      uint256 balance = token.balanceOf(this);
      token.transfer(owner, balance);
    }

     
    selfdestruct(owner);
  }
}

contract GameV001 is AccessByGame, TokenDestructible {
  using SafeMath for uint256;

  uint8 constant INIT_WIDTH = 5;
  uint8 constant INIT_DEPTH = 8;

  UserToken private userToken;
  EverGold private goldToken;
  CastleToken private castleToken;
  NinjaToken private ninjaToken;
  ItemToken private itemToken;

  struct AttackLog {
    uint256 castleid;
    uint16 reward;
    uint32 hp;
    uint8 path;
    uint32 trapDamage;
    bool dead;
  }

  mapping (uint256 => AttackLog[]) private attackLogs;
  mapping (uint256 => uint256) private numAttackLogs;

  event Attack(uint256 ninjaid, uint256 castleid, uint32 hp, uint8 path, uint32 trapDamage, uint32 damage);
  event AttackStart(uint256 ninjaid, uint256 castleid, uint32 hp);
  event AttackEnd(uint256 ninjaid, uint256 castleid, bool result);

  constructor(
    address _goldTokenAddress,
    address _castleTokenAddress,
    address _ninjaTokenAddress,
    address _userTokenAddress,
    address _itemTokenAddress)
    public
  {
    require(_goldTokenAddress != address(0));
    require(_castleTokenAddress != address(0));
    require(_ninjaTokenAddress != address(0));
    require(_userTokenAddress != address(0));
    require(_itemTokenAddress != address(0));

    goldToken = EverGold(_goldTokenAddress);
    castleToken = CastleToken(_castleTokenAddress);
    ninjaToken = NinjaToken(_ninjaTokenAddress);
    userToken = UserToken(_userTokenAddress);
    itemToken = ItemToken(_itemTokenAddress);
  }

  function  registerUser(string _name)
    public
    returns (bool)
  {
    require(msg.sender != address(0));
    require(userToken.mint(msg.sender, _name));

    return true;
  }

  function  buyNinja(address _beneficiary)
    public
    payable
    returns (bool)
  {
    require(msg.sender != address(0));
    uint256 price = ninjaToken.getPrice();
    require(msg.value == price);
    require(ninjaToken.mint(_beneficiary));

    return true;
  }

  function buyCastle(address _beneficiary)
    public
    payable
    returns (bool)
  {
    require(msg.sender != address(0));
    uint256 price = castleToken.getPrice();
    require(msg.value == price);
    require(castleToken.mint(_beneficiary));

    return true;
  }

  function buyItem(address _beneficiary, uint8 _itemid, uint256 _amount)
    public
    payable
    returns (bool)
  {
    require(msg.sender != address(0));
    uint16 price = itemToken.getPrice(_itemid);
    uint256 totalPrice = price * _amount;
    require(msg.value == totalPrice);
    require(itemToken.buy(_beneficiary, _itemid, _amount));

    return true;
  }

  function defence(
    address _beneficiary,
    uint256 _castleid,
    uint16 _reward,
    bytes _traps,
    uint256[] _useTraps)
    public
    payable
    whenNotPaused
    returns (bool)
  {
    require(msg.value == _reward);

    for (uint256 i = 1; i < _useTraps.length; i++) {
      if (_useTraps[i] > 0) {
        require(itemToken.useItem(_beneficiary, i, _useTraps[i]));
      }
    }
    require(castleToken.setTraps(_castleid, _reward, _traps));

    return true;
  }

  function addTraps(
    uint256 _castleid,
    bytes _traps,
    uint256[] _useTraps)
    public
    whenNotPaused
    returns (bool)
  {
    require(castleToken.getReward(_castleid) > 0);
    bytes memory traps = castleToken.getTrapInfo(_castleid);
    for (uint256 i = 1; i < _useTraps.length; i++) {
      if ((traps[i]) == 0 &&
        (_useTraps[i] > 0)) {
        require(itemToken.useItem(msg.sender, i, _useTraps[i]));
      }
    }
    require(castleToken.setTraps(_castleid, castleToken.getReward(_castleid), _traps));
    return true;
  }

  function attack(
    uint256 _ninjaid,
    uint256 _castleid,
    bytes _path)
    public
    payable
    whenNotPaused
    returns (bool)
  {
    uint16 reward = castleToken.getReward(_castleid);
    require(msg.value == reward / 2);

    uint32 hp = ninjaToken.getHp(_ninjaid);

    _clearAttackLog(_ninjaid);

    bytes memory steps = new bytes(_path.length);
    uint256 count = 0;
    uint32 damage = 0;
    for (uint256 i = 0; i < _path.length; i++) {
      uint32 trapDamage = _computeDamage(_castleid, _ninjaid, uint8(_path[i]));
      if (trapDamage > 0) {
        steps[count++] = _path[i];
        damage = damage + trapDamage;
        if (hp <= damage) {
          _insertAttackLog(_ninjaid, _castleid, reward, hp, uint8(_path[i]), trapDamage, true);
          address castleOwner = castleToken.ownerOf(_castleid);
          goldToken.transfer(castleOwner, reward / 2);
          castleToken.win(_castleid, _ninjaid, uint256(_path[i]), steps, count);
          ninjaToken.lost(_ninjaid);
          ninjaToken.setPath(_ninjaid, _castleid, _path, steps);
          emit AttackEnd(_ninjaid, _castleid, false);

          return true;
        }
      }
      _insertAttackLog(_ninjaid, _castleid, reward, hp, uint8(_path[i]), trapDamage, false);
    }
    require(goldToken.transfer(ninjaToken.ownerOf(_ninjaid), reward + reward / 2));
    require(castleToken.lost(_castleid, _ninjaid));
    require(ninjaToken.win(_ninjaid));
    ninjaToken.setPath(_ninjaid, _castleid, _path, steps);
    emit AttackEnd(_ninjaid, _castleid, true);
    return true;
  }

  function _computeDamage(uint256 _castleid, uint256 _ninjaid, uint8 _itemid)
    internal
    view
    returns (uint32)
  {
    uint32 trapPower = itemToken.getPower(castleToken.getTrapid(_castleid, uint8(_itemid)));
    if (trapPower <= 0) {
      return 0;
    }
    uint32 trapDamage = trapPower + castleToken.getLevel(_castleid) - 1;
    uint8 dna1 = ninjaToken.getDna1(_ninjaid);
    uint8 dna2 = ninjaToken.getDna2(_ninjaid);
    if (_itemid == 1) {
      if (dna1 == 4) {
        trapDamage *= 2;
      }
      if (dna2 == 4) {
        trapDamage *= 2;
      }
      if (dna1 == 3) {
        trapDamage /= 2;
      }
      if (dna2 == 3) {
        trapDamage /= 2;
      }
    } else if (_itemid == 2) {
      if (dna1 == 5) {
        trapDamage *= 2;
      }
      if (dna2 == 5) {
        trapDamage *= 2;
      }
      if (dna1 == 4) {
        trapDamage /= 2;
      }
      if (dna2 == 4) {
        trapDamage /= 2;
      }
    } else if (_itemid == 3) {
      if (dna1 == 1) {
        trapDamage *= 2;
      }
      if (dna2 == 1) {
        trapDamage *= 2;
      }
      if (dna1 == 5) {
        trapDamage /= 2;
      }
      if (dna2 == 5) {
        trapDamage /= 2;
      }
    } else if (_itemid == 4) {
      if (dna1 == 2) {
        trapDamage *= 2;
      }
      if (dna2 == 2) {
        trapDamage *= 2;
      }
      if (dna1 == 1) {
        trapDamage /= 2;
      }
      if (dna2 == 1) {
        trapDamage /= 2;
      }
    } else if (_itemid == 5) {
      if (dna1 == 3) {
        trapDamage *= 2;
      }
      if (dna2 == 3) {
        trapDamage *= 2;
      }
      if (dna1 == 2) {
        trapDamage /= 2;
      }
      if (dna2 == 2) {
        trapDamage /= 2;
      }
    }
    return trapDamage;
  }

  function _insertAttackLog(
    uint256 _ninjaid,
    uint256 _castleid,
    uint16 _reward,
    uint32 _hp,
    uint8 _path,
    uint32 _trapDamage,
    bool _dead)
    private
  {
    if(numAttackLogs[_ninjaid] == attackLogs[_ninjaid].length) {
      attackLogs[_ninjaid].length += 1;
    }
    AttackLog memory log = AttackLog(_castleid, _reward, _hp, _path, _trapDamage, _dead);
    attackLogs[_ninjaid][numAttackLogs[_ninjaid]++] = log;
  }

  function _clearAttackLog(uint256 _ninjaid)
    private
  {
    numAttackLogs[_ninjaid] = 0;
  }

  function setGoldContract(address _goldTokenAddress)
    public
    onlyOwner
  {
    require(_goldTokenAddress != address(0));

    goldToken = EverGold(_goldTokenAddress);
  }

  function setCastleContract(address _castleTokenAddress)
    public
    onlyOwner
  {
    require(_castleTokenAddress != address(0));

    castleToken = CastleToken(_castleTokenAddress);
  }

  function setNinjaContract(address _ninjaTokenAddress)
    public
    onlyOwner
  {
    require(_ninjaTokenAddress != address(0));

    ninjaToken = NinjaToken(_ninjaTokenAddress);
  }

  function setItemContract(address _itemTokenAddress)
    public
    onlyOwner
  {
    require(_itemTokenAddress != address(0));

    itemToken = ItemToken(_itemTokenAddress);
  }

  function setUserContract(address _userTokenAddress)
    public
    onlyOwner
  {
    require(_userTokenAddress != address(0));

    userToken = UserToken(_userTokenAddress);
  }

  function getLastAttack(uint256 _ninjaid, uint256 _index)
    public
    view
    returns (uint256 castleid, uint16 reward, uint32 hp, uint8 path, uint32 trapDamage, bool dead)
  {
    require(ninjaToken.ownerOf(_ninjaid) == msg.sender);
    AttackLog memory log = attackLogs[_ninjaid][_index];
    return (log.castleid, log.reward, log.hp, log.path, log.trapDamage, log.dead);
  }

  function getLastAttackCount(uint256 _ninjaid)
    public
    view
    returns (uint256)
  {
    require(ninjaToken.ownerOf(_ninjaid) == msg.sender);
    return numAttackLogs[_ninjaid];
  }
}