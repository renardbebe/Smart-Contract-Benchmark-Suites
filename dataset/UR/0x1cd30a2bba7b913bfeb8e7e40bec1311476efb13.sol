 

pragma solidity ^0.4.25;

 
 
contract Renter {
    address support = msg.sender;
    uint public prizeFund;
    address public lastInvestor;
    uint public lastInvestedAt;
    
    uint public totalInvestors;
    uint public totalInvested;
    
     
    mapping (address => uint) public invested;
     
    mapping (address => uint) public atBlock;
     
    mapping (address => address) public referrers;
    
    function bytesToAddress(bytes source) internal pure returns (address parsedAddress) {
        assembly {
            parsedAddress := mload(add(source,0x14))
        }
        return parsedAddress;
    }

     
    function () external payable {
        require(msg.value == 0 || msg.value == 0.01 ether
            || msg.value == 0.1 ether || msg.value == 1 ether);
        
        prizeFund += msg.value * 7 / 100;
        uint transferAmount;
        
        support.transfer(msg.value / 10);
        
         
        if (invested[msg.sender] != 0) {
            uint max = (address(this).balance - prizeFund) * 9 / 10;
            
             
             
             
            uint percentage = referrers[msg.sender] == 0x0 ? 4 : 5;
            uint amount = invested[msg.sender] * percentage / 100 * (block.number - atBlock[msg.sender]) / 5900;
            if (amount > max) {
                amount = max;
            }

            transferAmount += amount;
        } else {
            totalInvestors++;
        }
        
        if (lastInvestor == msg.sender && block.number >= lastInvestedAt + 42) {
            transferAmount += prizeFund;
            prizeFund = 0;
        }
        
        if (msg.value > 0) {
            if (invested[msg.sender] == 0 && msg.data.length == 20) {
                address referrerAddress = bytesToAddress(bytes(msg.data));
                require(referrerAddress != msg.sender);     
                if (invested[referrerAddress] > 0) {
                    referrers[msg.sender] = referrerAddress;
                }
            }
            
            if (referrers[msg.sender] != 0x0) {
                referrers[msg.sender].transfer(msg.value / 10);
            }
            
            lastInvestor = msg.sender;
            lastInvestedAt = block.number;
        }

         
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
        totalInvested += msg.value;
        
        if (transferAmount > 0) {
            msg.sender.transfer(transferAmount);
        }
    }
}