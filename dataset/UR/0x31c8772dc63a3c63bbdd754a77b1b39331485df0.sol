 

pragma solidity ^0.4.16;


 
contract Ownable {
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}


 
library SafeMath {
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

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
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


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}


 

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    super.transferFrom(_from, _to, _value);
  }
}


 
contract HeroOrigenToken is PausableToken, MintableToken {
  using SafeMath for uint256;

  string public constant name = "Hero Origen Token";
  string public constant symbol = "HERO";
  uint8 public constant decimals = 18;
}


 
contract MainSale is Ownable {
  using SafeMath for uint256;
  event TokensPurchased(address indexed buyer, uint256 ether_amount);
  event MainSaleClosed();

  HeroOrigenToken public token = new HeroOrigenToken();

  address public multisigVault = 0x1706024467ef8C9C4648Da6FC35f2C995Ac79CF6;

  uint256 public totalReceived = 0;
  uint256 public hardcap = 250000 ether;
  uint256 public minimum = 10 ether;

  uint256 public altDeposits = 0;
  uint256 public start = 1511178900;  
  bool public saleOngoing = true;

   
  modifier isSaleOn() {
    require(start <= now && saleOngoing);
    _;
  }

   
  modifier isAtLeastMinimum() {
    require(msg.value >= minimum);
    _;
  }

   
  modifier isUnderHardcap() {
    require(totalReceived + altDeposits <= hardcap);
    _;
  }

  function MainSale() public {
    token.pause();
  }

   
  function acceptPayment(address sender) public isAtLeastMinimum isUnderHardcap isSaleOn payable {
    totalReceived = totalReceived.add(msg.value);
    multisigVault.transfer(this.balance);
    TokensPurchased(sender, msg.value);
  }

   
  function setStart(uint256 _start) external onlyOwner {
    start = _start;
  }

   
  function setMinimum(uint256 _minimum) external onlyOwner {
    minimum = _minimum;
  }

   
  function setHardcap(uint256 _hardcap) external onlyOwner {
    hardcap = _hardcap;
  }

   
  function setAltDeposits(uint256 totalAltDeposits) external onlyOwner {
    altDeposits = totalAltDeposits;
  }

   
  function setMultisigVault(address _multisigVault) external onlyOwner {
    require(_multisigVault != address(0));
    multisigVault = _multisigVault;
  }

   
  function setSaleOngoing(bool _saleOngoing) external onlyOwner {
    saleOngoing = _saleOngoing;
  }

   
  function closeSale() external onlyOwner {
    token.transferOwnership(owner);
    MainSaleClosed();
  }

   
  function retrieveTokens(address _token) external onlyOwner {
    ERC20 foreignToken = ERC20(_token);
    foreignToken.transfer(multisigVault, foreignToken.balanceOf(this));
  }

   
  function() external payable {
    acceptPayment(msg.sender);
  }
}