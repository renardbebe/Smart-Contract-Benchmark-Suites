 

pragma solidity ^0.4.25;

 
 
 
 
 
 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
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

contract NetkillerToken is Ownable{
    
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint public decimals;
    uint256 public totalSupply;
    
     
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint decimalUnits
    ) public {
        owner = msg.sender;
        name = tokenName;                                    
        symbol = tokenSymbol; 
        decimals = decimalUnits;
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balances[msg.sender] = totalSupply;                 
    }

    function balanceOf(address _address) view public returns (uint256 balance) {
        return balances[_address];
    }
    
     
    function _transfer(address _from, address _to, uint256 _value) internal {
        require (_to != address(0));                         
        require (balances[_from] >= _value);                 
        require (balances[_to] + _value > balances[_to]);    
        balances[_from] = balances[_from].sub(_value);       
        balances[_to] = balances[_to].add(_value);           
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);      
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function airdrop(address[] _to, uint256 _value) onlyOwner public returns (bool success) {
        
        require(_value > 0 && balanceOf(msg.sender) >= _value.mul(_to.length));
        
        for (uint i=0; i<_to.length; i++) {
            _transfer(msg.sender, _to[i], _value);
        }
        return true;
    }
    
    function batchTransfer(address[] _to, uint256[] _value) onlyOwner public returns (bool success) {
        require(_to.length == _value.length);

        uint256 amount = 0;
        for(uint n=0;n<_value.length;n++){
            amount = amount.add(_value[n]);
        }
        
        require(amount > 0 && balanceOf(msg.sender) >= amount);
        
        for (uint i=0; i<_to.length; i++) {
            transfer(_to[i], _value[i]);
        }
        return true;
    }
}