 

 
 
pragma solidity ^0.4.8;

contract ERC20Basic {
     
     
    uint256 public totalSupply;
    address public target;
    uint256 public totalCount;

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is ERC20Basic {

    uint256 constant MAX_UINT256 = 2**256 - 1;

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
         
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

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}


contract AeaToken is StandardToken {

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'H0.1';        
    bool public canIssue;
      
    event Issue(address addr, uint ethAmount, uint tokenAmount);
     function AeaToken(
        ) public {
        uint256 indexPrice=21000*(10**22);
        balances[msg.sender] = indexPrice-10000*(10**22); 
         
        totalSupply = indexPrice;                         
        totalCount = 10000*(10**22);
        name = "Test9527Token";                                    
        decimals = 18;                             
        symbol = "test9527";      
        target=msg.sender;
        canIssue=true;
    }

    	 
	function withdrawEther(uint256 amount) {
		if(msg.sender != target)throw;
		target.transfer(amount);

	}
    
    modifier canPay {
        if (totalCount>0) {
            _;
        } else {
            
            throw;
        }
    }
    
    
    
     
	function() payable canPay {
	    
	    assert(msg.value>=0.0001 ether);
	    if(msg.sender!=target){
	        uint256 tokens=1000*msg.value;
	        if(canIssue){
	            if(tokens>totalCount){
                    balances[msg.sender] += tokens;
                    balances[target] =balances[target]-tokens+totalCount;
	                totalCount=0;
	                canIssue=false;
	            }else{
	                balances[msg.sender]=balances[msg.sender]+tokens;
	                totalCount=totalCount-tokens;
	            }
	            Issue(msg.sender,msg.value,tokens);
	        }
	    }
	    
	    if (!target.send(msg.value)) {
            throw;
        }
	 
    }
}