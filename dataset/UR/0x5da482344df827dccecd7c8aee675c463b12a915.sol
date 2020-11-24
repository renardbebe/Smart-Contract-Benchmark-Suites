 

pragma solidity ^0.4.18;

 
contract ERC20
{
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    
    constructor(string _name, string _symbol) public 
    {
        name = _name;
        symbol = _symbol;
    }
    
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

 
contract Ownable
{
    address internal owner;
        
    constructor() public 
    {
        owner = msg.sender;
    }
    
    modifier onlyOwner() 
    {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyNotOwner()
    {
        require(msg.sender != owner);
        _;
    }
}

 
contract Issuable is Ownable
{
    mapping (address => bool) internal issuers;
    
    event IssuerAdd(address who);
    event IssuerRemoved(address who);
    
    function addIssuer(address who) onlyOwner public
    {
        require(who != owner);  
        require(!issuers[who]);
        issuers[who] = true;
        emit IssuerAdd(who);
    }
    
    function removeIssuer(address who) onlyOwner public
    {
        require(issuers[who]);
        issuers[who] = false;
        emit IssuerRemoved(who);
    }
    
    modifier onlyIssuer()
    {
        require(issuers[msg.sender]);
        _;
    }
    
    function IsIssuer(address who) public view onlyOwner returns(bool)
    {
        return issuers[who];
    }
}

 
contract TimeLimit
{
    uint256 public ICOStart; 
    uint256 public ICOEnd; 
    uint256 public TransferStart; 
    
    bool internal ICOEnable;
    bool internal TransferEnable;
    
    event ICOStarted();
    event ICOEnded();
    event TrasferEnabled();
    
    modifier onlyInIssueTime()
    {
        require(IsIssueTime());
         
         
        if (!ICOEnable && now <= ICOEnd)
        {
            emit ICOStarted();
            ICOEnable = true;
        }
        if (ICOEnable && now > ICOEnd)
        {
            emit ICOEnded();
            ICOEnable = false;
        }
        _;
    }
    
    modifier transferEnable()
    {
        require(now > TransferStart);
        if (!TransferEnable)
        {
            emit TrasferEnabled();
            TransferEnable = true;
        }
        _;
    }
    
    modifier closeCheckICO()
    {
        if (now > TransferStart) 
        {
            closeICO();
            return;
        }
        _;
    }
    
    function IsIssueTime() public view returns(bool)
    {
        return (now > ICOStart && now <= TransferStart);
    }
    
    function IsIcoTime() public view returns(bool)
    {
        return (now > ICOStart && now <= ICOEnd);
    }
    
    function IsTransferEnable() public view returns(bool)
    {
        return (now > TransferStart);
    }
    
    function closeICO() internal;
}

 
contract OurContract is ERC20, Issuable, TimeLimit
{
    event Cause(address to, uint256 val, uint8 _type, string message);
    
     
    function transfer(
        address to, uint256 value
        ) transferEnable public returns (bool)
    {
        return _transfer(msg.sender, to, value);
    }
    
    function transferFrom(
        address from, address to, uint256 value
        ) transferEnable public returns (bool) 
    {
        require(value <= allowances[from][msg.sender]);
        _transfer(from, to, value);
        allowances[from][msg.sender] = allowances[from][msg.sender] - value;
        return true;
    }
    
    function approve(
        address spender, uint256 value
        ) public onlyNotOwner returns (bool)
    {
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
     
    function totalSupply() public view returns (uint256) 
    {
        return totalSupply_;
    }
    
    function balanceOf(address owner_) public view returns (uint256 balance) 
    {
        return balances[owner_];
    }
    
    function allowance(
        address owner_, address spender
        ) public view returns (uint256) 
    {
        return allowances[owner_][spender];
    }
    
     
    function issue(
        address to, uint256 value, uint8 _type, string message
        ) onlyIssuer onlyInIssueTime closeCheckICO public
    {
        require(to != owner);
        require(!issuers[to]);
        _transfer(owner, to, value);
        emit Cause(to, value, _type, message);
    }
    
     
     
    constructor(
        string _name, string _symbol
        ) public 
        ERC20(_name, _symbol)
    {
        totalSupply_ = 300000000000000000000000000;  
        ICOStart = 1537747200;  
        ICOEnd = 1564531200;  
        TransferStart = 1565308800;  
        balances[msg.sender] = totalSupply_;
    }
    
    function endICO() onlyOwner closeCheckICO public returns(bool)
    {
        return (now > ICOEnd);
    }
    
     
     
    
     
    uint256 internal totalSupply_;
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowances;
    
     
    function _transfer(
        address from, address to, uint256 value
        ) onlyNotOwner internal returns (bool) 
    {
        require(to != address(0));
        require(value <= balances[from]);
        require(value + balances[to] > balances[to]);

        balances[from] = balances[from] - value;
        balances[to] = balances[to] + value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function closeICO() internal
    {
        totalSupply_ -= balances[owner];
        balances[owner] = 0;
        owner = 0;
    }
}