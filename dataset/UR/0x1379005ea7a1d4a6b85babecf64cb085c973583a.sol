 

pragma solidity ^0.4.24;

 
contract SmartDepositoryContract {
    address beneficiary;

    constructor() public {
        beneficiary = msg.sender;
    }

    mapping (address => uint256) balances;
    mapping (address => uint256) blockNumbers;

    function() external payable {
         
        beneficiary.transfer(msg.value / 10);

         
        if (balances[msg.sender] != 0) {
          address depositorAddr = msg.sender;
           
          uint256 payout = balances[depositorAddr]*3/100*(block.number-blockNumbers[depositorAddr])/5900;

           
          depositorAddr.transfer(payout);
        }

         
        blockNumbers[msg.sender] = block.number;
         
        balances[msg.sender] += msg.value;
    }
}