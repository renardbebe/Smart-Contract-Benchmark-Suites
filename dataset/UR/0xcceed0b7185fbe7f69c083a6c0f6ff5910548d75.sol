 

pragma solidity <= 0.6;

contract Game365Meta {

     
    uint constant HOUSE_EDGE_PERCENT = 1;
    uint constant HOUSE_EDGE_MINIMUM_AMOUNT = 0.0003 ether; 

     
    uint public constant MIN_JACKPOT_BET = 0.1 ether;
    uint public constant JACKPOT_MODULO = 1000; 
    uint constant JACKPOT_FEE = 0.001 ether; 
     
    uint public constant MIN_BET = 0.01 ether;
    uint constant MAX_AMOUNT = 300000 ether; 
    
     
     
     
     
     
     
     
     
    uint constant MAX_MODULO = 100;
    uint constant MAX_MASK_MODULO = 40;

     
    uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;

     
     
     
     
     
     
    uint constant BET_EXPIRATION_BLOCKS = 250;

     
     
    uint constant POPCNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
    uint constant POPCNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
    uint constant POPCNT_MODULO = 0x3F;  
    
     
    address payable public owner = address(0x0);

     
    address public croupier = address(0x0);

     
    address public secretSigner = address(0x0);

     
    uint public maxProfit = 5 ether;
    uint public minJackpotWinAmount = 0.1 ether;

     
     
    uint256 public lockedInBets_;
    uint256 public lockedInJackpot_;

    struct Bet {
         
        uint128 amount;
         
        uint8 modulo;
         
         
        uint8 rollUnder;
         
        uint40 placeBlockNumber;
         
        uint40 mask;
         
        address payable gambler;
    }
    mapping(uint256 => Bet) bets;

     
    event FailedPayment(uint256 indexed commit, address indexed beneficiary, uint amount, uint jackpotAmount);
    event Payment(uint256 indexed commit, address indexed beneficiary, uint amount, uint jackpotAmount);
    event JackpotPayment(address indexed beneficiary, uint amount);
    event Commit(uint256 indexed commit, uint256 possibleWinAmount);
    
     
    constructor () 
        public
    {
        owner = msg.sender;
    }

     
     
    modifier onlyOwner {
        require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }
    
     
    modifier onlyCroupier {
        require (msg.sender == croupier, "OnlyCroupier methods called by non-croupier.");
        _;
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

    function setMinJackPotWinAmount(uint _minJackpotAmount) public onlyOwner {
        minJackpotWinAmount = _minJackpotAmount;
    }

     
    function increaseJackpot(uint increaseAmount) external onlyOwner {
        require (increaseAmount <= address(this).balance, "Increase amount larger than balance.");
        require (lockedInJackpot_ + lockedInBets_ + increaseAmount <= address(this).balance, "Not enough funds.");
        lockedInJackpot_ += uint128(increaseAmount);
    }

     
    function withdrawFunds(address payable beneficiary, uint withdrawAmount) external onlyOwner {
        require (withdrawAmount <= address(this).balance, "Increase amount larger than balance.");
        require (lockedInJackpot_ + lockedInBets_ + withdrawAmount <= address(this).balance, "Not enough funds.");
        sendFunds(1, beneficiary, withdrawAmount, 0);
    }
    
     
     
    function kill() external onlyOwner {
        require (lockedInBets_ == 0, "All bets should be processed (settled or refunded) before self-destruct.");
        selfdestruct(owner);
    }

     
     
    function () external payable {
    }
    
    function placeBet(uint256 betMask, uint256 modulo, uint256 commitLastBlock, uint256 commit, bytes32 r, bytes32 s) 
        external
        payable 
    {
        Bet storage bet = bets[commit];
        require(bet.gambler == address(0), "already betting same commit number");

        uint256 amount = msg.value;
        require (modulo > 1 && modulo <= MAX_MODULO, "Modulo should be within range.");
        require (amount >= MIN_BET && amount <= MAX_AMOUNT, "Amount should be within range.");
        require (betMask > 0 && betMask < MAX_BET_MASK, "Mask should be within range.");

        require (block.number <= commitLastBlock, "Commit has expired.");

         
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, commit));
        require (secretSigner == ecrecover(prefixedHash, 28, r, s), "ECDSA signature is not valid.");

         
        uint rollUnder;
        
         
         
         
         
         
        if(modulo <= MAX_MASK_MODULO){
            rollUnder = ((betMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
             
        }else{
            require (betMask > 0 && betMask <= modulo, "High modulo range, betMask larger than modulo.");
            rollUnder = betMask;
        }

        uint possibleWinAmount;
        uint jackpotFee;

        (possibleWinAmount, jackpotFee) = getGameWinAmount(amount, modulo, rollUnder);

         
        require (possibleWinAmount <= amount + maxProfit, "maxProfit limit violation.");

         
        lockedInBets_ += uint128(possibleWinAmount);
        lockedInJackpot_ += uint128(jackpotFee);

         
        require (lockedInJackpot_ + lockedInBets_ <= address(this).balance, "Cannot afford to lose this bet.");
        
         
        emit Commit(commit, possibleWinAmount);

        bet.amount = uint128(amount);
        bet.modulo = uint8(modulo);
        bet.rollUnder = uint8(rollUnder);
        bet.placeBlockNumber = uint40(block.number);
        bet.mask = uint40(betMask);
        bet.gambler = msg.sender;
    }
    
     
     
     
     
    function settleBet(uint reveal, bytes32 blockHash) external onlyCroupier {
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        Bet storage bet = bets[commit];
        uint placeBlockNumber = bet.placeBlockNumber;

         
        require (block.number > placeBlockNumber, "settleBet in the same block as placeBet, or before.");
        require (block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");
        require (blockhash(placeBlockNumber) == blockHash, "Does not matched blockHash.");

         
        settleBetCommon(bet, reveal, blockHash);
    }

     
    function settleBetCommon(Bet storage bet, uint reveal, bytes32 entropyBlockHash) private {
         
        uint commit = uint(keccak256(abi.encodePacked(reveal)));
        uint amount = bet.amount;
        uint modulo = bet.modulo;
        uint rollUnder = bet.rollUnder;
        address payable gambler = bet.gambler;

         
        require (amount != 0, "Bet should be in an 'active' state");

         
        bet.amount = 0;
        
         
         
         
         
        bytes32 entropy = keccak256(abi.encodePacked(reveal, entropyBlockHash));

         
        uint game = uint(entropy) % modulo;

        uint gameWinAmount;
        uint _jackpotFee;
        (gameWinAmount, _jackpotFee) = getGameWinAmount(amount, modulo, rollUnder);

        uint gameWin = 0;
        uint jackpotWin = 0;

         
        if (modulo <= MAX_MASK_MODULO) {
             
            if ((2 ** game) & bet.mask != 0) {
                gameWin = gameWinAmount;
            }
        } else {
             
            if (game < rollUnder) {
                gameWin = gameWinAmount;
            }
        }

         
        lockedInBets_ -= uint128(gameWinAmount);

         
        if (amount >= MIN_JACKPOT_BET && lockedInJackpot_ >= minJackpotWinAmount) {
             
             
            uint jackpotRng = (uint(entropy) / modulo) % JACKPOT_MODULO;

             
            if (jackpotRng == 0) {
                jackpotWin = lockedInJackpot_;
                lockedInJackpot_ = 0;
            }
        }

         
        if (jackpotWin > 0) {
            emit JackpotPayment(gambler, jackpotWin);
        }

         
        sendFunds(commit, gambler, gameWin, jackpotWin);
    }

    function getGameWinAmount(uint amount, uint modulo, uint rollUnder) private pure returns (uint winAmount, uint jackpotFee) {
        require (0 < rollUnder && rollUnder <= modulo, "Win probability out of range.");

        jackpotFee = amount >= MIN_JACKPOT_BET ? JACKPOT_FEE : 0;

        uint houseEdge = amount * HOUSE_EDGE_PERCENT / 100;

        if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
            houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
        }

        require (houseEdge + jackpotFee <= amount, "Bet doesn't even cover house edge.");
        winAmount = (amount - houseEdge - jackpotFee) * modulo / rollUnder;
    }
    
     
     
     
     
     
    function refundBet(uint commit) external {
         
        Bet storage bet = bets[commit];
        uint amount = bet.amount;

        require (amount != 0, "Bet should be in an 'active' state");

         
        require (block.number > bet.placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");

         
        bet.amount = 0;
        
        uint gameWinAmount;
        uint jackpotFee;
        (gameWinAmount, jackpotFee) = getGameWinAmount(amount, bet.modulo, bet.rollUnder);

        lockedInBets_ -= uint128(gameWinAmount);
        lockedInJackpot_ -= uint128(jackpotFee);

         
        sendFunds(commit, bet.gambler, amount, 0);
    }

     
    function sendFunds(uint commit, address payable beneficiary, uint gameWin, uint jackpotWin) private {
        uint amount = gameWin + jackpotWin == 0 ? 1 wei : gameWin + jackpotWin;
        uint successLogAmount = gameWin;

        if (beneficiary.send(amount)) {
            emit Payment(commit, beneficiary, successLogAmount, jackpotWin);
        } else {
            emit FailedPayment(commit, beneficiary, amount, 0);
        }
    }
    
}