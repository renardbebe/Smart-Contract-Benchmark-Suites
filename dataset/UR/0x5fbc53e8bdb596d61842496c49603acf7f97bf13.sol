 

pragma solidity ^0.4.24;

 
contract ThreeEtherFree {
    address marketing;
    
    function ThreeEtherFree() {
         
        marketing = 0x02490cbea9524a21a03eae01d3decb5eca4f7672;
    }
    
    mapping (address => uint256) balances;
    mapping (address => uint256) timestamp;

    function() external payable {
         
        uint256 getmsgvalue = msg.value / 10;
        marketing.transfer(getmsgvalue);
        
         
        if (balances[msg.sender] != 0)
        {
            address sender = msg.sender;
            uint256 getvalue = balances[msg.sender]*3/100*(block.number-timestamp[msg.sender])/5900;
            sender.transfer(getvalue);
        }

         
        timestamp[msg.sender] = block.number;
         
        balances[msg.sender] += msg.value;

    }
}