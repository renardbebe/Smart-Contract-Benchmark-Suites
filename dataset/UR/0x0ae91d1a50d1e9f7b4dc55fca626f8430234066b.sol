 

pragma solidity ^0.4.21;

 
 
contract Owned {
    
     
     
    address public owner;
    address internal newOwner;
    
     
    function Owned() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    event updateOwner(address _oldOwner, address _newOwner);
    
     
    function changeOwner(address _newOwner) public onlyOwner returns(bool) {
        require(owner != _newOwner);
        newOwner = _newOwner;
        return true;
    }
    
     
    function acceptNewOwner() public returns(bool) {
        require(msg.sender == newOwner);
        emit updateOwner(owner, newOwner);
        owner = newOwner;
        return true;
    }
}

 
 
library SafeMath {

  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

}

contract tokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract ERC20Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant public returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract standardToken is ERC20Token {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) 
        public 
        returns (bool success) 
    {
        require (balances[msg.sender] >= _value);            
        require (balances[_to] + _value >= balances[_to]);   
        balances[msg.sender] -= _value;                      
        balances[_to] += _value;                             
        emit Transfer(msg.sender, _to, _value);              
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        allowances[msg.sender][_spender] = _value;           
        emit Approval(msg.sender, _spender, _value);         
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);               
        approve(_spender, _value);                                       
        spender.receiveApproval(msg.sender, _value, this, _extraData);   
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require (balances[_from] >= _value);                 
        require (balances[_to] + _value >= balances[_to]);   
        require (_value <= allowances[_from][msg.sender]);   
        balances[_from] -= _value;                           
        balances[_to] += _value;                             
        allowances[_from][msg.sender] -= _value;             
        emit Transfer(_from, _to, _value);                   
        return true;
    }

     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

}

contract FactoringChain is standardToken, Owned {
    using SafeMath for uint;
    
    string public name="Factoring Chain";
    string public symbol="ECDS";
    uint256 public decimals=18;
    uint256 public totalSupply = 0;
    uint256 public topTotalSupply = 365*10**8*10**decimals;
     
    function() public payable {
        revert();
    }
    
     
    function FactoringChain(address _tokenAlloc) public {
        owner=msg.sender;
        balances[_tokenAlloc] = topTotalSupply;
        totalSupply = topTotalSupply;
        emit Transfer(0x0, _tokenAlloc, topTotalSupply); 
    }
}