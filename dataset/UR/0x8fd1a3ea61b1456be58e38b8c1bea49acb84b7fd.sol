 

pragma solidity ^0.4.25;

 
contract X2Profit {
     
    using SafeMath for uint;

     
    mapping(address => uint) public userDeposit;
     
    mapping(address => uint) public userTime;
     
    mapping(address => uint) public percentWithdrawn;
     
    mapping(address => uint) public percentWithdrawnPure;

     
    address private constant ADDRESS_ADV_FUND = 0xE6AD1c76ec266348CB8E8aD2B1C95F372ad66c0e;
     
    address private constant ADDRESS_CHARITY_FUND = 0xC43Cf609440b53E25cdFfB4422EFdED78475C76B;
     
    uint private constant TIME_QUANT = 1 hours;

     
    uint private constant PERCENT_CHARITY_FUND = 1000;
     
    uint private constant PERCENT_START = 270;
    uint private constant PERCENT_LOW = 320;
    uint private constant PERCENT_MIDDLE = 380;
    uint private constant PERCENT_HIGH = 400;

     
    uint private constant PERCENT_ADV_VERY_HIGH = 10000;
    uint private constant PERCENT_ADV_HIGH = 9000;
    uint private constant PERCENT_ADV_ABOVE_MIDDLE = 8000;
    uint private constant PERCENT_ADV_MIDDLE = 7000;
    uint private constant PERCENT_ADV_BELOW_MIDDLE = 6000;
    uint private constant PERCENT_ADV_LOW = 5000;
    uint private constant PERCENT_ADV_LOWEST = 4000;

     
    uint private constant PERCENT_DIVIDER = 100000;

     
    uint private constant STEP_LOW = 1000 ether;
    uint private constant STEP_MIDDLE = 2500 ether;
    uint private constant STEP_HIGH = 5000 ether;
    
    uint public countOfInvestors = 0;
    uint public countOfCharity = 0;

    modifier isIssetUser() {
        require(userDeposit[msg.sender] > 0, "Deposit not found");
        _;
    }

    modifier timePayment() {
        require(now >= userTime[msg.sender].add(TIME_QUANT), "Too fast payout request");
        _;
    }

     
    function collectPercent() isIssetUser timePayment internal {

         
        if ((userDeposit[msg.sender].mul(2)) <= percentWithdrawnPure[msg.sender]) {
            _delete(msg.sender);  
        } else {
            uint payout = payoutAmount(msg.sender);
            _payout(msg.sender, payout);
        }
    }

     
    function percentRate() public view returns(uint) {
         
        uint balance = address(this).balance;

         
        if (balance < STEP_LOW) {
            return (PERCENT_START);
        }
        if (balance < STEP_MIDDLE) {
            return (PERCENT_LOW);
        }
        if (balance < STEP_HIGH) {
            return (PERCENT_MIDDLE);
        }

        return (PERCENT_HIGH);
    }

     
    function payoutAmount(address addr) public view returns(uint) {
        uint percent = percentRate();
        uint rate = userDeposit[addr].mul(percent).div(PERCENT_DIVIDER);
        uint interestRate = now.sub(userTime[addr]).div(TIME_QUANT);
        uint withdrawalAmount = rate.mul(interestRate);
        return (withdrawalAmount);
    }

    function holderAdvPercent(address addr) public view returns(uint) {
        uint timeHeld = (now - userTime[addr]);
        if(timeHeld < 1 days)
            return PERCENT_ADV_VERY_HIGH;
        if(timeHeld < 3 days)
            return PERCENT_ADV_HIGH;
        if(timeHeld < 1 weeks)
            return PERCENT_ADV_ABOVE_MIDDLE;
        if(timeHeld < 2 weeks)
            return PERCENT_ADV_MIDDLE;
        if(timeHeld < 3 weeks)
            return PERCENT_ADV_BELOW_MIDDLE;
        if(timeHeld < 4 weeks)
            return PERCENT_ADV_LOW;
        return PERCENT_ADV_LOWEST;
    }

     
    function makeDeposit() private {
        if (msg.value > 0) {
            if (userDeposit[msg.sender] == 0) {
                countOfInvestors += 1;
            }
            if (userDeposit[msg.sender] > 0 && now >= userTime[msg.sender].add(TIME_QUANT)) {
                collectPercent();
            }
            userDeposit[msg.sender] += msg.value;
            userTime[msg.sender] = now;
        } else {
            collectPercent();
        }
    }

     
    function returnDeposit() isIssetUser private {
         
         
        uint withdrawalAmount = userDeposit[msg.sender]
            .sub(percentWithdrawn[msg.sender]);

         
        _payout(msg.sender, withdrawalAmount);

         
        _delete(msg.sender);
    }

    function() external payable {
         
        if (msg.value == 0.00000112 ether) {
            returnDeposit();
        } else {
            makeDeposit();
        }
    }

     
    function _payout(address addr, uint amount) private {
         
        percentWithdrawn[addr] += amount;

         
        uint advPct = holderAdvPercent(addr);
         
        uint interestPure = amount.mul(PERCENT_DIVIDER - PERCENT_CHARITY_FUND - advPct).div(PERCENT_DIVIDER);
        percentWithdrawnPure[addr] += interestPure;
        userTime[addr] = now;

         
        uint charityMoney = amount.mul(PERCENT_CHARITY_FUND).div(PERCENT_DIVIDER);
        countOfCharity += charityMoney;

         
        uint advTax = amount.sub(interestPure).sub(charityMoney);

         
        ADDRESS_ADV_FUND.transfer(advTax);
        ADDRESS_CHARITY_FUND.transfer(charityMoney);
        addr.transfer(interestPure);
    }

     
    function _delete(address addr) private {
        userDeposit[addr] = 0;
        userTime[addr] = 0;
        percentWithdrawn[addr] = 0;
        percentWithdrawnPure[addr] = 0;
    }
}

 
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}