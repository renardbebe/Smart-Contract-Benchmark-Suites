 

pragma solidity ^0.4.24;

 
contract tokenFallback {
	uint256 public totalSupply;

	function balanceOf(address _owner) public constant returns (uint256 balance);
	function transfer(address _to, uint256 _value) public returns (bool success);
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
	function approve(address _spender, uint256 _value) public returns (bool success);
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TokenBurner {
	struct Claim {
		uint256[] amount;
		string[] pubkey;
	}

	struct BatchTime {
		uint256 blockNumber;
		uint256 eventCount;
	}

	 
	uint16 public AEdeliveryBatchCounter = 0;

	 
	address public AEdmin;
	address public AEToken;

	 
	modifier onlyAEdmin() {
		require (msg.sender == AEdmin);
		_;
	}

	mapping(address => Claim) burned;
	 
	uint256 public burnCount;
	 
	mapping(uint16 => BatchTime) public batchTimes;

	constructor(address _AEdmin, address _AEToken) public {
		require (_AEdmin != 0x0);
		AEdmin = _AEdmin;

		if (_AEToken == 0x0) {
			_AEToken = 0x5CA9a71B1d01849C0a95490Cc00559717fCF0D1d;  
		}

		AEToken = _AEToken;
	}

	 
	function checkAddress(bytes str) public pure returns (bool) {
		bytes memory ak = "ak_";
		bytes memory result = new bytes(3);
		for(uint i = 0; i < 3; i++) {
			result[i-0] = str[i];
		}
		return (keccak256(result) == keccak256(ak));
	}

	function receiveApproval(
			address _from,
			uint256 _value,
			address _token,
			bytes _pubkey
			) public returns (bool) {

		 
		require(msg.sender == AEToken);

		 

		 
		 
		 
		string memory pubKeyString = string(_pubkey);

		require (bytes(pubKeyString).length > 50 && bytes(pubKeyString).length < 70);
		require (checkAddress(_pubkey));

		require(tokenFallback(_token).transferFrom(_from, this, _value));
		burned[_from].pubkey.push(pubKeyString);  
		burned[_from].amount.push(_value);
		emit Burn(_from, _pubkey, _value, ++burnCount, AEdeliveryBatchCounter);
		return true;
	}

	function countUpDeliveryBatch()
		public onlyAEdmin
		{
			batchTimes[AEdeliveryBatchCounter].blockNumber = block.number;
			batchTimes[AEdeliveryBatchCounter].eventCount = burnCount;
			++AEdeliveryBatchCounter;
		}

	event Burn(address indexed _from, bytes _pubkey, uint256 _value, uint256 _count, uint16 indexed _deliveryPeriod);
}