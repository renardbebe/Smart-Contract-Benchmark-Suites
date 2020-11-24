 

pragma solidity ^0.4.24;

 
contract Ownable {

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  address public owner;
  address public ownerCandidate;

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function setOwnerCandidate(address candidate) external onlyOwner {
    ownerCandidate = candidate;
  }

   
  function approveNewOwner() external {
    address candidate = ownerCandidate;
    require(msg.sender == candidate, "Only owner candidate can use this function");
    emit OwnershipTransferred(owner, candidate);
    owner = candidate;
    ownerCandidate = 0x0;
  }
}

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract IERC20Token {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function allowance(address _owner, address _spender) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract CFGToken is IERC20Token, Ownable {

  using SafeMath for uint256;

  mapping(address => uint256) private balances;
  mapping(address => mapping(address => uint256)) private allowed;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint256 private totalSupply_;

  bool public initialized = false;
  uint256 public lockedUntil;
  address public hotWallet;
  address public reserveWallet;
  address public teamWallet;
  address public advisersWallet;

  constructor() public {
    symbol = "CFGT";
    name = "Cardonio Financial Group Token";
    decimals = 18;
  }

  function init(address _hotWallet, address _reserveWallet, address _teamWallet, address _advisersWallet) external onlyOwner {
    require(!initialized, "Already initialized");

    lockedUntil = now + 730 days;  
    hotWallet = _hotWallet;
    reserveWallet = _reserveWallet;
    teamWallet = _teamWallet;
    advisersWallet = _advisersWallet;

    uint256 hotSupply      = 380000000e18;
    uint256 reserveSupply  = 100000000e18;
    uint256 teamSupply     =  45000000e18;
    uint256 advisersSupply =  25000000e18;

    balances[hotWallet] = hotSupply;
    balances[reserveWallet] = reserveSupply;
    balances[teamWallet] = teamSupply;
    balances[advisersWallet] = advisersSupply;

    totalSupply_ = hotSupply.add(reserveSupply).add(teamSupply).add(advisersSupply);
    initialized = true;
  }

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0), "Receiver address should be specified");
    require(initialized, "Not initialized yet");
    require(_value <= balances[msg.sender], "Not enough funds");

    if (teamWallet == msg.sender && lockedUntil > now) {
      revert("Tokens locked");
    }

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    require(msg.sender != _spender, "Owner can not approve to himself");
    require(initialized, "Not initialized yet");

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0), "Receiver address should be specified");
    require(initialized, "Not initialized yet");
    require(_value <= balances[_from], "Not enough funds");
    require(_value <= allowed[_from][msg.sender], "Not enough allowance");

    if (teamWallet == _from && lockedUntil > now) {
      revert("Tokens locked");
    }

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function mint(address _to, uint256 _amount) external {
    address source = hotWallet;
    require(msg.sender == source, "You are not allowed withdraw tokens");
    withdraw(source, _to, _amount);
  }

   
  function withdraw(address _from, address _to, uint256 _amount) private {
    require(_to != address(0), "Receiver address should be specified");
    require(initialized, "Not initialized yet");
    require(_amount > 0, "Amount should be more than zero");
    require(_amount <= balances[_from], "Not enough funds");

    balances[_from] = balances[_from].sub(_amount);
    balances[_to] = balances[_to].add(_amount);

    emit Transfer(_from, _to, _amount);
  }

   
  function withdrawFromReserveWallet(address _to, uint256 _amount) external {
    address source = reserveWallet;
    require(msg.sender == source, "You are not allowed withdraw tokens");
    withdraw(source, _to, _amount);
  }

   
  function withdrawFromTeamWallet(address _to, uint256 _amount) external {
    address source = teamWallet;
    require(msg.sender == source, "You are not allowed withdraw tokens");
    require(lockedUntil <= now, "Tokens locked");
    withdraw(source, _to, _amount);
  }

   
  function withdrawFromAdvisersWallet(address _to, uint256 _amount) external {
    address source = advisersWallet;
    require(msg.sender == source, "You are not allowed withdraw tokens");
    withdraw(source, _to, _amount);
  }
}