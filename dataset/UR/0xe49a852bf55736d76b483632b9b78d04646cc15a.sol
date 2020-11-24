 

pragma solidity ^0.4.24;

 



 
library AddressUtils {

   
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_addr) }
    return size > 0;
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

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address previousOwner);
  event OwnershipTransferred(
    address previousOwner,
    address newOwner
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

interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
   

  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
   

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

  event Transfer(
    address _from,
    address _to,
    uint256 _tokenId
  );
  event Approval(
    address _owner,
    address _approved,
    uint256 _tokenId
  );
  event ApprovalForAll(
    address _owner,
    address _operator,
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
  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

  bool public isPaused = false;
   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256) internal ownedTokensCount;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  address public saleAgent = 0x0;

  uint256 public numberOfTokens;

  constructor() public {
     
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0), "owner couldn't be 0x0");
    return ownedTokensCount[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0), "owner couldn't be 0x0");
    return owner;
  }

   
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

   
  function approve(address _to, uint256 _tokenId) public {
    require(isPaused == false, "transactions on pause");    
    address owner = ownerOf(_tokenId);
    require(_to != owner, "can't approve to yourself");
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender, "can't send to yourself");
    require(isPaused == false, "transactions on pause");
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
  {
    require(isPaused == false, "transactions on pause");
    require(isApprovedOrOwner(msg.sender, _tokenId) || msg.sender == saleAgent);
    require(_from != address(0), "sender can't be 0x0");
    require(_to != address(0), "receiver can't be 0x0");

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
    numberOfTokens++;
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
    if (!_to.isContract() || _to == saleAgent) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

 
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

   
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

contract FabgToken is ERC721Token, Ownable {
    struct data {
        tokenType typeOfToken;
        bytes32 name;
        bytes32 url;
        bool isSnatchable;
    }
    
    mapping(uint256 => data) internal tokens;
    mapping(uint256 => uint256) internal pricesForIncreasingAuction;
    
    address presale;

    enum tokenType{MASK, LAND}
    
    event TokenCreated(
        address Receiver, 
        tokenType Type, 
        bytes32 Name, 
        bytes32 URL, 
        uint256 TokenId, 
        bool IsSnatchable
    );
    event TokenChanged(
        address Receiver, 
        tokenType Type, 
        bytes32 Name, 
        bytes32 URL, 
        uint256 TokenId, 
        bool IsSnatchable
    );
    event Paused();
    event Unpaused();
    
    modifier onlySaleAgent {
        require(msg.sender == saleAgent);
        _;
    }
    
     
    constructor() ERC721Token("FABGToken", "FABG") public {
    }

     
    function() public payable {
        revert();
    }

      
    function setPauseForAll() public onlyOwner {
        require(isPaused == false, "transactions on pause");
        isPaused = true;
        PreSale(saleAgent).setPauseForAll();

        emit Paused();
    }

      
    function setUnpauseForAll() public onlyOwner {
        require(isPaused == true, "transactions isn't on pause");
        isPaused = false;
        PreSale(saleAgent).setUnpauseForAll();

        emit Unpaused();
    }

     
    function setSaleAgent(address _saleAgent) public onlyOwner {
        saleAgent = _saleAgent;
    }
    
     
    function adminsTokenCreation(address _receiver, uint256 _price, tokenType _type, bytes32 _name, bytes32 _url, bool _isSnatchable) public onlyOwner {
        tokenCreation(_receiver, _price, _type, _name, _url, _isSnatchable);
    }

     
    function tokenCreation(address _receiver, uint256 _price, tokenType _type, bytes32 _name, bytes32 _url, bool _isSnatchable) internal {
        require(isPaused == false, "transactions on pause");
        uint256 tokenId = totalSupply();
        
        data memory info = data(_type, _name, _url, _isSnatchable);
        tokens[tokenId] = info;
        
        if(_isSnatchable == true) {
            pricesForIncreasingAuction[tokenId] = _price;
        }
        
        _mint(_receiver, tokenId);

        emit TokenCreated(_receiver, _type, _name, _url, tokenId, _isSnatchable);
    }

     
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        require(bytes(source).length <= 32, "too high length of source");
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

     
    function bytes32ToString(bytes32 x) public pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

     
    function getTokenById(uint256 _tokenId) public view returns (
        tokenType typeOfToken, 
        bytes32 name, 
        bytes32 URL, 
        bool isSnatchable
    ) {
        typeOfToken = tokens[_tokenId].typeOfToken;
        name = tokens[_tokenId].name;
        URL = tokens[_tokenId].url;
        isSnatchable = tokens[_tokenId].isSnatchable;
    }
        
     
    function getTokenPriceForIncreasing(uint256 _tokenId) public view returns (uint256) {
        require(tokens[_tokenId].isSnatchable == true);

        return pricesForIncreasingAuction[_tokenId];
    }

     
    function allTokensOfUsers(address _owner) public view returns(uint256[]) {
        return ownedTokens[_owner];
    }
    
      
    function setPresaleAddress(address _presale) public onlyOwner {
        presale = _presale;
    }

         
    function rewriteTokenFromPresale(
        uint256 _tokenId,
        address _receiver, 
        uint256 _price, 
        tokenType _type, 
        bytes32 _name, 
        bytes32 _url, 
        bool _isSnatchable
    ) public onlyOwner {
        require(ownerOf(_tokenId) == presale);
        data memory info = data(_type, _name, _url, _isSnatchable);
        tokens[_tokenId] = info;
        
        if(_isSnatchable == true) {
            pricesForIncreasingAuction[_tokenId] = _price;
        }
        
        emit TokenChanged(_receiver, _type, _name, _url, _tokenId, _isSnatchable);
    }
}
contract PreSale is Ownable {
    using SafeMath for uint;
    
    FabgToken token;
     
    address adminsWallet;
    bool public isPaused;
    uint256 totalMoney;
    
    event TokenBought(address Buyer, uint256 tokenID, uint256 price);
    event Payment(address payer, uint256 weiAmount);
    event Withdrawal(address receiver, uint256 weiAmount);
    
    modifier onlyToken() {
        require(msg.sender == address(token), "called not from token");
        _;
    }

     
    constructor(FabgToken _tokenAddress, address _walletForEth) public {
        token = _tokenAddress;
        adminsWallet = _walletForEth;
    }
    
     
    function() public payable {
       emit Payment(msg.sender, msg.value);
    }
    
      
    function setPauseForAll() public onlyToken {
        require(isPaused == false, "transactions on pause");
        isPaused = true;
    }

      
    function setUnpauseForAll() public onlyToken {
        require(isPaused == true, "transactions on pause");
        isPaused = false;
    }   
    
     
    function buyToken(uint256 _tokenId) public payable {
        require(isPaused == false, "transactions on pause");
        require(token.exists(_tokenId), "token doesn't exist");
        require(token.ownerOf(_tokenId) == address(this), "contract isn't owner of token");
        require(msg.value >= token.getTokenPriceForIncreasing(_tokenId), "was sent not enough ether");
        
        token.transferFrom(address(this), msg.sender, _tokenId);
        (msg.sender).transfer(msg.value.sub(token.getTokenPriceForIncreasing(_tokenId)));
        
        totalMoney = totalMoney.add(token.getTokenPriceForIncreasing(_tokenId));

        emit TokenBought(msg.sender, _tokenId, token.getTokenPriceForIncreasing(_tokenId));
    }

     
    function setAddressForPayment(address _newMultisig) public onlyOwner {
        adminsWallet = _newMultisig;
    }    
    
     
    function withdraw() public onlyOwner {
        require(adminsWallet != address(0), "admins wallet couldn't be 0x0");

        uint256 amount = address(this).balance;  
        (adminsWallet).transfer(amount);
        emit Withdrawal(adminsWallet, amount);
    }
}