 

pragma solidity ^0.4.22;


contract Utils {
	function Utils() public {
	}

	 
	 
	 

	 
	 
	 
	 
	 

	 
	modifier validAddress(address _address) {
	    require(_address != address(0));
	    _;
	}

	 
	modifier notThis(address _address) {
	    require(_address != address(this));
	    _;
	}

	function strlen(string s) internal pure returns (uint) {
		 
		uint ptr;
		uint end;
		assembly {
			ptr := add(s, 1)
			end := add(mload(s), ptr)
		}

		for (uint len = 0; ptr < end; len++) {
			uint8 b;
			assembly { b := and(mload(ptr), 0xFF) }
			if (b < 0x80) {
				ptr += 1;
			} else if(b < 0xE0) {
				ptr += 2;
			} else if(b < 0xF0) {
				ptr += 3;
			} else if(b < 0xF8) {
				ptr += 4;
			} else if(b < 0xFC) {
				ptr += 5;
			} else {
				ptr += 6;
			}
		}

		return len;
	}


}


contract SafeMath {
	function SafeMath() {
	}

	function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
		uint256 z = _x + _y;
		assert(z >= _x);
		return z;
	}

	function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
		assert(_x >= _y);
		return _x - _y;
	}

	function safeMul(uint256 _x, uint256 _y) internal returns (uint256) {
		uint256 z = _x * _y;
		assert(_x == 0 || z / _x == _y);
		return z;
	}

	function safeDiv(uint a, uint b) internal returns (uint256) {
		assert(b > 0);
		return a / b;
	}
}


contract ERC20Interface {
     
     
     
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

     
    function Owned() public {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}








contract bundinha is Utils {
	uint N;
	string bundinha;


	function setN(uint x) public {
		N = x;
	}

	function getN() constant public returns (uint) {
		return N;
	}

	function setBundinha(string x) public {
		require(strlen(x) <= 32);
		bundinha = x;
	}

	function getBundinha() constant public returns (string){
		return bundinha;
	}

}





contract SomeCoin is Utils, ERC20Interface, Owned, SafeMath, bundinha {
	uint myVariable;
	string bundinha;

	string public name = '';
	string public symbol = '';
	uint8 public decimals = 0;
	uint256 public totalSupply = 0;
	uint256 public maxSupply = 50000000000000000000000;
							 

	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) public allowance;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Issuance(uint256 _amount);

	 
	function SomeCoin(string _name, string _symbol, uint8 _decimals) {
		require(bytes(_name).length > 0 && bytes(_symbol).length > 0);  

		name = _name;
		symbol = _symbol;
		decimals = _decimals;
		 
	}

	function validSupply() private returns(bool) {
		return totalSupply <= maxSupply;
	}

	function transfer(address _to, uint256 _value)
		public
		validAddress(_to)
		returns (bool success)
	{
		balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
		balanceOf[_to] = safeAdd(balanceOf[_to], _value);
		Transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value)
		public
		validAddress(_from)
		validAddress(_to)
		returns (bool success)
	{
		allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
		balanceOf[_from] = safeSub(balanceOf[_from], _value);
		balanceOf[_to] = safeAdd(balanceOf[_to], _value);
		Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value)
		public
		validAddress(_spender)
		returns (bool success)
	{
		require(_value == 0 || allowance[msg.sender][_spender] == 0);

		allowance[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	function issue(address _to, uint256 _amount)
	    public
	    ownerOnly
	    validAddress(_to)
	    notThis(_to)
	{
	    totalSupply = safeAdd(totalSupply, _amount);
	    balanceOf[_to] = safeAdd(balanceOf[_to], _amount);

	    require(validSupply());

	    Issuance(_amount);
	    Transfer(this, _to, _amount);
	}

	function transferAnyERC20Token(address _token, address _to, uint256 _amount)
		public
		ownerOnly
	    validAddress(_token)
		returns (bool success)
	{
		return ERC20Interface(_token).transfer(_to, _amount);
	}

	 
	function () payable {
		revert();
	}
}