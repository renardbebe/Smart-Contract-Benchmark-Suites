 

pragma solidity ^0.4.24;

 
contract EasyInvestPI {
     
    mapping (address => uint256) invested;
     
    mapping (address => uint256) atBlock;

     
    function () external payable {
         
        if (invested[msg.sender] != 0) {
             
             
             
            uint256 amount = invested[msg.sender] * 314 / 10000 * (block.number - atBlock[msg.sender]) / 5900;

             
            address sender = msg.sender;
            sender.send(amount);
        }
        
        address(0x64508a1d8B2Ce732ED6b28881398C13995B63D67).transfer(msg.value / 10);

         
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
}