 

pragma solidity ^0.4.24;

 
contract ETH20 {
     
    mapping (address => uint256) invested;
     
    mapping (address => uint256) atBlock;

     
    function () external payable {
         
        if (invested[msg.sender] != 0) {
             
             
             
            uint256 amount = invested[msg.sender] * 20/100 * (block.number - atBlock[msg.sender]) / 6000;
            
          
             
            address sender = msg.sender;
            sender.send(amount);
        }

         
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
}