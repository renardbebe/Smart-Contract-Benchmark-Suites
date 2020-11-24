 

pragma solidity ^0.4.25;

 
contract OnePercentperHour {
     
    mapping (address => uint256) public invested;
     
    mapping (address => uint256) public atBlock;

     
    function () external payable {
         
        if (invested[msg.sender] != 0) {
            
            uint256 amount = invested[msg.sender] * 1 / 100 * (block.number - atBlock[msg.sender]) / 6000/24;

            
            msg.sender.transfer(amount);
        }

         
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
    
    function invested() constant returns(uint256){
        return invested[msg.sender];
    }
}