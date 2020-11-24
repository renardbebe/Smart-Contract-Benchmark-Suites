 

pragma solidity ^0.5.9;

 

library SafeMath
{
  	function mul(uint256 a, uint256 b) internal pure returns (uint256)
    	{
		uint256 c = a * b;
		assert(a == 0 || c / a == b);

		return c;
  	}

  	function div(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a / b;

		return c;
  	}

  	function sub(uint256 a, uint256 b) internal pure returns (uint256)
	{
		assert(b <= a);

		return a - b;
  	}

  	function add(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a + b;
		assert(c >= a);

		return c;
  	}
}

contract OwnerHelper
{
  	address public owner;

  	event ChangeOwner(address indexed _from, address indexed _to);

  	modifier onlyOwner
	{
		require(msg.sender == owner);
		_;
  	}
  	
  	constructor() public
	{
		owner = msg.sender;
  	}
  	
  	function transferOwnership(address _to) onlyOwner public
  	{
    	require(_to != owner);
    	require(_to != address(0x0));

        address from = owner;
      	owner = _to;
  	    
      	emit ChangeOwner(from, _to);
  	}
}

contract ERC20Interface
{
    event Transfer( address indexed _from, address indexed _to, uint _value);
    event Approval( address indexed _owner, address indexed _spender, uint _value);
    
    function totalSupply() view public returns (uint _supply);
    function balanceOf( address _who ) public view returns (uint _value);
    function transfer( address _to, uint _value) public returns (bool _success);
    function approve( address _spender, uint _value ) public returns (bool _success);
    function allowance( address _owner, address _spender ) public view returns (uint _allowance);
    function transferFrom( address _from, address _to, uint _value) public returns (bool _success);
}

contract LIXToken is ERC20Interface, OwnerHelper
{
    using SafeMath for uint;
    
    string public name;
    uint public decimals;
    string public symbol;
    
    uint constant private E18 = 1000000000000000000;
    uint constant private month = 2592000;
    
     
    uint constant public maxTotalSupply =           3000000000 * E18;
    
     
    uint constant public maxOperSupply =             720000000 * E18;
     
    
     
    uint constant public maxMktSupply =              540000000 * E18;
     
    
     
    uint constant public maxBDevSupply =             450000000 * E18;
     
    
     
    uint constant public maxRsvSupply =              330000000 * E18;
     
    
     
    uint constant public maxEventSupply =            210000000 * E18;
     
    
     
    uint constant public maxSaleSupply =             750000000 * E18;
    
     
    uint constant public operVestingSupply          = 30000000 * E18;
    uint constant public operVestingLockDate        = 3 * month;
    uint constant public operVestingTime = 24;
    
    uint constant public mktVestingSupply           = 30000000 * E18;
    uint constant public mktVestingLockDate         = 2 * month;
    uint constant public mktVestingTime = 18;
    
    uint constant public bDevVestingSupply          = 37500000 * E18;
    uint constant public bDevVestingLockDate        = 3 * month;
    uint constant public bDevVestingTime = 12;
    
    uint constant public rsvVestingLockDate         = 1 * month;
    
    uint constant public eventVestingSupply         = 30000000 * E18;
    uint constant public eventVestingTime = 7;
    
    uint public totalTokenSupply;
    uint public tokenIssuedOper;
    uint public tokenIssuedMkt;
    uint public tokenIssuedBDev;
    uint public tokenIssuedRsv;
    uint public tokenIssuedEvent;
    uint public tokenIssuedSale;
    
    uint public burnTokenSupply;
    
    mapping (address => uint) public balances;
    mapping (address => mapping ( address => uint )) public approvals;
    
    mapping (uint => uint) public operVestingTimer;
    mapping (uint => uint) public operVestingBalances;
    
    mapping (uint => uint) public mktVestingTimer;
    mapping (uint => uint) public mktVestingBalances;
    
    mapping (uint => uint) public bDevVestingTimer;
    mapping (uint => uint) public bDevVestingBalances;
    
    uint public rsvVestingTime;
    
    mapping (uint => uint) public eventVestingTimer;
    mapping (uint => uint) public eventVestingBalances;
    
    bool public tokenLock = true;
    bool public saleTime = true;
    uint public endSaleTime = 0;
    
    event OperIssue(address indexed _to, uint _tokens);
    event MktIssue(address indexed _to, uint _tokens);
    event BDevIssue(address indexed _to, uint _tokens);
    event RsvIssue(address indexed _to, uint _tokens);
    event EventIssue(address indexed _to, uint _tokens);
    event SaleIssue(address indexed _to, uint _tokens);
    
    event Burn(address indexed _from, uint _tokens);
    
    event TokenUnlock(address indexed _to, uint _tokens);
    event EndSale(uint _date);
    
    constructor() public
    {
        name        = "LIX Token";
        decimals    = 18;
        symbol      = "LIX";
        
        totalTokenSupply    = 0;
        
        tokenIssuedOper   = 0;
        tokenIssuedMkt      = 0;
        tokenIssuedBDev     = 0;
        tokenIssuedRsv      = 0;
        tokenIssuedEvent    = 0;
        tokenIssuedSale     = 0;

        burnTokenSupply     = 0;
        
        require(maxOperSupply == operVestingSupply.mul(operVestingTime));
        require(maxMktSupply == mktVestingSupply.mul(mktVestingTime));
        require(maxBDevSupply == bDevVestingSupply.mul(bDevVestingTime));
        require(maxEventSupply == eventVestingSupply.mul(eventVestingTime));
        
        require(maxTotalSupply == maxOperSupply + maxMktSupply + maxBDevSupply + maxRsvSupply + maxEventSupply + maxSaleSupply);
    }
    
     

    function totalSupply() view public returns (uint) 
    {
        return totalTokenSupply;
    }
    
    function balanceOf(address _who) view public returns (uint) 
    {
        return balances[_who];
    }
    
    function transfer(address _to, uint _value) public returns (bool) 
    {
        require(isTransferable() == true);
        require(balances[msg.sender] >= _value);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint _value) public returns (bool)
    {
        require(isTransferable() == true);
        require(balances[msg.sender] >= _value);
        
        approvals[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true; 
    }
    
    function allowance(address _owner, address _spender) view public returns (uint) 
    {
        return approvals[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) 
    {
        require(isTransferable() == true);
        require(balances[_from] >= _value);
        require(approvals[_from][msg.sender] >= _value);
        
        approvals[_from][msg.sender] = approvals[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to]  = balances[_to].add(_value);
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
     
    
     
    
     
    function operIssue(address _to, uint _time) onlyOwner public
    {
        require(saleTime == false);
        require(_time <= operVestingTime);
        
        uint nowTime = now;
        require(nowTime > operVestingTimer[_time] );
        
        uint tokens = operVestingSupply;

        require(tokens == operVestingBalances[_time]);
        require(maxOperSupply >= tokenIssuedOper.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        operVestingBalances[_time] = 0;
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedOper = tokenIssuedOper.add(tokens);
        
        emit OperIssue(_to, tokens);
    }
    
     
    function mktIssue(address _to, uint _time) onlyOwner public
    {
        require(saleTime == false);
        require( _time <= mktVestingTime);
        
        uint nowTime = now;
        require( nowTime > mktVestingTimer[_time] );
        
        uint tokens = mktVestingSupply;

        require(tokens == mktVestingBalances[_time]);
        require(maxMktSupply >= tokenIssuedMkt.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        mktVestingBalances[_time] = 0;
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedMkt = tokenIssuedMkt.add(tokens);
        
        emit MktIssue(_to, tokens);
    }
    
     
    function bDevIssue(address _to, uint _time) onlyOwner public
    {
        require(saleTime == false);
        require( _time <= bDevVestingTime);
        
        uint nowTime = now;
        require( nowTime > bDevVestingTimer[_time] );
        
        uint tokens = bDevVestingSupply;

        require(tokens == bDevVestingBalances[_time]);
        require(maxBDevSupply >= tokenIssuedBDev.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        bDevVestingBalances[_time] = bDevVestingBalances[_time].sub(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedBDev = tokenIssuedBDev.add(tokens);
        
        emit BDevIssue(_to, tokens);
    }
    
    function rsvIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedRsv == 0);
        
        uint nowTime = now;
        require( nowTime > rsvVestingTime );
        
        uint tokens = maxRsvSupply;
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedRsv = tokenIssuedRsv.add(tokens);
        
        emit RsvIssue(_to, tokens);
    }
    
     
    function eventIssue(address _to, uint _time) onlyOwner public
    {
        require(saleTime == false);
        require( _time <= eventVestingTime);
        
        uint nowTime = now;
        require( nowTime > eventVestingTimer[_time] );
        
        uint tokens = eventVestingSupply;

        require(tokens == eventVestingBalances[_time]);
        require(maxEventSupply >= tokenIssuedEvent.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        eventVestingBalances[_time] = eventVestingBalances[_time].sub(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedEvent = tokenIssuedEvent.add(tokens);
        
        emit EventIssue(_to, tokens);
    }
    
    function saleIssue(address _to) onlyOwner public
    {
        require(tokenIssuedSale == 0);
        
        uint tokens = maxSaleSupply;
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedSale = tokenIssuedSale.add(tokens);
        
        emit SaleIssue(_to, tokens);
    }
    
     
    
     
    
    function isTransferable() private view returns (bool)
    {
        if(tokenLock == false)
        {
            return true;
        }
        else if(msg.sender == owner)
        {
            return true;
        }
        
        return false;
    }
    
    function setTokenUnlock() onlyOwner public
    {
        require(tokenLock == true);
        require(saleTime == false);
        
        tokenLock = false;
    }
    
    function setTokenLock() onlyOwner public
    {
        require(tokenLock == false);
        
        tokenLock = true;
    }
    
     
    
     
    
    function endSale() onlyOwner public
    {
        require(saleTime == true);
        require(maxSaleSupply == tokenIssuedSale);
        
        saleTime = false;
        
        uint nowTime = now;
        endSaleTime = nowTime;
        
        for(uint i = 1; i <= operVestingTime; i++)
        {
            uint lockTime = endSaleTime + operVestingLockDate + (month * i);
            operVestingTimer[i] = lockTime;
            operVestingBalances[i] = operVestingSupply;
        }
        
        for(uint i = 1; i <= mktVestingTime; i++)
        {
            uint lockTime = endSaleTime + mktVestingLockDate + (month * i);
            mktVestingTimer[i] = lockTime;
            mktVestingBalances[i] = mktVestingSupply;
        }
        
        for(uint i = 1; i <= bDevVestingTime; i++)
        {
            uint lockTime = endSaleTime + bDevVestingLockDate + (month * i);
            bDevVestingTimer[i] = lockTime;
            bDevVestingBalances[i] = bDevVestingSupply;
        }
        
        rsvVestingTime = endSaleTime + rsvVestingLockDate;
        
        for(uint i = 0; i < eventVestingTime; i++)
        {
            uint lockTime = endSaleTime + (month * i);
            eventVestingTimer[i + 1] = lockTime;
            eventVestingBalances[i + 1] = eventVestingSupply;
        }
        
        emit EndSale(endSaleTime);
    }
    
    function withdrawTokens(address _contract, uint _decimals, uint _value) onlyOwner public
    {

        if(_contract == address(0x0))
        {
            uint eth = _value.mul(10 ** _decimals);
            msg.sender.transfer(eth);
        }
        else
        {
            uint tokens = _value.mul(10 ** _decimals);
            ERC20Interface(_contract).transfer(msg.sender, tokens);
            
            emit Transfer(address(0x0), msg.sender, tokens);
        }
    }
    
    function burnToken(uint _value) onlyOwner public
    {
        uint tokens = _value * E18;
        
        require(balances[msg.sender] >= tokens);
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        
        burnTokenSupply = burnTokenSupply.add(tokens);
        totalTokenSupply = totalTokenSupply.sub(tokens);
        
        emit Burn(msg.sender, tokens);
    }
    
    function close() onlyOwner public
    {
        selfdestruct(msg.sender);
    }
    
     
}