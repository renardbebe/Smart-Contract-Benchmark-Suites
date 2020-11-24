 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity 0.5.0;


 

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a);
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b <= a);
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }

    c = a * b;
    require(c / a == b);
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
    require(b > 0);
    return a / b;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
    require(b > 0);
    return a % b;
  }

  function ceilingDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    return add(div(a, b), mod(a, b) > 0 ? 1 : 0);
  }

  function subU64(uint64 a, uint64 b) internal pure returns (uint64 c) {
    require(b <= a);
    return a - b;
  }

  function addU8(uint8 a, uint8 b) internal pure returns (uint8 c) {
    c = a + b;
    require(c >= a);
  }
}

 
contract KBDChestSale is
  Ownable
{
  using SafeMath for uint256;

    
  event ChestPurchased(
    uint16 _chestType,
    uint16 _chestAmount,
    address indexed _buyer,
    address indexed _referrer,
    uint256 _referralReward
  );

  struct Discount {
    uint256 blockNumber; 
    uint256 percentage;
  }
  
  event Swap(address indexed sender, ERC20 srcToken, ERC20 destToken);
  
   
  uint256 ethPrice;
  
  mapping (uint256 => uint256) chestTypePricing;
  mapping (address => bool) partnerReferral;
  mapping (uint256 => Discount) discountMapping;    

  constructor() public {
    chestTypePricing[0] = 5; 
    chestTypePricing[1] = 20;
    chestTypePricing[2] = 50;
    ethPrice = 209;
  }
  
  function setPartner(address _address, bool _status) external onlyOwner{
      partnerReferral[_address] = _status;
  }
  
  function setDiscount(uint256 _id, uint256 _blockNumber, uint256 _percentage) external onlyOwner{
      Discount memory discount;
      discount.blockNumber = _blockNumber;
      discount.percentage = _percentage;
      discountMapping[_id] = discount;
  }
  
   
  function setPriceOfEth(uint256 _price) external onlyOwner {
      ethPrice = _price;
  }
  
  function getPriceOfEth() external view returns (uint256) {
      return ethPrice;
  }
  
  function setChestTypePricing(uint256 _chestType, uint256 _chestPrice) external onlyOwner {
      chestTypePricing[_chestType] = _chestPrice;
  }
  
  function purchaseChest(uint16 _chestType, uint16 _chestAmount, uint256 _discountId, address payable _referrer) external payable {
        _purchaseChest(msg.sender, _referrer, _chestType, _chestAmount, msg.value, _discountId);
  } 
  
   
  function getChestPrice(uint256 _chestType, uint256 _discountId) public view returns (uint256) {
      uint256 chestPrice = chestTypePricing[_chestType];
      require(chestPrice != 0, "Invalid chest");
      
      Discount memory discount = discountMapping[_discountId];

      if (discount.percentage != 0) {
        require(discount.blockNumber >= block.number, "Discount has expired");
        return ((chestPrice).mul(discount.percentage).div(10000)).mul(1000000000000000000).div(ethPrice);
      } 
      
      return (chestPrice).mul(1000000000000000000).div(ethPrice);
  }
  
  function getChestPrice(uint8 _chestType, uint8 _chestAmount, uint256 _discountId) public view returns (uint256) {
      require(_chestAmount < 256, "Invalid Amount");
      
      return getChestPrice(_chestType, _discountId) * _chestAmount;
  }

  function _getReferralPercentage(address _referrer, address _owner) internal view returns (uint256 _percentage) {
      if (_referrer != _owner && _referrer != address (0)) {
          if (partnerReferral[_referrer]) {
              return 3000;
          } else {
              return 1000;
          }
      } 
      return 0;
  }
  
  function _purchaseChest(
      address payable _buyer, 
      address payable _referrer, 
      uint256 _chestType,
      uint256 _chestAmount,
      uint256 _ethAmount,
      uint256 _discountId
  ) internal {
    uint256 _totalPrice = getChestPrice(uint8(_chestType), uint8(_chestAmount), _discountId);

     
    require(_ethAmount >= _totalPrice, "Not enough ether");

     
    if (_ethAmount > _totalPrice) {
      _buyer.transfer(_ethAmount - _totalPrice);
    }

    uint256 _referralReward = _totalPrice
      .mul(_getReferralPercentage(_referrer, _buyer))
      .div(10000);

    emit ChestPurchased(uint16(_chestType), uint16(_chestAmount), _buyer, _referrer, _referralReward);

     
    if (_referralReward > 0 && !_referrer.send(_referralReward)) {
      _referralReward = 0;
    }
  }
  
   
  function withdrawBalance()
  external onlyOwner {
    msg.sender.transfer(address(this).balance);
  }
}