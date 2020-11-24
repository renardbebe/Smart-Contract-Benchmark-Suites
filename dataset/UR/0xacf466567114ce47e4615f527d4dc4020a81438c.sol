 

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