 

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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract BurritoToken is ERC721, Ownable, Pausable {
  using SafeMath for uint256;

   
  uint256 private totalTokens;
  uint256[] private listed;
  uint256 public devOwed;
  uint256 public burritoPoolTotal;
  uint256 public tacoPoolTotal;
  uint256 public saucePoolTotal;
  uint256 public lastPurchase;

   
  mapping (uint256 => Token) private tokens;

   
  mapping (uint256 => address) private tokenOwner;

   
  mapping (uint256 => address) private tokenApprovals;

   
  mapping (address => uint256[]) private ownedTokens;

   
  mapping(uint256 => uint256) private ownedTokensIndex;

   
  mapping (address => uint256) private payoutBalances; 

   
  event Purchased(uint256 indexed _tokenId, address indexed _owner, uint256 _purchasePrice);

   
  uint256 private firstCap  = 0.5 ether;
  uint256 private secondCap = 1.0 ether;
  uint256 private thirdCap  = 3.0 ether;
  uint256 private finalCap  = 5.0 ether;

   
  uint256 public feePercentage = 5;
  uint256 public dividendCutPercentage = 100;  
  uint256 public dividendDecreaseFactor = 2;
  uint256 public megabossCutPercentage = 1;
  uint256 public bossCutPercentage = 1;
  uint256 public mainPoolCutPercentage = 15;

   
  uint256 private megabossTokenId = 10000000;

  uint256 private BURRITO_KIND = 1;
  uint256 private TACO_KIND = 2;
  uint256 private SAUCE_KIND = 3;

   
  struct Token {
      uint256 price;          
      uint256 lastPrice;      
      uint256 payout;         
      uint256 withdrawn;      
      address owner;          
      uint256 bossTokenId;    
      uint8   kind;           
      address[5] previousOwners;
  }

   
  function createToken(uint256 _tokenId, uint256 _price, uint256 _lastPrice, uint256 _payoutPercentage, uint8 _kind, uint256 _bossTokenId, address _owner) onlyOwner() public {
    require(_price > 0);
    require(_lastPrice < _price);
     
    require(tokens[_tokenId].price == 0);
     
    require(_kind > 0 && _kind <= 3);
    
     
    Token storage newToken = tokens[_tokenId];

    newToken.owner = _owner;
    newToken.price = _price;
    newToken.lastPrice = _lastPrice;
    newToken.payout = _payoutPercentage;
    newToken.kind = _kind;
    newToken.bossTokenId = _bossTokenId;
    newToken.previousOwners = [address(this), address(this), address(this), address(this), address(this)];

     
    listed.push(_tokenId);
    
     
    _mint(_owner, _tokenId);
  }

  function createMultiple (uint256[] _itemIds, uint256[] _prices, uint256[] _lastPrices, uint256[] _payouts, uint8[] _kinds, uint256[] _bossTokenIds, address[] _owners) onlyOwner() external {
    for (uint256 i = 0; i < _itemIds.length; i++) {
      createToken(_itemIds[i], _prices[i], _lastPrices[i], _payouts[i], _kinds[i], _bossTokenIds[i], _owners[i]);
    }
  }

   
  function getNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
    if (_price < firstCap) {
      return _price.mul(200).div(100 - feePercentage);
    } else if (_price < secondCap) {
      return _price.mul(135).div(100 - feePercentage);
    } else if (_price < thirdCap) {
      return _price.mul(125).div(100 - feePercentage);
    } else if (_price < finalCap) {
      return _price.mul(117).div(100 - feePercentage);
    } else {
      return _price.mul(115).div(100 - feePercentage);
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
    require(!paused);

     
    Token storage token = tokens[_tokenId];
    uint256 price = token.price;
    address oldOwner = token.owner;

     
    require(price > 0);
    require(msg.value >= price);
    require(oldOwner != msg.sender);

     
    uint256 priceDelta = price.sub(token.lastPrice);
    uint256 poolCut = calculatePoolCut(priceDelta);
    
    _updatePools(token.kind, poolCut);
    
    uint256 fee = price.mul(feePercentage).div(100);
    devOwed = devOwed.add(fee);

     
    uint256 taxesPaid = _payDividendsAndBosses(token, price);

    _shiftPreviousOwners(token, msg.sender);

    transferToken(oldOwner, msg.sender, _tokenId);

     
     
    uint256 finalPayout = price.sub(fee).sub(poolCut).sub(taxesPaid);

     
    token.lastPrice = price;
    token.price = getNextPrice(price);

     
    Purchased(_tokenId, msg.sender, price);

    if (oldOwner != address(this)) {
      oldOwner.transfer(finalPayout);
    }

     
    uint256 excess = msg.value - price;
    
    if (excess > 0) {
         
        msg.sender.transfer(excess);
    }
    
     
    lastPurchase = now;
  }

     
   
   
   
  function _shiftPreviousOwners(Token storage _token, address _newOwner) private {
      _token.previousOwners[4] = _token.previousOwners[3];
      _token.previousOwners[3] = _token.previousOwners[2];
      _token.previousOwners[2] = _token.previousOwners[1];
      _token.previousOwners[1] = _token.previousOwners[0];
      _token.previousOwners[0] = _newOwner;
  }

  function _updatePools(uint8 _kind, uint256 _poolCut) internal {
    uint256 poolCutToMain = _poolCut.mul(mainPoolCutPercentage).div(100);

    if (_kind == BURRITO_KIND) {
      burritoPoolTotal += _poolCut;
    } else if (_kind == TACO_KIND) {
      burritoPoolTotal += poolCutToMain;

      tacoPoolTotal += _poolCut.sub(poolCutToMain);
    } else if (_kind == SAUCE_KIND) {
      burritoPoolTotal += poolCutToMain;

      saucePoolTotal += _poolCut.sub(poolCutToMain);
    }
  }

   
  function _payDividendsAndBosses(Token _token, uint256 _price) private returns (uint256 paid) {
    uint256 dividend0 = _price.mul(dividendCutPercentage).div(10000);
    uint256 dividend1 = dividend0.div(dividendDecreaseFactor);
    uint256 dividend2 = dividend1.div(dividendDecreaseFactor);
    uint256 dividend3 = dividend2.div(dividendDecreaseFactor);
    uint256 dividend4 = dividend3.div(dividendDecreaseFactor);

     
    if (_token.previousOwners[0] != address(this)) {_token.previousOwners[0].transfer(dividend0); paid = paid.add(dividend0);}
    if (_token.previousOwners[1] != address(this)) {_token.previousOwners[1].transfer(dividend1); paid = paid.add(dividend1);}
    if (_token.previousOwners[2] != address(this)) {_token.previousOwners[2].transfer(dividend2); paid = paid.add(dividend2);}
    if (_token.previousOwners[3] != address(this)) {_token.previousOwners[3].transfer(dividend3); paid = paid.add(dividend3);}
    if (_token.previousOwners[4] != address(this)) {_token.previousOwners[4].transfer(dividend4); paid = paid.add(dividend4);}

    uint256 tax = _price.mul(1).div(100);

    if (tokens[megabossTokenId].owner != address(0)) {
      tokens[megabossTokenId].owner.transfer(tax);
      paid = paid.add(tax);
    }

    if (tokens[_token.bossTokenId].owner != address(0)) { 
      tokens[_token.bossTokenId].owner.transfer(tax);
      paid = paid.add(tax);
    }
  }

   
  function transferToken(address _from, address _to, uint256 _tokenId) internal {

     
    require(tokenExists(_tokenId));

     
    require(tokens[_tokenId].owner == _from);

    require(_to != address(0));
    require(_to != address(this));

     
    updateSinglePayout(_from, _tokenId);

     
    clearApproval(_from, _tokenId);

     
    removeToken(_from, _tokenId);

     
    tokens[_tokenId].owner = _to;
    addToken(_to, _tokenId);

    
    Transfer(_from, _to, _tokenId);
  }

   
  function withdraw() onlyOwner public {
    owner.transfer(devOwed);
    devOwed = 0;
  }

   
   
   
   
   
   
   

   
   

  function updatePayout(address _owner) public {
    uint256[] memory ownerTokens = ownedTokens[_owner];
    uint256 owed;
    for (uint256 i = 0; i < ownerTokens.length; i++) {
        uint256 totalOwed;
        
        if (tokens[ownerTokens[i]].kind == BURRITO_KIND) {
          totalOwed = burritoPoolTotal * tokens[ownerTokens[i]].payout / 10000;
        } else if (tokens[ownerTokens[i]].kind == TACO_KIND) {
          totalOwed = tacoPoolTotal * tokens[ownerTokens[i]].payout / 10000;
        } else if (tokens[ownerTokens[i]].kind == SAUCE_KIND) {
          totalOwed = saucePoolTotal * tokens[ownerTokens[i]].payout / 10000;
        }

        uint256 totalTokenOwed = totalOwed.sub(tokens[ownerTokens[i]].withdrawn);
        owed += totalTokenOwed;
        
        tokens[ownerTokens[i]].withdrawn += totalTokenOwed;
    }
    payoutBalances[_owner] += owed;
  }

  function priceOf(uint256 _tokenId) public view returns (uint256) {
    return tokens[_tokenId].price;
  }

   
  function updateSinglePayout(address _owner, uint256 _tokenId) internal {
    uint256 totalOwed;
        
    if (tokens[_tokenId].kind == BURRITO_KIND) {
      totalOwed = burritoPoolTotal * tokens[_tokenId].payout / 10000;
    } else if (tokens[_tokenId].kind == TACO_KIND) {
      totalOwed = tacoPoolTotal * tokens[_tokenId].payout / 10000;
    } else if (tokens[_tokenId].kind == SAUCE_KIND) {
      totalOwed = saucePoolTotal * tokens[_tokenId].payout / 10000;
    }

    uint256 totalTokenOwed = totalOwed.sub(tokens[_tokenId].withdrawn);
        
    tokens[_tokenId].withdrawn += totalTokenOwed;
    payoutBalances[_owner] += totalTokenOwed;
  }

   
  function withdrawRent(address _owner) public {
    require(_owner != address(0));
    updatePayout(_owner);
    uint256 payout = payoutBalances[_owner];
    payoutBalances[_owner] = 0;
    _owner.transfer(payout);
  }

  function getRentOwed(address _owner) public view returns (uint256 owed) {
    require(_owner != address(0));
    updatePayout(_owner);
    return payoutBalances[_owner];
  }

   
  function getToken (uint256 _tokenId) external view 
  returns (address _owner, uint256 _price, uint256 _lastPrice, uint256 _nextPrice, uint256 _payout, uint8 _kind, uint256 _bossTokenId, address[5] _previosOwners) 
  {
    Token memory token = tokens[_tokenId];
    return (token.owner, token.price, token.lastPrice, getNextPrice(token.price), token.payout, token.kind, token.bossTokenId, token.previousOwners);
  }

   
  function tokenExists (uint256 _tokenId) public view returns (bool _exists) {
    return tokens[_tokenId].price > 0;
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
    tokens[_tokenId].owner = _to;
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
    return "CryptoBurrito.co";
  }

  function symbol() public pure returns (string _symbol) {
    return "MBT";
  }

  function setFeePercentage(uint256 _newFee) onlyOwner public {
    require(_newFee <= 5);
    require(_newFee >= 3);

    feePercentage = _newFee;
  }
  
  function setMainPoolCutPercentage(uint256 _newFee) onlyOwner public {
    require(_newFee <= 30);
    require(_newFee >= 5);

    mainPoolCutPercentage = _newFee;
  }

  function setDividendCutPercentage(uint256 _newFee) onlyOwner public {
    require(_newFee <= 200);
    require(_newFee >= 50);

    dividendCutPercentage = _newFee;
  }

   
  OldContract oldContract;

  function setOldContract(address _addr) onlyOwner public {
    oldContract = OldContract(_addr);
  }

  function populateFromOldContract(uint256[] _ids) onlyOwner public {
    for (uint256 i = 0; i < _ids.length; i++) {
       
      if (tokens[_ids[i]].price == 0) {
        address _owner;
        uint256 _price;
        uint256 _lastPrice;
        uint256 _nextPrice;
        uint256 _payout;
        uint8 _kind;
        uint256 _bossTokenId;

        (_owner, _price, _lastPrice, _nextPrice, _payout, _kind, _bossTokenId) = oldContract.getToken(_ids[i]);

        createToken(_ids[i], _price, _lastPrice, _payout, _kind, _bossTokenId, _owner);
      }
    }
  }
}

interface OldContract {
  function getToken (uint256 _tokenId) external view 
  returns (address _owner, uint256 _price, uint256 _lastPrice, uint256 _nextPrice, uint256 _payout, uint8 _kind, uint256 _bossTokenId);
}