 

pragma solidity ^0.5.8;

contract SafeMath {
     

     
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        require(z >= _x);         
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_x >= _y);         
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        require(_x == 0 || z / _x == _y);         
        return z;
    }
	
	function safeDiv(uint256 _x, uint256 _y)internal pure returns (uint256){
	     
         
         
        return _x / _y;
	}
	
	function ceilDiv(uint256 _x, uint256 _y)internal pure returns (uint256){
		return (_x + _y - 1) / _y;
	}
}

contract XDCToken is SafeMath {
	mapping (address => uint256) balances;
	address public owner = msg.sender;
    string public name;
    string public symbol;
    uint8 public decimals = 18;
	 
    uint256 public totalSupply;
    
	 
    mapping (address => mapping (address => uint256)) allowed;

    constructor() public {
        uint256 initialSupply = 100000000;
        
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balances[owner] = totalSupply;
        name = "XueDaoCoin";
        symbol = "XDC";
    }
	
     
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
		 return balances[_owner];
	}

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
	    require(_value > 0 );                                           
		require(balances[msg.sender] >= _value);                        
        require(balances[_to] + _value > balances[_to]);                
    	balances[msg.sender] = safeSub(balances[msg.sender], _value);   
		balances[_to]  = safeAdd(balances[_to], _value);                
	
		emit Transfer(msg.sender, _to, _value); 			        
		return true;      
	}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
	  
	    require(balances[_from] >= _value);                  
        require(balances[_to] + _value >= balances[_to]);    
        require(_value <= allowed[_from][msg.sender]);       
        balances[_from] = safeSub(balances[_from], _value);   
        balances[_to] = safeAdd(balances[_to], _value);       
       
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        
        emit Transfer(_from, _to, _value);
        return true;
	}

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
		require(balances[msg.sender] >= _value);
		allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
		return true;
	
	}
	
     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
	}
	
	 
    function () external {
        revert();      
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}