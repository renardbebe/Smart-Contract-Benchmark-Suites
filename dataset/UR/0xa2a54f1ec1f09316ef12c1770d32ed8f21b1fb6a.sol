 

pragma solidity ^0.4.11;
contract DFT{
	mapping (address => uint256) balances;
	address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
	uint256 public lockAmount ;
    uint256 public startTime ;
	 
    uint256 public totalSupply;
	 
    mapping (address => mapping (address => uint256)) allowed;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function DFT() public { 
        owner = 0x7f29c275bB8903f233D90edBF88402F216aEdC05;           
		startTime = 1521129600;
        name = "DFT";                                    
        symbol = "DFT";                                            
        decimals = 8;                                             
		totalSupply = 210000000000000000;                
		balances[owner] = totalSupply;
        Transfer(msg.sender, owner, totalSupply);
    }
	
     
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
		 return balances[_owner];
	}

     
     
     
     
    function transfer(address _to, uint256 _value) public payable returns (bool success) {
	    require(_value > 0 );                                       
		require(balances[msg.sender] >= _value);
		balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
	}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public payable returns (bool success) {
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
	
}