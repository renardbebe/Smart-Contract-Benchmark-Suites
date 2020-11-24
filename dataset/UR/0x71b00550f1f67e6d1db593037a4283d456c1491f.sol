 

pragma solidity 0.4 .24;

 
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

 
contract Inv5 {
     
    using SafeMath
    for uint;
     
    mapping(address => uint) public userDeposit;
     
    mapping(address => uint) public userTime;
     
    mapping(address => uint) public persentWithdraw;
     
    address public projectFund = 0x3ad30df178F80cF8CfcA18Fa20e12D1FF088C6FD;
     
    address public charityFund = 0xB97FFbF3D6c822D943c545587C0a8a18B6568f26;
     
    uint projectPercent = 8;
     
    uint public charityPercent = 1;
     
    uint public chargingTime = 1 hours;
     
    uint public startPercent = 555;
    uint public lowPersent = 850;
    uint public middlePersent = 1000;
    uint public highPersent = 1555;
     
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

     
    function returnDeposit() isIssetUser private {
         
        uint withdrawalAmount = userDeposit[msg.sender].sub(persentWithdraw[msg.sender]).sub(userDeposit[msg.sender].mul(projectPercent).div(100));
         
        require(userDeposit[msg.sender] > withdrawalAmount, 'You have already repaid your deposit');
         
        userDeposit[msg.sender] = 0;
        userTime[msg.sender] = 0;
        persentWithdraw[msg.sender] = 0;
        msg.sender.transfer(withdrawalAmount);
    }

    function() external payable {
         
        if (msg.value == 0.00000112 ether) {
            returnDeposit();
        } else {
            makeDeposit();
        }
    }
}