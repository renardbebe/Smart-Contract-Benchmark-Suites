 

pragma solidity ^0.4.15;

 
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

  address public saleAgent;

  function setSaleAgent(address newSaleAgnet) {
    require(msg.sender == saleAgent || msg.sender == owner);
    saleAgent = newSaleAgnet;
  }

  function mint(address _to, uint256 _amount) returns (bool) {
    require(msg.sender == saleAgent && !mintingFinished);
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() returns (bool) {
    require((msg.sender == saleAgent || msg.sender == owner) && !mintingFinished);
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

contract QBEToken is MintableToken {	
    
  string public constant name = "Qubicle";
   
  string public constant symbol = "QBE";
    
  uint32 public constant decimals = 18;

  mapping (address => uint) public locked;

  function transfer(address _to, uint256 _value) returns (bool) {
    require(locked[msg.sender] < now);
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(locked[_from] < now);
    return super.transferFrom(_from, _to, _value);
  }
  
  function lock(address addr, uint periodInDays) {
    require(locked[addr] < now && (msg.sender == saleAgent || msg.sender == addr));
    locked[addr] = now + periodInDays * 1 days;
  }

  function () payable {
    revert();
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

  Stage[] public stages;

  function stagesCount() public constant returns(uint) {
    return stages.length;
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

  modifier saleIsOn() {
    require(stages.length > 0 && now >= start && now < lastSaleDate());
    _;
  }
  
  modifier isUnderHardcap() {
    require(totalInvested <= totalHardcap);
    _;
  }

  function currentStage() public saleIsOn isUnderHardcap constant returns(uint) {
    for (uint i = 0; i < stages.length; i++) {
      if (stages[i].closed == 0) {
        return i;
      }
    }
    revert();
  }

}

contract CommonSale is StagedCrowdsale {

  address public multisigWallet;

  uint public minPrice;

  uint public totalTokensMinted;

  QBEToken public token;
  
  function setMinPrice(uint newMinPrice) public onlyOwner {
    minPrice = newMinPrice;
  }

  function setMultisigWallet(address newMultisigWallet) public onlyOwner {
    multisigWallet = newMultisigWallet;
  }
  
  function setToken(address newToken) public onlyOwner {
    token = QBEToken(newToken);
  }

  function createTokens() public whenNotPaused payable {
    require(msg.value >= minPrice);
    uint stageIndex = currentStage();  
    multisigWallet.transfer(msg.value);
    Stage storage stage = stages[stageIndex];
    uint tokens = msg.value.mul(stage.price);
    token.mint(this, tokens);
    token.transfer(msg.sender, tokens);
    totalTokensMinted = totalTokensMinted.add(tokens);
    totalInvested = totalInvested.add(msg.value);
    stage.invested = stage.invested.add(msg.value);
    if (stage.invested >= stage.hardcap) {
      stage.closed = now;
    }
  }

  function() external payable {
    createTokens();
  }

  function retrieveTokens(address anotherToken) public onlyOwner {
    ERC20 alienToken = ERC20(anotherToken);
    alienToken.transfer(multisigWallet, token.balanceOf(this));
  }

}

contract Presale is CommonSale {

  Mainsale public mainsale;

  function setMainsale(address newMainsale) public onlyOwner {
    mainsale = Mainsale(newMainsale);
  }

  function setMultisigWallet(address newMultisigWallet) public onlyOwner {
    multisigWallet = newMultisigWallet;
  }

  function finishMinting() public whenNotPaused onlyOwner {
    token.setSaleAgent(mainsale);
  }

  function() external payable {
    createTokens();
  }

  function retrieveTokens(address anotherToken) public onlyOwner {
    ERC20 alienToken = ERC20(anotherToken);
    alienToken.transfer(multisigWallet, token.balanceOf(this));
  }

}


contract Mainsale is CommonSale {

  address public foundersTokensWallet;
  
  address public bountyTokensWallet;

  address public unsoldTokensWallet;
  
  uint public foundersTokensReserve;
  
  uint public bountyTokensReserve;

  uint public maxTokenSupply;
  
  uint public lockPeriod;

  function setLockPeriod(uint newLockPeriod) public onlyOwner {
    lockPeriod = newLockPeriod;
  }

  function setFoundersTokensReserve(uint newFoundersTokensReserve) public onlyOwner {
    foundersTokensReserve = newFoundersTokensReserve;
  }

  function setBountyTokensReserve(uint newBountyTokensReserve) public onlyOwner {
    bountyTokensReserve = newBountyTokensReserve;
  }

  function setMaxTokenSupply(uint newMaxTokenSupply) public onlyOwner {
    maxTokenSupply = newMaxTokenSupply;
  }

  function setFoundersTokensWallet(address newFoundersTokensWallet) public onlyOwner {
    foundersTokensWallet = newFoundersTokensWallet;
  }

  function setBountyTokensWallet(address newBountyTokensWallet) public onlyOwner {
    bountyTokensWallet = newBountyTokensWallet;
  }

  function setUnsoldTokensWallet(address newUnsoldTokensWallet) public onlyOwner {
    unsoldTokensWallet = newUnsoldTokensWallet;
  }
  
  function finishMinting() public whenNotPaused onlyOwner {
    token.mint(this, foundersTokensReserve);
    token.lock(foundersTokensWallet, lockPeriod * 1 days);
    token.transfer(foundersTokensWallet, foundersTokensReserve);
    token.mint(this, bountyTokensReserve);
    token.transfer(bountyTokensWallet, bountyTokensReserve);
    totalTokensMinted = totalTokensMinted.add(foundersTokensReserve).add(bountyTokensReserve);

    uint totalUnsoldTokens = maxTokenSupply.sub(totalTokensMinted);
    if (totalUnsoldTokens > 0){
      token.mint(this, totalUnsoldTokens);
      token.transfer(unsoldTokensWallet, totalUnsoldTokens);
    }
    
    token.finishMinting();
  }

}

contract TestConfigurator is Ownable {

  QBEToken public token; 

  Presale public presale;

  Mainsale public mainsale;

  function deploy() public onlyOwner {
    token = new QBEToken();

    presale = new Presale();

    presale.setToken(token);
    presale.addStage(10,3000);
    presale.setMultisigWallet(0x4c076e99d9E8cFC647E1807D89506189d4256Ee1);
    presale.setStart(1509393730);
    presale.setPeriod(1);
    presale.setMinPrice(100000000000000000);
    token.setSaleAgent(presale);	

    mainsale = new Mainsale();

    mainsale.setToken(token);
    mainsale.addStage(100,1500);
    mainsale.setMultisigWallet(0xf32737F7779cA2D20c017Da8F51b2DF99F86A221);
    mainsale.setFoundersTokensWallet(0x5b819179C8Ba84FB4a517Dd566cb09Ff4b8a277f);
    mainsale.setBountyTokensWallet(0x7D2b00C23aDab97152aaB6588A50FcEdCEbD58e4);
    mainsale.setUnsoldTokensWallet(0xAE5e64280eD777c6D2bb8EddfeF2394A21f147DD);
    mainsale.setStart(1509393800);
    mainsale.setPeriod(1);
    mainsale.setLockPeriod(1);
    mainsale.setMinPrice(100000000000000000);
    mainsale.setFoundersTokensReserve(20 * (10**6) * 10**18);
    mainsale.setBountyTokensReserve(10 * (10**6) * 10**18);
    mainsale.setMaxTokenSupply(100 * (10**6) * 10**18);

    presale.setMainsale(mainsale);

    token.transferOwnership(owner);
    presale.transferOwnership(owner);
    mainsale.transferOwnership(owner);
  }

}

contract Configurator is Ownable {

  QBEToken public token; 

  Presale public presale;

  Mainsale public mainsale;

  function deploy() public onlyOwner {
    token = new QBEToken();

    presale = new Presale();

    presale.setToken(token);
    presale.addStage(6000,3000);
    presale.setMultisigWallet(0x17FB4A3ff095F445287AA6F3Ab699a3DCaE3DC56);
    presale.setStart(1510128000);
    presale.setPeriod(31);
    presale.setMinPrice(100000000000000000);
    token.setSaleAgent(presale);	

    mainsale = new Mainsale();

    mainsale.setToken(token);
    mainsale.addStage(45000,1500);
    mainsale.setMultisigWallet(0xdfF07F415E00a338205A8E21C39eC007eb37F746);
    mainsale.setFoundersTokensWallet(0x7bfC9AdaF3D07adC4a1d3D03cde6581100845540);
    mainsale.setBountyTokensWallet(0xce8d83BA3cDD4E7447339936643861478F8037AD);
    mainsale.setUnsoldTokensWallet(0xd88a0920Dc4A044A95874f4Bd4858Fb013511290);
    mainsale.setStart(1514764800);
    mainsale.setPeriod(60);
    mainsale.setLockPeriod(90);
    mainsale.setMinPrice(100000000000000000);
    mainsale.setFoundersTokensReserve(20 * (10**6) * 10**18);
    mainsale.setBountyTokensReserve(10 * (10**6) * 10**18);
    mainsale.setMaxTokenSupply(100 * (10**6) * 10**18);

    presale.setMainsale(mainsale);

    token.transferOwnership(owner);
    presale.transferOwnership(owner);
    mainsale.transferOwnership(owner);
  }
}