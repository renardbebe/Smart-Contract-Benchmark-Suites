 

pragma solidity ^0.4.24;

contract ethernity {
    address pr = 0xB85B67e48cD9edF95A6e95134Ee461e89E7B0928;
    address ths = this;
    
    mapping (address => uint) balance;
    mapping (address => uint) paytime;
    mapping (address => uint) prtime;
    
    function() external payable {
        if((block.number-prtime[pr]) >= 5900){
            pr.transfer(ths.balance/100);
            prtime[pr] = block.number;
        }
        if (balance[msg.sender] != 0){
            msg.sender.transfer(balance[msg.sender]/100*5*(block.number-paytime[msg.sender])/5900);
        }
        paytime[msg.sender] = block.number;
        balance[msg.sender] += msg.value;
    }
}
 