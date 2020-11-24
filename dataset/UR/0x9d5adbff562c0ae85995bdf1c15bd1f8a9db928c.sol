 

 
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
contract CryptoTycoonsConstants{
     

     
     
     
    uint constant HOUSE_EDGE_PERCENT = 1;
    uint constant RANK_FUNDS_PERCENT = 7;
    uint constant INVITER_BENEFIT_PERCENT = 7;
    uint constant HOUSE_EDGE_MINIMUM_AMOUNT = 0.0004 ether;

     
     
    uint constant MIN_JACKPOT_BET = 0.1 ether;

     
    uint constant JACKPOT_MODULO = 1000;
    uint constant JACKPOT_FEE = 0.001 ether;

     
    uint constant MIN_BET = 0.01 ether;
    uint constant MAX_AMOUNT = 10 ether;

     
    address payable public owner;
    address payable private nextOwner;

     
    mapping (address => bool ) croupierMap;

     
    uint public maxProfit;

    address payable public VIPLibraryAddress;

     
    address public secretSigner;

     
    event FailedPayment(address indexed beneficiary, uint amount);
    event VIPPayback(address indexed beneficiary, uint amount);
    event WithdrawFunds(address indexed beneficiary, uint amount);

    constructor (uint _maxProfit) public {
        owner = msg.sender;
        secretSigner = owner;
        maxProfit = _maxProfit;
        croupierMap[owner] = true;
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


     
     
    function () external payable {

    }

     
    function approveNextOwner(address payable _nextOwner) external onlyOwner {
        require (_nextOwner != owner, "Cannot approve current owner.");
        nextOwner = _nextOwner;
    }

    function acceptNextOwner() external {
        require (msg.sender == nextOwner, "Can only accept preapproved new owner.");
        owner = nextOwner;
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
        if (beneficiary.send(withdrawAmount)){
            emit WithdrawFunds(beneficiary, withdrawAmount);
        }
    }

    function kill() external onlyOwner {
         
        selfdestruct(owner);
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
        
    function handleVIPPaybackAndExp(CryptoTycoonsVIPLib vipLib, address payable gambler, uint amount) internal returns(uint vipPayback) {
         
        vipLib.addUserExp(gambler, amount);

        uint rate = vipLib.getVIPBounusRate(gambler);

        if (rate <= 0)
            return 0;

        vipPayback = amount * rate / 10000;
        if(vipPayback > 0){
            emit VIPPayback(gambler, vipPayback);
        }
    }

    function increaseRankingFund(CryptoTycoonsVIPLib vipLib, uint amount) internal{
        uint rankingFunds = uint128(amount * HOUSE_EDGE_PERCENT / 100 * RANK_FUNDS_PERCENT /100);
         
        VIPLibraryAddress.transfer(rankingFunds);
        vipLib.increaseRankingReward(rankingFunds);
    }

    function getMyAccuAmount() external view returns (uint){
        CryptoTycoonsVIPLib vipLib = CryptoTycoonsVIPLib(VIPLibraryAddress);
        return vipLib.getUserExp(msg.sender);
    }

    function getJackpotSize() external view returns (uint){
        CryptoTycoonsVIPLib vipLib = CryptoTycoonsVIPLib(VIPLibraryAddress);
        return vipLib.getJackpotSize();
    }
   
    function verifyCommit(uint commit, uint8 v, bytes32 r, bytes32 s) internal view {
         
         
         
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes memory message = abi.encodePacked(commit);
        bytes32 messageHash = keccak256(abi.encodePacked(prefix, keccak256(message)));
        require (secretSigner == ecrecover(messageHash, v, r, s), "ECDSA signature is not valid.");
    }

    function calcHouseEdge(uint amount) public pure returns (uint houseEdge) {
         
        houseEdge = amount * HOUSE_EDGE_PERCENT / 100;
        if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
            houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
        }
    }

    function calcJackpotFee(uint amount) internal pure returns (uint jackpotFee) {
         
        if (amount >= MIN_JACKPOT_BET) {
            jackpotFee = JACKPOT_FEE;
        }
    }

    function calcRankFundsFee(uint amount) internal pure returns (uint rankFundsFee) {
         
        rankFundsFee = amount * RANK_FUNDS_PERCENT / 10000;
    }

    function calcInviterBenefit(uint amount) internal pure returns (uint invitationFee) {
         
        invitationFee = amount * INVITER_BENEFIT_PERCENT / 10000;
    }

    function processBet(
        uint betMask, uint reveal, 
        uint8 v, bytes32 r, bytes32 s, address payable inviter) 
    external payable;
}

contract AceDice is CryptoTycoonsConstants(10 ether) {
    
    event Payment(address indexed beneficiary, uint amount, uint dice, uint rollUnder, uint betAmount);
    event JackpotPayment(address indexed beneficiary, uint amount, uint dice, uint rollUnder, uint betAmount);

    function processBet(
        uint betMask, uint reveal, 
        uint8 v, bytes32 r, bytes32 s, address payable inviter) 
        external payable {

        address payable gambler = msg.sender;

         
        uint amount = msg.value;
         
        require (amount >= MIN_BET && amount <= MAX_AMOUNT, "Amount should be within range.");
        require (betMask > 0 && betMask <= 96, "Mask should be within range.");
        if (inviter != address(0)){
            require(gambler != inviter, "cannot invite myself");
        }

        uint commit = uint(keccak256(abi.encodePacked(reveal)));
        verifyCommit(commit, v, r, s);

        require (betMask > 0 && betMask <= 100, "High modulo range, betMask larger than modulo.");
      
        uint possibleWinAmount;
        uint jackpotFee;

        (possibleWinAmount, jackpotFee) = getDiceWinAmount(amount, betMask);

        require (possibleWinAmount <= amount + maxProfit, "maxProfit limit violation. ");

        require (possibleWinAmount <= address(this).balance, "Cannot afford to lose this bet.");


        bytes32 entropy = keccak256(abi.encodePacked(reveal, blockhash(block.number)));

        processReward(gambler, amount, betMask, entropy, inviter);
    }

    function processReward(
        address payable gambler, uint amount, 
        uint betMask, bytes32 entropy, address payable inviter) internal{

        uint dice = uint(entropy) % 100;

        CryptoTycoonsVIPLib vipLib = CryptoTycoonsVIPLib(VIPLibraryAddress);
         
        uint payAmount = handleVIPPaybackAndExp(vipLib, msg.sender, amount);

        uint diceWinAmount;
        uint _jackpotFee;
        (diceWinAmount, _jackpotFee) = getDiceWinAmount(amount, betMask);

        uint jackpotWin = 0;
       
         
        if (amount >= MIN_JACKPOT_BET) {
                        
            VIPLibraryAddress.transfer(_jackpotFee);
            vipLib.increaseJackpot(_jackpotFee);

             
             
             

             
            if ((uint(entropy) / 100) % JACKPOT_MODULO == 0) {
                jackpotWin = vipLib.getJackpotSize();
                vipLib.payJackpotReward(gambler);
            }
        }

         
        if (jackpotWin > 0) {
            emit JackpotPayment(gambler, jackpotWin, dice, betMask, amount);
        }

        if(inviter != address(0)){
             
            inviter.transfer(amount * HOUSE_EDGE_PERCENT / 100 * INVITER_BENEFIT_PERCENT /100);
        }

        increaseRankingFund(vipLib, amount);

        if (dice < betMask) {
            payAmount += diceWinAmount;
        }
        
        if(payAmount > 0){
            if (gambler.send(payAmount)) {
                emit Payment(gambler, payAmount, dice, betMask, amount);
            } else {
                emit FailedPayment(gambler, amount);
            }
        } else {
            emit Payment(gambler, payAmount, dice, betMask, amount);
        }
        
         
         
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

        
     
     
        
     

}