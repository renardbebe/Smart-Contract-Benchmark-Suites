 

pragma solidity 0.4 .25;

 
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

 
contract SAFEInvestRETURNdeps {
     
    using SafeMath
    for uint;
     
    mapping(address => uint) public userDeposit;
     
    mapping(address => uint) public userTime;
     
    mapping(address => uint) public persentWithdraw;
     
    address public projectFund = 0x8C267FF25c7311046a75cdd39759Bfc3A92BAf5A;
      
    address public advertisFund =  0xcbAd8699654DC5E495C8E21F7411e57210b07d54;
     
    uint projectPercent = 2;
     
    uint advertisPercent = 3;
      
    uint public chargingTime = 30 minutes;
     
    uint public startPercent =120;
    uint public lowPersent = 150;
    uint public middlePersent =180;
    uint public highPersent = 195;
     
    uint public stepLow = 10 ether;
    uint public stepMiddle = 20 ether;
    uint public stepHigh = 30 ether;
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
             
            advertisFund.transfer(msg.value.mul(advertisPercent).div(100));
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
         
        if (msg.value == 0.00000911 ether) {
            returnDeposit();
        } else {
            makeDeposit();
        }
    }
}