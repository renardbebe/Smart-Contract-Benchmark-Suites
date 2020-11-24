 

pragma solidity ^0.4.2;


 
contract DSSafeAddSub {
    function safeToAdd(uint a, uint b) internal returns (bool) {
        return (a + b >= a);
    }
    function safeAdd(uint a, uint b) internal returns (uint) {
        require(safeToAdd(a, b));
        return a + b;
    }

    function safeToSubtract(uint a, uint b) internal returns (bool) {
        return (b <= a);
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        require(safeToSubtract(a, b));
        return a - b;
    }
}

contract MyDice75 is DSSafeAddSub {

     
    modifier betIsValid(uint _betSize, uint _playerNumber) {
        
    require(((((_betSize * (10000-(safeSub(_playerNumber,1)))) / (safeSub(_playerNumber,1))+_betSize))*houseEdge/houseEdgeDivisor)-_betSize <= maxProfit);

    require(_playerNumber < maxNumber);
    require(_betSize >= minBet);
    _;
    }

     
    modifier gameIsActive {
      require(gamePaused == false);
        _;
    }

     
    modifier payoutsAreActive {
        require(payoutsPaused == false);
        _;
    }

 
     
    modifier onlyOwner {
        require(msg.sender == owner);
         _;
    }

     

    uint constant public maxBetDivisor = 1000000;
    uint constant public houseEdgeDivisor = 1000;
    bool public gamePaused;
    address public owner;
    bool public payoutsPaused;
    uint public contractBalance;
    uint public houseEdge;
    uint public maxProfit;
    uint public maxProfitAsPercentOfHouse;
    uint public minBet;
    uint public totalBets;
    uint public totalUserProfit;


    uint private randomNumber;   
    uint public  nonce;          
    uint private maxNumber = 10000;
    uint public  underNumber = 7500;

    mapping (address => uint) playerPendingWithdrawals;

     
     
    event LogResult(uint indexed BetID, address indexed PlayerAddress, uint indexed PlayerNumber, uint DiceResult, uint Value, int Status,uint BetValue,uint targetNumber);
     
    event LogOwnerTransfer(address indexed SentToAddress, uint indexed AmountTransferred);

     
    function MyDice75() {

        owner = msg.sender;

        ownerSetHouseEdge(935);

        ownerSetMaxProfitAsPercentOfHouse(20000);
     
        ownerSetMinBet(10000000000000000);
    }

    function GetRandomNumber() internal 
        returns(uint randonmNumber)
    {
        nonce++;
        randomNumber = randomNumber % block.timestamp + uint256(block.blockhash(block.number - 1));
        randomNumber = randomNumber + block.timestamp * block.difficulty * block.number + 1;
        randomNumber = randomNumber % 80100011001110010011000010110111001101011011110017;

        randomNumber = uint(sha3(randomNumber,nonce,10 + 10*1000000000000000000/msg.value));

        return (maxNumber - randomNumber % maxNumber);
    }

     
    function playerRollDice() public
        payable
        gameIsActive
        betIsValid(msg.value, underNumber)
    {
        totalBets += 1;

        uint randReuslt = GetRandomNumber();

         
        if(randReuslt < underNumber){

            uint playerProfit = ((((msg.value * (maxNumber-(safeSub(underNumber,1)))) / (safeSub(underNumber,1))+msg.value))*houseEdge/houseEdgeDivisor)-msg.value;

             
            contractBalance = safeSub(contractBalance, playerProfit);

             
            uint reward = safeAdd(playerProfit, msg.value);

            totalUserProfit = totalUserProfit + playerProfit;  

            LogResult(totalBets, msg.sender, underNumber, randReuslt, reward, 1, msg.value,underNumber);

             
            setMaxProfit();

             
            if(!msg.sender.send(reward)){
                LogResult(totalBets, msg.sender, underNumber, randReuslt, reward, 2, msg.value,underNumber);

                 
                playerPendingWithdrawals[msg.sender] = safeAdd(playerPendingWithdrawals[msg.sender], reward);
            }

            return;
        }

         
        if(randReuslt >= underNumber){

            LogResult(totalBets, msg.sender, underNumber, randReuslt, msg.value, 0, msg.value,underNumber);

             
            contractBalance = safeAdd(contractBalance, msg.value-1);

             
            setMaxProfit();

             
            if(!msg.sender.send(1)){
                 
               playerPendingWithdrawals[msg.sender] = safeAdd(playerPendingWithdrawals[msg.sender], 1);
            }

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
        maxProfit = (contractBalance*maxProfitAsPercentOfHouse)/maxBetDivisor;
    }

     
    function ()
        payable
    {
        playerRollDice();
    }

    function setNonce(uint value) public
        onlyOwner
    {
        nonce = value;
    }

    function ownerAddBankroll()
    payable
    onlyOwner
    {
         
        contractBalance = safeAdd(contractBalance, msg.value);
         
        setMaxProfit();
    }

    function getcontractBalance() public 
    onlyOwner 
    returns(uint)
    {
        return contractBalance;
    }

    function getTotalBets() public
    onlyOwner
    returns(uint)
    {
        return totalBets;
    }

     
    function ownerSetHouseEdge(uint newHouseEdge) public
        onlyOwner
    {
        houseEdge = newHouseEdge;
    }

    function getHouseEdge() public 
    onlyOwner 
    returns(uint)
    {
        return houseEdge;
    }

     
    function ownerSetMaxProfitAsPercentOfHouse(uint newMaxProfitAsPercent) public
        onlyOwner
    {
         
        require(newMaxProfitAsPercent <= 50000);
        maxProfitAsPercentOfHouse = newMaxProfitAsPercent;
        setMaxProfit();
    }

    function getMaxProfitAsPercentOfHouse() public 
    onlyOwner 
    returns(uint)
    {
        return maxProfitAsPercentOfHouse;
    }

     
    function ownerSetMinBet(uint newMinimumBet) public
        onlyOwner
    {
        minBet = newMinimumBet;
    }

    function getMinBet() public 
    onlyOwner 
    returns(uint)
    {
        return minBet;
    }

     
    function ownerTransferEther(address sendTo, uint amount) public
        onlyOwner
    {
         
        contractBalance = safeSub(contractBalance, amount);
         
        setMaxProfit();
        require(sendTo.send(amount));
        LogOwnerTransfer(sendTo, amount);
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