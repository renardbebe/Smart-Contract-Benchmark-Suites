 

pragma solidity ^0.4.24;
contract Game01 {
     
    address public teamAddress;
     
    address[] public players;
     
    uint public sumOfPlayers;
     
    uint public lowestOffer;
     
    uint public blockNumber;
     
    bytes32 public blcokHash;
     
    uint public numberOfBlcokHash;
     
    uint public winerIndex;
     
    address public winer;
     
    function produceWiner() private {
         
        blcokHash = blockhash(blockNumber);
         
        numberOfBlcokHash = uint(blcokHash);
         
        require(numberOfBlcokHash != 0);
         
        winerIndex = numberOfBlcokHash%sumOfPlayers;
         
        winer = players[winerIndex];
         
        uint tempTeam = (address(this).balance/100)*10;
         
        teamAddress.transfer(tempTeam);
         
        uint tempBonus = address(this).balance - tempTeam;
         
        winer.transfer(tempBonus);
    }
     
    function goWiner() public {
        produceWiner();
    }
     
    function betYours() public payable OnlyBet() {
         
        blcokHash = blockhash(blockNumber);
        numberOfBlcokHash = uint(blcokHash);
        require(numberOfBlcokHash == 0);
         
        sumOfPlayers = players.push(msg.sender);
    }
     
    modifier OnlyBet() {
        require(msg.value >= lowestOffer);
        _;
    }
     
    constructor(uint _blockNumber) public payable {
        teamAddress = msg.sender; 
        sumOfPlayers = 1; 
        players.push(msg.sender); 
        lowestOffer = 10000000000000000; 
        blockNumber = _blockNumber; 
    }
     
    function getTeamAddress() public view returns(address addr) {
        addr = teamAddress;
    }
     
    function getLowPrice() public view returns(uint low) {
        low = lowestOffer;
    }
     
    function getPlayerAddress(uint index) public view returns(address addr) {
        addr = players[index];
    }
     
    function getSumOfPlayers() public view returns(uint sum) {
        sum = sumOfPlayers;
    }
     
    function getBlockNumber() public view returns(uint num) {
        num = blockNumber;
    }
     
    function getBalances() public view returns(uint balace) {
        balace = address(this).balance;
    }
}