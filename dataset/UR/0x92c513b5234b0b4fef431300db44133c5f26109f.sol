 

pragma solidity ^0.4.16;

 
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

  mapping (address => mapping (address => uint256)) allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract Ownable {

  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
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

   
  function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

}

contract DbiCapitalToken is MintableToken {

  string public constant name = "DBI Capital Token";

  string public constant symbol = "DBI";

  uint32 public constant decimals = 18;

}

contract Crowdsale is Ownable {

  using SafeMath for uint;

  address multisig;  
  address bounty;    
  uint bountyCount = 1000000000000000000000;  

  DbiCapitalToken public token = new DbiCapitalToken();

  uint startDate = 0;  
  uint endDate = 0;    
  uint hardcap = 0;    
  uint rate = 0;       

  uint tokensSold = 0;
  uint etherReceived = 0;

  uint hardcapStage1 = 2000 ether;   
  uint hardcapStage2 = 20000 ether;  
  uint hardcapStage3 = 150000 ether;  

  uint rateStage1 = 100;  
  uint rateStage2 = 70;   
  uint rateStage3 = 50;   

  uint crowdsaleStage = 0;
  bool crowdsaleStarted = false;
  bool crowdsaleFinished = false;

  event CrowdsaleStageStarted(uint stage, uint startDate, uint endDate, uint rate, uint hardcap);
  event CrowdsaleFinished(uint tokensSold, uint etherReceived);
  event TokenSold(uint tokens, uint ethFromTokens, uint rate, uint hardcap);
  event HardcapGoalReached(uint tokensSold, uint etherReceived, uint hardcap, uint stage);


  function Crowdsale() public {
    multisig = 0x70C39CC41a3852e20a8B1a59A728305758e3aa37;
    bounty = 0x11404c733254d66612765B5A94fB4b1f0937639c;
    token.mint(bounty, bountyCount);
  }

  modifier saleIsOn() {
    require(now >= startDate && now <= endDate && crowdsaleStarted && !crowdsaleFinished && crowdsaleStage > 0 && crowdsaleStage <= 3);
    _;
  }

  modifier isUnderHardCap() {
    require(etherReceived <= hardcap);
    _;
  }

  function nextStage(uint _startDate, uint _endDate) public onlyOwner {
    crowdsaleStarted = true;
    crowdsaleStage += 1;
    startDate = _startDate;
    endDate = _endDate;
    if (crowdsaleStage == 1) {
      rate = rateStage1;
      hardcap = hardcapStage1;
      CrowdsaleStageStarted(crowdsaleStage, startDate, endDate, rate, hardcap);
    } else if (crowdsaleStage == 2) {
      rate = rateStage2;
      hardcap = hardcapStage2;
      CrowdsaleStageStarted(crowdsaleStage, startDate, endDate, rate, hardcap);
    } else if (crowdsaleStage == 3) {
      rate = rateStage3;
      hardcap = hardcapStage3;
      CrowdsaleStageStarted(crowdsaleStage, startDate, endDate, rate, hardcap);
    } else {
      finishMinting();
    }
  }

  function finishMinting() public onlyOwner {
    crowdsaleFinished = true;
    token.finishMinting();
    CrowdsaleFinished(tokensSold, etherReceived);
  }

  function createTokens() public isUnderHardCap saleIsOn payable {
    multisig.transfer(msg.value);
    uint tokens = rate.mul(msg.value);
    tokensSold += tokens;
    etherReceived += msg.value;
    TokenSold(tokens, msg.value, rate, hardcap);
    token.mint(msg.sender, tokens);
    if (etherReceived >= hardcap) {
      HardcapGoalReached(tokensSold, etherReceived, hardcap, crowdsaleStage);
    }
  }

  function() external payable {
    createTokens();
  }

  function getTokensSold() public view returns (uint) {
    return tokensSold;
  }

  function getEtherReceived() public view returns (uint) {
    return etherReceived;
  }

  function getCurrentHardcap() public view returns (uint) {
    return hardcap;
  }

  function getCurrentRate() public view returns (uint) {
    return rate;
  }

  function getStartDate() public view returns (uint) {
    return startDate;
  }

  function getEndDate() public view returns (uint) {
    return endDate;
  }

  function getStage() public view returns (uint) {
    return crowdsaleStage;
  }

  function isStarted() public view returns (bool) {
    return crowdsaleStarted;
  }

  function isFinished() public view returns (bool) {
    return crowdsaleFinished;
  }

}