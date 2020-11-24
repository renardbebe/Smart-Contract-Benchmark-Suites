 

 

 

pragma solidity ^0.4.18;

 

 
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

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public  returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}



contract BurnableToken is StandardToken {

  address public constant BURN_ADDRESS = 0;

   
  event Burned(address burner, uint burnedAmount);

   
  function burn(uint burnAmount) public {
    address burner = msg.sender;
    balances[burner] = SafeMath.sub(balances[burner], burnAmount);
    totalSupply = SafeMath.sub(totalSupply, burnAmount);
    Burned(burner, burnAmount);
  }
}
 







 
contract ReleasableToken is ERC20, Ownable {

   
  address public releaseAgent;

   
  bool public released = false;

   
  mapping (address => bool) public transferAgents;

  event CanTransferChecked(bool canTransfer, address indexed from, bool isTransferAgent, bool isReleased);

   
  modifier canTransfer(address _sender) {
    CanTransferChecked(released || transferAgents[_sender], _sender, transferAgents[_sender], released);
    if (released || transferAgents[_sender]) {revert();}
    _;
  }

   
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

     
    releaseAgent = addr;
  }

   
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

   
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

   
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }

  function transfer(address _to, uint _value) public returns (bool success) {
     
    CanTransferChecked(released || transferAgents[msg.sender], msg.sender, transferAgents[msg.sender], released);
    if (released || transferAgents[msg.sender]) {revert();}
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
     
    CanTransferChecked(released || transferAgents[msg.sender], msg.sender, transferAgents[msg.sender], released);
    if (released || transferAgents[msg.sender]) {revert();}
    return super.transferFrom(_from, _to, _value);
  }

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



 
contract VelixIDToken is ReleasableToken, BurnableToken {
 

  using SafeMath for uint256;

   
  event UpdatedTokenInformation(string newName, string newSymbol);

  string public name;

  string public symbol;

  uint public decimals;

 

   
  function VelixIDToken(string _name, string _symbol, uint _initialSupply, uint _decimals) public {
     
    require(_initialSupply != 0);

    owner = msg.sender;

    name = _name;
    symbol = _symbol;

    totalSupply = _initialSupply;

    decimals = _decimals;

     
    balances[owner] = totalSupply;
  }

   
  function setTokenInformation(string _name, string _symbol) onlyOwner public {
    name = _name;
    symbol = _symbol;

    UpdatedTokenInformation(name, symbol);
  }

  function transfer(address _to, uint _value) public returns (bool success) {
     
    CanTransferChecked(released || transferAgents[msg.sender], msg.sender, transferAgents[msg.sender], released);
    if (released || transferAgents[msg.sender]) {
      return super.transfer(_to, _value);
    } else {
      return false;
    }
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
     
    CanTransferChecked(released || transferAgents[msg.sender], msg.sender, transferAgents[msg.sender], released);
    if (released || transferAgents[msg.sender]) {
      return super.transferFrom(_from, _to, _value);
    } else {
      return false;
    }
  }
}