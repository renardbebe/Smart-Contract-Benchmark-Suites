 

pragma solidity ^0.4.13;


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
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

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}


contract GenesisToken is StandardToken, Ownable {
  using SafeMath for uint256;

   
  string public constant name = 'Genesis';
  string public constant symbol = 'GNS';
  uint256 public constant decimals = 18;
  string public version = '0.0.1';

   
  event EarnedGNS(address indexed contributor, uint256 amount);
  event TransferredGNS(address indexed from, address indexed to, uint256 value);

   
  function GenesisToken(
    address _owner,
    uint256 initialBalance)
  {
    owner = _owner;
    totalSupply = initialBalance;
    balances[_owner] = initialBalance;
    EarnedGNS(_owner, initialBalance);
  }

   
  function giveTokens(address _to, uint256 _amount) onlyOwner returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    EarnedGNS(_to, _amount);
    return true;
  }
}

 
contract CrowdWallet is Ownable {
  using SafeMath for uint;

  struct Deposit {
    uint amount;
    uint block;
  }

  struct Payout {
    uint amount;
    uint block;
  }

   
  GenesisToken public token;

   
  mapping (address => Deposit[]) public deposits;
  mapping (address => Payout[]) public payouts;

   
  uint public lifetimeDeposits;
  uint public lifetimePayouts;

   
  uint public blocksPerPayPeriod = 172800;  
  uint public previousPayoutBlock;
  uint public nextPayoutBlock;

   
   
  uint public payoutPool;

   
  uint multiplier = 10**18;

   
  uint public minWithdrawalThreshold = 100000000000000000;  

   
  event onDeposit(address indexed _from, uint _amount);
  event onPayout(address indexed _to, uint _amount);
  event onPayoutFailure(address indexed _to, uint amount);

   
  function CrowdWallet(address _gns, address _owner, uint _blocksPerPayPeriod) {
    token = GenesisToken(_gns);
    owner = _owner;
    blocksPerPayPeriod = _blocksPerPayPeriod;
    nextPayoutBlock = now.add(blocksPerPayPeriod);
  }

  function setMinimumWithdrawal(uint _weiAmount) onlyOwner {
    minWithdrawalThreshold = _weiAmount;
  }

  function setBlocksPerPayPeriod(uint _blocksPerPayPeriod) onlyOwner {
    blocksPerPayPeriod = _blocksPerPayPeriod;
  }

   
  function withdraw() {
    require(previousPayoutBlock > 0);

     
    require(!isAddressLocked(msg.sender));

    uint payoutAmount = calculatePayoutForAddress(msg.sender);

     
    require(payoutAmount > minWithdrawalThreshold);

     
     
    payouts[msg.sender].push(Payout({ amount: payoutAmount, block: now }));

    require(this.balance >= payoutAmount);

    onPayout(msg.sender, payoutAmount);

    lifetimePayouts += payoutAmount;

    msg.sender.transfer(payoutAmount);
  }

   
  function isAddressLocked(address contributor) constant returns(bool) {
    var paymentHistory = payouts[contributor];

    if (paymentHistory.length == 0) {
      return false;
    }

    var lastPayment = paymentHistory[paymentHistory.length - 1];

    return (lastPayment.block >= previousPayoutBlock) && (lastPayment.block < nextPayoutBlock);
  }

   
  function isNewPayoutPeriod() constant returns(bool) {
    return now >= nextPayoutBlock;
  }

   
  function startNewPayoutPeriod() {
    require(isNewPayoutPeriod());

    previousPayoutBlock = nextPayoutBlock;
    nextPayoutBlock = nextPayoutBlock.add(blocksPerPayPeriod);
    payoutPool = this.balance;
  }

   
  function calculatePayoutForAddress(address payee) constant returns(uint) {
    uint ownedAmount = token.balanceOf(payee);
    uint totalSupply = token.totalSupply();
    uint percentage = (ownedAmount * multiplier) / totalSupply;
    uint payout = (payoutPool * percentage) / multiplier;

    return payout;
  }

   
  function ethBalance() constant returns(uint) {
    return this.balance;
  }

   
  function deposit() payable {
    onDeposit(msg.sender, msg.value);
    lifetimeDeposits += msg.value;
    deposits[msg.sender].push(Deposit({ amount: msg.value, block: now }));
  }

  function () payable {
    deposit();
  }
}