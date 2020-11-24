 

pragma solidity ^0.4.25;

 
 
 
 
 
 
 
 
contract EtherDice {

    using SafeMath for uint256;

     

     
     
     
    uint constant HOUSE_EDGE_PERCENT = 1;

     
    uint constant MIN_BET = 0.01 ether;
    uint constant MAX_AMOUNT = 300000 ether;

     
     
     
     
     
     
     
     
     
    uint constant MAX_MODULO = 100;

     
     
     
     
     
     
     
     
     
     
    uint constant MAX_MASK_MODULO = 40;

     
    uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;

     
     
    address constant DUMMY_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

     
     
     
     
     
     
    uint public betExpirationBlocks = 250;

     
    address public owner;
    address private nextOwner;

     
    uint public maxProfit;

     
    address public secretSigner;

    address public exchange = 0x89df456bb9ef0F7bf7718389b150d6161c9E0431;

     
     
    uint public lockedInBets;

     
    struct Bet {
         
        uint amount;
         
        uint8 modulo;
         
         
        uint8 rollUnder;
         
        uint placeBlockNumber;
         
        uint40 mask;
         
        address gambler;
    }

     
    mapping (uint => Bet) bets;

     
    address public croupier;

     
    event SettleBet(uint commit, uint dice, uint amount, uint diceWin);

     
    event Refund(uint commit, uint amount);

     
    event Commit(uint commit);

     
    constructor () public {
        owner = msg.sender;
        secretSigner = DUMMY_ADDRESS;
        croupier = DUMMY_ADDRESS;
    }

     
    modifier onlyOwner {
        require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }

     
    modifier onlyCroupier {
        require (msg.sender == croupier, "OnlyCroupier methods called by non-croupier.");
        _;
    }

     
    function approveNextOwner(address _nextOwner) external onlyOwner {
        require (_nextOwner != owner, "Cannot approve current owner.");
        nextOwner = _nextOwner;
    }

    function acceptNextOwner() external {
        require (msg.sender == nextOwner, "Can only accept preapproved new owner.");
        owner = nextOwner;
    }

     
     
    function () public payable {
    }

     
    function setSecretSigner(address newSecretSigner) external onlyOwner {
        secretSigner = newSecretSigner;
    }

     
    function setCroupier(address newCroupier) external onlyOwner {
        croupier = newCroupier;
    }

     
    function setMaxProfit(uint _maxProfit) public onlyOwner {
        require (_maxProfit < MAX_AMOUNT, "maxProfit should be a sane number.");
        maxProfit = _maxProfit;
    }

     
    function setBetExpirationBlocks(uint _betExpirationBlocks) public onlyOwner {
        require (_betExpirationBlocks > 0, "betExpirationBlocks should be a sane number.");
        betExpirationBlocks = _betExpirationBlocks;
    }

     
    function withdrawFunds(uint withdrawAmount) external onlyOwner {
        require (withdrawAmount <= address(this).balance, "Increase amount larger than balance.");
        require (lockedInBets.add(withdrawAmount) <= address(this).balance, "Not enough funds.");
        exchange.transfer(withdrawAmount);
    }

    function getBetInfoByReveal(uint reveal) external view returns (uint commit, uint amount, uint modulo, uint rollUnder, uint placeBlockNumber, uint mask, address gambler) {
        commit = uint(keccak256(abi.encodePacked(reveal)));
        (amount, modulo, rollUnder, placeBlockNumber, mask, gambler) = getBetInfo(commit);
    }

    function getBetInfo(uint commit) public view returns (uint amount, uint modulo, uint rollUnder, uint placeBlockNumber, uint mask, address gambler) {
        Bet storage bet = bets[commit];
        amount = bet.amount;
        modulo = bet.modulo;
        rollUnder = bet.rollUnder;
        placeBlockNumber = bet.placeBlockNumber;
        mask = bet.mask;
        gambler = bet.gambler;
    }

     

     
     
     
     
     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function placeBet(uint betMask, uint modulo, uint commitLastBlock, uint commit, bytes32 r, bytes32 s, uint8 v) external payable {
         
        Bet storage bet = bets[commit];
        require (bet.gambler == address(0), "Bet should be in a 'clean' state.");

         
        require (modulo > 1 && modulo <= MAX_MODULO, "Modulo should be within range.");
        require (msg.value >= MIN_BET && msg.value <= MAX_AMOUNT, "Amount should be within range.");
        require (betMask > 0 && betMask < MAX_BET_MASK, "Mask should be within range.");

         
        require (block.number <= commitLastBlock && commitLastBlock <= block.number.add(betExpirationBlocks), "Commit has expired.");
        require (secretSigner == ecrecover(keccak256(abi.encodePacked(uint40(commitLastBlock), commit)), v, r, s), "ECDSA signature is not valid.");

        uint rollUnder;
         

        if (modulo <= MAX_MASK_MODULO) {
             
             
             
             
            rollUnder = ((betMask.mul(POPCNT_MULT)) & POPCNT_MASK).mod(POPCNT_MODULO);
             
            bet.mask = uint40(betMask);
        } else {
             
             
            require (betMask > 0 && betMask <= modulo, "High modulo range, betMask larger than modulo.");
            rollUnder = betMask;
        }

         
        uint possibleWinAmount;
        possibleWinAmount = getDiceWinAmount(msg.value, modulo, rollUnder);

         
        require (possibleWinAmount <= msg.value.add(maxProfit), "maxProfit limit violation.");

         
        lockedInBets = lockedInBets.add(possibleWinAmount);

         
        require (lockedInBets <= address(this).balance, "Cannot afford to lose this bet.");

         
        emit Commit(commit);

         
        bet.amount = msg.value;
        bet.modulo = uint8(modulo);
        bet.rollUnder = uint8(rollUnder);
        bet.placeBlockNumber = block.number;
         
        bet.gambler = msg.sender;
    }

     
     
     
     
    function settleBet(uint reveal, bytes32 blockHash) external onlyCroupier {
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        Bet storage bet = bets[commit];

         
        require (block.number > bet.placeBlockNumber, "settleBet in the same block as placeBet, or before.");
        require (block.number <= bet.placeBlockNumber.add(betExpirationBlocks), "Blockhash can't be queried by EVM.");
        require (blockhash(bet.placeBlockNumber) == blockHash);

         
        settleBetCommon(bet, reveal, commit, blockHash);
    }

     
    function settleBetCommon(Bet storage bet, uint reveal, uint commit, bytes32 entropyBlockHash) private {
         
        uint amount = bet.amount;
        uint modulo = bet.modulo;
        uint rollUnder = bet.rollUnder;
        address gambler = bet.gambler;

         
        require (amount != 0, "Bet should be in an 'active' state");

         
        bet.amount = 0;

         
         
         
         
        bytes32 entropy = keccak256(abi.encodePacked(reveal, entropyBlockHash));

         
        uint dice = uint(entropy).mod(modulo);

        uint diceWinAmount;
        diceWinAmount = getDiceWinAmount(amount, modulo, rollUnder);

        uint diceWin = 0;

         
        if (modulo <= MAX_MASK_MODULO) {
             
            if ((2 ** dice) & bet.mask != 0) {
                diceWin = diceWinAmount;
            }

        } else {
             
            if (dice < rollUnder) {
                diceWin = diceWinAmount;
            }

        }

         
        lockedInBets = lockedInBets.sub(diceWinAmount);

         
        gambler.transfer(diceWin == 0 ? 1 wei : diceWin);

         
        emit SettleBet(commit, dice, amount, diceWin);

    }

     
     
     
     
     
    function refundBet(uint commit) external {
         
        Bet storage bet = bets[commit];
        uint amount = bet.amount;

        require (amount != 0, "Bet should be in an 'active' state");

         
        require (block.number > bet.placeBlockNumber.add(betExpirationBlocks), "Blockhash can't be queried by EVM.");

         
        bet.amount = 0;

        uint diceWinAmount;
        diceWinAmount = getDiceWinAmount(amount, bet.modulo, bet.rollUnder);

        lockedInBets = lockedInBets.sub(diceWinAmount);

         
        bet.gambler.transfer(amount);

         
        emit Refund(commit, amount);
    }

     
    function getDiceWinAmount(uint amount, uint modulo, uint rollUnder) private pure returns (uint winAmount) {
        require (0 < rollUnder && rollUnder <= modulo, "Win probability out of range.");

        uint houseEdge = amount.mul(HOUSE_EDGE_PERCENT).div(100);

        require (houseEdge <= amount, "Bet doesn't even cover house edge.");
        winAmount = amount.sub(houseEdge).mul(modulo).div(rollUnder);
    }

     
     
    uint constant POPCNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
    uint constant POPCNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
    uint constant POPCNT_MODULO = 0x3F;

}

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);  
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}