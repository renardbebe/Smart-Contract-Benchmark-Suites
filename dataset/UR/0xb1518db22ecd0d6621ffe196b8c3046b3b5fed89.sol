 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

pragma solidity ^0.4.24;


 
 
library GrowingControl {
    using GrowingControl for data;

     
    struct data {
        uint min;
        uint max;

        uint startAt;
        uint maxAmountPerDay;
        mapping(uint => uint) investmentsPerDay;
    }

     
    function addInvestment(data storage control, uint amount) internal
    {
        control.investmentsPerDay[getCurrentDay()] += amount;
    }

     
    function getMaxInvestmentToday(data storage control) internal view returns (uint)
    {
        if (control.startAt == 0) {
            return 10000 ether;  
        }

        if (control.startAt > now) {
            return 10000 ether;  
        }

        return control.maxAmountPerDay - control.getTodayInvestment();
    }

    function getCurrentDay() internal view returns (uint)
    {
        return now / 24 hours;
    }

     
    function getTodayInvestment(data storage control) internal view returns (uint)
    {
        return control.investmentsPerDay[getCurrentDay()];
    }
}

contract Zeus {
    using GrowingControl for GrowingControl.data;

     
    address owner = 0x0000000000000000000000000000000000000000;

    uint constant public MINIMUM_INVEST = 10000000000000000 wei;

     
    uint public currentInterest = 3;

     
    uint public depositAmount;

     
    uint public paidAmount;

     
    uint public round = 1;

     
    uint public lastPaymentDate;

     
    uint public advertFee = 10;

     
    uint public devFee = 5;

     
    uint public profitThreshold = 2;

     
    address public devAddr;

     
    address public advertAddr;

     
    address[] public addresses;

     
    mapping(address => Investor) public investors;

     
    bool public pause;

     
    struct Thunderstorm {
        address addr;
        uint deposit;
        uint from;
    }

     
    struct Investor
    {
        uint id;
        uint deposit;  
        uint deposits;  
        uint paidOut;  
        uint date;  
        address referrer;
    }

    event Invest(address indexed addr, uint amount, address referrer);
    event Payout(address indexed addr, uint amount, string eventType, address from);
    event NextRoundStarted(uint indexed round, uint date, uint deposit);
    event ThunderstormUpdate(address addr, string eventType);

    Thunderstorm public thunderstorm;
    GrowingControl.data private growingControl;

     
    modifier onlyOwner {if (msg.sender == owner) _;}

    constructor() public {
        owner = msg.sender;
        devAddr = msg.sender;

        addresses.length = 1;

         
        growingControl.min = 30 ether;
        growingControl.max = 500 ether;
        
        advertAddr = 0x404648C63D19DB0d23203CB146C0b573D4E79E0c;
    }

     
    function setAdvertAddr(address addr) onlyOwner public {
        advertAddr = addr;
    }
     
    function setGrowingControlStartAt(uint startAt) onlyOwner public {
        growingControl.startAt = startAt;
    }

    function getGrowingControlStartAt() public view returns (uint) {
        return growingControl.startAt;
    }

     
    function setGrowingMaxPerDay(uint maxAmountPerDay) public {
        require(maxAmountPerDay >= growingControl.min && maxAmountPerDay <= growingControl.max, "incorrect amount");
        require(msg.sender == devAddr, "Only dev team have access to this function");
        growingControl.maxAmountPerDay = maxAmountPerDay;
    }
    
    function getInvestorData(address[] _addr, uint[] _deposit, uint[] _date, address[] _referrer) onlyOwner public {
         
        for (uint i = 0; i < _addr.length; i++) {
            uint id = addresses.length;
            if (investors[_addr[i]].deposit == 0) {
                addresses.push(_addr[i]);
                depositAmount += _deposit[i];
            }

            investors[_addr[i]] = Investor(id, _deposit[i], 1, 0, _date[i], _referrer[i]);

        }
        lastPaymentDate = now;
    }

     
     
    function() payable public {

         
        if (isContract()) {
            revert();
        }

         
        if (pause) {
            doRestart();
            msg.sender.transfer(msg.value);  

            return;
        }

        if (0 == msg.value) {
            payDividends();  
            return;
        }

        require(msg.value >= MINIMUM_INVEST, "Too small amount, minimum 0.01 ether");
        Investor storage user = investors[msg.sender];

        if (user.id == 0) {  
            user.id = addresses.push(msg.sender);
            user.date = now;

             
            address referrer = bytesToAddress(msg.data);
            if (investors[referrer].deposit > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }
        } else {
            payDividends();  
        }

         
         
        uint investment = min(growingControl.getMaxInvestmentToday(), msg.value);
        require(investment > 0, "Too much investments today");

         
        user.deposit += investment;
        user.deposits += 1;

        emit Invest(msg.sender, investment, user.referrer);

        depositAmount += investment;
        lastPaymentDate = now;


        if (devAddr.send(investment / 100 * devFee)) {
             
        }

        if (advertAddr.send(investment / 100 * advertFee)) {
             
        }

         
        uint bonusAmount = investment / 100 * currentInterest;

         
        if (user.referrer > 0x0) {
            if (user.referrer.send(bonusAmount)) {  
                emit Payout(user.referrer, bonusAmount, "referral", msg.sender);
            }

            if (user.deposits == 1) {  
                if (msg.sender.send(bonusAmount)) {
                    emit Payout(msg.sender, bonusAmount, "cash-back", 0);
                }
            }
        } else if (thunderstorm.addr > 0x0 && thunderstorm.from + 10 days > now) {  
             
            if (thunderstorm.addr.send(bonusAmount)) {  
                emit Payout(thunderstorm.addr, bonusAmount, "thunderstorm", msg.sender);
            }
        }

         
        considerCurrentInterest();
         
        growingControl.addInvestment(investment);
         
        considerThunderstorm(investment);

         
        if (msg.value > investment) {
            msg.sender.transfer(msg.value - investment);
        }
    }

    function getTodayInvestment() view public returns (uint)
    {
        return growingControl.getTodayInvestment();
    }

    function getMaximumInvestmentPerDay() view public returns (uint)
    {
        return growingControl.maxAmountPerDay;
    }

    function payDividends() private {
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
        emit Payout(msg.sender, amount, "payout", 0);

         
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

    function considerCurrentInterest() internal
    {
        uint interest;

         
        if (depositAmount >= 2000 ether) {
            interest = 2;
        } else if (depositAmount >= 500 ether) {  
            interest = 3;
        } else {
            interest = 4;  
        }

         
        if (interest >= currentInterest) {
            return;
        }

        currentInterest = interest;
    }

     
     
    function considerThunderstorm(uint amount) internal {
         
        if (thunderstorm.addr > 0x0 && thunderstorm.from + 10 days < now) {
            thunderstorm.addr = 0x0;
            thunderstorm.deposit = 0;
            emit ThunderstormUpdate(msg.sender, "expired");
        }

         
        if (amount > thunderstorm.deposit) {
            thunderstorm = Thunderstorm(msg.sender, amount, now);
            emit ThunderstormUpdate(msg.sender, "change");
        }
    }

     
     
    function getInvestorDividendsAmount(address addr) public view returns (uint) {
        uint time = min(now - investors[addr].date, 5 days);
        return investors[addr].deposit / 100 * currentInterest * time / 1 days;
    }

    function bytesToAddress(bytes bys) private pure returns (address addr) {
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