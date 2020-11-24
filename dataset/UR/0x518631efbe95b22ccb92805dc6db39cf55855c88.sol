 

 
pragma solidity ^0.5.0;

contract CryptoTycoonsVIPLib{
    
    address payable public owner;
    
     
    uint128 public jackpotSize;
    uint128 public rankingRewardSize;
    
    mapping (address => uint) userExpPool;
    mapping (address => bool) public callerMap;

    event RankingRewardPayment(address indexed beneficiary, uint amount);

    modifier onlyOwner {
        require(msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }

    modifier onlyCaller {
        bool isCaller = callerMap[msg.sender];
        require(isCaller, "onlyCaller methods called by non-caller.");
        _;
    }

    constructor() public{
        owner = msg.sender;
        callerMap[owner] = true;
    }

     
     
    function () external payable {
    }

    function kill() external onlyOwner {
        selfdestruct(owner);
    }

    function addCaller(address caller) public onlyOwner{
        bool isCaller = callerMap[caller];
        if (isCaller == false){
            callerMap[caller] = true;
        }
    }

    function deleteCaller(address caller) external onlyOwner {
        bool isCaller = callerMap[caller];
        if (isCaller == true) {
            callerMap[caller] = false;
        }
    }

    function addUserExp(address addr, uint256 amount) public onlyCaller{
        uint exp = userExpPool[addr];
        exp = exp + amount;
        userExpPool[addr] = exp;
    }

    function getUserExp(address addr) public view returns(uint256 exp){
        return userExpPool[addr];
    }

    function getVIPLevel(address user) public view returns (uint256 level) {
        uint exp = userExpPool[user];

        if(exp >= 25 ether && exp < 125 ether){
            level = 1;
        } else if(exp >= 125 ether && exp < 250 ether){
            level = 2;
        } else if(exp >= 250 ether && exp < 1250 ether){
            level = 3;
        } else if(exp >= 1250 ether && exp < 2500 ether){
            level = 4;
        } else if(exp >= 2500 ether && exp < 12500 ether){
            level = 5;
        } else if(exp >= 12500 ether && exp < 25000 ether){
            level = 6;
        } else if(exp >= 25000 ether && exp < 125000 ether){
            level = 7;
        } else if(exp >= 125000 ether && exp < 250000 ether){
            level = 8;
        } else if(exp >= 250000 ether && exp < 1250000 ether){
            level = 9;
        } else if(exp >= 1250000 ether){
            level = 10;
        } else{
            level = 0;
        }

        return level;
    }

    function getVIPBounusRate(address user) public view returns (uint256 rate){
        uint level = getVIPLevel(user);
        return level;
    }

     
    function increaseJackpot(uint increaseAmount) external onlyCaller {
        require (increaseAmount <= address(this).balance, "Increase amount larger than balance.");
        require (jackpotSize + increaseAmount <= address(this).balance, "Not enough funds.");
        jackpotSize += uint128(increaseAmount);
    }

    function payJackpotReward(address payable to) external onlyCaller{
        to.transfer(jackpotSize);
        jackpotSize = 0;
    }

    function getJackpotSize() external view returns (uint256){
        return jackpotSize;
    }

    function increaseRankingReward(uint amount) public onlyCaller{
        require (amount <= address(this).balance, "Increase amount larger than balance.");
        require (rankingRewardSize + amount <= address(this).balance, "Not enough funds.");
        rankingRewardSize += uint128(amount);
    }

    function payRankingReward(address payable to) external onlyCaller {
        uint128 prize = rankingRewardSize / 2;
        rankingRewardSize = rankingRewardSize - prize;
        if(to.send(prize)){
            emit RankingRewardPayment(to, prize);
        }
    }

    function getRankingRewardSize() external view returns (uint128){
        return rankingRewardSize;
    }
}

contract CardRPS {
     

     
     
     
    uint constant HOUSE_EDGE_PERCENT = 1;
    uint constant HOUSE_EDGE_MINIMUM_AMOUNT = 0.0004 ether;

     
     
    uint constant MIN_JACKPOT_BET = 0.1 ether;

     
    uint constant JACKPOT_MODULO = 1000;
    uint constant JACKPOT_FEE = 0.001 ether;

     
    uint constant MIN_BET = 0.01 ether;
    uint constant MAX_AMOUNT = 300000 ether;

     
     
     
     
     
     
     
     
     
     

     
     
     
     
     
     
     
     
     
     
    uint constant MAX_MASK_MODULO = 40;

     
    uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;

     
     
     
     
     
     
    uint constant BET_EXPIRATION_BLOCKS = 250;

     
     
    address constant DUMMY_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

     
    address payable public owner;
    address payable private nextOwner;

     
    uint public maxProfit;

     
    address public secretSigner;

     
     
    uint128 public lockedInBets;

     
    struct Bet {
         
        uint amount;
         
        uint40 placeBlockNumber;
         
        address payable gambler;
         
        address payable inviter;
    }

    struct RandomNumber{
        uint8 playerNum1;
        uint8 playerNum2;
        uint8 npcNum1;
        uint8 npcNum2;
        uint8 rouletteIndex;
    }

     
    mapping (uint => Bet) bets;

     
    mapping (address => bool ) croupierMap;

    address payable public VIPLibraryAddress;

     
    event FailedPayment(address indexed beneficiary, uint amount);
    event Payment(address indexed beneficiary, uint amount, uint playerNum1, uint playerNum2, uint npcNum1, uint npcNum2, uint betAmount);
    event JackpotPayment(address indexed beneficiary, uint amount, uint playerNum1, uint playerNum2, uint npcNum1, uint npcNum2, uint betAmount);
    event VIPPayback(address indexed beneficiary, uint amount);

     
    event Commit(uint commit);

     
    constructor () public {
        owner = msg.sender;
        secretSigner = DUMMY_ADDRESS;
    }

     
    modifier onlyOwner {
        require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }

     
    modifier onlyCroupier {
    bool isCroupier = croupierMap[msg.sender];
        require(isCroupier, "OnlyCroupier methods called by non-croupier.");
        _;
    }

     
    function approveNextOwner(address payable _nextOwner) external onlyOwner {
        require (_nextOwner != owner, "Cannot approve current owner.");
        nextOwner = _nextOwner;
    }

    function acceptNextOwner() external {
        require (msg.sender == nextOwner, "Can only accept preapproved new owner.");
        owner = nextOwner;
    }

     
     
    function () external payable {
    }

     
    function setSecretSigner(address newSecretSigner) external onlyOwner {
        secretSigner = newSecretSigner;
    }

    function getSecretSigner() external onlyOwner view returns(address){
        return secretSigner;
    }

    function addCroupier(address newCroupier) external onlyOwner {
        bool isCroupier = croupierMap[newCroupier];
        if (isCroupier == false) {
            croupierMap[newCroupier] = true;
        }
    }
    
    function deleteCroupier(address newCroupier) external onlyOwner {
        bool isCroupier = croupierMap[newCroupier];
        if (isCroupier == true) {
            croupierMap[newCroupier] = false;
        }
    }

    function setVIPLibraryAddress(address payable addr) external onlyOwner{
        VIPLibraryAddress = addr;
    }

     
    function setMaxProfit(uint _maxProfit) public onlyOwner {
        require (_maxProfit < MAX_AMOUNT, "maxProfit should be a sane number.");
        maxProfit = _maxProfit;
    }

     
    function withdrawFunds(address payable beneficiary, uint withdrawAmount) external onlyOwner {
        require (withdrawAmount <= address(this).balance, "Increase amount larger than balance.");
        require (lockedInBets + withdrawAmount <= address(this).balance, "Not enough funds.");
        sendFunds(beneficiary, withdrawAmount, withdrawAmount, 0, 0, 0, 0, 0);
    }

    function kill() external onlyOwner {
        require (lockedInBets == 0, "All bets should be processed (settled or refunded) before self-destruct.");
        selfdestruct(owner);
    }

    function encodePacketCommit(uint commitLastBlock, uint commit) private pure returns(bytes memory){
        return abi.encodePacked(uint40(commitLastBlock), commit);
    }

    function verifyCommit(uint commitLastBlock, uint commit, uint8 v, bytes32 r, bytes32 s) private view {
         
        require (block.number <= commitLastBlock, "Commit has expired.");
         
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes memory message = encodePacketCommit(commitLastBlock, commit);
        bytes32 messageHash = keccak256(abi.encodePacked(prefix, keccak256(message)));
        require (secretSigner == ecrecover(messageHash, v, r, s), "ECDSA signature is not valid.");
    }

    function placeBet(uint betMask, uint commitLastBlock, uint commit, uint8 v, bytes32 r, bytes32 s) external payable {
         
        Bet storage bet = bets[commit];
        require (bet.gambler == address(0), "Bet should be in a 'clean' state.");

         
        uint amount = msg.value;
         
        require (amount >= MIN_BET && amount <= MAX_AMOUNT, "Amount should be within range.");
        require (betMask > 0 && betMask < MAX_BET_MASK, "Mask should be within range.");

        verifyCommit(commitLastBlock, commit, v, r, s);

         
        uint possibleWinAmount = amount * 5;
        uint jackpotFee = amount >= MIN_JACKPOT_BET ? JACKPOT_FEE : 0;

         
        require (possibleWinAmount <= amount + maxProfit, "maxProfit limit violation. ");

         
        lockedInBets += uint128(possibleWinAmount);

         
        require (jackpotFee + lockedInBets <= address(this).balance, "Cannot afford to lose this bet.");

         
        emit Commit(commit);

         
        bet.amount = amount;
        bet.placeBlockNumber = uint40(block.number);
        bet.gambler = msg.sender;

        CryptoTycoonsVIPLib vipLib = CryptoTycoonsVIPLib(VIPLibraryAddress);
        vipLib.addUserExp(msg.sender, amount);

        if (jackpotFee > 0){
            VIPLibraryAddress.transfer(jackpotFee);
            vipLib.increaseJackpot(jackpotFee);
        }
    }

    function placeBetWithInviter(uint betMask, uint commitLastBlock, uint commit, uint8 v, bytes32 r, bytes32 s, address payable inviter) external payable {
         
        Bet storage bet = bets[commit];
        require (bet.gambler == address(0), "Bet should be in a 'clean' state.");

         
        uint amount = msg.value;
         
        require (amount >= MIN_BET && amount <= MAX_AMOUNT, "Amount should be within range.");
        require (betMask > 0 && betMask < MAX_BET_MASK, "Mask should be within range.");
        require (address(this) != inviter && inviter != address(0), "cannot invite mysql");

        verifyCommit(commitLastBlock, commit, v, r, s);

         
         

         
         
         
         
         
         
         
         
         
         
         
         
         
         

         
        uint possibleWinAmount = amount * 5;
        uint jackpotFee  = amount >= MIN_JACKPOT_BET ? JACKPOT_FEE : 0;

         
        require (possibleWinAmount <= amount + maxProfit, "maxProfit limit violation. ");

         
        lockedInBets += uint128(possibleWinAmount);
         

         
        require (jackpotFee + lockedInBets <= address(this).balance, "Cannot afford to lose this bet.");

         
        emit Commit(commit);

         
        bet.amount = amount;
         
         
        bet.placeBlockNumber = uint40(block.number);
         
        bet.gambler = msg.sender;
        bet.inviter = inviter;

        CryptoTycoonsVIPLib vipLib = CryptoTycoonsVIPLib(VIPLibraryAddress);
        vipLib.addUserExp(msg.sender, amount);

        if (jackpotFee > 0){
            VIPLibraryAddress.transfer(jackpotFee);
            vipLib.increaseJackpot(jackpotFee);
        }
    }
    
    function applyVIPLevel(address payable gambler, uint amount) private {
        CryptoTycoonsVIPLib vipLib = CryptoTycoonsVIPLib(VIPLibraryAddress);
        uint rate = vipLib.getVIPBounusRate(gambler);

        if (rate <= 0)
            return;

        uint vipPayback = amount * rate / 10000;
        if(gambler.send(vipPayback)){
            emit VIPPayback(gambler, vipPayback);
        }
    }

    function getMyAccuAmount() external view returns (uint){
        CryptoTycoonsVIPLib vipLib = CryptoTycoonsVIPLib(VIPLibraryAddress);
        return vipLib.getUserExp(msg.sender);
    }

    function getJackpotSize() external view returns (uint){
        CryptoTycoonsVIPLib vipLib = CryptoTycoonsVIPLib(VIPLibraryAddress);
        return vipLib.getJackpotSize();
    }

     
     
     
     
    function settleBet(uint reveal, bytes32 blockHash) external onlyCroupier {
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        Bet storage bet = bets[commit];
        uint placeBlockNumber = bet.placeBlockNumber;

         
        require (block.number > placeBlockNumber, "settleBet in the same block as placeBet, or before.");
        require (block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");
        require (blockhash(placeBlockNumber) == blockHash);

         
        settleBetCommon(bet, reveal, blockHash);
    }

         
    function settleBetCommon(Bet storage bet, uint reveal, bytes32 entropyBlockHash) private {
         
        uint amount = bet.amount;
         
         
         

         
        require (amount != 0, "Bet should be in an 'active' state");

        applyVIPLevel(bet.gambler, amount);

         
        bet.amount = 0;

         
        lockedInBets -= uint128(amount * 5);

         
         
         
         
        uint entropy = uint(keccak256(abi.encodePacked(reveal, entropyBlockHash)));
        uint seed = entropy;
         

        RandomNumber memory randomNumber = RandomNumber(0, 0, 0, 0, 0);
         
        randomNumber.playerNum1 = uint8(seed % 3);
        seed = seed / 2 ** 8;
        
        randomNumber.playerNum2 = uint8(seed % 3);        
        seed = seed / 2 ** 8;

        randomNumber.npcNum1 = uint8(seed % 3);
        seed = seed / 2 ** 8;

        randomNumber.npcNum2 = uint8(seed % 3);
        seed = seed / 2 ** 8;

        randomNumber.rouletteIndex = uint8(seed % 12);
        seed = seed / 2 ** 8;

        uint jackpotFee = amount >= MIN_JACKPOT_BET ? JACKPOT_FEE : 0;


        uint houseEdge = amount * HOUSE_EDGE_PERCENT / 100;

        if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
            houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
        }
        amount = amount - houseEdge - jackpotFee;

        uint8 winValue = calculateWinValue(randomNumber);  

        uint winAmount;

        if (winValue == 0) {
             
            winAmount = amount;
        } else if (winValue == 1) {
             
            winAmount = amount * getRouletteRate(randomNumber.rouletteIndex) / 10;
        } else {

        }

        if(bet.inviter != address(0)){
             
            bet.inviter.transfer(amount * HOUSE_EDGE_PERCENT / 100 * 10 /100);
        }
        
        processVIPAndJackpotLogic(bet, amount, houseEdge, randomNumber, seed);

         
        sendFunds(bet.gambler, winAmount == 0 ? 1 wei : winAmount, winAmount, 
                    randomNumber.playerNum1, 
                    randomNumber.playerNum2, 
                    randomNumber.npcNum1, 
                    randomNumber.npcNum2, 
                    amount);
    }

    function processVIPAndJackpotLogic(Bet memory bet, uint amount, uint houseEdge, RandomNumber memory randomNumber, uint entropy) private{
        CryptoTycoonsVIPLib vipLib = CryptoTycoonsVIPLib(VIPLibraryAddress);
        
        handleJackpotStatus(bet, amount, randomNumber, entropy, vipLib);

         
        VIPLibraryAddress.transfer(uint128(houseEdge * 9 /100));
        vipLib.increaseRankingReward(uint128(houseEdge * 9 /100));
    }

    function handleJackpotStatus(Bet memory bet, uint amount, RandomNumber memory randomNumber, uint seed, CryptoTycoonsVIPLib vipLib) private {
        uint jackpotWin = 0;
         
        if (amount >= MIN_JACKPOT_BET) {
             
             
             

             
            if (seed % JACKPOT_MODULO == 0) {
                jackpotWin = vipLib.getJackpotSize();
                vipLib.payJackpotReward(bet.gambler);
            }
        }

         
        if (jackpotWin > 0) {
            emit JackpotPayment(bet.gambler, 
                    jackpotWin, 
                    randomNumber.playerNum1, 
                    randomNumber.playerNum2, 
                    randomNumber.npcNum1, 
                    randomNumber.npcNum2, 
                    amount);
        }
    }

    function calculateWinValue(RandomNumber memory randomNumber) private pure returns (uint8){
        uint8 playerNum1 = randomNumber.playerNum1;
        uint8 playerNum2 = randomNumber.playerNum2;
        uint8 npcNum1 = randomNumber.npcNum1;
        uint8 npcNum2 = randomNumber.npcNum2;

        uint8 winValue = 0;
        if (playerNum1 == npcNum1){  
            if (playerNum2 == npcNum2){
                winValue = 0;
            } else if(playerNum2 == 0 && npcNum2 == 2){
                winValue = 1;  
            } else if(playerNum2 == 1 && npcNum2 == 0){
                winValue = 1;  
            } else if(playerNum2 == 2 && npcNum2 == 1){
                winValue = 1;  
            } else{
                winValue = 2;  
            }
        } else if(playerNum1 == 0 && npcNum1 == 2){
            winValue = 1;  
        } else if(playerNum1 == 1 && npcNum1 == 0){
            winValue = 1;  
        } else if(playerNum1 == 2 && npcNum1 == 1){
            winValue = 1;  
        } else{
            winValue = 2;  
        } 
        return winValue;
    }

    function getRouletteRate(uint index) private pure returns (uint8){
        uint8 rate = 11;
        if (index == 0){
            rate = 50;
        } else if(index== 1){
            rate = 11;
        } else if(index== 2){
            rate = 20;
        } else if(index== 3){
            rate = 15;
        } else if(index== 4){
            rate = 20;
        } else if(index== 5){
            rate = 11;
        } else if(index== 6){
            rate = 20;
        } else if(index== 7){
            rate = 15;
        } else if(index== 8){
            rate = 20;
        } else if(index== 9){
            rate = 11;
        } else if(index== 10){
            rate = 20;
        } else if(index== 11){
            rate = 15;
        }
        return rate;
    }

     
     
     
     
     
    function refundBet(uint commit) external {
         
        Bet storage bet = bets[commit];
        uint amount = bet.amount;

        require (amount != 0, "Bet should be in an 'active' state");

         
        require (block.number > bet.placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");

         
        bet.amount = 0;

        uint diceWinAmount;
        uint jackpotFee  = amount >= MIN_JACKPOT_BET ? JACKPOT_FEE : 0;

        lockedInBets -= uint128(diceWinAmount);
         
        CryptoTycoonsVIPLib vipLib = CryptoTycoonsVIPLib(VIPLibraryAddress);
        vipLib.increaseJackpot(-jackpotFee);

         
        sendFunds(bet.gambler, amount, amount, 0,0, 0, 0, 0);
    }

     
     
     

     

     

     
     
     

     
     
     

     
    function sendFunds(address payable beneficiary, uint amount, uint successLogAmount, uint playerNum1, uint playerNum2, uint npcNum1, uint npcNum2, uint betAmount) private {
        if (beneficiary.send(amount)) {
            emit Payment(beneficiary, successLogAmount, playerNum1, playerNum2, npcNum1, npcNum2, betAmount);
        } else {
            emit FailedPayment(beneficiary, amount);
        }
    }

    function thisBalance() public view returns(uint) {
        return address(this).balance;
    }

    function payTodayReward(address payable to) external onlyOwner {
        CryptoTycoonsVIPLib vipLib = CryptoTycoonsVIPLib(VIPLibraryAddress);
        vipLib.payRankingReward(to);
    }

    function getRankingRewardSize() external view returns (uint128) {
        CryptoTycoonsVIPLib vipLib = CryptoTycoonsVIPLib(VIPLibraryAddress);
        return vipLib.getRankingRewardSize();
    }
}