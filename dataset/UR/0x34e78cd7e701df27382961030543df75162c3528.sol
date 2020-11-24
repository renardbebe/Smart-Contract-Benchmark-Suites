 

pragma solidity 0.4.25;

 
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

 
contract ETH_v3 {
     
    using SafeMath
    for uint;
     
    mapping(address => uint) public userDeposit;
     
    mapping(address => uint) public userTime;
     
    mapping(address => uint) public persentWithdraw;
     
    address public projectFund = 0x18e9F86ed0430679f79EF2eA0cc5E1186b80c570;
     
    address public charityFund = 0xf36EEbB7438aDef0E7fE4650a6Cd6dB238B58c6a;
     
    uint projectPercent = 8;
     
    uint public charityPercent = 5;
     
    uint public chargingTime = 1 hours;
     
    uint public startPercent = 250;
    uint public lowPersent = 300;
    uint public middlePersent = 350;
    uint public highPersent = 375;
     
    uint public stepLow = 1000 ether;
    uint public stepMiddle = 2500 ether;
    uint public stepHigh = 5000 ether;
    uint public countOfInvestors = 0;
    uint public countOfCharity = 0;

    modifier isIssetUser() {
        require(userDeposit[msg.sender] > 0, "Deposit not found");
        _;
    }

    modifier timePayment() {
        require(now >= userTime[msg.sender].add(chargingTime), "Too fast payout request");
        _;
    }

     
    function collectPercent() isIssetUser timePayment internal {
         
        if ((userDeposit[msg.sender].mul(2)) <= persentWithdraw[msg.sender]) {
            userDeposit[msg.sender] = 0;
            userTime[msg.sender] = 0;
            persentWithdraw[msg.sender] = 0;
        } else {
            uint payout = payoutAmount();
            userTime[msg.sender] = now;
            persentWithdraw[msg.sender] += payout;
            msg.sender.transfer(payout);
        }
    }

     
    function persentRate() public view returns(uint) {
         
        uint balance = address(this).balance;
         
        if (balance < stepLow) {
            return (startPercent);
        }
        if (balance >= stepLow && balance < stepMiddle) {
            return (lowPersent);
        }
        if (balance >= stepMiddle && balance < stepHigh) {
            return (middlePersent);
        }
        if (balance >= stepHigh) {
            return (highPersent);
        }
    }

     
    function payoutAmount() public view returns(uint) {
        uint persent = persentRate();
        uint rate = userDeposit[msg.sender].mul(persent).div(100000);
        uint interestRate = now.sub(userTime[msg.sender]).div(chargingTime);
        uint withdrawalAmount = rate.mul(interestRate);
        return (withdrawalAmount);
    }

     
    function makeDeposit() private {
        if (msg.value > 0) {
            if (userDeposit[msg.sender] == 0) {
                countOfInvestors += 1;
            }
            if (userDeposit[msg.sender] > 0 && now > userTime[msg.sender].add(chargingTime)) {
                collectPercent();
            }
            userDeposit[msg.sender] = userDeposit[msg.sender].add(msg.value);
            userTime[msg.sender] = now;
             
            projectFund.transfer(msg.value.mul(projectPercent).div(100));
             
            uint charityMoney = msg.value.mul(charityPercent).div(100);
            countOfCharity+=charityMoney;
            charityFund.transfer(charityMoney);
        } else {
            collectPercent();
        }
    }
}