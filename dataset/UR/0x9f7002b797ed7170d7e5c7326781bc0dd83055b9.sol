 

pragma solidity ^0.5.8;


library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
}


interface IERC20 {
  function balanceOf(address owner) external view returns (uint256 balance);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
  function approve(address spender, uint256 value) external returns (bool success);
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
 
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  string public constant name = "CAPZ";
  string public constant symbol = "CAPZ";
  uint8 public constant decimals = 18;

   
  uint256 public totalSupply;

  mapping(address => uint256) internal balances;
  mapping(address => mapping(address => uint256)) internal allowed;

   
   
   
  function balanceOf(address owner) external view returns (uint256) {
    return balances[owner];
  }

   
   
   
  function transfer(address to, uint256 value) external returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
   
   
   
   
   
  function transferFrom(address from, address to, uint256 value) external returns (bool) {
    _transfer(from, to, value);
    _approve(from, msg.sender, allowed[from][msg.sender].sub(value));
    return true;
  }

   
   
   
   
   
   
   
  function approve(address spender, uint256 value) external returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }

   
   
   
   
  function allowance(address owner, address spender) external view returns (uint256) {
    return allowed[owner][spender];
  }

   
   
   
   
  function _transfer(address from, address to, uint256 value) internal {
    require(address(this) != to);
    require(address(0) != to);

    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(value);

    emit Transfer(from, to, value);
  }

   
   
   
   
  function _approve(address owner, address spender, uint256 value) internal {
    require(address(0) != owner);
    require(address(0) != spender);

    allowed[owner][spender] = value;

    emit Approval(owner, spender, value);
  }

   
   
   
   
   
  function _mint(address account, uint256 value) internal {
    require(address(0) != account);

    totalSupply = totalSupply.add(value);
    balances[account] = balances[account].add(value);

    emit Transfer(address(0), account, value);
  }
}


 
 
 
 
 
 
 
 
contract CAPZ is ERC20 {
  using SafeMath for uint256;

   
   
  address internal owner;

   
   
   
  uint256 public balanceInWei;

   
   
   
   
  uint256 public goalLimitMinInWei;

   
   
   
  uint256 public goalLimitMaxInWei;

   
  uint256 public endOn;

   
  uint256 public startOn;

   
  mapping(address => uint256) internal refunds;

   
  enum ICOStatus {
     
    NotOpen,
     
     
    Open,
     
     
     
     
    GoalReached,
     
     
    GoalNotReached
  }

  constructor (uint256 _startOn, uint256 _endOn, uint256 _goalLimitMinInWei, uint256 _goalLimitMaxInWei) public {
    require(_startOn < _endOn);
    require(_goalLimitMinInWei < _goalLimitMaxInWei);

    owner = msg.sender;
    endOn = _endOn;
    startOn = _startOn;
    goalLimitMaxInWei = _goalLimitMaxInWei;
    goalLimitMinInWei = _goalLimitMinInWei;
  }

  function () external payable {
    require(0 == msg.data.length);

    buyTokens();
  }

   
   
   
   
   
   
   
   
   
  function buyTokens() public whenOpen payable {
    uint256 receivedAmount = msg.value;
    address beneficiary = msg.sender;
    uint256 newBalance = balanceInWei.add(receivedAmount);
    uint256 newRefundBalance = refunds[beneficiary].add(receivedAmount);

    _mint(beneficiary, receivedAmount);
    refunds[beneficiary] = newRefundBalance;
    balanceInWei = newBalance;
  }

   
   
   
  function escrowRefund() external whenGoalNotReached {
    uint256 amount = refunds[msg.sender];

    require(address(0) != msg.sender);
    require(0 < amount);

    refunds[msg.sender] = 0;
    msg.sender.transfer(amount);
  }

   
   
   
   
  function escrowWithdraw() external onlyOwner whenGoalReached {
    uint256 amount = address(this).balance;

    require(address(0) != msg.sender);
    require(0 < amount);

    msg.sender.transfer(amount);
  }

   
   
   
   
   
   
  function escrowClaim(uint256 amount) external whenGoalReached {
    _transfer(msg.sender, owner, amount);
    emit Claim(msg.sender, amount);
  }

   
   
   
   
   
   
  function alterGoal(uint256 _goalLimitMinInWei, uint256 _goalLimitMaxInWei) external onlyOwner {
    ICOStatus status = status(block.timestamp);

    require(ICOStatus.GoalReached != status);
    require(ICOStatus.GoalNotReached != status);
    require(_goalLimitMinInWei < _goalLimitMaxInWei);

    goalLimitMinInWei = _goalLimitMinInWei;
    goalLimitMaxInWei = _goalLimitMaxInWei;

    emit GoalChange(_goalLimitMinInWei, _goalLimitMaxInWei);
  }

   
  function transferOwnership(address newOwner) external onlyOwner {
    require(address(0) != newOwner);
    require(address(this) != newOwner);

    owner = newOwner;
  }

   
   
   
   
  function status() external view returns (ICOStatus) {
    return status(block.timestamp);
  }

   
   
  function status(uint256 timestamp) internal view returns (ICOStatus) {
    if (timestamp < startOn) {
      return ICOStatus.NotOpen;
    } else if (timestamp < endOn && balanceInWei < goalLimitMaxInWei) {
      return ICOStatus.Open;
    } else if (balanceInWei >= goalLimitMinInWei) {
      return ICOStatus.GoalReached;
    } else {
      return ICOStatus.GoalNotReached;
    }
  }

   
   
  event GoalChange(uint256 goalLimitMinInWei, uint256 goalLimitMaxInWei);

   
   
  event Claim(address beneficiary, uint256 value);

  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

  modifier whenOpen() {
    require(ICOStatus.Open == status(block.timestamp));
    _;
  }

  modifier whenGoalReached() {
    require(ICOStatus.GoalReached == status(block.timestamp));
    _;
  }

  modifier whenGoalNotReached() {
    require(ICOStatus.GoalNotReached == status(block.timestamp));
    _;
  }
}