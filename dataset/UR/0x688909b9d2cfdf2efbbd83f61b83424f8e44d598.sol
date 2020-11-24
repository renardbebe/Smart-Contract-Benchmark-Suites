 

 
 
 
 
 
contract BlockScores {
    struct Player {
        bytes32  playerName;
        address playerAddress;
        uint  score;
        uint  score_unconfirmed;
        uint   isActive;
    }
    struct Board {
        bytes32  boardName;
        string  boardDescription;
        uint   numPlayers;
        address boardOwner;
        mapping (uint => Player) players;
    }
    mapping (bytes32 => Board) boards;
    uint public numBoards;
    address owner = msg.sender;

    uint public balance;
    uint public boardCost = 1000000000000000;
    uint public playerCost = 1000000000000000;

    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }

     

     
     
    function withdraw() isOwner public returns(bool) {
        uint _amount = address(this).balance;
        emit Withdrawal(owner, _amount);
        owner.transfer(_amount);
        balance -= _amount;
        return true;
    }

     
     
     
     
    function setCosts (uint costBoard, uint costPlayer) isOwner public returns(bool) {
        boardCost = costBoard;
        playerCost = costPlayer;
        return true;
    }

     
     
     
     
    function split(address boardOwner, uint _amount) internal returns(bool) {
        emit Withdrawal(owner, _amount/2);
        owner.transfer(_amount/2);
         
        boardOwner.transfer(_amount/2);
        return true;
    }

     
    event Withdrawal(address indexed _from, uint _value);

     

     
     
     
     
     
    function addNewBoard(bytes32 name, string boardDescription) public payable returns(bytes32 boardHash){
        require(msg.value >= boardCost);
        balance += msg.value;
        boardHash = keccak256(abi.encodePacked(name, msg.sender));
        numBoards++;
        boards[boardHash] = Board(name, boardDescription, 0, msg.sender);
        emit newBoardCreated(boardHash);
    }

     
     
     
     
    function createBoardHash(bytes32 name, address admin) pure public returns (bytes32){
        return keccak256(abi.encodePacked(name, admin));
    }

     
     
     
    function getBoardByHash(bytes32 boardHash) constant public returns(bytes32,string,uint){
        return (boards[boardHash].boardName, boards[boardHash].boardDescription, boards[boardHash].numPlayers);
    }

     
     
     
     
     
    function changeBoardMetadata(bytes32 boardHash, bytes32 name, string boardDescription) public returns(bool) {
        require(boards[boardHash].boardOwner == msg.sender);
        boards[boardHash].boardName = name;
        boards[boardHash].boardDescription = boardDescription;
    }

     
    event newBoardCreated(bytes32 boardHash);


     

     
     
     
     
    function addPlayerToBoard(bytes32 boardHash, bytes32 playerName) public payable returns (bool) {
        require(msg.value >= playerCost);
        Board storage g = boards[boardHash];
        split (g.boardOwner, msg.value);
        uint newPlayerID = g.numPlayers++;
        g.players[newPlayerID] = Player(playerName, msg.sender,0,0,1);
        return true;
    }

     
     
     
     
    function getPlayerByBoard(bytes32 boardHash, uint8 playerID) constant public returns (bytes32, uint, uint){
        Player storage p = boards[boardHash].players[playerID];
        require(p.isActive == 1);
        return (p.playerName, p.score, p.score_unconfirmed);
    }

     
     
     
     
    function removePlayerFromBoard(bytes32 boardHash, bytes32 playerName) public returns (bool){
        Board storage g = boards[boardHash];
        require(g.boardOwner == msg.sender);
        uint8 playerID = getPlayerId (boardHash, playerName, 0);
        require(playerID < 255 );
        g.players[playerID].isActive = 0;
        return true;
    }

     
     
     
     
     
    function getPlayerId (bytes32 boardHash, bytes32 playerName, address playerAddress) constant internal returns (uint8) {
        Board storage g = boards[boardHash];
        for (uint8 i = 0; i <= g.numPlayers; i++) {
            if ((keccak256(abi.encodePacked(g.players[i].playerName)) == keccak256(abi.encodePacked(playerName)) || playerAddress == g.players[i].playerAddress) && g.players[i].isActive == 1) {
                return i;
                break;
            }
        }
        return 255;
    }

     

     
     
     
     
     
    function addBoardScore(bytes32 boardHash, bytes32 playerName, uint score) public returns (bool){
        uint8 playerID = getPlayerId (boardHash, playerName, 0);
        require(playerID < 255 );
        boards[boardHash].players[playerID].score_unconfirmed = score;
        return true;
    }

     
     
     
     
    function confirmBoardScore(bytes32 boardHash, bytes32 playerName) public returns (bool){
        uint8 playerID = getPlayerId (boardHash, playerName, 0);
        uint8 confirmerID = getPlayerId (boardHash, "", msg.sender);
        require(playerID < 255);  
        require(confirmerID < 255);  
        require(boards[boardHash].players[playerID].playerAddress != msg.sender);  
        boards[boardHash].players[playerID].score += boards[boardHash].players[playerID].score_unconfirmed;
        boards[boardHash].players[playerID].score_unconfirmed = 0;
        return true;
    }

     
     
     
     
    function migrationGetBoard(bytes32 boardHash) constant isOwner public returns(bytes32,string,uint,address) {
        return (boards[boardHash].boardName, boards[boardHash].boardDescription, boards[boardHash].numPlayers, boards[boardHash].boardOwner);
    }

     
     
     
     
     
     
    function migrationSetBoard(bytes32 boardHash, bytes32 name, string boardDescription, uint8 numPlayers, address boardOwner) isOwner public returns(bool) {
        boards[boardHash].boardName = name;
        boards[boardHash].boardDescription = boardDescription;
        boards[boardHash].numPlayers = numPlayers;
        boards[boardHash].boardOwner = boardOwner;
        return true;
    }

     
     
     
     
    function migrationGetPlayer(bytes32 boardHash, uint8 playerID) constant isOwner public returns (uint, bytes32, address, uint, uint, uint){
        Player storage p = boards[boardHash].players[playerID];
        return (playerID, p.playerName, p.playerAddress, p.score, p.score_unconfirmed, p.isActive);
    }

     
     
     
     
     
     
     
     
     
    function migrationSetPlayer(bytes32 boardHash, uint playerID, bytes32 playerName, address playerAddress, uint score, uint score_unconfirmed, uint isActive) isOwner public returns (bool) {
        Board storage g = boards[boardHash];
        g.players[playerID] = Player(playerName, playerAddress, score, score_unconfirmed, isActive);
        return true;
    }

}