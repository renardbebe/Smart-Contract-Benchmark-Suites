 

pragma solidity ^0.5.11;

library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		if (a == 0) {
			return 0;
		}
		c = a * b;
		assert(c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return a / b;
	}
	
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}

contract Ownable {
	address public owner;
	address public newOwner;

	event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

	constructor() public {
		owner = msg.sender;
		newOwner = address(0);
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "msg.sender == owner");
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		require(address(0) != _newOwner, "address(0) != _newOwner");
		newOwner = _newOwner;
	}

	function acceptOwnership() public {
		require(msg.sender == newOwner, "msg.sender == newOwner");
		emit OwnershipTransferred(owner, msg.sender);
		owner = msg.sender;
		newOwner = address(0);
	}
}

contract tokenInterface {
	function balanceOf(address _owner) public view returns (uint256 balance);
	function transfer(address _to, uint256 _value) public returns (bool);
	bool public started;
}

contract Token_Timelock_ERC20 is Ownable {
    using SafeMath for uint256;
	
	tokenInterface public tokenContract;
	uint256 public dataUnlock;
	address public payee;

	constructor(address _tokenAddress, uint256 _dataUnlock, address _payee, string  memory _name, string memory _symbol, uint8 _decimals) public {
		tokenContract = tokenInterface(_tokenAddress);
		dataUnlock = _dataUnlock;
		
		payee = _payee;
		name = _name;
        symbol = _symbol;
        decimals = _decimals;
	}
	
	uint256 registeredBalance;
	function init() onlyOwner public {
	    uint256 diff = totalSupply().sub(registeredBalance);
	    registeredBalance = totalSupply();
	    emit Transfer(address(0), payee, diff );
	}
	
	function () external {
	    transfer( msg.sender, totalSupply() );
	}
	
	 
	 
 	string public name;
    string public symbol;
    uint8 public decimals;
	
    function totalSupply() view public returns(uint256){
        return tokenContract.balanceOf(address(this));
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    function transfer(address _to, uint256 _amount) public returns (bool) {
        require( msg.sender == payee, "msg.sender == payee" );
		require( balanceOf(payee) > 0, "balanceOf(payee) > 0" );
		require( now > dataUnlock, "now > dataUnlock" );
		
		tokenContract.transfer(_to, _amount);
        emit Transfer(msg.sender, address(0), _amount);
		
        return true;
    }

    function balanceOf(address _tknHolder) public view returns (uint256 balance) {
        if (payee == _tknHolder) balance = totalSupply();
    }
	 
 	 
	 
	 function changeTokenContract(address _tokenAddress) onlyOwner public {
	     tokenContract = tokenInterface(_tokenAddress);
	 }
	 
	 function changeDataUnlock(uint256 _dataUnlock) onlyOwner public {
	     dataUnlock = _dataUnlock;
	 }
	 
	 function changePayee(address _payee) onlyOwner public {
		payee = _payee;
	 }
	 
	 function changeName(string  memory _name) onlyOwner public {
		name = _name;
	 }
	 
	 function changeSymbol(string memory _symbol) onlyOwner public {
		symbol = _symbol;
	 }
	 
	 function changeDecimals(uint8 _decimals) onlyOwner public {
		decimals = _decimals;
	 }
	
}