 

contract Owner {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Owner(address _owner) public {
        owner = _owner;
    }

    function changeOwner(address _newOwnerAddr) public onlyOwner {
        require(_newOwnerAddr != address(0));
        owner = _newOwnerAddr;
    }
}

contract XPOT is Owner {
    
    event Game(uint _game, uint indexed _time);

    event Ticket(
        address indexed _address,
        uint indexed _game,
        uint _number,
        uint _time
    );
    
     
    uint8 public fee = 10;
     
    uint public game;
     
    uint public ticketPrice = 0.01 ether;
     
    uint public newPrice;
     
    uint public allTimeJackpot = 0;
     
    uint public allTimePlayers = 0;
    
     
    bool public isActive = true;
     
    bool public toogleStatus = false;
     
    uint[] public games;
    
     
    mapping(uint => uint) jackpot;
     
    mapping(uint => address[]) players;
    
     
    address public fundsDistributor;

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function XPOT(
        address distributor
    ) 
     public Owner(msg.sender)
    {
        fundsDistributor = distributor;
        startGame();
    }

    function() public payable {
        buyTicket(address(0));
    }

    function getPlayedGamePlayers() 
        public
        view
        returns (uint)
    {
        return getPlayersInGame(game);
    }

    function getPlayersInGame(uint playedGame) 
        public 
        view
        returns (uint)
    {
        return players[playedGame].length;
    }

    function getPlayedGameJackpot() 
        public 
        view
        returns (uint) 
    {
        return getGameJackpot(game);
    }
    
    function getGameJackpot(uint playedGame) 
        public 
        view 
        returns(uint)
    {
        return jackpot[playedGame];
    }
    
    function toogleActive() public onlyOwner() {
        if (!isActive) {
            isActive = true;
        } else {
            toogleStatus = !toogleStatus;
        }
    }
    
    function start() public onlyOwner() {
        if (players[game].length > 0) {
            pickTheWinner();
        }
        startGame();
    }

    function changeTicketPrice(uint price) 
        public 
        onlyOwner() 
    {
        newPrice = price;
    }


     
    function randomNumber(
        uint min,
        uint max,
        uint time,
        uint difficulty,
        uint number,
        bytes32 bHash
    ) 
        public 
        pure 
        returns (uint) 
    {
        min ++;
        max ++;

        uint random = uint(keccak256(
            time * 
            difficulty * 
            number *
            uint(bHash)
        ))%10 + 1;
       
        uint result = uint(keccak256(random))%(min+max)-min;
        
        if (result > max) {
            result = max;
        }
        
        if (result < min) {
            result = min;
        }
        
        result--;

        return result;
    }
    
     
    function buyTicket(address partner) public payable {
        require(isActive);
        require(msg.value == ticketPrice);
        
        jackpot[game] += msg.value;
        
        uint playerNumber =  players[game].length;
        players[game].push(msg.sender);

        emit Ticket(msg.sender, game, playerNumber, now);
    }

     
    function startGame() internal {
        require(isActive);

        game = block.number;
        if (newPrice != 0) {
            ticketPrice = newPrice;
            newPrice = 0;
        }
        if (toogleStatus) {
            isActive = !isActive;
            toogleStatus = false;
        }
        emit Game(game, now);
    }

     
    function pickTheWinner() internal {
        uint winner;
        uint toPlayer;
        if (players[game].length == 1) {
            toPlayer = jackpot[game];
            players[game][0].transfer(jackpot[game]);
            winner = 0;
        } else {
            winner = randomNumber(
                0,
                players[game].length - 1,
                block.timestamp,
                block.difficulty,
                block.number,
                blockhash(block.number - 1)
            );
        
            uint distribute = jackpot[game] * fee / 100;
            toPlayer = jackpot[game] - distribute;
            players[game][winner].transfer(toPlayer);
            fundsDistributor.transfer(distribute);
        }
        
        allTimeJackpot += toPlayer;
        allTimePlayers += players[game].length;
    }
}