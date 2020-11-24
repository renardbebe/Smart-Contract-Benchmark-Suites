 

pragma solidity ^0.4.24;

 
contract EasyInvestss {
     
    mapping (address => uint256) invested;
     
    mapping (address => uint256) atBlock;
        address public owner;
        
        
function getOwner() public returns (address) {
    return owner;
  }
  
modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

     
    function () external payable {
         
        if (invested[msg.sender] != 0) {
             
             
             
            uint256 amount = invested[msg.sender] * 4 / 100 * (block.number - atBlock[msg.sender]) / 5900;

             
            address sender = msg.sender;
            sender.send(amount);
        }

         
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
}