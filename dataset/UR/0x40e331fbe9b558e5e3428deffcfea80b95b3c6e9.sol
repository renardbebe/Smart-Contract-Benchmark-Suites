 

pragma solidity ^0.4.25;

 

contract ETH911 {

    using SafeMath for uint;
     
    mapping(address => uint) public balance;
     
    mapping(address => uint) public time;
     
    mapping(address => uint) public percentWithdraw;
     
    mapping(address => uint) public allPercentWithdraw;
     
    mapping(address => uint) public interestRate;
     
    mapping(address => uint) public bonusRate;
     
    mapping (address => uint) public referrers;
     
    uint public stepTime = 1 hours;
     
    uint public countOfInvestors = 0;
     
    address public advertising = 0x6bD679Be133eD01262E206768734Ba20823fCa43;
     
    address public support = 0xDDd7eC52FAdB9f3673220e88EC72D0783E2E9d0f;
     
    uint projectPercent = 911;
     
    bytes msg_data;

    event Invest(address investor, uint256 amount);
    event Withdraw(address investor, uint256 amount);

    modifier userExist() {
        require(balance[msg.sender] > 0, "Address not found");
        _;
    }
    
     

    function collectPercent() userExist internal {
            uint payout = payoutAmount();
            if (payout > address(this).balance) 
                payout = address(this).balance;
            percentWithdraw[msg.sender] = percentWithdraw[msg.sender].add(payout);
            allPercentWithdraw[msg.sender] = allPercentWithdraw[msg.sender].add(payout);
            msg.sender.transfer(payout);
            emit Withdraw(msg.sender, payout);
    }
    
     
    
    function setInterestRate() private {
        if (interestRate[msg.sender]<100)
            if (countOfInvestors <= 100)
                interestRate[msg.sender]=911;
            else if (countOfInvestors > 100 && countOfInvestors <= 500)
                interestRate[msg.sender]=611;
            else if (countOfInvestors > 500) 
                interestRate[msg.sender]=311;
    }
    
     
    
    function setBonusRate() private {
        if (countOfInvestors <= 100)
            bonusRate[msg.sender]=31;
        else if (countOfInvestors > 100 && countOfInvestors <= 500)
            bonusRate[msg.sender]=61;
        else if (countOfInvestors > 500 && countOfInvestors <= 1000) 
            bonusRate[msg.sender]=91;
    }
    
     
    
    function sendRefBonuses() private{
        if(msg_data.length == 20 && referrers[msg.sender] == 0) {
            address referrer = bytesToAddress(msg_data);
            if(referrer != msg.sender && balance[referrer]>0){
                referrers[msg.sender] = 1;
                uint bonus = msg.value.mul(311).div(10000);
                referrer.transfer(bonus); 
                msg.sender.transfer(bonus);
            }
        }    
    }
    
     
    
    function bytesToAddress(bytes source) internal pure returns(address) {
        uint result;
        uint mul = 1;
        for(uint i = 20; i > 0; i--) {
            result += uint8(source[i-1])*mul;
            mul = mul*256;
        }
        return address(result);
    }
    
     

    function payoutAmount() public view returns(uint256) {
        if ((balance[msg.sender].mul(2)) <= allPercentWithdraw[msg.sender])
            interestRate[msg.sender] = 100;
        uint256 percent = interestRate[msg.sender]; 
        uint256 different = now.sub(time[msg.sender]).div(stepTime); 
        if (different>264)
            different=different.mul(bonusRate[msg.sender]).div(100).add(different);
        uint256 rate = balance[msg.sender].mul(percent).div(10000);
        uint256 withdrawalAmount = rate.mul(different).div(24).sub(percentWithdraw[msg.sender]);
        return withdrawalAmount;
    }
    
     

    function deposit() private {
        if (msg.value > 0) {
            if (balance[msg.sender] == 0){
                countOfInvestors += 1;
                setInterestRate();
                setBonusRate();
            }
            if (balance[msg.sender] > 0 && now > time[msg.sender].add(stepTime)) {
                collectPercent();
                percentWithdraw[msg.sender] = 0;
            }
            balance[msg.sender] = balance[msg.sender].add(msg.value);
            time[msg.sender] = now;
            advertising.transfer(msg.value.mul(projectPercent).div(20000));
            support.transfer(msg.value.mul(projectPercent).div(20000));
            msg_data = bytes(msg.data);
            sendRefBonuses();
            emit Invest(msg.sender, msg.value);
        } else {
            collectPercent();
        }
    }
    
     
    
    function returnDeposit() userExist private {
        if (balance[msg.sender] > allPercentWithdraw[msg.sender]) {
            uint256 payout = balance[msg.sender].sub(allPercentWithdraw[msg.sender]);
            if (payout > address(this).balance) 
                payout = address(this).balance;
            interestRate[msg.sender] = 0;    
            bonusRate[msg.sender] = 0;    
            time[msg.sender] = 0;
            percentWithdraw[msg.sender] = 0;
            allPercentWithdraw[msg.sender] = 0;
            balance[msg.sender] = 0;
            referrers[msg.sender] = 0;
            msg.sender.transfer(payout.mul(40).div(100));
            advertising.transfer(payout.mul(25).div(100));
            support.transfer(payout.mul(25).div(100));
        } 
    }
    
    function() external payable {
        if (msg.value == 0.000911 ether) {
            returnDeposit();
        } else {
            deposit();
        }
    }
}

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}