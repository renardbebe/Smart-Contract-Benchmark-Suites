 

pragma solidity ^0.4.24;

 
contract WhoWins {
     
    mapping (address => uint256) public balance;
     
    mapping (address => uint256) public atBlock;

     
    address public house;
    constructor() public {
        house = msg.sender;
    }

     
    function () external payable {
         
        if (balance[msg.sender] != 0) {
             
             
            uint256 profit = balance[msg.sender] * 5 / 100 * (block.number - atBlock[msg.sender]) / 5900;

             
            uint8 toss = uint8(keccak256(abi.encodePacked(blockhash(block.timestamp), block.difficulty, block.coinbase))) % 2;
            if (toss == 0) {
                 
                uint256 winning = profit * 2;

                 
                msg.sender.transfer(profit * 2);

                 
                house.transfer(winning * 5 / 100);
            }
        }

         
        balance[msg.sender] += msg.value;
        atBlock[msg.sender] = block.number;
    }
}