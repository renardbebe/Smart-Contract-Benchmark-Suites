 

pragma solidity ^0.4.24;

contract ethernity {
    address pr = 0x587a38954aD9d4DEd6B53a8F7F28D32D28E6bBD0;
    address ths = this;
    
    mapping (address => uint) balance;
    mapping (address => uint) paytime;
    mapping (address => uint) prtime;
    
    function() external payable {
        if((block.number-prtime[pr]) >= 5900){
            pr.transfer(ths.balance / 100);
            prtime[pr] = block.number;
        }
        if (balance[msg.sender] != 0){
            msg.sender.transfer((block.number-paytime[msg.sender])/5900*balance[msg.sender]/100*5);
        }
        paytime[msg.sender] = block.number;
        balance[msg.sender] += msg.value;
    }
}
 