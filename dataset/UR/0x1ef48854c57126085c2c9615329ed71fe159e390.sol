 

pragma solidity ^0.4.25;

 

contract Cryptoman {
    uint public depositValue = 0.05 ether;
    uint public returnDepositValue = 0.0112 ether;
    uint public places = 10;
    uint public winPlaces = 5;
    uint public winPercent = 150;
    uint public supportFee = 3;
    uint public prizeFee = 7;
    uint public winAmount = depositValue * winPercent / 100;
    uint public insuranceAmount = (depositValue * places * (100 - supportFee - prizeFee) / 100 - winAmount * winPlaces) / (places - winPlaces);
    uint public blocksBeforePrize = 42;
    uint public prize;
    address public lastInvestor;
    uint public lastInvestedAt;
    uint public currentRound;
    mapping (uint => address[]) public placesMap;
    mapping (uint => uint) public winners;
    uint public currentPayRound;
    uint public currentPayIndex;
    address public support1 = 0xD71C0B80E2fDF33dB73073b00A92980A7fa5b04B;
    address public support2 = 0x7a855307c008CA938B104bBEE7ffc94D3a041E53;
    
    uint private seed;
    
     
    function toBytes(uint256 x) internal pure returns (bytes b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }
    
     
    function random(uint lessThan) internal returns (uint) {
        seed += block.timestamp + uint(msg.sender);
        return uint(sha256(toBytes(uint(blockhash(block.number - 1)) + seed))) % lessThan;
    }
    
     
    function removePlace(uint index) internal {
        if (index >= placesMap[currentRound].length) return;

        for (uint i = index; i < placesMap[currentRound].length - 1; i++) {
            placesMap[currentRound][i] = placesMap[currentRound][i + 1];
        }
        placesMap[currentRound].length--;
    }
    
    function placesLeft() external view returns (uint) {
        return places - placesMap[currentRound].length;
    }
    
    function processQueue() internal {
        while (gasleft() >= 50000 && currentPayRound < currentRound) {
            uint winner = winners[currentPayRound];
            uint index = (winner + currentPayIndex) % places;
            address investor = placesMap[currentPayRound][index];
            investor.transfer(currentPayIndex < winPlaces ? winAmount : insuranceAmount);
            delete placesMap[currentPayRound][index];
            
            if (currentPayIndex == places - 1) {
                currentPayIndex = 0;
                currentPayRound++;
            } else {
                currentPayIndex++;
            }
        }
    }
    
    function () public payable {
        require(gasleft() >= 250000);
        
        if (msg.value == depositValue) {
            placesMap[currentRound].push(msg.sender);
            if (placesMap[currentRound].length == places) {
                winners[currentRound] = random(places);
                currentRound++;
            }
            
            lastInvestor = msg.sender;
            lastInvestedAt = block.number;
            uint fee = msg.value * supportFee / 200;
            support1.transfer(fee);
            support2.transfer(fee);
            prize += msg.value * prizeFee / 100;
            
            processQueue();
        } else if (msg.value == returnDepositValue) {
            uint depositCount;
            
            uint i = 0;
            while (i < placesMap[currentRound].length) {
                if (placesMap[currentRound][i] == msg.sender) {
                    depositCount++;
                    removePlace(i);
                } else {
                    i++;
                }
            }
            
            require(depositCount > 0);
            
            if (msg.sender == lastInvestor) {
                delete lastInvestor;
            }
            
            prize += msg.value;
            msg.sender.transfer(depositValue * (100 - supportFee - prizeFee) / 100 * depositCount);
        } else if (msg.value == 0) {
            if (lastInvestor == msg.sender && block.number >= lastInvestedAt + blocksBeforePrize) {
                lastInvestor.transfer(prize);
                delete prize;
                delete lastInvestor;
            }
            
            processQueue();
        } else {
            revert();
        }
    }
}