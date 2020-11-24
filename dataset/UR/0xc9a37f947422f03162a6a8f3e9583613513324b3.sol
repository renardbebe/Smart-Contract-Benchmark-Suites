 

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
    uint public constant PURCHASE_AMOUNT_CAP = 9000000;

     
    struct EarlyPurchase {
        address purchaser;
        uint amount;         
        uint purchasedAt;    
    }

     
    AbstractStarbaseCrowdsale public starbaseCrowdsale;

     
    address public owner;
    EarlyPurchase[] public earlyPurchases;
    uint public earlyPurchaseClosedAt;

     
    modifier noEther() {
        if (msg.value > 0) {
            throw;
        }
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }

    modifier onlyBeforeCrowdsale() {
        if (address(starbaseCrowdsale) != 0 &&
            starbaseCrowdsale.startDate() > 0)
        {
            throw;
        }
        _;
    }

    modifier onlyEarlyPurchaseTerm() {
        if (earlyPurchaseClosedAt > 0) {
            throw;
        }
        _;
    }

     
     
     
    function purchasedAmountBy(address purchaser)
        external
        constant
        noEther
        returns (uint amount)
    {
        for (uint i; i < earlyPurchases.length; i++) {
            if (earlyPurchases[i].purchaser == purchaser) {
                amount += earlyPurchases[i].amount;
            }
        }
    }

     
    function totalAmountOfEarlyPurchases()
        constant
        noEther
        returns (uint totalAmount)
    {
        for (uint i; i < earlyPurchases.length; i++) {
            totalAmount += earlyPurchases[i].amount;
        }
    }

     
    function numberOfEarlyPurchases()
        external
        constant
        noEther
        returns (uint)
    {
        return earlyPurchases.length;
    }

     
     
     
     
    function appendEarlyPurchase(address purchaser, uint amount, uint purchasedAt)
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

        if (purchasedAt == 0 || purchasedAt > now) {
            throw;
        }

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

     
    function () {
        throw;
    }
}


contract StarbaseEarlyPurchaseAmendment {
     
    event EarlyPurchaseInvalidated(uint epIdx);
    event EarlyPurchaseAmended(uint epIdx);

     
    AbstractStarbaseCrowdsale public starbaseCrowdsale;
    StarbaseEarlyPurchase public starbaseEarlyPurchase;

     
    address public owner;
    uint[] public invalidEarlyPurchaseIndexes;
    uint[] public amendedEarlyPurchaseIndexes;
    mapping (uint => StarbaseEarlyPurchase.EarlyPurchase) public amendedEarlyPurchases;

     
    modifier noEther() {
        if (msg.value > 0) {
            throw;
        }
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }

    modifier onlyBeforeCrowdsale() {
        if (address(starbaseCrowdsale) != 0 &&
            starbaseCrowdsale.startDate() > 0)
        {
            throw;
        }
        _;
    }

    modifier onlyEarlyPurchasesLoaded() {
        if (address(starbaseEarlyPurchase) == 0) {
            throw;
        }
        _;
    }

     
     
     
    function earlyPurchases(uint earlyPurchaseIndex)
        external
        constant
        onlyEarlyPurchasesLoaded
        returns (address purchaser, uint amount, uint purchasedAt)
    {
        return starbaseEarlyPurchase.earlyPurchases(earlyPurchaseIndex);
    }

     
     
    function purchasedAmountBy(address purchaser)
        external
        constant
        noEther
        returns (uint amount)
    {
        StarbaseEarlyPurchase.EarlyPurchase[] memory normalizedEP =
            normalizedEarlyPurchases();
        for (uint i; i < normalizedEP.length; i++) {
            if (normalizedEP[i].purchaser == purchaser) {
                amount += normalizedEP[i].amount;
            }
        }
    }

     
    function totalAmountOfEarlyPurchases()
        constant
        noEther
        returns (uint totalAmount)
    {
        StarbaseEarlyPurchase.EarlyPurchase[] memory normalizedEP =
            normalizedEarlyPurchases();
        for (uint i; i < normalizedEP.length; i++) {
            totalAmount += normalizedEP[i].amount;
        }
    }

     
    function numberOfEarlyPurchases()
        external
        constant
        noEther
        returns (uint)
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

     
    function invalidateEarlyPurchase(uint earlyPurchaseIndex)
        external
        noEther
        onlyOwner
        onlyEarlyPurchasesLoaded
        onlyBeforeCrowdsale
        returns (bool)
    {
        if (numberOfRawEarlyPurchases() <= earlyPurchaseIndex) {
            throw;   
        }

        for (uint i; i < invalidEarlyPurchaseIndexes.length; i++) {
            if (invalidEarlyPurchaseIndexes[i] == earlyPurchaseIndex) {
                throw;   
            }
        }

        invalidEarlyPurchaseIndexes.push(earlyPurchaseIndex);
        EarlyPurchaseInvalidated(earlyPurchaseIndex);
        return true;
    }

    function isInvalidEarlyPurchase(uint earlyPurchaseIndex)
        constant
        noEther
        returns (bool)
    {
        if (numberOfRawEarlyPurchases() <= earlyPurchaseIndex) {
            throw;   
        }

        for (uint i; i < invalidEarlyPurchaseIndexes.length; i++) {
            if (invalidEarlyPurchaseIndexes[i] == earlyPurchaseIndex) {
                return true;
            }
        }
        return false;
    }

    function amendEarlyPurchase(uint earlyPurchaseIndex, address purchaser, uint amount, uint purchasedAt)
        external
        noEther
        onlyOwner
        onlyEarlyPurchasesLoaded
        onlyBeforeCrowdsale
        returns (bool)
    {
        if (purchasedAt == 0 || purchasedAt > now) {
            throw;
        }

        if (numberOfRawEarlyPurchases() <= earlyPurchaseIndex) {
            throw;   
        }

        if (isInvalidEarlyPurchase(earlyPurchaseIndex)) {
            throw;   
        }

        if (!isAmendedEarlyPurchase(earlyPurchaseIndex)) {
            amendedEarlyPurchaseIndexes.push(earlyPurchaseIndex);
        }

        amendedEarlyPurchases[earlyPurchaseIndex] =
            StarbaseEarlyPurchase.EarlyPurchase(purchaser, amount, purchasedAt);
        EarlyPurchaseAmended(earlyPurchaseIndex);
        return true;
    }

    function isAmendedEarlyPurchase(uint earlyPurchaseIndex)
        constant
        noEther
        returns (bool)
    {
        if (numberOfRawEarlyPurchases() <= earlyPurchaseIndex) {
            throw;   
        }

        for (uint i; i < amendedEarlyPurchaseIndexes.length; i++) {
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
        if (starbaseEarlyPurchaseAddress == 0 ||
            address(starbaseEarlyPurchase) != 0)
        {
            throw;
        }

        starbaseEarlyPurchase = StarbaseEarlyPurchase(starbaseEarlyPurchaseAddress);
        if (starbaseEarlyPurchase.earlyPurchaseClosedAt() == 0) {
            throw;    
        }
        return true;
    }

     
    function StarbaseEarlyPurchaseAmendment() noEther {
        owner = msg.sender;
    }

     
    function () {
        throw;
    }

     
    function normalizedEarlyPurchases()
        constant
        internal
        returns (StarbaseEarlyPurchase.EarlyPurchase[] normalizedEP)
    {
        uint rawEPCount = numberOfRawEarlyPurchases();
        normalizedEP = new StarbaseEarlyPurchase.EarlyPurchase[](
            rawEPCount - invalidEarlyPurchaseIndexes.length);

        uint normalizedIdx;
        for (uint i; i < rawEPCount; i++) {
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

    function getEarlyPurchase(uint earlyPurchaseIndex)
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
        returns (uint)
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
    uint256 public totalAmountOfEarlyPurchasesInCny;  

     
    uint256 public maxCrowdsaleCap;      
    uint256 public totalAmountOfPurchasesInCny;  
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
        onlyOwner
    {
        assert(startDate == 0 && block.number >= purchaseStartBlock);    
        startCrowdsale(timestamp);
    }

     
    function endCrowdsale(uint256 timestamp)
        external
        onlyOwner
    {
        assert(timestamp > 0 && timestamp <= now);
        assert(block.number > purchaseStartBlock && endedAt == 0);    
        endedAt = timestamp;
        totalAmountOfEarlyPurchasesInCny = totalAmountOfEarlyPurchasesWithBonus();
        totalAmountOfPurchasesInCny = totalRaisedAmountInCny();
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
                totalAmountOfPurchasesInCny;

            numOfPurchasedTokensOnCsBy[msg.sender] =
                SafeMath.add(numOfPurchasedTokensOnCsBy[msg.sender], tokenCount);
            assert(starbaseToken.allocateToCrowdsalePurchaser(msg.sender, tokenCount));
            numOfDeliveredCrowdsalePurchases++;
        }

         

        if (earlyPurchasedAmountBy[msg.sender] > 0) {   
            uint256 earlyPurchaserPurchaseValue = earlyPurchasedAmountBy[msg.sender];
            earlyPurchasedAmountBy[msg.sender] = 0;

            uint256 epTokenCalculationFromEPTokenAmount = SafeMath.mul(earlyPurchaseTokenAmount, earlyPurchaserPurchaseValue) / totalAmountOfEarlyPurchasesInCny;

            uint256 epTokenCalculationFromCrowdsaleTokenAmount = SafeMath.mul(crowdsaleTokenAmount, earlyPurchaserPurchaseValue) / totalAmountOfPurchasesInCny;

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
            }

            numOfLoadedEarlyPurchases = SafeMath.add(numOfLoadedEarlyPurchases, 1);
        }

        assert(numOfLoadedEarlyPurchases <= numOfOrigEp);
        if (numOfLoadedEarlyPurchases == numOfOrigEp) {
            earlyPurchasesLoaded = true;     
        }
        return true;
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

     
    function totalAmountOfCrowdsalePurchases() constant public returns (uint256 amount) {
        for (uint256 i; i < crowdsalePurchases.length; i++) {
            amount = SafeMath.add(amount, crowdsalePurchases[i].amount);
        }
    }

     
    function totalAmountOfCrowdsalePurchasesWithoutBonus() constant public returns (uint256 amount) {
        for (uint256 i; i < crowdsalePurchases.length; i++) {
            amount = SafeMath.add(amount, crowdsalePurchases[i].rawAmount);
        }
    }

     
    function totalRaisedAmountInCny() constant public returns (uint256) {
        return SafeMath.add(totalAmountOfEarlyPurchasesWithBonus(), totalAmountOfCrowdsalePurchases());
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

        return true;
    }

     

     
    function startCrowdsale(uint256 timestamp) internal {
        startDate = timestamp;
        uint256 presaleAmount = totalAmountOfCrowdsalePurchasesWithoutBonus();
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
            require(totalAmountOfCrowdsalePurchasesWithoutBonus() < maxCrowdsaleCap);    

            uint256 crowdsaleTotalAmountAfterPurchase =
                SafeMath.add(totalAmountOfCrowdsalePurchasesWithoutBonus(), amount);

             
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

            if (amount.add(totalAmountOfCrowdsalePurchasesWithoutBonus()) >= bonusRange)
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