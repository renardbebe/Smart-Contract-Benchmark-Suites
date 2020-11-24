 

pragma solidity ^0.4.18;

contract Phoenix {
     
    uint private MAX_ROUND_TIME = 365 days;
    
    uint private totalCollected;
    uint private currentRound;
    uint private currentRoundCollected;
    uint private prevLimit;
    uint private currentLimit;
    uint private currentRoundStartTime;

     
     
     
     
     
     
    struct Account {
        uint moneyNew;
        uint moneyHidden;
        uint profitTotal;
        uint profitTaken;

        uint lastUserUpdateRound;
    }
    
    mapping (address => Account) private accounts;


    function Phoenix() public {
        totalCollected = 0;
        currentRound = 0;
        currentRoundCollected = 0;
        prevLimit = 0;
        currentLimit = 100e18;
        currentRoundStartTime = block.timestamp;
    }
    
     
     
     
    function iterateToNextRound() private {
        currentRound++;
        uint tempcurrentLimit = currentLimit;
        
        if(currentRound == 1) {
            currentLimit = 200e18;
        }
        else {
            currentLimit = 4 * currentLimit - 2 * prevLimit;
        }
        
        prevLimit = tempcurrentLimit;
        currentRoundStartTime = block.timestamp;
        currentRoundCollected = 0;
    }
    
     
     
     
     
    function calculateUpdateProfit(address user) private view returns (Account) {
        Account memory acc = accounts[user];
        
        for(uint r = acc.lastUserUpdateRound; r < currentRound; r++) {
            acc.profitTotal *= 2;

            if(acc.moneyHidden > 0) {
                acc.profitTotal += acc.moneyHidden * 2;
                acc.moneyHidden = 0;
            }
            
            if(acc.moneyNew > 0) {
                acc.moneyHidden = acc.moneyNew;
                acc.moneyNew = 0;
            }
        }
        
        acc.lastUserUpdateRound = currentRound;
        return acc;
    }
    
     
    function updateProfit(address user) private returns(Account) {
        Account memory acc = calculateUpdateProfit(user);
        accounts[user] = acc;
        return acc;
    }

     
     
    function canceled() public view returns(bool isCanceled) {
        return block.timestamp >= (currentRoundStartTime + MAX_ROUND_TIME);
    }
    
     
    function () public payable {
        require(!canceled());
        deposit();
    }

     
     
     
     
     
     
     
    function deposit() public payable {
        require(!canceled());
        
        updateProfit(msg.sender);

        uint money2add = msg.value;
        totalCollected += msg.value;
        while(currentRoundCollected + money2add >= currentLimit) {
            accounts[msg.sender].moneyNew += currentLimit - 
                currentRoundCollected;
            money2add -= currentLimit - currentRoundCollected;

            iterateToNextRound();
            updateProfit(msg.sender);
        }
        
        accounts[msg.sender].moneyNew += money2add;
        currentRoundCollected += money2add;
    }
    
     
     
     
     
     
    function whatRound() public view returns (uint totalCollectedSum, 
            uint roundCollected, uint currentRoundNumber, 
            uint remainsCurrentRound) {
        return (totalCollected, currentRoundCollected, currentRound, 
            currentLimit - currentRoundCollected);
    }

     
     
     
     
     
     
     
    function myAccount() public view returns (uint profitTotal, 
            uint profitTaken, uint profitAvailable, uint investmentInProgress) {
        var acc = calculateUpdateProfit(msg.sender);
        return (acc.profitTotal, acc.profitTaken, 
                acc.profitTotal - acc.profitTaken, 
                acc.moneyNew + acc.moneyHidden);
    }

     
     
     
     
     
     
     
    function payback() private {
        require(canceled());

        var acc = accounts[msg.sender];
        uint hiddenpart = 0;
        if(prevLimit > 0) {
            hiddenpart = (acc.moneyHidden * 100e18) / prevLimit;
        }
        uint money2send = acc.moneyNew + acc.profitTotal - acc.profitTaken + 
            hiddenpart;
        if(money2send > this.balance) {
            money2send = this.balance;
        }
        acc.moneyNew = 0;
        acc.moneyHidden = 0;
        acc.profitTaken = acc.profitTotal;

        msg.sender.transfer(money2send);
    }

     
     
     
     
     
    function takeProfit() public {
        Account memory acc = updateProfit(msg.sender);

        if(canceled()) {
            payback();
            return;
        }

        uint money2send = acc.profitTotal - acc.profitTaken;
        acc.profitTaken += money2send;
        accounts[msg.sender] = acc;

        if(money2send > 0) {
            msg.sender.transfer(money2send);
        }
    }
}