 

pragma solidity 0.4.24;

 
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

 
contract Destructible is Ownable {

  constructor() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
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

contract Operatable is Ownable {

    address public operator;

    event LogOperatorChanged(address indexed from, address indexed to);

    modifier isValidOperator(address _operator) {
        require(_operator != address(0));
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator);
        _;
    }

    constructor(address _owner, address _operator) public isValidOperator(_operator) {
        require(_owner != address(0));
        
        owner = _owner;
        operator = _operator;
    }

    function setOperator(address _operator) public onlyOwner isValidOperator(_operator) {
        emit LogOperatorChanged(operator, _operator);
        operator = _operator;
    }
}

 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

 
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

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

 
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

contract CryptoTakeoversNFT is ERC721Token("CryptoTakeoversNFT",""), Operatable {
    
    event LogGameOperatorChanged(address indexed from, address indexed to);

    address public gameOperator;

    modifier onlyGameOperator() {
        assert(gameOperator != address(0));
        require(msg.sender == gameOperator);
        _;
    }

    constructor (address _owner, address _operator) Operatable(_owner, _operator) public {
    }

    function mint(uint256 _tokenId, string _tokenURI) public onlyGameOperator {
        super._mint(operator, _tokenId);
        super._setTokenURI(_tokenId, _tokenURI);
    }

    function hostileTakeover(address _to, uint256 _tokenId) public onlyGameOperator {
        address tokenOwner = super.ownerOf(_tokenId);
        operatorApprovals[tokenOwner][gameOperator] = true;
        super.safeTransferFrom(tokenOwner, _to, _tokenId);
    }

    function setGameOperator(address _gameOperator) public onlyOperator {
        emit LogGameOperatorChanged(gameOperator, _gameOperator);
        gameOperator = _gameOperator;
    }

    function burn(uint256 _tokenId) public onlyGameOperator {
        super._burn(operator, _tokenId);
    }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 
 
 
contract CryptoTakeoversToken is MintableToken, Operatable {

     

    event LogGameOperatorChanged(address indexed from, address indexed to);
    event LogShouldBlockPublicTradeSet(bool value, address indexed owner);

     

    bool public shouldBlockPublicTrade;
    address public gameOperator;

     

    modifier hasMintPermission() {
        require(msg.sender == operator || (gameOperator != address(0) && msg.sender == gameOperator));
        _;
    }

    modifier hasTradePermission(address _from) {
        require(_from == operator || !shouldBlockPublicTrade);
        _;
    }

     

     
     
     
    constructor (address _owner, address _operator) Operatable(_owner, _operator) public {
        shouldBlockPublicTrade = true;
    }

     

     
     
     
     
    function transfer(address _to, uint256 _value) public hasTradePermission(msg.sender) returns (bool) {
        return super.transfer(_to, _value);
    }

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public hasTradePermission(_from) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
     
    function setGameOperator(address _gameOperator) public onlyOperator {
        require(_gameOperator != address(0));

        emit LogGameOperatorChanged(gameOperator, _gameOperator);

        gameOperator = _gameOperator;
    }

     

     
     
    function setShouldBlockPublicTrade(bool _shouldBlockPublicTrade) public onlyOwner {
        shouldBlockPublicTrade = _shouldBlockPublicTrade;

        emit LogShouldBlockPublicTradeSet(_shouldBlockPublicTrade, owner);
    }
}

 
 
 
contract CryptoTakeoversPresale is Destructible, Pausable, Operatable {

     

    event LogNFTBought(uint256 indexed tokenId, address indexed buyer, uint256 value);
    event LogTokensBought(address indexed buyer, uint256 amount, uint256 value);
    event LogNFTGifted(address indexed to, uint256 indexed tokenId, uint256 price, address indexed operator);
    event LogTokensGifted(address indexed to, uint256 amount, address indexed operator);
    event LogNFTBurned(uint256 indexed tokenId, address indexed operator);
    event LogTokenPricesSet(
        uint256[] previousThresholds, 
        uint256[] previousPrices, 
        uint256[] newThresholds, 
        uint256[] newPrices, 
        address indexed operator);
    event LogNFTMintedNotForSale(uint256 indexed tokenId, address indexed operator);
    event LogNFTMintedForSale(uint256 indexed tokenId, uint256 tokenPrice, address indexed operator);
    event LogNFTSetNotForSale(uint256 indexed tokenId, address indexed operator);
    event LogNFTSetForSale(uint256 indexed tokenId, uint256 tokenPrice, address indexed operator);
    event LogDiscountSet(uint256 indexed tokenId, uint256 discountPrice, address indexed operator);
    event LogDiscountUpdated(uint256 indexed tokenId, uint256 discountPrice, address indexed operator);
    event LogDiscountRemoved(uint256 indexed tokenId, address indexed operator);
    event LogDiscountsReset(uint256 count, address indexed operator);
    event LogStartAndEndTimeSet(uint256 startTime, uint256 endTime, address indexed operator);
    event LogStartTimeSet(uint256 startTime, address indexed operator);
    event LogEndTimeSet(uint256 endTime, address indexed operator);
    event LogTokensContractSet(address indexed previousAddress, address indexed newAddress, address indexed owner);
    event LogItemsContractSet(address indexed previousAddress, address indexed newAddress, address indexed owner);
    event LogWithdrawToChanged(address indexed previousAddress, address indexed newAddress, address indexed owner);
    event LogWithdraw(address indexed withdrawTo, uint256 value, address indexed owner);

     

    using SafeMath for uint256;

    CryptoTakeoversNFT public items;
    CryptoTakeoversToken public tokens;

    uint256 public startTime;
    uint256 public endTime;
    address public withdrawTo;
    
    mapping (uint256 => uint256) tokenPrices;
    uint256[] public itemsForSale;
    mapping (uint256 => uint256) itemsForSaleIndex;
    mapping (uint256 => uint256) discountedItemPrices;
    uint256[] public discountedItems;
    mapping (uint256 => uint256) discountedItemsIndex;

    uint256[] public tokenDiscountThresholds;
    uint256[] public tokenDiscountedPrices;

     

    modifier onlyDuringPresale() {
        require(startTime != 0 && endTime != 0);
        require(now >= startTime);
        require(now <= endTime);
        _;
    }

     

     
     
     
     
     
     
    constructor (
        address _owner,
        address _operator, 
        address _cryptoTakeoversNFTAddress, 
        address _cryptoTakeoversTokenAddress
    ) 
        Operatable(_owner, _operator) 
        public 
    {
        items = CryptoTakeoversNFT(_cryptoTakeoversNFTAddress);
        tokens = CryptoTakeoversToken(_cryptoTakeoversTokenAddress);
        withdrawTo = owner;
    }

     
     
    function buyNFT(uint256 _tokenId) public payable onlyDuringPresale whenNotPaused {
        require(msg.value == _getItemPrice(_tokenId), "value sent must equal the price");
    
        _setItemNotForSale(_tokenId);

        items.hostileTakeover(msg.sender, _tokenId);

        emit LogNFTBought(_tokenId, msg.sender, msg.value);
    }

     
     
    function buyTokens(uint256 _amount) public payable onlyDuringPresale whenNotPaused {
        require(tokenDiscountedPrices.length > 0, "prices should be set before selling tokens");
        uint256 priceToUse = tokenDiscountedPrices[0];
        for (uint256 index = 1; index < tokenDiscountedPrices.length; index++) {
            if (_amount >= tokenDiscountThresholds[index]) {
                priceToUse = tokenDiscountedPrices[index];
            }
        }
        require(msg.value == _amount.mul(priceToUse), "we only accept exact payment");

        tokens.mint(msg.sender, _amount);

        emit LogTokensBought(msg.sender, _amount, msg.value);
    }

     
     
     
     
     
     
     
    function getItem(uint256 _tokenId) external view 
        returns(uint256 tokenId, address owner, string tokenURI, uint256 price, uint256 discountedPrice, bool forSale, bool discounted) {
        tokenId = _tokenId;
        owner = items.ownerOf(_tokenId);
        tokenURI = items.tokenURI(_tokenId);
        price = tokenPrices[_tokenId];
        discountedPrice = discountedItemPrices[_tokenId];
        forSale = isTokenForSale(_tokenId);
        discounted = _isTokenDiscounted(_tokenId);
    }

     
     
     
     
     
     
    function getItemsForSale(uint256 _fromIndex, uint256 _toIndex) public view 
        returns(uint256[20] ids, address[20] owners, uint256[20] prices, uint256[20] discountedPrices) {
        require(_toIndex <= itemsForSale.length);
        require(_fromIndex < _toIndex);
        require(_toIndex.sub(_fromIndex) <= ids.length);

        uint256 resultIndex = 0;
        for (uint256 index = _fromIndex; index < _toIndex; index++) {
            uint256 tokenId = itemsForSale[index];
            ids[resultIndex] = tokenId;
            owners[resultIndex] = items.ownerOf(tokenId);
            prices[resultIndex] = tokenPrices[tokenId];
            discountedPrices[resultIndex] = discountedItemPrices[tokenId];
            resultIndex = resultIndex.add(1);
        }
    }

     
     
     
     
     
     
     
    function getDiscountedItemsForSale(uint256 _fromIndex, uint256 _toIndex) public view 
        returns(uint256[20] ids, address[20] owners, uint256[20] prices, uint256[20] discountedPrices) {
        require(_toIndex <= discountedItems.length, "toIndex out of bounds");
        require(_fromIndex < _toIndex, "fromIndex must be less than toIndex");
        require(_toIndex.sub(_fromIndex) <= ids.length, "requested range cannot exceed 20 items");
        
        uint256 resultIndex = 0;
        for (uint256 index = _fromIndex; index < _toIndex; index++) {
            uint256 tokenId = discountedItems[index];
            ids[resultIndex] = tokenId;
            owners[resultIndex] = items.ownerOf(tokenId);
            prices[resultIndex] = tokenPrices[tokenId];
            discountedPrices[resultIndex] = discountedItemPrices[tokenId];
            resultIndex = resultIndex.add(1);
        }
    }

     
     
     
    function isTokenForSale(uint256 _tokenId) internal view returns(bool) {
        return tokenPrices[_tokenId] != 0;
    }

     
     
    function totalItemsForSale() public view returns(uint256) {
        return itemsForSale.length;
    }

     
     
    function NFTBalanceOf(address _owner) public view returns (uint256) {
        return items.balanceOf(_owner);
    }

     
     
    function tokenOfOwnerByRange(address _owner, uint256 _fromIndex, uint256 _toIndex) public view returns(uint256[20] ids) {
        require(_toIndex <= items.balanceOf(_owner));
        require(_fromIndex < _toIndex);
        require(_toIndex.sub(_fromIndex) <= ids.length);

        uint256 resultIndex = 0;
        for (uint256 index = _fromIndex; index < _toIndex; index++) {
            ids[resultIndex] = items.tokenOfOwnerByIndex(_owner, index);
            resultIndex = resultIndex.add(1);
        }
    }

     
     
    function tokenBalanceOf(address _owner) public view returns (uint256) {
        return tokens.balanceOf(_owner);
    }

     
     
    function totalDiscountedItemsForSale() public view returns (uint256) {
        return discountedItems.length;
    }

     

     
     
     
     
     
    function giftNFT(address _to, uint256 _tokenId, uint256 _tokenPrice) public onlyOperator {
        require(_to != address(0));
        require(items.ownerOf(_tokenId) == operator);
        require(_tokenPrice > 0, "must provide the token price to log");

        if (isTokenForSale(_tokenId)) {
            _setItemNotForSale(_tokenId);
        }

        items.hostileTakeover(_to, _tokenId);

        emit LogNFTGifted(_to, _tokenId, _tokenPrice, operator);
    }

     
     
     
    function giftTokens(address _to, uint256 _amount) public onlyOperator {
        require(_to != address(0));
        require(_amount > 0);
        
        tokens.mint(_to, _amount);

        emit LogTokensGifted(_to, _amount, operator);
    }

     
     
     
     
    function burnNFT(uint256 _tokenId) public onlyOperator {
        if (isTokenForSale(_tokenId)) {
            _setItemNotForSale(_tokenId);
        }
        
        items.burn(_tokenId);

        emit LogNFTBurned(_tokenId, operator);
    }

     
     
     
    function setTokenPrices(uint256[] _tokenDiscountThresholds, uint256[] _tokenDiscountedPrices) public onlyOperator {
        require(_tokenDiscountThresholds.length <= 10, "inputs length must be under 10 options");
        require(_tokenDiscountThresholds.length == _tokenDiscountedPrices.length, "input arrays must have the same length");

        emit LogTokenPricesSet(tokenDiscountThresholds, tokenDiscountedPrices, _tokenDiscountThresholds, _tokenDiscountedPrices, operator);

        tokenDiscountThresholds = _tokenDiscountThresholds;
        tokenDiscountedPrices = _tokenDiscountedPrices;
    }

     
     
     
    function getTokenPrices() public view returns(uint256[10] discountThresholds, uint256[10] discountedPrices) {
        for (uint256 index = 0; index < tokenDiscountThresholds.length; index++) {
            discountThresholds[index] = tokenDiscountThresholds[index];
            discountedPrices[index] = tokenDiscountedPrices[index];
        }
    }

     
     
     
    function mintNFTNotForSale(uint256 _tokenId, string _tokenURI) public onlyOperator {
        items.mint(_tokenId, _tokenURI);

        emit LogNFTMintedNotForSale(_tokenId, operator);
    }

     
     
     
    function mintNFTsNotForSale(uint256[] _tokenIds, bytes32[] _tokenURIParts) public onlyOperator {
        require(_tokenURIParts.length > 0, "need at least one string to build URIs");

        for (uint256 index = 0; index < _tokenIds.length; index++) {
            uint256 tokenId = _tokenIds[index];
            string memory tokenURI = _generateTokenURI(_tokenURIParts, tokenId);

            mintNFTNotForSale(tokenId, tokenURI);
        }
    }

     
     
     
     
    function mintNFTForSale(uint256 _tokenId, string _tokenURI, uint256 _tokenPrice) public onlyOperator {
        tokenPrices[_tokenId] = _tokenPrice;
        itemsForSaleIndex[_tokenId] = itemsForSale.push(_tokenId).sub(1);
        items.mint(_tokenId, _tokenURI);

        emit LogNFTMintedForSale(_tokenId, _tokenPrice, operator);
    }

     
     
     
     
    function mintNFTsForSale(uint256[] _tokenIds, bytes32[] _tokenURIParts, uint256[] _tokenPrices) public onlyOperator {
        require(_tokenIds.length == _tokenPrices.length, "ids and prices must have the same length");
        require(_tokenURIParts.length > 0, "must have URI parts to build URIs");

        for (uint256 index = 0; index < _tokenIds.length; index++) {
            uint256 tokenId = _tokenIds[index];
            uint256 tokenPrice = _tokenPrices[index];
            string memory tokenURI = _generateTokenURI(_tokenURIParts, tokenId);

            mintNFTForSale(tokenId, tokenURI, tokenPrice);
        }
    }

     
     
     
    function setItemForSale(uint256 _tokenId, uint256 _tokenPrice) public onlyOperator {
        require(items.exists(_tokenId));
        require(!isTokenForSale(_tokenId));
        require(items.ownerOf(_tokenId) == operator, "cannot set item for sale after it has been sold");

        tokenPrices[_tokenId] = _tokenPrice;
        itemsForSaleIndex[_tokenId] = itemsForSale.push(_tokenId).sub(1);
        
        emit LogNFTSetForSale(_tokenId, _tokenPrice, operator);
    }

     
     
     
    function setItemsForSale(uint256[] _tokenIds, uint256[] _tokenPrices) public onlyOperator {
        require(_tokenIds.length == _tokenPrices.length);
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            setItemForSale(_tokenIds[index], _tokenPrices[index]);
        }
    }

     
     
    function setItemNotForSale(uint256 _tokenId) public onlyOperator {
        _setItemNotForSale(_tokenId);

        emit LogNFTSetNotForSale(_tokenId, operator);
    }

     
     
    function setItemsNotForSale(uint256[] _tokenIds) public onlyOperator {
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            setItemNotForSale(_tokenIds[index]);
        }
    }

     
     
     
    function updateItemPrice(uint256 _tokenId, uint256 _tokenPrice) public onlyOperator {
        require(items.exists(_tokenId));
        require(items.ownerOf(_tokenId) == operator);
        require(isTokenForSale(_tokenId));
        tokenPrices[_tokenId] = _tokenPrice;
    }

     
     
     
    function updateItemsPrices(uint256[] _tokenIds, uint256[] _tokenPrices) public onlyOperator {
        require(_tokenIds.length == _tokenPrices.length, "input arrays must have the same length");
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            updateItemPrice(_tokenIds[index], _tokenPrices[index]);
        }
    }

     
     
     
    function setDiscounts(uint256[] _tokenIds, uint256[] _discountPrices) public onlyOperator {
        require(_tokenIds.length == _discountPrices.length, "input arrays must have the same length");

        for (uint256 index = 0; index < _tokenIds.length; index++) {
            _setDiscount(_tokenIds[index], _discountPrices[index]);    
        }
    }

     
     
    function removeDiscounts(uint256[] _tokenIds) public onlyOperator {
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            _removeDiscount(_tokenIds[index]);            
        }
    }

     
     
     
    function updateDiscounts(uint256[] _tokenIds, uint256[] _discountPrices) public onlyOperator {
        require(_tokenIds.length == _discountPrices.length, "arrays must be same-length");

        for (uint256 index = 0; index < _tokenIds.length; index++) {
            _updateDiscount(_tokenIds[index], _discountPrices[index]);
        }
    }

     
    function resetDiscounts() public onlyOperator {
        emit LogDiscountsReset(discountedItems.length, operator);

        for (uint256 index = 0; index < discountedItems.length; index++) {
            uint256 tokenId = discountedItems[index];
            discountedItemPrices[tokenId] = 0;
            discountedItemsIndex[tokenId] = 0;            
        }
        discountedItems.length = 0;
    }

     
     
     
     
    function resetOldAndSetNewDiscounts(uint256[] _tokenIds, uint256[] _discountPrices) public onlyOperator {
        resetDiscounts();
        setDiscounts(_tokenIds, _discountPrices);
    }

     
     
     
     
    function setStartAndEndTime(uint256 _startTime, uint256 _endTime) public onlyOperator {
        require(_startTime >= now);
        require(_startTime < _endTime);

        startTime = _startTime;
        endTime = _endTime;

        emit LogStartAndEndTimeSet(_startTime, _endTime, operator);
    }

    function setStartTime(uint256 _startTime) public onlyOperator {
        require(_startTime > 0);

        startTime = _startTime;

        emit LogStartTimeSet(_startTime, operator);
    }

    function setEndTime(uint256 _endTime) public onlyOperator {
        require(_endTime > 0);

        endTime = _endTime;

        emit LogEndTimeSet(_endTime, operator);
    }

     
    function withdraw() public onlyOperator {
        require(withdrawTo != address(0));
        uint256 balance = address(this).balance;
        require(address(this).balance > 0);

        withdrawTo.transfer(balance);

        emit LogWithdraw(withdrawTo, balance, owner);
    }

     

     
     
     
     
    function setTokensContract(address _cryptoTakeoversTokenAddress) public onlyOwner {
        emit LogTokensContractSet(tokens, _cryptoTakeoversTokenAddress, owner);

        tokens = CryptoTakeoversToken(_cryptoTakeoversTokenAddress);
    }

     
     
     
     
    function setItemsContract(address _cryptoTakeoversNFTAddress) public onlyOwner {
        emit LogItemsContractSet(items, _cryptoTakeoversNFTAddress, owner);

        items = CryptoTakeoversNFT(_cryptoTakeoversNFTAddress);
    }

     
     
     
    function setWithdrawTo(address _withdrawTo) public onlyOwner {
        require(_withdrawTo != address(0));

        emit LogWithdrawToChanged(withdrawTo, _withdrawTo, owner);

        withdrawTo = _withdrawTo;
    }

     

     
     
    function _setItemNotForSale(uint256 _tokenId) internal {
        require(items.exists(_tokenId));
        require(isTokenForSale(_tokenId));

        if (_isTokenDiscounted(_tokenId)) {
            _removeDiscount(_tokenId);
        }

        tokenPrices[_tokenId] = 0;

        uint256 currentTokenIndex = itemsForSaleIndex[_tokenId];
        uint256 lastTokenIndex = itemsForSale.length.sub(1);
        uint256 lastTokenId = itemsForSale[lastTokenIndex];

        itemsForSale[currentTokenIndex] = lastTokenId;
        itemsForSale[lastTokenIndex] = 0;
        itemsForSale.length = itemsForSale.length.sub(1);

        itemsForSaleIndex[_tokenId] = 0;
        itemsForSaleIndex[lastTokenId] = currentTokenIndex;
    }

    function _appendUintToString(string inStr, uint vInput) internal pure returns (string str) {
        uint v = vInput;
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory inStrb = bytes(inStr);
        bytes memory s = new bytes(inStrb.length + i);
        uint j;
        for (j = 0; j < inStrb.length; j++) {
            s[j] = inStrb[j];
        }
        for (j = 0; j < i; j++) {
            s[j + inStrb.length] = reversed[i - 1 - j];
        }
        str = string(s);
    }

    function _bytes32ArrayToString(bytes32[] data) internal pure returns (string) {
        bytes memory bytesString = new bytes(data.length * 32);
        uint urlLength;
        for (uint256 i = 0; i < data.length; i++) {
            for (uint256 j = 0; j < 32; j++) {
                byte char = byte(bytes32(uint(data[i]) * 2 ** (8 * j)));
                if (char != 0) {
                    bytesString[urlLength] = char;
                    urlLength += 1;
                }
            }
        }
        bytes memory bytesStringTrimmed = new bytes(urlLength);
        for (i = 0; i < urlLength; i++) {
            bytesStringTrimmed[i] = bytesString[i];
        }
        return string(bytesStringTrimmed);
    }

    function _generateTokenURI(bytes32[] _tokenURIParts, uint256 _tokenId) internal pure returns(string tokenURI) {
        string memory baseUrl = _bytes32ArrayToString(_tokenURIParts);
        tokenURI = _appendUintToString(baseUrl, _tokenId);
    }

    function _setDiscount(uint256 _tokenId, uint256 _discountPrice) internal {
        require(items.exists(_tokenId), "does not make sense to set a discount for an item that does not exist");
        require(items.ownerOf(_tokenId) == operator, "we only change items still owned by us");
        require(isTokenForSale(_tokenId), "does not make sense to set a discount for an item not for sale");
        require(!_isTokenDiscounted(_tokenId), "cannot discount the same item twice");
        require(_discountPrice > 0 && _discountPrice < tokenPrices[_tokenId], "discount price must be positive and less than full price");

        discountedItemPrices[_tokenId] = _discountPrice;
        discountedItemsIndex[_tokenId] = discountedItems.push(_tokenId).sub(1);

        emit LogDiscountSet(_tokenId, _discountPrice, operator);
    }

    function _updateDiscount(uint256 _tokenId, uint256 _discountPrice) internal {
        require(items.exists(_tokenId), "item must exist");
        require(items.ownerOf(_tokenId) == operator, "we must own the item");
        require(_isTokenDiscounted(_tokenId), "must be discounted");
        require(_discountPrice > 0 && _discountPrice < tokenPrices[_tokenId], "discount price must be positive and less than full price");

        discountedItemPrices[_tokenId] = _discountPrice;

        emit LogDiscountUpdated(_tokenId, _discountPrice, operator);
    }

    function _getItemPrice(uint256 _tokenId) internal view returns(uint256) {
        if (_isTokenDiscounted(_tokenId)) {
            return discountedItemPrices[_tokenId];
        }
        return tokenPrices[_tokenId];
    }

    function _isTokenDiscounted(uint256 _tokenId) internal view returns(bool) {
        return discountedItemPrices[_tokenId] != 0;
    }

    function _removeDiscount(uint256 _tokenId) internal {
        require(items.exists(_tokenId), "item must exist");
        require(_isTokenDiscounted(_tokenId), "item must be discounted");

        discountedItemPrices[_tokenId] = 0;

        uint256 currentTokenIndex = discountedItemsIndex[_tokenId];
        uint256 lastTokenIndex = discountedItems.length.sub(1);
        uint256 lastTokenId = discountedItems[lastTokenIndex];

        discountedItems[currentTokenIndex] = lastTokenId;
        discountedItems[lastTokenIndex] = 0;
        discountedItems.length = discountedItems.length.sub(1);

        discountedItemsIndex[_tokenId] = 0;
        discountedItemsIndex[lastTokenId] = currentTokenIndex;

        emit LogDiscountRemoved(_tokenId, operator);
    }
}