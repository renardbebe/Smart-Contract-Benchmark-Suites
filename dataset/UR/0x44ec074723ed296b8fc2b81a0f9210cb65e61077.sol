 

pragma solidity ^0.4.18;

contract DSSafeAddSub {
    function safeToAdd(uint a, uint b) internal returns (bool) {
        return (a + b >= a);
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        if (!safeToAdd(a, b)) throw;
        return a + b;
    }

    function safeToSubtract(uint a, uint b) internal returns (bool) {
        return (b <= a);
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        if (!safeToSubtract(a, b)) throw;
        return a - b;
    }
}


contract LuckyDice is DSSafeAddSub {

     
    modifier betIsValid(uint _betSize, uint minRollLimit, uint maxRollLimit) {
        if (_betSize < minBet || maxRollLimit < minNumber || minRollLimit > maxNumber || maxRollLimit - 1 <= minRollLimit) throw;
        _;
    }

     
    modifier gameIsActive {
        if (gamePaused == true) throw;
        _;
    }

     
    modifier payoutsAreActive {
        if (payoutsPaused == true) throw;
        _;
    }


     
    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

     
    modifier onlyCasino {
        if (msg.sender != casino) throw;
        _;
    }

     
    uint[] rollSumProbability = [0, 0, 0, 0, 0, 128600, 643004, 1929012, 4501028, 9002057, 16203703, 26363168, 39223251, 54012345, 69444444, 83719135, 94521604, 100308641, 100308641, 94521604, 83719135, 69444444, 54012345, 39223251, 26363168, 16203703, 9002057, 4501028, 1929012, 643004, 128600];
    uint probabilityDivisor = 10000000;

     
    uint constant public maxProfitDivisor = 1000000;
    uint constant public houseEdgeDivisor = 1000;
    uint constant public maxNumber = 30;
    uint constant public minNumber = 5;
    bool public gamePaused;
    address public owner;
    bool public payoutsPaused;
    address public casino;
    uint public contractBalance;
    uint public houseEdge;
    uint public maxProfit;
    uint public maxProfitAsPercentOfHouse;
    uint public minBet;
    int public totalBets;
    uint public maxPendingPayouts;
    uint public totalWeiWon = 0;
    uint public totalWeiWagered = 0;

     
    uint public jackpot = 0;
    uint public jpPercentage = 40;  
    uint public jpPercentageDivisor = 1000;
    uint public jpMinBet = 10000000000000000;  

     
    uint tempDiceSum;
    bool tempJp;
    uint tempDiceValue;
    bytes tempRollResult;
    uint tempFullprofit;

     
    mapping(bytes32 => address) public playerAddress;
    mapping(bytes32 => address) playerTempAddress;
    mapping(bytes32 => bytes32) playerBetDiceRollHash;
    mapping(bytes32 => uint) playerBetValue;
    mapping(bytes32 => uint) playerTempBetValue;
    mapping(bytes32 => uint) playerRollResult;
    mapping(bytes32 => uint) playerMaxRollLimit;
    mapping(bytes32 => uint) playerMinRollLimit;
    mapping(address => uint) playerPendingWithdrawals;
    mapping(bytes32 => uint) playerProfit;
    mapping(bytes32 => uint) playerToJackpot;
    mapping(bytes32 => uint) playerTempReward;

     
     
    event LogBet(bytes32 indexed DiceRollHash, address indexed PlayerAddress, uint ProfitValue, uint ToJpValue,
        uint BetValue, uint minRollLimit, uint maxRollLimit);

     
     
    event LogResult(bytes32 indexed DiceRollHash, address indexed PlayerAddress, uint minRollLimit, uint maxRollLimit,
        uint DiceResult, uint Value, string Salt, int Status);

     
    event LogRefund(bytes32 indexed DiceRollHash, address indexed PlayerAddress, uint indexed RefundValue);

     
    event LogOwnerTransfer(address indexed SentToAddress, uint indexed AmountTransferred);

     
     
    event LogJpPayment(bytes32 indexed DiceRollHash, address indexed PlayerAddress, uint DiceResult, uint JackpotValue,
        int Status);


     
    function LuckyDice() {

        owner = msg.sender;
        casino = msg.sender;

         
        ownerSetHouseEdge(960);

         
        ownerSetMaxProfitAsPercentOfHouse(55556);

         
        ownerSetMinBet(100000000000000000);
    }

     
    function playerMakeBet(uint minRollLimit, uint maxRollLimit, bytes32 diceRollHash, uint8 v, bytes32 r, bytes32 s) public
    payable
    gameIsActive
    betIsValid(msg.value, minRollLimit, maxRollLimit)
    {
         
        if (playerAddress[diceRollHash] != 0x0) throw;

         
        if (casino != ecrecover(diceRollHash, v, r, s)) throw;

        tempFullprofit = getFullProfit(msg.value, minRollLimit, maxRollLimit);
        playerProfit[diceRollHash] = getProfit(msg.value, tempFullprofit);
        playerToJackpot[diceRollHash] = getToJackpot(msg.value, tempFullprofit);
        if (playerProfit[diceRollHash] - playerToJackpot[diceRollHash] > maxProfit)
            throw;

         
        playerBetDiceRollHash[diceRollHash] = diceRollHash;
         
        playerMinRollLimit[diceRollHash] = minRollLimit;
        playerMaxRollLimit[diceRollHash] = maxRollLimit;
         
        playerBetValue[diceRollHash] = msg.value;
         
        playerAddress[diceRollHash] = msg.sender;
         
        maxPendingPayouts = safeAdd(maxPendingPayouts, playerProfit[diceRollHash]);


         
        if (maxPendingPayouts >= contractBalance)
            throw;

         
        LogBet(diceRollHash, playerAddress[diceRollHash], playerProfit[diceRollHash], playerToJackpot[diceRollHash],
            playerBetValue[diceRollHash], playerMinRollLimit[diceRollHash], playerMaxRollLimit[diceRollHash]);
    }

    function getFullProfit(uint _betSize, uint minRollLimit, uint maxRollLimit) internal returns (uint){
        uint probabilitySum = 0;
        for (uint i = minRollLimit + 1; i < maxRollLimit; i++)
        {
            probabilitySum += rollSumProbability[i];
        }

        return _betSize * safeSub(probabilityDivisor * 100, probabilitySum) / probabilitySum;
    }

    function getProfit(uint _betSize, uint fullProfit) internal returns (uint){
        return (fullProfit + _betSize) * houseEdge / houseEdgeDivisor - _betSize;
    }

    function getToJackpot(uint _betSize, uint fullProfit) internal returns (uint){
        return (fullProfit + _betSize) * jpPercentage / jpPercentageDivisor;
    }

    function withdraw(bytes32 diceRollHash, string rollResult, string salt) public
    payoutsAreActive
    {
         
        if (playerAddress[diceRollHash] == 0x0) throw;

         
        bytes32 hash = sha256(rollResult, salt);
        if (diceRollHash != hash) throw;

         
        playerTempAddress[diceRollHash] = playerAddress[diceRollHash];
         
        delete playerAddress[diceRollHash];

         
        playerTempReward[diceRollHash] = playerProfit[diceRollHash];
         
        playerProfit[diceRollHash] = 0;

         
        maxPendingPayouts = safeSub(maxPendingPayouts, playerTempReward[diceRollHash]);

         
        playerTempBetValue[diceRollHash] = playerBetValue[diceRollHash];
         
        playerBetValue[diceRollHash] = 0;

         
        totalBets += 1;

         
        totalWeiWagered += playerTempBetValue[diceRollHash];

        tempDiceSum = 0;
        tempJp = true;
        tempRollResult = bytes(rollResult);
        for (uint i = 0; i < 5; i++) {
            tempDiceValue = uint(tempRollResult[i]) - 48;
            tempDiceSum += tempDiceValue;
            playerRollResult[diceRollHash] = playerRollResult[diceRollHash] * 10 + tempDiceValue;

            if (tempRollResult[i] != tempRollResult[1]) {
                tempJp = false;
            }
        }

         
        if (playerTempBetValue[diceRollHash] >= jpMinBet && tempJp) {
            LogJpPayment(playerBetDiceRollHash[diceRollHash], playerTempAddress[diceRollHash],
                playerRollResult[diceRollHash], jackpot, 0);

            uint jackpotTmp = jackpot;
            jackpot = 0;

            if (!playerTempAddress[diceRollHash].send(jackpotTmp)) {
                LogJpPayment(playerBetDiceRollHash[diceRollHash], playerTempAddress[diceRollHash],
                    playerRollResult[diceRollHash], jackpotTmp, 1);

                 
                playerPendingWithdrawals[playerTempAddress[diceRollHash]] =
                safeAdd(playerPendingWithdrawals[playerTempAddress[diceRollHash]], jackpotTmp);
            }
        }

         
        if (playerMinRollLimit[diceRollHash] < tempDiceSum && tempDiceSum < playerMaxRollLimit[diceRollHash]) {
             
            contractBalance = safeSub(contractBalance, playerTempReward[diceRollHash]);

             
            totalWeiWon = safeAdd(totalWeiWon, playerTempReward[diceRollHash]);

             
            playerTempReward[diceRollHash] = safeSub(playerTempReward[diceRollHash], playerToJackpot[diceRollHash]);
            jackpot = safeAdd(jackpot, playerToJackpot[diceRollHash]);

             
            playerTempReward[diceRollHash] = safeAdd(playerTempReward[diceRollHash], playerTempBetValue[diceRollHash]);

            LogResult(playerBetDiceRollHash[diceRollHash], playerTempAddress[diceRollHash],
                playerMinRollLimit[diceRollHash], playerMaxRollLimit[diceRollHash], playerRollResult[diceRollHash],
                playerTempReward[diceRollHash], salt, 1);

             
            setMaxProfit();

             
            if (!playerTempAddress[diceRollHash].send(playerTempReward[diceRollHash])) {
                LogResult(playerBetDiceRollHash[diceRollHash], playerTempAddress[diceRollHash],
                    playerMinRollLimit[diceRollHash], playerMaxRollLimit[diceRollHash], playerRollResult[diceRollHash],
                    playerTempReward[diceRollHash], salt, 2);

                 
                playerPendingWithdrawals[playerTempAddress[diceRollHash]] =
                safeAdd(playerPendingWithdrawals[playerTempAddress[diceRollHash]], playerTempReward[diceRollHash]);
            }

            return;

        } else {
             

            LogResult(playerBetDiceRollHash[diceRollHash], playerTempAddress[diceRollHash],
                playerMinRollLimit[diceRollHash], playerMaxRollLimit[diceRollHash], playerRollResult[diceRollHash],
                playerTempBetValue[diceRollHash], salt, 0);

             
            contractBalance = safeAdd(contractBalance, (playerTempBetValue[diceRollHash]));

             
            setMaxProfit();

            return;
        }

    }

     
    function playerWithdrawPendingTransactions() public
    payoutsAreActive
    returns (bool)
    {
        uint withdrawAmount = playerPendingWithdrawals[msg.sender];
        playerPendingWithdrawals[msg.sender] = 0;
         
        if (msg.sender.call.value(withdrawAmount)()) {
            return true;
        } else {
             
             
            playerPendingWithdrawals[msg.sender] = withdrawAmount;
            return false;
        }
    }

     
    function playerGetPendingTxByAddress(address addressToCheck) public constant returns (uint) {
        return playerPendingWithdrawals[addressToCheck];
    }

     
    function setMaxProfit() internal {
        maxProfit = (contractBalance * maxProfitAsPercentOfHouse) / maxProfitDivisor;
    }

     
    function()
    payable
    onlyOwner
    {
         
        contractBalance = safeAdd(contractBalance, msg.value);
         
        setMaxProfit();
    }


     
    function ownerUpdateContractBalance(uint newContractBalanceInWei) public
    onlyOwner
    {
        contractBalance = newContractBalanceInWei;
    }

     
    function ownerSetHouseEdge(uint newHouseEdge) public
    onlyOwner
    {
        houseEdge = newHouseEdge;
    }

     
    function ownerSetMaxProfitAsPercentOfHouse(uint newMaxProfitAsPercent) public
    onlyOwner
    {
        maxProfitAsPercentOfHouse = newMaxProfitAsPercent;
        setMaxProfit();
    }

     
    function ownerSetMinBet(uint newMinimumBet) public
    onlyOwner
    {
        minBet = newMinimumBet;
    }

     
    function ownerSetJpMinBet(uint newJpMinBet) public
    onlyOwner
    {
        jpMinBet = newJpMinBet;
    }

     
    function ownerTransferEther(address sendTo, uint amount) public
    onlyOwner
    {
         
        contractBalance = safeSub(contractBalance, amount);
         
        setMaxProfit();
        if (!sendTo.send(amount)) throw;
        LogOwnerTransfer(sendTo, amount);
    }

     
    function ownerRefundPlayer(bytes32 diceRollHash, address sendTo, uint originalPlayerProfit, uint originalPlayerBetValue) public
    onlyOwner
    {
         
        maxPendingPayouts = safeSub(maxPendingPayouts, originalPlayerProfit);
         
        if (!sendTo.send(originalPlayerBetValue)) throw;
         
        LogRefund(diceRollHash, sendTo, originalPlayerBetValue);
    }

     
    function ownerPauseGame(bool newStatus) public
    onlyOwner
    {
        gamePaused = newStatus;
    }

     
    function ownerPausePayouts(bool newPayoutStatus) public
    onlyOwner
    {
        payoutsPaused = newPayoutStatus;
    }

     
    function ownerSetCasino(address newCasino) public
    onlyOwner
    {
        casino = newCasino;
    }

     
    function ownerChangeOwner(address newOwner) public
    onlyOwner
    {
        owner = newOwner;
    }

     
    function ownerkill() public
    onlyOwner
    {
        suicide(owner);
    }
}