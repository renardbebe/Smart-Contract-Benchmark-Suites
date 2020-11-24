 

pragma solidity 0.4.25;
 
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

contract EmcoTokenInterface is ERC20 {

    function setReferral(bytes32 _code) public;
    function setReferralCode(bytes32 _code) public view returns (bytes32);

    function referralCodeOwners(bytes32 _code) public view returns (address);
    function referrals(address _address) public view returns (address);
    function userReferralCodes(address _address) public view returns (bytes32);

}

 
contract Clan is Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public rewards;
    mapping(uint256 => uint256) public epochRewards;
    mapping(address => uint256) public epochJoined;
    mapping(uint => uint256) private membersNumForEpoch;

    mapping(address => mapping(uint => bool)) public reclaimedRewards;

    uint public lastMembersNumber = 0;

    event UserJoined(address userAddress);
    event UserLeaved(address userAddress);

    uint public startBlock;
    uint public epochLength;

    uint public ownersReward;

    EmcoToken emco;

    address public clanOwner;

    constructor(address _clanOwner, address _emcoToken, uint256 _epochLength) public {
        clanOwner = _clanOwner;
        startBlock = block.number;
        epochLength = _epochLength; 
        emco = EmcoToken(_emcoToken);
    }

    function replenish(uint amount) public onlyOwner {
         
         
        uint currentEpoch = getCurrentEpoch();
        if(membersNumForEpoch[currentEpoch] == 0) {
            membersNumForEpoch[currentEpoch] = lastMembersNumber;
        }
        uint ownersPart;
        if(membersNumForEpoch[currentEpoch] == 0) {
             
            ownersPart = amount;
        } else {
            ownersPart = amount.div(10);
            epochRewards[currentEpoch] = epochRewards[currentEpoch].add(amount - ownersPart);
        }
        ownersReward = ownersReward.add(ownersPart);
    }

    function getMembersForEpoch(uint epochNumber) public view returns (uint membersNumber) {
        return membersNumForEpoch[epochNumber];
    }

    function getCurrentEpoch() public view returns (uint256) {
        return (block.number - startBlock) / epochLength; 
    }

     
    function join(address user) public onlyOwner {
        emit UserJoined(user);
        uint currentEpoch = getCurrentEpoch();
        epochJoined[user] = currentEpoch + 1;

         
        uint currentMembersNum = lastMembersNumber;
        if(currentMembersNum == 0) {
            membersNumForEpoch[currentEpoch + 1] = currentMembersNum + 1;
        } else {
            membersNumForEpoch[currentEpoch + 1] = membersNumForEpoch[currentEpoch + 1] + 1;
        }
         
        lastMembersNumber = membersNumForEpoch[currentEpoch + 1];
    }

    function leaveClan(address user) public onlyOwner {
        epochJoined[user] = 0;
        emit UserLeaved(user);

         
        uint currentEpoch = getCurrentEpoch();
        uint currentMembersNum = lastMembersNumber;
        if(currentMembersNum != 0) {
            membersNumForEpoch[currentEpoch + 1] = membersNumForEpoch[currentEpoch + 1] - 1;
        } 
         
        lastMembersNumber = membersNumForEpoch[currentEpoch + 1];
    }

    function calculateReward(uint256 epoch) public view returns (uint256) {
        return epochRewards[epoch].div(membersNumForEpoch[epoch]);
    }

    function reclaimOwnersReward() public {
        require(msg.sender == clanOwner);
        emco.transfer(msg.sender, ownersReward);
        ownersReward = 0;
    }

     
    function reclaimReward(uint256 epoch) public {
        uint currentEpoch = getCurrentEpoch();
        require(currentEpoch > epoch);
        require(epochJoined[msg.sender] != 0);
        require(epochJoined[msg.sender] <= epoch);
        require(reclaimedRewards[msg.sender][epoch] == false);

        uint userReward = calculateReward(epoch);
        require(userReward > 0);

        require(emco.transfer(msg.sender, userReward));
        reclaimedRewards[msg.sender][epoch] = true;
    }

}

 
contract EmcoToken is StandardToken, Ownable {

    string public constant name = "EmcoToken";
    string public constant symbol = "EMCO";
    uint8 public constant decimals = 18;

     
    uint public constant MAX_SUPPLY = 36000000 * (10 ** uint(decimals));

    mapping (address => uint) public miningBalances;
    mapping (address => uint) public lastMiningBalanceUpdateTime;

     
    mapping (address => address) public joinedClans;
    mapping (address => address) public userClans;
    mapping (address => bool) public clanRegistry;
    mapping (address => uint256) public inviteeCount;

    address systemAddress;

    EmcoTokenInterface private oldContract;

    uint public constant DAY_MINING_DEPOSIT_LIMIT = 360000 * (10 ** uint(decimals));
    uint public constant TOTAL_MINING_DEPOSIT_LIMIT = 3600000 * (10 ** uint(decimals));
    uint currentDay;
    uint currentDayDeposited;
    uint public miningTotalDeposited;

    mapping(address => bytes32) private userRefCodes;
    mapping(bytes32 => address) private refCodeOwners;
    mapping(address => address) private refs;

    event Mine(address indexed beneficiary, uint value);

    event MiningBalanceUpdated(address indexed owner, uint amount, bool isDeposit);

    event Migrate(address indexed user, uint256 amount);

    event TransferComment(address indexed to, uint256 amount, bytes comment);

    event SetReferral(address whoSet, address indexed referrer);

    constructor(address emcoAddress) public {
        systemAddress = msg.sender;
        oldContract = EmcoTokenInterface(emcoAddress);
    }

    function migrate(uint _amount) public {
        require(oldContract.transferFrom(msg.sender, this, _amount));
        totalSupply_ = totalSupply_.add(_amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);
        emit Migrate(msg.sender, _amount);
        emit Transfer(address(0), msg.sender, _amount);
    }

    function setReferralCode(bytes32 _code) public returns (bytes32) {
        require(_code != "");
        require(refCodeOwners[_code] == address(0));
        require(oldContract.referralCodeOwners(_code) == address(0));
        require(userReferralCodes(msg.sender) == "");
        userRefCodes[msg.sender] = _code;
        refCodeOwners[_code] = msg.sender;
        return _code;
    }

    function referralCodeOwners(bytes32 _code) public view returns (address owner) {
        address refCodeOwner = refCodeOwners[_code];
        if(refCodeOwner == address(0)) {
            return oldContract.referralCodeOwners(_code);
        } else {
            return refCodeOwner;
        }
    }

    function userReferralCodes(address _address) public view returns (bytes32) {
        bytes32 code = oldContract.userReferralCodes(_address);
        if(code != "") {
            return code;
        } else {
            return userRefCodes[_address];
        }
    }

    function referrals(address _address) public view returns (address) {
        address refInOldContract = oldContract.referrals(_address);
        if(refInOldContract != address(0)) {
            return refInOldContract;
        } else {
            return refs[_address];
        }
    }

    function setReferral(bytes32 _code) public {
        require(refCodeOwners[_code] != address(0));
        require(referrals(msg.sender) == address(0));
        require(oldContract.referrals(msg.sender) == address(0));
        address referrer = refCodeOwners[_code];
        require(referrer != msg.sender, "Can not invite yourself");
        refs[msg.sender] = referrer;
        inviteeCount[referrer] = inviteeCount[referrer].add(1);
        emit SetReferral(msg.sender, referrer);
    }

    function transferWithComment(address _to, uint256 _value, bytes _comment) public returns (bool) {
        emit TransferComment(_to, _value, _comment);
        return transfer(_to, _value);
    }

	 
    function createClan(uint256 epochLength) public returns (address clanAddress) {
        require(epochLength >= 175200);  
		 
        require(userClans[msg.sender] == address(0x0));
		 
        require(inviteeCount[msg.sender] >= 10);

		 
        Clan clan = new Clan(msg.sender, this, epochLength);

		 
        userClans[msg.sender] = clan;
        clanRegistry[clan] = true;
        return clan;
    }

	function joinClan(address clanAddress) public {
		 
		require(clanRegistry[clanAddress]);
		require(joinedClans[msg.sender] == address(0x0));

		 
		Clan clan = Clan(clanAddress);
		clan.join(msg.sender);

		 
		joinedClans[msg.sender] = clanAddress;
	}

	function leaveClan() public {
		address clanAddress = joinedClans[msg.sender];
		require(clanAddress != address(0x0));

		Clan clan = Clan(clanAddress);
		clan.leaveClan(msg.sender);

		 
		joinedClans[msg.sender] = address(0x0);
	}

	 
	function updateInviteesCount(address invitee, uint256 count) public onlyOwner {
		inviteeCount[invitee] = count;
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
		require(miningBalances[msg.sender] >= _amount, "not enough mining tokens");

		miningBalances[msg.sender] = miningBalances[msg.sender].sub(_amount);
		balances[msg.sender] = balances[msg.sender].add(_amount);

		 
		miningTotalDeposited = miningTotalDeposited.sub(_amount);
		lastMiningBalanceUpdateTime[msg.sender] = now;
		emit MiningBalanceUpdated(msg.sender, _amount, false);
	}

	  
	function mine() public {
		require(totalSupply_ < MAX_SUPPLY, "mining is over");
		uint reward = getReward(totalSupply_);
		uint daysForReward = getDaysForReward();

		uint mintedAmount = miningBalances[msg.sender].mul(reward.sub(1000000000))
										.mul(daysForReward).div(100000000000);
		require(mintedAmount != 0);

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
		address referrer = referrals(msg.sender);
		
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

		 
		mintClanReward(mintedAmount.mul(5).div(1000));
	}

	function mintClanReward(uint reward) private {
		 
		address clanAddress = joinedClans[msg.sender];
		if(clanAddress != address(0x0)) {
			 
			require(clanRegistry[clanAddress], "clan is not registered");

			 
			balances[clanAddress] = balances[clanAddress].add(reward);
			Clan clan = Clan(clanAddress);
			clan.replenish(reward);
			totalSupply_ = totalSupply_.add(reward);
		}
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