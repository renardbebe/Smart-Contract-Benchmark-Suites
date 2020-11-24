 

pragma solidity ^0.4.25;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }
  

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }


   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
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




 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}




 
contract BasicToken is ERC20Basic, Ownable {
    
  using SafeMath for uint256;
  
  event TokensBurned(address from, uint256 value);
  event TokensMinted(address to, uint256 value);

  mapping(address => uint256) balances;
  mapping(address => bool) blacklisted;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(!blacklisted[msg.sender] && !blacklisted[_to]);
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }


   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
  
  
  
  function addToBlacklist(address[] _addrs) public onlyOwner returns(bool) {
      for(uint i=0; i < _addrs.length; i++) {
          blacklisted[_addrs[i]] = true;
      }
      return true;
  }
  
  
  function removeFromBlacklist(address _addr) public onlyOwner returns(bool) {
      require(blacklisted[_addr]);
      blacklisted[_addr] = false;
      return true;
  }
  

}




 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(!blacklisted[_from] && !blacklisted[_to] && !blacklisted[msg.sender]);
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }


   
  function approve(address _spender, uint256 _value) public returns (bool) {
    require(!blacklisted[_spender] && !blacklisted[msg.sender]);
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }


   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}




 
contract Pausable is Ownable {
    
  event Pause();
  event Unpause();

  bool public paused = true;


   
  modifier whenNotPaused() {
    require(!paused || msg.sender == owner);
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




 
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }


  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
  

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }
  

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }
  

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}




contract LMA is PausableToken {
    
    string public  name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     
    constructor() public {
        name = "Lamoneda";
        symbol = "LMA";
        decimals = 18;
        totalSupply = 500000000e18;
        balances[owner] = totalSupply;
        emit Transfer(address(this), owner, totalSupply);
    }
    
    function burnFrom(address _addr, uint256 _value) public onlyOwner returns(bool) {
        require(balanceOf(_addr) >= _value);
        balances[_addr] = balances[_addr].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Transfer(_addr, 0x0, _value);
        emit TokensBurned(_addr, _value);
        return true;
    }
  
  
    function mintTo(address _addr, uint256 _value) public onlyOwner returns(bool) {
        require(!blacklisted[_addr]);
        balances[_addr] = balances[_addr].add(_value);
        totalSupply = totalSupply.add(_value);
        emit Transfer(address(this), _addr, _value);
        emit TokensMinted(_addr, _value);
        return true;
    }
}