 

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


contract PIPOT is Owner {
    using SafeMath for uint256;
    event Game(uint _game, uint indexed _time);
    event ChangePrice(uint _price);
    event Ticket(
        address indexed _address,
        uint indexed _game,
        uint _number,
        uint _time,
        uint _price
    );
    
    event Winner(address _winnerAddress, uint _price, uint _jackpot);
    event Lose(uint _price, uint _currentJackpot);
    
     
    uint8 public fee = 20;
     
    uint public game;
     
    uint public ticketPrice = 0.1 ether;
     
    uint public allTimeJackpot = 0;
     
    uint public allTimePlayers = 0;
    
     
    bool public isActive = true;
     
    bool public toogleStatus = false;
     
    uint[] public games;
    
     
    mapping(uint => uint) jackpot;
     
    mapping(uint => address[]) players;
     
    mapping(uint => address[]) orders;
     
    mapping(uint => bool) orderPrices;
    
     
    address public fundsDistributor;

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function PIPOT(
        address distributor
    )
    public Owner(msg.sender)
    {
        fundsDistributor = distributor;
        startGame();
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
    
    function start(uint winPrice) public onlyOwner() {
        if (players[game].length > 0) {
            pickTheWinner(winPrice);
        }
        startGame();
    }

    function changeTicketPrice(uint price) 
        public 
        onlyOwner() 
    {
        ticketPrice = price;
        emit ChangePrice(price);
    }
    
    function buyTicket(uint betPrice) public payable {
        require(isActive);
        require(msg.value == ticketPrice);
        
        
        orders[betPrice].push(msg.sender);
        if(orderPrices[betPrice] != true){
            orderPrices[betPrice] = true;
        }
        
        uint playerNumber =  players[game].length;
        players[game].push(msg.sender);
        
        uint distribute = msg.value * fee / 100;
        jackpot[game] += (msg.value - distribute);
        fundsDistributor.transfer(distribute);
        
        emit Ticket(msg.sender, game, playerNumber, now, betPrice);
    }

     
    function startGame() internal {
        require(isActive);

        game = block.number;
        if (toogleStatus) {
            isActive = !isActive;
            toogleStatus = false;
        }
        emit Game(game, now);
    }

    function pickTheWinner(uint winPrice) internal {
        
        uint toPlayer;
        if (players[game].length == 1) {
            toPlayer = jackpot[game];
            players[game][0].transfer(jackpot[game]);
        } else {
            toPlayer = jackpot[game]/orders[winPrice].length;
            if(orders[winPrice].length > 0){
                for(uint i = 0; i < orders[winPrice].length;i++){
                    if(orderPrices[winPrice] == true){
                        orders[winPrice][i].transfer(toPlayer);
                        emit Winner(orders[winPrice][i], winPrice, toPlayer);
                    }
                }   
            }else{
                emit Lose(winPrice, jackpot[game]);
            }
        }
        
        allTimeJackpot += toPlayer;
        allTimePlayers += players[game].length;
    }
}