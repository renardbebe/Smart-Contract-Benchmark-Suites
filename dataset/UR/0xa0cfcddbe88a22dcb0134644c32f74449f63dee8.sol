 

pragma solidity ^0.5.8;

contract Ownable {

    address owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

}

contract Moderated is Ownable {

    address moderator;

    constructor () public {
      
        moderator = owner;
    }

    modifier onlyModerator() {
        require(msg.sender == moderator);
        _;
    }
    
     modifier onlyModeratorOrOwner() {
        require(msg.sender == moderator || msg.sender == owner);
        _;
    }

    function setModerator (address newModerator) public onlyOwner {
        
        moderator = newModerator;
        
    }

}

contract LevelappLottery is Moderated {
    struct Draw
    {
        uint timestamp;  
        uint membersCount; 
        string hash;
        uint winner;
    }
        
    mapping (string => Draw) drawsByHash;
    
    
    
    function createDraw (uint membersCount, string memory hash) public onlyModeratorOrOwner {
       
        require(drawsByHash[hash].timestamp == 0);
        uint winner = rand(membersCount, now);
        Draw memory d = Draw ({timestamp : now, membersCount: membersCount, hash : hash, winner: winner });         
        drawsByHash[hash] = d;
    
    }

    function getWinnerNumber(string memory hash) public view returns (uint) {
        
        return drawsByHash[hash].winner;
        
    }
    
    function getTime(string memory hash) public view returns (uint) {
        
        return drawsByHash[hash].timestamp;
        
    }
    function getMembersCount(string memory hash) public view returns (uint) {
        
        return drawsByHash[hash].membersCount;
        
    }
    
     
    function rand(uint max, uint256 seed) private returns (uint256 result){
        
        uint256 factor = seed * 100 / max;
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumber));
        return (uint256((uint256(hashVal) / factor)) % max) + 1;
    }


}