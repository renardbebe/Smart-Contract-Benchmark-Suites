 

pragma solidity ^0.4.21;



 
contract Ownable {
	
	address public owner;
	address public potentialOwner;
	
	
	event OwnershipRemoved(address indexed previousOwner);
	event OwnershipTransfer(address indexed previousOwner, address indexed newOwner);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	
	
	 
	function Ownable() public {
		owner = msg.sender;
	}
	
	
	 
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	
	 
	modifier onlyPotentialOwner() {
		require(msg.sender == potentialOwner);
		_;
	}
	
	
	 
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransfer(owner, newOwner);
		potentialOwner = newOwner;
	}
	
	
	 
	function confirmOwnership() public onlyPotentialOwner {
		emit OwnershipTransferred(owner, potentialOwner);
		owner = potentialOwner;
		potentialOwner = address(0);
	}
	
	
	 
	function removeOwnership() public onlyOwner {
		emit OwnershipRemoved(owner);
		owner = address(0);
	}
	
}

 
library AddressTools {
	
	 
	function isContract(address a) internal view returns (bool) {
		if(a == address(0)) {
			return false;
		}
		
		uint codeSize;
		 
		assembly {
			codeSize := extcodesize(a)
		}
		
		if(codeSize > 0) {
			return true;
		}
		
		return false;
	}
	
}

 
contract ERC223Reciever {
	
	 
	function tokenFallback(address _from, uint256 _value, bytes _data) external returns (bool);
	
}

 
library SafeMath {
	
	 
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}
	
	
	 
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a / b;
		return c;
	}
	
	
	 
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}
	
	
	 
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
	
	
	 
	function pow(uint a, uint b) internal pure returns (uint) {
		if (b == 0) {
			return 1;
		}
		uint c = a ** b;
		assert(c >= a);
		return c;
	}
	
	
	 
	function withDecimals(uint number, uint decimals) internal pure returns (uint) {
		return mul(number, pow(10, decimals));
	}
	
}

 
contract ERC20Basic {
	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
	
	using SafeMath for uint256;
	
	mapping(address => uint256) public balances;
	
	uint256 public totalSupply_;
	
	
	 
	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}
	
	
	 
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);
		
		 
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}
	
	
	 
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}
	
}

 
contract BurnableToken is BasicToken {
	
	event Burn(address indexed burner, uint256 value);
	
	 
	function burn(uint256 _value) public {
		require(_value <= balances[msg.sender]);
		 
		 
		
		address burner = msg.sender;
		balances[burner] = balances[burner].sub(_value);
		totalSupply_ = totalSupply_.sub(_value);
		emit Burn(burner, _value);
		emit Transfer(burner, address(0), _value);
	}
}

 
contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public view returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {
	
	mapping (address => mapping (address => uint256)) internal allowed;
	
	
	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);
		
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}
	
	
	 
	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}
	
	
	 
	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}
	
	 
	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
	
	
	 
	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

}

 
contract ERC223 is ERC20 {
	function transfer(address to, uint256 value, bytes data) public returns (bool);
	event ERC223Transfer(address indexed from, address indexed to, uint256 value, bytes data);
}

 
contract ERC223Token is ERC223, StandardToken {
	
	using AddressTools for address;
	
	
	 
	function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
		return executeTransfer(_to, _value, _data);
	}
	
	
	 
	function transfer(address _to, uint256 _value) public returns (bool) {
		bytes memory _data;
		
		return executeTransfer(_to, _value, _data);
	}
	
	
	 
	function executeTokenFallback(address _to, uint256 _value, bytes _data) private returns (bool) {
		ERC223Reciever receiver = ERC223Reciever(_to);
		
		return receiver.tokenFallback(msg.sender, _value, _data);
	}
	
	
	 
	function executeTransfer(address _to, uint256 _value, bytes _data) private returns (bool) {
		require(super.transfer(_to, _value));
		
		if(_to.isContract()) {
			require(executeTokenFallback(_to, _value, _data));
			emit ERC223Transfer(msg.sender, _to, _value, _data);
		}
		
		return true;
	}
	
}

 
contract UKTTokenBasic is ERC223, BurnableToken {
	
	bool public isControlled = false;
	bool public isConfigured = false;
	bool public isAllocated = false;
	
	 
	mapping(bytes32 => address) public allocationAddressesTypes;
	 
	mapping(address => uint32) public timelockedAddresses;
	 
	mapping(address => bool) public lockedAddresses;
	
	
	function setConfiguration(string _name, string _symbol, uint _totalSupply) external returns (bool);
	function setInitialAllocation(address[] addresses, bytes32[] addressesTypes, uint[] amounts) external returns (bool);
	function setInitialAllocationLock(address allocationAddress ) external returns (bool);
	function setInitialAllocationUnlock(address allocationAddress ) external returns (bool);
	function setInitialAllocationTimelock(address allocationAddress, uint32 timelockTillDate ) external returns (bool);
	
	 
	event Controlled(address indexed tokenController);
	 
	event Configured(string tokenName, string tokenSymbol, uint totalSupply);
	event InitiallyAllocated(address indexed owner, bytes32 addressType, uint balance);
	event InitiallAllocationLocked(address indexed owner);
	event InitiallAllocationUnlocked(address indexed owner);
	event InitiallAllocationTimelocked(address indexed owner, uint32 timestamp);
	
}

 
contract UKTToken is UKTTokenBasic, ERC223Token, Ownable {
	
	using AddressTools for address;
	
	string public name;
	string public symbol;
	uint public constant decimals = 18;
	
	 
	address public controller;
	
	
	modifier onlyController() {
		require(msg.sender == controller);
		_;
	}
	
	modifier onlyUnlocked(address _address) {
		address from = _address != address(0) ? _address : msg.sender;
		require(
			lockedAddresses[from] == false &&
			(
				timelockedAddresses[from] == 0 ||
				timelockedAddresses[from] <= now
			)
		);
		_;
	}
	
	
	 
	function setController(
		address _controller
	) public onlyOwner {
		 
		require(!isControlled);
		 
		require(_controller.isContract());
		
		controller = _controller;
		removeOwnership();
		
		emit Controlled(controller);
		
		isControlled = true;
	}
	
	
	 
	function setConfiguration(
		string _name,
		string _symbol,
		uint _totalSupply
	) external onlyController returns (bool) {
		 
		require(!isConfigured);
		 
		require(bytes(_name).length > 0);
		 
		require(bytes(_symbol).length > 0);
		 
		require(_totalSupply > 0);
		
		name = _name;
		symbol = _symbol;
		totalSupply_ = _totalSupply.withDecimals(decimals);
		
		emit Configured(name, symbol, totalSupply_);
		
		isConfigured = true;
		
		return isConfigured;
	}
	
	
	 
	function setInitialAllocation(
		address[] addresses,
		bytes32[] addressesTypes,
		uint[] amounts
	) external onlyController returns (bool) {
		 
		require(!isAllocated);
		 
		require(addresses.length == addressesTypes.length);
		 
		require(addresses.length == amounts.length);
		 
		uint balancesSum = 0;
		for(uint b = 0; b < amounts.length; b++) {
			balancesSum = balancesSum.add(amounts[b]);
		}
		require(balancesSum.withDecimals(decimals) == totalSupply_);
		
		for(uint a = 0; a < addresses.length; a++) {
			balances[addresses[a]] = amounts[a].withDecimals(decimals);
			allocationAddressesTypes[addressesTypes[a]] = addresses[a];
			emit InitiallyAllocated(addresses[a], addressesTypes[a], balanceOf(addresses[a]));
		}
		
		isAllocated = true;
		
		return isAllocated;
	}
	
	
	 
	function setInitialAllocationLock(
		address allocationAddress
	) external onlyController returns (bool) {
		require(allocationAddress != address(0));
		
		lockedAddresses[allocationAddress] = true;
		
		emit InitiallAllocationLocked(allocationAddress);
		
		return true;
	}
	
	
	 
	function setInitialAllocationUnlock(
		address allocationAddress
	) external onlyController returns (bool) {
		require(allocationAddress != address(0));
		
		lockedAddresses[allocationAddress] = false;
		
		emit InitiallAllocationUnlocked(allocationAddress);
		
		return true;
	}
	
	
	 
	function setInitialAllocationTimelock(
		address allocationAddress,
		uint32 timelockTillDate
	) external onlyController returns (bool) {
		require(allocationAddress != address(0));
		require(timelockTillDate >= now);
		
		timelockedAddresses[allocationAddress] = timelockTillDate;
		
		emit InitiallAllocationTimelocked(allocationAddress, timelockTillDate);
		
		return true;
	}
	
	
	 
	function transfer(
		address _to,
		uint256 _value
	) public onlyUnlocked(address(0)) returns (bool) {
		require(super.transfer(_to, _value));
		return true;
	}
	
	
	 
	function transfer(
		address _to,
		uint256 _value,
		bytes _data
	) public onlyUnlocked(address(0)) returns (bool) {
		require(super.transfer(_to, _value, _data));
		return true;
	}
	
	
	 
	function transferFrom(
		address _from,
		address _to,
		uint256 _value
	) public onlyUnlocked(_from) returns (bool) {
		require(super.transferFrom(_from, _to, _value));
		return true;
	}
	
}