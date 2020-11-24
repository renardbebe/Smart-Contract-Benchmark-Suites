 

pragma solidity ^0.4.16;


 
 
contract SafeMath {
 
 
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }
 
    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }
 
    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }
 
}
 
contract TokenERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
 
 
contract StartMyToken is TokenERC20 {
 
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }
 
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
 
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
 
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
 
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
 
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}


 
contract LoveToken is StartMyToken, SafeMath {
 
   
     
    string  public constant name = "LOVE Token";
    string  public constant symbol = "LOVE";
    uint256 public constant decimals = 1;
    string  public version = "1.1";
 
     
    address public ethFundDeposit;           
    address public newContractAddr;          
 
     
    bool    public isFunding;                 
    uint256 public fundingStartBlock;
    uint256 public fundingStopBlock;
 
    uint256 public currentSupply;            
    uint256 public tokenRaised = 0;          
    uint256 public tokenMigrated = 0;      
    uint256 public tokenExchangeRate = 521;              
 
     
    event AllocateToken(address indexed _to, uint256 _value);    
    event IssueToken(address indexed _to, uint256 _value);       
    event IncreaseSupply(uint256 _value);
    event DecreaseSupply(uint256 _value);
     
    
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);
   
    
     
    function formatDecimals(uint256 _value) internal returns (uint256 ) {
        return _value * 10 ** decimals;
    }
 
     
    function LoveToken(
        address _ethFundDeposit,
        uint256 _currentSupply)
    {
        ethFundDeposit = _ethFundDeposit;
 
        isFunding = false;                            
        fundingStartBlock = 0;
        fundingStopBlock = 0;
 
        currentSupply = formatDecimals(_currentSupply);
        totalSupply = formatDecimals(5201314);
        balances[msg.sender] = totalSupply;
        if(currentSupply > totalSupply) revert();
    }

    modifier isOwner()  { require(msg.sender == ethFundDeposit); _; }
 
     
    function setTokenExchangeRate(uint256 _tokenExchangeRate) isOwner external {
        if (_tokenExchangeRate == 0) revert();
        if (_tokenExchangeRate == tokenExchangeRate) revert();
 
        tokenExchangeRate = _tokenExchangeRate;
    }
 
     
    function increaseSupply (uint256 _value) isOwner external {
        uint256 value = formatDecimals(_value);
        if (value + currentSupply > totalSupply) revert();
        currentSupply = safeAdd(currentSupply, value);
        IncreaseSupply(value);
    }
 
     
    function decreaseSupply (uint256 _value) isOwner external {
        uint256 value = formatDecimals(_value);
        if (value + tokenRaised > currentSupply) revert();
 
        currentSupply = safeSubtract(currentSupply, value);
        DecreaseSupply(value);
    }
 
     
    function startFunding (uint256 _fundingStartBlock, uint256 _fundingStopBlock) isOwner external {
        if (isFunding) revert();
        if (_fundingStartBlock >= _fundingStopBlock) revert();
        if (block.number >= _fundingStartBlock) revert();
 
        fundingStartBlock = _fundingStartBlock;
        fundingStopBlock = _fundingStopBlock;
        isFunding = true;
    }
 
     
    function stopFunding() isOwner external {
        if (!isFunding) revert();
        isFunding = false;
    }
 
     
    function setMigrateContract(address _newContractAddr) isOwner external {
        if (_newContractAddr == newContractAddr) revert();
        newContractAddr = _newContractAddr;
    }
 
     
    function changeOwner(address _newFundDeposit) isOwner() external {
        if (_newFundDeposit == address(0x0)) revert();
        ethFundDeposit = _newFundDeposit;
    }
 
     
   
 
     
    function transferETH() isOwner external {
        if (this.balance == 0) revert();
        if (!ethFundDeposit.send(this.balance)) revert();
    }
 
     
    function allocateToken (address _addr, uint256 _eth) isOwner external {
        if (_eth == 0) revert();
        if (_addr == address(0x0)) revert();
 
        uint256 tokens = safeMult(formatDecimals(_eth), tokenExchangeRate);
        if (tokens + tokenRaised > currentSupply) revert();
 
        tokenRaised = safeAdd(tokenRaised, tokens);
        balances[_addr] += tokens;
 
        AllocateToken(_addr, tokens);   
    }
 
     
    function () payable {
        require (!isFunding);
        if (msg.value == 0) revert();
 
        if (block.number < fundingStartBlock) revert();
        if (block.number > fundingStopBlock) revert();
 
        uint256 tokens = safeMult(msg.value, tokenExchangeRate);
        if (tokens + tokenRaised > currentSupply) revert();
 
        tokenRaised = safeAdd(tokenRaised, tokens);
        balances[msg.sender] += tokens;
 
        IssueToken(msg.sender, tokens);   
    }
}