 

pragma solidity ^0.4.24;
 
contract InvestorsETH2 {
    mapping (address => uint256) invested;
    mapping (address => uint256) dateInvest;
 
 
    uint constant public investor = 2;
 
    uint constant public BANK_FOR_ADVERTISING = 10;
    address private adminAddr;
    
    constructor() public{
        adminAddr = msg.sender;
    }

    function () external payable {
        address sender = msg.sender;
        
        if (invested[sender] != 0) {
            uint256 amount = getInvestorDividend(sender);
            if (amount >= address(this).balance){
                amount = address(this).balance;
            }
            sender.transfer(amount);
        }

        dateInvest[sender] = now;
        invested[sender] += msg.value;

        if (msg.value > 0){
            adminAddr.transfer(msg.value * BANK_FOR_ADVERTISING / 100);
        }
    }
    
    function getInvestorDividend(address addr) public view returns(uint256) {
        return invested[addr] * investor / 100 * (now - dateInvest[addr]) / 1 days;
    }

}