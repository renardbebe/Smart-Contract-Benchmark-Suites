 

pragma solidity ^0.4.20;
 
 
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
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

 
contract Ownable {
    
  address public owner;
  

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));      
    owner = newOwner;
  }
}

 
contract Pausable is Ownable {
  address public saleAgent;
  address public partner;

  modifier onlyAdmin() {
    require(msg.sender == owner || msg.sender == saleAgent || msg.sender == partner);
    _;
  }

  function setSaleAgent(address newSaleAgent) onlyOwner public {
    require(newSaleAgent != address(0)); 
    saleAgent = newSaleAgent;
  }

  function setPartner(address newPartner) onlyOwner public {
    require(newPartner != address(0)); 
    partner = newPartner;
  }

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

 
contract BasicToken is ERC20Basic, Pausable {
    
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 public storageTime = 1522749600;  

  modifier checkStorageTime() {
    require(now >= storageTime);
    _;
  }

  modifier onlyPayloadSize(uint256 numwords) {
    assert(msg.data.length >= numwords * 32 + 4);
    _;
  }

  function setStorageTime(uint256 _time) public onlyOwner {
    storageTime = _time;
  }

   
  function transfer(address _to, uint256 _value) public
  onlyPayloadSize(2) whenNotPaused checkStorageTime returns (bool) {
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

  mapping (address => mapping (address => uint256)) allowed;

   

  function transferFrom(address _from, address _to, uint256 _value) public 
  onlyPayloadSize(3) whenNotPaused checkStorageTime returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public 
  onlyPayloadSize(2) whenNotPaused returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

    
  function increaseApproval(address _spender, uint _addedValue) public 
  onlyPayloadSize(2)
  returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public 
  onlyPayloadSize(2)
  returns (bool) {
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

 

contract MintableToken is StandardToken{
    
  event Mint(address indexed to, uint256 amount);
  
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) public onlyAdmin whenNotPaused canMint returns  (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(this), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
}

 
contract BurnableToken is MintableToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public onlyPayloadSize(1) {
    require(_value <= balances[msg.sender]);
     
     
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
  }

  function burnFrom(address _from, uint256 _value) public 
  onlyPayloadSize(2)
  returns (bool success) {
    require(balances[_from] >= _value); 
    require(_value <= allowed[_from][msg.sender]); 
    balances[_from] = balances[_from].sub(_value);  
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);  
    totalSupply = totalSupply.sub(_value);
    Burn(_from, _value);
    return true;
    }
}

contract AlttexToken is BurnableToken {
    string public constant name = "Alttex";
    string public constant symbol = "ALTX";
    uint8 public constant decimals = 8;
}