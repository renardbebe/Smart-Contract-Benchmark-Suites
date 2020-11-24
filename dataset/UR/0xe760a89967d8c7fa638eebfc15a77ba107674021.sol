 

pragma solidity ^0.4.13;


contract admined {
	address public admin;
    address public coAdmin;

	function admined() {
		admin = msg.sender;
        coAdmin = msg.sender;
	}

	modifier onlyAdmin(){
		require((msg.sender == admin) || (msg.sender == coAdmin)) ;
		_;
	}

	function transferAdminship(address newAdmin) onlyAdmin {
		admin = newAdmin;
	}

    function transferCoadminship(address newCoadmin) onlyAdmin {
		coAdmin = newCoadmin;
	}


} 

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
     
    event Burn(address indexed from, uint256 value);
}

 

contract StandardToken is Token {

    uint256 constant MAX_UINT256 = 2**256 - 1;

    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         

         
        require(_to != 0x0);
        
        require(_value > 0);
        
         
        require(balances[_to] + _value > balances[_to]);
        
        uint256 allowance = allowed[_from][msg.sender];
         
        require(balances[_from] >= _value && allowance >= _value);
         
        balances[_to] += _value;
         
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function approve(address _spender, uint256 _value) returns (bool success) {
    		
    		require(_value > 0);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}


 


contract ZigguratToken is admined, StandardToken {

     

     
    string public name;                    
    uint8 public decimals = 18;            
    string public symbol;                  
    string public version = "1.0";        
    uint256 public totalMaxSupply = 5310000000 * 10 ** 17;  
    
    function ZigguratToken(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) {
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
    }

     
     

    function mintToken(address target, uint256 mintedAmount) onlyAdmin returns (bool success) {
          
        require ((totalMaxSupply == 0) || ((totalMaxSupply != 0) && (safeAdd (totalSupply, mintedAmount) <= totalMaxSupply )));

        balances[target] = safeAdd(balances[target], mintedAmount);
        totalSupply = safeAdd(totalSupply, mintedAmount);
		Transfer(0, this, mintedAmount);
		Transfer(this, target, mintedAmount);
        return true;
	} 

    function safeAdd(uint a, uint b) internal returns (uint) {
        require (a + b >= a); 
        return a + b;
    }

     
     

    function decreaseSupply(uint _value, address _from) onlyAdmin returns (bool success) {
    	  require(_value > 0);
        balances[_from] = safeSub(balances[_from], _value);
        totalSupply = safeSub(totalSupply, _value);  
        Transfer(_from, 0, _value);
        return true;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        require (b <= a); 
        return a - b;
    }

     
         
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
    		require(_value > 0);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

}