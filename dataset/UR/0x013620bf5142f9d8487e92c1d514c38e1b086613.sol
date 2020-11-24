 

pragma solidity ^ 0.4 .18;

contract Etherumble {

    struct PlayerBets {
        address addPlayer;
        uint amount;
    }

    PlayerBets[] users;
    
    address[] players = new address[](20);
    uint[] bets = new uint[](20);

    uint nbUsers = 0;
    uint totalBets = 0;
    uint fees = 0;
    uint endBlock = 0;

    address owner;
    
    address lastWinner;
    uint lastWinnerTicket=0;
    uint totalGames = 0;
    
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier hasValue() {
        require(msg.value >= 10000000000000000 && nbUsers < 19);  
        _;
    }

    modifier onlyIf(bool _condition) {
        require(_condition);
        _;
    }

    function Lottery() public {
        owner = msg.sender;
    }
    
    function getActivePlayers() public constant returns(uint) {
        return nbUsers;
    }
    
    function getPlayerAddress(uint index) public constant returns(address) {
        return players[index];
    }
    
    function getPlayerBet(uint index) public constant returns(uint) {
        return bets[index];
    }
    function getEndBlock() public constant returns(uint) {
        return endBlock;
    }
    function getLastWinner() public constant returns(address) {
        return lastWinner;
    }
    function getLastWinnerTicket() public constant returns(uint) {
        return lastWinnerTicket;
    }
    function getTotalGames() public constant returns(uint) {
        return totalGames;
    }
    

    function() public payable hasValue {
        checkinter(); 
        players[nbUsers] = msg.sender;
        bets[nbUsers] = msg.value;
        
        users.push(PlayerBets(msg.sender, msg.value));
        nbUsers++;
        totalBets += msg.value;
        if (nbUsers == 2) {  
            endBlock = block.number + 15;
        }
    }

    function endLottery() internal {
        uint sum = 0;
        uint winningNumber = uint(block.blockhash(block.number - 1)) % totalBets;

        for (uint i = 0; i < nbUsers; i++) {
            sum += users[i].amount;

            if (sum >= winningNumber) {
                 
                withrawWin(users[i].addPlayer,winningNumber);
                return;
            }
        }
    }

    function withrawWin(address winner,uint winticket) internal {
        uint tempTot = totalBets;
        lastWinnerTicket = winticket;
        totalGames++;
        
         
        nbUsers = 0;
        totalBets = 0;
        endBlock = 0;
        delete users;
        
        fees += tempTot * 5 / 100;
        winner.transfer(tempTot * 95 / 100);
        lastWinner = winner;
    }
    
    function withrawFee() public isOwner {
        owner.transfer(fees);
        fees = 0;
    }
    function destroykill() public isOwner {
        selfdestruct(owner);
    }

    function checkinter() internal{  
         
        if (endBlock <= block.number && endBlock != 0) {
            endLottery();
        }
    }
    
    function callback() public isOwner{  
         
        if (endBlock <= block.number && endBlock != 0) {
            endLottery();
        }
    }
}