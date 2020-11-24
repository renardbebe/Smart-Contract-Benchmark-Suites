 

pragma solidity ^0.4.21;
 

 
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
}

 

 
contract MultiOwnable {
	
	address[] public owners;
	mapping(address => bool) public isOwner;
	
	event OwnerAddition(address indexed owner);
	event OwnerRemoval(address indexed owner);
	
	 
	function MultiOwnable() public {
		isOwner[msg.sender] = true;
		owners.push(msg.sender);
	}
	
	 
	modifier onlyOwner() {
		require(isOwner[msg.sender]);
		_;
	}
	
	 
	modifier ownerDoesNotExist(address _owner) {
		require(!isOwner[_owner]);
		_;
	}
	
	 
	modifier ownerExists(address _owner) {
		require(isOwner[_owner]);
		_;
	}
	
	 
	modifier notNull(address _address) {
		require(_address != 0);
		_;
	}
	
	 
	function addOwner(address _owner)
	public
	onlyOwner
	ownerDoesNotExist(_owner)
	notNull(_owner)
	{
		isOwner[_owner] = true;
		owners.push(_owner);
		emit OwnerAddition(_owner);
	}
	
	 
	function removeOwner(address _owner)
	public
	onlyOwner
	ownerExists(_owner)
	{
		isOwner[_owner] = false;
		for (uint i = 0; i < owners.length - 1; i++)
			if (owners[i] == _owner) {
				owners[i] = owners[owners.length - 1];
				break;
			}
		owners.length -= 1;
		emit OwnerRemoval(_owner);
	}
	
}

contract DestroyableMultiOwner is MultiOwnable {
	 
	function destroy() public onlyOwner {
		selfdestruct(owners[0]);
	}
}

interface BrokerImp {
	function reward(address _beneficiary, uint256 _value) external returns (bool);
}

contract BrokerInt is MultiOwnable, DestroyableMultiOwner {
	using SafeMath for uint256;
	
	BrokerImp public brokerImp;
	
	event BrokerImpChanged(address _previousBrokerImp, address _brokerImp);
	event Reward(address _to, uint256 _value);
	
	 
	function BrokerInt(address _brokerImp) public{
		require(_brokerImp != address(0));
		brokerImp = BrokerImp(_brokerImp);
	}
	
	 
	function reward(address _beneficiary, uint256 _value) public onlyOwner {
		require(brokerImp.reward(_beneficiary, _value));
		emit Reward(_beneficiary, _value);
	}
	
	 
	function changeBrokerImp(address _brokerImp) public onlyOwner {
		emit BrokerImpChanged(brokerImp, _brokerImp);
		brokerImp = BrokerImp(_brokerImp);
	}
}