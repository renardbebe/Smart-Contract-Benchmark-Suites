 

pragma solidity ^0.4.18;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
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

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
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

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function () public payable {
    revert();
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

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract MintableToken is StandardToken, Ownable {
    
  event Mint(address indexed to, uint256 amount);
  
  event MintFinished();

  event SaleAgentUpdated(address currentSaleAgent);

  bool public mintingFinished = false;

  address public saleAgent;

  modifier notLocked() {
    require(msg.sender == owner || msg.sender == saleAgent || mintingFinished);
    _;
  }

  function setSaleAgent(address newSaleAgnet) public {
    require(msg.sender == saleAgent || msg.sender == owner);
    saleAgent = newSaleAgnet;
    SaleAgentUpdated(saleAgent);
  }

  function mint(address _to, uint256 _amount) public returns (bool) {
    require(msg.sender == saleAgent && !mintingFinished);
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() public returns (bool) {
    require((msg.sender == saleAgent || msg.sender == owner) && !mintingFinished);
    mintingFinished = true;
    MintFinished();
    return true;
  }

  function transfer(address _to, uint256 _value) public notLocked returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address from, address to, uint256 value) public notLocked returns (bool) {
    return super.transferFrom(from, to, value);
  }
  
}

contract StagedCrowdsale is Pausable {

  using SafeMath for uint;

   
  struct Stage {
    uint hardcap;
    uint price;
    uint invested;
    uint closed;
  }

   
  uint public start;

   
  uint public period;

   
  uint public totalHardcap;
 
   
  uint public totalInvested;

   
  uint public softcap;

   
  Stage[] public stages;

  event MilestoneAdded(uint hardcap, uint price);

  modifier saleIsOn() {
    require(stages.length > 0 && now >= start && now < lastSaleDate());
    _;
  }

  modifier saleIsFinished() {
    require(totalInvested >= softcap || now > lastSaleDate());
    _;
  }
  
  modifier isUnderHardcap() {
    require(totalInvested <= totalHardcap);
    _;
  }

  modifier saleIsUnsuccessful() {
    require(totalInvested < softcap || now > lastSaleDate());
    _;
  }

   
  function stagesCount() public constant returns(uint) {
    return stages.length;
  }

   
  function setSoftcap(uint newSoftcap) public onlyOwner {
    require(newSoftcap > 0);
    softcap = newSoftcap.mul(1 ether);
  }

   
  function setStart(uint newStart) public onlyOwner {
    start = newStart;
  }

   
  function setPeriod(uint newPeriod) public onlyOwner {
    period = newPeriod;
  }

   
  function addStage(uint hardcap, uint price) public onlyOwner {
    require(hardcap > 0 && price > 0);
    Stage memory stage = Stage(hardcap.mul(1 ether), price, 0, 0);
    stages.push(stage);
    totalHardcap = totalHardcap.add(stage.hardcap);
    MilestoneAdded(hardcap, price);
  }

   
  function removeStage(uint8 number) public onlyOwner {
    require(number >= 0 && number < stages.length);
    Stage storage stage = stages[number];
    totalHardcap = totalHardcap.sub(stage.hardcap);    
    delete stages[number];
    for (uint i = number; i < stages.length - 1; i++) {
      stages[i] = stages[i+1];
    }
    stages.length--;
  }

   
  function changeStage(uint8 number, uint hardcap, uint price) public onlyOwner {
    require(number >= 0 && number < stages.length);
    Stage storage stage = stages[number];
    totalHardcap = totalHardcap.sub(stage.hardcap);    
    stage.hardcap = hardcap.mul(1 ether);
    stage.price = price;
    totalHardcap = totalHardcap.add(stage.hardcap);    
  }

   
  function insertStage(uint8 numberAfter, uint hardcap, uint price) public onlyOwner {
    require(numberAfter < stages.length);
    Stage memory stage = Stage(hardcap.mul(1 ether), price, 0, 0);
    totalHardcap = totalHardcap.add(stage.hardcap);
    stages.length++;
    for (uint i = stages.length - 2; i > numberAfter; i--) {
      stages[i + 1] = stages[i];
    }
    stages[numberAfter + 1] = stage;
  }

   
  function clearStages() public onlyOwner {
    for (uint i = 0; i < stages.length; i++) {
      delete stages[i];
    }
    stages.length -= stages.length;
    totalHardcap = 0;
  }

   
  function lastSaleDate() public constant returns(uint) {
    return start + period * 1 days;
  }  

   
  function currentStage() public saleIsOn isUnderHardcap constant returns(uint) {
    for(uint i = 0; i < stages.length; i++) {
      if(stages[i].closed == 0) {
        return i;
      }
    }
    revert();
  }

}

contract CommonSale is StagedCrowdsale {

   
  MYTCToken public token;  

   
  uint public slaveWalletPercent = 50;

   
  uint public percentRate = 100;

   
  uint public minInvestment;
  
   
  bool public slaveWalletInitialized;

   
  bool public slaveWalletPercentInitialized;

   
  address public masterWallet;

   
  address public slaveWallet;
  
   
  address public directMintAgent;

   
  mapping (address => uint256) public investedAmountOf;

   
  mapping (address => uint256) public tokenAmountOf;

   
  mapping (uint => address) public contributors;

   
  uint public uniqueContributors;  

   
  event TokenPurchased(address indexed purchaser, uint256 value, uint256 purchaseDate);

   
  event TokenMinted(address to, uint tokens, uint256 mintedDate);

   
  event InvestmentReturned(address indexed investor, uint256 amount, uint256 returnDate);
  
  modifier onlyDirectMintAgentOrOwner() {
    require(directMintAgent == msg.sender || owner == msg.sender);
    _;
  }  

   
  function setToken(address newToken) public onlyOwner {
    token = MYTCToken(newToken);
  }

   
  function setMinInvestment(uint newMinInvestment) public onlyOwner {
    minInvestment = newMinInvestment;
  }  

   
  function setMasterWallet(address newMasterWallet) public onlyOwner {
    masterWallet = newMasterWallet;
  }

   
  function setSlaveWallet(address newSlaveWallet) public onlyOwner {
    require(!slaveWalletInitialized);
    slaveWallet = newSlaveWallet;
    slaveWalletInitialized = true;
  }

   
  function setSlaveWalletPercent(uint newSlaveWalletPercent) public onlyOwner {
    require(!slaveWalletPercentInitialized);
    slaveWalletPercent = newSlaveWalletPercent;
    slaveWalletPercentInitialized = true;
  }

   
  function setDirectMintAgent(address newDirectMintAgent) public onlyOwner {
    directMintAgent = newDirectMintAgent;
  }  

   
  function directMint(address to, uint investedWei) public onlyDirectMintAgentOrOwner saleIsOn {
    calculateAndMintTokens(to, investedWei);
    TokenPurchased(to, investedWei, now);
  }

   
  function createTokens() public whenNotPaused payable {
    require(msg.value >= minInvestment);
    uint masterValue = msg.value.mul(percentRate.sub(slaveWalletPercent)).div(percentRate);
    uint slaveValue = msg.value.sub(masterValue);
    masterWallet.transfer(masterValue);
    slaveWallet.transfer(slaveValue);
    calculateAndMintTokens(msg.sender, msg.value);
    TokenPurchased(msg.sender, msg.value, now);
  }

   
  function calculateAndMintTokens(address to, uint weiInvested) internal {
     
    uint stageIndex = currentStage();
    Stage storage stage = stages[stageIndex];
    uint tokens = weiInvested.mul(stage.price);
     
    if(investedAmountOf[msg.sender] == 0) {
        contributors[uniqueContributors] = msg.sender;
        uniqueContributors += 1;
    }
     
    investedAmountOf[msg.sender] = investedAmountOf[msg.sender].add(weiInvested);
    tokenAmountOf[msg.sender] = tokenAmountOf[msg.sender].add(tokens);
     
    mintTokens(to, tokens);
    totalInvested = totalInvested.add(weiInvested);
    stage.invested = stage.invested.add(weiInvested);
     
    if(stage.invested >= stage.hardcap) {
      stage.closed = now;
    }
  }

   
  function mintTokens(address to, uint tokens) internal {
    token.mint(this, tokens);
    token.transfer(to, tokens);
    TokenMinted(to, tokens, now);
  }

   
  function() external payable {
    createTokens();
  }
  
   
  function retrieveExternalTokens(address anotherToken, address to) public onlyOwner {
    ERC20 alienToken = ERC20(anotherToken);
    alienToken.transfer(to, alienToken.balanceOf(this));
  }

   
  function refund() public saleIsUnsuccessful {
    uint value = investedAmountOf[msg.sender];
    investedAmountOf[msg.sender] = 0;
    msg.sender.transfer(value);
    InvestmentReturned(msg.sender, value, now);
  }

}

contract WhiteListToken is CommonSale {

  mapping(address => bool)  public whiteList;

  modifier onlyIfWhitelisted() {
    require(whiteList[msg.sender]);
    _;
  }

  function addToWhiteList(address _address) public onlyDirectMintAgentOrOwner {
    whiteList[_address] = true;
  }

  function addAddressesToWhitelist(address[] _addresses) public onlyDirectMintAgentOrOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      addToWhiteList(_addresses[i]);
    }
  }

  function deleteFromWhiteList(address _address) public onlyDirectMintAgentOrOwner {
    whiteList[_address] = false;
  }

  function deleteAddressesFromWhitelist(address[] _addresses) public onlyDirectMintAgentOrOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      deleteFromWhiteList(_addresses[i]);
    }
  }

}

contract MYTCToken is MintableToken {	
    
   
  string public constant name = "MYTC";
   
   
  string public constant symbol = "MYTC";
    
   
  uint32 public constant decimals = 18;

   
  mapping (address => uint) public locked;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(locked[msg.sender] < now);
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(locked[_from] < now);
    return super.transferFrom(_from, _to, _value);
  }
  
   
  function lock(address addr, uint periodInDays) public {
    require(locked[addr] < now && (msg.sender == saleAgent || msg.sender == addr));
    locked[addr] = now + periodInDays * 1 days;
  }

}

contract PreTge is CommonSale {

   
  Tge public tge;

   
  event PreTgeFinalized(address indexed finalizer, uint256 saleEnded);

   
  function setMainsale(address newMainsale) public onlyOwner {
    tge = Tge(newMainsale);
  }

   
  function setTgeAsSaleAgent() public whenNotPaused saleIsFinished onlyOwner {
    token.setSaleAgent(tge);
    PreTgeFinalized(msg.sender, now);
  }
}


contract Tge is WhiteListToken {

   
  address public teamTokensWallet;
  
   
  address public bountyTokensWallet;

   
  address public reservedTokensWallet;
  
   
  uint public teamTokensPercent;
  
   
  uint public bountyTokensPercent;

   
  uint public reservedTokensPercent;
  
   
  uint public lockPeriod;  

   
  uint public totalTokenSupply;

   
  event TgeFinalized(address indexed finalizer, uint256 saleEnded);

   
  function setLockPeriod(uint newLockPeriod) public onlyOwner {
    lockPeriod = newLockPeriod;
  }

   
  function setTeamTokensPercent(uint newTeamTokensPercent) public onlyOwner {
    teamTokensPercent = newTeamTokensPercent;
  }

   
  function setBountyTokensPercent(uint newBountyTokensPercent) public onlyOwner {
    bountyTokensPercent = newBountyTokensPercent;
  }

   
  function setReservedTokensPercent(uint newReservedTokensPercent) public onlyOwner {
    reservedTokensPercent = newReservedTokensPercent;
  }
  
   
  function setTotalTokenSupply(uint newTotalTokenSupply) public onlyOwner {
    totalTokenSupply = newTotalTokenSupply;
  }

   
  function setTeamTokensWallet(address newTeamTokensWallet) public onlyOwner {
    teamTokensWallet = newTeamTokensWallet;
  }

   
  function setBountyTokensWallet(address newBountyTokensWallet) public onlyOwner {
    bountyTokensWallet = newBountyTokensWallet;
  }

   
  function setReservedTokensWallet(address newReservedTokensWallet) public onlyOwner {
    reservedTokensWallet = newReservedTokensWallet;
  }

   
  function endSale() public whenNotPaused saleIsFinished onlyOwner {    
     
     

    uint foundersTokens = totalTokenSupply.mul(teamTokensPercent).div(percentRate);
    uint reservedTokens = totalTokenSupply.mul(reservedTokensPercent).div(percentRate);
    uint bountyTokens = totalTokenSupply.mul(bountyTokensPercent).div(percentRate); 
    mintTokens(reservedTokensWallet, reservedTokens);
    mintTokens(teamTokensWallet, foundersTokens);
    mintTokens(bountyTokensWallet, bountyTokens); 
    uint currentSupply = token.totalSupply();
    if (currentSupply < totalTokenSupply) {
       
      mintTokens(reservedTokensWallet, totalTokenSupply.sub(currentSupply));
    }  
    token.lock(teamTokensWallet, lockPeriod);      
    token.finishMinting();
    TgeFinalized(msg.sender, now);
  }

     
  function() external onlyIfWhitelisted payable {
    require(now >= start && now < lastSaleDate());
    createTokens();
  }
}