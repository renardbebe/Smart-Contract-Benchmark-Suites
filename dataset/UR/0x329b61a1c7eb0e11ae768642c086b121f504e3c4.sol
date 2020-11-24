 

pragma solidity ^0.4.23;

library SafeMath
{
    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a+b;
        assert (c>=a);
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        assert(a>=b);
        return (a-b);
    }
    function mul(uint256 a,uint256 b)internal pure returns (uint256)
    {
        if (a==0)
        {
        return 0;
        }
        uint256 c = a*b;
        assert ((c/a)==b);
        return c;
    }
    function div(uint256 a,uint256 b)internal pure returns (uint256)
    {
        return a/b;
    }
}

contract ERC20
{
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Owned
{
    address public owner;

    constructor() internal
    {
        owner = msg.sender;
    }
    modifier onlyowner()
    {
        require(msg.sender==owner);
        _;
    }
}

contract pausable is Owned
{
    event Pause();
    event Unpause();
    bool public pause = false;

    modifier whenNotPaused()
    {
        require(!pause);
        _;
    }
    modifier whenPaused()
    {
        require(pause);
        _;
    }
    function pause() onlyowner whenNotPaused public
    {
        pause = true;
        emit Pause();
    }
    function unpause() onlyowner whenPaused public
    {
        pause = false;
        emit Unpause();
    }
}

contract TokenControl is ERC20,pausable
{
    using SafeMath for uint256;
    mapping (address =>uint256) internal balances;
    mapping (address => mapping(address =>uint256)) internal allowed;
    uint256 totaltoken;

    function totalSupply() public view returns (uint256)
    {
        return totaltoken;
    }
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool)
    {
        require(_to!=address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function balanceOf(address _owner) public view returns (uint256 balance)
    {
        return balances[_owner];
    }
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused  returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256)
    {
        return allowed[_owner][_spender];
    }
    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool)
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue)
        {
            allowed[msg.sender][_spender] = 0;
        }
        else
        {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract claimable is Owned
{
    address public pendingOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyPendingOwner()
    {
        require(msg.sender == pendingOwner);
        _;
    }
    function transferOwnership(address newOwner) onlyowner public
    {
        pendingOwner = newOwner;
    }
    function claimOwnership() onlyPendingOwner public
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

 
contract RT is TokenControl,claimable
{
    using SafeMath for uint256;
    string public constant name    = "RecuToken";
    string public constant symbol  = "RT";
    uint256 public decimals = 18;
    uint256 totalsupply =  500000000*(10**decimals);

    address public vault;

     
    constructor () public
    {
        balances[msg.sender] = totalsupply;
        totaltoken = totalsupply;
        vault = msg.sender;
    }

     

    address public salesAgent;
    address internal pendingAgent;

    event SetSalesAgent(address indexed previousSalesAgent, address indexed newSalesAgent);
    event RemovedSalesAgent(address indexed currentSalesAgent);

     
    function setSalesAgent(address newSalesAgent) onlyowner public
    {
        pendingAgent = newSalesAgent;
    }

    function claimSalesAgent() public
    {
        require(msg.sender==pendingAgent);
        emit SetSalesAgent(salesAgent, pendingAgent);
        salesAgent = pendingAgent;
        pendingAgent = address(0);
    }

     
    function removedSalesAgent() onlyowner public
    {
        emit RemovedSalesAgent(salesAgent);
        salesAgent = address(0);
    }

     
    function transferTokensFromVault(address toAddress, uint256 tokensAmount) public
    {
        require(salesAgent == msg.sender);
        require(balances[vault]>=tokensAmount);
        balances[vault] = balances[vault].sub(tokensAmount);
        balances[toAddress] = balances[toAddress].add(tokensAmount);
        emit Transfer(vault, toAddress, tokensAmount);
    }
}