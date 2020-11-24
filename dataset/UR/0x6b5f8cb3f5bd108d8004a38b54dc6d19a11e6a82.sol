 

pragma solidity ^0.4.18;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract TaskFairToken is StandardToken, Ownable {	

  event Mint(address indexed to, uint256 amount);

  event MintFinished();
    
  string public constant name = "Task Fair Token";
   
  string public constant symbol = "TFT";
    
  uint32 public constant decimals = 18;

  bool public mintingFinished = false;
 
  address public saleAgent;

  modifier notLocked() {
    require(msg.sender == owner || msg.sender == saleAgent || mintingFinished);
    _;
  }

  function transfer(address _to, uint256 _value) public notLocked returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address from, address to, uint256 value) public notLocked returns (bool) {
    return super.transferFrom(from, to, value);
  }

  function setSaleAgent(address newSaleAgent) public {
    require(saleAgent == msg.sender || owner == msg.sender);
    saleAgent = newSaleAgent;
  }

  function mint(address _to, uint256 _amount) public returns (bool) {
    require(!mintingFinished);
    require(msg.sender == saleAgent);
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  function finishMinting() public returns (bool) {
    require(!mintingFinished);
    require(msg.sender == owner || msg.sender == saleAgent);
    mintingFinished = true;
    MintFinished();
    return true;
  }

}

contract StagedCrowdsale is Ownable {

  using SafeMath for uint;

  uint public price;

  struct Stage {
    uint period;
    uint hardCap;
    uint discount;
    uint invested;
    uint closed;
  }

  uint public constant STAGES_PERCENT_RATE = 100;

  uint public start;

  uint public totalPeriod;

  uint public totalHardCap;
 
  uint public invested;

  Stage[] public stages;

  function stagesCount() public constant returns(uint) {
    return stages.length;
  }

  function setStart(uint newStart) public onlyOwner {
    start = newStart;
  }

  function setPrice(uint newPrice) public onlyOwner {
    price = newPrice;
  }

  function addStage(uint period, uint hardCap, uint discount) public onlyOwner {
    require(period > 0 && hardCap > 0);
    stages.push(Stage(period, hardCap, discount, 0, 0));
    totalPeriod = totalPeriod.add(period);
    totalHardCap = totalHardCap.add(hardCap);
  }

  function removeStage(uint8 number) public onlyOwner {
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

  function changeStage(uint8 number, uint period, uint hardCap, uint discount) public onlyOwner {
    require(number >= 0 && number < stages.length);

    Stage storage stage = stages[number];

    totalHardCap = totalHardCap.sub(stage.hardCap);    
    totalPeriod = totalPeriod.sub(stage.period);    

    stage.hardCap = hardCap;
    stage.period = period;
    stage.discount = discount;

    totalHardCap = totalHardCap.add(hardCap);    
    totalPeriod = totalPeriod.add(period);    
  }

  function insertStage(uint8 numberAfter, uint period, uint hardCap, uint discount) public onlyOwner {
    require(numberAfter < stages.length);


    totalPeriod = totalPeriod.add(period);
    totalHardCap = totalHardCap.add(hardCap);

    stages.length++;

    for (uint i = stages.length - 2; i > numberAfter; i--) {
      stages[i + 1] = stages[i];
    }

    stages[numberAfter + 1] = Stage(period, hardCap, discount, 0, 0);
  }

  function clearStages() public onlyOwner {
    for (uint i = 0; i < stages.length; i++) {
      delete stages[i];
    }
    stages.length -= stages.length;
    totalPeriod = 0;
    totalHardCap = 0;
  }

  function lastSaleDate() public constant returns(uint) {
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

  function currentStage() public constant returns(uint) {
    require(now >= start);
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
    revert();
  }

  function updateStageWithInvested(uint stageIndex, uint investedInWei) internal {
    invested = invested.add(investedInWei);
    Stage storage stage = stages[stageIndex];
    stage.invested = stage.invested.add(investedInWei);
    if(stage.invested >= stage.hardCap) {
      stage.closed = now;
    }
  }


}


contract CommonCrowdsale is StagedCrowdsale {

  uint public constant PERCENT_RATE = 1000;

  uint public minInvestedLimit;

  uint public minted;

  address public directMintAgent;
  
  address public wallet;

  address public devWallet;

  address public devTokensWallet;

  address public securityWallet;

  address public foundersTokensWallet;

  address public bountyTokensWallet;

  address public growthTokensWallet;

  address public advisorsTokensWallet;

  address public securityTokensWallet;

  uint public devPercent;

  uint public securityPercent;

  uint public bountyTokensPercent;

  uint public devTokensPercent;

  uint public advisorsTokensPercent;

  uint public foundersTokensPercent;

  uint public growthTokensPercent;

  uint public securityTokensPercent;

  TaskFairToken public token;

  modifier canMint(uint value) {
    require(now >= start && value >= minInvestedLimit);
    _;
  }

  modifier onlyDirectMintAgentOrOwner() {
    require(directMintAgent == msg.sender || owner == msg.sender);
    _;
  }

  function setMinInvestedLimit(uint newMinInvestedLimit) public onlyOwner {
    minInvestedLimit = newMinInvestedLimit;
  }

  function setDevPercent(uint newDevPercent) public onlyOwner { 
    devPercent = newDevPercent;
  }

  function setSecurityPercent(uint newSecurityPercent) public onlyOwner { 
    securityPercent = newSecurityPercent;
  }

  function setBountyTokensPercent(uint newBountyTokensPercent) public onlyOwner { 
    bountyTokensPercent = newBountyTokensPercent;
  }

  function setGrowthTokensPercent(uint newGrowthTokensPercent) public onlyOwner { 
    growthTokensPercent = newGrowthTokensPercent;
  }

  function setFoundersTokensPercent(uint newFoundersTokensPercent) public onlyOwner { 
    foundersTokensPercent = newFoundersTokensPercent;
  }

  function setAdvisorsTokensPercent(uint newAdvisorsTokensPercent) public onlyOwner { 
    advisorsTokensPercent = newAdvisorsTokensPercent;
  }

  function setDevTokensPercent(uint newDevTokensPercent) public onlyOwner { 
    devTokensPercent = newDevTokensPercent;
  }

  function setSecurityTokensPercent(uint newSecurityTokensPercent) public onlyOwner { 
    securityTokensPercent = newSecurityTokensPercent;
  }

  function setFoundersTokensWallet(address newFoundersTokensWallet) public onlyOwner { 
    foundersTokensWallet = newFoundersTokensWallet;
  }

  function setGrowthTokensWallet(address newGrowthTokensWallet) public onlyOwner { 
    growthTokensWallet = newGrowthTokensWallet;
  }

  function setBountyTokensWallet(address newBountyTokensWallet) public onlyOwner { 
    bountyTokensWallet = newBountyTokensWallet;
  }

  function setAdvisorsTokensWallet(address newAdvisorsTokensWallet) public onlyOwner { 
    advisorsTokensWallet = newAdvisorsTokensWallet;
  }

  function setDevTokensWallet(address newDevTokensWallet) public onlyOwner { 
    devTokensWallet = newDevTokensWallet;
  }

  function setSecurityTokensWallet(address newSecurityTokensWallet) public onlyOwner { 
    securityTokensWallet = newSecurityTokensWallet;
  }

  function setWallet(address newWallet) public onlyOwner { 
    wallet = newWallet;
  }

  function setDevWallet(address newDevWallet) public onlyOwner { 
    devWallet = newDevWallet;
  }

  function setSecurityWallet(address newSecurityWallet) public onlyOwner { 
    securityWallet = newSecurityWallet;
  }

  function setDirectMintAgent(address newDirectMintAgent) public onlyOwner {
    directMintAgent = newDirectMintAgent;
  }

  function directMint(address to, uint investedWei) public onlyDirectMintAgentOrOwner canMint(investedWei) {
    calculateAndTransferTokens(to, investedWei);
  }

  function setStart(uint newStart) public onlyOwner { 
    start = newStart;
  }

  function setToken(address newToken) public onlyOwner { 
    token = TaskFairToken(newToken);
  }

  function mintExtendedTokens() internal {
    uint extendedTokensPercent = bountyTokensPercent.add(devTokensPercent).add(advisorsTokensPercent).add(foundersTokensPercent).add(growthTokensPercent).add(securityTokensPercent);
    uint allTokens = minted.mul(PERCENT_RATE).div(PERCENT_RATE.sub(extendedTokensPercent));

    uint bountyTokens = allTokens.mul(bountyTokensPercent).div(PERCENT_RATE);
    mintAndSendTokens(bountyTokensWallet, bountyTokens);

    uint advisorsTokens = allTokens.mul(advisorsTokensPercent).div(PERCENT_RATE);
    mintAndSendTokens(advisorsTokensWallet, advisorsTokens);

    uint foundersTokens = allTokens.mul(foundersTokensPercent).div(PERCENT_RATE);
    mintAndSendTokens(foundersTokensWallet, foundersTokens);

    uint growthTokens = allTokens.mul(growthTokensPercent).div(PERCENT_RATE);
    mintAndSendTokens(growthTokensWallet, growthTokens);

    uint devTokens = allTokens.mul(devTokensPercent).div(PERCENT_RATE);
    mintAndSendTokens(devTokensWallet, devTokens);

    uint secuirtyTokens = allTokens.mul(securityTokensPercent).div(PERCENT_RATE);
    mintAndSendTokens(securityTokensWallet, secuirtyTokens);
  }

  function mintAndSendTokens(address to, uint amount) internal {
    token.mint(to, amount);
    minted = minted.add(amount);
  }

  function calculateAndTransferTokens(address to, uint investedInWei) internal {
    uint stageIndex = currentStage();
    Stage storage stage = stages[stageIndex];

     
    uint tokens = investedInWei.mul(price).mul(STAGES_PERCENT_RATE).div(STAGES_PERCENT_RATE.sub(stage.discount)).div(1 ether);
    
     
    mintAndSendTokens(to, tokens);

    updateStageWithInvested(stageIndex, investedInWei);
  }

  function createTokens() public payable;

  function() external payable {
    createTokens();
  }

  function retrieveTokens(address anotherToken) public onlyOwner {
    ERC20 alienToken = ERC20(anotherToken);
    alienToken.transfer(wallet, alienToken.balanceOf(this));
  }

}

contract TGE is CommonCrowdsale {
  
  function TGE() public {
    setMinInvestedLimit(100000000000000000);
    setPrice(4000000000000000000000);
    setBountyTokensPercent(50);
    setAdvisorsTokensPercent(20);
    setDevTokensPercent(30);
    setFoundersTokensPercent(50);
    setGrowthTokensPercent(300);
    setSecurityTokensPercent(5);
    setDevPercent(20);
    setSecurityPercent(10);

     
    addStage(7, 2850000000000000000000, 20);
    addStage(7, 5700000000000000000000, 10);
    addStage(7, 18280000000000000000000, 0);
    
    setStart(1514941200);
    setWallet(0x570241a4953c71f92B794F77dd4e7cA295E79bb1);

    setBountyTokensWallet(0xb2C6f32c444C105F168a9Dc9F5cfCCC616041c8a);
    setDevTokensWallet(0xad3Df84A21d508Ad1E782956badeBE8725a9A447);
    setAdvisorsTokensWallet(0x7C737C97004F1C9156faaf2A4D04911e970aC554);
    setFoundersTokensWallet(0xFEED17c1db96B62C18642A675a6561F3A395Bc10);
    setGrowthTokensWallet(0xEc3E7D403E9fD34E83F00182421092d44f9543b2);
    setSecurityTokensWallet(0xa820b6D6434c703B1b406b12d5b82d41F72069b4);

    setDevWallet(0xad3Df84A21d508Ad1E782956badeBE8725a9A447);
    setSecurityWallet(0xA6A9f8b8D063538C84714f91390b48aE58047E31);
  }

  function finishMinting() public onlyOwner {
    mintExtendedTokens();
    token.finishMinting();
  }

  function createTokens() public payable canMint(msg.value) {
    uint devWei = msg.value.mul(devPercent).div(PERCENT_RATE);
    uint securityWei = this.balance.mul(securityPercent).div(PERCENT_RATE);
    devWallet.transfer(devWei);
    securityWallet.transfer(securityWei);
    wallet.transfer(msg.value.sub(devWei).sub(securityWei));
    calculateAndTransferTokens(msg.sender, msg.value);
  } 

}