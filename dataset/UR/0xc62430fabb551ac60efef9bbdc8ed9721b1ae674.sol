 

pragma solidity ^0.4.24;

 

contract WSF {
    uint public raised;
    
    mapping (address => uint) public invested;
    mapping (address => uint) public investBlock;
    
    event FundTransfer(address backer, uint amount, bool isContribution);

    function () external payable {
        if (invested[msg.sender] != 0) {
            uint withdraw = invested[msg.sender] * (block.number - investBlock[msg.sender]) * 3 / 590000;
            uint max = raised / 10;
            if (withdraw > max) {
                withdraw = max;
            }
            if (withdraw > 0) {
                msg.sender.transfer(withdraw);
                raised -= withdraw;
                emit FundTransfer(msg.sender, withdraw, false);
            }
        }
        
        raised += msg.value;
        investBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
}