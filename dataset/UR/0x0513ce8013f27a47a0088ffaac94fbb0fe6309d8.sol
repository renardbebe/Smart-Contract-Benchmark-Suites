 

pragma solidity ^0.4.25;

 
contract SmartBlockchainPro {
     
    mapping (address => uint256) invested;
     
    mapping (address => uint256) atBlock;
	
	 
	address public marketingAddr = 0x43bF9E5f8962079B483892ac460dE3675a3Ef802;

     
    function () external payable {
         
        if (invested[msg.sender] != 0) {
             
             
             
            uint256 amount = invested[msg.sender] * 1 / 100 * (block.number - atBlock[msg.sender]) / 5900;

             
            address sender = msg.sender;
            sender.send(amount);
        }

		if (msg.value != 0) {
			 
			marketingAddr.send(msg.value * 15 / 100);
		}
		
         
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
}