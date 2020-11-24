 

 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

pragma solidity ^0.4.24;


 
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

 

pragma solidity ^0.4.24;




 
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

 

pragma solidity ^0.4.24;



 
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

 

pragma solidity ^0.4.24;




 
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
    uint256 _addedValue
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
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

pragma solidity ^0.4.24;



 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

 

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


 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

 

pragma solidity ^0.4.24;



 
contract ERC721Basic is ERC165 {
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
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

 

pragma solidity ^0.4.24;



 
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
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

 

pragma solidity ^0.4.24;


 
contract ERC721Receiver {
   
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

   
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

 

pragma solidity ^0.4.24;


 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

 

pragma solidity ^0.4.24;



 
contract SupportsInterfaceWithLookup is ERC165 {
  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) internal supportedInterfaces;

   
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

   
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}

 

pragma solidity ^0.4.24;







 
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
   

  bytes4 private constant InterfaceId_ERC721Exists = 0x4f558e79;
   

  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

   
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

  constructor()
    public
  {
     
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
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

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
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
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

 

pragma solidity ^0.4.24;





 
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

  bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

   
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

     
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
  function name() external view returns (string) {
    return name_;
  }

   
  function symbol() external view returns (string) {
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

 

pragma solidity ^0.4.24;



contract LeasedEmblem is  ERC721Token, Ownable {


  address internal leaseExchange;


  struct Metadata {
    uint256 amount;
    address leasor;
    uint256 duration;
    uint256 tradeExpiry;
    uint256 leaseExpiry;
    bool isMining;
  }


  mapping(uint256 => Metadata) public metadata;


  mapping(address => uint256[]) internal leasedTokens;


  mapping(uint256 => uint256) internal leasedTokensIndex;


  mapping (uint256 => address) internal tokenLeasor;


  mapping (address => uint256) internal leasedTokensCount;

  uint256 highestId = 1;

  uint256 sixMonths       = 15768000;

  constructor (string _name, string _symbol) public ERC721Token(_name, _symbol) {
  }



  function getNewId() public view returns(uint256) {
    return highestId;
  }

  function leasorOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenLeasor[_tokenId];
    require(owner != address(0));
    return owner;
  }

  function balanceOfLeasor(address _leasor) public view returns (uint256) {
    require(_leasor != address(0));
    return leasedTokensCount[_leasor];
  }

  function tokenOfLeasorByIndex(address _leasor,uint256 _index) public view returns (uint256){
    require(_index < balanceOfLeasor(_leasor));
    return leasedTokens[_leasor][_index];
  }

  function addTokenToLeasor(address _to, uint256 _tokenId) internal {
    require(tokenLeasor[_tokenId] == address(0));
    tokenLeasor[_tokenId] = _to;
    leasedTokensCount[_to] = leasedTokensCount[_to].add(1);
    uint256 length = leasedTokens[_to].length;
    leasedTokens[_to].push(_tokenId);
    leasedTokensIndex[_tokenId] = length;
  }

  function removeTokenFromLeasor(address _from, uint256 _tokenId) internal {
    require(leasorOf(_tokenId) == _from);
    leasedTokensCount[_from] = leasedTokensCount[_from].sub(1);
    tokenLeasor[_tokenId] = address(0);

    uint256 tokenIndex = leasedTokensIndex[_tokenId];
    uint256 lastTokenIndex = leasedTokens[_from].length.sub(1);
    uint256 lastToken = leasedTokens[_from][lastTokenIndex];

    leasedTokens[_from][tokenIndex] = lastToken;
    leasedTokens[_from][lastTokenIndex] = 0;
    leasedTokens[_from].length--;
    leasedTokensIndex[_tokenId] = 0;
    leasedTokensIndex[lastToken] = tokenIndex;
  }

  function setLeaseExchange(address _leaseExchange) public onlyOwner {
    leaseExchange = _leaseExchange;
  }

  function totalAmount() external view returns (uint256) {
    uint256 amount = 0;
    for(uint256 i = 0; i < allTokens.length; i++){
      amount += metadata[allTokens[i]].amount;
    }
    return amount;
  }

  function setMetadata(uint256 _tokenId, uint256 amount, address leasor, uint256 duration,uint256 tradeExpiry, uint256 leaseExpiry) internal {
    require(exists(_tokenId));
    metadata[_tokenId]= Metadata(amount,leasor,duration,tradeExpiry,leaseExpiry,false);
  }

  function getMetadata(uint256 _tokenId) public view returns (uint256, address, uint256, uint256,uint256, bool) {
    require(exists(_tokenId));
    return (
      metadata[_tokenId].amount,
      metadata[_tokenId].leasor,
      metadata[_tokenId].duration,
      metadata[_tokenId].tradeExpiry,
      metadata[_tokenId].leaseExpiry,
      metadata[_tokenId].isMining
    );
  }

  function getAmountForUser(address owner) external view returns (uint256) {
    uint256 amount = 0;
    uint256 numTokens = balanceOf(owner);

    for(uint256 i = 0; i < numTokens; i++){
      amount += metadata[tokenOfOwnerByIndex(owner,i)].amount;
    }
    return amount;
  }

  function getAmountForUserMining(address owner) external view returns (uint256) {
    uint256 amount = 0;
    uint256 numTokens = balanceOf(owner);

    for(uint256 i = 0; i < numTokens; i++){
      if(metadata[tokenOfOwnerByIndex(owner,i)].isMining) {
        amount += metadata[tokenOfOwnerByIndex(owner,i)].amount;
      }
    }
    return amount;
  }

  function getAmount(uint256 _tokenId) public view returns (uint256) {
    require(exists(_tokenId));
    return metadata[_tokenId].amount;
  }

  function getTradeExpiry(uint256 _tokenId) public view returns (uint256) {
    require(exists(_tokenId));
    return metadata[_tokenId].tradeExpiry;
  }

  function getDuration(uint256 _tokenId) public view returns (uint256) {
    require(exists(_tokenId));
    return metadata[_tokenId].duration;
  }

  function getIsMining(uint256 _tokenId) public view returns (bool) {
    require(exists(_tokenId));
    return metadata[_tokenId].isMining;
  }

  function startMining(address _owner, uint256 _tokenId) public returns (bool) {
    require(msg.sender == leaseExchange);
    require(exists(_tokenId));
    require(ownerOf(_tokenId) == _owner);
    require(now < metadata[_tokenId].tradeExpiry);
    require(metadata[_tokenId].isMining == false);
    Metadata storage m = metadata[_tokenId];
    m.isMining = true;
    m.leaseExpiry = now + m.duration;
    return true;
  }

  function canRetrieveEMB(address _leasor, uint256 _tokenId) public view returns (bool) {
    require(exists(_tokenId));
    require(metadata[_tokenId].leasor == _leasor);
    if(metadata[_tokenId].isMining == false) {
      return(now > metadata[_tokenId].leaseExpiry);
    }
    else {
      return(now > metadata[_tokenId].tradeExpiry);
    }
  }

  function endLease(address _leasee, uint256 _tokenId) public {
    require(msg.sender == leaseExchange);
    require(exists(_tokenId));
    require(ownerOf(_tokenId) == _leasee);
    require(now > metadata[_tokenId].leaseExpiry);
    removeTokenFromLeasor(metadata[_tokenId].leasor, _tokenId);
    _burn(_leasee, _tokenId);
  }

  function splitLEMB(uint256 _tokenId, uint256 amount) public {
    require(exists(_tokenId));
    require(ownerOf(_tokenId) == msg.sender);
    require(metadata[_tokenId].isMining == false);
    require(now < metadata[_tokenId].tradeExpiry);
    require(amount < getAmount(_tokenId));

    uint256 _newTokenId = getNewId();

    Metadata storage m = metadata[_tokenId];
    m.amount = m.amount - amount;

    _mint(msg.sender, _newTokenId);
    addTokenToLeasor(m.leasor, _newTokenId);
    setMetadata(_newTokenId, amount, m.leasor, m.duration,m.tradeExpiry, 0);
    highestId = highestId + 1;
  }

  function mintUniqueTokenTo(address _to, uint256 amount, address leasor, uint256 duration) public {
    require(msg.sender == leaseExchange);
    uint256 _tokenId = getNewId();
    _mint(_to, _tokenId);
    addTokenToLeasor(leasor, _tokenId);
    uint256 tradeExpiry = now + sixMonths;
    setMetadata(_tokenId, amount, leasor, duration,tradeExpiry, 0);
    highestId = highestId + 1;
  }

  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);
    delete metadata[_tokenId];
  }

  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    require(metadata[_tokenId].isMining == false);
    _;
  }

}

 

pragma solidity ^0.4.24;






contract Emblem is DetailedERC20, StandardToken, Ownable {
  using SafeMath for uint256;

   mapping (bytes12 => address) public vanityAddresses;
   mapping (address => bytes12[]) public ownedVanities;
   mapping (address => mapping(bytes12 => uint256)) public ownedVanitiesIndex;
   mapping (bytes12 => uint256) allVanitiesIndex;
   bytes12[] public allVanities;
   mapping (address => mapping (bytes12 => address)) internal allowedVanities;

   mapping (bytes12 => uint256) vanityFees;
   mapping (bytes12 => bool) vanityFeeEnabled;

   bool internal useVanityFees = true;
   uint256 internal vanityPurchaseCost = 100 * (10 ** 8);

   mapping (address => bool) public frozenAccounts;
   bool public completeFreeze = false;

   mapping (address => bool) internal freezable;
   mapping (address => bool) internal externalFreezers;

   address leaseExchange;
   LeasedEmblem LEMB;

   event TransferVanity(address from, address to, bytes12 vanity);
   event ApprovedVanity(address from, address to, bytes12 vanity);
   event VanityPurchased(address from, bytes12 vanity);

   constructor(string _name, string _ticker, uint8 _decimal, uint256 _supply, address _wallet, address _lemb) DetailedERC20(_name, _ticker, _decimal) public {
     totalSupply_ = _supply;
     balances[_wallet] = _supply;
     LEMB = LeasedEmblem(_lemb);
   }

   function setLeaseExchange(address _leaseExchange) public onlyOwner {
     leaseExchange = _leaseExchange;
   }

   function setVanityPurchaseCost(uint256 cost) public onlyOwner {
     vanityPurchaseCost = cost;
   }

   function enableFees(bool enabled) public onlyOwner {
     useVanityFees = enabled;
   }

   function setLEMB(address _lemb) public onlyOwner {
     LEMB = LeasedEmblem(_lemb);
   }

   function setVanityFee(bytes12 vanity, uint256 fee) public onlyOwner {
     require(fee >= 0);
     vanityFees[vanity] = fee;
   }

   function getFee(bytes12 vanity) public view returns(uint256) {
     return vanityFees[vanity];
   }

   function enabledVanityFee(bytes12 vanity) public view returns(bool) {
     return vanityFeeEnabled[vanity] && useVanityFees;
   }

   function setTicker(string _ticker) public onlyOwner {
     symbol = _ticker;
   }

   function approveOwner(uint256 _value) public onlyOwner returns (bool) {
     allowed[msg.sender][address(this)] = _value;
     return true;
   }

   function vanityAllowance(address _owner, bytes12 _vanity, address _spender) public view returns (bool) {
     return allowedVanities[_owner][_vanity] == _spender;
   }

   function getVanityOwner(bytes12 _vanity) public view returns (address) {
     return vanityAddresses[_vanity];
   }

   function getAllVanities() public view returns (bytes12[]){
     return allVanities;
   }

   function getMyVanities() public view returns (bytes12[]){
     return ownedVanities[msg.sender];
   }

   function approveVanity(address _spender, bytes12 _vanity) public returns (bool) {
     require(vanityAddresses[_vanity] == msg.sender);
     allowedVanities[msg.sender][_vanity] = _spender;

     emit ApprovedVanity(msg.sender, _spender, _vanity);
     return true;
   }

   function clearVanityApproval(bytes12 _vanity) public returns (bool){
     require(vanityAddresses[_vanity] == msg.sender);
     delete allowedVanities[msg.sender][_vanity];
     return true;
   }

   function transferVanity(bytes12 van, address newOwner) public returns (bool) {
     require(newOwner != 0x0);
     require(vanityAddresses[van] == msg.sender);

     vanityAddresses[van] = newOwner;
     ownedVanities[newOwner].push(van);
     ownedVanitiesIndex[newOwner][van] = ownedVanities[newOwner].length.sub(1);

     uint256 vanityIndex = ownedVanitiesIndex[msg.sender][van];
     uint256 lastVanityIndex = ownedVanities[msg.sender].length.sub(1);
     bytes12 lastVanity = ownedVanities[msg.sender][lastVanityIndex];

     ownedVanities[msg.sender][vanityIndex] = lastVanity;
     ownedVanities[msg.sender][lastVanityIndex] = "";
     ownedVanities[msg.sender].length--;

     ownedVanitiesIndex[msg.sender][van] = 0;
     ownedVanitiesIndex[msg.sender][lastVanity] = vanityIndex;

     emit TransferVanity(msg.sender, newOwner,van);

     return true;
   }

   function transferVanityFrom(
     address _from,
     address _to,
     bytes12 _vanity
   )
     public
     returns (bool)
   {
     require(_to != address(0));
     require(_from == vanityAddresses[_vanity]);
     require(msg.sender == allowedVanities[_from][_vanity]);

     vanityAddresses[_vanity] = _to;
     ownedVanities[_to].push(_vanity);
     ownedVanitiesIndex[_to][_vanity] = ownedVanities[_to].length.sub(1);

     uint256 vanityIndex = ownedVanitiesIndex[_from][_vanity];
     uint256 lastVanityIndex = ownedVanities[_from].length.sub(1);
     bytes12 lastVanity = ownedVanities[_from][lastVanityIndex];

     ownedVanities[_from][vanityIndex] = lastVanity;
     ownedVanities[_from][lastVanityIndex] = "";
     ownedVanities[_from].length--;

     ownedVanitiesIndex[_from][_vanity] = 0;
     ownedVanitiesIndex[_from][lastVanity] = vanityIndex;

     emit TransferVanity(msg.sender, _to,_vanity);

     return true;
   }

   function purchaseVanity(bytes12 van) public returns (bool) {
     require(vanityAddresses[van] == address(0));

     for(uint8 i = 0; i < 12; i++){
       require((van[i] >= 48 && van[i] <= 57) || (van[i] >= 65 && van[i] <= 90));
     }

     require(canTransfer(msg.sender,vanityPurchaseCost));

     balances[msg.sender] = balances[msg.sender].sub(vanityPurchaseCost);
     balances[address(this)] = balances[address(this)].add(vanityPurchaseCost);
     emit Transfer(msg.sender, address(this), vanityPurchaseCost);

     vanityAddresses[van] = msg.sender;
     ownedVanities[msg.sender].push(van);
     ownedVanitiesIndex[msg.sender][van] = ownedVanities[msg.sender].length.sub(1);
     allVanities.push(van);
     allVanitiesIndex[van] = allVanities.length.sub(1);

     emit VanityPurchased(msg.sender, van);
   }

   function freezeTransfers(bool _freeze) public onlyOwner {
     completeFreeze = _freeze;
   }

   function freezeAccount(address _target, bool _freeze) public onlyOwner {
     frozenAccounts[_target] = _freeze;
   }

   function canTransfer(address _account,uint256 _value) internal view returns (bool) {
      return (!frozenAccounts[_account] && !completeFreeze && (_value + LEMB.getAmountForUserMining(_account) <= balances[_account]));
   }

   function transfer(address _to, uint256 _value) public returns (bool){
      require(canTransfer(msg.sender,_value));
      super.transfer(_to,_value);
   }


   function multiTransfer(bytes32[] _addressesAndAmounts) public {
      for (uint i = 0; i < _addressesAndAmounts.length; i++) {
          address to = address(_addressesAndAmounts[i] >> 96);
          uint amount = uint(uint56(_addressesAndAmounts[i]));
          transfer(to, amount);
      }
   }

   function freezeMe(bool freeze) public {
     require(!frozenAccounts[msg.sender]);
     freezable[msg.sender] = freeze;
   }

   function canFreeze(address _target) public view returns(bool){
     return freezable[_target];
   }

   function isFrozen(address _target) public view returns(bool) {
     return completeFreeze || frozenAccounts[_target];
   }

   function externalFreezeAccount(address _target, bool _freeze) public {
     require(freezable[_target]);
     require(externalFreezers[msg.sender]);
     frozenAccounts[_target] = _freeze;
   }

   function setExternalFreezer(address _target, bool _canFreeze) public onlyOwner {
     externalFreezers[_target] = _canFreeze;
   }


   function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
      require(!completeFreeze);
      if(msg.sender != leaseExchange) require(canTransfer(_from,_value));
      super.transferFrom(_from,_to,_value);
   }

   function decreaseApproval(address _spender,uint256 _subtractedValue) public returns (bool) {


     if(_spender == leaseExchange) {
       require(allowed[msg.sender][_spender].sub(_subtractedValue) >= LEMB.getAmountForUserMining(msg.sender));
     }
     super.decreaseApproval(_spender,_subtractedValue);
   }

   function approve(address _spender, uint256 _value) public returns (bool) {


     if(_spender == leaseExchange){
       require(_value >= LEMB.getAmountForUserMining(msg.sender));
     }

     allowed[msg.sender][_spender] = _value;
     emit Approval(msg.sender, _spender, _value);
     return true;
   }

}