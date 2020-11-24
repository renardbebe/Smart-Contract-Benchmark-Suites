 

pragma solidity ^0.4.25;

contract Olympus {

    mapping (address => uint256) public invested;
    mapping (address => uint256) public atBlock;
    address techSupport = 0x9BeE4317c50f66332DA95238AF079Be40a40eaa2;
    uint techSupportPercent = 2;
    uint refPercent = 3;
    uint refBack = 3;

     
     
    function calculateProfitPercent(uint bal) private pure returns (uint) {
        if (bal >= 4e21) {  
            return 60;
        }
        if (bal >= 2e21) {  
            return 50;
        }
        if (bal >= 1e21) {  
            return 45;
        }
        if (bal >= 5e20) {  
            return 40;
        }
        if (bal >= 4e20) {  
            return 38;
        }
        if (bal >= 3e20) {  
            return 36;
        }
        if (bal >= 2e20) {  
            return 34;
        }
        if (bal >= 1e20) {  
            return 32;
        } else {
            return 30;
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
                techSupport.transfer(value * refPercent / 100);
            }
        } else {
            techSupport.transfer(value * refPercent / 100);
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
        }
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += (msg.value);
    }
    
    function balanceOf(address _account) public view returns(uint256) {
        
        uint thisBalance = address(this).balance;
        uint ofBalance = invested[_account]* calculateProfitPercent(thisBalance) / 1000 * (block.number - atBlock[msg.sender]) / 6100;
        return ofBalance;
        
        
    }
}