 

pragma solidity ^0.4.15;

 
contract IERC20 {
    function totalSupply() constant returns (uint _totalSupply);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


 
library SafeMathLib {

 
  function minus(uint a, uint b) internal constant returns (uint) {
    assert(b <= a);
    return a - b;
  }

 
  function plus(uint a, uint b) internal constant returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

}

 
contract Ownable {

  address public owner;
  mapping (address => bool) public accessHolder;

   
  function Ownable() {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
  
   
  function addToAccesslist(address user) onlyOwner {
    accessHolder[user] = true;
  }
  
}


 
contract BitIndia is IERC20, Ownable {
    
    using SafeMathLib for uint256;
    
    uint256 public constant totalTokenSupply = 180000000 * 10**18;

    string public name;     
    string public symbol;   
    uint8 public constant decimals = 18;
    
    uint private publicTransferDealine = 1509494400;  
    bool private isPublicTransferAllowed = false;
    
    
    mapping (address => uint256) public balances;
     
    mapping(address => mapping(address => uint256)) approved;
    
    function BitIndia(string tokenName, string tokenSymbol) {
        
        name = tokenName;
        symbol = tokenSymbol;
        balances[msg.sender] = totalTokenSupply;

    }
    
    function totalSupply() constant returns (uint256 _totalSupply) {
        return totalTokenSupply;
    }
    
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    
     
    function _transfer(address _from, address _to, uint256 _value) internal {
        require (_to != 0x0);                                
        require (balances[_from] >= _value);                  
        require (balances[_to] + _value > balances[_to]);    
        balances[_from] = balances[_from].minus(_value);     
        balances[_to] = balances[_to].plus(_value);          
        Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require (_value <= approved[_from][msg.sender]);      
        approved[_from][msg.sender] = approved[_from][msg.sender].minus(_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
     
    function approve(address _spender, uint256 _value) returns (bool success) {
        if(balances[msg.sender] >= _value) {
            approved[msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _value);
            return true;
        }
        return false;
    }
    
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return approved[_owner][_spender];
    }
    
     
    function allowPublicTransfer() onlyOwner {
        isPublicTransferAllowed = true;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}