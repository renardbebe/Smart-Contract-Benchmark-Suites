 

pragma solidity ^0.4.25;

 

 

 

contract TriipInvestorsServices {

    event ConfirmPurchase(address _sender, uint _startTime, uint _amount);

    event Payoff(address _seller, uint _amount, uint _kpi);
    
    event Refund(address _buyer, uint _amount);

    event Claim(address _sender, uint _counting, uint _buyerWalletBalance);

    enum PaidStage {
        NONE,
        FIRST_PAYMENT,
        SECOND_PAYMENT,
        FINAL_PAYMENT
    }

    uint public KPI_0k = 0;
    uint public KPI_25k = 25;
    uint public KPI_50k = 50;
    uint public KPI_100k = 100;    
    
    address public seller;  
    address public buyer;   
    address public buyerWallet;  
    
    uint public startTime = 0;
    uint public endTime = 0;
    bool public isEnd = false;    

    uint decimals = 18;
    uint unit = 10 ** decimals;
    
    uint public paymentAmount = 69 * unit;                 
    uint public targetSellingAmount = 10 * paymentAmount;  
    
    uint claimCounting = 0;

    PaidStage public paidStage = PaidStage.NONE;

    uint public balance;

     

     
     
     
     

     
     
     
     

     
     
     
     

     
     
     

     

    constructor(address _buyer, address _seller, address _buyerWallet) public {

        seller = _seller;
        buyer = _buyer;
        buyerWallet = _buyerWallet;

    }

    modifier whenNotEnd() {
        require(!isEnd, "This contract should not be endTime") ;
        _;
    }

    function confirmPurchase() public payable {  

        require(startTime == 0);

        require(msg.value == paymentAmount, "Not equal installment fee");

        startTime = now;

        endTime = startTime + ( 45 * 1 days );

        balance += msg.value;

        emit ConfirmPurchase(msg.sender, startTime, balance);
    }

    function contractEthBalance() public view returns (uint) {

        return balance;
    }

    function buyerWalletBalance() public view returns (uint) {
        
        return address(buyerWallet).balance;
    }

    function claimFirstInstallment() public whenNotEnd returns (bool) {

        require(paidStage == PaidStage.NONE, "First installment has already been claimed");

        require(now >= startTime + 1 days, "Require first installment fee to be claimed after startTime + 1 day");

        uint payoffAmount = balance * 40 / 100;  

         
        balance = balance - payoffAmount;  

        seller.transfer(payoffAmount);  

        emit Payoff(seller, payoffAmount, KPI_0k );
        emit Claim(msg.sender, claimCounting, buyerWalletBalance());

        return true;
    }
    
    function claim() public whenNotEnd returns (uint) {

        claimCounting = claimCounting + 1;

        uint payoffAmount = 0;

        uint sellingAmount  = targetSellingAmount;
        uint buyerBalance = buyerWalletBalance();

        emit Claim(msg.sender, claimCounting, buyerWalletBalance());
        
        if ( buyerBalance >= sellingAmount ) {

            payoffAmount = balance;

            seller.transfer(payoffAmount);
            paidStage = PaidStage.FINAL_PAYMENT;

            balance = 0;
            endContract();

            emit Payoff(seller, payoffAmount, KPI_100k);

        }
        else {
            payoffAmount = claimByKPI();

        }

        return payoffAmount;
    }

    function claimByKPI() private returns (uint) {

        uint payoffAmount = 0;
        uint sellingAmount = targetSellingAmount;
        uint buyerBalance = buyerWalletBalance();

        if ( buyerBalance >= ( sellingAmount * KPI_50k / 100) 
            && now >= (startTime + ( 30 * 1 days) )
            ) {

            uint paidPercent = 66;

            if ( paidStage == PaidStage.NONE) {
                paidPercent = 66;  
            }else if( paidStage == PaidStage.FIRST_PAYMENT) {
                 
                 
                paidPercent = 50;
            }

            payoffAmount = balance * paidPercent / 100;

             
            balance = balance - payoffAmount;

            seller.transfer(payoffAmount);

            emit Payoff(seller, payoffAmount, KPI_50k);

            paidStage = PaidStage.SECOND_PAYMENT;
        }

        if( buyerBalance >= ( sellingAmount * KPI_25k / 100) 
            && now >= (startTime + (15 * 1 days) )
            && paidStage == PaidStage.NONE ) {

            payoffAmount = balance * 33 / 100;

             
            balance = balance - payoffAmount;

            seller.transfer(payoffAmount);

            emit Payoff(seller, payoffAmount, KPI_25k );

            paidStage = PaidStage.FIRST_PAYMENT;

        }

        if(now >= (startTime + (45 * 1 days) )) {

            endContract();
        }

        return payoffAmount;
    }

    function endContract() private {
        isEnd = true;
    }
    
    function refund() public returns (uint) {

        require(now >= endTime);

         
        uint refundAmount = address(this).balance;

        buyer.transfer(refundAmount);

        emit Refund(buyer, refundAmount);

        return refundAmount;
    }
}