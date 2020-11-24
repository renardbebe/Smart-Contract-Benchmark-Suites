 

pragma solidity ^0.4.11;
contract LightCoinToken{
	mapping (address => uint256) balances;
	address public owner;
	address public lockOwner;
    string public name;
    string public symbol;
    uint8 public decimals;
	uint256 public lockAmount ;
    uint256 public startTime ;
	 
    uint256 public totalSupply;
	 
    mapping (address => mapping (address => uint256)) allowed;
    function LightCoinToken() public { 
        owner = 0x9a64fE62837d8E2C0Bd0C2a96bbDdEA609Ab2F19;           
		lockOwner = 0x821C05372425709a68090A17075A855dd20371c7;
		startTime = 1515686400;
        name = "Lightcoin";                                    
        symbol = "Light";                                            
        decimals =8;                                             
		totalSupply = 21000000000000000000;                
		balances[owner] = totalSupply * 90 /100 ;
		balances[0x6CC0BE3c4ad8306526506CB602591AA029896B46]=2000000;
		lockAmount = totalSupply / 10 ;
    }
	
     
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
		 return balances[_owner];
	}

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
	    require(_value > 0 );                                       
		require(balances[msg.sender] >= _value);
		balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
	}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
	    require(balances[_from] >= _value);                  
        require(balances[_to] + _value >= balances[_to]);    
        require(_value <= allowed[_from][msg.sender]);       
		balances[_from] -= _value;
        balances[_to] += _value;
		allowed[_from][_to] -= _value;
        Transfer(_from, _to, _value);
        return true;
	}

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
		require(balances[msg.sender] >= _value);
		allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
		return true;
	}
	
     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
	}
	
	 
    function () private {
        revert();      
    }
	
	function releaseToken() public{
	   require(now >= startTime +2 years);	   
       uint256 i = ((now  - startTime -2 years) / (0.5 years));
	   uint256  releasevalue = totalSupply /40 ;
	   require(lockAmount > (4 - i - 1) * releasevalue); 	   
	   lockAmount -= releasevalue ;
	   balances[lockOwner] +=  releasevalue ;
    }
	
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}