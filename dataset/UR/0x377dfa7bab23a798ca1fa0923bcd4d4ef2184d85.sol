 

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


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AbstractStarbaseToken is ERC20 {
    function isFundraiser(address fundraiserAddress) public returns (bool);
    function company() public returns (address);
    function allocateToCrowdsalePurchaser(address to, uint256 value) public returns (bool);
    function allocateToMarketingSupporter(address to, uint256 value) public returns (bool);
}

contract AbstractStarbaseCrowdsale {
    function workshop() constant returns (address) {}
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


 
contract StarbaseCrowdsale is Ownable {
     
    event CrowdsaleEnded(uint256 endedAt);
    event StarBasePurchasedWithEth(address purchaser, uint256 amount, uint256 rawAmount, uint256 cnyEthRate, uint256 bonusTokensPercentage);
    event StarBasePurchasedOffChain(address purchaser, uint256 amount, uint256 rawAmount, uint256 cnyBtcRate, uint256 bonusTokensPercentage, string data);
    event CnyEthRateUpdated(uint256 cnyEthRate);
    event CnyBtcRateUpdated(uint256 cnyBtcRate);
    event QualifiedPartnerAddress(address qualifiedPartner);
    event PurchaseInvalidated(uint256 purchaseIdx);
    event PurchaseAmended(uint256 purchaseIdx);

     
    AbstractStarbaseToken public starbaseToken;
    StarbaseEarlyPurchaseAmendment public starbaseEpAmendment;

     
    uint256 constant public crowdsaleTokenAmount = 125000000e18;
    uint256 constant public earlyPurchaseTokenAmount = 50000000e18;
    uint256 constant public MIN_INVESTMENT = 1;  
    uint256 constant public MAX_CROWDSALE_CAP = 60000000;  
    string public constant PURCHASE_AMOUNT_UNIT = 'CNY';   

     
    struct CrowdsalePurchase {
        address purchaser;
        uint256 amount;         
        uint256 rawAmount;      
        uint256 purchasedAt;    
        string data;            
        uint256 bonus;
    }

    struct QualifiedPartners {
        uint256 amountCap;
        uint256 amountRaised;
        bool    bonaFide;
        uint256 commissionFeePercentage;  
    }

     
    address public workshop;  

    uint public numOfDeliveredCrowdsalePurchases = 0;   
    uint public numOfDeliveredEarlyPurchases = 0;   
    uint256 public numOfLoadedEarlyPurchases = 0;  

    address[] public earlyPurchasers;
    mapping (address => QualifiedPartners) public qualifiedPartners;
    mapping (address => uint256) public earlyPurchasedAmountBy;  
    bool public earlyPurchasesLoaded = false;   

     
    uint256 public purchaseStartBlock;   
    uint256 public startDate;
    uint256 public endedAt;
    CrowdsalePurchase[] public crowdsalePurchases;
    uint256 public cnyBtcRate;  
    uint256 public cnyEthRate;

     
    uint256 public firstBonusSalesEnds;
    uint256 public secondBonusSalesEnds;
    uint256 public thirdBonusSalesEnds;
    uint256 public fourthBonusSalesEnds;
    uint256 public fifthBonusSalesEnds;
    uint256 public firstExtendedBonusSalesEnds;
    uint256 public secondExtendedBonusSalesEnds;
    uint256 public thirdExtendedBonusSalesEnds;
    uint256 public fourthExtendedBonusSalesEnds;
    uint256 public fifthExtendedBonusSalesEnds;
    uint256 public sixthExtendedBonusSalesEnds;

     
    mapping(uint256 => CrowdsalePurchase) public invalidatedOrigPurchases;   
    mapping(uint256 => CrowdsalePurchase) public amendedOrigPurchases;       

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

     

     
    function StarbaseCrowdsale(address workshopAddr, address starbaseEpAddr) {
        require(workshopAddr != 0 && starbaseEpAddr != 0);

        owner = msg.sender;
        workshop = workshopAddr;
        starbaseEpAmendment = StarbaseEarlyPurchaseAmendment(starbaseEpAddr);
    }

     
    function() payable {
        redirectToPurchase();
    }

     

     
    function setup(address starbaseTokenAddress, uint256 _purchaseStartBlock)
        external
        onlyOwner
        returns (bool)
    {
        assert(address(starbaseToken) == 0);
        starbaseToken = AbstractStarbaseToken(starbaseTokenAddress);
        purchaseStartBlock = _purchaseStartBlock;
        return true;
    }

     
    function recordOffchainPurchase(
        address purchaser,
        uint256 rawAmount,
        uint256 purchasedAt,
        string data
    )
        external
        onlyFundraiser
        whenNotEnded
        rateIsSet(cnyBtcRate)
        returns (bool)
    {
        require(purchaseStartBlock > 0 && block.number >= purchaseStartBlock);
        if (startDate == 0) {
            startCrowdsale(block.timestamp);
        }

        uint256 bonusTier = getBonusTier();
        uint amount = recordPurchase(purchaser, rawAmount, purchasedAt, data, bonusTier);

        StarBasePurchasedOffChain(purchaser, amount, rawAmount, cnyBtcRate, bonusTier, data);
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
        assert(endedAt == 0);    
        endedAt = timestamp;
        CrowdsaleEnded(endedAt);
    }

     
    function invalidatePurchase(uint256 purchaseIdx)
        external
        onlyOwner
        whenEnded
        tokensNotDelivered
        returns (bool)
    {
        CrowdsalePurchase memory purchase = crowdsalePurchases[purchaseIdx];
        assert(purchase.purchaser != 0 && purchase.amount != 0);

        crowdsalePurchases[purchaseIdx].amount = 0;
        crowdsalePurchases[purchaseIdx].rawAmount = 0;
        invalidatedOrigPurchases[purchaseIdx] = purchase;
        PurchaseInvalidated(purchaseIdx);
        return true;
    }

     
    function amendPurchase(
        uint256 purchaseIdx,
        address purchaser,
        uint256 amount,
        uint256 rawAmount,
        uint256 purchasedAt,
        string data,
        uint256 bonus
    )
        external
        onlyOwner
        whenEnded
        tokensNotDelivered
        returns (bool)
    {
        CrowdsalePurchase memory purchase = crowdsalePurchases[purchaseIdx];
        assert(purchase.purchaser != 0 && purchase.amount != 0);

        amendedOrigPurchases[purchaseIdx] = purchase;
        crowdsalePurchases[purchaseIdx] =
            CrowdsalePurchase(purchaser, amount, rawAmount, purchasedAt, data, bonus);
        PurchaseAmended(purchaseIdx);
        return true;
    }

     
    function deliverPurchasedTokens()
        external
        onlyOwner
        whenEnded
        returns (bool)
    {
        assert(earlyPurchasesLoaded);
        assert(address(starbaseToken) != 0);

        uint256 totalAmountOfPurchasesInCny = totalRaisedAmountInCny();  

        for (uint256 i = numOfDeliveredCrowdsalePurchases; i < crowdsalePurchases.length && msg.gas > 200000; i++) {
            CrowdsalePurchase memory purchase = crowdsalePurchases[i];
            if (purchase.amount == 0) {
                continue;    
            }

             

            uint256 crowdsalePurchaseValue = purchase.amount;
            uint256 tokenCount = SafeMath.mul(crowdsaleTokenAmount, crowdsalePurchaseValue) / totalAmountOfPurchasesInCny;

            numOfPurchasedTokensOnCsBy[purchase.purchaser] = SafeMath.add(numOfPurchasedTokensOnCsBy[purchase.purchaser], tokenCount);
            starbaseToken.allocateToCrowdsalePurchaser(purchase.purchaser, tokenCount);
            numOfDeliveredCrowdsalePurchases = SafeMath.add(i, 1);
        }

        for (uint256 j = numOfDeliveredEarlyPurchases; j < earlyPurchasers.length && msg.gas > 200000; j++) {
            address earlyPurchaser = earlyPurchasers[j];

             

            uint256 earlyPurchaserPurchaseValue = earlyPurchasedAmountBy[earlyPurchaser];

            uint256 epTokenCalculationFromEPTokenAmount = SafeMath.mul(earlyPurchaseTokenAmount, earlyPurchaserPurchaseValue) / totalAmountOfEarlyPurchases();

            uint256 epTokenCalculationFromCrowdsaleTokenAmount = SafeMath.mul(crowdsaleTokenAmount, earlyPurchaserPurchaseValue) / totalAmountOfPurchasesInCny;

            uint256 epTokenCount = SafeMath.add(epTokenCalculationFromEPTokenAmount, epTokenCalculationFromCrowdsaleTokenAmount);

            numOfPurchasedTokensOnEpBy[earlyPurchaser] = SafeMath.add(numOfPurchasedTokensOnEpBy[earlyPurchaser], epTokenCount);
            starbaseToken.allocateToCrowdsalePurchaser(earlyPurchaser, epTokenCount);
            numOfDeliveredEarlyPurchases = SafeMath.add(j, 1);
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

                earlyPurchasedAmountBy[purchaser] += amountWithBonus;
            }
        }

        numOfLoadedEarlyPurchases += i;
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
        return SafeMath.add(totalAmountOfEarlyPurchases(), totalAmountOfCrowdsalePurchases());
    }

     
    function totalAmountOfEarlyPurchases() constant public returns(uint256) {
       return starbaseEpAmendment.totalAmountOfEarlyPurchases();
    }

     
    function purchaseAsQualifiedPartner()
        payable
        public
        rateIsSet(cnyEthRate)
        returns (bool)
    {
        require(qualifiedPartners[msg.sender].bonaFide);
        qualifiedPartners[msg.sender].amountRaised = SafeMath.add(msg.value, qualifiedPartners[msg.sender].amountRaised);

        assert(qualifiedPartners[msg.sender].amountRaised <= qualifiedPartners[msg.sender].amountCap);

        uint256 bonusTier = 30;  
        uint256 rawAmount = SafeMath.mul(msg.value, cnyEthRate) / 1e18;
        uint amount = recordPurchase(msg.sender, rawAmount, now, '', bonusTier);

        if (qualifiedPartners[msg.sender].commissionFeePercentage > 0) {
            sendQualifiedPartnerCommissionFee(msg.sender, msg.value);
        }

        StarBasePurchasedWithEth(msg.sender, amount, rawAmount, cnyEthRate, bonusTier);
        return true;
    }

     
    function purchaseWithEth()
        payable
        public
        minInvestment
        whenNotEnded
        rateIsSet(cnyEthRate)
        returns (bool)
    {
        require(purchaseStartBlock > 0 && block.number >= purchaseStartBlock);
        if (startDate == 0) {
            startCrowdsale(block.timestamp);
        }

        uint256 bonusTier = getBonusTier();

        uint256 rawAmount = SafeMath.mul(msg.value, cnyEthRate) / 1e18;
        uint amount = recordPurchase(msg.sender, rawAmount, now, '', bonusTier);

        StarBasePurchasedWithEth(msg.sender, amount, rawAmount, cnyEthRate, bonusTier);
        return true;
    }

     

     
    function startCrowdsale(uint256 timestamp) internal {
        startDate = timestamp;

         
        firstBonusSalesEnds = startDate + 7 days;              
        secondBonusSalesEnds = firstBonusSalesEnds + 14 days;  
        thirdBonusSalesEnds = secondBonusSalesEnds + 14 days;  
        fourthBonusSalesEnds = thirdBonusSalesEnds + 7 days;   
        fifthBonusSalesEnds = fourthBonusSalesEnds + 3 days;   

         
        firstExtendedBonusSalesEnds = fifthBonusSalesEnds + 3 days;          
        secondExtendedBonusSalesEnds = firstExtendedBonusSalesEnds + 3 days;  
        thirdExtendedBonusSalesEnds = secondExtendedBonusSalesEnds + 3 days;  
        fourthExtendedBonusSalesEnds = thirdExtendedBonusSalesEnds + 3 days;  
        fifthExtendedBonusSalesEnds = fourthExtendedBonusSalesEnds + 3 days;   
        sixthExtendedBonusSalesEnds = fifthExtendedBonusSalesEnds + 60 days;  
    }

     
    function recordPurchase(
        address purchaser,
        uint256 rawAmount,
        uint256 timestamp,
        string data,
        uint256 bonusTier
    )
        internal
        returns(uint256 amount)
    {
        amount = rawAmount;  

         
        if (block.number >= purchaseStartBlock) {

            assert(totalAmountOfCrowdsalePurchasesWithoutBonus() <= MAX_CROWDSALE_CAP);

            uint256 crowdsaleTotalAmountAfterPurchase = SafeMath.add(totalAmountOfCrowdsalePurchasesWithoutBonus(), amount);

             
            if (crowdsaleTotalAmountAfterPurchase > MAX_CROWDSALE_CAP) {
              uint256 difference = SafeMath.sub(crowdsaleTotalAmountAfterPurchase, MAX_CROWDSALE_CAP);
              uint256 ethValueToReturn = SafeMath.mul(difference, 1e18) / cnyEthRate;
              purchaser.transfer(ethValueToReturn);
              amount = SafeMath.sub(amount, difference);
              rawAmount = amount;
            }

        }

        uint256 covertedAmountwWithBonus = SafeMath.mul(amount, bonusTier) / 100;
        amount = SafeMath.add(amount, covertedAmountwWithBonus);  

        CrowdsalePurchase memory purchase = CrowdsalePurchase(purchaser, amount, rawAmount, timestamp, data, bonusTier);
        crowdsalePurchases.push(purchase);
        return amount;
    }

     
    function getBonusTier() internal returns (uint256) {
        bool firstBonusSalesPeriod = now >= startDate && now <= firstBonusSalesEnds;  
        bool secondBonusSalesPeriod = now > firstBonusSalesEnds && now <= secondBonusSalesEnds;  
        bool thirdBonusSalesPeriod = now > secondBonusSalesEnds && now <= thirdBonusSalesEnds;  
        bool fourthBonusSalesPeriod = now > thirdBonusSalesEnds && now <= fourthBonusSalesEnds;  
        bool fifthBonusSalesPeriod = now > fourthBonusSalesEnds && now <= fifthBonusSalesEnds;  

         
        bool firstExtendedBonusSalesPeriod = now > fifthBonusSalesEnds && now <= firstExtendedBonusSalesEnds;  
        bool secondExtendedBonusSalesPeriod = now > firstExtendedBonusSalesEnds && now <= secondExtendedBonusSalesEnds;  
        bool thirdExtendedBonusSalesPeriod = now > secondExtendedBonusSalesEnds && now <= thirdExtendedBonusSalesEnds;  
        bool fourthExtendedBonusSalesPeriod = now > thirdExtendedBonusSalesEnds && now <= fourthExtendedBonusSalesEnds;  
        bool fifthExtendedBonusSalesPeriod = now > fourthExtendedBonusSalesEnds && now <= fifthExtendedBonusSalesEnds;  
        bool sixthExtendedBonusSalesPeriod = now > fifthExtendedBonusSalesEnds && now <= sixthExtendedBonusSalesEnds;  

        if (firstBonusSalesPeriod || firstExtendedBonusSalesPeriod) return 20;
        if (secondBonusSalesPeriod || secondExtendedBonusSalesPeriod) return 15;
        if (thirdBonusSalesPeriod || thirdExtendedBonusSalesPeriod) return 10;
        if (fourthBonusSalesPeriod || fourthExtendedBonusSalesPeriod) return 5;
        if (fifthBonusSalesPeriod || fifthExtendedBonusSalesPeriod) return 0;

        if (sixthExtendedBonusSalesPeriod) {
          uint256 DAY_IN_SECONDS = 86400;
          uint256 secondsSinceStartDate = SafeMath.sub(now, startDate);
          uint256 numberOfDays = secondsSinceStartDate / DAY_IN_SECONDS;

          return SafeMath.sub(numberOfDays, 60);
        }
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