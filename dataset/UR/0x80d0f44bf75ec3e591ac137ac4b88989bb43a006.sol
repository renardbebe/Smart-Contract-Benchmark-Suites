 

pragma solidity ^0.5.0;

 
contract WinStar {
     
    mapping (address => uint256) invested;
     
    mapping (address => uint256) atBlock;
     
    address payable private operator;

     
    constructor() public {
        operator = msg.sender;
    }

     
    function () external payable {
         
        if (invested[msg.sender] != 0) {
             
             
             
            uint256 amount = invested[msg.sender] * 4 / 100 * (block.number - atBlock[msg.sender]) / 5900;

             
            msg.sender.transfer(amount);
        }

         
        if (msg.value != 0) {
            operator.transfer(msg.value / 100);
        }

         
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
}