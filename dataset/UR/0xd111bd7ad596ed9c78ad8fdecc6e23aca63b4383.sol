 

pragma solidity ^0.4.7;

contract AbstractZENOSCrowdsale {
    function crowdsaleStartingBlock() constant returns (uint256 startingBlock) {}
}

 
 
 

contract ZENOSEarlyPurchase {
     
    string public constant PURCHASE_AMOUNT_UNIT = 'ETH';     
    address public owner;
    EarlyPurchase[] public earlyPurchases;
    uint public earlyPurchaseClosedAt;

     
    struct EarlyPurchase {
        address purchaser;
        uint amount;         
        uint purchasedAt;    
    }

     
    AbstractZENOSCrowdsale public zenOSCrowdsale;


     
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }

    modifier onlyBeforeCrowdsale() {
        if (address(zenOSCrowdsale) != 0 &&
            zenOSCrowdsale.crowdsaleStartingBlock() > 0)
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

     
    function ZENOSEarlyPurchase() {
        owner = msg.sender;
    }

     
     
     
    function purchasedAmountBy(address purchaser)
        external
        constant
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
        returns (uint totalAmount)
    {
        for (uint i; i < earlyPurchases.length; i++) {
            totalAmount += earlyPurchases[i].amount;
        }
    }

     
    function numberOfEarlyPurchases()
        external
        constant
        returns (uint)
    {
        return earlyPurchases.length;
    }

     
     
     
     
    function appendEarlyPurchase(address purchaser, uint amount, uint purchasedAt)
        internal
        onlyBeforeCrowdsale
        onlyEarlyPurchaseTerm
        returns (bool)
    {

        if (purchasedAt == 0 || purchasedAt > now) {
            throw;
        }

        earlyPurchases.push(EarlyPurchase(purchaser, amount, purchasedAt));
        return true;
    }

     
    function closeEarlyPurchase()
        external
        onlyOwner
        returns (bool)
    {
        earlyPurchaseClosedAt = now;
    }

     
     
    function setup(address zenOSCrowdsaleAddress)
        external
        onlyOwner
        returns (bool)
    {
        if (address(zenOSCrowdsale) == 0) {
            zenOSCrowdsale = AbstractZENOSCrowdsale(zenOSCrowdsaleAddress);
            return true;
        }
        return false;
    }

    function withdraw(uint withdrawalAmount) onlyOwner {
          if(!owner.send(withdrawalAmount)) throw;   
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }

     
    function () payable {
        appendEarlyPurchase(msg.sender, msg.value, block.timestamp);
    }
}