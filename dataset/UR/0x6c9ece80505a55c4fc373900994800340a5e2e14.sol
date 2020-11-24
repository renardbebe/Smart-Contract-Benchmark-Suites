 

pragma solidity ^0.4.21;

 
 
contract ERC223Receiver {
	struct TKN {
		address sender;
		uint value;
		bytes data;
		bytes4 sig;
	}
	function tokenFallback(address _from, uint _value, bytes _data) public pure;
}

  
 
contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);

 
 
 
 
 

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
  
   
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract CGENToken is ERC223 {

	 
	 
	string public constant name = "Cryptanogen"; 
	string public constant symbol = "CGEN" ;
	uint8 public constant decimals = 8;

	 
	uint128 public availableSupply;

	 
	struct vesting {
		uint createdAt;
		uint128 amount;
		uint8 releaseRate;
		uint32 releaseIntervalSeconds;
		uint8 nextReleasePeriod;
		bool completed;
	}

	struct tokenAccount {
		uint128 vestedBalance;
		uint128 releasedBalance;
		vesting []vestingIndex; 
	}

	 
	mapping (address => tokenAccount) tokenAccountIndex;

	 
	address public owner;

	 
	uint creationTime;

	 
	 

	 
	 

	function CGENToken(uint _supply) public {
		totalSupply = _supply;
		availableSupply = uint128(totalSupply);
		require(uint(availableSupply) == totalSupply);
		owner = msg.sender;
		creationTime = now;
		emit Transfer(0x0, owner, _supply);
	}

	 
 
 
 


	 
	function vestToAddressEx(address _who, uint128 _amount, uint8 _divisor, uint32 _intervalSeconds) public returns(bool) {

		 
		vesting memory newVesting;

		 
		require(msg.sender == owner);

		 
		require(_amount > 0);
		require(_divisor <= 100 && _divisor > 0);
		require(_intervalSeconds > 0);

		 
		require(100 % _divisor == 0);

		 
		require(_amount <= availableSupply);

		newVesting.createdAt = now;
		newVesting.amount = _amount;
		newVesting.releaseRate = 100 / _divisor;
		newVesting.releaseIntervalSeconds = _intervalSeconds;
		newVesting.nextReleasePeriod = 0;
		newVesting.completed = false;
		tokenAccountIndex[_who].vestingIndex.push(newVesting);

		availableSupply -= _amount;
		tokenAccountIndex[_who].vestedBalance += _amount;
		emit Transfer(owner, _who, _amount);
		return true;
	}

	 
	 
	function checkRelease(address _who, uint _idx) public view returns(uint128) {
		vesting memory v;
		uint i;
		uint timespan;
		uint timestep;
		uint maxEligibleFactor;
		uint128 releaseStep;
		uint128 eligibleAmount;

		 
		require(tokenAccountIndex[_who].vestingIndex.length > _idx);
		v = tokenAccountIndex[_who].vestingIndex[_idx];
		if (v.completed) {
			return 0;
		}

		 
		 
		timespan = now - tokenAccountIndex[_who].vestingIndex[_idx].createdAt;
		timestep = tokenAccountIndex[_who].vestingIndex[_idx].releaseIntervalSeconds * 1 seconds;
		maxEligibleFactor = (timespan / timestep) * tokenAccountIndex[_who].vestingIndex[_idx].releaseRate;
		if (maxEligibleFactor > 100) {
			maxEligibleFactor = 100;
		}

		releaseStep = (tokenAccountIndex[_who].vestingIndex[_idx].amount * tokenAccountIndex[_who].vestingIndex[_idx].releaseRate) / 100;
		 
		for (i = tokenAccountIndex[_who].vestingIndex[_idx].nextReleasePeriod * tokenAccountIndex[_who].vestingIndex[_idx].releaseRate; i < maxEligibleFactor; i += tokenAccountIndex[_who].vestingIndex[_idx].releaseRate) {
			eligibleAmount += releaseStep;
		}

		return eligibleAmount;
	}

	 
	 
	function release(address _who, uint _idx) public returns(uint128) {
		vesting storage v;
		uint8 j;
		uint8 i;
		uint128 total;
		uint timespan;
		uint timestep;
		uint128 releaseStep;
		uint maxEligibleFactor;

		 
		 
		require(tokenAccountIndex[_who].vestingIndex.length > _idx);
		v = tokenAccountIndex[_who].vestingIndex[_idx];
		if (v.completed) {
			revert();
		}

		 
		 
		timespan = now - v.createdAt;
		timestep = v.releaseIntervalSeconds * 1 seconds;
		maxEligibleFactor = (timespan / timestep) * v.releaseRate;
		if (maxEligibleFactor > 100) {
			maxEligibleFactor = 100;
		}

		releaseStep = (v.amount * v.releaseRate) / 100;
		for (i = v.nextReleasePeriod * v.releaseRate; i < maxEligibleFactor; i += v.releaseRate) {
			total += releaseStep;
			j++;
		}
		tokenAccountIndex[_who].vestedBalance -= total;
		tokenAccountIndex[_who].releasedBalance += total;
		if (maxEligibleFactor == 100) {
			v.completed = true;
		} else {
			v.nextReleasePeriod += j;
		}
		return total;
	}

	 
	function getVestingAmount(address _who, uint _idx) public view returns (uint128) {
		return tokenAccountIndex[_who].vestingIndex[_idx].amount;
	}

	function getVestingReleaseRate(address _who, uint _idx) public view returns (uint8) {
		return tokenAccountIndex[_who].vestingIndex[_idx].releaseRate;
	}

	function getVestingReleaseInterval(address _who, uint _idx) public view returns(uint32) {
		return tokenAccountIndex[_who].vestingIndex[_idx].releaseIntervalSeconds;
	}

	function getVestingCreatedAt(address _who, uint _idx) public view returns(uint) {
		return tokenAccountIndex[_who].vestingIndex[_idx].createdAt;
	}

	function getVestingsCount(address _who) public view returns(uint) {
		return tokenAccountIndex[_who].vestingIndex.length;
	}

	function vestingIsCompleted(address _who, uint _idx) public view returns(bool) {
		require(tokenAccountIndex[_who].vestingIndex.length > _idx);

		return tokenAccountIndex[_who].vestingIndex[_idx].completed;
	}

	 
	function transfer(address _to, uint256 _value, bytes _data, string _custom_callback_unimplemented) public returns(bool) {
		uint128 shortValue;

		 
		require(_to != owner);
		require(msg.sender != owner);
	
		 
		 
		shortValue = uint128(_value);
		require(uint(shortValue) == _value);

		 
		require(tokenAccountIndex[msg.sender].releasedBalance >= shortValue);

		 
		tokenAccountIndex[msg.sender].releasedBalance -= shortValue;
		tokenAccountIndex[_to].releasedBalance += shortValue;

		 
		if (isContract(_to)) {
			ERC223Receiver receiver = ERC223Receiver(_to);
			receiver.tokenFallback(msg.sender, _value, _data);
		}
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	 
	function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
		return transfer(_to, _value, _data, "");
	}

	 
	function transfer(address _to, uint256 _value) public returns (bool) {
		bytes memory empty;
		return transfer(_to, _value, empty, "");
	}

	 
	 
	function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
		return false;
	}

	 
	 
	function approve(address _spender, uint256 _value) public returns(bool) {
		return false;
	}

	 
	 
	function allowance(address _owner, address _spender) public view returns(uint256) {
		return 0;
	}

	 
	function vestedBalanceOf(address _who) public view returns (uint) {
		return uint(tokenAccountIndex[_who].vestedBalance);
	}

	 
	 
	 
	function balanceOf(address _who) public view returns (uint) {
		if (_who == owner) {
			return availableSupply;
		}
		return uint(tokenAccountIndex[_who].vestedBalance + tokenAccountIndex[_who].releasedBalance);
	}

	 
	function isContract(address _addr) private view returns (bool) {
		uint l;

		 
		assembly {
			l := extcodesize(_addr)
		}
		return (l > 0);
	}
}