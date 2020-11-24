 

pragma solidity ^0.4.12;
contract Token{
     
    uint256 public totalSupply;

     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
    function approve(address _spender, uint256 _value) returns (bool success);

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract QFBToken is Token {
    address manager;
 
    mapping(address => uint) frozenTime;

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    function freeze(address account, bool frozen) public onlyManager {
        frozenTime[account] = now + 10 minutes;
 
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        if(balances[msg.sender] >= _value && _value > 0) {
            require(balances[msg.sender] >= _value);
            balances[msg.sender] -= _value; 
            balances[_to] += _value; 
            Transfer(msg.sender, _to, _value); 
            freeze(_to, true);
            return true;
        }
        
    }


    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(frozenTime[_from] <= now);
        
        if(balances[_from] >= _value  && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            Transfer(_from, _to, _value);

            return true;
        } else {
            return false;
        }
    }
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value) returns (bool success)   
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender]; 
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    string public constant name = "QFBCOIN";                    
    uint256 public constant decimals = 18;                
    string public constant symbol = "QFB";                
    string public version = 'QF1.0';     

     
    address public ethFundDeposit;           
    address public newContractAddr;          

     
    bool    public isFunding;                 
    uint256 public fundingStartBlock;
    uint256 public fundingStopBlock;

    uint256 public currentSupply;            
    uint256 public tokenRaised = 0;          
    uint256 public tokenMigrated = 0;      
    uint256 public tokenExchangeRate = 625;              

     
    event AllocateToken(address indexed _to, uint256 _value);    
    event IssueToken(address indexed _to, uint256 _value);       
    event IncreaseSupply(uint256 _value);
    event DecreaseSupply(uint256 _value);
    event Migrate(address indexed _to, uint256 _value);

      
    function formatDecimals(uint256 _value) internal returns (uint256) {
        return _value * 10 ** decimals;
    }

     
    function QFBToken( address _ethFundDeposit, uint256 _currentSupply) {
        ethFundDeposit = _ethFundDeposit;

        isFunding = false;
         
        fundingStartBlock = 0;
        fundingStopBlock = 0;
        currentSupply = formatDecimals(_currentSupply);
        totalSupply = formatDecimals(10000);
        balances[msg.sender] = totalSupply;
        manager = msg.sender;
        if (currentSupply > totalSupply) throw;
    }
}