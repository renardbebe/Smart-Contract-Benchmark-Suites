 

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