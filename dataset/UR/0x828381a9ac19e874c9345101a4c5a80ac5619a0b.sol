 

 
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

        if(exp >= 30 ether && exp < 150 ether){
            level = 1;
        } else if(exp >= 150 ether && exp < 300 ether){
            level = 2;
        } else if(exp >= 300 ether && exp < 1500 ether){
            level = 3;
        } else if(exp >= 1500 ether && exp < 3000 ether){
            level = 4;
        } else if(exp >= 3000 ether && exp < 15000 ether){
            level = 5;
        } else if(exp >= 15000 ether && exp < 30000 ether){
            level = 6;
        } else if(exp >= 30000 ether && exp < 150000 ether){
            level = 7;
        } else if(exp >= 150000 ether){
            level = 8;
        } else{
            level = 0;
        }

        return level;
    }

    function getVIPBounusRate(address user) public view returns (uint256 rate){
        uint level = getVIPLevel(user);

        if(level == 1){
            rate = 1;
        } else if(level == 2){
            rate = 2;
        } else if(level == 3){
            rate = 3;
        } else if(level == 4){
            rate = 4;
        } else if(level == 5){
            rate = 5;
        } else if(level == 6){
            rate = 7;
        } else if(level == 7){
            rate = 9;
        } else if(level == 8){
            rate = 11;
        } else if(level == 9){
            rate = 13;
        } else if(level == 10){
            rate = 15;
        } else{
            rate = 0;
        }
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

contract AceDice {
     

     
     
     
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
         
         
         
         
        uint8 rollUnder;
         
        uint40 placeBlockNumber;
         
        uint40 mask;
         
        address payable gambler;
         
        address payable inviter;
    }

    struct Profile{
         
        uint avatarIndex;
         
        bytes32 nickName;
    }

     
    mapping (uint => Bet) bets;

    mapping (address => Profile) profiles;

     
    mapping (address => bool ) croupierMap;

    address payable public VIPLibraryAddress;

     
    event FailedPayment(address indexed beneficiary, uint amount);
    event Payment(address indexed beneficiary, uint amount, uint dice, uint rollUnder, uint betAmount);
    event JackpotPayment(address indexed beneficiary, uint amount, uint dice, uint rollUnder, uint betAmount);
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
        sendFunds(beneficiary, withdrawAmount, withdrawAmount, 0, 0, 0);
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

         
        uint mask;

         
         
         
         
         
         
         
         
         
         
         
        require (betMask > 0 && betMask <= 100, "High modulo range, betMask larger than modulo.");
         
         

         
        uint possibleWinAmount;
        uint jackpotFee;

        (possibleWinAmount, jackpotFee) = getDiceWinAmount(amount, betMask);

         
        require (possibleWinAmount <= amount + maxProfit, "maxProfit limit violation. ");

         
        lockedInBets += uint128(possibleWinAmount);

         
        require (jackpotFee + lockedInBets <= address(this).balance, "Cannot afford to lose this bet.");

         
        emit Commit(commit);

         
        bet.amount = amount;
         
        bet.rollUnder = uint8(betMask);
        bet.placeBlockNumber = uint40(block.number);
        bet.mask = uint40(mask);
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

         
        uint mask;

         
         
         
         
         
         
         
         
         
         
         
        require (betMask > 0 && betMask <= 100, "High modulo range, betMask larger than modulo.");
         
         

         
        uint possibleWinAmount;
        uint jackpotFee;

        (possibleWinAmount, jackpotFee) = getDiceWinAmount(amount, betMask);

         
        require (possibleWinAmount <= amount + maxProfit, "maxProfit limit violation. ");

         
        lockedInBets += uint128(possibleWinAmount);
         

         
        require (jackpotFee + lockedInBets <= address(this).balance, "Cannot afford to lose this bet.");

         
        emit Commit(commit);

         
        bet.amount = amount;
         
        bet.rollUnder = uint8(betMask);
        bet.placeBlockNumber = uint40(block.number);
        bet.mask = uint40(mask);
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
         
        uint rollUnder = bet.rollUnder;
        address payable gambler = bet.gambler;

         
        require (amount != 0, "Bet should be in an 'active' state");

        applyVIPLevel(gambler, amount);

         
        bet.amount = 0;

         
         
         
         
        bytes32 entropy = keccak256(abi.encodePacked(reveal, entropyBlockHash));

         
        uint dice = uint(entropy) % 100;

        uint diceWinAmount;
        uint _jackpotFee;
        (diceWinAmount, _jackpotFee) = getDiceWinAmount(amount, rollUnder);

        uint diceWin = 0;
        uint jackpotWin = 0;


        if (dice < rollUnder) {
            diceWin = diceWinAmount;
        }

         
        lockedInBets -= uint128(diceWinAmount);
        
        CryptoTycoonsVIPLib vipLib = CryptoTycoonsVIPLib(VIPLibraryAddress);
        
         
        if (amount >= MIN_JACKPOT_BET) {
             
             
             

             
            if ((uint(entropy) / 100) % JACKPOT_MODULO == 0) {
                jackpotWin = vipLib.getJackpotSize();
                vipLib.payJackpotReward(gambler);
            }
        }

         
        if (jackpotWin > 0) {
            emit JackpotPayment(gambler, jackpotWin, dice, rollUnder, amount);
        }

        if(bet.inviter != address(0)){
             
            bet.inviter.transfer(amount * HOUSE_EDGE_PERCENT / 100 * 10 /100);
        }

         
        VIPLibraryAddress.transfer(uint128(amount * HOUSE_EDGE_PERCENT / 100 * 9 /100));
        vipLib.increaseRankingReward(uint128(amount * HOUSE_EDGE_PERCENT / 100 * 9 /100));

         
        sendFunds(gambler, diceWin == 0 ? 1 wei : diceWin, diceWin, dice, rollUnder, amount);
    }

     
     
     
     
     
    function refundBet(uint commit) external {
         
        Bet storage bet = bets[commit];
        uint amount = bet.amount;

        require (amount != 0, "Bet should be in an 'active' state");

         
        require (block.number > bet.placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");

         
        bet.amount = 0;

        uint diceWinAmount;
        uint jackpotFee;
        (diceWinAmount, jackpotFee) = getDiceWinAmount(amount, bet.rollUnder);

        lockedInBets -= uint128(diceWinAmount);
         
        CryptoTycoonsVIPLib vipLib = CryptoTycoonsVIPLib(VIPLibraryAddress);
        vipLib.increaseJackpot(-jackpotFee);

         
        sendFunds(bet.gambler, amount, amount, 0, 0, 0);
    }

     
    function getDiceWinAmount(uint amount, uint rollUnder) private pure returns (uint winAmount, uint jackpotFee) {
        require (0 < rollUnder && rollUnder <= 100, "Win probability out of range.");

        jackpotFee = amount >= MIN_JACKPOT_BET ? JACKPOT_FEE : 0;

        uint houseEdge = amount * HOUSE_EDGE_PERCENT / 100;

        if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
        houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
        }

        require (houseEdge + jackpotFee <= amount, "Bet doesn't even cover house edge.");
        winAmount = (amount - houseEdge - jackpotFee) * 100 / rollUnder;
    }

     
    function sendFunds(address payable beneficiary, uint amount, uint successLogAmount, uint dice, uint rollUnder, uint betAmount) private {
        if (beneficiary.send(amount)) {
            emit Payment(beneficiary, successLogAmount, dice, rollUnder, betAmount);
        } else {
            emit FailedPayment(beneficiary, amount);
        }
    }

    function thisBalance() public view returns(uint) {
        return address(this).balance;
    }

    function setAvatarIndex(uint index) external{
        require (index >=0 && index <= 100, "avatar index should be in range");
        Profile storage profile = profiles[msg.sender];
        profile.avatarIndex = index;
    }

    function setNickName(bytes32 nickName) external{
        Profile storage profile = profiles[msg.sender];
        profile.nickName = nickName;
    }

    function getProfile() external view returns(uint, bytes32){
        Profile storage profile = profiles[msg.sender];
        return (profile.avatarIndex, profile.nickName);
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