 

 
 

pragma solidity ^0.4.17;

 
contract Token {
	function transfer(address _to, uint256 _value) public returns (bool success);
}

 
contract Certifier {
	event Confirmed(address indexed who);
	event Revoked(address indexed who);
	function certified(address) public constant returns (bool);
	function get(address, string) public constant returns (bytes32);
	function getAddress(address, string) public constant returns (address);
	function getUint(address, string) public constant returns (uint);
}

 
 
 
 
contract SecondPriceAuction {
	 

	 
	event Buyin(address indexed who, uint accounted, uint received, uint price);

	 
	event Injected(address indexed who, uint accounted, uint received);

	 
	event Uninjected(address indexed who);

	 
	event Ticked(uint era, uint received, uint accounted);

	 
	event Ended(uint price);

	 
	event Finalised(address indexed who, uint tokens);

	 
	event Retired();

	 

	 
	 
	function SecondPriceAuction(
		address _certifierContract,
		address _tokenContract,
		address _treasury,
		address _admin,
		uint _beginTime,
		uint _tokenCap
	)
		public
	{
		certifier = Certifier(_certifierContract);
		tokenContract = Token(_tokenContract);
		treasury = _treasury;
		admin = _admin;
		beginTime = _beginTime;
		tokenCap = _tokenCap;
		endTime = beginTime + 28 days;
	}

	 
	function() public { assert(false); }

	 

	 
	function buyin(uint8 v, bytes32 r, bytes32 s)
		public
		payable
		when_not_halted
		when_active
		only_eligible(msg.sender, v, r, s)
	{
		flushEra();

		 
		if (currentBonus > 0) {
			 
			if (now >= beginTime + BONUS_MIN_DURATION				 
				&& lastNewInterest + BONUS_LATCH <= block.number	 
			) {
				currentBonus--;
			}
			if (now >= beginTime + BONUS_MAX_DURATION) {
				currentBonus = 0;
			}
			if (buyins[msg.sender].received == 0) {	 
				lastNewInterest = uint32(block.number);
			}
		}

		uint accounted;
		bool refund;
		uint price;
		(accounted, refund, price) = theDeal(msg.value);

		 
		require (!refund);

		 
		buyins[msg.sender].accounted += uint128(accounted);
		buyins[msg.sender].received += uint128(msg.value);
		totalAccounted += accounted;
		totalReceived += msg.value;
		endTime = calculateEndTime();
		Buyin(msg.sender, accounted, msg.value, price);

		 
		treasury.transfer(msg.value);
	}

	 
	function inject(address _who, uint128 _received)
		public
		only_admin
		only_basic(_who)
		before_beginning
	{
		uint128 bonus = _received * uint128(currentBonus) / 100;
		uint128 accounted = _received + bonus;

		buyins[_who].accounted += accounted;
		buyins[_who].received += _received;
		totalAccounted += accounted;
		totalReceived += _received;
		endTime = calculateEndTime();
		Injected(_who, accounted, _received);
	}

	 
	function uninject(address _who)
		public
		only_admin
		before_beginning
	{
		totalAccounted -= buyins[_who].accounted;
		totalReceived -= buyins[_who].received;
		delete buyins[_who];
		endTime = calculateEndTime();
		Uninjected(_who);
	}

	 
	function finalise(address _who)
		public
		when_not_halted
		when_ended
		only_buyins(_who)
	{
		 
		if (endPrice == 0) {
			endPrice = totalAccounted / tokenCap;
			Ended(endPrice);
		}

		 
		uint total = buyins[_who].accounted;
		uint tokens = total / endPrice;
		totalFinalised += total;
		delete buyins[_who];
		require (tokenContract.transfer(_who, tokens));

		Finalised(_who, tokens);

		if (totalFinalised == totalAccounted) {
			Retired();
		}
	}

	 

	 
	function flushEra() private {
		uint currentEra = (now - beginTime) / ERA_PERIOD;
		if (currentEra > eraIndex) {
			Ticked(eraIndex, totalReceived, totalAccounted);
		}
		eraIndex = currentEra;
	}

	 

	 
	function setHalted(bool _halted) public only_admin { halted = _halted; }

	 
	function drain() public only_admin { treasury.transfer(this.balance); }

	 

	 

	 
	function calculateEndTime() public constant returns (uint) {
		var factor = tokenCap / DIVISOR * USDWEI;
		return beginTime + 40000000 * factor / (totalAccounted + 5 * factor) - 5760;
	}

	 
	 
	 
	function currentPrice() public constant when_active returns (uint weiPerIndivisibleTokenPart) {
		return (USDWEI * 40000000 / (now - beginTime + 5760) - USDWEI * 5) / DIVISOR;
	}

	 
	function tokensAvailable() public constant when_active returns (uint tokens) {
		uint _currentCap = totalAccounted / currentPrice();
		if (_currentCap >= tokenCap) {
			return 0;
		}
		return tokenCap - _currentCap;
	}

	 
	 
	function maxPurchase() public constant when_active returns (uint spend) {
		return tokenCap * currentPrice() - totalAccounted;
	}

	 
	 
	function theDeal(uint _value)
		public
		constant
		when_active
		returns (uint accounted, bool refund, uint price)
	{
		uint _bonus = bonus(_value);

		price = currentPrice();
		accounted = _value + _bonus;

		uint available = tokensAvailable();
		uint tokens = accounted / price;
		refund = (tokens > available);
	}

	 
	function bonus(uint _value)
		public
		constant
		when_active
		returns (uint extra)
	{
		return _value * uint(currentBonus) / 100;
	}

	 
	function isActive() public constant returns (bool) { return now >= beginTime && now < endTime; }

	 
	function allFinalised() public constant returns (bool) { return now >= endTime && totalAccounted == totalFinalised; }

	 
	function isBasicAccount(address _who) internal constant returns (bool) {
		uint senderCodeSize;
		assembly {
			senderCodeSize := extcodesize(_who)
		}
	    return senderCodeSize == 0;
	}

	 

	 
	modifier when_active { require (isActive()); _; }

	 
	modifier before_beginning { require (now < beginTime); _; }

	 
	modifier when_ended { require (now >= endTime); _; }

	 
	modifier when_not_halted { require (!halted); _; }

	 
	modifier only_buyins(address _who) { require (buyins[_who].accounted != 0); _; }

	 
	modifier only_admin { require (msg.sender == admin); _; }

	 
	 
	modifier only_eligible(address who, uint8 v, bytes32 r, bytes32 s) {
		require (
			ecrecover(STATEMENT_HASH, v, r, s) == who &&
			certifier.certified(who) &&
			isBasicAccount(who) &&
			msg.value >= DUST_LIMIT
		);
		_;
	}

	 
	modifier only_basic(address who) { require (isBasicAccount(who)); _; }

	 

	struct Account {
		uint128 accounted;	 
		uint128 received;	 
	}

	 
	mapping (address => Account) public buyins;

	 
	uint public totalReceived = 0;

	 
	uint public totalAccounted = 0;

	 
	uint public totalFinalised = 0;

	 
	uint public endTime;

	 
	 
	uint public endPrice;

	 
	bool public halted;

	 
	uint8 public currentBonus = 15;

	 
	uint32 public lastNewInterest;

	 

	 
	Token public tokenContract;

	 
	Certifier public certifier;

	 
	address public treasury;

	 
	address public admin;

	 
	uint public beginTime;

	 
	 
	uint public tokenCap;

	 
	 
	uint public eraIndex;

	 
	uint constant public ERA_PERIOD = 5 minutes;

	 

	 
	uint constant public DUST_LIMIT = 5 finney;

	 
	 
	 
	 
	 
	 
	bytes32 constant public STATEMENT_HASH = 0x2cedb9c5443254bae6c4f44a31abcb33ec27a0bd03eb58e22e38cdb8b366876d;

	 
	uint constant public BONUS_MIN_DURATION = 1 hours;

	 
	uint constant public BONUS_MAX_DURATION = 24 hours;

	 
	uint constant public BONUS_LATCH = 2;

	 
	uint constant public USDWEI = 3226 szabo;

	 
	uint constant public DIVISOR = 1000;
}