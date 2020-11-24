 

pragma solidity ^0.4.13;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract AbstractStarbaseToken {
    function isFundraiser(address fundraiserAddress) public returns (bool);
    function company() public returns (address);
    function allocateToCrowdsalePurchaser(address to, uint256 value) public returns (bool);
    function allocateToMarketingSupporter(address to, uint256 value) public returns (bool);
}


contract AbstractStarbaseCrowdsale {
    function startDate() constant returns (uint256) {}
    function endedAt() constant returns (uint256) {}
    function isEnded() constant returns (bool);
    function totalRaisedAmountInCny() constant returns (uint256);
    function numOfPurchasedTokensOnCsBy(address purchaser) constant returns (uint256);
    function numOfPurchasedTokensOnEpBy(address purchaser) constant returns (uint256);
}

 
 
contract StarbaseEarlyPurchase {
     
    string public constant PURCHASE_AMOUNT_UNIT = 'CNY';     
    string public constant PURCHASE_AMOUNT_RATE_REFERENCE = 'http: 
    uint256 public constant PURCHASE_AMOUNT_CAP = 9000000;

     
    struct EarlyPurchase {
        address purchaser;
        uint256 amount;         
        uint256 purchasedAt;    
    }

     
    AbstractStarbaseCrowdsale public starbaseCrowdsale;

     
    address public owner;
    EarlyPurchase[] public earlyPurchases;
    uint256 public earlyPurchaseClosedAt;

     
    modifier noEther() {
        require(msg.value == 0);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyBeforeCrowdsale() {
        assert(address(starbaseCrowdsale) == address(0) || starbaseCrowdsale.startDate() == 0);
        _;
    }

    modifier onlyEarlyPurchaseTerm() {
        assert(earlyPurchaseClosedAt <= 0);
        _;
    }

     

     
    function purchasedAmountBy(address purchaser)
        external
        constant
        noEther
        returns (uint256 amount)
    {
        for (uint256 i; i < earlyPurchases.length; i++) {
            if (earlyPurchases[i].purchaser == purchaser) {
                amount += earlyPurchases[i].amount;
            }
        }
    }

     
    function totalAmountOfEarlyPurchases()
        constant
        noEther
        public
        returns (uint256 totalAmount)
    {
        for (uint256 i; i < earlyPurchases.length; i++) {
            totalAmount += earlyPurchases[i].amount;
        }
    }

     
    function numberOfEarlyPurchases()
        external
        constant
        noEther
        returns (uint256)
    {
        return earlyPurchases.length;
    }

     
    function appendEarlyPurchase(address purchaser, uint256 amount, uint256 purchasedAt)
        external
        noEther
        onlyOwner
        onlyBeforeCrowdsale
        onlyEarlyPurchaseTerm
        returns (bool)
    {
        if (amount == 0 ||
            totalAmountOfEarlyPurchases() + amount > PURCHASE_AMOUNT_CAP)
        {
            return false;
        }

        assert(purchasedAt != 0 || purchasedAt <= now);

        earlyPurchases.push(EarlyPurchase(purchaser, amount, purchasedAt));
        return true;
    }

     
    function closeEarlyPurchase()
        external
        noEther
        onlyOwner
        returns (bool)
    {
        earlyPurchaseClosedAt = now;
    }

     
    function setup(address starbaseCrowdsaleAddress)
        external
        noEther
        onlyOwner
        returns (bool)
    {
        if (address(starbaseCrowdsale) == 0) {
            starbaseCrowdsale = AbstractStarbaseCrowdsale(starbaseCrowdsaleAddress);
            return true;
        }
        return false;
    }

     
    function StarbaseEarlyPurchase() noEther {
        owner = msg.sender;
    }
}

 
 
contract StarbaseEarlyPurchaseAmendment {
     
    event EarlyPurchaseInvalidated(uint256 epIdx);
    event EarlyPurchaseAmended(uint256 epIdx);

     
    AbstractStarbaseCrowdsale public starbaseCrowdsale;
    StarbaseEarlyPurchase public starbaseEarlyPurchase;

     
    address public owner;
    uint256[] public invalidEarlyPurchaseIndexes;
    uint256[] public amendedEarlyPurchaseIndexes;
    mapping (uint256 => StarbaseEarlyPurchase.EarlyPurchase) public amendedEarlyPurchases;

     
    modifier noEther() {
        require(msg.value == 0);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyBeforeCrowdsale() {
        assert(address(starbaseCrowdsale) == address(0) || starbaseCrowdsale.startDate() == 0);
        _;
    }

    modifier onlyEarlyPurchasesLoaded() {
        assert(address(starbaseEarlyPurchase) != address(0));
        _;
    }

     

     
    function earlyPurchases(uint256 earlyPurchaseIndex)
        external
        constant
        onlyEarlyPurchasesLoaded
        returns (address purchaser, uint256 amount, uint256 purchasedAt)
    {
        return starbaseEarlyPurchase.earlyPurchases(earlyPurchaseIndex);
    }

     
    function purchasedAmountBy(address purchaser)
        external
        constant
        noEther
        returns (uint256 amount)
    {
        StarbaseEarlyPurchase.EarlyPurchase[] memory normalizedEP =
            normalizedEarlyPurchases();
        for (uint256 i; i < normalizedEP.length; i++) {
            if (normalizedEP[i].purchaser == purchaser) {
                amount += normalizedEP[i].amount;
            }
        }
    }

     
    function totalAmountOfEarlyPurchases()
        constant
        noEther
        public
        returns (uint256 totalAmount)
    {
        StarbaseEarlyPurchase.EarlyPurchase[] memory normalizedEP =
            normalizedEarlyPurchases();
        for (uint256 i; i < normalizedEP.length; i++) {
            totalAmount += normalizedEP[i].amount;
        }
    }

     
    function numberOfEarlyPurchases()
        external
        constant
        noEther
        returns (uint256)
    {
        return normalizedEarlyPurchases().length;
    }

     
    function setup(address starbaseCrowdsaleAddress)
        external
        noEther
        onlyOwner
        returns (bool)
    {
        if (address(starbaseCrowdsale) == 0) {
            starbaseCrowdsale = AbstractStarbaseCrowdsale(starbaseCrowdsaleAddress);
            return true;
        }
        return false;
    }

     

      
    function invalidateEarlyPurchase(uint256 earlyPurchaseIndex)
        external
        noEther
        onlyOwner
        onlyEarlyPurchasesLoaded
        onlyBeforeCrowdsale
        returns (bool)
    {
        assert(numberOfRawEarlyPurchases() > earlyPurchaseIndex);  

        for (uint256 i; i < invalidEarlyPurchaseIndexes.length; i++) {
            assert(invalidEarlyPurchaseIndexes[i] != earlyPurchaseIndex);
        }

        invalidEarlyPurchaseIndexes.push(earlyPurchaseIndex);
        EarlyPurchaseInvalidated(earlyPurchaseIndex);
        return true;
    }

     
    function isInvalidEarlyPurchase(uint256 earlyPurchaseIndex)
        constant
        noEther
        public
        returns (bool)
    {
        assert(numberOfRawEarlyPurchases() > earlyPurchaseIndex);  


        for (uint256 i; i < invalidEarlyPurchaseIndexes.length; i++) {
            if (invalidEarlyPurchaseIndexes[i] == earlyPurchaseIndex) {
                return true;
            }
        }
        return false;
    }

     
    function amendEarlyPurchase(uint256 earlyPurchaseIndex, address purchaser, uint256 amount, uint256 purchasedAt)
        external
        noEther
        onlyOwner
        onlyEarlyPurchasesLoaded
        onlyBeforeCrowdsale
        returns (bool)
    {
        assert(purchasedAt != 0 || purchasedAt <= now);

        assert(numberOfRawEarlyPurchases() > earlyPurchaseIndex);

        assert(!isInvalidEarlyPurchase(earlyPurchaseIndex));  

        if (!isAmendedEarlyPurchase(earlyPurchaseIndex)) {
            amendedEarlyPurchaseIndexes.push(earlyPurchaseIndex);
        }

        amendedEarlyPurchases[earlyPurchaseIndex] =
            StarbaseEarlyPurchase.EarlyPurchase(purchaser, amount, purchasedAt);
        EarlyPurchaseAmended(earlyPurchaseIndex);
        return true;
    }

     
    function isAmendedEarlyPurchase(uint256 earlyPurchaseIndex)
        constant
        noEther
        returns (bool)
    {
        assert(numberOfRawEarlyPurchases() > earlyPurchaseIndex);  

        for (uint256 i; i < amendedEarlyPurchaseIndexes.length; i++) {
            if (amendedEarlyPurchaseIndexes[i] == earlyPurchaseIndex) {
                return true;
            }
        }
        return false;
    }

     
    function loadStarbaseEarlyPurchases(address starbaseEarlyPurchaseAddress)
        external
        noEther
        onlyOwner
        onlyBeforeCrowdsale
        returns (bool)
    {
        assert(starbaseEarlyPurchaseAddress != 0 ||
            address(starbaseEarlyPurchase) == 0);

        starbaseEarlyPurchase = StarbaseEarlyPurchase(starbaseEarlyPurchaseAddress);
        assert(starbaseEarlyPurchase.earlyPurchaseClosedAt() != 0);  

        return true;
    }

     
    function StarbaseEarlyPurchaseAmendment() noEther {
        owner = msg.sender;
    }

     

     
    function normalizedEarlyPurchases()
        constant
        internal
        returns (StarbaseEarlyPurchase.EarlyPurchase[] normalizedEP)
    {
        uint256 rawEPCount = numberOfRawEarlyPurchases();
        normalizedEP = new StarbaseEarlyPurchase.EarlyPurchase[](
            rawEPCount - invalidEarlyPurchaseIndexes.length);

        uint256 normalizedIdx;
        for (uint256 i; i < rawEPCount; i++) {
            if (isInvalidEarlyPurchase(i)) {
                continue;    
            }

            StarbaseEarlyPurchase.EarlyPurchase memory ep;
            if (isAmendedEarlyPurchase(i)) {
                ep = amendedEarlyPurchases[i];   
            } else {
                ep = getEarlyPurchase(i);
            }

            normalizedEP[normalizedIdx] = ep;
            normalizedIdx++;
        }
    }

     
    function getEarlyPurchase(uint256 earlyPurchaseIndex)
        internal
        constant
        onlyEarlyPurchasesLoaded
        returns (StarbaseEarlyPurchase.EarlyPurchase)
    {
        var (purchaser, amount, purchasedAt) =
            starbaseEarlyPurchase.earlyPurchases(earlyPurchaseIndex);
        return StarbaseEarlyPurchase.EarlyPurchase(purchaser, amount, purchasedAt);
    }

     
    function numberOfRawEarlyPurchases()
        internal
        constant
        onlyEarlyPurchasesLoaded
        returns (uint256)
    {
        return starbaseEarlyPurchase.numberOfEarlyPurchases();
    }
}


contract Certifier {
	event Confirmed(address indexed who);
	event Revoked(address indexed who);
	function certified(address) public constant returns (bool);
	function get(address, string) public constant returns (bytes32);
	function getAddress(address, string) public constant returns (address);
	function getUint(address, string) public constant returns (uint);
}

 
contract StarbaseCrowdsale is Ownable {
    using SafeMath for uint256;
     
    event CrowdsaleEnded(uint256 endedAt);
    event StarbasePurchasedWithEth(address purchaser, uint256 amount, uint256 rawAmount, uint256 cnyEthRate);
    event CnyEthRateUpdated(uint256 cnyEthRate);
    event CnyBtcRateUpdated(uint256 cnyBtcRate);
    event QualifiedPartnerAddress(address qualifiedPartner);

     
    AbstractStarbaseToken public starbaseToken;
    StarbaseEarlyPurchaseAmendment public starbaseEpAmendment;
    Certifier public picopsCertifier;

     
    uint256 constant public crowdsaleTokenAmount = 125000000e18;
    uint256 constant public earlyPurchaseTokenAmount = 50000000e18;
    uint256 constant public MIN_INVESTMENT = 1;  
    uint256 constant public MAX_CAP = 67000000;  
    string public constant PURCHASE_AMOUNT_UNIT = 'CNY';   

     
    struct CrowdsalePurchase {
        address purchaser;
        uint256 amount;         
        uint256 rawAmount;      
        uint256 purchasedAt;    
    }

    struct QualifiedPartners {
        uint256 amountCap;
        uint256 amountRaised;
        bool    bonaFide;
        uint256 commissionFeePercentage;  
    }

     
    enum BonusMilestones {
        First,
        Second,
        Third,
        Fourth,
        Fifth
    }

     
    BonusMilestones public bonusMilestones = BonusMilestones.First;

     
    uint public numOfDeliveredCrowdsalePurchases;   
    uint public numOfDeliveredEarlyPurchases;   
    uint256 public numOfLoadedEarlyPurchases;  

     
    address[] public earlyPurchasers;
    mapping (address => uint256) public earlyPurchasedAmountBy;  
    bool public earlyPurchasesLoaded = false;   
    uint256 public totalAmountOfEarlyPurchases;  

     
    bool public presalePurchasesLoaded = false;  
    uint256 public maxCrowdsaleCap;      
    uint256 public totalAmountOfCrowdsalePurchases;  
    uint256 public totalAmountOfCrowdsalePurchasesWithoutBonus;  
    mapping (address => QualifiedPartners) public qualifiedPartners;
    uint256 public purchaseStartBlock;   
    uint256 public startDate;
    uint256 public endedAt;
    CrowdsalePurchase[] public crowdsalePurchases;
    mapping (address => uint256) public crowdsalePurchaseAmountBy;  
    uint256 public cnyBtcRate;  
    uint256 public cnyEthRate;

     
    uint256 public firstBonusEnds;
    uint256 public secondBonusEnds;
    uint256 public thirdBonusEnds;
    uint256 public fourthBonusEnds;

     
    mapping (address => uint256) public numOfPurchasedTokensOnCsBy;     
    mapping (address => uint256) public numOfPurchasedTokensOnEpBy;     

     
    modifier minInvestment() {
         
        assert(msg.value >= MIN_INVESTMENT);
        _;
    }

    modifier whenNotStarted() {
        assert(startDate == 0);
        _;
    }

    modifier whenEnded() {
        assert(isEnded());
        _;
    }

    modifier hasBalance() {
        assert(this.balance > 0);
        _;
    }
    modifier rateIsSet(uint256 _rate) {
        assert(_rate != 0);
        _;
    }

    modifier whenNotEnded() {
        assert(!isEnded());
        _;
    }

    modifier tokensNotDelivered() {
        assert(numOfDeliveredCrowdsalePurchases == 0);
        assert(numOfDeliveredEarlyPurchases == 0);
        _;
    }

    modifier onlyFundraiser() {
        assert(address(starbaseToken) != 0);
        assert(starbaseToken.isFundraiser(msg.sender));
        _;
    }

    modifier onlyQualifiedPartner() {
        assert(qualifiedPartners[msg.sender].bonaFide);
        _;
    }

    modifier onlyQualifiedPartnerORPicopsCertified() {
        assert(qualifiedPartners[msg.sender].bonaFide || picopsCertifier.certified(msg.sender));
        _;
    }

     
     
    function StarbaseCrowdsale(address starbaseEpAddr, address picopsCertifierAddr) {
        require(starbaseEpAddr != 0 && picopsCertifierAddr != 0);
        owner = msg.sender;
        starbaseEpAmendment = StarbaseEarlyPurchaseAmendment(starbaseEpAddr);
        picopsCertifier = Certifier(picopsCertifierAddr);
    }

     
    function() payable {
        redirectToPurchase();
    }

     

     
    function setup(address starbaseTokenAddress, uint256 _purchaseStartBlock)
        external
        onlyOwner
        returns (bool)
    {
        require(starbaseTokenAddress != address(0));
        require(address(starbaseToken) == 0);
        starbaseToken = AbstractStarbaseToken(starbaseTokenAddress);
        purchaseStartBlock = _purchaseStartBlock;

         
        maxCrowdsaleCap = MAX_CAP.sub(totalAmountOfEarlyPurchasesWithoutBonus());

        assert(maxCrowdsaleCap > 0);

        return true;
    }

     
    function withdrawForCompany()
        external
        onlyFundraiser
        hasBalance
    {
        address company = starbaseToken.company();
        require(company != address(0));
        company.transfer(this.balance);
    }

     
    function updatePurchaseStartBlock(uint256 _purchaseStartBlock)
        external
        whenNotStarted
        onlyFundraiser
        returns (bool)
    {
        purchaseStartBlock = _purchaseStartBlock;
        return true;
    }

     
    function updateCnyEthRate(uint256 rate)
        external
        onlyFundraiser
        returns (bool)
    {
        cnyEthRate = rate;
        CnyEthRateUpdated(cnyEthRate);
        return true;
    }

     
    function updateCnyBtcRate(uint256 rate)
        external
        onlyFundraiser
        returns (bool)
    {
        cnyBtcRate = rate;
        CnyBtcRateUpdated(cnyBtcRate);
        return true;
    }

     
    function ownerStartsCrowdsale(uint256 timestamp)
        external
        whenNotStarted
        onlyOwner
    {
        assert(block.number >= purchaseStartBlock);    
        startCrowdsale(timestamp);
    }

     
    function endCrowdsale(uint256 timestamp)
        external
        onlyOwner
    {
        assert(timestamp > 0 && timestamp <= now);
        assert(block.number >= purchaseStartBlock && endedAt == 0);    
        endedAt = timestamp;
        CrowdsaleEnded(endedAt);
    }

     
    function endCrowdsale() internal {
        assert(block.number >= purchaseStartBlock && endedAt == 0);
        endedAt = now;
        CrowdsaleEnded(endedAt);
    }

     
    function withdrawPurchasedTokens()
        external
        whenEnded
        returns (bool)
    {
        assert(earlyPurchasesLoaded);
        assert(address(starbaseToken) != 0);

         

        if (crowdsalePurchaseAmountBy[msg.sender] > 0) {
            uint256 crowdsalePurchaseValue = crowdsalePurchaseAmountBy[msg.sender];
            crowdsalePurchaseAmountBy[msg.sender] = 0;

            uint256 tokenCount =
                SafeMath.mul(crowdsaleTokenAmount, crowdsalePurchaseValue) /
                totalRaisedAmountInCny();

            numOfPurchasedTokensOnCsBy[msg.sender] =
                SafeMath.add(numOfPurchasedTokensOnCsBy[msg.sender], tokenCount);
            assert(starbaseToken.allocateToCrowdsalePurchaser(msg.sender, tokenCount));
            numOfDeliveredCrowdsalePurchases++;
        }

         

        if (earlyPurchasedAmountBy[msg.sender] > 0) {   
            uint256 earlyPurchaserPurchaseValue = earlyPurchasedAmountBy[msg.sender];
            earlyPurchasedAmountBy[msg.sender] = 0;

            uint256 epTokenCalculationFromEPTokenAmount = SafeMath.mul(earlyPurchaseTokenAmount, earlyPurchaserPurchaseValue) / totalAmountOfEarlyPurchases;

            uint256 epTokenCalculationFromCrowdsaleTokenAmount = SafeMath.mul(crowdsaleTokenAmount, earlyPurchaserPurchaseValue) / totalRaisedAmountInCny();

            uint256 epTokenCount = SafeMath.add(epTokenCalculationFromEPTokenAmount, epTokenCalculationFromCrowdsaleTokenAmount);

            numOfPurchasedTokensOnEpBy[msg.sender] = SafeMath.add(numOfPurchasedTokensOnEpBy[msg.sender], epTokenCount);
            assert(starbaseToken.allocateToCrowdsalePurchaser(msg.sender, epTokenCount));
            numOfDeliveredEarlyPurchases++;
        }

        return true;
    }

     
    function loadEarlyPurchases() external onlyOwner returns (bool) {
        if (earlyPurchasesLoaded) {
            return false;     
        }

        uint256 numOfOrigEp = starbaseEpAmendment
            .starbaseEarlyPurchase()
            .numberOfEarlyPurchases();

        for (uint256 i = numOfLoadedEarlyPurchases; i < numOfOrigEp && msg.gas > 200000; i++) {
            if (starbaseEpAmendment.isInvalidEarlyPurchase(i)) {
                numOfLoadedEarlyPurchases = SafeMath.add(numOfLoadedEarlyPurchases, 1);
                continue;
            }
            var (purchaser, amount,) =
                starbaseEpAmendment.isAmendedEarlyPurchase(i)
                ? starbaseEpAmendment.amendedEarlyPurchases(i)
                : starbaseEpAmendment.earlyPurchases(i);
            if (amount > 0) {
                if (earlyPurchasedAmountBy[purchaser] == 0) {
                    earlyPurchasers.push(purchaser);
                }
                 
                uint256 bonus = SafeMath.mul(amount, 20) / 100;
                uint256 amountWithBonus = SafeMath.add(amount, bonus);

                earlyPurchasedAmountBy[purchaser] = SafeMath.add(earlyPurchasedAmountBy[purchaser], amountWithBonus);
                totalAmountOfEarlyPurchases = totalAmountOfEarlyPurchases.add(amountWithBonus);
            }

            numOfLoadedEarlyPurchases = SafeMath.add(numOfLoadedEarlyPurchases, 1);
        }

        assert(numOfLoadedEarlyPurchases <= numOfOrigEp);
        if (numOfLoadedEarlyPurchases == numOfOrigEp) {
            earlyPurchasesLoaded = true;     
        }
        return true;
    }

     
    function loadPresalePurchases(address starbaseCrowdsalePresale)
        external
        onlyOwner
        whenNotEnded
    {
        require(starbaseCrowdsalePresale != 0);
        require(!presalePurchasesLoaded);
        StarbaseCrowdsale presale = StarbaseCrowdsale(starbaseCrowdsalePresale);
        for (uint i; i < presale.numOfPurchases(); i++) {
            var (purchaser, amount, rawAmount, purchasedAt) =
                presale.crowdsalePurchases(i);   
            crowdsalePurchases.push(CrowdsalePurchase(purchaser, amount, rawAmount, purchasedAt));

             
            crowdsalePurchaseAmountBy[purchaser] = SafeMath.add(crowdsalePurchaseAmountBy[purchaser], amount);
            totalAmountOfCrowdsalePurchases = totalAmountOfCrowdsalePurchases.add(amount);
            totalAmountOfCrowdsalePurchasesWithoutBonus = totalAmountOfCrowdsalePurchasesWithoutBonus.add(rawAmount);
        }
        presalePurchasesLoaded = true;
    }

     
    function setQualifiedPartner(address _qualifiedPartner, uint256 _amountCap, uint256 _commissionFeePercentage)
        external
        onlyOwner
    {
        assert(!qualifiedPartners[_qualifiedPartner].bonaFide);
        qualifiedPartners[_qualifiedPartner].bonaFide = true;
        qualifiedPartners[_qualifiedPartner].amountCap = _amountCap;
        qualifiedPartners[_qualifiedPartner].commissionFeePercentage = _commissionFeePercentage;
        QualifiedPartnerAddress(_qualifiedPartner);
    }

     
    function unlistQualifiedPartner(address _qualifiedPartner) external onlyOwner {
        assert(qualifiedPartners[_qualifiedPartner].bonaFide);
        qualifiedPartners[_qualifiedPartner].bonaFide = false;
    }

     
    function updateQualifiedPartnerCapAmount(address _qualifiedPartner, uint256 _amountCap) external onlyOwner {
        assert(qualifiedPartners[_qualifiedPartner].bonaFide);
        qualifiedPartners[_qualifiedPartner].amountCap = _amountCap;
    }

     

     
    function isEnded() constant public returns (bool) {
        return (endedAt > 0 && endedAt <= now);
    }

     
    function numOfPurchases() constant public returns (uint256) {
        return crowdsalePurchases.length;
    }

     
    function totalRaisedAmountInCny() constant public returns (uint256) {
        return totalAmountOfEarlyPurchases.add(totalAmountOfCrowdsalePurchases);
    }

     
    function totalAmountOfEarlyPurchasesWithBonus() constant public returns(uint256) {
       return starbaseEpAmendment.totalAmountOfEarlyPurchases().mul(120).div(100);
    }

     
    function totalAmountOfEarlyPurchasesWithoutBonus() constant public returns(uint256) {
       return starbaseEpAmendment.totalAmountOfEarlyPurchases();
    }

     
    function purchaseAsQualifiedPartner()
        payable
        public
        rateIsSet(cnyEthRate)
        onlyQualifiedPartner
        returns (bool)
    {
        require(msg.value > 0);
        qualifiedPartners[msg.sender].amountRaised = SafeMath.add(msg.value, qualifiedPartners[msg.sender].amountRaised);

        assert(qualifiedPartners[msg.sender].amountRaised <= qualifiedPartners[msg.sender].amountCap);

        uint256 rawAmount = SafeMath.mul(msg.value, cnyEthRate) / 1e18;
        recordPurchase(msg.sender, rawAmount, now);

        if (qualifiedPartners[msg.sender].commissionFeePercentage > 0) {
            sendQualifiedPartnerCommissionFee(msg.sender, msg.value);
        }

        return true;
    }

     
    function purchaseWithEth()
        payable
        public
        minInvestment
        whenNotEnded
        rateIsSet(cnyEthRate)
        onlyQualifiedPartnerORPicopsCertified
        returns (bool)
    {
        require(purchaseStartBlock > 0 && block.number >= purchaseStartBlock);

        if (startDate == 0) {
            startCrowdsale(block.timestamp);
        }

        uint256 rawAmount = SafeMath.mul(msg.value, cnyEthRate) / 1e18;
        recordPurchase(msg.sender, rawAmount, now);

        if (totalAmountOfCrowdsalePurchasesWithoutBonus >= maxCrowdsaleCap) {
            endCrowdsale();  
        }

        return true;
    }

     

     
    function startCrowdsale(uint256 timestamp) internal {
        startDate = timestamp;
        uint256 presaleAmount = totalAmountOfCrowdsalePurchasesWithoutBonus;
        if (maxCrowdsaleCap > presaleAmount) {
            uint256 mainSaleCap = maxCrowdsaleCap.sub(presaleAmount);
            uint256 twentyPercentOfCrowdsalePurchase = mainSaleCap.mul(20).div(100);

             
            firstBonusEnds =  twentyPercentOfCrowdsalePurchase;
            secondBonusEnds = firstBonusEnds.add(twentyPercentOfCrowdsalePurchase);
            thirdBonusEnds =  secondBonusEnds.add(twentyPercentOfCrowdsalePurchase);
            fourthBonusEnds = thirdBonusEnds.add(twentyPercentOfCrowdsalePurchase);
        }
    }

     
    function recordPurchase(
        address purchaser,
        uint256 rawAmount,
        uint256 timestamp
    )
        internal
        returns(uint256 amount)
    {
        amount = rawAmount;  

         
        if (block.number >= purchaseStartBlock) {
            require(totalAmountOfCrowdsalePurchasesWithoutBonus < maxCrowdsaleCap);    

            uint256 crowdsaleTotalAmountAfterPurchase =
                SafeMath.add(totalAmountOfCrowdsalePurchasesWithoutBonus, amount);

             
            if (crowdsaleTotalAmountAfterPurchase > maxCrowdsaleCap) {
              uint256 difference = SafeMath.sub(crowdsaleTotalAmountAfterPurchase, maxCrowdsaleCap);
              uint256 ethValueToReturn = SafeMath.mul(difference, 1e18) / cnyEthRate;
              purchaser.transfer(ethValueToReturn);
              amount = SafeMath.sub(amount, difference);
              rawAmount = amount;
            }
        }

        amount = getBonusAmountCalculation(amount);  

        CrowdsalePurchase memory purchase = CrowdsalePurchase(purchaser, amount, rawAmount, timestamp);
        crowdsalePurchases.push(purchase);
        StarbasePurchasedWithEth(msg.sender, amount, rawAmount, cnyEthRate);
        crowdsalePurchaseAmountBy[purchaser] = SafeMath.add(crowdsalePurchaseAmountBy[purchaser], amount);
        totalAmountOfCrowdsalePurchases = totalAmountOfCrowdsalePurchases.add(amount);
        totalAmountOfCrowdsalePurchasesWithoutBonus = totalAmountOfCrowdsalePurchasesWithoutBonus.add(rawAmount);
        return amount;
    }

     
    function calculateBonus
        (
            BonusMilestones nextMilestone,
            uint256 amount,
            uint256 bonusRange,
            uint256 bonusTier,
            uint256 results
        )
        internal
        returns (uint256 result, uint256 newAmount)
    {
        uint256 bonusCalc;

        if (amount <= bonusRange) {
            bonusCalc = amount.mul(bonusTier).div(100);

            if (amount.add(totalAmountOfCrowdsalePurchasesWithoutBonus) >= bonusRange)
                bonusMilestones = nextMilestone;

            result = results.add(amount).add(bonusCalc);
            newAmount = 0;

        } else {
            bonusCalc = bonusRange.mul(bonusTier).div(100);
            bonusMilestones = nextMilestone;
            result = results.add(bonusRange).add(bonusCalc);
            newAmount = amount.sub(bonusRange);
        }
    }

     
    function getBonusAmountCalculation(uint256 amount) internal returns (uint256) {
        if (block.number < purchaseStartBlock) {
            uint256 bonusFromAmount = amount.mul(30).div(100);  
            return amount.add(bonusFromAmount);
        }

         
        uint256 firstBonusRange = firstBonusEnds;
        uint256 secondBonusRange = secondBonusEnds.sub(firstBonusEnds);
        uint256 thirdBonusRange = thirdBonusEnds.sub(secondBonusEnds);
        uint256 fourthBonusRange = fourthBonusEnds.sub(thirdBonusEnds);
        uint256 result;

        if (bonusMilestones == BonusMilestones.First)
            (result, amount) = calculateBonus(BonusMilestones.Second, amount, firstBonusRange, 20, result);

        if (bonusMilestones == BonusMilestones.Second)
            (result, amount) = calculateBonus(BonusMilestones.Third, amount, secondBonusRange, 15, result);

        if (bonusMilestones == BonusMilestones.Third)
            (result, amount) = calculateBonus(BonusMilestones.Fourth, amount, thirdBonusRange, 10, result);

        if (bonusMilestones == BonusMilestones.Fourth)
            (result, amount) = calculateBonus(BonusMilestones.Fifth, amount, fourthBonusRange, 5, result);

        return result.add(amount);
    }

     
    function sendQualifiedPartnerCommissionFee(address qualifiedPartner, uint256 amountSent) internal {
         
        uint256 commissionFeePercentageCalculationAmount = SafeMath.mul(amountSent, qualifiedPartners[qualifiedPartner].commissionFeePercentage) / 100;

         
        qualifiedPartner.transfer(commissionFeePercentageCalculationAmount);
    }

     
    function redirectToPurchase() internal {
        if (block.number < purchaseStartBlock) {
            purchaseAsQualifiedPartner();
        } else {
            purchaseWithEth();
        }
    }
}

 
contract StarbaseCrowdsaleContractW is Ownable {
    using SafeMath for uint256;

     
    event TokenWithdrawn(address purchaser, uint256 tokenCount);
    event CrowdsalePurchaseBonusLog(
        uint256 purchaseIdx, uint256 rawAmount, uint256 bonus);

     
    AbstractStarbaseToken public starbaseToken;
    StarbaseCrowdsale public starbaseCrowdsale;
    StarbaseEarlyPurchaseAmendment public starbaseEpAmendment;

     
    uint256 constant public crowdsaleTokenAmount = 125000000e18;
    uint256 constant public earlyPurchaseTokenAmount = 50000000e18;

     

     
    address[] public earlyPurchasers;
    mapping (address => uint256) public earlyPurchasedAmountBy;  
    bool public earlyPurchasesLoaded = false;   
    uint256 public totalAmountOfEarlyPurchases;  
    uint public numOfDeliveredEarlyPurchases;   
    uint256 public numOfLoadedEarlyPurchases;  

     
    uint256 public totalAmountOfCrowdsalePurchases;  
    uint256 public totalAmountOfCrowdsalePurchasesWithoutBonus;  
    uint256 public startDate;
    uint256 public endedAt;
    mapping (address => uint256) public crowdsalePurchaseAmountBy;  
    uint public numOfDeliveredCrowdsalePurchases;   

     
    bool public crowdsalePurchasesLoaded = false;    
    uint256 public numOfLoadedCrowdsalePurchases;  
    uint256 public totalAmountOfPresalePurchasesWithoutBonus;   

     
    mapping (address => bool) public tokenWithdrawn;     
    mapping (address => uint256) public numOfPurchasedTokensOnCsBy;     
    mapping (address => uint256) public numOfPurchasedTokensOnEpBy;     

     
    modifier whenEnded() {
        assert(isEnded());
        _;
    }

     

     
    function () { revert(); }

     

     
    function setup(address starbaseTokenAddress, address StarbaseCrowdsaleAddress)
        external
        onlyOwner
    {
        require(starbaseTokenAddress != address(0) && StarbaseCrowdsaleAddress != address(0));
        require(address(starbaseToken) == 0 && address(starbaseCrowdsale) == 0);

        starbaseToken = AbstractStarbaseToken(starbaseTokenAddress);
        starbaseCrowdsale = StarbaseCrowdsale(StarbaseCrowdsaleAddress);
        starbaseEpAmendment = StarbaseEarlyPurchaseAmendment(starbaseCrowdsale.starbaseEpAmendment());

        require(starbaseCrowdsale.startDate() > 0);
        startDate = starbaseCrowdsale.startDate();

        require(starbaseCrowdsale.endedAt() > 0);
        endedAt = starbaseCrowdsale.endedAt();
    }

     
    function loadCrowdsalePurchases(uint256 numOfPresalePurchases)
        external
        onlyOwner
        whenEnded
    {
        require(!crowdsalePurchasesLoaded);

        uint256 numOfPurchases = starbaseCrowdsale.numOfPurchases();

        for (uint256 i = numOfLoadedCrowdsalePurchases; i < numOfPurchases && msg.gas > 200000; i++) {
            var (purchaser, amount, rawAmount,) =
                starbaseCrowdsale.crowdsalePurchases(i);

            uint256 bonus;
            if (i < numOfPresalePurchases) {
                bonus = rawAmount * 30 / 100;    
                totalAmountOfPresalePurchasesWithoutBonus =
                    totalAmountOfPresalePurchasesWithoutBonus.add(rawAmount);
            } else {
                bonus = calculateBonus(rawAmount);  
            }

             
            CrowdsalePurchaseBonusLog(i, rawAmount, bonus);
            amount = rawAmount + bonus;

             
            crowdsalePurchaseAmountBy[purchaser] = SafeMath.add(crowdsalePurchaseAmountBy[purchaser], amount);
            totalAmountOfCrowdsalePurchases = totalAmountOfCrowdsalePurchases.add(amount);
            totalAmountOfCrowdsalePurchasesWithoutBonus = totalAmountOfCrowdsalePurchasesWithoutBonus.add(rawAmount);

            numOfLoadedCrowdsalePurchases++;     
        }

        assert(numOfLoadedCrowdsalePurchases <= numOfPurchases);
        if (numOfLoadedCrowdsalePurchases == numOfPurchases) {
            crowdsalePurchasesLoaded = true;     
        }
    }

     
    function addEarlyPurchases() external onlyOwner returns (bool) {
        if (earlyPurchasesLoaded) {
            return false;     
        }

        uint256 numOfOrigEp = starbaseEpAmendment
            .starbaseEarlyPurchase()
            .numberOfEarlyPurchases();

        for (uint256 i = numOfLoadedEarlyPurchases; i < numOfOrigEp && msg.gas > 200000; i++) {
            if (starbaseEpAmendment.isInvalidEarlyPurchase(i)) {
                numOfLoadedEarlyPurchases = SafeMath.add(numOfLoadedEarlyPurchases, 1);
                continue;
            }
            var (purchaser, amount,) =
                starbaseEpAmendment.isAmendedEarlyPurchase(i)
                ? starbaseEpAmendment.amendedEarlyPurchases(i)
                : starbaseEpAmendment.earlyPurchases(i);
            if (amount > 0) {
                if (earlyPurchasedAmountBy[purchaser] == 0) {
                    earlyPurchasers.push(purchaser);
                }
                 
                uint256 bonus = SafeMath.mul(amount, 10) / 100;
                uint256 amountWithBonus = SafeMath.add(amount, bonus);

                earlyPurchasedAmountBy[purchaser] = SafeMath.add(earlyPurchasedAmountBy[purchaser], amountWithBonus);
                totalAmountOfEarlyPurchases = totalAmountOfEarlyPurchases.add(amountWithBonus);
            }

            numOfLoadedEarlyPurchases = SafeMath.add(numOfLoadedEarlyPurchases, 1);
        }

        assert(numOfLoadedEarlyPurchases <= numOfOrigEp);
        if (numOfLoadedEarlyPurchases == numOfOrigEp) {
            earlyPurchasesLoaded = true;     
        }

        return true;
    }

     
    function withdrawPurchasedTokens()
        external
        whenEnded
    {
        require(crowdsalePurchasesLoaded);
        assert(earlyPurchasesLoaded);
        assert(address(starbaseToken) != 0);

         
        require(!tokenWithdrawn[msg.sender]);
        tokenWithdrawn[msg.sender] = true;

         

        if (crowdsalePurchaseAmountBy[msg.sender] > 0) {
            uint256 crowdsalePurchaseValue = crowdsalePurchaseAmountBy[msg.sender];
            uint256 tokenCount =
                SafeMath.mul(crowdsaleTokenAmount, crowdsalePurchaseValue) /
                totalRaisedAmountInCny();

            numOfPurchasedTokensOnCsBy[msg.sender] =
                SafeMath.add(numOfPurchasedTokensOnCsBy[msg.sender], tokenCount);
            assert(starbaseToken.allocateToCrowdsalePurchaser(msg.sender, tokenCount));
            numOfDeliveredCrowdsalePurchases++;
            TokenWithdrawn(msg.sender, tokenCount);
        }

         

        if (earlyPurchasedAmountBy[msg.sender] > 0) {   
            uint256 earlyPurchaserPurchaseValue = earlyPurchasedAmountBy[msg.sender];
            uint256 epTokenCalculationFromEPTokenAmount = SafeMath.mul(earlyPurchaseTokenAmount, earlyPurchaserPurchaseValue) / totalAmountOfEarlyPurchases;
            uint256 epTokenCalculationFromCrowdsaleTokenAmount = SafeMath.mul(crowdsaleTokenAmount, earlyPurchaserPurchaseValue) / totalRaisedAmountInCny();
            uint256 epTokenCount = SafeMath.add(epTokenCalculationFromEPTokenAmount, epTokenCalculationFromCrowdsaleTokenAmount);

            numOfPurchasedTokensOnEpBy[msg.sender] = SafeMath.add(numOfPurchasedTokensOnEpBy[msg.sender], epTokenCount);
            assert(starbaseToken.allocateToCrowdsalePurchaser(msg.sender, epTokenCount));
            numOfDeliveredEarlyPurchases++;
            TokenWithdrawn(msg.sender, epTokenCount);
        }
    }

     

     
    function isEnded() constant public returns (bool) {
        return (starbaseCrowdsale != address(0) && endedAt > 0);
    }

     
    function totalRaisedAmountInCny() constant public returns (uint256) {
        return totalAmountOfEarlyPurchases.add(totalAmountOfCrowdsalePurchases);
    }

     

     
    function calculateBonus(uint256 rawAmount)
        internal
        returns (uint256 bonus)
    {
        uint256 purchasedAmount =
            totalAmountOfCrowdsalePurchasesWithoutBonus
                .sub(totalAmountOfPresalePurchasesWithoutBonus);
        uint256 e1 = starbaseCrowdsale.firstBonusEnds();
        uint256 e2 = starbaseCrowdsale.secondBonusEnds();
        uint256 e3 = starbaseCrowdsale.thirdBonusEnds();
        uint256 e4 = starbaseCrowdsale.fourthBonusEnds();
        return calculateBonusInRange(purchasedAmount, rawAmount, 0, e1, 20)
            .add(calculateBonusInRange(purchasedAmount, rawAmount, e1, e2, 15))
            .add(calculateBonusInRange(purchasedAmount, rawAmount, e2, e3, 10))
            .add(calculateBonusInRange(purchasedAmount, rawAmount, e3, e4, 5));
    }

    function calculateBonusInRange(
        uint256 purchasedAmount,
        uint256 rawAmount,
        uint256 bonusBegin,
        uint256 bonusEnd,
        uint256 bonusTier
    )
        public
        constant
        returns (uint256 bonus)
    {
        uint256 sum = purchasedAmount + rawAmount;
        if (purchasedAmount > bonusEnd || sum < bonusBegin) {
            return 0;    
        }

        uint256 min = purchasedAmount <= bonusBegin ? bonusBegin : purchasedAmount;
        uint256 max = bonusEnd <= sum ? bonusEnd : sum;
        return max.sub(min) * bonusTier / 100;
    }
}