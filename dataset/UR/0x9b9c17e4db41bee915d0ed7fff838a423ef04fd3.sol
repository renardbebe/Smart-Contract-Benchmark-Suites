 

pragma solidity ^0.4.18;
 
 
 
contract Random {
    uint256 _seed;

    function _rand() internal returns (uint256) {
        _seed = uint256(keccak256(_seed, block.blockhash(block.number - 1), block.coinbase, block.difficulty));
        return _seed;
    }

    function _randBySeed(uint256 _outSeed) internal view returns (uint256) {
        return uint256(keccak256(_outSeed, block.blockhash(block.number - 1), block.coinbase, block.difficulty));
    }

    
    function _randByRange(uint256 _min, uint256 _max) internal returns (uint256) {
        if (_min >= _max) {
            return _min;
        }
        return (_rand() % (_max - _min +1)) + _min;
    }

    function _rankByNumber(uint256 _max) internal returns (uint256) {
        return _rand() % _max;
    }
    
}

interface CaptainTokenInterface {
  function CreateCaptainToken(address _owner,uint256 _price, uint32 _captainId, uint32 _color,uint32 _atk,uint32 _defense,uint32 _atk_min,uint32 _atk_max) public ;
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
  function balanceOf(address _owner) external view returns (uint256);
  function setTokenPrice(uint256 _tokenId, uint256 _price) external;
  function checkCaptain(address _owner,uint32 _captainId) external returns (bool);
  function setSelled(uint256 _tokenId, bool fsell) external;
}

interface CaptainGameConfigInterface {
  function getCardInfo(uint32 cardId) external constant returns (uint32,uint32,uint32, uint32,uint32,uint256,uint256);
  function getSellable(uint32 _captainId) external returns (bool);
  function getLevelConfig(uint32 cardId, uint32 level) external view returns (uint32 atk,uint32 defense,uint32 atk_min,uint32 atk_max);
}

contract CaptainPreSell is Random {
  using SafeMath for SafeMath;
  address devAddress;
  
  function CaptainPreSell() public {
    devAddress = msg.sender;
  }

  CaptainTokenInterface public captains;
  CaptainGameConfigInterface public config; 
   
  event BuyToken(uint256 tokenId, uint256 oldPrice, address prevOwner, address winner);
  
   
  mapping(uint32 => uint256) captainToCount;
  mapping(address => uint32[]) captainUserMap; 
   
   
   
  function() external payable {
  }

  modifier onlyOwner() {
    require(msg.sender == devAddress);
    _;
  }

   
  function setGameConfigContract(address _address) external onlyOwner {
    config = CaptainGameConfigInterface(_address);
  }

   
  function setCaptainTokenContract(address _address) external onlyOwner {
    captains = CaptainTokenInterface(_address);
  }

  function prepurchase(uint32 _captainId) external payable {
    uint32 color;
    uint32 atk;
    uint32 defense;
    uint256 price;
    uint256 captainCount;
    uint256 SellCount = captainToCount[_captainId];
    (color,atk,,,defense,price,captainCount) = config.getCardInfo(_captainId);
    require(config.getSellable(_captainId) == true);
    SellCount += 1;
    require(SellCount<=captainCount);
    uint256 rdm = _randByRange(90,110) % 10000;
     
    require(msg.sender != address(0));
    require(!captains.checkCaptain(msg.sender,_captainId));
     
    require(msg.value >= price);
      
    uint32 atk_min;
    uint32 atk_max; 
    (,,atk_min,atk_max) = config.getLevelConfig(_captainId,1);
   
    atk_min = uint32(SafeMath.div(SafeMath.mul(uint256(atk_min),rdm),100));
    atk_max = uint32(SafeMath.div(SafeMath.mul(uint256(atk_max),rdm),100));
   
    price = SafeMath.div(SafeMath.mul(price,130),100);
    captains.CreateCaptainToken(msg.sender,price,_captainId,color,atk, defense,atk_min,atk_max);
  
    uint256 balance = captains.balanceOf(msg.sender);
    uint256 tokenId = captains.tokenOfOwnerByIndex(msg.sender,balance-1);
    captains.setTokenPrice(tokenId,price);
     
    captainToCount[_captainId] = SellCount;

     
     
     
    BuyToken(_captainId, price,address(this),msg.sender);
  }

  function getCaptainCount(uint32 _captainId) external constant returns (uint256) {
    return captainToCount[_captainId];
  }

   
  function withdraw() external onlyOwner {
    require(this.balance>0);
    msg.sender.transfer(this.balance);
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

  function mul32(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function div32(uint32 a, uint32 b) internal pure returns (uint32) {
     
    uint32 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function sub32(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function add32(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}