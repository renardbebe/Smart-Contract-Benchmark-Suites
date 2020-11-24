 

pragma solidity 0.5.8;
 
 

 
 

 
 
 

 
 

 
 
 
 
 
 
 
 


 
 
contract multiowned {

	 

	 
	struct MultiOwnedOperationPendingState {
		 
		uint256 yetNeeded;

		 
		uint256 ownersDone;

		 
		uint256 index;
	}

	 

	event Confirmation(address owner, bytes32 operation);
	event Revoke(address owner, bytes32 operation);
	event FinalConfirmation(address owner, bytes32 operation);

	 
	event OwnerChanged(address oldOwner, address newOwner);
	event OwnerAdded(address newOwner);
	event OwnerRemoved(address oldOwner);

	 
	event RequirementChanged(uint256 newRequirement);

	 

	 
	modifier onlyOwner {
		require(isOwner(msg.sender), "Auth");
		_;
	}
	 
	 
	 
	modifier onlyManyOwners(bytes32 _operation) {
		if (confirmAndCheck(_operation)) {
			_;
		}
		 
		 
		 
	}

	modifier validNumOwners(uint256 _numOwners) {
		require(_numOwners > 0 && _numOwners <= c_maxOwners, "NumOwners OOR");
		_;
	}

	modifier multiOwnedValidRequirement(uint256 _required, uint256 _numOwners) {
		require(_required > 0 && _required <= _numOwners, "Req OOR");
		_;
	}

	modifier ownerExists(address _address) {
		require(isOwner(_address), "Auth");
		_;
	}

	modifier ownerDoesNotExist(address _address) {
		require(!isOwner(_address), "Is owner");
		_;
	}

	modifier multiOwnedOperationIsActive(bytes32 _operation) {
		require(isOperationActive(_operation), "NoOp");
		_;
	}

	 

	 
	 
	constructor (address[] memory _owners, uint256 _required)
		public
		validNumOwners(_owners.length)
		multiOwnedValidRequirement(_required, _owners.length)
	{
		assert(c_maxOwners <= 255);

		m_numOwners = _owners.length;
		m_multiOwnedRequired = _required;

		for (uint256 i = 0; i < _owners.length; ++i)
		{
			address owner = _owners[i];
			 
			require(address(0) != owner && !isOwner(owner), "Exists");   

			uint256 currentOwnerIndex = checkOwnerIndex(i + 1);   
			m_owners[currentOwnerIndex] = owner;
			m_ownerIndex[owner] = currentOwnerIndex;
		}

		assertOwnersAreConsistent();
	}

	 
	 
	 
	 
	function changeOwner(address _from, address _to)
		external
		ownerExists(_from)
		ownerDoesNotExist(_to)
		onlyManyOwners(keccak256(msg.data))
	{
		assertOwnersAreConsistent();

		clearPending();
		uint256 ownerIndex = checkOwnerIndex(m_ownerIndex[_from]);
		m_owners[ownerIndex] = _to;
		m_ownerIndex[_from] = 0;
		m_ownerIndex[_to] = ownerIndex;

		assertOwnersAreConsistent();
		emit OwnerChanged(_from, _to);
	}

	 
	 
	 
	function addOwner(address _owner)
		external
		ownerDoesNotExist(_owner)
		validNumOwners(m_numOwners + 1)
		onlyManyOwners(keccak256(msg.data))
	{
		assertOwnersAreConsistent();

		clearPending();
		m_numOwners++;
		m_owners[m_numOwners] = _owner;
		m_ownerIndex[_owner] = checkOwnerIndex(m_numOwners);

		assertOwnersAreConsistent();
		emit OwnerAdded(_owner);
	}

	 
	 
	 
	function removeOwner(address _owner)
		external
		ownerExists(_owner)
		validNumOwners(m_numOwners - 1)
		multiOwnedValidRequirement(m_multiOwnedRequired, m_numOwners - 1)
		onlyManyOwners(keccak256(msg.data))
	{
		assertOwnersAreConsistent();

		clearPending();
		uint256 ownerIndex = checkOwnerIndex(m_ownerIndex[_owner]);
		m_owners[ownerIndex] = address(0);
		m_ownerIndex[_owner] = 0;
		 
		reorganizeOwners();

		assertOwnersAreConsistent();
		emit OwnerRemoved(_owner);
	}

	 
	 
	 
	function changeRequirement(uint256 _newRequired)
		external
		multiOwnedValidRequirement(_newRequired, m_numOwners)
		onlyManyOwners(keccak256(msg.data))
	{
		m_multiOwnedRequired = _newRequired;
		clearPending();
		emit RequirementChanged(_newRequired);
	}

	 
	 
	function getOwner(uint256 ownerIndex) public view returns (address) {
		return m_owners[ownerIndex + 1];
	}

	 
	 
	function getOwners() public view returns (address[] memory) {
		address[] memory result = new address[](m_numOwners);
		for (uint256 i = 0; i < m_numOwners; i++)
			result[i] = getOwner(i);

		return result;
	}

	 
	 
	 
	function isOwner(address _addr) public view returns (bool) {
		return m_ownerIndex[_addr] > 0;
	}

	 
	 
	 
	 
	function amIOwner() external view onlyOwner returns (bool) {
		return true;
	}

	 
	 
	function revoke(bytes32 _operation)
		external
		multiOwnedOperationIsActive(_operation)
		onlyOwner
	{
		uint256 ownerIndexBit = makeOwnerBitmapBit(msg.sender);
		MultiOwnedOperationPendingState storage pending = m_multiOwnedPending[_operation];
		require(pending.ownersDone & ownerIndexBit > 0, "Auth");

		assertOperationIsConsistent(_operation);

		pending.yetNeeded++;
		pending.ownersDone -= ownerIndexBit;

		assertOperationIsConsistent(_operation);
		emit Revoke(msg.sender, _operation);
	}

	 
	 
	 
	function hasConfirmed(bytes32 _operation, address _owner)
		external
		view
		multiOwnedOperationIsActive(_operation)
		ownerExists(_owner)
		returns (bool)
	{
		return !(m_multiOwnedPending[_operation].ownersDone & makeOwnerBitmapBit(_owner) == 0);
	}

	 

	function confirmAndCheck(bytes32 _operation)
		internal
		onlyOwner
		returns (bool)
	{
		if (512 == m_multiOwnedPendingIndex.length)
			 
			 
			 
			 
			clearPending();

		MultiOwnedOperationPendingState storage pending = m_multiOwnedPending[_operation];

		 
		if (! isOperationActive(_operation)) {
			 
			pending.yetNeeded = m_multiOwnedRequired;
			 
			pending.ownersDone = 0;
			pending.index = m_multiOwnedPendingIndex.length++;
			m_multiOwnedPendingIndex[pending.index] = _operation;
			assertOperationIsConsistent(_operation);
		}

		 
		uint256 ownerIndexBit = makeOwnerBitmapBit(msg.sender);
		 
		if (pending.ownersDone & ownerIndexBit == 0) {
			 
			assert(pending.yetNeeded > 0);
			if (pending.yetNeeded == 1) {
				 
				delete m_multiOwnedPendingIndex[m_multiOwnedPending[_operation].index];
				delete m_multiOwnedPending[_operation];
				emit FinalConfirmation(msg.sender, _operation);
				return true;
			}
			else
			{
				 
				pending.yetNeeded--;
				pending.ownersDone |= ownerIndexBit;
				assertOperationIsConsistent(_operation);
				emit Confirmation(msg.sender, _operation);
			}
		}
	}

	 
	 
	function reorganizeOwners() private {
		uint256 free = 1;
		uint256 numberOfOwners = m_numOwners;
		while (free < numberOfOwners)
		{
			 
			while (free < numberOfOwners && m_owners[free] != address(0)) free++;

			 
			while (numberOfOwners > 1 && m_owners[numberOfOwners] == address(0)) numberOfOwners--;

			 
			if (free < numberOfOwners && m_owners[numberOfOwners] != address(0) && m_owners[free] == address(0))
			{
				 
				m_owners[free] = m_owners[numberOfOwners];
				m_ownerIndex[m_owners[free]] = free;
				m_owners[numberOfOwners] = address(0);
			}
		}
		m_numOwners = numberOfOwners;
	}

	function clearPending() private onlyOwner {
		uint256 length = m_multiOwnedPendingIndex.length;
		 
		for (uint256 i = 0; i < length; ++i) {
			if (m_multiOwnedPendingIndex[i] != 0)
				delete m_multiOwnedPending[m_multiOwnedPendingIndex[i]];
		}
		delete m_multiOwnedPendingIndex;
	}

	function checkOwnerIndex(uint256 ownerIndex) internal pure returns (uint256) {
		assert(0 != ownerIndex && ownerIndex <= c_maxOwners);
		return ownerIndex;
	}

	function makeOwnerBitmapBit(address owner) private view returns (uint256) {
		uint256 ownerIndex = checkOwnerIndex(m_ownerIndex[owner]);
		return 2 ** ownerIndex;
	}

	function isOperationActive(bytes32 _operation) private view returns (bool) {
		return 0 != m_multiOwnedPending[_operation].yetNeeded;
	}


	function assertOwnersAreConsistent() private view {
		assert(m_numOwners > 0);
		assert(m_numOwners <= c_maxOwners);
		assert(m_owners[0] == address(0));
		assert(0 != m_multiOwnedRequired && m_multiOwnedRequired <= m_numOwners);
	}

	function assertOperationIsConsistent(bytes32 _operation) private view {
		MultiOwnedOperationPendingState storage pending = m_multiOwnedPending[_operation];
		assert(0 != pending.yetNeeded);
		assert(m_multiOwnedPendingIndex[pending.index] == _operation);
		assert(pending.yetNeeded <= m_multiOwnedRequired);
	}


	 

	uint256 constant c_maxOwners = 250;

	 
	uint256 public m_multiOwnedRequired;


	 
	uint256 public m_numOwners;

	 
	 
	 
	address[256] internal m_owners;

	 
	mapping(address => uint256) internal m_ownerIndex;


	 
	mapping(bytes32 => MultiOwnedOperationPendingState) internal m_multiOwnedPending;
	bytes32[] internal m_multiOwnedPendingIndex;
}


 
contract ERC20Basic {
	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
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


 
contract BasicToken is ERC20Basic {
	using SafeMath for uint256;

	mapping(address => uint256) balances;

	uint256 totalSupply_;

	 
	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	 
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0), "Self");
		require(_value <= balances[msg.sender], "NSF");

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
	function allowance(address owner, address spender) public view returns (uint256);

	function transferFrom(address from, address to, uint256 value) public returns (bool);

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
		require(_to != address(0), "Invl");
		require(_value <= balances[_from], "NSF");
		require(_value <= allowed[_from][msg.sender], "NFAllowance");

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

contract SparksterTokenSwap is StandardToken, multiowned {
	using SafeMath for uint256;
	struct Member {
		mapping(uint256 => uint256) weiBalance;  
		uint256[] groups;  
		 
		 
	}

	enum GroupStates {
		none,
		distributing,
		distributed,
		unlocked  
		 
	}

	struct Group {
		GroupStates state;  
		mapping(address => bool) exists;  
		string name;
		uint256 ratio;  
		uint256 unlockTime;  
		 
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

	address[] internal initialSigners = [0xCdF06E2F49F7445098CFA54F52C7f43eE40fa016, 0x0D2b5b40F88cCb05e011509830c2E5003d73FE92, 0x363d591196d3004Ca708DB2049501440718594f5];
	address public oracleAddress;
	address constant public oldSprkAddress = 0x971d048E737619884f2df75e31c7Eb6412392328;
	address public owner;  
	 
	 
	bool public transferLock = true;  
	bool public allowedToBuyBack = false;
	bool public allowedToPurchase = false;
	string public name;									  
	string public symbol;								  
	uint8 public decimals;							 
	uint8 constant internal maxGroups = 100;  
	uint256 public penalty;
	uint256 public maxGasPrice;  
	uint256 internal nextGroupNumber;
	uint256 public sellPrice;  
	uint256 public minimumRequiredBalance;  
	 
	uint256 public openGroupNumber;
	mapping(address => Member) internal members;  
	mapping(uint256 => Group) internal groups;  
	mapping(address => uint256) internal withdrawableBalances;  
	ERC20 oldSprk;  
	event WantsToPurchase(address walletAddress, uint256 weiAmount, uint256 groupNumber, bool inPhase1);
	event PurchasedCallbackOnAccept(uint256 groupNumber, address[] addresses);
	event WantsToDistribute(uint256 groupNumber);
	event NearingHardCap(uint256 groupNumber, uint256 remainder);
	event ReachedHardCap(uint256 groupNumber);
	event DistributeDone(uint256 groupNumber);
	event DistributedBatch(uint256 groupNumber, uint256 howMany);
	event ShouldCallDoneDistributing();
	event AirdroppedBatch(address[] addresses);
	event RefundedBatch(address[] addresses);
	event AddToGroup(address walletAddress, uint256 groupNumber);
	event ChangedTransferLock(bool transferLock);
	event ChangedAllowedToPurchase(bool allowedToPurchase);
	event ChangedAllowedToBuyBack(bool allowedToBuyBack);
	event SetSellPrice(uint256 sellPrice);

	modifier onlyOwnerOrOracle() {
		require(isOwner(msg.sender) || msg.sender == oracleAddress, "Auth");
		_;
	}

	modifier onlyManyOwnersOrOracle(bytes32 _operation) {
		if (confirmAndCheck(_operation) || msg.sender == oracleAddress)
			_;
		 
	}

	modifier canTransfer() {
		if (!isOwner(msg.sender)) {  
			require(!transferLock, "Locked");
		}
		_;
	}

	modifier canPurchase() {
		require(allowedToPurchase, "Disallowed");
		_;
	}

	modifier canSell() {
		require(allowedToBuyBack, "Denied");
		_;
	}

	function() external payable {
		purchase();
	}

	constructor()
	multiowned( initialSigners, 2) public {
		require(isOwner(msg.sender), "NaO");
		oldSprk = ERC20(oldSprkAddress);
		owner = msg.sender;
		name = "Sparkster";									 
		decimals = 18;					  
		symbol = "SPRK";							 
		maxGasPrice = 40 * 10**9;  
		uint256 amount = 435000000;
		uint256 decimalAmount = amount.mul(uint(10)**decimals);
		totalSupply_ = decimalAmount;
		balances[msg.sender] = decimalAmount;
		emit Transfer(address(0), msg.sender, decimalAmount);  
	}

	function swapTokens() public returns(bool) {
		require(msg.sender != address(this), "Self");  
		 
		 
		uint256 amountToTransfer = oldSprk.allowance(msg.sender, address(this));
		require(amountToTransfer > 0, "Amount==0");
		 
		balances[msg.sender] = balances[msg.sender].add(amountToTransfer);
		balances[owner] = balances[owner].sub(amountToTransfer);
		 
		require(oldSprk.transferFrom(msg.sender, address(this), amountToTransfer), "Transfer");
		emit Transfer(owner, msg.sender, amountToTransfer);
		return true;
	}

	function setOwnerAddress(address newAddress) public onlyManyOwners(keccak256(msg.data)) returns(bool) {
		require(newAddress != address(0), "Invl");
		require(newAddress != owner, "Self");
		uint256 oldOwnerBalance = balances[owner];
		balances[newAddress] = balances[newAddress].add(oldOwnerBalance);
		balances[owner] = 0;
		emit Transfer(owner, newAddress, oldOwnerBalance);
		owner = newAddress;
		return true;
	}

	function setOracleAddress(address newAddress) public onlyManyOwners(keccak256(msg.data)) returns(bool) {
		oracleAddress = newAddress;
		return true;
	}

	function removeOracleAddress() public onlyOwner returns(bool) {
		oracleAddress = address(0);
		return true;
	}

	function setMaximumGasPrice(uint256 gweiPrice) public onlyManyOwners(keccak256(msg.data)) returns(bool) {
		maxGasPrice = gweiPrice.mul(10**9);  
		return true;
	}

	function purchase() public canPurchase payable returns(bool) {
		Member storage memberRecord = members[msg.sender];
		Group storage openGroup = groups[openGroupNumber];
		require(openGroup.ratio > 0, "Not initialized");  
		uint256 currentTimestamp = block.timestamp;
		require(currentTimestamp >= openGroup.startTime && currentTimestamp <= openGroup.deadline, "OOR");
		 
		require(openGroup.state == GroupStates.none, "State");
		 
		require(tx.gasprice <= maxGasPrice, "Gas price");  
		uint256 weiAmount = msg.value;																		 
		 
		require(weiAmount >= 0.1 ether, "Amount<0.1 ether");
		uint256 weiTotal = openGroup.weiTotal.add(weiAmount);  
		 
		require(weiTotal <= openGroup.cap, "Cap exceeded");														 
		uint256 userWeiTotal = memberRecord.weiBalance[openGroupNumber].add(weiAmount);  
		if (!openGroup.exists[msg.sender]) {  
			openGroup.addresses.push(msg.sender);
			openGroup.exists[msg.sender] = true;
			memberRecord.groups.push(openGroupNumber);
		}
		if(currentTimestamp <= openGroup.phase1endTime){																			  
			emit WantsToPurchase(msg.sender, weiAmount, openGroupNumber, true);
			return true;
		} else if (currentTimestamp <= openGroup.phase2endTime) {  
			require(userWeiTotal <= openGroup.max2, "Phase2 cap exceeded");  
			emit WantsToPurchase(msg.sender, weiAmount, openGroupNumber, false);
			return true;
		} else {  
			require(userWeiTotal <= openGroup.max3, "Phase3 cap exceeded");  
			emit WantsToPurchase(msg.sender, weiAmount, openGroupNumber, false);
			return true;
		}
	}

	function purchaseCallbackOnAccept(
		uint256 groupNumber, address[] memory addresses, uint256[] memory weiAmounts)
	public onlyManyOwnersOrOracle(keccak256(msg.data)) returns(bool success) {
		return accept(groupNumber, addresses, weiAmounts);
	}

	 
	 
	function accept(
		uint256 groupNumber, address[] memory addresses, uint256[] memory weiAmounts)
	private onlyOwnerOrOracle returns(bool) {
		uint256 n = addresses.length;
		require(n == weiAmounts.length, "Length");
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

	function insertAndApprove(uint256 groupNumber, address[] memory addresses, uint256[] memory weiAmounts)
	public onlyManyOwnersOrOracle(keccak256(msg.data)) returns(bool) {
		uint256 n = addresses.length;
		require(n == weiAmounts.length, "Length");
		Group storage theGroup = groups[groupNumber];
		for (uint256 i = 0; i < n; i++) {
			address theAddress = addresses[i];
			if (!theGroup.exists[theAddress]) {
				theGroup.addresses.push(theAddress);
				theGroup.exists[theAddress] = true;
				members[theAddress].groups.push(groupNumber);
			}
		}
		return accept(groupNumber, addresses, weiAmounts);
	}

	function callbackInsertApproveAndDistribute(
		uint256 groupNumber, address[] memory addresses, uint256[] memory weiAmounts)
	public onlyManyOwnersOrOracle(keccak256(msg.data)) returns(bool) {
		uint256 n = addresses.length;
		require(n == weiAmounts.length, "Length");
		require(getGroupState(groupNumber) != GroupStates.unlocked, "Unlocked");
		Group storage theGroup = groups[groupNumber];
		uint256 newOwnerSupply = balances[owner];
		for (uint256 i = 0; i < n; i++) {
			address theAddress = addresses[i];
			Member storage memberRecord = members[theAddress];
			uint256 weiAmount = weiAmounts[i];
			memberRecord.weiBalance[groupNumber] = memberRecord.weiBalance[groupNumber].add(weiAmount);
			 
			if (!theGroup.exists[theAddress]) {
				theGroup.addresses.push(theAddress);
				theGroup.exists[theAddress] = true;
				memberRecord.groups.push(groupNumber);
			}
			uint256 additionalBalance = weiAmount.mul(theGroup.ratio);  
			if (additionalBalance > 0) {
				balances[theAddress] = balances[theAddress].add(additionalBalance);
				newOwnerSupply = newOwnerSupply.sub(additionalBalance);  
				emit Transfer(owner, theAddress, additionalBalance);  
			}
		}
		balances[owner] = newOwnerSupply;
		emit PurchasedCallbackOnAccept(groupNumber, addresses);
		if (getGroupState(groupNumber) != GroupStates.distributed)
			theGroup.state = GroupStates.distributed;
		return true;
	}

	function getWithdrawableAmount() public view returns(uint256) {
		return withdrawableBalances[msg.sender];
	}

	function withdraw() public returns (bool) {
		uint256 amount = withdrawableBalances[msg.sender];
		require(amount > 0, "NSF");
		withdrawableBalances[msg.sender] = 0;
		minimumRequiredBalance = minimumRequiredBalance.sub(amount);
		msg.sender.transfer(amount);
		return true;
	}

	function refund(address[] memory addresses, uint256[] memory weiAmounts) public onlyManyOwners(keccak256(msg.data)) returns(bool success) {
		uint256 n = addresses.length;
		require (n == weiAmounts.length, "Length");
		uint256 thePenalty = penalty;
		uint256 totalRefund = 0;
		for(uint256 i = 0; i < n; i++) {
			uint256 weiAmount = weiAmounts[i];
			address payable theAddress = address(uint160(address(addresses[i])));
			if (thePenalty < weiAmount) {
				weiAmount = weiAmount.sub(thePenalty);
				totalRefund = totalRefund.add(weiAmount);
				withdrawableBalances[theAddress] = withdrawableBalances[theAddress].add(weiAmount);
			}
		}
		require(address(this).balance >= minimumRequiredBalance + totalRefund, "NSF");  
		minimumRequiredBalance = minimumRequiredBalance.add(totalRefund);
		emit RefundedBatch(addresses);
		return true;
	}

	function signalDoneDistributing(uint256 groupNumber) public onlyManyOwnersOrOracle(keccak256(msg.data)) {
		Group storage theGroup = groups[groupNumber];
		theGroup.state = GroupStates.distributed;
		emit DistributeDone(groupNumber);
	}

	function drain(address payable to) public onlyManyOwners(keccak256(msg.data)) returns(bool) {
		uint256 amountAllowedToDrain = address(this).balance.sub(minimumRequiredBalance);
		require(amountAllowedToDrain > 0, "NSF");
		to.transfer(amountAllowedToDrain);
		return true;
	}

	function setPenalty(uint256 newPenalty) public onlyManyOwners(keccak256(msg.data)) returns(bool) {
		penalty = newPenalty;
		return true;
	}

	function buyback(uint256 amount) public canSell {
		require(sellPrice>0, "sellPrice==0");
		uint256 decimalAmount = amount.mul(uint(10)**decimals);  
		require(balances[msg.sender].sub(decimalAmount) >= getLockedTokens_(msg.sender), "NSF");  
		balances[msg.sender] = balances[msg.sender].sub(decimalAmount);
		 
		uint256 totalCost = amount.mul(sellPrice);  
		minimumRequiredBalance = minimumRequiredBalance.add(totalCost);
		require(address(this).balance >= minimumRequiredBalance, "NSF");  
		balances[owner] = balances[owner].add(decimalAmount);  
		withdrawableBalances[msg.sender] = withdrawableBalances[msg.sender].add(totalCost);  
		emit Transfer(msg.sender, owner, decimalAmount);  
	}

	function fundContract() public onlyOwnerOrOracle payable {  
	}

	function setSellPrice(uint256 thePrice) public onlyManyOwners(keccak256(msg.data)) returns (bool) {
		sellPrice = thePrice;
		emit SetSellPrice(thePrice);
		return true;
	}

	function setAllowedToBuyBack(bool value) public onlyManyOwners(keccak256(msg.data)) {
		allowedToBuyBack = value;
		emit ChangedAllowedToBuyBack(value);
	}

	function setAllowedToPurchase(bool value) public onlyManyOwners(keccak256(msg.data)) returns(bool) {
		allowedToPurchase = value;
		emit ChangedAllowedToPurchase(value);
		return true;
	}

	function createGroup(
		string memory groupName, uint256 startEpoch, uint256 phase1endEpoch, uint256 phase2endEpoch, uint256 deadlineEpoch,
		uint256 unlockAfterEpoch, uint256 phase2weiCap, uint256 phase3weiCap, uint256 hardWeiCap, uint256 ratio) public
	onlyManyOwners(keccak256(msg.data)) returns (bool success, uint256 createdGroupNumber) {
		require(nextGroupNumber < maxGroups, "Too many groups");
		createdGroupNumber = nextGroupNumber;
		Group storage theGroup = groups[createdGroupNumber];
		theGroup.name = groupName;
		theGroup.startTime = startEpoch;
		theGroup.phase1endTime = phase1endEpoch;
		theGroup.phase2endTime = phase2endEpoch;
		theGroup.deadline = deadlineEpoch;
		theGroup.unlockTime = unlockAfterEpoch;
		theGroup.max2 = phase2weiCap;
		theGroup.max3 = phase3weiCap;
		theGroup.cap = hardWeiCap;
		theGroup.ratio = ratio;
		nextGroupNumber++;
		success = true;
	}

	function getGroup(uint256 groupNumber) public view returns(string memory groupName, string memory status, uint256 phase2cap,
	uint256 phase3cap, uint256 cap, uint256 ratio, uint256 startTime, uint256 phase1endTime, uint256 phase2endTime, uint256 deadline,
	uint256 weiTotal) {
		require(groupNumber < nextGroupNumber, "OOR");
		Group storage theGroup = groups[groupNumber];
		groupName = theGroup.name;
		GroupStates state = getGroupState(groupNumber);
		status = (state == GroupStates.none)? "none"
		:(state == GroupStates.distributing)? "distributing"
		:(state == GroupStates.distributed)? "distributed":"unlocked";
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

	function getGroupUnlockTime(uint256 groupNumber) public view returns(uint256) {
		require(groupNumber < nextGroupNumber, "OOR");
		Group storage theGroup = groups[groupNumber];
		return theGroup.unlockTime;
	}

	function getHowMuchUntilHardCap_(uint256 groupNumber) internal view returns(uint256) {
		Group storage theGroup = groups[groupNumber];
		if (theGroup.weiTotal > theGroup.cap) {  
			return 0;
		}
		return theGroup.cap.sub(theGroup.weiTotal);
	}

	function getHowMuchUntilHardCap() public view returns(uint256) {
		return getHowMuchUntilHardCap_(openGroupNumber);
	}

	function addMemberToGroup(address walletAddress, uint256 groupNumber) public onlyOwner returns(bool) {
		emit AddToGroup(walletAddress, groupNumber);
		return true;
	}

	function instructOracleToDistribute(uint256 groupNumber) public onlyOwnerOrOracle returns(bool) {
		require(groupNumber < nextGroupNumber && getGroupState(groupNumber) < GroupStates.distributed, "Dist");
		emit WantsToDistribute(groupNumber);
		return true;
	}

	function distributeCallback(uint256 groupNumber, uint256 howMany) public onlyManyOwnersOrOracle(keccak256(msg.data)) returns (bool success) {
		Group storage theGroup = groups[groupNumber];
		GroupStates state = getGroupState(groupNumber);
		require(state < GroupStates.distributed, "Dist");
		if (state != GroupStates.distributing) {
			theGroup.state = GroupStates.distributing;
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
			 
			emit ShouldCallDoneDistributing();
		}
		theGroup.nextDistributionIndex = exclusiveEndIndex;  
		 
		return true;
	}

	function getHowManyLeftToDistribute(uint256 groupNumber) public view returns(uint256 remainder) {
		Group storage theGroup = groups[groupNumber];
		return theGroup.addresses.length - theGroup.nextDistributionIndex;
	}

	function unlock(uint256 groupNumber) public onlyManyOwners(keccak256(msg.data)) returns (bool success) {
		Group storage theGroup = groups[groupNumber];
		require(getGroupState(groupNumber) == GroupStates.distributed, "Undist");  
		require(theGroup.unlockTime == 0, "Unlocktime");
		 
		theGroup.state = GroupStates.unlocked;
		return true;
	}

	function liftGlobalLock() public onlyManyOwners(keccak256(msg.data)) returns(bool) {
		transferLock = false;
		emit ChangedTransferLock(transferLock);
		return true;
	}

	function airdrop( address[] memory addresses, uint256[] memory tokenDecimalAmounts) public onlyManyOwnersOrOracle(keccak256(msg.data))
	returns (bool) {
		uint256 n = addresses.length;
		require(n == tokenDecimalAmounts.length, "Length");
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

	function transfer(address _to, uint256 _value) public canTransfer returns (bool success) {
		 
		require(balances[msg.sender].sub(_value) >= getLockedTokens_(msg.sender), "Not enough tokens");
		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public canTransfer returns (bool success) {
		 
		require(balances[_from].sub(_value) >= getLockedTokens_(_from), "Not enough tokens");
		return super.transferFrom(_from, _to, _value);
	}

	function setOpenGroup(uint256 groupNumber) public onlyManyOwners(keccak256(msg.data)) returns (bool) {
		require(groupNumber < nextGroupNumber, "OOR");
		openGroupNumber = groupNumber;
		return true;
	}

	function getGroupState(uint256 groupNumber) public view returns(GroupStates) {
		require(groupNumber < nextGroupNumber, "out of range");  
		Group storage theGroup = groups[groupNumber];
		if (theGroup.state < GroupStates.distributed)
			return theGroup.state;
		 
		 
		if (block.timestamp < theGroup.unlockTime)
			return GroupStates.distributed;
		else if (theGroup.unlockTime > 0)  
			return GroupStates.unlocked;
		return theGroup.state;
	}

	function getLockedTokensInGroup_(address walletAddress, uint256 groupNumber) internal view returns (uint256 balance) {
		Member storage theMember = members[walletAddress];
		if (getGroupState(groupNumber) == GroupStates.unlocked) {
			return 0;
		}
		return theMember.weiBalance[groupNumber].mul(groups[groupNumber].ratio);
	}

	function getLockedTokens_(address walletAddress) internal view returns(uint256 balance) {
		uint256[] storage memberGroups = members[walletAddress].groups;
		uint256 n = memberGroups.length;
		for (uint256 i = 0; i < n; i++) {
			balance = balance.add(getLockedTokensInGroup_(walletAddress, memberGroups[i]));
		}
		return balance;
	}

	function getLockedTokens(address walletAddress) public view returns(uint256 balance) {
		return getLockedTokens_(walletAddress);
	}

	function getUndistributedBalanceOf_(address walletAddress, uint256 groupNumber) internal view returns (uint256 balance) {
		Member storage theMember = members[walletAddress];
		Group storage theGroup = groups[groupNumber];
		if (getGroupState(groupNumber) > GroupStates.distributing) {
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
	
	function burn(uint256 amount) public onlyManyOwners(keccak256(msg.data)) {
		balances[owner] = balances[owner].sub(amount);
		totalSupply_ = totalSupply_.sub(amount);
		emit Transfer(owner, address(0), amount);
	}
}