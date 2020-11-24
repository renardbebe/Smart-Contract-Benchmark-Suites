 

pragma solidity ^0.4.24;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
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

 

contract TokenVesting is Ownable {
  using SafeMath for uint;

  ERC20 public token;
  address public receiver;
  uint256 public startTime;
  uint256 public cliff;
  uint256 public totalPeriods;
  uint256 public timePerPeriod;
  uint256 public totalTokens;
  uint256 public tokensClaimed;

  event VestingFunded(uint256 totalTokens);
  event TokensClaimed(uint256 tokensClaimed);
  event VestingKilled();

   
  constructor(
    address _token,
    address _receiver,
    uint256 _startTime,
    uint256 _cliff,
    uint256 _totalPeriods,
    uint256 _timePerPeriod
  ) public {
    token = ERC20(_token);
    receiver = _receiver;
    startTime = _startTime;
    cliff = _cliff;
    totalPeriods = _totalPeriods;
    timePerPeriod = _timePerPeriod;
  }

   
  function fundVesting(uint256 _totalTokens) public onlyOwner {
    require(totalTokens == 0, "Vesting already funded");
    require(token.allowance(owner, address(this)) == _totalTokens);
    totalTokens = _totalTokens;
    token.transferFrom(owner, address(this), totalTokens);
    emit VestingFunded(_totalTokens);
  }

   
  function changeReceiver(address newReceiver) public onlyOwner {
    require(newReceiver != address(0));
    receiver = newReceiver;
  }

   
  function claimTokens() public {

    require(totalTokens > 0, "Vesting has not been funded yet");
    require(msg.sender == receiver, "Only receiver can claim tokens");
    require(now > startTime.add(cliff), "Vesting hasnt started yet");

    uint256 timePassed = now.sub(startTime.add(cliff));
    uint256 tokensToClaim = totalTokens
      .div(totalPeriods)
      .mul(timePassed.div(timePerPeriod))
      .sub(tokensClaimed);

    token.transfer(receiver, tokensToClaim);
    tokensClaimed = tokensClaimed.add(tokensToClaim);

    emit TokensClaimed(tokensToClaim);

  }

   
  function killVesting() public onlyOwner {
    token.transfer(owner, totalTokens.sub(tokensClaimed));
    tokensClaimed = totalTokens;
    emit VestingKilled();
  }

}