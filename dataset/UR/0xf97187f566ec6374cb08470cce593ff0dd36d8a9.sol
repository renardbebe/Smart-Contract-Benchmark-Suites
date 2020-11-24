 

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

 

 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
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

 

contract BMBYToken is ERC721Token("BMBY", "BMBY"), Ownable {

    struct BMBYTokenInfo {
        uint64 timestamp;
        string userId;
    }

    BMBYTokenInfo[] public tokens;

    mapping(uint256 => address) private creators;
    mapping(uint256 => uint256) private prices;

    address public ceoAddress;
    uint64 public creationFee;
    uint64 public initialTokenValue;
    string public baseURI;

    uint public currentOwnerFeePercent;
    uint public creatorFeePercent;

    uint256 public priceStep1;
    uint256 public priceStep2;
    uint256 public priceStep3;
    uint256 public priceStep4;
    uint256 public priceStep5;
    uint256 public priceStep6;
    uint256 public priceStep7;
    uint256 public priceStep8;

    event TokenCreated(uint256 tokenId, uint64 timestamp, string userId, address creator);
    event TokenSold(uint256 tokenId, uint256 oldPriceInEther, uint256 newPriceInEther, address prevOwner, address newOwener);

     


    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    constructor() public {
        ceoAddress = msg.sender;
        baseURI = "https://bmby.co/api/tokens/";

        creationFee = 0.03 ether;
        initialTokenValue = 0.06 ether;

        priceStep1 = 5.0 ether;
        priceStep2 = 10.0 ether;
        priceStep3 = 20.0 ether;
        priceStep4 = 30.0 ether;
        priceStep5 = 40.0 ether;
        priceStep6 = 50.0 ether;
        priceStep7 = 60.0 ether;
        priceStep8 = 70.0 ether;

        currentOwnerFeePercent = 85;
        creatorFeePercent = 5;
    }


    function getNewTokenPrice(uint256 currentTokenPrice) public view returns (uint256){

        uint newPriceValuePercent;

        if (currentTokenPrice <= priceStep1) {
            newPriceValuePercent = 200;
        } else if (currentTokenPrice <= priceStep2) {
            newPriceValuePercent = 150;
        } else if (currentTokenPrice <= priceStep3) {
            newPriceValuePercent = 135;
        } else if (currentTokenPrice <= priceStep4) {
            newPriceValuePercent = 125;
        } else if (currentTokenPrice <= priceStep5) {
            newPriceValuePercent = 120;
        } else if (currentTokenPrice <= priceStep6) {
            newPriceValuePercent = 117;
        } else if (currentTokenPrice <= priceStep7) {
            newPriceValuePercent = 115;
        } else if (currentTokenPrice <= priceStep8) {
            newPriceValuePercent = 113;
        } else {
            newPriceValuePercent = 110;
        }

        return currentTokenPrice.mul(newPriceValuePercent).div(100);
    }

     
     

    function mint(string userId) public payable {

        require(msg.value >= creationFee);
        address tokenCreator = msg.sender;

        require(isValidAddress(tokenCreator));

        uint64 timestamp = uint64(now);

        BMBYTokenInfo memory newToken = BMBYTokenInfo({timestamp : timestamp, userId : userId});

        uint256 tokenId = tokens.push(newToken) - 1;

        require(tokenId == uint256(uint32(tokenId)));

        prices[tokenId] = initialTokenValue;
        creators[tokenId] = tokenCreator;

        string memory tokenIdString = toString(tokenId);
        string memory tokenUri = concat(baseURI, tokenIdString);

        _mint(tokenCreator, tokenId);
        _setTokenURI(tokenId, tokenUri);

        emit TokenCreated(tokenId, timestamp, userId, tokenCreator);
    }

    function purchase(uint256 tokenId) public payable {

        address newHolder = msg.sender;
        address holder = ownerOf(tokenId);

        require(holder != newHolder);

        uint256 contractPayment = msg.value;

        require(contractPayment > 0);
        require(isValidAddress(newHolder));

        uint256 currentTokenPrice = prices[tokenId];

        require(currentTokenPrice > 0);

        require(contractPayment >= currentTokenPrice);

         
         

        uint256 newTokenPrice = getNewTokenPrice(currentTokenPrice);
        require(newTokenPrice > currentTokenPrice);

         

        uint256 currentOwnerFee = uint256(currentTokenPrice.mul(currentOwnerFeePercent).div(100));
        uint256 creatorFee = uint256(currentTokenPrice.mul(creatorFeePercent).div(100));

        require(contractPayment > currentOwnerFee + creatorFee);

         

        address creator = creators[tokenId];

         
        if (holder != address(this)) {
             
            holder.transfer(currentOwnerFee);
        }

         
        if (holder != creator) {
             
            creator.transfer(creatorFee);
        }

        emit Transfer(holder, newHolder, tokenId);
        emit TokenSold(tokenId, currentTokenPrice, newTokenPrice, holder, newHolder);

        removeTokenFrom(holder, tokenId);
        addTokenTo(newHolder, tokenId);

        prices[tokenId] = newTokenPrice;
    }

    function payout(uint256 amount, address destination) public onlyCEO {
        require(isValidAddress(destination));
        uint balance = address(this).balance;
        require(balance >= amount);
        destination.transfer(amount);
    }

     
     

    function setCEOAddress(address newValue) public onlyCEO {
        require(isValidAddress(newValue));
        ceoAddress = newValue;
    }

    function setCreationFee(uint64 newValue) public onlyCEO {
        creationFee = newValue;
    }

    function setInitialTokenValue(uint64 newValue) public onlyCEO {
        initialTokenValue = newValue;
    }

    function setBaseURI(string newValue) public onlyCEO {
        baseURI = newValue;
    }

    function setCurrentOwnerFeePercent(uint newValue) public onlyCEO {
        currentOwnerFeePercent = newValue;
    }

    function setCreatorFeePercent(uint newValue) public onlyCEO {
        creatorFeePercent = newValue;
    }

    function setPriceStep1(uint256 newValue) public onlyCEO {
        priceStep1 = newValue;
    }

    function setPriceStep2(uint256 newValue) public onlyCEO {
        priceStep2 = newValue;
    }

    function setPriceStep3(uint256 newValue) public onlyCEO {
        priceStep3 = newValue;
    }

    function setPriceStep4(uint256 newValue) public onlyCEO {
        priceStep4 = newValue;
    }

    function setPriceStep5(uint256 newValue) public onlyCEO {
        priceStep5 = newValue;
    }

    function setPriceStep6(uint256 newValue) public onlyCEO {
        priceStep6 = newValue;
    }

    function setPriceStep7(uint256 newValue) public onlyCEO {
        priceStep7 = newValue;
    }

    function setPriceStep8(uint256 newValue) public onlyCEO {
        priceStep8 = newValue;
    }

     
     

    function getTokenInfo(uint tokenId) public view returns (string userId, uint64 timestamp, address creator, address holder, uint256 price){
        BMBYTokenInfo memory tokenInfo = tokens[tokenId];

        userId = tokenInfo.userId;
        timestamp = tokenInfo.timestamp;
        creator = creators[tokenId];
        holder = ownerOf(tokenId);
        price = prices[tokenId];
    }

    function getTokenCreator(uint256 tokenId) public view returns (address) {
        return creators[tokenId];
    }

    function getTokenPrice(uint256 tokenId) public view returns (uint256) {
        return prices[tokenId];
    }


     
     

    function toString(uint256 v) private pure returns (string) {
        if (v == 0) {
            return "0";
        }
        else {
            uint maxlength = 100;
            bytes memory reversed = new bytes(maxlength);
            uint i = 0;
            while (v != 0) {
                uint remainder = v % 10;
                v = v / 10;
                reversed[i] = byte(48 + remainder);

                if (v != 0) {
                    i++;
                }
            }

            bytes memory s = new bytes(i + 1);
            for (uint j = 0; j <= i; j++) {
                s[j] = reversed[i - j];
            }
            return string(s);

        }
    }

    function concat(string _a, string _b) private pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory abcde = new string(_ba.length + _bb.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        return string(babcde);
    }

    function isValidAddress(address addr) private pure returns (bool) {
        return addr != address(0);
    }

}