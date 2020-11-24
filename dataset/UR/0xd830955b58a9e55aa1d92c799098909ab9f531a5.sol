 

pragma solidity ^0.4.16;

 
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


contract FidcomToken is MintableToken {
    
  string public constant name = "Fidcom";
   
  string public constant symbol = "FIDC";
    
  uint32 public constant decimals = 18;

  bool public transferAllowed = false;

  modifier whenTransferAllowed() {
    require(transferAllowed);
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


contract StagedCrowdsale is Ownable {

  using SafeMath for uint;

  struct Stage {
    uint period;
    uint hardCap;
    uint price;
    uint invested;
    uint closed;
  }

  uint public start;

  uint public totalPeriod;

  uint public totalHardCap;
 
  uint public totalInvested;

  Stage[] public stages;

  function stagesCount() constant returns(uint) {
    return stages.length;
  }

  function setStart(uint newStart) onlyOwner {
    start = newStart;
  }

  function addStage(uint period, uint hardCap, uint price) onlyOwner {
    require(period>0 && hardCap >0 && price > 0);
    stages.push(Stage(period, hardCap, price, 0, 0));
    totalPeriod = totalPeriod.add(period);
    totalHardCap = totalHardCap.add(hardCap);
  }

  function removeStage(uint8 number) onlyOwner {
    require(number >=0 && number < stages.length);

    Stage storage stage = stages[number];
    totalHardCap = totalHardCap.sub(stage.hardCap);    
    totalPeriod = totalPeriod.sub(stage.period);

    delete stages[number];

    for (uint i = number; i < stages.length - 1; i++) {
      stages[i] = stages[i+1];
    }

    stages.length--;
  }

  function changeStage(uint8 number, uint period, uint hardCap, uint price) onlyOwner {
    require(number >= 0 &&number < stages.length);

    Stage storage stage = stages[number];

    totalHardCap = totalHardCap.sub(stage.hardCap);    
    totalPeriod = totalPeriod.sub(stage.period);    

    stage.hardCap = hardCap;
    stage.period = period;
    stage.price = price;

    totalHardCap = totalHardCap.add(hardCap);    
    totalPeriod = totalPeriod.add(period);    
  }

  function insertStage(uint8 numberAfter, uint period, uint hardCap, uint price) onlyOwner {
    require(numberAfter < stages.length);


    totalPeriod = totalPeriod.add(period);
    totalHardCap = totalHardCap.add(hardCap);

    stages.length++;

    for (uint i = stages.length - 2; i > numberAfter; i--) {
      stages[i + 1] = stages[i];
    }

    stages[numberAfter + 1] = Stage(period, hardCap, price, 0, 0);
  }

  function clearStages() onlyOwner {
    for (uint i = 0; i < stages.length; i++) {
      delete stages[i];
    }
    stages.length -= stages.length;
    totalPeriod = 0;
    totalHardCap = 0;
  }

  modifier saleIsOn() {
    require(stages.length > 0 && now >= start && now < lastSaleDate());
    _;
  }
  
  modifier isUnderHardCap() {
    require(totalInvested <= totalHardCap);
    _;
  }
  
  function lastSaleDate() constant returns(uint) {
    require(stages.length > 0);
    uint lastDate = start;
    for(uint i=0; i < stages.length; i++) {
      if(stages[i].invested >= stages[i].hardCap) {
        lastDate = stages[i].closed;
      } else {
        lastDate = lastDate.add(stages[i].period * 1 days);
      }
    }
    return lastDate;
  }

  function currentStage() saleIsOn constant returns(uint) {
    uint previousDate = start;
    for(uint i=0; i < stages.length; i++) {
      if(stages[i].invested < stages[i].hardCap) {
        if(now >= previousDate && now < previousDate + stages[i].period * 1 days) {
          return i;
        }
        previousDate = previousDate.add(stages[i].period * 1 days);
      } else {
        previousDate = stages[i].closed;
      }
    }
    return 0;
  }

  function updateStageWithInvested() internal {
    uint stageIndex = currentStage();
    totalInvested = totalInvested.add(msg.value);
    Stage storage stage = stages[stageIndex];
    stage.invested = stage.invested.add(msg.value);
    if(stage.invested >= stage.hardCap) {
      stage.closed = now;
    }
  }


}

contract Crowdsale is StagedCrowdsale, Pausable {
    
  address public multisigWallet;
  
  address public foundersTokensWallet;
  
  address public bountyTokensWallet;
  
  uint public percentRate = 1000;

  uint public foundersPercent;
  
  uint public bountyPercent;
  
  FidcomToken public token = new FidcomToken();

  function setFoundersPercent(uint newFoundersPercent) onlyOwner {
    require(newFoundersPercent > 0 && newFoundersPercent < percentRate);
    foundersPercent = newFoundersPercent;
  }
  
  function setBountyPercent(uint newBountyPercent) onlyOwner {
    require(newBountyPercent > 0 && newBountyPercent < percentRate);
    bountyPercent = newBountyPercent;
  }
  
  function setMultisigWallet(address newMultisigWallet) onlyOwner {
    multisigWallet = newMultisigWallet;
  }

  function setFoundersTokensWallet(address newFoundersTokensWallet) onlyOwner {
    foundersTokensWallet = newFoundersTokensWallet;
  }

  function setBountyTokensWallet(address newBountyTokensWallet) onlyOwner {
    bountyTokensWallet = newBountyTokensWallet;
  }

  function finishMinting() public whenNotPaused onlyOwner {
    uint issuedTokenSupply = token.totalSupply();
    uint summaryTokensPercent = bountyPercent + foundersPercent;
    uint summaryFoundersTokens = issuedTokenSupply.mul(summaryTokensPercent).div(percentRate - summaryTokensPercent);
    uint totalSupply = summaryFoundersTokens + issuedTokenSupply;
    uint foundersTokens = totalSupply.mul(foundersPercent).div(percentRate);
    uint bountyTokens = totalSupply.mul(bountyPercent).div(percentRate);
    token.mint(foundersTokensWallet, foundersTokens);
    token.mint(bountyTokensWallet, bountyTokens);
    token.finishMinting();
    token.allowTransfer();
    token.transferOwnership(owner);
  }

  function createTokens() whenNotPaused isUnderHardCap saleIsOn payable {
    require(msg.value > 0);
    uint stageIndex = currentStage();
    Stage storage stage = stages[stageIndex];
    multisigWallet.transfer(msg.value);
    uint price = stage.price;
    uint tokens = msg.value.mul(1 ether).div(price);
    updateStageWithInvested();
    token.mint(msg.sender, tokens);
  }

  function() external payable {
    createTokens();
  }

  function retrieveTokens(address anotherToken) public onlyOwner {
    ERC20 alienToken = ERC20(anotherToken);
    alienToken.transfer(multisigWallet, token.balanceOf(this));
  }

}