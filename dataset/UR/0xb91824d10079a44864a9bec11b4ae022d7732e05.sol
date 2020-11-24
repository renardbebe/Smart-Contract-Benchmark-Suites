 

pragma solidity ^0.4.8;

 
 contract token {
     string public name = "cao token";  
     string public symbol = "CAO";  
     uint8 public decimals = 18;   
     uint256 public totalSupply;  

     
     mapping (address => uint256) public balanceOf;

     event Transfer(address indexed from, address indexed to, uint256 value);   

      

     function token(address _owned, string tokenName, string tokenSymbol) public {
          
         balanceOf[_owned] = totalSupply;
         name = tokenName;
         symbol = tokenSymbol;
     }

      
     function transfer(address _to, uint256 _value) public{
        
       balanceOf[msg.sender] -= _value;

        
       balanceOf[_to] += _value;

        
       Transfer(msg.sender, _to, _value);
     }

      
     function issue(address _to, uint256 _amount) public{
         totalSupply = totalSupply + _amount;
         balanceOf[_to] += _amount;

          
         Transfer(this, _to, _amount);
     }
  }

 
contract CAOsale is token {
    address public beneficiary = msg.sender;  
    uint public fundingGoal;   
    uint public amountRaised;  
    uint public deadline;  
    uint public price;   
    bool public fundingGoalReached = false;   
    bool public crowdsaleClosed = false;  


    mapping(address => uint256) public balance;  

     
    event GoalReached(address _beneficiary, uint _amountRaised);

     
    event FundTransfer(address _backer, uint _amount, bool _isContribution);

     

     
     
     
    function CAOsale(
        uint fundingGoalInEthers,
        uint durationInMinutes,
        string tokenName,
        string tokenSymbol
    ) public token(this, tokenName, tokenSymbol){
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = 0.00001 ether;  
    }

     
     

     
    function () payable public{
         
         
        require(!crowdsaleClosed);
         
        uint amount = msg.value;

         
        balance[msg.sender] += amount;

         
        amountRaised += amount;

         
        issue(msg.sender, amount / price * 10 ** uint256(decimals));
        FundTransfer(msg.sender, amount, true);
    }

     
    modifier afterDeadline() {
         
        if (now >= deadline) _;
        }

     
    function checkGoalReached() afterDeadline public{
        if (amountRaised >= fundingGoal){
             
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
         
        crowdsaleClosed = true;
    }

     
    function safeWithdrawal() afterDeadline public{

         
        if (!fundingGoalReached) {
             
            uint amount = balance[msg.sender];

            if (amount > 0) {
                 
                 
                 
                msg.sender.transfer(amount);
                FundTransfer(msg.sender, amount, false);
                balance[msg.sender] = 0;
            }
        }

         
        if (fundingGoalReached && beneficiary == msg.sender) {

             
            beneficiary.transfer(amountRaised);

            FundTransfer(beneficiary, amount, false);
        }
    }
}