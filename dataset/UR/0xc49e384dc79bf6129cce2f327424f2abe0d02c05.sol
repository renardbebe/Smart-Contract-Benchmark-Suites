 

 


pragma solidity ^0.4.19;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract Bet4Land is owned {

     
    struct Game {
        uint gameId;             
        bytes8 landKey;          
        uint seedBlock;          
        uint userNum;            
        string content;          
    }

    uint gameNum;
     
    mapping(uint => Game) games;
    mapping(uint => uint) indexMap;

     
    function Bet4Land() public {
        gameNum = 1;
    }

     
    function newGame(uint gameId, bytes8 landKey, uint seedBlock, uint userNum, string content) onlyOwner public returns (uint gameIndex) {
        require(indexMap[gameId] == 0);              
        gameIndex = gameNum++;
        indexMap[gameId] = gameIndex;
        games[gameIndex] = Game(gameId, landKey, seedBlock, userNum, content);
    }

     
    function getGameInfoByIndex(uint gameIndex) onlyOwner public view returns (uint gameId, bytes8 landKey, uint seedBlock, uint userNum, string content) {
        require(gameIndex < gameNum);                
        require(gameIndex >= 1);                     
        gameId = games[gameIndex].gameId;
        landKey = games[gameIndex].landKey;
        seedBlock = games[gameIndex].seedBlock;
        userNum = games[gameIndex].userNum;
        content = games[gameIndex].content;
    }

     
    function getGameInfoById(uint gameId) public view returns (uint gameIndex, bytes8 landKey, uint seedBlock, uint userNum, string content) {
        gameIndex = indexMap[gameId];
        require(gameIndex < gameNum);               
        require(gameIndex >= 1);                    
        landKey = games[gameIndex].landKey;
        seedBlock = games[gameIndex].seedBlock;
        userNum = games[gameIndex].userNum;
        content = games[gameIndex].content;
    }

     
    function getGameNum() onlyOwner public view returns (uint num) {
        num = gameNum - 1;
    }
}