 

 
 
 pragma solidity ^0.4.18;

 

 

 

 

contract IERC20Token {

     
    function name() public constant returns (string _name) { _name; }
    function symbol() public constant returns (string _symbol) { _symbol; }
    function decimals() public constant returns (uint8 _decimals) { _decimals; }
    
    function totalSupply() public constant returns (uint total) {total;}
    function balanceOf(address _owner) public constant returns (uint balance) {_owner; balance;}    
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {_owner; _spender; remaining;}

    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}
 
 

 
contract SafeMath {

     
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {        
        assert(a+b >= a);
        return a+b;
    }

     
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        return a - b;
    }

     
    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }

    function safeDiv(uint256 x, uint256 y) internal pure returns (uint256) {
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

    function ERC20StandardToken() public {
     
    }    

     
     
     

    function totalSupply() public constant returns (uint total) {
        total = tokensIssued;
    }
 
    function balanceOf(address _owner) public constant returns (uint balance) {
        balance = balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

         
        doTransfer(msg.sender, _to, _value);        
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        
         
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);        
         
        doTransfer(_from, _to, _value);        
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        remaining = allowed[_owner][_spender];
    }    

     
     
     
     
    function getRealTokenAmount(uint256 tokens) public constant returns (uint256) {
        return tokens * (uint256(10) ** decimals);
    }

     
     
     
    
    function doTransfer(address _from, address _to, uint256 _value) internal {
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
    }
} 

 
contract ITokenPool {    

     
    ERC20StandardToken public token;

     
    function setTrustee(address trustee, bool state) public;

     
     
    function getTokenAmount() public constant returns (uint256 tokens) {tokens;}
} 
 

 

 

 

 
contract IOwned {
    function owner() public constant returns (address) {}
    function transferOwnership(address _newOwner) public;
} 

contract Owned is IOwned {
    address public owner;        

    function Owned() public {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        require(msg.sender == owner);
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

    function Manageable() public Owned() {
        managers[owner] = true;
    }

     
    modifier managerOnly {
        require(managers[msg.sender]);
        _;
    }

    function transferOwnership(address _newOwner) public ownerOnly {
        super.transferOwnership(_newOwner);

        managers[_newOwner] = true;
        managers[msg.sender] = false;
    }

    function setManager(address manager, bool state) public ownerOnly {
        managers[manager] = state;
        ManagerSet(manager, state);
    }
} 
 





 
contract ReturnableToken is Manageable, ERC20StandardToken {

     
    mapping (address => bool) public returnAgents;

    function ReturnableToken() public {}    
    
     
    function setReturnAgent(ReturnTokenAgent agent) public managerOnly {
        returnAgents[address(agent)] = true;
    }

     
    function removeReturnAgent(ReturnTokenAgent agent) public managerOnly {
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

     
    function returnToken(address from, uint256 amountReturned)  public;

     
    function setReturnableToken(ReturnableToken token) public managerOnly {
        returnableTokens[address(token)] = true;
    }

     
    function removeReturnableToken(ReturnableToken token) public managerOnly {
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

 



 



 
contract ITokenHolder {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
}
 

 
contract TokenHolder is ITokenHolder, Manageable {
    
    function TokenHolder() {
    }

     
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        managerOnly
    {
        assert(_token.transfer(_to, _amount));
    }
}
 

 
contract BCSCrowdsale is ReturnTokenAgent, TokenHolder, ICrowdsaleFormula, SafeMath {

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
    uint256 public totalInvestments;

    bool public failure;  

    mapping (address => uint256) public investedFrom;  
    mapping (address => uint256) public returnedTo;  
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
        totalInvestments = 0;
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
        ++totalInvestments;
        Invested(msg.sender, weiPaid, tokensToBuy);
    }

     
    function returnToken(address from, uint256 amountReturned) public returnableTokenOnly {
        if (msg.sender == address(tokenPool.token()) && getState() == State.FinishedFailure) {
             
            require(tokensSoldTo[from] == amountReturned);

            returnedTo[from] = investedFrom[from];
            investedFrom[from] = 0;
            from.transfer(returnedTo[from]);

            Refund(from, returnedTo[from]);
        }
    }

     
    function canInvest(address investor, uint256 amount) constant returns(bool) {
        return getState() == State.Active &&
                    (address(restrictions) == 0x0 || 
                    restrictions.canInvest(investor, amount, tokensLeft()));
    }

     
    function howManyTokensForEther(uint256 weiAmount) constant returns(uint256 tokens, uint256 excess) {        
        uint256 bpct = getCurrentBonusPct(weiAmount);
        uint256 maxTokens = (tokensLeft() * 100) / (100 + bpct);

        tokens = weiAmount * realAmountForOneEther / 1 ether;
        if (tokens > maxTokens) {
            tokens = maxTokens;
        }

        excess = weiAmount - tokens * 1 ether / realAmountForOneEther;

        tokens = (tokens * 100 + tokens * bpct) / 100;
    }

     
    function getCurrentBonusPct(uint256 investment) constant returns (uint256) {
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
        } else if ((endTime == 0 || now < endTime) && tokensLeft() > 0) {
            return State.Active;
        } else if (weiCollected >= minimumGoalInWei || tokensLeft() <= 0) {
            return State.FinishedSuccess;
        } else {
            return State.FinishedFailure;
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

  
contract BCSAddBonusCrowdsale is BCSCrowdsale {
    
    uint256 public decreaseStepPct;
    uint256 public stepDuration;
    uint256 public maxDecreasePct;
    uint256[] public investSteps;
    uint8[] public bonusPctSteps;
    
    function BCSAddBonusCrowdsale(        
        ITokenPool _tokenPool,
        IInvestRestrictions _restrictions,
        address _beneficiary, 
        uint256 _startTime, 
        uint256 _durationInHours, 
        uint256 _goalInWei,
        uint256 _tokensForOneEther,
        uint256 _bonusPct,
        uint256 _maxDecreasePct,        
        uint256 _decreaseStepPct,
        uint256 _stepDurationDays,
        uint256[] _investSteps,
        uint8[] _bonusPctSteps              
        ) 
        BCSCrowdsale(
            _tokenPool,
            _restrictions,
            _beneficiary, 
            _startTime, 
            _durationInHours, 
            _goalInWei,
            _tokensForOneEther,
            _bonusPct
        )
    {
        require (_bonusPct >= maxDecreasePct);

        investSteps = _investSteps;
        bonusPctSteps = _bonusPctSteps;
        maxDecreasePct = _maxDecreasePct;
        decreaseStepPct = _decreaseStepPct;
        stepDuration = _stepDurationDays * 1 days;
    }

    function getCurrentBonusPct(uint256 investment) public constant returns (uint256) {
        
        uint256 decreasePct = decreaseStepPct * (now - startTime) / stepDuration;
        if (decreasePct > maxDecreasePct) {
            decreasePct = maxDecreasePct;
        }

        uint256 first24hAddition = (now - startTime < 1 days ? 1 : 0);

        for (int256 i = int256(investSteps.length) - 1; i >= 0; --i) {
            if (investment >= investSteps[uint256(i)]) {
                return bonusPct - decreasePct + bonusPctSteps[uint256(i)] + first24hAddition;
            }
        }
                
        return bonusPct - decreasePct + first24hAddition;
    }

}