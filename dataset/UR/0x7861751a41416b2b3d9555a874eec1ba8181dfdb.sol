 

pragma solidity ^0.4.24;

 
contract OBSToken {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
	string lname = "OuroBoros";
	string lsymbol= "OBS";
	uint8 dec=6;
	address manager;
	uint256 thetotal;
	constructor(uint256 total) public
	{
	    thetotal= total;
		manager = msg.sender;
		balances[manager]=total;
	}
	
	function name() public view returns (string)
	{
	   return lname;
	}
	
	function symbol() public view returns (string)
	{
	   return lsymbol;
	}
	
	function decimals() public view returns (uint8)
	{
	   return dec;
	}
	
	function totalSupply() public view returns (uint256)
	{
		return thetotal;
	}
	
	function balanceOf(address _owner) public view returns (uint256 balance)
	{
	    return balances[_owner];
	}
	
	function transfer(address _to, uint256 _value) public returns (bool success)
	{
	    require(_value > 0 &&_value < 210000000000000000);
		require(balances[msg.sender] >= _value);
		
		uint256 oldtotal= add(balances[msg.sender],balances[_to]);
		balances[msg.sender] = sub(balances[msg.sender],_value);
		balances[_to] = add(balances[_to] ,_value);
		require(balances[_to] + balances[msg.sender] == oldtotal);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}
	
	
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
	{
		require(_value > 0 &&_value < 210000000000000000);
		require(balances[_from] >= _value);
		if(msg.sender != manager)
		{
			require(allowed[_from][msg.sender] >= _value);
			allowed[_from][msg.sender] = sub(allowed[_from][msg.sender],_value);
		}
	
		uint256 oldtotal= add(balances[_from],balances[_to]);
		balances[_from] = sub(balances[_from],_value);	
		balances[_to] = add(balances[_to],_value);
		require(balances[_from] + balances[_to] == oldtotal);
		emit Transfer(_from, _to, _value);
		return true;
	}
	
	function approve(address _spender, uint256 _value) public returns (bool success)
	{
        require(_value > 0 &&_value < 210000000000000000);
		require(balances[msg.sender] >= _value);
        allowed[msg.sender][_spender] = add(allowed[msg.sender][_spender],_value);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
	}
	
	function allowance(address _owner, address _spender) public view returns (uint256 remaining)
	{
	    return allowed[_owner][_spender];
	}
	
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
	
	
	function batch(address []fromaddr, address []toAddr, uint256 []value) public returns (bool)
	{
		require(msg.sender == manager);
		require(toAddr.length == value.length && fromaddr.length==toAddr.length && toAddr.length >= 1);
		for(uint256 i = 0 ; i < toAddr.length; i++){
			if(!transferFrom(fromaddr[i], toAddr[i], value[i])) 
			   {  revert(); }
		}
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }
	
	 function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }
	
	 function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }
	
	 function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
	
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}