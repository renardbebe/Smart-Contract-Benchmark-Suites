 

 
 
pragma solidity ^0.4.19;

contract token {
    function transferFrom(address sender, address receiver, uint amount) returns(bool success) {}
    function burn() {}
}

library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract LympoICO {
    using SafeMath for uint;

     
     
    uint constant public pre_maxGoal = 265000000e18;  
     
    uint[2] public pre_prices = [60000, 50000];
    uint[1] public pre_amount_stages = [90000000e18];  
     
    uint constant public pre_start = 1516618800;  
     
    uint constant public pre_end = 1517655600;  
     
    uint public pre_tokensSold = 0;

     
     
    uint constant public maxGoal = 385000000e18;  
     
    uint[1] public prices = [40000];
     
    uint constant public start = 1518865200;  
     
    uint constant public end = 1519815600;  
     
    uint public tokensSold = 0;

     
    uint constant public fundingGoal = 150000000e18;  
     
    uint public amountRaised;
     
    mapping(address => uint) public balances;
     
    bool public crowdsaleEnded = false;
     
    address public tokenOwner;
     
    token public tokenReward;
     
    address wallet;
     
    event GoalReached(address _tokenOwner, uint _amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution, uint _amountRaised);

     
    function LympoICO(address tokenAddr, address walletAddr, address tokenOwnerAddr) {
        tokenReward = token(tokenAddr);
        wallet = walletAddr;
        tokenOwner = tokenOwnerAddr;
    }
    
     
    function() payable {
        if (msg.sender != wallet)  
            exchange(msg.sender);
    }
    
     
     
     
    function exchange(address receiver) payable {
        uint amount = msg.value;
        uint price = getPrice();
        uint numTokens = amount.mul(price);

        bool isPreICO = (now >= pre_start && now <= pre_end);
        bool isICO = (now >= start && now <= end);

        require(isPreICO || isICO);
        require(numTokens > 0);
        if (isPreICO)
        {
            require(!crowdsaleEnded && pre_tokensSold.add(numTokens) <= pre_maxGoal);
            if (pre_tokensSold < pre_amount_stages[0])
                require(numTokens <= 6000000e18);  
            else
                require(numTokens <= 12500000e18);  
        }
        if (isICO)
        {
            require(!crowdsaleEnded && tokensSold.add(numTokens) <= maxGoal);
        }

        wallet.transfer(amount);
        balances[receiver] = balances[receiver].add(amount);
        
         
        amountRaised = amountRaised.add(amount);

        if (isPreICO)
            pre_tokensSold = pre_tokensSold.add(numTokens);
        if (isICO)
            tokensSold = tokensSold.add(numTokens);

        assert(tokenReward.transferFrom(tokenOwner, receiver, numTokens));
        FundTransfer(receiver, amount, true, amountRaised);
    }

     
    function getPrice() constant returns (uint price) {
         
        if (now >= pre_start && now <= pre_end)
        {
            for(uint i = 0; i < pre_amount_stages.length; i++) {
                if(pre_tokensSold < pre_amount_stages[i])
                    return pre_prices[i];
            }
            return pre_prices[pre_prices.length-1];
        }
         
        return prices[prices.length-1];
    }

    modifier afterDeadline() { if (now >= end) _; }

     
    function checkGoalReached() afterDeadline {
        if (pre_tokensSold.add(tokensSold) >= fundingGoal){
            tokenReward.burn();  
            GoalReached(tokenOwner, amountRaised);
        }
        crowdsaleEnded = true;
    }

     
     
    function safeWithdrawal() afterDeadline {
        uint amount = balances[msg.sender];
        if (address(this).balance >= amount) {
            balances[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                FundTransfer(msg.sender, amount, false, amountRaised);
            }
        }
    }
}