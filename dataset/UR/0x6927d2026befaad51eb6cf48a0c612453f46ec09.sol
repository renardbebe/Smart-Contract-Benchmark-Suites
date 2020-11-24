 

pragma solidity ^0.4.13;

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

contract AccountModifiers is Ownable {

  uint defaultTakerFeeDiscount;
  uint defaultRebatePercentage;
  
  mapping (address => uint) takerFeeDiscounts;    
  mapping (address => uint) rebatePercentages;    
  
  function setDefaults(uint _defaultTakerFeeDiscount, uint _defaultRebatePercentage) onlyOwner {
    defaultTakerFeeDiscount = _defaultTakerFeeDiscount;
    defaultRebatePercentage = _defaultRebatePercentage;
  }

  function setModifiers(address _user, uint _takeFeeDiscount, uint _rebatePercentage) onlyOwner {
    takerFeeDiscounts[_user] = _takeFeeDiscount;
    rebatePercentages[_user] = _rebatePercentage;
  }

  function takerFeeDiscount(address _user) internal constant returns (uint) {
    return defaultTakerFeeDiscount > takerFeeDiscounts[_user] ? defaultTakerFeeDiscount : takerFeeDiscounts[_user];
  }

  function rebatePercentage(address _user) internal constant returns (uint) {
    return defaultRebatePercentage > rebatePercentages[_user] ? defaultRebatePercentage : rebatePercentages[_user];
  }

  function accountModifiers(address _user) constant returns(uint, uint) {
    return (takerFeeDiscount(_user), rebatePercentage(_user));
  }

  function tradeModifiers(address _maker, address _taker) constant returns(uint, uint) {
    return (takerFeeDiscount(_taker), rebatePercentage(_maker));
  }
}