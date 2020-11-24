 

pragma solidity ^0.4.11;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract FinalizableToken {
    bool public isFinalized = false;
}

contract BasicToken is FinalizableToken, ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) {
    if (!isFinalized) revert();

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) {
    if (!isFinalized) revert();

    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract SimpleToken is StandardToken {

  string public name = "SimpleToken";
  string public symbol = "SIM";
  uint256 public decimals = 18;
  uint256 public INITIAL_SUPPLY = 10000;

   
  function SimpleToken() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }

}




contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

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

library Math {
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}


contract RexToken is StandardToken, Ownable {

  function version() constant returns (bytes32) {
      return "0.1.1";
  }

  string public constant name = "REX - Real Estate tokens";
  string public constant symbol = "REX";
  uint256 public constant decimals = 18;

  uint256 constant BASE_RATE = 700;
  uint256 constant ETH_RATE = 225; 
  uint256 constant USD_RAISED_CAP = 30*10**6; 
  uint256 constant ETHER_RAISED_CAP = USD_RAISED_CAP / ETH_RATE;
  uint256 public constant WEI_RAISED_CAP = ETHER_RAISED_CAP * 1 ether;
  uint256 constant DURATION = 4 weeks;


  uint256 TOTAL_SHARE = 1000;
  uint256 CROWDSALE_SHARE = 500;

  address ANGELS_ADDRESS = 0x00998eba0E5B83018a0CFCdeCc5304f9f167d27a;
  uint256 ANGELS_SHARE = 50;

  address CORE_1_ADDRESS = 0x4aD48BE9bf6E2d35277Bd33C100D283C29C7951F;
  uint256 CORE_1_SHARE = 75;
  address CORE_2_ADDRESS = 0x2a62609c6A6bDBE25Da4fb05980e85db9A479C5e;
  uint256 CORE_2_SHARE = 75;

  address PARTNERSHIP_ADDRESS = 0x53B8fFBe35AE548f22d5a3b31D6E5e0C04f0d2DF;
  uint256 PARTNERSHIP_SHARE = 70;

  address REWARDS_ADDRESS = 0x43F1aa047D3241B7DD250EB37b25fc509085fDf9;
  uint256 REWARDS_SHARE = 200;

  address AFFILIATE_ADDRESS = 0x64ea62A8080eD1C2b8d996ACC7a82108975e5361;
  uint256 AFFILIATE_SHARE = 30;

   
  address vault;
  uint256 public startTime;
  uint256 public weiRaised;

  event TokenCreated(address indexed investor, uint256 amount);

  function RexToken(uint256 _start, address _vault) {
    startTime = _start;
    vault = _vault;
    isFinalized = false;
  }

  function () payable {
    createTokens(msg.sender);
  }

  function createTokens(address recipient) payable {
    if (tokenSaleOnHold) revert();
    if (msg.value == 0) revert();
    if (now < startTime) revert();
    if (now > startTime + DURATION) revert();

    uint256 weiAmount = msg.value;

    if (weiRaised >= WEI_RAISED_CAP) revert();

     
    if ((weiRaised + weiAmount) > WEI_RAISED_CAP) {
      weiAmount = WEI_RAISED_CAP - weiRaised;
      if (!msg.sender.send(msg.value - weiAmount)) 
        revert();
    }

     
    uint256 tokens = weiAmount.mul(getRate());

     
    totalSupply = totalSupply.add(tokens);
    weiRaised = weiRaised.add(weiAmount);

    balances[recipient] = balances[recipient].add(tokens);
    TokenCreated(recipient, tokens);

     
    if (!vault.send(weiAmount)) revert();
  }

   
  function getRate() constant returns (uint256) {
    uint256 bonus = 0;
    if (now < (startTime + 1 weeks)) {
      bonus = 300;
    } else if (now < (startTime + 2 weeks)) {
      bonus = 200;
    } else if (now < (startTime + 3 weeks)) {
      bonus = 100;
    }
    return BASE_RATE.add(bonus);
  }

  function tokenAmount(uint256 share, uint256 finalSupply) constant returns (uint) {
    if (share > TOTAL_SHARE) revert();

    return share.mul(finalSupply).div(TOTAL_SHARE);
  }

   
  function grantTokensByShare(address to, uint256 share, uint256 finalSupply) internal {
    uint256 tokens = tokenAmount(share, finalSupply);
    balances[to] = balances[to].add(tokens);
    TokenCreated(to, tokens);
    totalSupply = totalSupply.add(tokens);
  }

  function getFinalSupply() constant returns (uint256) {
    return TOTAL_SHARE.mul(totalSupply).div(CROWDSALE_SHARE);
  }


   
  function finalize() onlyOwner() {
    if (isFinalized) revert();

     
    if (weiRaised < WEI_RAISED_CAP && now <= startTime + DURATION) revert();

    uint256 finalSupply = getFinalSupply();

    grantTokensByShare(ANGELS_ADDRESS, ANGELS_SHARE, finalSupply);
    grantTokensByShare(CORE_1_ADDRESS, CORE_1_SHARE, finalSupply);
    grantTokensByShare(CORE_2_ADDRESS, CORE_2_SHARE, finalSupply);

    grantTokensByShare(PARTNERSHIP_ADDRESS, PARTNERSHIP_SHARE, finalSupply);
    grantTokensByShare(REWARDS_ADDRESS, REWARDS_SHARE, finalSupply);
    grantTokensByShare(AFFILIATE_ADDRESS, AFFILIATE_SHARE, finalSupply);
    
    isFinalized = true;
  }

  bool public tokenSaleOnHold;

  function toggleTokenSaleOnHold() onlyOwner() {
    if (tokenSaleOnHold)
      tokenSaleOnHold = false;
    else
      tokenSaleOnHold = true;
  }

  bool public migrateDisabled;

  struct structMigrate {
    uint dateTimeCreated;
    uint amount;
  }

  mapping(address => structMigrate) pendingMigrations;

  function toggleMigrationStatus() onlyOwner() {
    if (migrateDisabled)
      migrateDisabled = false;
    else
      migrateDisabled = true;
  }

  function migrate(uint256 amount) {

     
    if (!isFinalized) 
      revert();

     
    if (migrateDisabled) 
      revert();

     
    if (pendingMigrations[msg.sender].amount > 0)
      revert();

     
     
     
    uint256 amount_4dp = amount / (10**14);

     
    StandardToken(0x0042a689f1ebfca404e13c29cb6d01e00059ba9dbc).transferFrom(msg.sender, this, amount_4dp);

     
    pendingMigrations[msg.sender].dateTimeCreated = now;
    pendingMigrations[msg.sender].amount = amount;
  }

  function claimMigrate() {

     
    if (migrateDisabled) 
      revert();

     
    if (pendingMigrations[msg.sender].amount == 0)
      revert();

     
    if (now < pendingMigrations[msg.sender].dateTimeCreated + 1 weeks)
      revert();

     
    balances[msg.sender] += pendingMigrations[msg.sender].amount;
    totalSupply += pendingMigrations[msg.sender].amount;

     
    delete pendingMigrations[msg.sender];
  }

  function transferOwnCoins(address _to, uint _value) onlyOwner() {
    if (!isFinalized) revert();

    balances[this] = balances[this].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(this, _to, _value);
  }

}