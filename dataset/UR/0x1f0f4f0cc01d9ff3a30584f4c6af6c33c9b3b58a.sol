 

pragma solidity ^0.5.0;

 
 
 
 
 
 
 
 
contract BetQueue {
     
     
     
     
    struct Bet {
        address payable player;
        uint amount;
    }
     
     
     
    mapping(uint256 => Bet) private queue;
     
    uint256 private first = 1;
     
    uint256 private last = 0;
     
     
    address owner;
     
     
    constructor() public
    {
        owner = msg.sender;
    }
     
     
     
     
     
    function enqueue(address payable player, uint amount) public {
        require(msg.sender == owner, 'Access Denied');
        last += 1;
        queue[last] = Bet(player,amount);
    }
     
     
     
     
     
     
    function dequeue() public returns (address payable player, uint amount) {
        require(msg.sender == owner, 'Access Denied');
        require(!isEmpty(),'Queue is empty');
        (player,amount) = (queue[first].player,queue[first].amount);
        delete queue[first];
        first += 1;
        if(last < first) {
            first = 1;
            last = 0;
        }
    }
     
     
     
    function count() public view returns (uint total) {
        require(msg.sender == owner, 'Access Denied');
        return last - first + 1;
    }
     
     
     
     
     
     
    function totalAmount() public view returns (uint total)
    {
        require(msg.sender == owner, 'Access Denied');
        total = 0;
        for(uint i = first; i <= last; i ++ ) {
            total = total + queue[i].amount;
        }
    }
     
     
     
     
     
    function isEmpty() public view returns (bool) {
        require(msg.sender == owner, 'Access Denied');
        return last < first;
    }
}


 
 
 
 
 
 
 
contract RockPaperScissors
{
     
     
    enum Move
    {
        None,
        Rock,
        Paper,
        Scissors
    }
     
     
     
     
     
     
    event WinnerPayout(address winner, Move move, address loser, uint payout);
     
     
     
     
     
     
     
     
    event WinnerForefit(address winner, Move move, address loser, uint payout);
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    event OpeningMove(Move move, bool maxReached);
     
     
     
     
     
     
     
    event RefundFailure(address player, uint bet);
     
     
     
     
     
    event GameClosed();
     
     
    address payable private owner;
     
     
    BetQueue private openingMovers;
     
     
    uint public minimumBet;
     
     
     
    Move public openingMove;
     
     
     
    bool public open;
     
     
     
     
    uint private maxQueueCount;
     
     
     
    constructor(uint minBet) public
    {
        require(minBet>0,'Minimum Bet must be greater than zero.');
        owner = msg.sender;
        openingMove = Move.None;
        openingMovers = new BetQueue();
        minimumBet = minBet;
        open = true;
        maxQueueCount = 20;
    }
     
     
     
    function() external payable { }
     
     
     
     
     
     
     
     
     
     
     
     
    function play(Move move) public payable returns (bool isWinner)
    {
        require(open, 'Game is finished.');
        require(msg.value >= minimumBet,'Bet is too low.');
        require(move == Move.Rock || move == Move.Paper || move == Move.Scissors,'Move is invalid.');
        isWinner = false;
        if(openingMove == Move.None)
        {
            openingMove = move;
            openingMovers.enqueue(msg.sender,msg.value);
            emit OpeningMove(openingMove, false);
        }
        else if(move == openingMove)
        {
            require(openingMovers.count() < maxQueueCount, "Too Many Bets of the same type.");
            openingMovers.enqueue(msg.sender,msg.value);
            emit OpeningMove(openingMove, openingMovers.count() >= maxQueueCount);
        }
        else
        {
            (address payable otherPlayer, uint otherBet) = openingMovers.dequeue();
            Move otherMove = openingMove;
            if(openingMovers.isEmpty()) {
                openingMove = Move.None;
            }
            uint payout = (address(this).balance - msg.value - otherBet - openingMovers.totalAmount())/2;
            if((move == Move.Rock && otherMove == Move.Scissors) || (move == Move.Paper && otherMove == Move.Rock) || (move == Move.Scissors && otherMove == Move.Paper))
            {
                isWinner = true;
                payout = payout + msg.value + otherBet / 2;
                emit WinnerPayout(msg.sender, move, otherPlayer, payout);
                 
                msg.sender.transfer(payout);
            }
            else
            {
                payout = payout + msg.value/2 + otherBet;
                if(otherPlayer.send(payout)) {
                    emit WinnerPayout(otherPlayer, otherMove, msg.sender, payout);
                } else {
                     
                     
                     
                     
                    emit WinnerForefit(otherPlayer, otherMove, msg.sender, payout);
                }
            }
        }
    }
     
     
     
     
     
     
     
    function setMaxQueueSize(uint maxSize) external {
        require(owner == msg.sender, 'Access Denied');
        require(maxSize > 0, 'Size must be greater than zero.');
        maxQueueCount = maxSize;
    }
     
     
     
     
     
     
    function end() external
    {
        require(owner == msg.sender, 'Access Denied');
        require(open, 'Game is already finished.');
        open = false;
        openingMove = Move.None;
        while(!openingMovers.isEmpty())
        {
            (address payable player, uint bet) = openingMovers.dequeue();
            if(!player.send(bet))
            {
                emit RefundFailure(player,bet);
            }
        }
        emit GameClosed();
    }
     
     
     
     
     
     
    function withdraw() external
    {
        require(owner == msg.sender, 'Access Denied');
        require(!open, 'Game is still running.');
        uint balance = address(this).balance;
        if(balance > 0) {
            owner.transfer(balance);
        }
    }
}