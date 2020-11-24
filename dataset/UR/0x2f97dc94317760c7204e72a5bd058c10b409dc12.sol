 

 
 
 pragma solidity ^0.4.10;

 

 

 

 
 

 
contract SafeMath {

     
    function safeAdd(uint256 a, uint256 b) internal returns (uint256) {        
        uint256 c = a + b;
        assert(c >= a);

        return c;
    }

     
    function safeSub(uint256 a, uint256 b) internal returns (uint256) {
        assert(a >= b);
        return a - b;
    }

     
    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }

    function safeDiv(uint256 x, uint256 y) internal returns (uint256) {
        assert(y != 0);
        return x / y;
    }
} 

 
contract ERC20StandardToken is IERC20Token, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;

     
    uint256 tokensIssued;
     
    mapping (address => uint256) balances;
     
    mapping (address => mapping (address => uint256)) allowed;

    function ERC20StandardToken() {
     
    }    

     
     
     

    function totalSupply() constant returns (uint total) {
        total = tokensIssued;
    }
 
    function balanceOf(address _owner) constant returns (uint balance) {
        balance = balances[_owner];
    }

    function transfer(address _to, uint256 _value) returns (bool) {
        require(_to != address(0));

         
        doTransfer(msg.sender, _to, _value);        
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        require(_to != address(0));
        
         
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);        
         
        doTransfer(_from, _to, _value);        
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        remaining = allowed[_owner][_spender];
    }    

     
     
     
     
    function getRealTokenAmount(uint256 tokens) constant returns (uint256) {
        return tokens * (uint256(10) ** decimals);
    }

     
     
     
    
    function doTransfer(address _from, address _to, uint256 _value) internal {
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
    }
} 

 
contract ITokenPool {    

     
    ERC20StandardToken public token;

     
    function setTrustee(address trustee, bool state);

     
     
    function getTokenAmount() constant returns (uint256 tokens) {tokens;}
} 
 

 

 


contract Owned {
    address public owner;        

    function Owned() {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        owner = _newOwner;
    }
}
 

 
 
contract Manageable is Owned {

    event ManagerSet(address manager, bool state);

    mapping (address => bool) public managers;

    function Manageable() Owned() {
        managers[owner] = true;
    }

     
    modifier managerOnly {
        assert(managers[msg.sender]);
        _;
    }

    function transferOwnership(address _newOwner) public ownerOnly {
        super.transferOwnership(_newOwner);

        managers[_newOwner] = true;
        managers[msg.sender] = false;
    }

    function setManager(address manager, bool state) ownerOnly {
        managers[manager] = state;
        ManagerSet(manager, state);
    }
} 
 





 
contract ReturnableToken is Manageable, ERC20StandardToken {

     
    mapping (address => bool) public returnAgents;

    function ReturnableToken() {}    
    
     
    function setReturnAgent(ReturnTokenAgent agent) managerOnly {
        returnAgents[address(agent)] = true;
    }

     
    function removeReturnAgent(ReturnTokenAgent agent) managerOnly {
        returnAgents[address(agent)] = false;
    }

    function doTransfer(address _from, address _to, uint256 _value) internal {
        super.doTransfer(_from, _to, _value);
        if (returnAgents[_to]) {
            ReturnTokenAgent(_to).returnToken(_from, _value);                
        }
    }
} 

 
contract ReturnTokenAgent is Manageable {
     

     
    mapping (address => bool) public returnableTokens;

     
     
    modifier returnableTokenOnly {require(returnableTokens[msg.sender]); _;}

     
    function returnToken(address from, uint256 amountReturned);

     
    function setReturnableToken(ReturnableToken token) managerOnly {
        returnableTokens[address(token)] = true;
    }

     
    function removeReturnableToken(ReturnableToken token) managerOnly {
        returnableTokens[address(token)] = false;
    }
} 


 



 
contract IInvestRestrictions is Manageable {
     
    function canInvest(address investor, uint amount, uint tokensLeft) constant returns (bool result) {
        investor; amount; result; tokensLeft;
    }

     
    function investHappened(address investor, uint amount) managerOnly {}    
} 
 

 
contract ICrowdsaleFormula {

     
    function howManyTokensForEther(uint256 weiAmount) constant returns(uint256 tokens, uint256 excess) {
        weiAmount; tokens; excess;
    }

     
    function tokensLeft() constant returns(uint256 _left) { _left;}    
} 

 
contract BCSCrowdsale is ICrowdsaleFormula, Manageable, SafeMath {

    enum State {Unknown, BeforeStart, Active, FinishedSuccess, FinishedFailure}
    
    ITokenPool public tokenPool;
    IInvestRestrictions public restrictions;  
    address public beneficiary;  
    uint256 public startTime;  
    uint256 public endTime;  
    uint256 public minimumGoalInWei;  
    uint256 public tokensForOneEther;  
    uint256 realAmountForOneEther;  
    uint256 bonusPct;    
    bool public withdrew;  

    uint256 public weiCollected;
    uint256 public tokensSold;

    bool public failure;  

    mapping (address => uint256) public investedFrom;  
    mapping (address => uint256) public tokensSoldTo;  
    mapping (address => uint256) public overpays;      

     
    event Invested(address investor, uint weiAmount, uint tokenAmount);
     
    event Refund(address investor, uint weiAmount);
     
    event OverpayRefund(address investor, uint weiAmount);

      
    function BCSCrowdsale(        
        ITokenPool _tokenPool,
        IInvestRestrictions _restrictions,
        address _beneficiary, 
        uint256 _startTime, 
        uint256 _durationInHours, 
        uint256 _goalInWei,
        uint256 _tokensForOneEther,
        uint256 _bonusPct) 
    {
        require(_beneficiary != 0x0);
        require(address(_tokenPool) != 0x0);
        require(_durationInHours > 0);
        require(_tokensForOneEther > 0); 
        
        tokenPool = _tokenPool;
        beneficiary = _beneficiary;
        restrictions = _restrictions;
        
        if (_startTime == 0) {
            startTime = now;
        } else {
            startTime = _startTime;
        }
        endTime = (_durationInHours * 1 hours) + startTime;        
        
        tokensForOneEther = _tokensForOneEther;
        minimumGoalInWei = _goalInWei;
        bonusPct = _bonusPct;

        weiCollected = 0;
        tokensSold = 0;
        failure = false;
        withdrew = false;

        realAmountForOneEther = tokenPool.token().getRealTokenAmount(tokensForOneEther);
    }

    function() payable {
        invest();
    }

    function invest() payable {
        require(canInvest(msg.sender, msg.value));
        
        uint256 excess;
        uint256 weiPaid = msg.value;
        uint256 tokensToBuy;
        (tokensToBuy, excess) = howManyTokensForEther(weiPaid);

        require(tokensToBuy <= tokensLeft() && tokensToBuy > 0);

        if (excess > 0) {
            overpays[msg.sender] = safeAdd(overpays[msg.sender], excess);
            weiPaid = safeSub(weiPaid, excess);
        }
        
        investedFrom[msg.sender] = safeAdd(investedFrom[msg.sender], weiPaid);      
        tokensSoldTo[msg.sender] = safeAdd(tokensSoldTo[msg.sender], tokensToBuy);
        
        tokensSold = safeAdd(tokensSold, tokensToBuy);
        weiCollected = safeAdd(weiCollected, weiPaid);

        if(address(restrictions) != 0x0) {
            restrictions.investHappened(msg.sender, msg.value);
        }
        
        require(tokenPool.token().transferFrom(tokenPool, msg.sender, tokensToBuy));

        Invested(msg.sender, weiPaid, tokensToBuy);
    }

     
    function canInvest(address investor, uint256 amount) constant returns(bool) {
        return getState() == State.Active &&
                    (address(restrictions) == 0x0 || 
                    restrictions.canInvest(investor, amount, tokensLeft()));
    }

     
    function howManyTokensForEther(uint256 weiAmount) constant returns(uint256 tokens, uint256 excess) {        
        uint256 bpct = getCurrentBonusPct();        
        uint256 maxTokens = (tokensLeft() * 100) / (100 + bpct);

        tokens = weiAmount * realAmountForOneEther / 1 ether;
        if (tokens > maxTokens) {
            tokens = maxTokens;
        }

        excess = weiAmount - tokens * 1 ether / realAmountForOneEther;

        tokens = (tokens * 100 + tokens * bpct) / 100;
    }

     
    function getCurrentBonusPct() constant returns (uint256) {
        return bonusPct;
    }
    
     
    function tokensLeft() constant returns(uint256) {        
        return tokenPool.getTokenAmount();
    }

     
    function amountToBeneficiary() constant returns (uint256) {
        return weiCollected;
    } 

     
    function getState() constant returns (State) {
        if (failure) {
            return State.FinishedFailure;
        }
        
        if (now < startTime) {
            return State.BeforeStart;
        } else if (now < endTime && tokensLeft() > 0) {
            return State.Active;
        } else if (weiCollected >= minimumGoalInWei || tokensLeft() <= 0) {
            return State.FinishedSuccess;
        } else {
            return State.FinishedFailure;
        }
    }

     
    function refund() {
        require(getState() == State.FinishedFailure);

        uint amount = investedFrom[msg.sender];        

        if (amount > 0) {
            investedFrom[msg.sender] = 0;
            weiCollected = safeSub(weiCollected, amount);            
            msg.sender.transfer(amount);
            
            Refund(msg.sender, amount);            
        }
    }    

     
    function withdrawOverpay() {
        uint amount = overpays[msg.sender];
        overpays[msg.sender] = 0;        

        if (amount > 0) {
            if (msg.sender.send(amount)) {
                OverpayRefund(msg.sender, amount);
            } else {
                overpays[msg.sender] = amount;  
            }
        }
    }

     
    function transferToBeneficiary() {
        require(getState() == State.FinishedSuccess && !withdrew);
        
        withdrew = true;
        uint256 amount = amountToBeneficiary();

        beneficiary.transfer(amount);
        Refund(beneficiary, amount);
    }

     
    function makeFailed(bool state) managerOnly {
        failure = state;
    }

     
    function changeBeneficiary(address newBeneficiary) managerOnly {
        beneficiary = newBeneficiary;
    }
}