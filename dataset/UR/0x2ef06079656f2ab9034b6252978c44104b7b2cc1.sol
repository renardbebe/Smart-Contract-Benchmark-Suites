 

pragma solidity ^0.4.4;
 
 
 
 
 

contract OOSTToken { 
     
     
    uint256 public totalSupply;
    
     
     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender)  public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 

library OOSTMaths {
 
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
 
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract Ownable {
    address public owner;
    address public newOwner;

     
    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

    
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    event OwnershipTransferred(address indexed _from, address indexed _to);
}


contract OostStandardToken is OOSTToken, Ownable {
    
    using OOSTMaths for uint256;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (frozenAccount[msg.sender]) 
            return false;
        require(
            (balances[msg.sender] >= _value)  
            && (_value > 0)  
            && (_to != address(0))  
            && (balances[_to].add(_value) >= balances[_to])  
            && (msg.data.length >= (2 * 32) + 4));  
             

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (frozenAccount[msg.sender]) 
            return false;
        require(
            (allowed[_from][msg.sender] >= _value)  
            && (balances[_from] >= _value)  
            && (_value > 0)  
            && (_to != address(0))  
            && (balances[_to].add(_value) >= balances[_to])  
            && (msg.data.length >= (2 * 32) + 4)  
             
        );
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
         
     
    
    uint256 constant public DECIMALS = 8;                
    uint256 public totalSupply = 24 * (10**7) * 10**8 ;  
    string constant public NAME = "OOST";                
    string constant public SYMBOL = "OOST";              
    string constant public VERSION = "v1";               
    
    function OOST() public {
        balances[msg.sender] = totalSupply;                
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }
}