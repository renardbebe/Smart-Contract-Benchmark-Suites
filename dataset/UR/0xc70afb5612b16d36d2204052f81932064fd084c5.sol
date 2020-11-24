 

pragma solidity ^0.4.20;

 
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

   
  function transferOwnership(address newOwner) public onlyOwner {
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

contract MintableToken {
  event Mint(address indexed to, uint256 amount);
  function leave() public;
  function mint(address _to, uint256 _amount) public returns (bool);
}

contract CryptoColors is Pausable {
  using SafeMath for uint256;

   

  string public constant name = "Pixinch Color";
  string public constant symbol = "PCLR";
  uint public constant totalSupply = 16777216;

   
   
  uint256 public totalBoughtColor;
   
  uint256 public startTime;
  uint256 public endTime;
  
   
  address public wallet;
   
  uint256 public colorPrice;
   
  uint public supplyPerColor;
   
  uint8 public ownerPart;

  uint8 public bonusStep;
  uint public nextBonusStepLimit = 500000;

   
  
   
  modifier onlyOwnerOf(uint _index) {
    require(tree[_index].owner == msg.sender);
    _;
  }

   
  modifier isValid(uint _tokenId, uint _index) {
    require(_validToken(_tokenId) && _validIndex(_index));
    _;
  }

   
  modifier whenActive() {
    require(isCrowdSaleActive());
    _;
  }

   
  modifier whenGameActive() {
    require(isGameActivated());
    _;
  }

   
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ColorPurchased(address indexed from, address indexed to, uint256 color, uint256 value);
  event ColorReserved(address indexed to, uint256 qty);


   
   
  uint256 weiRaised;
  uint256 cap;
   
  uint8 walletPart;
   
  MintableToken token;
   
  uint startPrice = 10 finney;

  struct BlockRange {
    uint start;
    uint end;
    uint next;
    address owner;
    uint price;
  }

  BlockRange[totalSupply+1] tree;
   
  uint minId = 1;
   
  uint lastBlockId = 0;
   
  mapping(address => uint256[]) ownerRangeIndex;
   
  mapping (uint256 => address) tokenApprovals;
   
  mapping(address => uint) private payments;
   
  mapping(address => uint) private ownerBalance;
  

   

  function CryptoColors(uint256 _startTime, uint256 _endTime, address _token, address _wallet) public {
    require(_token != address(0));
    require(_wallet != address(0));
    require(_startTime > 0);
    require(_endTime > now);

    owner = msg.sender;
    
    colorPrice = 0.001 ether;
    supplyPerColor = 4;
    ownerPart = 50;
    walletPart = 50;

    startTime = _startTime;
    endTime = _endTime;
    cap = 98000 ether;
    
    token = MintableToken(_token);
    wallet = _wallet;
    
     
    reserveRange(owner, 167770);
  }

   
  function () external payable {
    buy();
  }

   
  
  function myPendingPayment() public view returns (uint) {
    return payments[msg.sender];
  }

  function isGameActivated() public view returns (bool) {
    return totalSupply == totalBoughtColor || now > endTime;
  }

  function isCrowdSaleActive() public view returns (bool) {
    return now < endTime && now >= startTime && weiRaised < cap;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownerBalance[_owner];
  }

  function ownerOf(uint256 _tokenId) whenGameActive public view returns (address owner) {
    require(_validToken(_tokenId));
    uint index = lookupIndex(_tokenId);
    return tree[index].owner;
  }

   
  function tokensIndexOf(address _owner, bool _withHistory) whenGameActive public view returns (uint[] result) {
    require(_owner != address(0));
    if (_withHistory) {
      return ownerRangeIndex[_owner];
    } else {
      uint[] memory indexes = ownerRangeIndex[_owner];
      result = new uint[](indexes.length);
      uint i = 0;
      for (uint index = 0; index < indexes.length; index++) {
        BlockRange storage br = tree[indexes[index]];
        if (br.owner == _owner) {
          result[i] = indexes[index];
          i++;
        }
      }
      return;
    }
  }

  function approvedFor(uint256 _tokenId) whenGameActive public view returns (address) {
    require(_validToken(_tokenId));
    return tokenApprovals[_tokenId];
  }

   
  function getRange(uint _index) public view returns (uint, uint, address, uint, uint) {
    BlockRange storage range = tree[_index];
    require(range.owner != address(0));
    return (range.start, range.end, range.owner, range.next, range.price);
  }

  function lookupIndex(uint _tokenId) public view returns (uint index) {
    return lookupIndex(_tokenId, 1);
  }

  function lookupIndex(uint _tokenId, uint _start) public view returns (uint index) {
    if (_tokenId > totalSupply || _tokenId > minId) {
      return 0;
    }
    BlockRange storage startBlock = tree[_tokenId];
    if (startBlock.owner != address(0)) {
      return _tokenId;
    }
    index = _start;
    startBlock = tree[index];
    require(startBlock.owner != address(0));
    while (startBlock.end < _tokenId && startBlock.next != 0 ) {
      index = startBlock.next;
      startBlock = tree[index];
    }
    return;
  }

   

  function buy() public payable whenActive whenNotPaused returns (string thanks) {
    require(msg.sender != address(0));
    require(msg.value.div(colorPrice) > 0);
    uint _nbColors = 0;
    uint value = msg.value;
    if (totalSupply > totalBoughtColor) {
      (_nbColors, value) = buyColors(msg.sender, value);
    }
    if (totalSupply == totalBoughtColor) {
       
      if (weiRaised.add(value) > cap) {
        value = cap.sub(weiRaised);
      }
      _nbColors = _nbColors.add(value.div(colorPrice));
      mintPin(msg.sender, _nbColors);
      if (weiRaised == cap ) {
        endTime = now;
        token.leave();
      }
    }
    forwardFunds(value);
    return "thank you for your participation.";
  }

  function purchase(uint _tokenId) public payable whenGameActive {
    uint _index = lookupIndex(_tokenId);
    return purchaseWithIndex(_tokenId, _index);
  }
  
  function purchaseWithIndex(uint _tokenId, uint _index) public payable whenGameActive isValid(_tokenId, _index) {
    require(msg.sender != address(0));

    BlockRange storage bRange = tree[_index];
    require(bRange.start <= _tokenId && _tokenId <= bRange.end);
    if (bRange.start < bRange.end) {
       
      _index = splitRange(_index, _tokenId, _tokenId);
      bRange = tree[_index];
    }

    uint price = bRange.price;
    address prevOwner = bRange.owner;
    require(msg.value >= price && prevOwner != msg.sender);
    if (prevOwner != address(0)) {
      payments[prevOwner] = payments[prevOwner].add(price);
      ownerBalance[prevOwner]--;
    }
     
    bRange.price = bRange.price.add(bRange.price);
    bRange.owner = msg.sender;

     
    ownerRangeIndex[msg.sender].push(_index);
    ownerBalance[msg.sender]++;

    ColorPurchased(prevOwner, msg.sender, _tokenId, price);
    msg.sender.transfer(msg.value.sub(price));
  }

   

  function updateToken(address _token) onlyOwner public {
    require(_token != address(0));
    token = MintableToken(_token);
  }

  function updateWallet(address _wallet) onlyOwner public {
    require(_wallet != address(0));
    wallet = _wallet;
  }

  function withdrawPayment() public whenGameActive {
    uint refund = payments[msg.sender];
    payments[msg.sender] = 0;
    msg.sender.transfer(refund);
  }

  function transfer(address _to, uint256 _tokenId) public {
    uint _index = lookupIndex(_tokenId);
    return transferWithIndex(_to, _tokenId, _index);
  }
  
  function transferWithIndex(address _to, uint256 _tokenId, uint _index) public isValid(_tokenId, _index) onlyOwnerOf(_index) {
    BlockRange storage bRange = tree[_index];
    if (bRange.start > _tokenId || _tokenId > bRange.end) {
      _index = lookupIndex(_tokenId, _index);
      require(_index > 0);
      bRange = tree[_index];
    }
    if (bRange.start < bRange.end) {
      _index = splitRange(_index, _tokenId, _tokenId);
      bRange = tree[_index];
    }
    require(_to != address(0) && bRange.owner != _to);
    bRange.owner = _to;
    ownerRangeIndex[msg.sender].push(_index);
    Transfer(msg.sender, _to, _tokenId);
    ownerBalance[_to]++;
    ownerBalance[msg.sender]--;
  }

  function approve(address _to, uint256 _tokenId) public {
    uint _index = lookupIndex(_tokenId);
    return approveWithIndex(_to, _tokenId, _index);
  }
  
  function approveWithIndex(address _to, uint256 _tokenId, uint _index) public isValid(_tokenId, _index) onlyOwnerOf(_index) {
    require(_to != address(0));
    BlockRange storage bRange = tree[_index];
    if (bRange.start > _tokenId || _tokenId > bRange.end) {
      _index = lookupIndex(_tokenId, _index);
      require(_index > 0);
      bRange = tree[_index];
    }
    require(_to != bRange.owner);
    if (bRange.start < bRange.end) {
      splitRange(_index, _tokenId, _tokenId);
    }
    tokenApprovals[_tokenId] = _to;
    Approval(msg.sender, _to, _tokenId);
  }

  function takeOwnership(uint256 _tokenId) public {
    uint index = lookupIndex(_tokenId);
    return takeOwnershipWithIndex(_tokenId, index);
  }

  function takeOwnershipWithIndex(uint256 _tokenId, uint _index) public isValid(_tokenId, _index) {
    require(tokenApprovals[_tokenId] == msg.sender);
    BlockRange storage bRange = tree[_index];
    require(bRange.start <= _tokenId && _tokenId <= bRange.end);
    ownerBalance[bRange.owner]--;
    bRange.owner = msg.sender;
    ownerRangeIndex[msg.sender].push(_index); 
    ownerBalance[msg.sender]++;
    Transfer(bRange.owner, msg.sender, _tokenId);
    delete tokenApprovals[_tokenId];
  }


   
  function forwardFunds(uint256 value) private {
    wallet.transfer(value);
    weiRaised = weiRaised.add(value);
    msg.sender.transfer(msg.value.sub(value));
  }

  function mintPin(address _to, uint _nbColors) private {
    uint _supply = supplyPerColor.mul(_nbColors);
    if (_supply == 0) {
      return;
    }
    uint _ownerPart = _supply.mul(ownerPart)/100;
    token.mint(_to, uint256(_ownerPart.mul(100000000)));
    uint _walletPart = _supply.mul(walletPart)/100;
    token.mint(wallet, uint256(_walletPart.mul(100000000)));
  }

  function buyColors(address _to, uint256 value) private returns (uint _nbColors, uint valueRest) {
    _nbColors = value.div(colorPrice);
    if (bonusStep < 3 && totalBoughtColor.add(_nbColors) > nextBonusStepLimit) {
      uint max = nextBonusStepLimit.sub(totalBoughtColor);
      uint val = max.mul(colorPrice);
      if (max == 0 || val > value) {
        return (0, value);
      }
      valueRest = value.sub(val);
      reserveColors(_to, max);
      uint _c;
      uint _v;
      (_c, _v) = buyColors(_to, valueRest);
      return (_c.add(max), _v.add(val));
    }
    reserveColors(_to, _nbColors);
    return (_nbColors, value);
  }

  function reserveColors(address _to, uint _nbColors) private returns (uint) {
    if (_nbColors > totalSupply - totalBoughtColor) {
      _nbColors = totalSupply - totalBoughtColor;
    }
    if (_nbColors == 0) {
      return;
    }
    reserveRange(_to, _nbColors);
    ColorReserved(_to, _nbColors);
    mintPin(_to, _nbColors);
    checkForSteps();
    return _nbColors;
  }

  function checkForSteps() private {
    if (bonusStep < 3 && totalBoughtColor >= nextBonusStepLimit) {
      if ( bonusStep == 0) {
        colorPrice = colorPrice + colorPrice;
      } else {
        colorPrice = colorPrice + colorPrice - (1 * 0.001 finney);
      }
      bonusStep = bonusStep + 1;
      nextBonusStepLimit = nextBonusStepLimit + (50000 + (bonusStep+1) * 100000);
    }
    if (isGameActivated()) {
      colorPrice = 1 finney;
      ownerPart = 70;
      walletPart = 30;
      endTime = now.add(120 hours);
    }
  }

  function _validIndex(uint _index) internal view returns (bool) {
    return _index > 0 && _index < tree.length;
  }

  function _validToken(uint _tokenId) internal pure returns (bool) {
    return _tokenId > 0 && _tokenId <= totalSupply;
  }

  function reserveRange(address _to, uint _nbTokens) internal {
    require(_nbTokens <= totalSupply);
    BlockRange storage rblock = tree[minId];
    rblock.start = minId;
    rblock.end = minId.add(_nbTokens).sub(1);
    rblock.owner = _to;
    rblock.price = startPrice;
    
    rblock = tree[lastBlockId];
    rblock.next = minId;
    
    lastBlockId = minId;
    ownerRangeIndex[_to].push(minId);
    
    ownerBalance[_to] = ownerBalance[_to].add(_nbTokens);
    minId = minId.add(_nbTokens);
    totalBoughtColor = totalBoughtColor.add(_nbTokens);
  }

  function splitRange(uint index, uint start, uint end) internal returns (uint) {
    require(index > 0);
    require(start <= end);
    BlockRange storage startBlock = tree[index];
    require(startBlock.start < startBlock.end && startBlock.start <= start && startBlock.end >= end);

    BlockRange memory rblockUnique = tree[start];
    rblockUnique.start = start;
    rblockUnique.end = end;
    rblockUnique.owner = startBlock.owner;
    rblockUnique.price = startBlock.price;
    
    uint nextStart = end.add(1);
    if (nextStart <= totalSupply) {
      rblockUnique.next = nextStart;

      BlockRange storage rblockEnd = tree[nextStart];
      rblockEnd.start = nextStart;
      rblockEnd.end = startBlock.end;
      rblockEnd.owner = startBlock.owner;
      rblockEnd.next = startBlock.next;
      rblockEnd.price = startBlock.price;
    }

    if (startBlock.start < start) {
      startBlock.end = start.sub(1);
    } else {
      startBlock.end = start;
    }
    startBlock.next = start;
    tree[start] = rblockUnique;
     
    if (rblockUnique.next != startBlock.next) {
      ownerRangeIndex[startBlock.owner].push(startBlock.next);
    }
    if (rblockUnique.next != 0) {
      ownerRangeIndex[startBlock.owner].push(rblockUnique.next);
    }
    
    return startBlock.next;
  }
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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