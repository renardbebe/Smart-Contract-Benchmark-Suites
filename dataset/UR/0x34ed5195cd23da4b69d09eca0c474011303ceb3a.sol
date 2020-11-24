 

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
    require(newOwner != address(0));
    owner = newOwner;
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


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}


 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


contract DisbursableToken is MintableToken {
  using SafeMath for uint256;

  struct Account {
    uint claimedPoints;
    uint allowedPoints;
    uint lastPointsPerToken;
  }

  event Disburse(address _source, uint _amount);
  event ClaimDisbursement(address _account, uint _amount);
   
   
  uint pointMultiplier = 1e18;
  uint totalPointsPerToken;
  uint unclaimedDisbursement;
  uint totalDisbursement;

  mapping(address => Account) accounts;

   
  function disburse() public payable {
    totalPointsPerToken = totalPointsPerToken.add(msg.value.mul(pointMultiplier).div(totalSupply));
    unclaimedDisbursement = unclaimedDisbursement.add(msg.value);
    totalDisbursement = totalDisbursement.add(msg.value);
    Disburse(msg.sender, msg.value);
  }

   
  function updatePoints(address _account) internal {
    uint newPointsPerToken = totalPointsPerToken.sub(accounts[_account].lastPointsPerToken);
    accounts[_account].allowedPoints = accounts[_account].allowedPoints.add(balances[_account].mul(newPointsPerToken));
    accounts[_account].lastPointsPerToken = totalPointsPerToken;
  }

   
  function claimable(address _owner) constant returns (uint256 remaining) {
    updatePoints(_owner);
    return accounts[_owner].allowedPoints.sub(accounts[_owner].claimedPoints).div(pointMultiplier);
  }

   
  function claim(uint _amount) public {
    require(_amount > 0);
    updatePoints(msg.sender);
    uint claimingPoints = _amount.mul(pointMultiplier);
    require(accounts[msg.sender].claimedPoints.add(claimingPoints) <= accounts[msg.sender].allowedPoints);
    accounts[msg.sender].claimedPoints = accounts[msg.sender].claimedPoints.add(claimingPoints);
    ClaimDisbursement(msg.sender, _amount);
    require(msg.sender.send(_amount));
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    updatePoints(_to);
    super.mint(_to, _amount);
  }

  function transfer(address _to, uint _value) returns(bool) {
    updatePoints(msg.sender);
    updatePoints(_to);
    super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint _value) returns(bool) {
    updatePoints(_from);
    updatePoints(_to);
    super.transferFrom(_from, _to, _value);
  }
}


 

contract HeroToken is DisbursableToken {
  string public name = "Hero Token";
  string public symbol = "HERO";
  uint public decimals = 18;

  bool public tradingStarted = false;
   
  modifier hasStartedTrading() {
    require(tradingStarted);
    _;
  }

   
  function startTrading() onlyOwner {
    tradingStarted = true;
  }

   
  function transfer(address _to, uint _value) hasStartedTrading returns(bool) {
    super.transfer(_to, _value);
  }

    
  function transferFrom(address _from, address _to, uint _value) hasStartedTrading returns(bool) {
    super.transferFrom(_from, _to, _value);
  }

  function() external payable {
    disburse();
  }
}

 
contract MainSale is Ownable {
  using SafeMath for uint;
  event TokenSold(address recipient, uint ether_amount, uint token_amount, uint exchangerate);
  event AuthorizedCreate(address recipient, uint token_amount);
  event MainSaleClosed();

  HeroToken public token = new HeroToken();

  address public multisigVault = 0x877f1DAa6e6E9dc2764611D48c56172CE3547656;

  uint public hardcap = 250000 ether;
  uint public exchangeRate = 200;
  uint public minimum = 10 ether;

  uint public altDeposits = 0;
  uint public start = 1504266900;  
  bool public saleOngoing = true;

   
  modifier isSaleOn() {
    require(start < now && saleOngoing && !token.mintingFinished());
    _;
  }

   
  modifier isOverMinimum() {
    require(msg.value >= minimum);
    _;
  }

   
  modifier isUnderHardcap() {
    require(multisigVault.balance + altDeposits <= hardcap);
    _;
  }

   
  function createTokens(address recipient) public isOverMinimum isUnderHardcap isSaleOn payable {
    uint base = exchangeRate.mul(msg.value).mul(10**token.decimals()).div(1 ether);
    uint bonus = bonusTokens(base);
    uint tokens = base.add(bonus);
    token.mint(recipient, tokens);
    require(multisigVault.send(msg.value));
    TokenSold(recipient, msg.value, tokens, exchangeRate);
  }

   
  function bonusTokens(uint base) constant returns(uint) {
    uint bonus = 0;
    if (now <= start + 3 hours) {
      bonus = base.mul(3).div(10);
    } else if (now <= start + 24 hours) {
      bonus = base.mul(2).div(10);
    } else if (now <= start + 3 days) {
      bonus = base.div(10);
    } else if (now <= start + 7 days) {
      bonus = base.div(20);
    } else if (now <= start + 14 days) {
      bonus = base.div(40);
    }
    return bonus;
  }

   
  function authorizedCreateTokens(address recipient, uint tokens) public onlyOwner {
    token.mint(recipient, tokens);
    AuthorizedCreate(recipient, tokens);
  }

   
  function setStart(uint _start) public onlyOwner {
    start = _start;
  }

   
  function setMinimum(uint _minimum) public onlyOwner {
    minimum = _minimum;
  }

   
  function setHardcap(uint _hardcap) public onlyOwner {
    hardcap = _hardcap;
  }

   
  function setAltDeposits(uint totalAltDeposits) public onlyOwner {
    altDeposits = totalAltDeposits;
  }

   
  function setMultisigVault(address _multisigVault) public onlyOwner {
    if (_multisigVault != address(0)) {
      multisigVault = _multisigVault;
    }
  }

   
  function setExchangeRate(uint _exchangeRate) public onlyOwner {
    exchangeRate = _exchangeRate;
  }

   
  function setSaleOngoing(bool _saleOngoing) public onlyOwner {
    saleOngoing = _saleOngoing;
  }

   
  function finishMinting() public onlyOwner {
    token.finishMinting();
    token.transferOwnership(owner);
    MainSaleClosed();
  }

   
  function retrieveTokens(address _token) public onlyOwner {
    ERC20 foreignToken = ERC20(_token);
    foreignToken.transfer(multisigVault, foreignToken.balanceOf(this));
  }

   
  function() external payable {
    createTokens(msg.sender);
  }
}