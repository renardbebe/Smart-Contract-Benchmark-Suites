 

pragma solidity 0.4.25;

 
contract OneHundredFiftyFive {

    using SafeMath for uint256;

    struct Investor {
        uint256 deposit;
        uint256 paymentTime;
        uint256 withdrawals;
        bool hold;
    }

    mapping (address => Investor) public investors;

    uint256 public countOfInvestors;
    uint256 public startTime;

    address public ownerAddress = 0xC24ddFFaaCEB94f48D2771FE47B85b49818204Be;

     
    constructor() public {
        startTime = now;
    }

     
    function getUserProfit(address _address) view public returns (uint256) {
        Investor storage investor = investors[_address];

        uint256 passedMinutes = now.sub(investor.paymentTime).div(1 minutes);

        if (investor.hold) {
            uint firstDay = 0;

            if (passedMinutes >= 1440) {
                firstDay = 1440;
            }

             
             
            return investor.deposit.mul(400 + 4 * (passedMinutes.sub(firstDay)).div(1440)).mul(passedMinutes).div(14400000);
        } else {
             
             
            uint256 differentPercent = investor.deposit.mul(4).div(100);
            return differentPercent.mul(passedMinutes).div(1440);
        }
    }

     
    function getCurrentTime() view public returns (uint256) {
        return now;
    }

     
    function withdraw(address _address) private {
        Investor storage investor = investors[_address];
        uint256 balance = getUserProfit(_address);

        if (investor.deposit > 0 && balance > 0) {
            if (address(this).balance < balance) {
                balance = address(this).balance;
            }

            investor.withdrawals = investor.withdrawals.add(balance);
            investor.paymentTime = now;

            if (investor.withdrawals >= investor.deposit.mul(155).div(100)) {
                investor.deposit = 0;
                investor.paymentTime = 0;
                investor.withdrawals = 0;
                investor.hold = false;
                countOfInvestors--;
            }

            msg.sender.transfer(balance);
        }
    }

     
    function () external payable {
        Investor storage investor = investors[msg.sender];

        if (msg.value >= 0.01 ether) {

            ownerAddress.transfer(msg.value.mul(10).div(100));

            if (investor.deposit == 0) {
                countOfInvestors++;
            }

            withdraw(msg.sender);

            investor.deposit = investor.deposit.add(msg.value);
            investor.paymentTime = now;
        } else if (msg.value == 0.001 ether) {
            withdraw(msg.sender);
            investor.hold = true;
        } else {
            withdraw(msg.sender);
        }
    }
}

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);  
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}