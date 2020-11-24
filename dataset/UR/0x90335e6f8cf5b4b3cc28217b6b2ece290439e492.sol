 

pragma solidity ^0.4.11;
 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract DragonCoin is StandardToken {
    using SafeMath for uint256;
    
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);
    
    string public name = "DragonGameCoin"; 
    string public symbol = "DGC";
    uint public decimals = 18;
    uint public INITIAL_SUPPLY = 1000000 * (10 ** decimals);     
    uint public MAX_SUPPLY = 10 * 100000000 * (10 ** decimals); 
    address public ceo;
    address public coo;
    address public cfo;

    function DragonCoin() {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        ceo = msg.sender;
        Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
    
    function setCEO(address newCEO) public onlyCEO{
        require(newCEO != address(0));
        
        ceo = newCEO;
    }
    
    function setCOO(address newCOO) public onlyCEO{
        require(newCOO != address(0));
        
        coo = newCOO;
    }
    
    function setCFO(address newCFO) public onlyCEO{
        require(newCFO != address(0));
        
        cfo = newCFO;
    }
    
    function mint(uint256 value) public onlyCFO returns (bool) {
        require(totalSupply_.add(value) <= MAX_SUPPLY);
        
        balances[cfo] = balances[cfo].add(value);
        totalSupply_ = totalSupply_.add(value);
        
         
        Mint(cfo, value);
        Transfer(0x0, cfo, value);
        return true;
    }
    
    function burn(uint256 value) public onlyCOO returns (bool) {
        require(balances[coo] >= value); 
        
        balances[coo] = balances[coo].sub(value);
        totalSupply_ = totalSupply_.sub(value);
        
         
        Burn(coo, value);
        Transfer(coo, 0x0, value);
        return true;
    }
    
    
     
    modifier onlyCEO() {
        require(msg.sender == ceo);
        _;
    }
    
     
    modifier onlyCFO() {
        require(msg.sender == cfo);
        _;
    }
    
     
    modifier onlyCOO() {
        require(msg.sender == coo);
        _;
    }
    
    
}