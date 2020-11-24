 

pragma solidity 0.4.24;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
    uint256 _addedValue
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
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
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


contract SparksterToken is StandardToken, Ownable{
	using SafeMath for uint256;
	struct Member {
		mapping(uint256 => uint256) weiBalance;  
	}

	struct Group {
		bool distributed;  
		bool distributing;  
		bool unlocked;  
		mapping(address => bool) exists;  
		string name;
		uint256 ratio;  
		uint256 startTime;  
		uint256 phase1endTime;  
		uint256 phase2endTime;  
		uint256 deadline;  
		uint256 max2;  
		uint256 max3;  
		uint256 weiTotal;  
		uint256 cap;  
		uint256 nextDistributionIndex;  
		address[] addresses;  
	}

	address oracleAddress;
	bool public transferLock = true;  
	bool public allowedToBuyBack = false;
	bool public allowedToPurchase = false;
	string public name;									  
	string public symbol;								  
	uint8 public decimals;							 
	uint256 public penalty;
	uint256 public maxGasPrice;  
	uint256 internal nextGroupNumber;
	uint256 public sellPrice;  
	mapping(address => Member) internal members;
	mapping(uint256 => Group) internal groups;
	uint256 public openGroupNumber;
	event WantsToPurchase(address walletAddress, uint256 weiAmount, uint256 groupNumber, bool inPhase1);
	event PurchasedCallbackOnAccept(uint256 groupNumber, address[] addresses);
	event WantsToDistribute(uint256 groupNumber);
	event NearingHardCap(uint256 groupNumber, uint256 remainder);
	event ReachedHardCap(uint256 groupNumber);
	event DistributeDone(uint256 groupNumber);
	event DistributedBatch(uint256 groupNumber, uint256 howMany);
	event AirdroppedBatch(address[] addresses);
	event RefundedBatch(address[] addresses);
	event AddToGroup(address walletAddress, uint256 groupNumber);
	event ChangedTransferLock(bool transferLock);
	event ChangedAllowedToPurchase(bool allowedToPurchase);
	event ChangedAllowedToBuyBack(bool allowedToBuyBack);
	event SetSellPrice(uint256 sellPrice);
	
	modifier onlyOwnerOrOracle() {
		require(msg.sender == owner || msg.sender == oracleAddress);
		_;
	}
	
	 
	modifier onlyPayloadSize(uint size) {	 
		require(msg.data.length == size + 4);
		_;
	}

	modifier canTransfer() {
		if (msg.sender != owner) {
			require(!transferLock);
		}
		_;
	}

	modifier canPurchase() {
		require(allowedToPurchase);
		_;
	}

	modifier canSell() {
		require(allowedToBuyBack);
		_;
	}

	function() public payable {
		purchase();
	}

	constructor() public {
		name = "Sparkster";									 
		decimals = 18;					  
		symbol = "SPRK";							 
		setMaximumGasPrice(40);
		mintTokens(435000000);
	}
	
	function setOracleAddress(address newAddress) public onlyOwner returns(bool success) {
		oracleAddress = newAddress;
		return true;
	}

	function removeOracleAddress() public onlyOwner {
		oracleAddress = address(0);
	}

	function setMaximumGasPrice(uint256 gweiPrice) public onlyOwner returns(bool success) {
		maxGasPrice = gweiPrice.mul(10**9);  
		return true;
	}

	function mintTokens(uint256 amount) public onlyOwner {
		 
		uint256 decimalAmount = amount.mul(uint(10)**decimals);
		totalSupply_ = totalSupply_.add(decimalAmount);
		balances[msg.sender] = balances[msg.sender].add(decimalAmount);
		emit Transfer(address(0), msg.sender, decimalAmount);  
	}

	function purchase() public canPurchase payable returns(bool success) {
		require(msg.sender != address(0));  
		Member storage memberRecord = members[msg.sender];
		Group storage openGroup = groups[openGroupNumber];
		require(openGroup.ratio > 0);  
		uint256 currentTimestamp = block.timestamp;
		require(currentTimestamp >= openGroup.startTime && currentTimestamp <= openGroup.deadline);																  
		require(!openGroup.distributing && !openGroup.distributed);  
		require(tx.gasprice <= maxGasPrice);  
		uint256 weiAmount = msg.value;																		 
		require(weiAmount >= 0.1 ether);
		uint256 weiTotal = openGroup.weiTotal.add(weiAmount);  
		require(weiTotal <= openGroup.cap);														 
		uint256 userWeiTotal = memberRecord.weiBalance[openGroupNumber].add(weiAmount);	 
		if (!openGroup.exists[msg.sender]) {  
			openGroup.addresses.push(msg.sender);
			openGroup.exists[msg.sender] = true;
		}
		if(currentTimestamp <= openGroup.phase1endTime){																			  
			emit WantsToPurchase(msg.sender, weiAmount, openGroupNumber, true);
			return true;
		} else if (currentTimestamp <= openGroup.phase2endTime) {  
			require(userWeiTotal <= openGroup.max2);  
			emit WantsToPurchase(msg.sender, weiAmount, openGroupNumber, false);
			return true;
		} else {  
			require(userWeiTotal <= openGroup.max3);  
			emit WantsToPurchase(msg.sender, weiAmount, openGroupNumber, false);
			return true;
		}
	}
	
	function purchaseCallbackOnAccept(uint256 groupNumber, address[] addresses, uint256[] weiAmounts) public onlyOwnerOrOracle returns(bool success) {
		uint256 n = addresses.length;
		require(n == weiAmounts.length, "Array lengths mismatch");
		Group storage theGroup = groups[groupNumber];
		uint256 weiTotal = theGroup.weiTotal;
		for (uint256 i = 0; i < n; i++) {
			Member storage memberRecord = members[addresses[i]];
			uint256 weiAmount = weiAmounts[i];
			weiTotal = weiTotal.add(weiAmount);								  
			memberRecord.weiBalance[groupNumber] = memberRecord.weiBalance[groupNumber].add(weiAmount);														  
		}
		theGroup.weiTotal = weiTotal;
		if (getHowMuchUntilHardCap_(groupNumber) <= 100 ether) {
			emit NearingHardCap(groupNumber, getHowMuchUntilHardCap_(groupNumber));
			if (weiTotal >= theGroup.cap) {
				emit ReachedHardCap(groupNumber);
			}
		}
		emit PurchasedCallbackOnAccept(groupNumber, addresses);
		return true;
	}

	function insertAndApprove(uint256 groupNumber, address[] addresses, uint256[] weiAmounts) public onlyOwnerOrOracle returns(bool success) {
		uint256 n = addresses.length;
		require(n == weiAmounts.length, "Array lengtsh mismatch");
		Group storage theGroup = groups[groupNumber];
		for (uint256 i = 0; i < n; i++) {
			address theAddress = addresses[i];
			if (!theGroup.exists[theAddress]) {
				theGroup.addresses.push(theAddress);
				theGroup.exists[theAddress] = true;
			}
		}
		return purchaseCallbackOnAccept(groupNumber, addresses, weiAmounts);
	}

	function callbackInsertApproveAndDistribute(uint256 groupNumber, address[] addresses, uint256[] weiAmounts) public onlyOwnerOrOracle returns(bool success) {
		uint256 n = addresses.length;
		require(n == weiAmounts.length, "Array lengths mismatch");
		Group storage theGroup = groups[groupNumber];
		if (!theGroup.distributing) {
			theGroup.distributing = true;
		}
		uint256 newOwnerSupply = balances[owner];
		for (uint256 i = 0; i < n; i++) {
			address theAddress = addresses[i];
			Member storage memberRecord = members[theAddress];
			uint256 weiAmount = weiAmounts[i];
			memberRecord.weiBalance[groupNumber] = memberRecord.weiBalance[groupNumber].add(weiAmount);														  
			uint256 additionalBalance = weiAmount.mul(theGroup.ratio);  
			if (additionalBalance > 0) {  
				balances[theAddress] = balances[theAddress].add(additionalBalance);
				newOwnerSupply = newOwnerSupply.sub(additionalBalance);  
				emit Transfer(owner, theAddress, additionalBalance);  
			}
		}
		balances[owner] = newOwnerSupply;
		emit PurchasedCallbackOnAccept(groupNumber, addresses);
		return true;
	}

	function refund(address[] addresses, uint256[] weiAmounts) public onlyOwnerOrOracle returns(bool success) {
		uint256 n = addresses.length;
		require (n == weiAmounts.length, "Array lengths mismatch");
		uint256 thePenalty = penalty;
		for(uint256 i = 0; i < n; i++) {
			uint256 weiAmount = weiAmounts[i];
			address theAddress = addresses[i];
			if (thePenalty <= weiAmount) {
				weiAmount = weiAmount.sub(thePenalty);
				require(address(this).balance >= weiAmount);
				theAddress.transfer(weiAmount);
			}
		}
		emit RefundedBatch(addresses);
		return true;
	}

	function signalDoneDistributing(uint256 groupNumber) public onlyOwnerOrOracle {
		Group storage theGroup = groups[groupNumber];
		theGroup.distributed = true;
		theGroup.distributing = false;
		emit DistributeDone(groupNumber);
	}
	
	function drain() public onlyOwner {
		owner.transfer(address(this).balance);
	}
	
	function setPenalty(uint256 newPenalty) public onlyOwner returns(bool success) {
		penalty = newPenalty;
		return true;
	}
	
	function buyback(uint256 amount) public canSell {  
		uint256 decimalAmount = amount.mul(uint(10)**decimals);  
		require(balances[msg.sender].sub(decimalAmount) >= getLockedTokens_(msg.sender));  
		balances[msg.sender] = balances[msg.sender].sub(decimalAmount);  
		 
		uint256 totalCost = amount.mul(sellPrice);  
		require(address(this).balance >= totalCost);  
		balances[owner] = balances[owner].add(decimalAmount);  
		msg.sender.transfer(totalCost);  
		emit Transfer(msg.sender, owner, decimalAmount);  
	}

	function fundContract() public onlyOwnerOrOracle payable {  
	}

	function setSellPrice(uint256 thePrice) public onlyOwner {
		sellPrice = thePrice;
	}
	
	function setAllowedToBuyBack(bool value) public onlyOwner {
		allowedToBuyBack = value;
		emit ChangedAllowedToBuyBack(value);
	}

	function setAllowedToPurchase(bool value) public onlyOwner {
		allowedToPurchase = value;
		emit ChangedAllowedToPurchase(value);
	}
	
	function createGroup(string groupName, uint256 startEpoch, uint256 phase1endEpoch, uint256 phase2endEpoch, uint256 deadlineEpoch, uint256 phase2weiCap, uint256 phase3weiCap, uint256 hardWeiCap, uint256 ratio) public onlyOwner returns (bool success, uint256 createdGroupNumber) {
		createdGroupNumber = nextGroupNumber;
		Group storage theGroup = groups[createdGroupNumber];
		theGroup.name = groupName;
		theGroup.startTime = startEpoch;
		theGroup.phase1endTime = phase1endEpoch;
		theGroup.phase2endTime = phase2endEpoch;
		theGroup.deadline = deadlineEpoch;
		theGroup.max2 = phase2weiCap;
		theGroup.max3 = phase3weiCap;
		theGroup.cap = hardWeiCap;
		theGroup.ratio = ratio;
		nextGroupNumber++;
		success = true;
	}

	function getGroup(uint256 groupNumber) public view returns(string groupName, bool distributed, bool unlocked, uint256 phase2cap, uint256 phase3cap, uint256 cap, uint256 ratio, uint256 startTime, uint256 phase1endTime, uint256 phase2endTime, uint256 deadline, uint256 weiTotal) {
		require(groupNumber < nextGroupNumber);
		Group storage theGroup = groups[groupNumber];
		groupName = theGroup.name;
		distributed = theGroup.distributed;
		unlocked = theGroup.unlocked;
		phase2cap = theGroup.max2;
		phase3cap = theGroup.max3;
		cap = theGroup.cap;
		ratio = theGroup.ratio;
		startTime = theGroup.startTime;
		phase1endTime = theGroup.phase1endTime;
		phase2endTime = theGroup.phase2endTime;
		deadline = theGroup.deadline;
		weiTotal = theGroup.weiTotal;
	}
	
	function getHowMuchUntilHardCap_(uint256 groupNumber) internal view returns(uint256 remainder) {
		Group storage theGroup = groups[groupNumber];
		if (theGroup.weiTotal > theGroup.cap) {  
			return 0;
		}
		return theGroup.cap.sub(theGroup.weiTotal);
	}
	
	function getHowMuchUntilHardCap() public view returns(uint256 remainder) {
		return getHowMuchUntilHardCap_(openGroupNumber);
	}

	function addMemberToGroup(address walletAddress, uint256 groupNumber) public onlyOwner returns(bool success) {
		emit AddToGroup(walletAddress, groupNumber);
		return true;
	}
	
	function instructOracleToDistribute(uint256 groupNumber) public onlyOwner {
		Group storage theGroup = groups[groupNumber];
		require(groupNumber < nextGroupNumber && !theGroup.distributed);  
		emit WantsToDistribute(groupNumber);
	}
	
	function distributeCallback(uint256 groupNumber, uint256 howMany) public onlyOwnerOrOracle returns (bool success) {
		Group storage theGroup = groups[groupNumber];
		require(!theGroup.distributed);
		if (!theGroup.distributing) {
			theGroup.distributing = true;
		}
		uint256 n = theGroup.addresses.length;
		uint256 nextDistributionIndex = theGroup.nextDistributionIndex;
		uint256 exclusiveEndIndex = nextDistributionIndex + howMany;
		if (exclusiveEndIndex > n) {
			exclusiveEndIndex = n;
		}
		uint256 newOwnerSupply = balances[owner];
		for (uint256 i = nextDistributionIndex; i < exclusiveEndIndex; i++) {
			address theAddress = theGroup.addresses[i];
			uint256 balance = getUndistributedBalanceOf_(theAddress, groupNumber);
			if (balance > 0) {  
				balances[theAddress] = balances[theAddress].add(balance);
				newOwnerSupply = newOwnerSupply.sub(balance);  
				emit Transfer(owner, theAddress, balance);  
			}
		}
		balances[owner] = newOwnerSupply;
		if (exclusiveEndIndex < n) {
			emit DistributedBatch(groupNumber, howMany);
		} else {  
			signalDoneDistributing(groupNumber);
		}
		theGroup.nextDistributionIndex = exclusiveEndIndex;  
		return true;
	}

	function getHowManyLeftToDistribute(uint256 groupNumber) public view returns(uint256 remainder) {
		Group storage theGroup = groups[groupNumber];
		return theGroup.addresses.length - theGroup.nextDistributionIndex;
	}

	function changeGroupInfo(uint256 groupNumber, uint256 startEpoch, uint256 phase1endEpoch, uint256 phase2endEpoch, uint256 deadlineEpoch, uint256 phase2weiCap, uint256 phase3weiCap, uint256 hardWeiCap, uint256 ratio) public onlyOwner returns (bool success) {
		Group storage theGroup = groups[groupNumber];
		if (startEpoch > 0) {
			theGroup.startTime = startEpoch;
		}
		if (phase1endEpoch > 0) {
			theGroup.phase1endTime = phase1endEpoch;
		}
		if (phase2endEpoch > 0) {
			theGroup.phase2endTime = phase2endEpoch;
		}
		if (deadlineEpoch > 0) {
			theGroup.deadline = deadlineEpoch;
		}
		if (phase2weiCap > 0) {
			theGroup.max2 = phase2weiCap;
		}
		if (phase3weiCap > 0) {
			theGroup.max3 = phase3weiCap;
		}
		if (hardWeiCap > 0) {
			theGroup.cap = hardWeiCap;
		}
		if (ratio > 0) {
			theGroup.ratio = ratio;
		}
		return true;
	}

	function relockGroup(uint256 groupNumber) public onlyOwner returns(bool success) {
		groups[groupNumber].unlocked = true;
		return true;
	}

	function resetGroupInfo(uint256 groupNumber) public onlyOwner returns (bool success) {
		Group storage theGroup = groups[groupNumber];
		theGroup.startTime = 0;
		theGroup.phase1endTime = 0;
		theGroup.phase2endTime = 0;
		theGroup.deadline = 0;
		theGroup.max2 = 0;
		theGroup.max3 = 0;
		theGroup.cap = 0;
		theGroup.ratio = 0;
		return true;
	}

	function unlock(uint256 groupNumber) public onlyOwner returns (bool success) {
		Group storage theGroup = groups[groupNumber];
		require(theGroup.distributed);  
		theGroup.unlocked = true;
		return true;
	}
	
	function setGlobalLock(bool value) public onlyOwner {
		transferLock = value;
		emit ChangedTransferLock(transferLock);
	}
	
	function burn(uint256 amount) public onlyOwner {
		 
		 
		balances[msg.sender] = balances[msg.sender].sub(amount);  
		totalSupply_ = totalSupply_.sub(amount);  
		emit Transfer(msg.sender, address(0), amount);
	}
	
	function splitTokensBeforeDistribution(uint256 splitFactor) public onlyOwner returns (bool success) {
		 
		uint256 ownerBalance = balances[msg.sender];
		uint256 multiplier = ownerBalance.mul(splitFactor);
		uint256 increaseSupplyBy = multiplier.sub(ownerBalance);  
		balances[msg.sender] = multiplier;
		totalSupply_ = totalSupply_.mul(splitFactor);
		emit Transfer(address(0), msg.sender, increaseSupplyBy);  
		 
		uint256 n = nextGroupNumber;
		require(n > 0);  
		for (uint256 i = 0; i < n; i++) {
			Group storage currentGroup = groups[i];
			currentGroup.ratio = currentGroup.ratio.mul(splitFactor);
		}
		return true;
	}

	function reverseSplitTokensBeforeDistribution(uint256 splitFactor) public onlyOwner returns (bool success) {
		 
		uint256 ownerBalance = balances[msg.sender];
		uint256 divier = ownerBalance.div(splitFactor);
		uint256 decreaseSupplyBy = ownerBalance.sub(divier);
		 
		totalSupply_ = totalSupply_.div(splitFactor);
		balances[msg.sender] = divier;
		 
		emit Transfer(msg.sender, address(0), decreaseSupplyBy);
		 
		uint256 n = nextGroupNumber;
		require(n > 0);  
		for (uint256 i = 0; i < n; i++) {
			Group storage currentGroup = groups[i];
			currentGroup.ratio = currentGroup.ratio.div(splitFactor);
		}
		return true;
	}

	function airdrop( address[] addresses, uint256[] tokenDecimalAmounts) public onlyOwnerOrOracle returns (bool success) {
		uint256 n = addresses.length;
		require(n == tokenDecimalAmounts.length, "Array lengths mismatch");
		uint256 newOwnerBalance = balances[owner];
		for (uint256 i = 0; i < n; i++) {
			address theAddress = addresses[i];
			uint256 airdropAmount = tokenDecimalAmounts[i];
			if (airdropAmount > 0) {
				uint256 currentBalance = balances[theAddress];
				balances[theAddress] = currentBalance.add(airdropAmount);
				newOwnerBalance = newOwnerBalance.sub(airdropAmount);
				emit Transfer(owner, theAddress, airdropAmount);
			}
		}
		balances[owner] = newOwnerBalance;
		emit AirdroppedBatch(addresses);
		return true;
	}

	function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) canTransfer returns (bool success) {		
		 
		if (msg.sender != owner) {  
			require(balances[msg.sender].sub(_value) >= getLockedTokens_(msg.sender));
		}
		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) canTransfer returns (bool success) {
		 
		if (msg.sender != owner) {  
			require(balances[_from].sub(_value) >= getLockedTokens_(_from));
		}
		return super.transferFrom(_from, _to, _value);
	}

	function setOpenGroup(uint256 groupNumber) public onlyOwner returns (bool success) {
		require(groupNumber < nextGroupNumber);
		openGroupNumber = groupNumber;
		return true;
	}

	function getLockedTokensInGroup_(address walletAddress, uint256 groupNumber) internal view returns (uint256 balance) {
		Member storage theMember = members[walletAddress];
		if (groups[groupNumber].unlocked) {
			return 0;
		}
		return theMember.weiBalance[groupNumber].mul(groups[groupNumber].ratio);
	}

	function getLockedTokens_(address walletAddress) internal view returns(uint256 balance) {
		uint256 n = nextGroupNumber;
		for (uint256 i = 0; i < n; i++) {
			balance = balance.add(getLockedTokensInGroup_(walletAddress, i));
		}
		return balance;
	}

	function getLockedTokens(address walletAddress) public view returns(uint256 balance) {
		return getLockedTokens_(walletAddress);
	}

	function getUndistributedBalanceOf_(address walletAddress, uint256 groupNumber) internal view returns (uint256 balance) {
		Member storage theMember = members[walletAddress];
		Group storage theGroup = groups[groupNumber];
		if (theGroup.distributed) {
			return 0;
		}
		return theMember.weiBalance[groupNumber].mul(theGroup.ratio);
	}

	function getUndistributedBalanceOf(address walletAddress, uint256 groupNumber) public view returns (uint256 balance) {
		return getUndistributedBalanceOf_(walletAddress, groupNumber);
	}

	function checkMyUndistributedBalance(uint256 groupNumber) public view returns (uint256 balance) {
		return getUndistributedBalanceOf_(msg.sender, groupNumber);
	}

	function transferRecovery(address _from, address _to, uint256 _value) public onlyOwner returns (bool success) {
		 
		allowed[_from][msg.sender] = allowed[_from][msg.sender].add(_value);  
		return transferFrom(_from, _to, _value);
	}
}