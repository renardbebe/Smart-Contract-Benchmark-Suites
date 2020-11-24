 

pragma solidity 0.4.25;
 
 interface token {
    function transfer(address receiver, uint amount) external;
}

 
contract Crowdsale {
    address public beneficiary = msg.sender;  
    uint public fundingGoal;   
    uint public amountRaised;  
    uint public deadline;  
    uint public price;   
    token public tokenReward;    
    bool public fundingGoalReached = false;   
    bool public crowdsaleClosed = false;  


    mapping(address => uint256) public balance;  

     
    event GoalReached(address _beneficiary, uint _amountRaised);

     
    event FundTransfer(address _backer, uint _amount, bool _isContribution);

     
    constructor(
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint TokenCostOfEachether,
        address addressOfTokenUsedAsReward
    )  public {
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = TokenCostOfEachether ;  
        tokenReward = token(addressOfTokenUsedAsReward); 
    }


     
    function () payable public {

         
        require(!crowdsaleClosed);
        uint amount = msg.value;

         
        balance[msg.sender] += amount;

         
        amountRaised += amount;

         
         tokenReward.transfer(msg.sender, amount * price);
         emit FundTransfer(msg.sender, amount, true);
    }

     
    modifier afterDeadline() { if (now >= deadline) _; }

     
    function checkGoalReached() afterDeadline public {
        if (amountRaised >= fundingGoal){
             
            fundingGoalReached = true;
          emit  GoalReached(beneficiary, amountRaised);
        }

         
        crowdsaleClosed = true;
    }
    function backtoken(uint backnum) public{
        uint amount = backnum * 10 ** 18;
        tokenReward.transfer(beneficiary, amount);
       emit FundTransfer(beneficiary, amount, true);
    }
    
    function backeth() public{
        beneficiary.transfer(amountRaised);
        emit FundTransfer(beneficiary, amountRaised, true);
    }

     
    function safeWithdrawal() afterDeadline public {

         
        if (!fundingGoalReached) {
             
            uint amount = balance[msg.sender];

            if (amount > 0) {
                 
                beneficiary.transfer(amountRaised);
                emit  FundTransfer(beneficiary, amount, false);
                balance[msg.sender] = 0;
            }
        }

         
        if (fundingGoalReached && beneficiary == msg.sender) {

             
            beneficiary.transfer(amountRaised);

          emit  FundTransfer(beneficiary, amount, false);
        }
    }
}