 

pragma solidity ^0.4.18;

contract HelloChicken {

  event Transfer(address indexed from, address indexed to, uint256 value);

  string public constant name = "Chicken";
  string public constant symbol = "CHK";
  uint256 public constant decimals = 0;

  uint256 totalSupply_;

  mapping(address => uint256) balances_;
  mapping(address => uint256) lastDay_;
  mapping(address => uint256) spentToday_;

  function Chicken() public {
    totalSupply_ = 0;
  }

  function underLimit(uint256 _value) internal returns (bool) {
    if (today() > lastDay_[msg.sender]) {
      spentToday_[msg.sender] = 0;
      lastDay_[msg.sender] = today();
    }
    if (spentToday_[msg.sender] + _value >= spentToday_[msg.sender] && spentToday_[msg.sender] + _value <= 5) {
      spentToday_[msg.sender] += _value;
      return true;
    }
    return false;
  }

  function today() private view returns (uint256) {
    return now / 1 days;
  }

  modifier limitedDaily(uint256 _value) {
    require(underLimit(_value));
    _;
  }

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public limitedDaily(_value) returns (bool) {
    require(_to != address(0));
    require(_to != msg.sender);

    totalSupply_ += _value;
    balances_[_to] += _value;
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances_[_owner];
  }
}