 

pragma solidity ^0.4.23;

 

 
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

 

 
contract Adminable is Ownable {
    address public admin;

    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

     
    constructor() public {
        admin = msg.sender;
    }

     
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin is allowed to execute this method.");
        _;
    }

     
    function transferAdmin(address newAdmin) public onlyOwner {
        require(newAdmin != address(0));
        emit AdminTransferred(admin, newAdmin);
        admin = newAdmin;
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

 

contract EpicsToken is ERC721Token("Epics.gg Token", "EPICS TOKEN"), Ownable, Adminable {
    event TokenLock(string uuid);     
    event TokenUnlock(string uuid);   
    event UserVerified(string userToken, address userAddress);   
    event TokenCreated(string uuid, address to);
    event TokenDestroyed(string uuid);
    event TokenOwnerSet(address from, address to, string uuid);

    event TradingLock();           
    event TradingUnlock();         

    struct Token {
        string uuid;
        string properties;
    }

    mapping (string => uint256) private uuidToTokenId;   
    mapping (string => bool) private uuidExists;         
    mapping (uint256 => bool) private lockedTokens;      
    bool public tradingLocked;                           
    Token[] tokens;                                      

     
    function ownerOfUUID(string _uuid) public view returns (address) {
        require(uuidExists[_uuid] == true, "UUID does not exist.");  
        uint256 _tokenId = uuidToTokenId[_uuid];
        return ownerOf(_tokenId);
    }

     
    function tokenIdOfUUID(string _uuid) public view returns (uint256) {
        require(uuidExists[_uuid] == true, "UUID does not exist.");
        return uuidToTokenId[_uuid];
    }

     
    function getToken(uint256 _tokenId) public view returns (string uuid, string properties) {
        require(exists(_tokenId), "Token does not exist.");
        Token memory token = tokens[_tokenId];
        uuid = token.uuid;
        properties = token.properties;
    }

    function isTokenLocked(uint256 _tokenId) public view returns (bool) {
        require(exists(_tokenId), "Token does not exist.");
        return lockedTokens[_tokenId];
    }

    function verifyUser(string userToken) public returns (bool) {
        emit UserVerified(userToken, msg.sender);
        return true;
    }

    function tokensByOwner(address _owner) public view returns (uint256[]) {
        return ownedTokens[_owner];
    }

     
     

     
    function lockTrading() public onlyAdmin {
        require(tradingLocked == false, "Trading already locked.");
        tradingLocked = true;
        emit TradingLock();
    }

     
    function unlockTrading() public onlyAdmin {
        require(tradingLocked == true, "Trading already unlocked.");
        tradingLocked = false;
        emit TradingUnlock();
    }

     
     

     
    function createToken(string _uuid, string _properties, address _to) public onlyAdmin {
        require(uuidExists[_uuid] == false, "UUID already exists.");
        Token memory _token = Token({uuid: _uuid, properties: _properties});
        uint256 _tokenId = tokens.push(_token) - 1;
        uuidToTokenId[_uuid] = _tokenId;
        uuidExists[_uuid] = true;
        lockedTokens[_tokenId] = true;
        _mint(_to, _tokenId);
        emit TokenCreated(_uuid, _to);
    }

     
    function updateToken(string _uuid, string _properties) public onlyAdmin {
        require(uuidExists[_uuid] == true, "UUID does not exist.");
        uint256 _tokenId = uuidToTokenId[_uuid];
        Token memory _token = Token({uuid: _uuid, properties: _properties});
        tokens[_tokenId] = _token;
    }

    function destroyToken(uint256 _tokenId) public onlyAdmin {
        require(exists(_tokenId), "Token does not exist.");
        require(lockedTokens[_tokenId] == true, "Token must be locked before being destroyed.");
        Token memory _token = tokens[_tokenId];
        delete uuidExists[_token.uuid];
        delete uuidToTokenId[_token.uuid];
        delete lockedTokens[_tokenId];
        _burn(ownerOf(_tokenId), _tokenId);
        emit TokenDestroyed(_token.uuid);
    }

     
    function lockToken(address _owner, uint256 _tokenId) public onlyAdmin {
        require(exists(_tokenId), "Token does not exist.");
        require(lockedTokens[_tokenId] == false, "Token is already locked.");
        require(ownerOf(_tokenId) == _owner, "The owner has changed since it was suppose to be locked.");
        lockedTokens[_tokenId] = true;
        Token memory _token = tokens[_tokenId];
        emit TokenLock(_token.uuid);
    }

     
    function unlockToken(address _owner, uint256 _tokenId) public onlyAdmin {
        require(exists(_tokenId), "Token does not exist.");
        require(lockedTokens[_tokenId] == true, "Token is already unlocked.");
        require(ownerOf(_tokenId) == _owner, "The owner has changed since it was suppose to be locked.");
        lockedTokens[_tokenId] = false;
        Token memory _token = tokens[_tokenId];
        emit TokenUnlock(_token.uuid);
    }

     
    function setOwner(address _to, uint256 _tokenId) public onlyAdmin {
        require(exists(_tokenId), "Token does not exist.");
        require(lockedTokens[_tokenId] == true || tradingLocked == true, "Token must be locked before owner is changed.");
        address _owner = ownerOf(_tokenId);
        clearApproval(_owner, _tokenId);
        removeTokenFrom(_owner, _tokenId);
        addTokenTo(_to, _tokenId);
        Token memory _token = tokens[_tokenId];
        emit TokenOwnerSet(_owner, _to, _token.uuid);
        emit Transfer(_owner, _to, _tokenId);
    }

     
     

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(tradingLocked == false && lockedTokens[_tokenId] == false, "Token must be unlocked to be transferred.");
        super.transferFrom(_from, _to, _tokenId);
    }

    function approve(address _to, uint256 _tokenId) public {
        require(tradingLocked == false && lockedTokens[_tokenId] == false, "Token must be unlocked to be approved.");
        super.approve(_to, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        require(tradingLocked == false, "Token must be unlocked to be approved for all.");
        super.setApprovalForAll(_operator, _approved);
    }
}