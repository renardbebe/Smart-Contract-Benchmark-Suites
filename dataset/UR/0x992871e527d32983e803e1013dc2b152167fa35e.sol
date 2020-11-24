 

 
 
pragma solidity ^0.4.8;

contract SafeMath {
    function safeDiv(uint a, uint b) internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

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

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    uint256 constant MAX_UINT256 = 2**256 - 1;

    bool public isFrozen;               

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (isFrozen) revert();
         
         
         
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (isFrozen) revert();
         
         
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
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

contract PreAdsMobileToken is StandardToken, SafeMath {

     

     
    string public name;                    
    uint8 public decimals = 18;                 
    string public symbol;                  
    string public version = 'H0.1';        

     
    address public ethFundDeposit;       

     
    bool public isFinalized;               
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public checkNumber;
    uint256 public totalSupplyWithOutBonus;
    uint256 public constant tokenExchangeRate               = 400;  
    uint256 public constant tokenCreationCapWithOutBonus    = 3 * (10**6) * 10**18;
    uint256 public constant tokenNeedForBonusLevel0         = 100 * (10**3) * 10**18;
    uint256 public constant bonusLevel0PercentModifier      = 300;
    uint256 public constant tokenNeedForBonusLevel1         = 50 * (10**3) * 10**18;
    uint256 public constant bonusLevel1PercentModifier      = 200;
    uint256 public constant tokenCreationMinPayment         = 50 * (10**3) * 10**18;

     
    event CreateAds(address indexed _to, uint256 _value);

     
    function PreAdsMobileToken(
    string _tokenName,
    string _tokenSymbol,
    address _ethFundDeposit,
    uint256 _fundingStartBlock,
    uint256 _fundingEndBlock
    )
    {
        balances[msg.sender] = 0;                
        totalSupply = 0;                         
        name = _tokenName;            
        decimals = 18;                           
        symbol = _tokenSymbol;                         
        isFinalized = false;                     
        isFrozen = false;
        ethFundDeposit = _ethFundDeposit;
        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
        checkNumber = 42;                        
    }

     
    function createTokens() public payable {
        if (isFinalized) revert();
        if (block.number < fundingStartBlock) revert();
        if (block.number > fundingEndBlock) revert();
        if (msg.value == 0) revert();
        uint256 tokensWithOutBonus = safeMult(msg.value, tokenExchangeRate);  
        if (tokensWithOutBonus < tokenCreationMinPayment) revert();
        uint256 checkedSupplyWithOutBonus = safeAdd(totalSupplyWithOutBonus, tokensWithOutBonus);
         
        if (tokenCreationCapWithOutBonus < checkedSupplyWithOutBonus) revert();   
        totalSupplyWithOutBonus = checkedSupplyWithOutBonus;

        uint256 tokens = tokensWithOutBonus;
        if(tokens >= tokenNeedForBonusLevel0) {
            tokens = safeDiv(tokens, 100);
            tokens = safeMult(tokens, bonusLevel0PercentModifier);
        } else {
            if(tokens >= tokenNeedForBonusLevel1) {
                tokens = safeDiv(tokens, 100);
                tokens = safeMult(tokens, bonusLevel1PercentModifier);
            }
        }
        uint256 checkedSupply = safeAdd(totalSupply, tokens);
        totalSupply = checkedSupply;
        balances[msg.sender] += tokens;   
        CreateAds(msg.sender, tokens);   
    }

     
    function cashin() external payable {
        if (isFinalized) revert();
    }

    function cashout(uint256 amount) external {
        if (isFinalized) revert();
        if (msg.sender != ethFundDeposit) revert();  
        if (!ethFundDeposit.send(amount)) revert();   
    }

     
    function freeze() external {
        if (msg.sender != ethFundDeposit) revert();  
        isFrozen = true;
    }

    function unFreeze() external {
        if (msg.sender != ethFundDeposit) revert();  
        isFrozen = false;
    }

     
    function finalize() external {
        if (isFinalized) revert();
        if (msg.sender != ethFundDeposit) revert();  
        if (block.number <= fundingEndBlock && totalSupplyWithOutBonus < tokenCreationCapWithOutBonus - tokenCreationMinPayment) revert();
         
        if (!ethFundDeposit.send(this.balance)) revert();   
        isFinalized = true;
    }

     
    function() external payable {
        createTokens();
    }

}