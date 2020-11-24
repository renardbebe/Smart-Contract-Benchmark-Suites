 

pragma solidity 0.4.24;

contract IMigrationContract {
    function migrate(address _addr, uint256 _tokens, uint256 _totaltokens) public returns (bool success);
}

 
contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }
    
    function safeDiv(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x / y;
        return z;
    }

}

 
contract Ownable {
    address public ethFundDeposit;

    event OwnershipTransferred(address indexed ethFundDeposit, address indexed _newFundDeposit);

     
    constructor() public {
        ethFundDeposit = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == ethFundDeposit);
        _;
    }

     
    function transferOwnership(address _newFundDeposit) public onlyOwner {
        require(_newFundDeposit != address(0));
        emit OwnershipTransferred(ethFundDeposit, _newFundDeposit);
        ethFundDeposit = _newFundDeposit;
    }
}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}


 
contract controllable is Ownable {

    event AddToBlacklist(address _addr);
    event DeleteFromBlacklist(address _addr);

     
    mapping (address => bool) internal blacklist;  

     
    function addtoblacklist(address _addr) public onlyOwner {
        blacklist[_addr] = true;
        emit AddToBlacklist(_addr);
    }

     
    function deletefromblacklist(address _addr) public onlyOwner {
        blacklist[_addr] = false;
        emit DeleteFromBlacklist(_addr);
    }

     
    function isBlacklist(address _addr) public view returns(bool) {
        return blacklist[_addr];
    }
}


 
contract Lockable is Ownable, SafeMath {

     
    mapping (address => uint256) balances;
    mapping (address => uint256) totalbalances;
    uint256 public totalreleaseblances;

    mapping (address => mapping (uint256 => uint256)) userbalances;  
    mapping (address => mapping (uint256 => uint256)) userRelease;  
    mapping (address => mapping (uint256 => uint256)) isRelease;  
    mapping (address => mapping (uint256 => uint256)) userChargeTime;  
    mapping (address => uint256) userChargeCount;  
    mapping (address => mapping (uint256 => uint256)) lastCliff;  

     
    mapping (address => mapping (uint256 => mapping (uint256 => uint256))) userbalancesSegmentation;  

    uint256 internal duration = 30*15 days;
    uint256 internal cliff = 90 days;

     
    event userlockmechanism(address _addr,uint256 _amount,uint256 _timestamp);
    event userrelease(address _addr, uint256 _times, uint256 _amount);

    modifier onlySelfOrOwner(address _addr) {
        require(msg.sender == _addr || msg.sender == ethFundDeposit);
        _;
    }

    function LockMechanism (
        address _addr,
        uint256 _value
    )
        internal
    {
        require(_addr != address(0));
        require(_value != 0);
         
        userChargeCount[_addr] = safeAdd(userChargeCount[_addr],1);
        uint256 _times = userChargeCount[_addr];
         
        userChargeTime[_addr][_times] = ShowTime();
         
        userbalances[_addr][_times] = _value;
        initsegmentation(_addr,userChargeCount[_addr],_value);
        totalbalances[_addr] = safeAdd(totalbalances[_addr],_value);
        isRelease[_addr][_times] = 0;
        emit userlockmechanism(_addr,_value,ShowTime());
    }

 
    function initsegmentation(address _addr,uint256 _times,uint256 _value) internal {
        for (uint8 i = 1 ; i <= 5 ; i++ ) {
            userbalancesSegmentation[_addr][_times][i] = safeDiv(_value,5);
        }
    }

 
    function CalcPeriod(address _addr, uint256 _times) public view returns (uint256) {
        uint256 userstart = userChargeTime[_addr][_times];
        if (ShowTime() >= safeAdd(userstart,duration)) {
            return 5;
        }
        uint256 timedifference = safeSubtract(ShowTime(),userstart);
        uint256 period = 0;
        for (uint8 i = 1 ; i <= 5 ; i++ ) {
            if (timedifference >= cliff) {
                timedifference = safeSubtract(timedifference,cliff);
                period += 1;
            }
        }
        return period;
    }

 
    function ReleasableAmount(address _addr, uint256 _times) public view returns (uint256) {
        require(_addr != address(0));
        uint256 period = CalcPeriod(_addr,_times);
        if (safeSubtract(period,isRelease[_addr][_times]) > 0){
            uint256 amount = 0;
            for (uint256 i = safeAdd(isRelease[_addr][_times],1) ; i <= period ; i++ ) {
                amount = safeAdd(amount,userbalancesSegmentation[_addr][_times][i]);
            }
            return amount;
        } else {
            return 0;
        }
    }

 
    function release(address _addr, uint256 _times) external onlySelfOrOwner(_addr) {
        uint256 amount = ReleasableAmount(_addr,_times);
        require(amount > 0);
        userRelease[_addr][_times] = safeAdd(userRelease[_addr][_times],amount);
        balances[_addr] = safeAdd(balances[_addr],amount);
        lastCliff[_addr][_times] = ShowTime();
        isRelease[_addr][_times] = CalcPeriod(_addr,_times);
        totalreleaseblances = safeAdd(totalreleaseblances,amount);
        emit userrelease(_addr, _times, amount);
    }

 
    function ShowTime() internal view returns (uint256) {
        return block.timestamp;
    }

 
    function totalBalanceOf(address _addr) public view returns (uint256) {
        return totalbalances[_addr];
    }
 
    function ShowRelease(address _addr, uint256 _times) public view returns (uint256) {
        return userRelease[_addr][_times];
    }
 
    function ShowUnrelease(address _addr, uint256 _times) public view returns (uint256) {
        return safeSubtract(userbalances[_addr][_times],ShowRelease(_addr,_times));
    }
 
    function ShowChargeTime(address _addr, uint256 _times) public view returns (uint256) {
        return userChargeTime[_addr][_times];
    }
 
    function ShowChargeCount(address _addr) public view returns (uint256) {
        return userChargeCount[_addr];
    }
 
    function ShowNextCliff(address _addr, uint256 _times) public view returns (uint256) {
        return safeAdd(lastCliff[_addr][_times],cliff);
    }
 
    function ShowSegmentation(address _addr, uint256 _times,uint256 _period) public view returns (uint256) {
        return userbalancesSegmentation[_addr][_times][_period];
    }

}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining); 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract StandardToken is controllable, Pausable, Token, Lockable {

    function transfer(address _to, uint256 _value) public whenNotPaused() returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to] && !isBlacklist(msg.sender)) {
             
            balances[msg.sender] = safeSubtract(balances[msg.sender],_value);
            totalbalances[msg.sender] = safeSubtract(totalbalances[msg.sender],_value);
             
            balances[_to] = safeAdd(balances[_to],_value);
            totalbalances[_to] = safeAdd(totalbalances[_to],_value);

            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused() returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to] && !isBlacklist(msg.sender)) {
             
            balances[_to] = safeAdd(balances[_to],_value);
            totalbalances[_to] = safeAdd(totalbalances[_to],_value);
             
            balances[_from] = safeSubtract(balances[_from],_value);
            totalbalances[_from] = safeSubtract(totalbalances[_from],_value);
             
            allowed[_from][msg.sender] = safeSubtract(allowed[_from][msg.sender],_value);

            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) { 
        return allowed[_owner][_spender];
    }

     
    mapping (address => mapping (address => uint256)) allowed;
}

contract BugXToken is StandardToken {

     

     
    string  public constant name = "BUGX Token";
    string  public constant symbol = "BUX";
    uint256 public constant decimals = 18;
    string  public version = "1.0";

     
    address public newContractAddr;          

     
    bool    public isFunding;                 
    uint256 public fundingStartBlock;
    uint256 public fundingStopBlock;

    uint256 public currentSupply;            
    uint256 public tokenRaised = 0;            
    uint256 public tokenIssued = 0;          
    uint256 public tokenMigrated = 0;      
    uint256 internal tokenExchangeRate = 9000;              
    uint256 internal tokenExchangeRateTwo = 9900;              
    uint256 internal tokenExchangeRateThree = 11250;              

     
    event AllocateToken(address indexed _to, uint256 _value);    
    event TakebackToken(address indexed _from, uint256 _value);    
    event RaiseToken(address indexed _to, uint256 _value);       
    event IssueToken(address indexed _to, uint256 _value);
    event IncreaseSupply(uint256 _value);
    event DecreaseSupply(uint256 _value);
    event Migrate(address indexed _addr, uint256 _tokens, uint256 _totaltokens);

     
    function formatDecimals(uint256 _value) internal pure returns (uint256 ) {
        return _value * 10 ** decimals;
    }

     

     
    constructor(
        address _ethFundDeposit,
        uint256 _currentSupply
        ) 
        public
    {
        require(_ethFundDeposit != address(0x0));
        ethFundDeposit = _ethFundDeposit;

        isFunding = false;                            
        fundingStartBlock = 0;
        fundingStopBlock = 0;

        currentSupply = formatDecimals(_currentSupply);
        totalSupply = formatDecimals(1500000000);     
        require(currentSupply <= totalSupply);
        balances[ethFundDeposit] = currentSupply;
        totalbalances[ethFundDeposit] = currentSupply;
    }

     

     
    function increaseSupply (uint256 _tokens) onlyOwner external {
        uint256 _value = formatDecimals(_tokens);
        require (_value + currentSupply <= totalSupply);
        currentSupply = safeAdd(currentSupply, _value);
        tokenadd(ethFundDeposit,_value);
        emit IncreaseSupply(_value);
    }

     
    function decreaseSupply (uint256 _tokens) onlyOwner external {
        uint256 _value = formatDecimals(_tokens);
        uint256 tokenCirculation = safeAdd(tokenRaised,tokenIssued);
        require (safeAdd(_value,tokenCirculation) <= currentSupply);
        currentSupply = safeSubtract(currentSupply, _value);
        tokensub(ethFundDeposit,_value);
        emit DecreaseSupply(_value);
    }

     

    modifier whenFunding() {
        require (isFunding);
        require (block.number >= fundingStartBlock);
        require (block.number <= fundingStopBlock);
        _;
    }

     
    function startFunding (uint256 _fundingStartBlock, uint256 _fundingStopBlock) onlyOwner external {
        require (!isFunding);
        require (_fundingStartBlock < _fundingStopBlock);
        require (block.number < _fundingStartBlock);

        fundingStartBlock = _fundingStartBlock;
        fundingStopBlock = _fundingStopBlock;
        isFunding = true;
    }

     
    function stopFunding() onlyOwner external {
        require (isFunding);
        isFunding = false;
    }


     

     
    function setMigrateContract(address _newContractAddr) onlyOwner external {
        require (_newContractAddr != newContractAddr);
        newContractAddr = _newContractAddr;
    }

     
    function migrate(address _addr) onlySelfOrOwner(_addr) external {
        require(!isFunding);
        require(newContractAddr != address(0x0));

        uint256 tokens_value = balances[_addr];
        uint256 totaltokens_value = totalbalances[_addr];
        require (tokens_value != 0 || totaltokens_value != 0);

        balances[_addr] = 0;
        totalbalances[_addr] = 0;

        IMigrationContract newContract = IMigrationContract(newContractAddr);
        require (newContract.migrate(_addr, tokens_value, totaltokens_value));

        tokenMigrated = safeAdd(tokenMigrated, totaltokens_value);
        emit Migrate(_addr, tokens_value, totaltokens_value);
    }

     

     
    function tokenRaise (address _addr,uint256 _value) internal {
        uint256 tokenCirculation = safeAdd(tokenRaised,tokenIssued);
        require (safeAdd(_value,tokenCirculation) <= currentSupply);
        tokenRaised = safeAdd(tokenRaised, _value);
        emit RaiseToken(_addr, _value);
    }

     
    function tokenIssue (address _addr,uint256 _value) internal {
        uint256 tokenCirculation = safeAdd(tokenRaised,tokenIssued);
        require (safeAdd(_value,tokenCirculation) <= currentSupply);
        tokenIssued = safeAdd(tokenIssued, _value);
        emit IssueToken(_addr, _value);
    }

     
    function tokenTakeback (address _addr,uint256 _value) internal {
        require (tokenIssued >= _value);
        tokenIssued = safeSubtract(tokenIssued, _value);
        emit TakebackToken(_addr, _value);
    }

     
    function tokenadd (address _addr,uint256 _value) internal {
        require(_value != 0);
        require (_addr != address(0x0));
        balances[_addr] = safeAdd(balances[_addr], _value);
        totalbalances[_addr] = safeAdd(totalbalances[_addr], _value);
    }

     
    function tokensub (address _addr,uint256 _value) internal {
        require(_value != 0);
        require (_addr != address(0x0));
        balances[_addr] = safeSubtract(balances[_addr], _value);
        totalbalances[_addr] = safeSubtract(totalbalances[_addr], _value);
    }

     

     
    function allocateToken(address _addr, uint256 _tokens) onlyOwner external {
        uint256 _value = formatDecimals(_tokens);
        tokenadd(_addr,_value);
        tokensub(ethFundDeposit,_value);
        tokenIssue(_addr,_value);
        emit Transfer(ethFundDeposit, _addr, _value);
    }

     
    function deductionToken (address _addr, uint256 _tokens) onlyOwner external {
        uint256 _value = formatDecimals(_tokens);
        tokensub(_addr,_value);
        tokenadd(ethFundDeposit,_value);
        tokenTakeback(_addr,_value);
        emit Transfer(_addr, ethFundDeposit, _value);
    }

     
    function addSegmentation(address _addr, uint256 _times,uint256 _period,uint256 _tokens) onlyOwner external returns (bool) {
        uint256 amount = userbalancesSegmentation[_addr][_times][_period];
        if (amount != 0 && _tokens != 0){
            uint256 _value = formatDecimals(_tokens);
            userbalancesSegmentation[_addr][_times][_period] = safeAdd(amount,_value);
            userbalances[_addr][_times] = safeAdd(userbalances[_addr][_times], _value);
            totalbalances[_addr] = safeAdd(totalbalances[_addr], _value);
            tokensub(ethFundDeposit,_value);
            tokenIssue(_addr,_value);
            return true;
        } else {
            return false;
        }
    }

     
    function subSegmentation(address _addr, uint256 _times,uint256 _period,uint256 _tokens) onlyOwner external returns (bool) {
        uint256 amount = userbalancesSegmentation[_addr][_times][_period];
        if (amount != 0 && _tokens != 0){
            uint256 _value = formatDecimals(_tokens);
            userbalancesSegmentation[_addr][_times][_period] = safeSubtract(amount,_value);
            userbalances[_addr][_times] = safeSubtract(userbalances[_addr][_times], _value);
            totalbalances[_addr] = safeSubtract(totalbalances[_addr], _value);
            tokenadd(ethFundDeposit,_value);
            tokenTakeback(_addr,_value);
            return true;
        } else {
            return false;
        }
    }

     

     
    function setTokenExchangeRate(uint256 _RateOne,uint256 _RateTwo,uint256 _RateThree) onlyOwner external {
        require (_RateOne != 0 && _RateTwo != 0 && _RateThree != 0);
        require (_RateOne != tokenExchangeRate && _RateTwo != tokenExchangeRateTwo && _RateThree != tokenExchangeRateThree);

        tokenExchangeRate = _RateOne;
        tokenExchangeRateTwo = _RateTwo;
        tokenExchangeRateThree = _RateThree;
    }

     
    function computeTokenAmount(uint256 _eth) internal view returns (uint256 tokens) {
        if(_eth > 0 && _eth < 100 ether){
            tokens = safeMult(_eth, tokenExchangeRate);
        }
        
        if (_eth >= 100 ether && _eth < 500 ether){
            tokens = safeMult(_eth, tokenExchangeRateTwo);
        }

        if (_eth >= 500 ether ){
            tokens = safeMult(_eth, tokenExchangeRateThree);
        }
    }

     

    function LockMechanismByOwner (
        address _addr,
        uint256 _tokens
    )
        external onlyOwner whenFunding
    {
        require (_tokens != 0);
        uint256 _value = formatDecimals(_tokens);
        tokenRaise(_addr,_value);
        tokensub(ethFundDeposit,_value);
        LockMechanism(_addr,_value);
        emit Transfer(ethFundDeposit,_addr,_value);
    }

     

     
    function transferETH() onlyOwner external {
        require (address(this).balance != 0);
        ethFundDeposit.transfer(address(this).balance);
    }

    function () public payable whenFunding {  
        require (msg.value != 0);
        uint256 _value = computeTokenAmount(msg.value);
        tokenRaise(msg.sender,_value);
        tokensub(ethFundDeposit,_value);
        LockMechanism(msg.sender,_value);
        emit Transfer(ethFundDeposit,msg.sender,_value);
    }
}