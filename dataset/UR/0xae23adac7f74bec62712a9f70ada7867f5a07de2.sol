 

pragma solidity ^0.4.17;

contract MultiKeyDailyLimitWallet {
	uint constant LIMIT_PRECISION = 1000000;
	 
	mapping(address=>uint) public credentials;
	 
	uint public lastWithdrawalTime;
	 
	uint public dailyCount;
	uint public nonce;

	event OnWithdrawTo(address indexed from, address indexed to, uint amount,
		uint64 timestamp);

	function MultiKeyDailyLimitWallet(address[] keys, uint[] limits) public {
		require(keys.length == limits.length);
		for (uint i = 0; i < keys.length; i++) {
			var limit = limits[i];
			 
			require (limit > 0 && limit <= LIMIT_PRECISION);
			credentials[keys[i]] = limit;
		}
	}

	 

	function getRemainingLimit(address key) public view returns (uint) {
		var pct = credentials[key];
		if (pct == 0)
			return 0;

		var _dailyCount = dailyCount;
		if ((block.timestamp - lastWithdrawalTime) >= 1 days)
			_dailyCount = 0;

		var amt = ((this.balance + _dailyCount) * pct) / LIMIT_PRECISION;
		if (amt == 0 && this.balance > 0)
			amt = 1;
		if (_dailyCount >= amt)
			return 0;
		return amt - _dailyCount;
	}

	function withdrawTo(uint amount, address to, bytes signature) public {
		require(amount > 0 && to != address(this));
		assert(block.timestamp >= lastWithdrawalTime);

		var limit = getSignatureRemainingLimit(signature,
			keccak256(address(this), nonce, amount, to));
		require(limit >= amount);
		require(this.balance >= amount);

		 
		if ((block.timestamp - lastWithdrawalTime) >= 1 days)
			dailyCount = 0;

		lastWithdrawalTime = block.timestamp;
		dailyCount += amount;
		nonce++;
		to.transfer(amount);
		OnWithdrawTo(msg.sender, to, amount, uint64(block.timestamp));
	}

	function getSignatureRemainingLimit(bytes signature, bytes32 payload)
			private view returns (uint) {

		var addr = extractSignatureAddress(signature, payload);
		return getRemainingLimit(addr);
	}

	function extractSignatureAddress(bytes signature, bytes32 payload)
			private pure returns (address) {

		payload = keccak256("\x19Ethereum Signed Message:\n32", payload);
		bytes32 r;
		bytes32 s;
		uint8 v;
		assembly {
			r := mload(add(signature, 32))
			s := mload(add(signature, 64))
			v := and(mload(add(signature, 65)), 255)
		}
		if (v < 27)
			v += 27;
		require(v == 27 || v == 28);
		return ecrecover(payload, v, r, s);
	}

	function() public payable {}
}