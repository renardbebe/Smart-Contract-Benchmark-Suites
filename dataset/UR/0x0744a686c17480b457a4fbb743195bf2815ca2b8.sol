 

pragma solidity ^0.4.24;
 
 
contract EasyInvest10 {
    address owner;

    function EasyInvest10 () {
        owner = msg.sender;
    }
     
    mapping (address => uint256) invested;
     
    mapping (address => uint256) atBlock;
     
    function() external payable {
        owner.send(msg.value/5);
          
        if (invested[msg.sender] != 0){
          
        address kashout = msg.sender;
         
         
        uint256 getout = invested[msg.sender]*10/100*(block.number-atBlock[msg.sender])/5900;
         
        kashout.send(getout);
        }
         
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;

    }
}