 

pragma solidity ^0.4.24;

 

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


contract IERC20{
  function allowance(address owner, address spender) external view returns (uint);
  function transferFrom(address from, address to, uint value) external returns (bool);
  function approve(address spender, uint value) external returns (bool);
  function totalSupply() external view returns (uint);
  function balanceOf(address who) external view returns (uint);
  function transfer(address to, uint value) external returns (bool);
  
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract ITimeMachine {
  function getTimestamp_() internal view returns (uint);
}


contract TimeMachineP is ITimeMachine {
   
  function getTimestamp_() internal view returns(uint) {
    return block.timestamp;
  }
}


contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract SafeERC20Timelock is ITimeMachine, Ownable {
  using SafeMath for uint;

  event Lock(address indexed _from, address indexed _for, uint indexed timestamp, uint value);
  event Withdraw(address indexed _for, uint indexed timestamp, uint value);



  mapping (address => mapping(uint => uint)) public balance;
  IERC20 public token;
  uint public totalBalance;

  constructor (address _token) public {
    token = IERC20(_token);
  }

  function contractBalance_() internal view returns(uint) {
    return token.balanceOf(this);
  }

   
  function accept(address _for, uint _timestamp, uint _tvalue) public returns(bool){
    require(_for != address(0));
    require(_for != address(this));
    require(_timestamp > getTimestamp_());
    require(_tvalue > 0);
    uint _contractBalance = contractBalance_();
    uint _balance = balance[_for][_timestamp];
    uint _totalBalance = totalBalance;
    require(token.transferFrom(msg.sender, this, _tvalue));
    uint _value = contractBalance_().sub(_contractBalance);
    balance[_for][_timestamp] = _balance.add(_value);
    totalBalance = _totalBalance.add(_value);
    emit Lock(msg.sender, _for, _timestamp, _value);
    return true;
  }


   
  function release_(address _for, uint[] _timestamp, uint[] _value) internal returns(bool) {
    uint _len = _timestamp.length;
    require(_len == _value.length);
    uint _totalValue;
    uint _curValue;
    uint _curTimestamp;
    uint _subValue;
    uint _now = getTimestamp_();
    for (uint i = 0; i < _len; i++){
      _curTimestamp = _timestamp[i];
      _curValue = balance[_for][_curTimestamp];
      _subValue = _value[i];
      require(_curValue >= _subValue);
      require(_curTimestamp <= _now);
      balance[_for][_curTimestamp] = _curValue.sub(_subValue);
      _totalValue = _totalValue.add(_subValue);
      emit Withdraw(_for, _curTimestamp, _subValue);
    }
    totalBalance = totalBalance.sub(_totalValue);
    require(token.transfer(_for, _totalValue));
    return true;
  }


   
  function release(uint[] _timestamp, uint[] _value) external returns(bool) {
    return release_(msg.sender, _timestamp, _value);
  }

   
  function releaseForce(address _for, uint[] _timestamp, uint[] _value) onlyOwner external returns(bool) {
    return release_(_for, _timestamp, _value);
  }

   
  function saveLockedERC20Tokens(address _token, address _to, uint  _amount) onlyOwner external returns (bool) {
    require(IERC20(_token).transfer(_to, _amount));
    require(totalBalance <= contractBalance_());
    return true;
  }

  function () public payable {
    revert();
  }

}

contract SafeERC20TimelockProd is TimeMachineP, SafeERC20Timelock {
  constructor (address _token) public SafeERC20Timelock(_token) {
  }
}