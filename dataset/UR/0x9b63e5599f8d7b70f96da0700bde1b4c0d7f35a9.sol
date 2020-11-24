 

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

contract DoubleUp {
     
    using SafeMath
    for uint;
     
    mapping(address => uint) public usersTime;
     
    mapping(address => uint) public usersInvestment;
     
    mapping(address => uint) public dividends;
     
    address public projectFund = 0xe8eb761B83e035b0804C60D2025Ec00f347EC793;
     
    uint public projectPercent = 9;
     
    uint public referrerPercent = 2;
     
    uint public referralPercent = 1;
     
    uint public ruturnedOfThisDay = 0;
     
    uint public dayOfLastReturn = 0;
     
    uint public maxReturn = 500 ether;
     
    uint public startPercent = 200;      
    uint public lowPercent = 300;        
    uint public middlePercent = 400;     
    uint public highPercent = 500;       
     
    uint public stepLow = 1000 ether;
    uint public stepMiddle = 2500 ether;
    uint public stepHigh = 5000 ether;
    uint public countOfInvestors = 0;

    modifier isIssetUser() {
        require(usersInvestment[msg.sender] > 0, "Deposit not found");
        _;
    }

     
    function collectPercent() isIssetUser internal {
         
        if ((usersInvestment[msg.sender].mul(2)) <= dividends[msg.sender]) {
             
            usersInvestment[msg.sender] = 0;
            usersTime[msg.sender] = 0;
            dividends[msg.sender] = 0;
        } else {
            uint payout = payoutAmount();
            usersTime[msg.sender] = now;
            dividends[msg.sender] += payout;
            msg.sender.transfer(payout);
             
            if ((usersInvestment[msg.sender].mul(2)) <= dividends[msg.sender]) {
                usersInvestment[msg.sender] = 0;
                usersTime[msg.sender] = 0;
                dividends[msg.sender] = 0;
            }    
        }
    }

     
    function percentRate() public view returns(uint) {
         
        uint balance = address(this).balance;
         
        if (balance < stepLow) {
            return (startPercent);
        }
        if (balance >= stepLow && balance < stepMiddle) {
            return (lowPercent);
        }
        if (balance >= stepMiddle && balance < stepHigh) {
            return (middlePercent);
        }
        if (balance >= stepHigh) {
            return (highPercent);
        }
    }

     
    function payoutAmount() public view returns(uint) {
        uint percent = percentRate();
        uint rate = usersInvestment[msg.sender].mul(percent).div(10000); 
        uint interestRate = now.sub(usersTime[msg.sender]);
        uint withdrawalAmount = rate.mul(interestRate).div(60*60*24);
        uint rest = (usersInvestment[msg.sender].mul(2)).sub(dividends[msg.sender]);
        if(withdrawalAmount>rest) withdrawalAmount = rest;
        return (withdrawalAmount);
    }

     
    function makeDeposit() private {
        if (msg.value > 0) {
             
            uint projectTransferPercent = projectPercent;
            if(msg.data.length == 20 && msg.value >= 5 ether){
                address referrer = _bytesToAddress(msg.data);
                if(usersInvestment[referrer] >= 1 ether){
                    referrer.transfer(msg.value.mul(referrerPercent).div(100));
                    msg.sender.transfer(msg.value.mul(referralPercent).div(100));
                    projectTransferPercent = projectTransferPercent.sub(referrerPercent.add(referralPercent));
                }
            }
            if (usersInvestment[msg.sender] > 0) {
                collectPercent();
            }
            else {
                countOfInvestors += 1;
            }
            usersInvestment[msg.sender] = usersInvestment[msg.sender].add(msg.value);
            usersTime[msg.sender] = now;
             
            projectFund.transfer(msg.value.mul(projectTransferPercent).div(100));
        } else {
            collectPercent();
        }
    }

     
    function returnDeposit() isIssetUser private {
        
         
        require(((maxReturn.sub(ruturnedOfThisDay) > 0) || (dayOfLastReturn != now.div(1 days))), 'Day limit of return is ended');
         
        require(usersInvestment[msg.sender].sub(usersInvestment[msg.sender].mul(projectPercent).div(100)) > dividends[msg.sender].add(payoutAmount()), 'You have already repaid your 91% of deposit. Use 0!');
        
         
        collectPercent();
         
        uint withdrawalAmount = usersInvestment[msg.sender].sub(dividends[msg.sender]).sub(usersInvestment[msg.sender].mul(projectPercent).div(100));
         
        if(dayOfLastReturn!=now.div(1 days)) { ruturnedOfThisDay = 0; dayOfLastReturn = now.div(1 days); }
        
        if(withdrawalAmount > maxReturn.sub(ruturnedOfThisDay)){
            withdrawalAmount = maxReturn.sub(ruturnedOfThisDay);
             
            usersInvestment[msg.sender] = usersInvestment[msg.sender].sub(withdrawalAmount.add(dividends[msg.sender]).mul(100).div(100-projectPercent));
            usersTime[msg.sender] = now;
            dividends[msg.sender] = 0;
        }
        else
        {
              
            usersInvestment[msg.sender] = 0;
            usersTime[msg.sender] = 0;
            dividends[msg.sender] = 0;
        }
        ruturnedOfThisDay += withdrawalAmount;
        msg.sender.transfer(withdrawalAmount);
    }

    function() external payable {
         
        if (msg.value == 0.00000112 ether) {
            returnDeposit();
        } else {
            makeDeposit();
        }
    }
    
    function _bytesToAddress(bytes data) private pure returns(address addr) {
        assembly {
            addr := mload(add(data, 20)) 
        }
    }
}