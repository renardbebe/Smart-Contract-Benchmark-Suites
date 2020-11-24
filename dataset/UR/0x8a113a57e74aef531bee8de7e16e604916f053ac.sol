 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
pragma solidity ^0.4.11;

contract ERC20Protocol {
 
     
    uint public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint balance);

     
     
     
     
    function transfer(address _to, uint _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

 
 
contract Owned {

     
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;

     
    function Owned() {
        owner = msg.sender;
    }

    address public newOwner;

     
     
     
    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }


    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract StandardToken is ERC20Protocol {
    using SafeMath for uint;

     
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
         
         
         
         
        assert((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
}

contract tokenRecipient { 
	function receiveApproval(
		address _from, 
		uint256 _value, 
		address _token, 
		bytes _extraData); 
}

contract ClipperCoin is Owned{
    using SafeMath for uint;

     
    string public name = "Clipper Coin";
    string public symbol = "CCCT";
    uint public decimals = 18;

     
    uint public totalSupply = 200000000 ether;
    
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
     
    event Burn(address indexed from, uint256 value);
    
     
     
    function ClipperCoin(
    	uint256 initialSupply,
    	string tokenName,
    	uint8 tokenDecimals,
    	string tokenSymbol
    	) {
    	    
    	 
    	balanceOf[msg.sender]  = initialSupply;
    	
    	 
    	totalSupply  = initialSupply;
    	
    	 
    	name = tokenName;
    	
    	 
    	symbol = tokenSymbol;
    	
    	 
    	 
    	decimals = tokenDecimals;
    }
    
    
     
    function _transfer(
    	address _from,
    	address _to,
    	uint _value)
    	internal {
    	    
    	 
    	 
    	require (_to != 0x0);
    	
    	 
        require (balanceOf[_from] > _value);                
        
         
        require (balanceOf[_to] + _value > balanceOf[_to]); 
        balanceOf[_from] -= _value;                         
        balanceOf[_to] += _value;                           
        Transfer(_from, _to, _value);
    }
    
     
     
     
    function transfer(
    	address _to, 
    	uint256 _value) {
        _transfer(msg.sender, _to, _value);
    }

     
     
     
     
    function transferFrom(
    	address _from, 
    	address _to, 
    	uint256 _value) returns (bool success) {
        require (_value < allowance[_from][msg.sender]);     
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
     
     
    function approve(
    	address _spender, 
    	uint256 _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
     
     
     
     
    function approveAndCall(
    	address _spender, 
    	uint256 _value, 
    	bytes _extraData) returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }        

     
     
    function burn(uint256 _value) returns (bool success) {
        require (balanceOf[msg.sender] > _value);            
        balanceOf[msg.sender] -= _value;                      
        totalSupply -= _value;                                
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(
    	address _from, 
    	uint256 _value) returns (bool success) {
        require(balanceOf[_from] >= _value);                
        require(_value <= allowance[_from][msg.sender]);    
        balanceOf[_from] -= _value;                         
        allowance[_from][msg.sender] -= _value;             
        totalSupply -= _value;                              
        Burn(_from, _value);
        return true;
    }
}