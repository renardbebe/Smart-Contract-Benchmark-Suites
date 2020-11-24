 

pragma solidity ^0.4.17;


 
contract Ownable {
  address public owner;
   
  function Ownable() public {
    owner = msg.sender;
  }
   
  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }
   
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  bool public paused = false;
   
  modifier whenNotPaused() {
    require (!paused);
    _;
  }
   
  modifier whenPaused {
    require (paused);
    _;
  }
   
  function pause() onlyOwner whenNotPaused  public returns (bool) {
    paused = true;
    Pause();
    return true;
  }
   
  function unpause() onlyOwner whenPaused public returns (bool) {
    paused = false;
    Unpause();
    return true;
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

   
  function transfer(address _to, uint256 _value) public returns (bool){
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


 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(_who, _value);
    Transfer(_who, address(0), _value);
  }
}

 
contract MintableToken is StandardToken, Ownable {

  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  uint256 public oneCoin = 10 ** 18;
  uint256 public maxTokens = 2000 * (10**6) * oneCoin;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {

    require(totalSupply.add(_amount) <= maxTokens); 


    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Transfer(0X0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 
 
 

contract IrisToken is MintableToken, BurnableToken, Pausable {
   
  string public name = "IRIS";
  string public symbol = "IRIS";
  uint256 public decimals = 18;

   
  bool public tradingStarted = false;

   
  modifier hasStartedTrading() {
    require(tradingStarted);
    _;
  }

   
  function startTrading() public onlyOwner {
    tradingStarted = true;
  }

   
  function transfer(address _to, uint _value) hasStartedTrading whenNotPaused public returns (bool) {
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint _value) hasStartedTrading whenNotPaused public returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function emergencyERC20Drain( ERC20 oddToken, uint amount ) public {
    oddToken.transfer(owner, amount);
  }
}

contract IrisTokenPrivatSale is Ownable, Pausable{

  using SafeMath for uint256;

   
  IrisToken public token;
 

  uint256 public decimals = 18;  

  uint256 public oneCoin = 10**decimals;

  address public multiSig; 

   
   
  uint256 public weiRaised;

   
  uint256 public tokenRaised;
  
   
  uint256 public numberOfPurchasers = 0;

  event HostEther(address indexed buyer, uint256 value);
  event TokenPlaced(address indexed beneficiary, uint256 amount); 
  event SetWallet(address _newWallet);
  event SendedEtherToMultiSig(address walletaddress, uint256 amountofether);

  function setWallet(address _newWallet) public onlyOwner {
    multiSig = _newWallet;
    SetWallet(_newWallet);
}
  function IrisTokenPrivatSale() public {
      


 

    multiSig = 0x02cb1ADc98e984A67a3d892Dbb7eD72b36dA7b07;  

 

    token = new IrisToken();
   
}
  

  function placeTokens(address beneficiary, uint256 _tokens) onlyOwner public {
    
    require(_tokens != 0);
    require (beneficiary != 0x0);
    
     

    if (token.balanceOf(beneficiary) == 0) {
      numberOfPurchasers++;
    }
    tokenRaised = tokenRaised.add(_tokens);  
    token.mint(beneficiary, _tokens);
    TokenPlaced(beneficiary, _tokens); 
  }

   
  function buyTokens(address buyer, uint256 amount) whenNotPaused internal {
    
    require (multiSig != 0x0);
    require (msg.value > 1 finney);
     
    weiRaised = weiRaised.add(amount);
   
    HostEther(buyer, amount);
     
    multiSig.transfer(this.balance);      
    SendedEtherToMultiSig(multiSig,amount);
  }

   
  function transferTokenContractOwnership(address _address) public onlyOwner {
   
    token.transferOwnership(_address);
   
  }

   
  function () public payable {
    buyTokens(msg.sender, msg.value);
  }

  function emergencyERC20Drain( ERC20 oddToken, uint amount ) public onlyOwner{
    oddToken.transfer(owner, amount);
  }
}