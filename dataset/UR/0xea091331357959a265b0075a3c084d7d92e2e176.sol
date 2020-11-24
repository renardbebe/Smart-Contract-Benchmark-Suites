 

pragma solidity ^0.4.18;
 
interface token {
    function transfer(address receiver, uint amount);
    function burn(uint256 _value) returns (bool);
    function balanceOf(address _address) returns (uint256);
}
contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract SafeMath {
     

    function safeMul(uint a, uint b) internal returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

}

contract BTCxCrowdsale is owned, SafeMath {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;   
     
    uint public deadline;  
    uint public rate;  
    uint public tokenDecimals;
    token public tokenReward;  
    uint public tokensSold = 0;  
     
    uint public start;  
    mapping(address => uint256) public balanceOf;   
     
    bool crowdsaleClosed = false;  

    event GoalReached(address beneficiary, uint capital);
    event FundTransfer(address backer, uint amount, bool isContribution);

     
    function BTCxCrowdsale( ) {
        beneficiary = 0x781AC8C2D6dc017c4259A1f06123659A4f6dFeD8;
        rate = 2; 
        tokenDecimals=8;
        fundingGoal = 14700000 * (10 ** tokenDecimals); 
        start = 1512831600;  
        deadline =1515628740;  
        tokenReward = token(0x5A82De3515fC4A4Db9BA9E869F269A1e85300092);  
    }    

     
      
    function () payable {
        uint amount = msg.value;   
        uint numTokens;  
        numTokens = getNumTokens(amount);    
        require(numTokens>0 && !crowdsaleClosed && now > start && now < deadline);
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], amount);
        amountRaised = safeAdd(amountRaised, amount);  
        tokensSold += numTokens;  
        tokenReward.transfer(msg.sender, numTokens);  
        beneficiary.transfer(amount);                
        FundTransfer(msg.sender, amount, true);
    }
     
    function getNumTokens(uint _value) internal returns(uint numTokens) {
        numTokens = safeMul(_value,rate)/(10 ** tokenDecimals);  
        return numTokens;
    }

    modifier afterDeadline() { if (now >= deadline) _; }

     
    function checkGoalReached() afterDeadline {
        require(msg.sender == owner);  
        if (tokensSold >=fundingGoal){
            GoalReached(beneficiary, amountRaised);
        }
        tokenReward.burn(tokenReward.balanceOf(this));  
        crowdsaleClosed = true;  
    }



}