 

pragma solidity ^0.4.25;

 

contract UnrealInvest {
    uint public prizePercent = 2;
    uint public supportPercent = 3;
    uint public refPercent = 5;
    uint public holdInterval = 20;
    uint public prizeInterval = 42;
    uint public percentWithoutRef = 120;
    uint public percentWithRef = 130;
    uint public minDeposit = 0.01 ether;
    
    address support = msg.sender;
    uint public prizeFund;
    address public lastInvestor;
    uint public lastInvestedAt;
    
    uint public activeInvestors;
    uint public totalInvested;
    
     
    mapping (address => bool) public registered;
     
    mapping (address => uint) public invested;
     
    mapping (address => uint) public paid;
     
    mapping (address => uint) public atBlock;
     
    mapping (address => address) public referrers;
    
    function bytesToAddress(bytes source) internal pure returns (address parsedAddress) {
        assembly {
            parsedAddress := mload(add(source,0x14))
        }
        return parsedAddress;
    }
    
    function () external payable {
        require(registered[msg.sender] && msg.value == 0 || msg.value >= minDeposit);
        
        bool fullyPaid;
        uint transferAmount;
        
        if (!registered[msg.sender] && msg.data.length == 20) {
            address referrerAddress = bytesToAddress(bytes(msg.data));
            require(referrerAddress != msg.sender);     
            if (registered[referrerAddress]) {
                referrers[msg.sender] = referrerAddress;
            }
        }
        registered[msg.sender] = true;
        
        if (invested[msg.sender] > 0 && block.number >= atBlock[msg.sender] + holdInterval) {
            uint availAmount = (address(this).balance - msg.value - prizeFund) / activeInvestors;
            uint payAmount = invested[msg.sender] * (referrers[msg.sender] == 0x0 ? percentWithoutRef : percentWithRef) / 100 - paid[msg.sender];
            if (payAmount > availAmount) {
                payAmount = availAmount;
            } else {
                fullyPaid = true;
            }
            if (payAmount > 0) {
                paid[msg.sender] += payAmount;
                transferAmount += payAmount;
                atBlock[msg.sender] = block.number;
            }
        }
        
        if (msg.value > 0) {
            if (invested[msg.sender] == 0) {
                activeInvestors++;
            }
            invested[msg.sender] += msg.value;
            atBlock[msg.sender] = block.number;
            totalInvested += msg.value;
            
            lastInvestor = msg.sender;
            lastInvestedAt = block.number;
            
            prizeFund += msg.value * prizePercent / 100;
            support.transfer(msg.value * supportPercent / 100);
            if (referrers[msg.sender] != 0x0) {
                referrers[msg.sender].transfer(msg.value * refPercent / 100);
            }
        }
        
        if (lastInvestor == msg.sender && block.number >= lastInvestedAt + prizeInterval) {
            transferAmount += prizeFund;
            delete prizeFund;
            delete lastInvestor;
        }
        
        if (transferAmount > 0) {
            msg.sender.transfer(transferAmount);
        }
        
        if (fullyPaid) {
            delete invested[msg.sender];
            delete paid[msg.sender];
            activeInvestors--;
        }
    }
}