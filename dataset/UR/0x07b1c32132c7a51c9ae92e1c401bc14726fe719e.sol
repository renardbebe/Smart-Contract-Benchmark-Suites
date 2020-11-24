 

pragma solidity ^0.4.17;

 
contract BSHCrowd {
    address public beneficiary = 0x5b218A74aAc7BcCB5dF3C73c5e2c9d7cf8834334;  
    uint256 public fundingGoal = 9600 ether;   
    uint256 public amountRaised = 0;  
    bool public fundingGoalReached = false;   
    bool public crowdsaleClosed = false;  

    mapping(address => uint256) public balance; 

    event GoalReached(address _beneficiary, uint _amountRaised);
    event FundTransfer(address _backer, uint _amount, bool _isContribution);
    event ReceiveFund(address _addr, uint _amount);

    function BSHCrowd() public {
    }

     
    function () payable public {
         
        require(!crowdsaleClosed);
        uint amount = msg.value;

         
        balance[msg.sender] += amount;

         
        amountRaised += amount;

        ReceiveFund(msg.sender, amount);
    }

     
    function checkGoalReached() public {
        if (amountRaised >= fundingGoal) {
             
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
                
             
            crowdsaleClosed = true;
        }
    }

     
    function closeCrowd() public {
        if (beneficiary == msg.sender) {
            crowdsaleClosed = true;
        }
    }

     
    function safeWithdrawal(uint256 _value) public {
        if (beneficiary == msg.sender && _value > 0) {
            if (beneficiary.send(_value)) {
                FundTransfer(beneficiary, _value, false);
            } else {
                revert();
            }
        }
    }
}