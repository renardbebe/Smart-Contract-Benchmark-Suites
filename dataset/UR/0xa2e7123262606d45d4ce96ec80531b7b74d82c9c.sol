 

 

pragma solidity 0.4.25;

 
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
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a); 
    return a - b; 
  } 
  
  function add(uint256 a, uint256 b) internal pure returns (uint256) { 
    uint256 c = a + b; assert(c >= a);
    return c;
  }

}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value)  public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]); 
     
    balances[msg.sender] = balances[msg.sender].sub(_value); 
    balances[_to] = balances[_to].add(_value); 
    emit Transfer(msg.sender, _to, _value); 
    
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
    emit Transfer(_from, _to, _value); 
    
    return true; 
  } 

   
  function approve(address _spender, uint256 _value) public returns (bool) { 
    allowed[msg.sender][_spender] = _value; 
    emit Approval(msg.sender, _spender, _value); 
    return true; 
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) { 
    return allowed[_owner][_spender]; 
  } 

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]); 
    return true; 
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender]; 
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function () public payable {
     
  }

}

 
contract Ownable {
  address public owner;

   
  constructor() public {
    owner = msg.sender;
  }
  
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
}


contract MyctIcoToken is StandardToken, Ownable {
    
    string public constant name = "MyctIco";
    string public constant symbol = "MYCT";
    uint32 public constant decimals = 18;
    
    uint256 public constant totalSupply = 100000000 * (10 ** 18);
    uint256 public totalTransferIco = 0;
    
    constructor() public {
    }
    
    function transferSale(address addr, uint256 tokens) public onlyOwner {
        require(addr != address(0));
        require(balances[address(this)] >= tokens);
        
        balances[addr] = balances[addr].add(tokens);
        balances[address(this)] = balances[address(this)].sub(tokens);
        emit Transfer(address(this), addr, tokens);
    } 
    
    function transferIco(address [] _holders, uint256 [] _tokens) public onlyOwner {
        
        for(uint i=0; i<_holders.length; ++i) {
            balances[_holders[i]] = _tokens[i];
            totalTransferIco += _tokens[i];
            emit Transfer(address(this), _holders[i], _tokens[i]);
        }
        
        require(totalTransferIco <= totalSupply);
    } 
}