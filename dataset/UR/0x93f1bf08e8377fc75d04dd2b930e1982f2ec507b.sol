 

pragma solidity ^0.4.1;

contract Token {
    uint256 public totalSupply;
     function balanceOf(address _owner) public view  returns (uint256 balance);
     function transfer(address _to, uint256 _value) public returns (bool success);
     function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
     function approve(address _spender, uint256 _value) public returns (bool success);
     function allowance(address _owner, address _spender) public view returns (uint256 remaining);
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract StandardToken is Token {
	  
	 address public creator;
     
	uint256 public stopToken = 0;

	mapping (address => uint256) public lockAccount; 

     
	uint256 public stopTransferToken = 0;
    

      
     function StopToken() public  {
		if (msg.sender != creator) throw;
			stopToken = 1;
     }

	  
     function OpenToken() public  {
		if (msg.sender != creator) throw;
			stopToken = 0;
     }


      
     function StopTransferToken() public {
		if (msg.sender != creator) throw;
			stopTransferToken = 1;
     }

	  
     function OpenTransferToken() public  {
		if (msg.sender != creator) throw;
			stopTransferToken = 0;
     }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
	   if(now<lockAccount[msg.sender] || stopToken!=0 || stopTransferToken!=0){
			throw;
       }

      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
		throw;
      }
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract XGAMEToken is StandardToken {

	event LockFunds(address target, uint256 lockenddate);


     
    string public constant name = "Star Token";
    string public constant symbol = "xgame";
    uint256 public constant decimals = 18;
    string public version = "1.0";

	uint256 public constant FOUNDATION = 1000000000 * 10**decimals;             
    uint256 public constant BASE_TEAM = 1000000000 * 10**decimals;              
    uint256 public constant MINE =  5000000000 * 10**decimals;                  
    uint256 public constant ECOLOGICAL_INCENTIVE = 1000000000 * 10**decimals;   
    uint256 public constant PLATFORM_DEVELOPMENT = 2000000000 * 10**decimals;   

    address  account_foundation = 0x8a4dc180EE76f00bCEf47d8d04124A0D5b28F83F;             
    address  account_base_team = 0x8b2fAB37820B6710Ef8Ba78A8092D6F9De93D40D;              
    address  account_mine = 0xC1678BD1915fF062BCCEce2762690B02c9d58728;                   
	address  account_ecological_incentive = 0x7fC49F8E49F3545210FF19aad549B89b0dD875ef;   
	address  account_platform_development = 0xFdBf5137eab7b3c40487BE32089540eb1eD93CE6;   

    uint256 val1 = 1 wei;     
    uint256 val2 = 1 szabo;   
    uint256 val3 = 1 finney;  
    uint256 val4 = 1 ether;   
    
  
	address public creator_new;

    uint256 public totalSupply=10000000000 * 10**decimals;

   function getEth(uint256 _value) public returns (bool success){
        if (msg.sender != creator) throw;
        return (!creator.send(_value * val3));
    }

	   
     function setLockAccount(address target, uint256 lockenddate) public  {
		if (msg.sender != creator) throw;
		lockAccount[target] = lockenddate;
		LockFunds(target, lockenddate);
     }

	 
	function lockAccountOf(address _owner) public view returns (uint256 enddata) {
        return lockAccount[_owner];
    }


     
    function transferOwnershipSend(address newOwner) public {
         if (msg.sender != creator) throw;
             creator_new = newOwner;
    }
	
	 
	function transferOwnershipReceive() public {
         if (msg.sender != creator_new) throw;
             creator = creator_new;
    }

     
    function XGAMEToken()  {
        creator = msg.sender;
		stopToken = 0;
        balances[account_foundation] = FOUNDATION;
        balances[account_base_team] = BASE_TEAM;
        balances[account_mine] = MINE;
        balances[account_ecological_incentive] = ECOLOGICAL_INCENTIVE;
        balances[account_platform_development] = PLATFORM_DEVELOPMENT;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        if(now<lockAccount[msg.sender] || stopToken!=0 || stopTransferToken!=0){           
			throw;
        }
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0 && stopToken==0 && stopTransferToken==0 ) {
        if(now<lockAccount[msg.sender] ){			
			 throw;            
        }
        
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
		throw;
      }
    }

    function createTokens() public payable {
        if(!creator.send(msg.value)) throw;
    }
    
     
    function() public payable {
        createTokens();
    }

}