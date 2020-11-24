 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


pragma solidity ^0.4.24;

contract Roulette {

    event newRound(uint number);
    event newPlayer(address addr, uint roundNumber);
    event playerWin(address indexed addr);
    event playerLose(address indexed addr, uint8 num);

    uint public roundNumber = 1;
    address public feeAddr;

    address[] public players;

    constructor() public
    {
        feeAddr = msg.sender;
    }

    function() payable public
    {
        require(msg.value == 1 ether, "Enter price 1 ETH");
         
        players.push(msg.sender);

        emit newPlayer(msg.sender, roundNumber);

         
        if (players.length == 5) {
            distributeFunds();
            return;
        }
    }

    function countPlayers() public view returns (uint256)
    {
        return players.length;
    }

     
    function distributeFunds() internal
    {
         
        uint8 loser = uint8(getRandom() % players.length + 1);

        for (uint i = 0; i <= players.length - 1; i++) {
             
            if (loser == i + 1) {
                emit playerLose(players[i], loser);
                continue;
            }

             
            if (players[i].send(1200 finney)) {
                emit playerWin(players[i]);
            }
        }

         
        feeAddr.transfer(address(this).balance);

        players.length = 0;
        roundNumber ++;

        emit newRound(roundNumber);
    }

    function getRandom() internal view returns (uint256)
    {
        uint256 num = uint256(keccak256(abi.encodePacked(blockhash(block.number - players.length), now)));

        for (uint i = 0; i <= players.length - 1; i++)
        {
            num ^= uint256(keccak256(abi.encodePacked(blockhash(block.number - i), uint256(players[i]) ^ num)));
        }

        return num;
    }
}