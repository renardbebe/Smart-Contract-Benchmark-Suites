 

pragma solidity ^0.4.19;

 

contract ClaimRegistry {
    function getSingleSubjectByAddress(address linkedAddress, uint subjectIndex) public view returns(address subject);
    function getSubjectClaimSetSize(address subject, uint typeNameIx, uint attrNameIx) public constant returns (uint) ;
    function getSubjectClaimSetEntryAt(address subject, uint typeNameIx, uint attrNameIx, uint ix) public constant returns (address issuer, uint url);
    function getSubjectCountByAddress(address linkedAddress) public view returns(uint subjectCount);
 }

 

contract NotakeyVerifierForICOP {

    uint public constant ICO_CONTRIBUTOR_TYPE = 6;
    uint public constant REPORT_BUNDLE = 6;
    uint public constant NATIONALITY_INDEX = 7;

    address public claimRegistryAddr;
    address public trustedIssuerAddr;
     

    uint public constant USA = 883423532389192164791648750371459257913741948437809479060803100646309888;
         
    uint public constant CHINA = 8796093022208;
         
    uint public constant SOUTH_KOREA = 83076749736557242056487941267521536;
         

     event GotUnregisteredPaymentAddress(address indexed paymentAddress);


    function NotakeyVerifierForICOP(address _trustedIssuerAddr, address _claimRegistryAddr) public {
        claimRegistryAddr = _claimRegistryAddr;
        trustedIssuerAddr  = _trustedIssuerAddr;
    }

    modifier onlyVerifiedSenders(address paymentAddress, uint256 nationalityBlacklist) {
         
         
        require(!_preventedByNationalityBlacklist(paymentAddress, nationalityBlacklist));

        _;
    }

    function sanityCheck() public pure returns (string) {
        return "Hello Dashboard";
    }

    function isVerified(address subject, uint256 nationalityBlacklist) public constant onlyVerifiedSenders(subject, nationalityBlacklist) returns (bool) {
        return true;
    }

    function _preventedByNationalityBlacklist(
        address paymentAddress,
        uint256 nationalityBlacklist) internal constant returns (bool)
    {
        var claimRegistry = ClaimRegistry(claimRegistryAddr);

        uint subjectCount = _lookupOwnerIdentityCount(paymentAddress);

        uint256 ignoredClaims;
        uint claimCount;
        address subject;

         
         
        for (uint subjectIndex = 0 ; subjectIndex < subjectCount ; subjectIndex++ ){
            subject = claimRegistry.getSingleSubjectByAddress(paymentAddress, subjectIndex);
            claimCount = claimRegistry.getSubjectClaimSetSize(subject, ICO_CONTRIBUTOR_TYPE, NATIONALITY_INDEX);
            ignoredClaims = 0;

            for (uint i = 0; i < claimCount; ++i) {
                var (issuer, url) = claimRegistry.getSubjectClaimSetEntryAt(subject, ICO_CONTRIBUTOR_TYPE, NATIONALITY_INDEX, i);
                var countryMask = 2**(url-1);

                if (issuer != trustedIssuerAddr) {
                    ignoredClaims += 1;
                } else {
                    if (((countryMask ^ nationalityBlacklist) & countryMask) != countryMask) {
                        return true;
                    }
                }
            }
        }

         
         
         
         
        require((claimCount - ignoredClaims) > 0);

        return false;
    }

    function _lookupOwnerIdentityCount(address paymentAddress) internal constant returns (uint){
        var claimRegistry = ClaimRegistry(claimRegistryAddr);
        var subjectCount = claimRegistry.getSubjectCountByAddress(paymentAddress);

         
         
         
             
             
         

        require(subjectCount > 0);

        return subjectCount;
    }

    function _hasIcoContributorType(address paymentAddress) internal constant returns (bool)
    {
        uint subjectCount = _lookupOwnerIdentityCount(paymentAddress);

        var atLeastOneValidReport = false;
        var atLeastOneValidNationality = false;
        address subject;

        var claimRegistry = ClaimRegistry(claimRegistryAddr);

         
         
        for (uint subjectIndex = 0 ; subjectIndex < subjectCount ; subjectIndex++ ){
            subject = claimRegistry.getSingleSubjectByAddress(paymentAddress, subjectIndex);

            var nationalityCount = claimRegistry.getSubjectClaimSetSize(subject, ICO_CONTRIBUTOR_TYPE, NATIONALITY_INDEX);
            for (uint nationalityIndex = 0; nationalityIndex < nationalityCount; ++nationalityIndex) {
                var (nationalityIssuer,) = claimRegistry.getSubjectClaimSetEntryAt(subject, ICO_CONTRIBUTOR_TYPE, NATIONALITY_INDEX, nationalityIndex);
                if (nationalityIssuer == trustedIssuerAddr) {
                    atLeastOneValidNationality = true;
                    break;
                }
            }

            var reportCount = claimRegistry.getSubjectClaimSetSize(subject, ICO_CONTRIBUTOR_TYPE, REPORT_BUNDLE);
            for (uint reportIndex = 0; reportIndex < reportCount; ++reportIndex) {
                var (reportIssuer,) = claimRegistry.getSubjectClaimSetEntryAt(subject, ICO_CONTRIBUTOR_TYPE, REPORT_BUNDLE, reportIndex);
                if (reportIssuer == trustedIssuerAddr) {
                    atLeastOneValidReport = true;
                    break;
                }
            }
        }

        return atLeastOneValidNationality && atLeastOneValidReport;
    }
}

 

 
 
 
 
 
 
 
 

pragma solidity ^0.4.19;



 
contract Token {
  function transferFrom(address from, address to, uint256 value) public returns (bool);
}

 
 
 
 
contract SecondPriceAuction {
	 

	 
	event Buyin(address indexed who, uint accounted, uint received, uint price);

	 
	event Injected(address indexed who, uint accounted, uint received);

	 
	event Ticked(uint era, uint received, uint accounted);

	 
	event Ended(uint price);

	 
	event Finalised(address indexed who, uint tokens);

	 
	event Retired();

	 

	 
	 
	 
	 
	 
	function SecondPriceAuction(
		address _trustedClaimIssuer,
		address _notakeyClaimRegistry,
		address _tokenContract,
		address _treasury,
		address _admin,
		uint _beginTime,
		uint _tokenCap
	)
		public
	{
		 
		verifier = new NotakeyVerifierForICOP(_trustedClaimIssuer, _notakeyClaimRegistry);

		tokenContract = Token(_tokenContract);
		treasury = _treasury;
		admin = _admin;
		beginTime = _beginTime;
		tokenCap = _tokenCap;
		endTime = beginTime + DEFAULT_AUCTION_LENGTH;
	}

	function() public payable { buyin(); }

	 
	function moveStartDate(uint newStart)
		public
		before_beginning
		only_admin
	{
		beginTime = newStart;
		endTime = calculateEndTime();
	}

	 
	function buyin()
		public
		payable
		when_not_halted
		when_active
		only_eligible(msg.sender)
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
		require (tokenContract.transferFrom(treasury, _who, tokens));

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
		var factor = tokenCap / DIVISOR * EURWEI;
		uint16 scaleDownRatio = 1;  
		return beginTime + (182035 * factor / (totalAccounted + factor / 10 ) - 0) / scaleDownRatio;
	}

	 
	 
	 
	function currentPrice() public constant when_active returns (uint weiPerIndivisibleTokenPart) {
		return ((EURWEI * 184325000 / (now - beginTime + 5760) - EURWEI*5) / DIVISOR);
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

	 
	 
	modifier only_eligible(address who) {
		require (
			verifier.isVerified(who, verifier.USA() | verifier.CHINA() | verifier.SOUTH_KOREA()) &&
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

	 
	NotakeyVerifierForICOP public verifier;

	 
	address public treasury;

	 
	address public admin;

	 
	uint public beginTime;

	 
	 
	uint public tokenCap;

	 
	 
	uint public eraIndex;

	 
	uint constant public ERA_PERIOD = 5 minutes;

	 

	 
	uint constant public DUST_LIMIT = 5 finney;

	 
	 
	 
	 

	 
	uint constant public BONUS_MIN_DURATION = 1 hours;

	 
	uint constant public BONUS_MAX_DURATION = 12 hours;

	 
	uint constant public BONUS_LATCH = 2;

	 
	uint constant public EURWEI = 2000 szabo;  

	 
	uint constant public DEFAULT_AUCTION_LENGTH = 2 days;

	 
	uint constant public DIVISOR = 1000;
}