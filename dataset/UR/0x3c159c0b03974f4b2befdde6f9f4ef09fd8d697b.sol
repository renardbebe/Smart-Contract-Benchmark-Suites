 

pragma solidity ^0.4.18;

 
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

   
  bool public transferPaused;
  address public crowdsale;
  
  function Pausable() public {
    transferPaused = false;
    crowdsale = msg.sender;  
  }

   
  modifier onlyCrowdsaleIfPaused() {
    if (transferPaused) {
      require(msg.sender == crowdsale);
    }
    _;
  }

   
   
  function changeCrowdsale(address newCrowdsale) onlyOwner public {
    require(newCrowdsale != address(0));
    CrowdsaleChanged(crowdsale, newCrowdsale);
    crowdsale = newCrowdsale;
  }

    
  function pause() public onlyOwner {
      transferPaused = true;
      Pause();
  }

   
  function unpause() public onlyOwner {
      transferPaused = false;
      Unpause();
  }

  event Pause();
  event Unpause();
  event CrowdsaleChanged(address indexed previousCrowdsale, address indexed newCrowdsale);

}

 
 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public returns (bool);
  function approve(address spender, uint value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract ExtendedToken is ERC20, Pausable {
  using SafeMath for uint;

   
  mapping (address => uint) public balances;
   
  mapping (address => mapping (address => uint)) internal allowed;

   
   
   
  function burn(uint _amount) public onlyOwner returns (bool) {
	  require(balances[msg.sender] >= _amount);     
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    totalSupply = totalSupply.sub(_amount);
    Burn(msg.sender, _amount);
    return true;
  }

   
  function _transfer(address _from, address _to, uint _value) internal onlyCrowdsaleIfPaused {
    require(_to != address(0));
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(_from, _to, _value);
  }
  
   
   
   
   
  function transfer(address _to, uint _value) public returns (bool) {
    _transfer(msg.sender, _to, _value);
    return true;
  }
  
  function transferFrom(address _from, address _to, uint _value) public returns (bool) {
    require(_value <= allowed[_from][msg.sender]);
    _transfer(_from, _to, _value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    return true;
  }

   
   
   
  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
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

   
   
  function claimTokens(address _token) public onlyOwner {
    if (_token == address(0)) {
         owner.transfer(this.balance);
         return;
    }

    ERC20 token = ERC20(_token);
    uint balance = token.balanceOf(this);
    token.transfer(owner, balance);
    ClaimedTokens(_token, owner, balance);
  }

   
  event Burn(address _from, uint _amount);
  event ClaimedTokens(address indexed _token, address indexed _owner, uint _amount);

}

 
contract CulturalCoinToken is ExtendedToken {
  string public constant name = "Cultural Coin Token";
  string public constant symbol = "CC";
  uint8 public constant decimals = 18;
  string public constant version = "v1";

  function CulturalCoinToken() public { 
    totalSupply = 1500 * 10**24;     
    balances[owner] = totalSupply;   
  }

}