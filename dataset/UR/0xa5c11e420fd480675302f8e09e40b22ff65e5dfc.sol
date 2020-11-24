 

pragma solidity 0.4.25;

contract X2Contract {
    using SafeMath for uint256;

    address public constant promotionAddress = 0x22e483dBeb45EDBC74d4fE25d79B5C28eA6Aa8Dd;
    address public constant adminAddress = 0x3C1FD40A99066266A60F60d17d5a7c51434d74bB;

    mapping (address => uint256) public deposit;
    mapping (address => uint256) public withdrawals;
    mapping (address => uint256) public time;

    uint256 public minimum = 0.01 ether;
    uint public promotionPercent = 10;
    uint public adminPercent = 2;
    uint256 public countOfInvestors;

     
    function getPhasePercent() view public returns (uint){
        uint contractBalance = address(this).balance;
        if (contractBalance < 300 ether) {
            return 2;
        }
        if (contractBalance >= 300 ether && contractBalance < 1200 ether) {
            return 3;
        }
        if (contractBalance >= 1200 ether) {
            return 4;
        }
    }

     
    function getUserBalance(address _address) view public returns (uint256) {
        uint percent = getPhasePercent();
        uint256 differentTime = now.sub(time[_address]).div(1 hours);
        uint256 differentPercent = deposit[_address].mul(percent).div(100);
        uint256 payout = differentPercent.mul(differentTime).div(24);

        return payout;
    }

     
    function withdraw(address _address) private {
         
        uint256 balance = getUserBalance(_address);
         
         
        if (deposit[_address] > 0 && address(this).balance >= balance && balance > 0) {
             
            withdrawals[_address] = withdrawals[_address].add(balance);
             
            time[_address] = now;
             
            if (withdrawals[_address] >= deposit[_address].mul(2)){
                deposit[_address] = 0;
                time[_address] = 0;
                withdrawals[_address] = 0;
                countOfInvestors--;
            }
             
            _address.transfer(balance);
        }

    }

     
    function () external payable {
        if (msg.value >= minimum){
             
            promotionAddress.transfer(msg.value.mul(promotionPercent).div(100));
             
            adminAddress.transfer(msg.value.mul(adminPercent).div(100));

             
            withdraw(msg.sender);

             
            if (deposit[msg.sender] == 0){
                countOfInvestors++;
            }

             
            deposit[msg.sender] = deposit[msg.sender].add(msg.value);
             
            time[msg.sender] = now;
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