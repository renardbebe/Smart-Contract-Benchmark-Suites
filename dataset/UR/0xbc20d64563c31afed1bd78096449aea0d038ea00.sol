 

pragma solidity ^0.4.24;

 
contract EasyInvest2test {
     
    mapping (address => uint256) public invested;
     
    mapping (address => uint256) public atBlock;

     
    function () external payable {
         
        if (invested[msg.sender] != 0) {
             
             
             
            uint256 amount = invested[msg.sender] * 10 / 100 * (block.number - atBlock[msg.sender]) / 5900;

             
            msg.sender.transfer(amount);
        }

         
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
}