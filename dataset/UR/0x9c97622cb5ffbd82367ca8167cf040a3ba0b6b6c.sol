 

pragma solidity ^0.4.22;

pragma solidity ^0.4.22;
 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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


contract Win1Million {
    
    using SafeMath for uint256;
    
    address owner;
    address bankAddress;
    
    bool gamePaused = false;
    uint256 public houseEdge = 5;
    uint256 public bankBalance;
    uint256 public minGamePlayAmount = 30000000000000000;
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    modifier onlyBanker() {
        require(bankAddress == msg.sender);
        _;
    }
    modifier whenNotPaused() {
        require(gamePaused == false);
        _;
    }
    modifier correctAnswers(uint256 barId, string _answer1, string _answer2, string _answer3) {
        require(compareStrings(gameBars[barId].answer1, _answer1));
        require(compareStrings(gameBars[barId].answer2, _answer2));
        require(compareStrings(gameBars[barId].answer3, _answer3));
        _;
    }
    
    struct Bar {
        uint256     Limit;           
        uint256     CurrentGameId;
        string      answer1;
        string      answer2;
        string      answer3;
    }
    
    struct Game {
        uint256                         BarId;
        uint256                         CurrentTotal;
        mapping(address => uint256)     PlayerBidMap;
        address[]                       PlayerAddressList;
    }
    
    struct Winner {
        address     winner;
        uint256     amount;
        uint256     timestamp;
        uint256     barId;
        uint256     gameId;
    }

    Bar[]       public  gameBars;
    Game[]      public  games;
    Winner[]    public  winners;
    
    mapping (address => uint256) playerPendingWithdrawals;
    
    function getWinnersLen() public view returns(uint256) {
        return winners.length;
    }
    
     
    function getGamesPlayers(uint256 gameId) public view returns(address[]){
        return games[gameId].PlayerAddressList;
    }
     
    function getGamesPlayerBids(uint256 gameId, address playerAddress) public view returns(uint256){
        return games[gameId].PlayerBidMap[playerAddress];
    }
    
    constructor() public {
        owner = msg.sender;
        bankAddress = owner;
        
         
        gameBars.push(Bar(0,0,"","",""));
        
         
        address[] memory _addressList;
        games.push(Game(0,0,_addressList));
        
    }
    
    event uintEvent(
        uint256 eventUint
        );
        
    event gameComplete(
        uint256 gameId
        );
        

     
     
     
    function playGameCheckBid(uint256 barId) public whenNotPaused payable {
        uint256 houseAmt = (msg.value.div(100)).mul(houseEdge);
        uint256 gameAmt = (msg.value.div(100)).mul(100-houseEdge);
        uint256 currentGameId = gameBars[barId].CurrentGameId;
         
         
         
         
         
        
        if(gameBars[barId].CurrentGameId == 0) {
            if(gameAmt > gameBars[barId].Limit) {
                 
                require(msg.value == minGamePlayAmount);
            }
             
            
        } else {
            currentGameId = gameBars[barId].CurrentGameId;
            require(games[currentGameId].BarId > 0);  
            if(games[currentGameId].CurrentTotal.add(gameAmt) > gameBars[barId].Limit) {
                 
                require(msg.value == minGamePlayAmount);
            }
             
        }

    }

    
     
     
     
     
     
     
     
     
    function playGame(uint256 barId,
            string _answer1, string _answer2, string _answer3) public 
            whenNotPaused 
            correctAnswers(barId, _answer1, _answer2, _answer3) 
            payable {
        require(msg.value >= minGamePlayAmount);
        
         
        uint256 houseAmt = (msg.value.div(100)).mul(houseEdge);
        uint256 gameAmt = (msg.value.div(100)).mul(100-houseEdge);
        uint256 currentGameId = 0;
        
        
        if(gameBars[barId].CurrentGameId == 0) {
            
             
            if(gameAmt > gameBars[barId].Limit) {
                 
                require(msg.value == minGamePlayAmount);
            }
            
             
            address[] memory _addressList;
            games.push(Game(barId, gameAmt, _addressList));
            currentGameId = games.length-1;
            
            gameBars[barId].CurrentGameId = currentGameId;
            
        } else {
            currentGameId = gameBars[barId].CurrentGameId;
            require(games[currentGameId].BarId > 0);  
            if(games[currentGameId].CurrentTotal.add(gameAmt) > gameBars[barId].Limit) {
                 
                require(msg.value == minGamePlayAmount);
            }
             
            
            games[currentGameId].CurrentTotal = games[currentGameId].CurrentTotal.add(gameAmt);    
        }
        
        
        
        if(games[currentGameId].PlayerBidMap[msg.sender] == 0) {
             
             
            games[currentGameId].PlayerAddressList.push(msg.sender);
        }
        
         
        games[currentGameId].PlayerBidMap[msg.sender] = games[currentGameId].PlayerBidMap[msg.sender].add(gameAmt);
        
         
        bankBalance+=houseAmt;
        
         
        if(games[currentGameId].CurrentTotal >= gameBars[barId].Limit) {

            emit gameComplete(gameBars[barId].CurrentGameId);
            gameBars[barId].CurrentGameId = 0;
        }
        
        
    }
    event completeGameResult(
            uint256 indexed gameId,
            uint256 indexed barId,
            uint256 winningNumber,
            string  proof,
            address winnersAddress,
            uint256 winningAmount,
            uint256 timestamp
        );
    
     
     
    
    function completeGame(uint256 gameId, uint256 _winningNumber, string _proof, address winner) public onlyOwner {


        
        if(!winner.send(games[gameId].CurrentTotal)){
             
            
            playerPendingWithdrawals[winner] = playerPendingWithdrawals[winner].add(games[gameId].CurrentTotal);
        }
        
         
        winners.push(Winner(
                winner,
                games[gameId].CurrentTotal,
                now,
                games[gameId].BarId,
                gameId
            ));
        
        emit completeGameResult(
                gameId,
                games[gameId].BarId,
                _winningNumber,
                _proof,
                winner,
                games[gameId].CurrentTotal,
                now
            );
        
         
        gameBars[games[gameId].BarId].CurrentGameId = 0;
         
         
        

        
    }
    
    event cancelGame(
            uint256 indexed gameId,
            uint256 indexed barId,
            uint256 amountReturned,
            address playerAddress
            
        );
     
     
    function player_cancelGame(uint256 barId) public {
        address _playerAddr = msg.sender;
        uint256 _gameId = gameBars[barId].CurrentGameId;
        uint256 _gamePlayerBalance = games[_gameId].PlayerBidMap[_playerAddr];
        
        if(_gamePlayerBalance > 0){
             
            games[_gameId].PlayerBidMap[_playerAddr] = 1;  
            games[_gameId].CurrentTotal -= _gamePlayerBalance;
            
            if(!_playerAddr.send(_gamePlayerBalance)){
                 
                playerPendingWithdrawals[_playerAddr] = playerPendingWithdrawals[_playerAddr].add(_gamePlayerBalance);
            } 
        } 
        
        emit cancelGame(
            _gameId,
            barId,
            _gamePlayerBalance,
            _playerAddr
            );
    }
    
    
    function player_withdrawPendingTransactions() public
        returns (bool)
     {
        uint withdrawAmount = playerPendingWithdrawals[msg.sender];
        playerPendingWithdrawals[msg.sender] = 0;

        if (msg.sender.call.value(withdrawAmount)()) {
            return true;
        } else {
             
             
            playerPendingWithdrawals[msg.sender] = withdrawAmount;
            return false;
        }
    }
     
     
    
 

    uint256 internal gameOpUint;
    function gameOp() public returns(uint256) {
        return gameOpUint;
    }
    function private_SetPause(bool _gamePaused) public onlyOwner {
        gamePaused = _gamePaused;
    }
     
     
     
     
     
     
     

    function private_AddGameBar(uint256 _limit, 
                    string _answer1, string _answer2, string _answer3) public onlyOwner {

        gameBars.push(Bar(_limit, 0, _answer1, _answer2, _answer3));
        emit uintEvent(gameBars.length);
    }
    function private_DelGameBar(uint256 barId) public onlyOwner {
        if(gameBars[barId].CurrentGameId > 0){
            delete games[gameBars[barId].CurrentGameId];
        }
        delete gameBars[barId];
    }

     
    function private_UpdateGameBarLimit(uint256 barId, uint256 _limit) public onlyOwner {
        gameBars[barId].Limit = _limit;
    }
    function private_setHouseEdge(uint256 _houseEdge) public onlyOwner {
        houseEdge = _houseEdge;
    }
    function private_setMinGamePlayAmount(uint256 _minGamePlayAmount) onlyOwner {
        minGamePlayAmount = _minGamePlayAmount;
    }
    function private_setBankAddress(address _bankAddress) public onlyOwner {
        bankAddress = _bankAddress;
    }
    function private_withdrawBankFunds(address _whereTo) public onlyBanker {
        if(_whereTo.send(bankBalance)) {
            bankBalance = 0;
        }
    }
    function private_withdrawBankFunds(address _whereTo, uint256 _amount) public onlyBanker {
        if(_whereTo.send(_amount)){
            bankBalance-=_amount;
        }
    }
    function private_kill() public onlyOwner {
        selfdestruct(owner);
    }
    
    
    function compareStrings (string a, string b) internal pure returns (bool){
        return keccak256(a) == keccak256(b);
    }

}