 

 

pragma solidity 0.4.24;
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
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function Ownable() {
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
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
contract BasicFrozenToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  mapping(address => uint256) unfrozeTimestamp;

  function isUnfrozen(address sender) public constant returns (bool) {
    return true;
  }
  function frozenTimeOf(address _owner) public constant returns (uint256 balance) {
    return unfrozeTimestamp[_owner];
  }
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
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  event NotPausable();

  bool public paused = false;
  bool public canPause = true;

  modifier whenNotPaused() {
    require(!paused || msg.sender == owner);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    require(canPause == true);
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    require(paused == true);
    paused = false;
    emit Unpause();
  }

  function notPausable() onlyOwner public{
    paused = false;
    canPause = false;
    emit NotPausable();
  }
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract StandardToken is ERC20, BasicFrozenToken {
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
}

contract MelecoinToken is StandardToken, Ownable, Pausable {
  string public name = "Melecoin Token";
  string public symbol = "MELC";
  uint public decimals = 18;
   
  uint256 public hardCap = 20000000000;
  
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(_to != address(0));
    require(_amount > 0);
    require(totalSupply + _amount <= hardCap);
    
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);

    uint frozenTime = 0; 

    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract MelecoinTokenCrowdsale is Ownable{
  enum CrowdsaleStage { ICOStage1, ICOStage2, ICOStage3}
  CrowdsaleStage public stage = CrowdsaleStage.ICOStage1;

  using SafeMath for uint256;
  MelecoinToken public token;
  uint256 public startICOTime;
  uint256 public endICOTime;
  uint256 public ICOrate;
  uint256 public ICOBonus;
  uint256 public weiRaised;

  address public wallet;
  address public tokenOwner;  
  
  mapping(address => bool) internal allowedMinters;
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function MelecoinTokenCrowdsale() {
    token = MelecoinToken(0x2bf809305d7d91551a23edc8e5a3a6195caa8bf7);
    tokenOwner = 0xe71CF8F15a36d3De9F16658E6B0c5F56252bA36C;
    wallet = 0x3ab64C27178fCe42Cd5A750CB5Ab370B0aC85fac;

    startICOTime    = 1564617600;
    endICOTime      = 1572566399;
    ICOrate         = 1124;
    ICOBonus        = 0;
  }
  function setRate(uint256 _newrate) public onlyOwner {
    ICOrate=_newrate;
  }
  function getRate() public returns (uint256){
    return ICOrate;
  }
  function setBonus(uint256 _newbonus) public onlyOwner {
    ICOBonus=_newbonus;
  }
  function getBonus() public returns (uint256){
    return ICOBonus;
  }
  function setCrowdsaleStage(uint _stage) public onlyOwner {
    if(uint(CrowdsaleStage.ICOStage1) == _stage) {
      stage = CrowdsaleStage.ICOStage1;
    } else if (uint(CrowdsaleStage.ICOStage2) == _stage) {
      stage = CrowdsaleStage.ICOStage2;
    } else if (uint(CrowdsaleStage.ICOStage3) == _stage) {
      stage = CrowdsaleStage.ICOStage3;
    }
  }
  function getsetCrowdsaleStage() public returns (uint){
    return uint(stage);
  }  
  
  function () payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());
    
    uint256 weiAmount = msg.value;

    uint256 tokens;
    weiRaised = weiRaised.add(weiAmount);
    tokens = weiAmount * ICOrate;
    uint256 bonus=0;
    
    bonus= tokens * ICOBonus / 100;
    
    tokens = tokens + bonus;
    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  function validPurchase() internal constant returns (bool) {
    if(now < endICOTime) {
      return true;
    } else return false;
  }

  function hasEnded() public constant returns (bool) {
    if(now >= endICOTime) return true;
    else return false;
  }

  function returnTokenOwnership() public {
    require(msg.sender == tokenOwner);
    token.transferOwnership(tokenOwner);
  }

  function addMinter(address addr) {
    require(msg.sender == tokenOwner);
    allowedMinters[addr] = true;
  }
  function removeMinter(address addr) {
    require(msg.sender == tokenOwner);
    allowedMinters[addr] = false;
  }
}