 

pragma solidity ^0.4.13;

 
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

 
contract Pausable is Ownable {
    
  event Pause();
  
  event Unpause();

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused {
    paused = false;
    Unpause();
  }
  
}

contract SGAToken is MintableToken {	
    
  string public constant name = "SGA Token";
   
  string public constant symbol = "SGA";
    
  uint32 public constant decimals = 18;

  bool public transferAllowed = false;

  modifier whenTransferAllowed() {
    require(transferAllowed || msg.sender == owner);
    _;
  }

  function allowTransfer() onlyOwner {
    transferAllowed = true;
  }

  function transfer(address _to, uint256 _value) whenTransferAllowed returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) whenTransferAllowed returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
    
}


contract PurchaseBonusCrowdsale is Pausable {

  using SafeMath for uint;

  struct Bonus {
    uint limit;
    uint bonus;
  }
 
  Bonus[] public bonuses;

  function bonusesCount() constant returns(uint) {
    return bonuses.length;
  }

  function addBonus(uint limit, uint bonus) onlyOwner {
    bonuses.push(Bonus(limit, bonus));
  }

  function removeBonus(uint8 number) onlyOwner {
    require(number < bonuses.length);

    delete bonuses[number];

    for (uint i = number; i < bonuses.length - 1; i++) {
      bonuses[i] = bonuses[i+1];
    }

    bonuses.length--;
  }

  function changeBonus(uint8 number, uint limit, uint bonusValue) onlyOwner {
    require(number < bonuses.length);
    Bonus storage bonus = bonuses[number];

    bonus.limit = limit;
    bonus.bonus = bonusValue;
  }

  function insertBonus(uint8 numberAfter, uint limit, uint bonus) onlyOwner {
    require(numberAfter < bonuses.length);

    bonuses.length++;

    for (uint i = bonuses.length - 2; i > numberAfter; i--) {
      bonuses[i + 1] = bonuses[i];
    }

    bonuses[numberAfter + 1] = Bonus(limit, bonus);
  }

  function clearBonuses() onlyOwner {
    require(bonuses.length > 0);
    for (uint i = 0; i < bonuses.length; i++) {
      delete bonuses[i];
    }
    bonuses.length -= bonuses.length;
  }

  function getBonus(uint value) constant returns(uint) {
    uint targetBonus = 0;
    if(value < bonuses[0].limit)
      return 0;
    for (uint i = bonuses.length; i > 0; i--) {
      Bonus storage bonus = bonuses[i - 1];
      if (value >= bonus.limit)
        return bonus.bonus;
      else
        targetBonus = bonus.bonus;
    }
    return targetBonus;
  }

}

contract Crowdsale is PurchaseBonusCrowdsale {

  uint public start;

  uint public period;

  uint public invested;

  uint public hardCap;
  
  uint public softCap;

  address public multisigWallet;

  address public secondWallet;
  
  address public foundersTokensWallet;
  
  uint public secondWalletPercent;

  uint public foundersTokensPercent;
  
  uint public price;
  
  uint public minPrice;

  uint public percentRate = 1000;

  bool public refundOn = false;
  
  mapping (address => uint) public balances;

  SGAToken public token = new SGAToken();

  function Crowdsale() {
    period = 60;
    price = 3000;
    minPrice = 50000000000000000;
    start = 1505998800;
    hardCap = 186000000000000000000000;
    softCap =  50000000000000000000000;
    foundersTokensPercent = 202;
    foundersTokensWallet = 0x839D81F27B870632428fab6ae9c5903936a4E5aE;
    multisigWallet = 0x0CeeD87a6b8ac86938B6c2d1a0fA2B2e9000Cf6c;
    secondWallet = 0x949e62320992D5BD123B4616d2E2769473101AbB;
    secondWalletPercent = 10;
    addBonus(1000000000000000000,5);
    addBonus(2000000000000000000,10);
    addBonus(3000000000000000000,15);
    addBonus(5000000000000000000,20);
    addBonus(7000000000000000000,25);
    addBonus(10000000000000000000,30);
    addBonus(15000000000000000000,35);
    addBonus(20000000000000000000,40);
    addBonus(50000000000000000000,45);
    addBonus(75000000000000000000,50);
    addBonus(100000000000000000000,55);
    addBonus(150000000000000000000,60);
    addBonus(200000000000000000000,70);
    addBonus(300000000000000000000,75);
    addBonus(500000000000000000000,80);
    addBonus(750000000000000000000,90);
    addBonus(1000000000000000000000,100);
    addBonus(1500000000000000000000,110);
    addBonus(2000000000000000000000,125);
    addBonus(3000000000000000000000,140);
  }

  modifier saleIsOn() {
    require(now >= start && now < lastSaleDate());
    _;
  }
  
  modifier isUnderHardCap() {
    require(invested <= hardCap);
    _;
  }
  
  function lastSaleDate() constant returns(uint) {
    return start + period * 1 days;
  }

  function setStart(uint newStart) onlyOwner {
    start = newStart;
  }
  
  function setMinPrice(uint newMinPrice) onlyOwner {
    minPrice = newMinPrice;
  }

  function setHardcap(uint newHardcap) onlyOwner {
    hardCap = newHardcap;
  }

  function setPrice(uint newPrice) onlyOwner {
    price = newPrice;
  }

  function setFoundersTokensPercent(uint newFoundersTokensPercent) onlyOwner {
    foundersTokensPercent = newFoundersTokensPercent;
  }

  function setSoftcap(uint newSoftcap) onlyOwner {
    softCap = newSoftcap;
  }

  function setSecondWallet(address newSecondWallet) onlyOwner {
    secondWallet = newSecondWallet;
  }
  
  function setSecondWalletPercent(uint newSecondWalletPercent) onlyOwner {
    secondWalletPercent = newSecondWalletPercent;
  }

  function setMultisigWallet(address newMultisigWallet) onlyOwner {
    multisigWallet = newMultisigWallet;
  }

  function setFoundersTokensWallet(address newFoundersTokensWallet) onlyOwner {
    foundersTokensWallet = newFoundersTokensWallet;
  }

  function createTokens() whenNotPaused isUnderHardCap saleIsOn payable {
    require(msg.value >= minPrice);
    balances[msg.sender] = balances[msg.sender].add(msg.value);
    invested = invested.add(msg.value);
    uint bonusPercent = getBonus(msg.value);
    uint tokens = msg.value.mul(price);
    uint bonusTokens = tokens.mul(bonusPercent).div(percentRate);
    uint tokensWithBonus = tokens.add(bonusTokens);
    token.mint(this, tokensWithBonus);
    token.transfer(msg.sender, tokensWithBonus);
  }

  function refund() whenNotPaused {
    require(now > start && refundOn && balances[msg.sender] > 0);
    msg.sender.transfer(balances[msg.sender]);
  } 

  function finishMinting() public whenNotPaused onlyOwner {
    if(invested < softCap) {
      refundOn = true;      
    } else {
      uint secondWalletInvested = invested.mul(secondWalletPercent).div(percentRate);
      secondWallet.transfer(secondWalletInvested);
      multisigWallet.transfer(invested - secondWalletInvested);    
      uint issuedTokenSupply = token.totalSupply();
      uint foundersTokens = issuedTokenSupply.mul(foundersTokensPercent).div(percentRate - foundersTokensPercent);
      token.mint(this, foundersTokens);
      token.allowTransfer();
      token.transfer(foundersTokensWallet, foundersTokens);
    }
    token.finishMinting();
    token.transferOwnership(owner);
  }

  function() external payable {
    createTokens();
  }

  function retrieveTokens(address anotherToken) public onlyOwner {
    ERC20 alienToken = ERC20(anotherToken);
    alienToken.transfer(multisigWallet, token.balanceOf(this));
  }

}