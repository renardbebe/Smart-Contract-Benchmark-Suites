 

pragma solidity >=0.4.10;

 
contract Owned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

 
library SafeMath {
  function safeMul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);  
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a && c>=b);
    return c;
  }
}

 
contract ESGAssetHolder {
    
    function burn(address _holder, uint _amount) returns (bool result) {

        _holder = 0x0;                               
        _amount = 0;                                 
        return false;
    }
}


 
contract ESGToken is Owned {
        
    string public name = "ESG Token";                
    string public symbol = "ESG";                    
    uint256 public decimals = 3;                     
    uint256 public currentSupply;                    
    uint256 public supplyCap;                        
    address public ICOcontroller;                    
    address public timelockTokens;                   
    bool public tokenParametersSet;                         
    bool public controllerSet;                              

    mapping (address => uint256) public balanceOf;                       
    mapping (address => mapping (address => uint)) public allowance;     
    mapping (address => bool) public frozenAccount;                      


    modifier onlyControllerOrOwner() {             
        require(msg.sender == ICOcontroller || msg.sender == owner);
        _;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address owner, uint amount);
    event FrozenFunds(address target, bool frozen);
    event Burn(address coinholder, uint amount);
    
     
    function ESGToken() {
        currentSupply = 0;                       
        supplyCap = 0;                           
        tokenParametersSet = false;              
        controllerSet = false;                   
    }

     
    function setICOController(address _ico) onlyOwner {      
        require(_ico != 0x0);
        ICOcontroller = _ico;
        controllerSet = true;
    }


     
    function setParameters(address _timelockAddr) onlyOwner {
        require(_timelockAddr != 0x0);

        timelockTokens = _timelockAddr;

        tokenParametersSet = true;
    }

    function parametersAreSet() constant returns (bool) {
        return tokenParametersSet && controllerSet;
    }

     
    function setTokenCapInUnits(uint256 _supplyCap) onlyControllerOrOwner {    
        assert(_supplyCap > 0);
        
        supplyCap = SafeMath.safeMul(_supplyCap, (10**decimals));
    }

     
    function mintLockedTokens(uint256 _mMentTkns) onlyControllerOrOwner {
        assert(_mMentTkns > 0);
        assert(tokenParametersSet);

        mint(timelockTokens, _mMentTkns);  
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balanceOf[_owner];
    }

     
    function mint(address _address, uint _amount) onlyControllerOrOwner {
        require(_address != 0x0);
        uint256 amount = SafeMath.safeMul(_amount, (10**decimals));              

         
        assert(supplyCap > 0 && amount > 0 && SafeMath.safeAdd(currentSupply, amount) <= supplyCap);
        
        balanceOf[_address] = SafeMath.safeAdd(balanceOf[_address], amount);     
        currentSupply = SafeMath.safeAdd(currentSupply, amount);                 
        
        Mint(_address, amount);
    }
    
     
    function transfer(address _to, uint _value) returns (bool success) {
        require(!frozenAccount[msg.sender]);         

         
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);    
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                  
        Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {   
        require(!frozenAccount[_from]);                          
        
         
        if (allowance[_from][msg.sender] < _value)
            return false;

         
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value); 

         
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);

        Transfer(_from, _to, _value);
        return true;
    }
    
     
    function approve(address _spender, uint256 _value)       
        returns (bool success)
    {
        require(!frozenAccount[msg.sender]);                 

         
        if ((_value != 0) && (allowance[msg.sender][_spender] != 0)) {
           return false;
        }

        allowance[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);
        return true;
    }

     

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }
    
     
    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

     
    function burn(uint _amount) returns (bool result) {

        if (_amount > balanceOf[msg.sender])
            return false;        

         
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _amount);
        currentSupply = SafeMath.safeSub(currentSupply, _amount);

         
        result = esgAssetHolder.burn(msg.sender, _amount);
        require(result);

        Burn(msg.sender, _amount);
    }

     

    ESGAssetHolder esgAssetHolder;               
    bool lockedAssetHolder;                      

    function lockAssetHolder() onlyOwner {       
        lockedAssetHolder = true;
    }

    function setAssetHolder(address _assetAdress) onlyOwner {    
        assert(!lockedAssetHolder);              
        esgAssetHolder = ESGAssetHolder(_assetAdress);
    }    
}

     
contract TokenTimelock {

     
    ESGToken token;

     
    address public beneficiary;

     
    uint256 public releaseTime;

    function TokenTimelock(address _token, address _beneficiary) {
        require(_token != 0x0);
        require(_beneficiary != 0x0);

        token = ESGToken(_token);
         
        beneficiary = _beneficiary;
        releaseTime = now + 2 years;
    }

     
    function lockedBalance() public constant returns (uint256) {
        return token.balanceOf(this);
    }

     
    function release() {
        require(now >= releaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.transfer(beneficiary, amount);
    }
}

     
contract ICOEvent is Owned {

    ESGToken public token;                               

    uint256 public startTime = 0;                        
    uint256 public endTime;                              
    uint256 duration;                                    
    bool parametersSet;                                  
    bool supplySet;                                      

    address holdingAccount = 0x0;                        
    uint256 public totalTokensMinted;                    

     
    uint256 public rate_toTarget;                        
    uint256 public rate_toCap;                           
    uint256 public totalWeiContributed = 0;              
    uint256 public minWeiContribution = 0.01 ether;      
    uint256 constant weiEtherConversion = 10**18;        

     
    uint256 public baseTargetInWei;                      
    uint256 public icoCapInWei;                          

    event logPurchase (address indexed purchaser, uint value, uint256 tokens);

    enum State { Active, Refunding, Closed }             
    State public state;
    mapping (address => uint256) public deposited;       
    mapping (address => uint256) public tokensIssued;    

     
    function ICOEvent() {
        state = State.Active;
        totalTokensMinted = 0;
        parametersSet = false;
        supplySet = false;
    }

      
    function ICO_setParameters(address _tokenAddress, uint256 _target_rate, uint256 _cap_rate, uint256 _baseTarget, uint256 _cap, address _holdingAccount, uint256 _duration) onlyOwner {
        require(_target_rate > 0 && _cap_rate > 0);
        require(_baseTarget >= 0);
        require(_cap > 0);
        require(_duration > 0);
        require(_holdingAccount != 0x0);
        require(_tokenAddress != 0x0);

        rate_toTarget = _target_rate;
        rate_toCap = _cap_rate;
        token = ESGToken(_tokenAddress);
        baseTargetInWei = SafeMath.safeMul(_baseTarget, weiEtherConversion);
        icoCapInWei = SafeMath.safeMul(_cap, weiEtherConversion);
        holdingAccount = _holdingAccount;
        duration = SafeMath.safeMul(_duration, 1 days);
        parametersSet = true;
    }

     
    function eventConfigured() internal constant returns (bool) {
        return parametersSet && supplySet;
    }

      
    function ICO_start() onlyOwner {
        assert (eventConfigured());
        startTime = now;
        endTime = SafeMath.safeAdd(startTime, duration);
    }

    function ICO_start_future(uint _startTime) onlyOwner {
        assert(eventConfigured());
        require(_startTime > now);
        startTime = _startTime;
        endTime = SafeMath.safeAdd(startTime, duration);
    }

    function ICO_token_supplyCap() onlyOwner {
        require(token.parametersAreSet());                           

         
        uint256 targetTokens = SafeMath.safeMul(baseTargetInWei, rate_toTarget);         
        targetTokens = SafeMath.safeDiv(targetTokens, weiEtherConversion);

         
        uint256 capTokens = SafeMath.safeSub(icoCapInWei, baseTargetInWei);
        capTokens = SafeMath.safeMul(capTokens, rate_toCap);
        capTokens = SafeMath.safeDiv(capTokens, weiEtherConversion);

         
        uint256 mmentTokens = SafeMath.safeMul(targetTokens, 10);
        mmentTokens = SafeMath.safeDiv(mmentTokens, 100);

         
        uint256 tokens_available = SafeMath.safeAdd(capTokens, targetTokens); 

        uint256 total_Token_Supply = SafeMath.safeAdd(tokens_available, mmentTokens);  

        token.setTokenCapInUnits(total_Token_Supply);           
        token.mintLockedTokens(mmentTokens);                    
        supplySet = true;
    }

     
    function () payable {
        deposit(msg.sender);
    }

     
    function deposit(address _for) payable {

         
        require(validPurchase(msg.value));            
        require(state == State.Active);      
        require(!ICO_Ended());               

         
        uint256 targetContribution = getPreTargetContribution(msg.value);                
        uint256 capContribution = SafeMath.safeSub(msg.value, targetContribution);       
        totalWeiContributed = SafeMath.safeAdd(totalWeiContributed, msg.value);          

         
        uint256 targetTokensToMint = SafeMath.safeMul(targetContribution, rate_toTarget);    
        uint256 capTokensToMint = SafeMath.safeMul(capContribution, rate_toCap);             
        uint256 tokensToMint = SafeMath.safeAdd(targetTokensToMint, capTokensToMint);        
        
        tokensToMint = SafeMath.safeDiv(tokensToMint, weiEtherConversion);                   
        totalTokensMinted = SafeMath.safeAdd(totalTokensMinted, tokensToMint);               

        deposited[_for] = SafeMath.safeAdd(deposited[_for], msg.value);                      
        tokensIssued[_for] = SafeMath.safeAdd(tokensIssued[_for], tokensToMint);             

        token.mint(_for, tokensToMint);                                                      
        logPurchase(_for, msg.value, tokensToMint);
    }

     
    function getPreTargetContribution(uint256 _valueSent) internal returns (uint256) {
        
        uint256 targetContribution = 0;                                                      

        if (totalWeiContributed < baseTargetInWei) {                                             
            if (SafeMath.safeAdd(totalWeiContributed, _valueSent) > baseTargetInWei) {            
                targetContribution = SafeMath.safeSub(baseTargetInWei, totalWeiContributed);      
            } else {
                targetContribution = _valueSent;
            }
        }
        return targetContribution;    
    }

     

     
    function ICO_Live() public constant returns (bool) {
        return (now >= startTime && now < endTime && state == State.Active);
    }

     
    function validPurchase(uint256 _value) payable returns (bool) {           
        bool validTime = (now >= startTime && now < endTime);            
        bool validAmount = (_value >= minWeiContribution);
        bool withinCap = SafeMath.safeAdd(totalWeiContributed, _value) <= icoCapInWei;

        return validTime && validAmount && withinCap;
    }

     
    function ICO_Ended() public constant returns (bool) {
        bool capReached = (totalWeiContributed >= icoCapInWei);
        bool stateValid = state == State.Closed;

        return (now >= endTime) || capReached || stateValid;
    }

     
    function Wei_Remaining_To_ICO_Cap() public constant returns (uint256) {
        return (icoCapInWei - totalWeiContributed);
    }

     
    function baseTargetReached() public constant returns (bool) {
    
        return totalWeiContributed >= baseTargetInWei;
    }

     
    function capReached() public constant returns (bool) {
    
        return totalWeiContributed == icoCapInWei;
    }

     

    event Closed();

     
    function close() onlyOwner {
        require((now >= endTime) || (totalWeiContributed >= icoCapInWei));
        require(state==State.Active);
        state = State.Closed;
        Closed();

        holdingAccount.transfer(this.balance);
    }
}