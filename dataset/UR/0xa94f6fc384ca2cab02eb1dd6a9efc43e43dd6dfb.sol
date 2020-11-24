 

pragma solidity ^0.4.21;



 
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

 
contract ERC223 is ERC20 {
	function transfer(address to, uint256 value, bytes data) public returns (bool);
	event ERC223Transfer(address indexed from, address indexed to, uint256 value, bytes data);
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

 
contract UKTTokenController is Ownable {
	
	using SafeMath for uint256;
	using AddressTools for address;
	
	bool public isFinalized = false;
	
	 
	UKTTokenBasic public token;
	 
	bytes32 public finalizeType = "transfer";
	 
	bytes32 public finalizeTransferAddressType = "";
	 
	uint8 internal MAX_ADDRESSES_FOR_DISTRIBUTE = 100;
	 
	address[] internal lockedAddressesList;
	
	
	 
	event Distributed(address indexed holder, bytes32 indexed trackingId, uint256 amount);
	 
	event Finalized();
	
	 
	function UKTTokenController(
		bytes32 _finalizeType,
		bytes32 _finalizeTransferAddressType
	) public {
		require(_finalizeType == "transfer" || _finalizeType == "burn");
		
		if (_finalizeType == "transfer") {
			require(_finalizeTransferAddressType != "");
		} else if (_finalizeType == "burn") {
			require(_finalizeTransferAddressType == "");
		}
		
		finalizeType = _finalizeType;
		finalizeTransferAddressType = _finalizeTransferAddressType;
	}
	
	
	 
	function setToken (
		address _token
	) public onlyOwner returns (bool) {
		require(token == address(0));
		require(_token.isContract());
		
		token = UKTTokenBasic(_token);
		
		return true;
	}
	
	
	 
	function configureTokenParams(
		string _name,
		string _symbol,
		uint _totalSupply
	) public onlyOwner returns (bool) {
		require(token != address(0));
		return token.setConfiguration(_name, _symbol, _totalSupply);
	}
	
	
	 
	function allocateInitialBalances(
		address[] addresses,
		bytes32[] addressesTypes,
		uint[] amounts
	) public onlyOwner returns (bool) {
		require(token != address(0));
		return token.setInitialAllocation(addresses, addressesTypes, amounts);
	}
	
	
	 
	function lockAllocationAddress(
		address allocationAddress
	) public onlyOwner returns (bool) {
		require(token != address(0));
		token.setInitialAllocationLock(allocationAddress);
		lockedAddressesList.push(allocationAddress);
		return true;
	}
	
	
	 
	function unlockAllocationAddress(
		address allocationAddress
	) public onlyOwner returns (bool) {
		require(token != address(0));
		
		token.setInitialAllocationUnlock(allocationAddress);
		
		for (uint idx = 0; idx < lockedAddressesList.length; idx++) {
			if (lockedAddressesList[idx] == allocationAddress) {
				lockedAddressesList[idx] = address(0);
				break;
			}
		}
		
		return true;
	}
	
	
	 
	function unlockAllAllocationAddresses() public onlyOwner returns (bool) {
		for(uint a = 0; a < lockedAddressesList.length; a++) {
			if (lockedAddressesList[a] == address(0)) {
				continue;
			}
			unlockAllocationAddress(lockedAddressesList[a]);
		}
		
		return true;
	}
	
	
	 
	function timelockAllocationAddress(
		address allocationAddress,
		uint32 timelockTillDate
	) public onlyOwner returns (bool) {
		require(token != address(0));
		return token.setInitialAllocationTimelock(allocationAddress, timelockTillDate);
	}
	
	
	
	 
	function distribute(
		address[] addresses,
		uint[] amounts,
		bytes32[] trackingIds
	) public onlyOwner returns (bool) {
		require(token != address(0));
		 
		require(addresses.length < MAX_ADDRESSES_FOR_DISTRIBUTE);
		 
		require(addresses.length == amounts.length && addresses.length == trackingIds.length);
		
		for(uint a = 0; a < addresses.length; a++) {
			token.transfer(addresses[a], amounts[a]);
			emit Distributed(addresses[a], trackingIds[a], amounts[a]);
		}
		
		return true;
	}
	
	
	 
	function finalize() public onlyOwner {
		
		if (finalizeType == "transfer") {
			 
			token.transfer(
				token.allocationAddressesTypes(finalizeTransferAddressType),
				token.balanceOf(this)
			);
		} else if (finalizeType == "burn") {
			 
			token.burn(token.balanceOf(this));
		}
		
		require(unlockAllAllocationAddresses());
		
		removeOwnership();
		
		isFinalized = true;
		emit Finalized();
	}
	
}