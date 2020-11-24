 

pragma solidity ^0.4.21;

 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Token {

     
     
    function balanceOf(address _owner) public view returns (uint balance);

     
     
     
     
    function transfer(address _to, uint _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


 
 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

 
 
 
 
 
 
 
 
 
 
 
contract DIDOToken is ERC20Token {
    using SafeMath for uint;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

     
     
     
     
     
     
     
     
    string public name;                    
    uint8  public decimals;                
    string public symbol;                  
    string public version = 'H0.1';        
    uint   public totalSupply;

     
     
     
    function() external payable {
        revert();
    }
    
    constructor() public {
        symbol   = "DIDO";                               
        name     = "Doitdo Axis";                        
        decimals = 18;                                   

        totalSupply = 3 * 10**26;                       
        balances[msg.sender] = totalSupply;             
    }

    function transfer(address _to, uint _value) public returns (bool) {
         
         
         
         
        if (_value > 0 && balances[msg.sender] >= _value) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
         
         
        if (_value > 0 && balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
            balances[_to] = balances[_to].add(_value);
            balances[_from] = balances[_to].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }
    
     
    function approveAndCall(address _spender, uint _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }
}