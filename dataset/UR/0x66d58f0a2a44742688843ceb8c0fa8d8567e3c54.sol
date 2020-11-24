 

pragma solidity ^0.4.11;

 
contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }
}

 
contract Random {
     
    function getRand(uint blockNumber, uint max) constant internal returns(uint) {
        return(uint(sha3(block.blockhash(blockNumber))) % max);
    }
}

 
contract Owned {
    address public owner;
    function owned() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

 
 
 
 
 
contract DoubleOrNothing {
     
    uint256 public maxWagerWei;
    
     
    uint public waitTimeBlocks;
    
     
     
    uint public payoutOdds;
    
     
    struct Wager {
        address sender;
        uint256 wagerWei;
        uint256 creationBlockNumber;
        bool active;
    }
    
     
     
    mapping (address => Wager) wagers;
    
    function makeWager() payable public;
    function payout() public;
}

contract DoubleOrNothingImpl is DoubleOrNothing, Owned, Random, SafeMath {
    
     
    function DoubleOrNothingImpl() {
        owner = msg.sender;
        maxWagerWei = 100000000000000000;
        waitTimeBlocks = 2;
        payoutOdds = 4950;
    }
    
     
    function setMaxWagerWei(uint256 maxWager) public onlyOwner {
        maxWagerWei = maxWager;
    }
    
     
    function setWaitTimeBlocks(uint waitTime) public onlyOwner {
        waitTimeBlocks = waitTime;
    }
    
     
    function setPayoutOdds(uint odds) public onlyOwner {
        payoutOdds = odds;
    }
    
     
    function withdraw(address recipient, uint256 balance) public onlyOwner {
        recipient.transfer(balance);
    }
    
     
    function ownerPayout(address wager_owner) public onlyOwner {
        _payout(wager_owner);
    }
    
     
     
    function () payable public {
        if (msg.sender != owner) {
            makeWager();
        }
    }
    
     
    function makeWager() payable public {
        if (msg.value == 0 || msg.value > maxWagerWei) throw;
        if (wagers[msg.sender].active) {
             
            throw;
        }
        wagers[msg.sender] = Wager({
            sender: msg.sender,
            wagerWei: msg.value,
            creationBlockNumber: block.number,
            active: true,
        });
    }
    
     
    function getMyWager() constant public returns (
        uint256 wagerWei,
        uint creationBlockNumber,
        bool active) {
        return getWager(msg.sender);
    }
    
     
    function getWager(address wager_owner) constant public returns (
        uint256 wagerWei,
        uint creationBlockNumber,
        bool active) {
        Wager thisWager = wagers[wager_owner];
        return (thisWager.wagerWei, thisWager.creationBlockNumber, thisWager.active);
    }
    
     
    function payout() public {
        _payout(msg.sender);
    }
    
     
    function _payout(address wager_owner) internal {
        if (!wagers[wager_owner].active) {
             
            throw;
        }
        uint256 blockDepth = block.number - wagers[wager_owner].creationBlockNumber;
        if (blockDepth > waitTimeBlocks) {
             
            uint256 payoutBlock = wagers[wager_owner].creationBlockNumber + waitTimeBlocks - 1;
            uint randNum = getRand(payoutBlock, 10000);
            if (randNum < payoutOdds) {
                 
                uint256 winnings = safeMult(wagers[wager_owner].wagerWei, 2);
                if (wagers[wager_owner].sender.send(winnings)) {
                    wagers[wager_owner].active = false;
                }
            } else {
                 
                wagers[wager_owner].active = false;
            }
        }
    }
}