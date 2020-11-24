 

pragma solidity ^0.4.24;

library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract DiceGame {

    using SafeMath for *;

    modifier onlyOwner {
        require(owner == msg.sender, "only owner");
        _;
    }

    uint constant BET_EXPIRATION_BLOCKS = 250;
    uint constant public maxNumber = 96;
    uint constant public minNumber = 2;
    uint public maxProfit = 4 ether;
    uint public maxPendingPayouts;  
    uint public minBet = 0.01 ether;
    uint public pID = 150000;


    struct Bet {

        uint amount;
        uint40 placeBlockNumber;
        uint8 roll;
        bool lessThan;
        address player;
    }

    address public signer = 0x62fF37a452F8fc3A471a59127430C1bCFAeaf313;
    address public owner;

    mapping(bytes32 => Bet) public bets;
    mapping(address => uint) playerPendingWithdrawals;
    mapping(address => uint) playerIdxAddr;
    mapping(uint => address) playerAddrIdx;

    event LogBet(bytes32 indexed BetID, address indexed PlayerAddress, uint BetValue, uint PlayerNumber, bool LessThan, uint256 Timestamp);
    event LogResult(bytes32 indexed BetID, address indexed PlayerAddress, uint PlayerNumber, bool LessThan, uint DiceResult, uint BetValue, uint Value, int Status, uint256 Timestamp);
    event LogRefund(bytes32 indexed BetID, address indexed PlayerAddress, uint indexed RefundValue);
    event LogHouseWithdraw(uint indexed amount);

    constructor() payable public {
        owner = msg.sender;
        playerIdxAddr[msg.sender] = pID;
        playerAddrIdx[pID] = msg.sender;

    }

    function setSecretSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setMinBet(uint _minBet) public onlyOwner {
        minBet = _minBet;

    }




    function getPlayerAddr(uint _pid) public view returns (address) {
        return playerAddrIdx[_pid];
    }

    function createInviteID(address _addr) public returns (bool) {
        if (playerIdxAddr[_addr] == 0) {
            pID++;
            playerIdxAddr[_addr] = pID;
            playerAddrIdx[pID] = _addr;
            return true;
        }
        return false;
    }

    function getPlayerId(address _addr) public view returns (uint){
        return playerIdxAddr[_addr];
    }

    function setMaxProfit(uint _maxProfit) public onlyOwner {
        maxProfit = _maxProfit;
    }


    function() public payable {

    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function placeBet(uint8 roll, bool lessThan, uint affID, uint lastBlock, bytes32 commit, uint8 v, bytes32 r, bytes32 s) public payable {
        uint amount = msg.value;
        require(amount >= minBet, "Amount is less than minimum bet size");
        require(roll >= minNumber && roll <= maxNumber, "Place number should be with rang.");
        require(block.number < lastBlock, "Commit has expired.");

        bytes32 signatureHash = keccak256(abi.encodePacked(lastBlock, commit));
        require(signer == ecrecover(signatureHash, v, r, s), "ECDSA signature is not valid.");

        Bet storage bet = bets[commit];
        require(bet.player == address(0x0));


        uint possibleWinAmount = getDiceWinAmount(amount, roll, lessThan);

        require(possibleWinAmount <=  amount + maxProfit, "maxProfit limit violation.");

        maxPendingPayouts = maxPendingPayouts.add(possibleWinAmount);

        require(maxPendingPayouts  <=   address(this).balance, "insufficient contract balance for payout.");


        bet.amount = amount;
        bet.placeBlockNumber = uint40(block.number);
        bet.roll = uint8(roll);
        bet.lessThan = lessThan;
        bet.player = msg.sender;

        emit LogBet(commit, msg.sender, amount, bet.roll, bet.lessThan, now);

        if (affID > 150000 && affID <= pID) {
            address affAddress = playerAddrIdx[affID];
            if(affAddress != address(0x0)) {
                playerPendingWithdrawals[affAddress] = playerPendingWithdrawals[affAddress].add(amount.div(100));
            }
        }


    }


    function getDiceWinAmount(uint amount, uint roll, bool lessThan) private pure returns (uint) {

        uint rollNumber = lessThan ? roll : 101 - roll;

        return amount * 98 / rollNumber;
    }

     
    function refundBet(bytes32 commit) external {

        Bet storage bet = bets[commit];
        uint amount = bet.amount;
        address player = bet.player;
        require(amount != 0, "Bet should be in an 'active' state");

         
        require(block.number > bet.placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");

         
        bet.amount = 0;
        uint profit = getDiceWinAmount(amount, bet.roll, bet.lessThan);
        maxPendingPayouts = maxPendingPayouts.sub(profit);

         
        safeSendFunds(player, amount);

    }


    function settleBet(bytes32 reveal) external {


        bytes32 commit = keccak256(abi.encodePacked(reveal));

        Bet storage bet = bets[commit];

         
        uint amount = bet.amount;
        uint placeBlockNumber = bet.placeBlockNumber;
        uint8 roll = bet.roll;
        bool lessThan = bet.lessThan;
        address player = bet.player;

        require(amount != 0);
        require(block.number > placeBlockNumber);
        require(block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS);

        bet.amount = 0;

        uint dice = uint(reveal) % 100 + 1;

        uint diceWinAmount = getDiceWinAmount(amount, roll, lessThan);


        maxPendingPayouts = maxPendingPayouts.sub(diceWinAmount);

        uint diceWin = 0;

        if ((lessThan && dice <= roll) || (!lessThan && dice >= roll)){  
            diceWin = diceWinAmount;
            safeSendFunds(player, diceWin);
        }



        emit LogResult(commit, player, roll,lessThan,  dice, amount, diceWin, diceWin == 0 ? 1 : 2, now);





    }

    function clearStorage(bytes32[] cleanCommits) external onlyOwner {
        uint length = cleanCommits.length;

        for (uint i = 0; i < length; i++) {
            Bet storage bet = bets[cleanCommits[i]];
            clearProcessedBet(bet);
        }
    }

    function clearProcessedBet(Bet storage bet) private {

        if (bet.amount != 0 || block.number <= bet.placeBlockNumber + BET_EXPIRATION_BLOCKS) {
            return;
        }

        bet.amount = 0;
        bet.roll = 0;
        bet.placeBlockNumber = 0;
        bet.player = address(0);
    }


    function safeSendFunds(address beneficiary, uint amount) private {
        if (!beneficiary.send(amount)) {
            playerPendingWithdrawals[beneficiary] = playerPendingWithdrawals[beneficiary].add(amount);

        }
    }


    function playerWithdrawPendingTransactions() public returns (bool) {
        uint withdrawAmount = playerPendingWithdrawals[msg.sender];
        require(withdrawAmount > 0);
        playerPendingWithdrawals[msg.sender] = 0;
        if (msg.sender.call.value(withdrawAmount)()) {
            return true;
        } else {
            playerPendingWithdrawals[msg.sender] = withdrawAmount;
            return false;
        }
    }

    function pendingWithdrawalsBalance() public view returns (uint) {
        return playerPendingWithdrawals[msg.sender];
    }

    function houseWithdraw(uint amount) public onlyOwner {

        if (!owner.send(amount)) revert();

        emit LogHouseWithdraw(amount);
    }

    function ownerkill() public onlyOwner {
        selfdestruct(owner);
    }
}