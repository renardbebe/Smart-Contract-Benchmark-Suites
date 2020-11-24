 

pragma solidity 0.4.24;
 
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


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
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

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 
contract EmcoToken is StandardToken, Ownable {

	string public constant name = "EmcoToken";
	string public constant symbol = "EMCO";
	uint8 public constant decimals = 18;

	uint public constant INITIAL_SUPPLY = 1500000 * (10 ** uint(decimals));
	uint public constant MAX_SUPPLY = 36000000 * (10 ** uint(decimals));

	mapping (address => uint) public miningBalances;
	mapping (address => uint) public lastMiningBalanceUpdateTime;

	address systemAddress;

	uint public constant DAY_MINING_DEPOSIT_LIMIT = 360000 * (10 ** uint(decimals));
	uint public constant TOTAL_MINING_DEPOSIT_LIMIT = 3600000 * (10 ** uint(decimals));
	uint currentDay;
	uint currentDayDeposited;
	uint public miningTotalDeposited;

	mapping(address => bytes32) public userReferralCodes;
	mapping(bytes32 => address) public referralCodeOwners;
	mapping(address => address) public referrals;

	event Mine(address indexed beneficiary, uint value);

	event MiningBalanceUpdated(address indexed owner, uint amount, bool isDeposit);

	constructor() public {
		balances[msg.sender] = INITIAL_SUPPLY;
		systemAddress = msg.sender;
		totalSupply_ = INITIAL_SUPPLY;
		emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
	}

	function setReferralCode(bytes32 _code) public returns (bytes32) {
		require(_code != "", "Ref code should not be empty");
		require(referralCodeOwners[_code] == address(0), "This referral code is already used");
		require(userReferralCodes[msg.sender] == "", "Referal code is already set");
		userReferralCodes[msg.sender] = _code;
		referralCodeOwners[_code] = msg.sender;
		return userReferralCodes[msg.sender];
	}

	function setReferral(bytes32 _code) public {
		require(referralCodeOwners[_code] != address(0), "Invalid referral code");
		require(referrals[msg.sender] == address(0), "You already have a referrer");
		address referrer = referralCodeOwners[_code];
		require(referrer != msg.sender, "Can not invite yourself");
		referrals[msg.sender] = referrer;
	}

	 
	function balanceOf(address _owner) public view returns (uint balance) {
		return balances[_owner].add(miningBalances[_owner]);
	}

	 
	function miningBalanceOf(address _owner) public view returns (uint balance) {
		return miningBalances[_owner];
	}

	 
	function depositToMiningBalance(uint _amount) public {
		require(balances[msg.sender] >= _amount, "not enough tokens");
		require(getCurrentDayDeposited().add(_amount) <= DAY_MINING_DEPOSIT_LIMIT,
			"Day mining deposit exceeded");
		require(miningTotalDeposited.add(_amount) <= TOTAL_MINING_DEPOSIT_LIMIT,
			"Total mining deposit exceeded");

		balances[msg.sender] = balances[msg.sender].sub(_amount);
		miningBalances[msg.sender] = miningBalances[msg.sender].add(_amount);
		miningTotalDeposited = miningTotalDeposited.add(_amount);
		updateCurrentDayDeposited(_amount);
		lastMiningBalanceUpdateTime[msg.sender] = now;
		emit MiningBalanceUpdated(msg.sender, _amount, true);
	}

	 
	function withdrawFromMiningBalance(uint _amount) public {
		require(miningBalances[msg.sender] >= _amount, "not enough tokens on mining balance");

		miningBalances[msg.sender] = miningBalances[msg.sender].sub(_amount);
		balances[msg.sender] = balances[msg.sender].add(_amount);

		 
		miningTotalDeposited.sub(_amount);
		lastMiningBalanceUpdateTime[msg.sender] = now;
		emit MiningBalanceUpdated(msg.sender, _amount, false);
	}

	  
	function mine() public {
		require(totalSupply_ < MAX_SUPPLY, "mining is over");
		uint reward = getReward(totalSupply_);
		uint daysForReward = getDaysForReward();

		uint mintedAmount = miningBalances[msg.sender].mul(reward.sub(1000000000))
										.mul(daysForReward).div(100000000000);
		require(mintedAmount != 0, "mining will not produce any reward");

		uint amountToBurn = miningBalances[msg.sender].mul(daysForReward).div(100);

		 
		if(totalSupply_.add(mintedAmount) > MAX_SUPPLY) {
			uint availableToMint = MAX_SUPPLY.sub(totalSupply_);
			amountToBurn = availableToMint.div(mintedAmount).mul(amountToBurn);
			mintedAmount = availableToMint;
		}

		totalSupply_ = totalSupply_.add(mintedAmount);

		miningBalances[msg.sender] = miningBalances[msg.sender].sub(amountToBurn);
		balances[msg.sender] = balances[msg.sender].add(amountToBurn);

		uint userReward;
		uint referrerReward = 0;
		address referrer = referrals[msg.sender];
		
		if(referrer == address(0)) {
			userReward = mintedAmount.mul(85).div(100);
		} else {
			userReward = mintedAmount.mul(86).div(100);
			referrerReward = mintedAmount.div(100);
			balances[referrer] = balances[referrer].add(referrerReward);
			emit Mine(referrer, referrerReward);
			emit Transfer(address(0), referrer, referrerReward);
		}
		balances[msg.sender] = balances[msg.sender].add(userReward);

		emit Mine(msg.sender, userReward);
		emit Transfer(address(0), msg.sender, userReward);

		 
		miningTotalDeposited = miningTotalDeposited.sub(amountToBurn);
		emit MiningBalanceUpdated(msg.sender, amountToBurn, false);

		 
		uint systemFee = mintedAmount.sub(userReward).sub(referrerReward);
		balances[systemAddress] = balances[systemAddress].add(systemFee);

		emit Mine(systemAddress, systemFee);
		emit Transfer(address(0), systemAddress, systemFee);

		lastMiningBalanceUpdateTime[msg.sender] = now;
	}

	 
	function setSystemAddress(address _systemAddress) public onlyOwner {
		systemAddress = _systemAddress;
	}

	 
	function getCurrentDayDeposited() public view returns (uint) {
		if(now / 1 days == currentDay) {
			return currentDayDeposited;
		} else {
			return 0;
		}
	}

	 
	function getDaysForReward() public view returns (uint rewardDaysNum){
		if(lastMiningBalanceUpdateTime[msg.sender] == 0) {
			return 0;
		} else {
			uint value = (now - lastMiningBalanceUpdateTime[msg.sender]) / (1 days);
			if(value > 100) {
				return 100;
			} else {
				return value;
			}
		}
	}

	 
	function getReward(uint _totalSupply) public pure returns (uint rewardPercent){
		uint rewardFactor = 1000000 * (10 ** uint256(decimals));
		uint decreaseFactor = 41666666;

		if(_totalSupply < 23 * rewardFactor) {
			return 2000000000 - (decreaseFactor.mul(_totalSupply.div(rewardFactor)));
		}

		if(_totalSupply < MAX_SUPPLY) {
			return 1041666666;
		} else {
			return 1000000000;
		} 
	}

	function updateCurrentDayDeposited(uint _addedTokens) private {
		if(now / 1 days == currentDay) {
			currentDayDeposited = currentDayDeposited.add(_addedTokens);
		} else {
			currentDay = now / 1 days;
			currentDayDeposited = _addedTokens;
		}
	}

}