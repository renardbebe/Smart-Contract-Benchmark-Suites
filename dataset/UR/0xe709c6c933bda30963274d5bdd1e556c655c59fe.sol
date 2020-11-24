 

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

 
contract token {
    mapping (address => uint256) public totalInvestmentOf;
    function transfer(address receiver, uint amount){  }
    function updateInvestmentTotal(address _to, uint256 _value){ }
    function burnUnsoldCoins(address _removeCoinsFrom){ }
}

contract Crowdsale is owned {
    uint public amountRaised;
     
    uint public deadline;
     
    uint public price = 1 ether;
     
    token public tokenReward;
    Funder[] public funders;
    event FundTransfer(address backer, uint amount, bool isContribution);
     
    bool crowdsaleClosed = false;
     
    uint weekTwoPriceRiseBegin = now + 10080 * 1 minutes;
     
    uint remainderRefund;
    uint amountAfterRefund;
     
    uint bankrollBeneficiaryAmount;
    uint etherollBeneficiaryAmount;
     
    address public beneficiary;
     
    address etherollBeneficiary = 0x5de92686587b10cd47e03b71f2e2350606fcaf14;

     
    struct Funder {
        address addr;
        uint amount;
    }

     
    function Crowdsale(
        address ifSuccessfulSendTo,
        uint durationInMinutes,
         
        token addressOfTokenUsedAsReward
    ) {
        beneficiary = ifSuccessfulSendTo;
        deadline = now + durationInMinutes * 1 minutes;
         
        tokenReward = token(addressOfTokenUsedAsReward);
    }



    function () {
         
        if(now > deadline) crowdsaleClosed = true;
        if (crowdsaleClosed) throw;
        uint amount = msg.value;

         
        if(amount < price) throw;

         
        if(now < weekTwoPriceRiseBegin){
             
            remainderRefund = amount % price;
            if(remainderRefund > 0){
                 
                msg.sender.send(remainderRefund);
                amountAfterRefund = amount-remainderRefund;
                tokenReward.transfer(msg.sender, amountAfterRefund / price);
                amountRaised += amountAfterRefund;
                funders[funders.length++] = Funder({addr: msg.sender, amount: amountAfterRefund});
                tokenReward.updateInvestmentTotal(msg.sender, amountAfterRefund);
                FundTransfer(msg.sender, amountAfterRefund, true);
            }

             
            if(remainderRefund == 0){
                 amountRaised += amount;
                 tokenReward.transfer(msg.sender, amount / price);
                 funders[funders.length++] = Funder({addr: msg.sender, amount: amount});
                 tokenReward.updateInvestmentTotal(msg.sender, amount);
                 FundTransfer(msg.sender, amount, true);
            }
        }

         
        if(now >= weekTwoPriceRiseBegin){
             
             
            if(price == 1 ether){price = (price*150)/100;}
             
             
            remainderRefund = amount % price;
            if(remainderRefund > 0){
                 
                msg.sender.send(remainderRefund);
                amountAfterRefund = amount-remainderRefund;
                tokenReward.transfer(msg.sender, amountAfterRefund / price);
                amountRaised += amountAfterRefund;
                funders[funders.length++] = Funder({addr: msg.sender, amount: amountAfterRefund});
                tokenReward.updateInvestmentTotal(msg.sender, amountAfterRefund);
                FundTransfer(msg.sender, amountAfterRefund, true);
            }

             
            if(remainderRefund == 0){
                 tokenReward.transfer(msg.sender, amount / price);
                 amountRaised += amount;
                 funders[funders.length++] = Funder({addr: msg.sender, amount: amount});
                 tokenReward.updateInvestmentTotal(msg.sender, amount);
                 FundTransfer(msg.sender, amount, true);
            }
        }
    }

     
    modifier afterDeadline() { if (now >= deadline) _ }

     
    modifier afterPriceRise() { if (now >= weekTwoPriceRiseBegin) _ }

     
    function checkGoalReached() afterDeadline {
         
        bankrollBeneficiaryAmount = (amountRaised*80)/100;
        beneficiary.send(bankrollBeneficiaryAmount);
        FundTransfer(beneficiary, bankrollBeneficiaryAmount, false);
         
        etherollBeneficiaryAmount = (amountRaised*20)/100;
        etherollBeneficiary.send(etherollBeneficiaryAmount);
        FundTransfer(etherollBeneficiary, etherollBeneficiaryAmount, false);
        etherollBeneficiary.send(this.balance);  
         
         
        crowdsaleClosed = true;
    }

     
     
     
    function updateTokenPriceWeekTwo() afterPriceRise {
         
        if(price == 1 ether){price = (price*150)/100;}
    }

    function burnCoins(address _removeCoinsFrom)
        onlyOwner
    {
        tokenReward.burnUnsoldCoins(_removeCoinsFrom);
    }

     
     
     
    function returnFunds()
        onlyOwner
    {
        for (uint i = 0; i < funders.length; ++i) {
          funders[i].addr.send(funders[i].amount);
          FundTransfer(funders[i].addr, funders[i].amount, false);
        }
    }

}