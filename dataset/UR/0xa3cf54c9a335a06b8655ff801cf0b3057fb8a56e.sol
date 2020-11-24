 

 

pragma solidity ^0.4.23;


 
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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


 
contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract PRODToken is ERC20, Pausable {

  using SafeMath for uint256;
    
  string public name = "Productivist";       
  string public symbol = "PROD";            
  uint256 public decimals = 8;             


   
  uint256 public constant SHARE_PURCHASERS = 617;
  uint256 public constant SHARE_FOUNDATION = 173;
  uint256 public constant SHARE_TEAM = 160;
  uint256 public constant SHARE_BOUNTY = 50;

   
  address public foundationAddress = 0x0;
  address public teamAddress = 0x0;
  address public bountyAddress = 0x0;

  uint256 totalSupply_ = 0;
  uint256 public cap = 385000000 * 10 ** decimals;  

  mapping(address => uint256) balances;
  
  mapping (address => mapping (address => uint256)) internal allowed;

  bool public mintingFinished = false;

  event Burn(address indexed burner, uint256 value);
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function setName(string _name) onlyOwner public {
    name = _name;
  }
  
  function setWallets(address _foundation, address _team, address _bounty) public onlyOwner canMint {
    require(_foundation != address(0) && _team != address(0) && _bounty != address(0));
    foundationAddress = _foundation;
    teamAddress = _team;
    bountyAddress = _bounty;
  } 
  
   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  
   
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  
   
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);
    require(_to != address(0));
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {

    require(foundationAddress != address(0) && teamAddress != address(0) && bountyAddress != address(0));
    require(SHARE_PURCHASERS + SHARE_FOUNDATION + SHARE_TEAM + SHARE_BOUNTY == 1000);
    require(totalSupply_ != 0);
    
     
    uint256 onePerThousand = totalSupply_ / SHARE_PURCHASERS;  
    
    uint256 foundationTokens = onePerThousand * SHARE_FOUNDATION;             
    uint256 teamTokens = onePerThousand * SHARE_TEAM;   
    uint256 bountyTokens = onePerThousand * SHARE_BOUNTY;
      
    mint(foundationAddress, foundationTokens);
    mint(teamAddress, teamTokens);
    mint(bountyAddress, bountyTokens);
  
    mintingFinished = true;
    emit MintFinished();
    return true;
  }


   
  function burn(uint256 _value) public whenNotPaused {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(burner, _value);
    emit Transfer(burner, address(0), _value);
  }
  

   
  function batchMint(address[] _data,uint256[] _amount) public onlyOwner canMint {
    for (uint i = 0; i < _data.length; i++) {
	mint(_data[i],_amount[i]);
    }
  }

}