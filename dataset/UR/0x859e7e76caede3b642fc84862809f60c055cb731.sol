 

pragma solidity ^0.4.7;
 
 
contract AbstractStarbaseCrowdsale {
    function startDate() constant returns (uint256 startDate) {}
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