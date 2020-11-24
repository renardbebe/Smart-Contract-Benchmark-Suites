 

pragma solidity ^0.4.18;

 
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract CryptoColors is ERC721, Ownable {
  using SafeMath for uint256;

   
  uint256 private totalTokens;
  uint256[] private listedCryptoColors;
  uint256 public devOwed;
  uint256 public poolTotal;
  uint256 public lastPurchase;

   
  mapping (uint256 => CryptoColor) public cryptoColorData;

   
  mapping (uint256 => address) private tokenOwner;

   
  mapping (uint256 => address) private tokenApprovals;

   
  mapping (address => uint256[]) private ownedTokens;

   
  mapping(uint256 => uint256) private ownedTokensIndex;

   
  mapping (address => uint256) private payoutBalances; 

   
  event TokenSold(uint256 indexed _tokenId, address indexed _owner, uint256 _purchasePrice, uint256 _price, address indexed _prevOwner);

   
  uint256 private firstCap  = 0.5 ether;
  uint256 private secondCap = 1.0 ether;
  uint256 private thirdCap  = 3.0 ether;
  uint256 private finalCap  = 5.0 ether;

   
  struct CryptoColor {
      uint256 startingPrice;  
      uint256 price;          
      uint256 lastPrice;      
      uint256 payout;         
      uint256 withdrawn;      
      address owner;          
  }

   
  function createContractToken(uint256 _tokenId, uint256 _startingPrice, uint256 _payoutPercentage, address _owner) onlyOwner() public {

     
    require(_startingPrice > 0);
     
    require(cryptoColorData[_tokenId].price == 0);
    
     
    CryptoColor storage newCryptoColor = cryptoColorData[_tokenId];

    newCryptoColor.owner = _owner;
    newCryptoColor.price = getNextPrice(_startingPrice);
    newCryptoColor.lastPrice = _startingPrice;
    newCryptoColor.payout = _payoutPercentage;
    newCryptoColor.startingPrice = _startingPrice;

     
    listedCryptoColors.push(_tokenId);
    
     
    _mint(_owner, _tokenId);
  }

  function createMultiple (uint256[] _itemIds, uint256[] _prices, uint256[] _payouts, address[] _owners) onlyOwner() external {
    for (uint256 i = 0; i < _itemIds.length; i++) {
      createContractToken(_itemIds[i], _prices[i], _payouts[i], _owners[i]);
    }
  }

   
  function getNextPrice (uint256 _price) private view returns (uint256 _nextPrice) {
    if (_price < firstCap) {
      return _price.mul(200).div(100);
    } else if (_price < secondCap) {
      return _price.mul(135).div(100);
    } else if (_price < thirdCap) {
      return _price.mul(125).div(100);
    } else if (_price < finalCap) {
      return _price.mul(117).div(100);
    } else {
      return _price.mul(115).div(100);
    }
  }

  function calculatePoolCut (uint256 _price) public view returns (uint256 _poolCut) {
    if (_price < firstCap) {
      return _price.mul(10).div(100);  
    } else if (_price < secondCap) {
      return _price.mul(9).div(100);  
    } else if (_price < thirdCap) {
      return _price.mul(8).div(100);  
    } else if (_price < finalCap) {
      return _price.mul(7).div(100);  
    } else {
      return _price.mul(5).div(100);  
    }
  }

   
  function purchase(uint256 _tokenId) public 
    payable
    isNotContract(msg.sender)
  {

     
    CryptoColor storage cryptoColor = cryptoColorData[_tokenId];
    uint256 price = cryptoColor.price;
    address oldOwner = cryptoColor.owner;
    address newOwner = msg.sender;
    uint256 excess = msg.value.sub(price);

     
    require(price > 0);
    require(msg.value >= price);
    require(oldOwner != msg.sender);

     
    uint256 profit = price.sub(cryptoColor.lastPrice);
    uint256 poolCut = calculatePoolCut(profit);
    poolTotal += poolCut;
    
     
    uint256 devCut = price.mul(5).div(100);
    devOwed = devOwed.add(devCut);

    transfer(oldOwner, newOwner, _tokenId);

     
    cryptoColor.lastPrice = price;
    cryptoColor.price = getNextPrice(price);

     
    TokenSold(_tokenId, newOwner, price, cryptoColor.price, oldOwner);

     
    oldOwner.transfer(price.sub(devCut.add(poolCut)));

     
    if (excess > 0) {
      newOwner.transfer(excess);
    }
    
     
    lastPurchase = now;

  }

   
  function transfer(address _from, address _to, uint256 _tokenId) internal {

     
    require(tokenExists(_tokenId));

     
    require(cryptoColorData[_tokenId].owner == _from);

    require(_to != address(0));
    require(_to != address(this));

     
    updateSinglePayout(_from, _tokenId);

     
    clearApproval(_from, _tokenId);

     
    removeToken(_from, _tokenId);

     
    cryptoColorData[_tokenId].owner = _to;
    addToken(_to, _tokenId);

    
    Transfer(_from, _to, _tokenId);
  }

   
  function withdraw() onlyOwner public {
    owner.transfer(devOwed);
    devOwed = 0;
  }

   
  function updatePayout(address _owner) public {
    uint256[] memory cryptoColors = ownedTokens[_owner];
    uint256 owed;
    for (uint256 i = 0; i < cryptoColors.length; i++) {
        uint256 totalcryptoColorOwed = poolTotal * cryptoColorData[cryptoColors[i]].payout / 10000;
        uint256 cryptoColorOwed = totalcryptoColorOwed.sub(cryptoColorData[cryptoColors[i]].withdrawn);
        owed += cryptoColorOwed;
        
        cryptoColorData[cryptoColors[i]].withdrawn += cryptoColorOwed;
    }
    payoutBalances[_owner] += owed;
  }

   
  function updateSinglePayout(address _owner, uint256 _itemId) internal {
    uint256 totalcryptoColorOwed = poolTotal * cryptoColorData[_itemId].payout / 10000;
    uint256 cryptoColorOwed = totalcryptoColorOwed.sub(cryptoColorData[_itemId].withdrawn);
        
    cryptoColorData[_itemId].withdrawn += cryptoColorOwed;
    payoutBalances[_owner] += cryptoColorOwed;
  }

   
  function withdrawRent(address _owner) public payable {
      updatePayout(_owner);
      uint256 payout = payoutBalances[_owner];
      payoutBalances[_owner] = 0;
      _owner.transfer(payout);
  }

  function getRentOwed(address _owner) public view returns (uint256 owed) {
    updatePayout(_owner);
    return payoutBalances[_owner];
  }

   
  function getToken (uint256 _tokenId) external view 
  returns (address _owner, uint256 _startingPrice, uint256 _price, uint256 _nextPrice, uint256 _payout, uint256 _id) 
  {
    CryptoColor memory cryptoColor = cryptoColorData[_tokenId];
    return (cryptoColor.owner, cryptoColor.startingPrice, cryptoColor.price, getNextPrice(cryptoColor.price), cryptoColor.payout, _tokenId);
  }

   
  function tokenExists (uint256 _tokenId) public view returns (bool _exists) {
    return cryptoColorData[_tokenId].price > 0;
  }

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  modifier isNotContract(address _buyer) {
    uint size;
    assembly { size := extcodesize(_buyer) }
    require(size == 0);
    _;
  }

   
  function totalSupply() public view returns (uint256) {
    return totalTokens;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return ownedTokens[_owner].length;
  }

   
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function approvedFor(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    clearApprovalAndTransfer(msg.sender, _to, _tokenId);
  }

   
  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    if (approvedFor(_tokenId) != 0 || _to != 0) {
      tokenApprovals[_tokenId] = _to;
      Approval(owner, _to, _tokenId);
    }
  }

   
  function takeOwnership(uint256 _tokenId) public {
    require(isApprovedFor(msg.sender, _tokenId));
    clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
  }

   
  function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
    return approvedFor(_tokenId) == _owner;
  }
  
   
  function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal isNotContract(_to) {
    require(_to != address(0));
    require(_to != ownerOf(_tokenId));
    require(ownerOf(_tokenId) == _from);

    clearApproval(_from, _tokenId);
    updateSinglePayout(_from, _tokenId);
    removeToken(_from, _tokenId);
    addToken(_to, _tokenId);
    Transfer(_from, _to, _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _owner);
    tokenApprovals[_tokenId] = 0;
    Approval(_owner, 0, _tokenId);
  }


     
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addToken(_to, _tokenId);
    Transfer(0x0, _to, _tokenId);
  }

   
  function addToken(address _to, uint256 _tokenId) private {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    cryptoColorData[_tokenId].owner = _to;
    uint256 length = balanceOf(_to);
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
    totalTokens = totalTokens.add(1);
  }

   
  function removeToken(address _from, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _from);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = balanceOf(_from).sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    tokenOwner[_tokenId] = 0;
    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
    totalTokens = totalTokens.sub(1);
  }

  function name() public pure returns (string _name) {
    return "CryptoColor";
  }

  function symbol() public pure returns (string _symbol) {
    return "CCLR";
  }
}