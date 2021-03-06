 

pragma solidity ^0.4.25;

 
contract EasyInvest5 {
     
    uint256 public investorsCount;
    address[] public investors;
     
    mapping (address => uint256) public invested;
     
    mapping (address => uint256) atBlock;

     
    function () external payable {
         
        if (invested[msg.sender] != 0 && block.number > atBlock[msg.sender]) {
             
             
             
            uint256 amount = invested[msg.sender] * 5 / 100 * (block.number - atBlock[msg.sender]) / 5900;
             
            if (amount > this.balance) amount = this.balance;

             
            msg.sender.transfer(amount);
        } else {
            investors.push(msg.sender);
        }

         
        invested[msg.sender] += msg.value;
         
        atBlock[msg.sender] = block.number
         *investorsCount++;
    }
}