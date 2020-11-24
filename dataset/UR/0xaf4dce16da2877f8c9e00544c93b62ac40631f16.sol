 

 

pragma solidity ^0.4.15;

contract SafeMath {
	 

	function safeMul(uint a, uint b) internal returns(uint) {
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function safeSub(uint a, uint b) internal returns(uint) {
		assert(b <= a);
		return a - b;
	}

	function safeAdd(uint a, uint b) internal returns(uint) {
		uint c = a + b;
		assert(c >= a && c >= b);
		return c;
	}
}

contract MonethaToken is SafeMath {
	 
	string constant public standard = "ERC20";
	string constant public name = "Monetha";
	string constant public symbol = "MTH";
	uint8 constant public decimals = 5;
	uint public totalSupply = 40240000000000;
	uint constant public tokensForIco = 20120000000000;
	uint constant public reservedAmount = 20120000000000;
	uint constant public lockedAmount = 15291200000000;
	address public owner;
	address public ico;
	 
	uint public startTime;
	uint public lockReleaseDate;
	 
	bool burned;

	 
	mapping(address => uint) public balanceOf;
	mapping(address => mapping(address => uint)) public allowance;


	 
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed _owner, address indexed spender, uint value);
	event Burned(uint amount);

	 
	function MonethaToken(address _ownerAddr, uint _startTime) {
		owner = _ownerAddr;
		startTime = _startTime;
		lockReleaseDate = startTime + 1 years;
		balanceOf[owner] = totalSupply;  
	}

	 
	function transfer(address _to, uint _value) returns(bool success) {
		require(now >= startTime);  
		if (msg.sender == owner && now < lockReleaseDate) 
			require(safeSub(balanceOf[msg.sender], _value) >= lockedAmount);  
		balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);  
		balanceOf[_to] = safeAdd(balanceOf[_to], _value);  
		Transfer(msg.sender, _to, _value);  
		return true;
	}

	 
	function approve(address _spender, uint _value) returns(bool success) {
		return _approve(_spender,_value);
	}
	
	 
	function _approve(address _spender, uint _value) internal returns(bool success) {
		 
		require((_value == 0) || (allowance[msg.sender][_spender] == 0));
		allowance[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}


	 
	function transferFrom(address _from, address _to, uint _value) returns(bool success) {
		if (now < startTime) 
			require(_from == owner);  
		if (_from == owner && now < lockReleaseDate) 
			require(safeSub(balanceOf[_from], _value) >= lockedAmount);  
		var _allowance = allowance[_from][msg.sender];
		balanceOf[_from] = safeSub(balanceOf[_from], _value);  
		balanceOf[_to] = safeAdd(balanceOf[_to], _value);  
		allowance[_from][msg.sender] = safeSub(_allowance, _value);
		Transfer(_from, _to, _value);
		return true;
	}


	 
	function burn() {
		 
		if (!burned && now > startTime) {
			uint difference = safeSub(balanceOf[owner], reservedAmount);
			balanceOf[owner] = reservedAmount;
			totalSupply = safeSub(totalSupply, difference);
			burned = true;
			Burned(difference);
		}
	}
	
	 
	function setICO(address _icoAddress) {
		require(msg.sender == owner);
		ico = _icoAddress;
		assert(_approve(ico, tokensForIco));
	}
	
	 
	function setStart(uint _newStart) {
		require(msg.sender == ico && _newStart < startTime);
		startTime = _newStart;
	}

}