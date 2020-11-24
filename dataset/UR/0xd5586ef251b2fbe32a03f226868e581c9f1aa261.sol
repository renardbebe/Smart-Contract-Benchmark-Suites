 

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

interface Token {
	function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

contract BrokerImp is DestroyableMultiOwner {
	using SafeMath for uint256;
	
	Token public token;
	uint256 public commission;
	address public broker;
	address public pool;
	uint256 public ethReward;
	mapping(address => bool) public ethSent;
	
	event CommissionChanged(uint256 _previousCommission, uint256 _commision);
	event EthRewardChanged(uint256 _previousEthReward, uint256 _ethReward);
	event BrokerChanged(address _previousBroker, address _broker);
	event PoolChanged(address _previousPool, address _pool);
	
	 
	function BrokerImp(address _token, address _pool, uint256 _commission, address _broker, uint256 _ethReward) public {
		require(_token != address(0));
		token = Token(_token);
		pool = _pool;
		commission = _commission;
		broker = _broker;
		ethReward = _ethReward;
	}
	
	 
	function fund(uint256 amount) payable public {
		require(msg.value == amount);
	}
	
	 
	function reward(address _beneficiary, uint256 _value) public onlyOwner returns (bool) {
		uint256 hundred = uint256(100);
		uint256 beneficiaryPart = hundred.sub(commission);
		uint256 total = (_value.div(beneficiaryPart)).mul(hundred);
		uint256 brokerCommission = total.sub(_value);
		if (!ethSent[_beneficiary]) {
			_beneficiary.transfer(ethReward);
			ethSent[_beneficiary] = true;
		}
		return (
		token.transferFrom(pool, broker, brokerCommission) &&
		token.transferFrom(pool, _beneficiary, _value)
		);
	}
	
	 
	function changeCommission(uint256 _commission) public onlyOwner {
		emit CommissionChanged(commission, _commission);
		commission = _commission;
	}
	
	 
	function changeEthReward(uint256 _ethReward) public onlyOwner {
		emit EthRewardChanged(ethReward, _ethReward);
		ethReward = _ethReward;
	}
	
	 
	function changeBroker(address _broker) public onlyOwner {
		emit BrokerChanged(broker, _broker);
		broker = _broker;
	}
	
	 
	function changePool(address _pool) public onlyOwner {
		emit PoolChanged(pool, _pool);
		pool = _pool;
	}
}