 

 
 
pragma solidity ^0.4.25;
contract NOTBAD_DynamicS {
    mapping (address => uint256) public invested;
    mapping (address => uint256) public atBlock;
    function () external payable
    {
        if (invested[msg.sender] != 0) {
             
            uint256 amount = invested[msg.sender] * ( 2 + ((address(this).balance / 1500) + (invested[msg.sender] / 400))) / 100 * (block.number - atBlock[msg.sender]) / 6000;
            msg.sender.transfer(amount);
        }
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
}