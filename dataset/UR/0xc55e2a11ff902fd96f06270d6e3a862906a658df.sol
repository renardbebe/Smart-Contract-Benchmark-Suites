 

pragma solidity ^0.5.7;

library MyEtherFundControl {
    using MyEtherFundControl for data;

    struct data {
        uint min;
        uint max;

        uint startAt;
        uint maxAmountPerDay;
        mapping(uint => uint) investmentsPerDay;
    }

    function addInvestment(data storage control, uint amount) internal{
        control.investmentsPerDay[getCurrentDay()] += amount;
    }

    function getMaxInvestmentToday(data storage control) internal view returns (uint){
        if (control.startAt == 0) {
            return 10000 ether;
        }

        if (control.startAt > now) {
            return 10000 ether;
        }

        return control.maxAmountPerDay - control.getTodayInvestment();
    }

    function getCurrentDay() internal view returns (uint){
        return now / 24 hours;
    }

    function getTodayInvestment(data storage control) internal view returns (uint){
        return control.investmentsPerDay[getCurrentDay()];
    }
}


contract MyEtherFund {
    using MyEtherFundControl for MyEtherFundControl.data;

    address public owner;

    uint constant public MIN_INVEST = 10000000000000000 wei;

    uint public currentInterest = 3;

    uint public depositAmount;

    uint public paidAmount;

    uint public round = 1;

    uint public lastPaymentDate;

    uint public advertisingCommission = 10;

    uint public devCommission = 5;

    uint public profitThreshold = 2;

    address payable public devAddress;

    address payable public advertiserAddress;

     
    address[] public addresses;

     
    mapping(address => Investor) public investors;

     
    bool public pause;

    struct TopInvestor {
        address payable addr;
        uint deposit;
        uint from;
    }

    struct Investor{
        uint id;
        uint deposit;
        uint deposits;
        uint paidOut;
        uint date;
        address payable referrer;
    }

    event Invest(address indexed addr, uint amount, address referrer);
    event Payout(address indexed addr, uint amount, string eventType, address from);
    event NextRoundStarted(uint indexed round, uint date, uint deposit);
    event PerseusUpdate(address addr, string eventType);

    TopInvestor public top_investor;
    MyEtherFundControl.data private myEtherFundControl;

     
    modifier onlyOwner {if (msg.sender == owner) _;}

    constructor() public {
        owner = msg.sender;
        devAddress = msg.sender;
        advertiserAddress = msg.sender;

        addresses.length = 1;

        myEtherFundControl.min = 30 ether;
        myEtherFundControl.max = 500 ether;
    }

     
    function setAdvertiserAddr(address payable addr) onlyOwner public {
        advertiserAddress = addr;
    }

     
    function transferOwnership(address payable addr) onlyOwner public {
        owner = addr;
    }

    function setMyEtherFundControlStartAt(uint startAt) onlyOwner public {
        myEtherFundControl.startAt = startAt;
    }

    function getMyEtherFundControlStartAt() public view returns (uint) {
        return myEtherFundControl.startAt;
    }

     
    function setGrowingMaxPerDay(uint maxAmountPerDay) public {
        require(maxAmountPerDay >= myEtherFundControl.min && maxAmountPerDay <= myEtherFundControl.max, "incorrect amount");
        require(msg.sender == devAddress, "Only dev team have access to this function");
        myEtherFundControl.maxAmountPerDay = maxAmountPerDay;
    }

     
     
    function() payable external {

         
        if (isContract()) {
            revert();
        }

         
        if (pause) {
            doRestart();
            msg.sender.transfer(msg.value);  

            return;
        }

        if (0 == msg.value) {
            payoutDividends();  
            return;
        }
        

        require(msg.value >= MIN_INVEST, "Too small amount, minimum 0.01 ether");
        Investor storage user = investors[msg.sender];

        if (user.id == 0) {  
            user.id = addresses.push(msg.sender);
            user.date = now;

             
            address payable referrer = bytesToAddress(msg.data);
            if (investors[referrer].deposit > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }
        } else {
            payoutDividends();  
        }

        uint investment = min(myEtherFundControl.getMaxInvestmentToday(), msg.value);
        require(investment > 0, "Too much investments today");

         
        user.deposit += investment;
        user.deposits += 1;

        emit Invest(msg.sender, investment, user.referrer);

        depositAmount += investment;
        lastPaymentDate = now;


        if (devAddress.send(investment / 100 * devCommission)) {
             
        }

        if (advertiserAddress.send(investment / 100 * advertisingCommission)) {
             
        }

         
        uint bonusAmount = investment / 100 * currentInterest;

         
        if (user.referrer != address(0)) {
            if (user.referrer.send(bonusAmount)) {  
                emit Payout(user.referrer, bonusAmount, "referral", msg.sender);
            }

            if (user.deposits == 1) {  
                if (msg.sender.send(bonusAmount)) {
                    emit Payout(msg.sender, bonusAmount, "cash-back", address(0));
                }
            }
        } else if (top_investor.addr != address(0) && top_investor.from + 24 hours > now) {
            if (top_investor.addr.send(bonusAmount)) {  
                emit Payout(top_investor.addr, bonusAmount, "perseus", msg.sender);
            }
        }

         
        considerCurrentInterest();
         
        myEtherFundControl.addInvestment(investment);
         
        considerTopInvestor(investment);

         
        if (msg.value > investment) {
            msg.sender.transfer(msg.value - investment);
        }
    }

    function getTodayInvestment() view public returns (uint){
        return myEtherFundControl.getTodayInvestment();
    }

    function getMaximumInvestmentPerDay() view public returns (uint){
        return myEtherFundControl.maxAmountPerDay;
    }

    function payoutDividends() private {
        require(investors[msg.sender].id > 0, "Investor not found");
        uint amount = getInvestorDividendsAmount(msg.sender);

        if (amount == 0) {
            return;
        }

         
        investors[msg.sender].date = now;

         
        investors[msg.sender].paidOut += amount;

         
        paidAmount += amount;

        uint balance = address(this).balance;

         
        if (balance < amount) {
            pause = true;
            amount = balance;
        }

        msg.sender.transfer(amount);
        emit Payout(msg.sender, amount, "payout", address(0));

         
        if (investors[msg.sender].paidOut >= investors[msg.sender].deposit * profitThreshold) {
            delete investors[msg.sender];
        }
    }

     
    function doRestart() private {
        uint txs;

        for (uint i = addresses.length - 1; i > 0; i--) {
            delete investors[addresses[i]];  
            addresses.length -= 1;  
            if (txs++ == 150) {  
                return;
            }
        }

        emit NextRoundStarted(round, now, depositAmount);
        pause = false;  
        round += 1;  
        depositAmount = 0;
        paidAmount = 0;
        lastPaymentDate = now;
    }

    function getInvestorCount() public view returns (uint) {
        return addresses.length - 1;
    }

    function considerCurrentInterest() internal{
        uint interest;

         
        if (depositAmount >= 4000 ether) {
            interest = 1;
        } else if (depositAmount >= 1000 ether) {  
            interest = 2;
        } else {
            interest = 3;  
        }

         
        if (interest >= currentInterest) {
            return;
        }

        currentInterest = interest;
    }

     
    function considerTopInvestor(uint amount) internal {
         
        if (top_investor.addr != address(0) && top_investor.from + 24 hours < now) {
            top_investor.addr = address(0);
            top_investor.deposit = 0;
            emit PerseusUpdate(msg.sender, "expired");
        }

         
        if (amount > top_investor.deposit) {
            top_investor = TopInvestor(msg.sender, amount, now);
            emit PerseusUpdate(msg.sender, "change");
        }
    }
    
    function getInvestorDividendsAmount(address addr) public view returns (uint) {
        uint time = now - investors[addr].date;
        return investors[addr].deposit / 100 * currentInterest * time / 1 days;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address payable addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

     
    function isContract() internal view returns (bool) {
        return msg.sender != tx.origin;
    }

     
    function min(uint a, uint b) public pure returns (uint) {
        if (a < b) return a;
        else return b;
    }
}