 

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

contract MEDIBEUToken is ERC20Interface, OwnerHelper
{
    using SafeMath for uint;
    
    string public name;
    uint public decimals;
    string public symbol;
    
    uint constant private E18 = 1000000000000000000;
    uint constant private month = 2592000;
    
     
    uint constant public maxTotalSupply =           1300000000 * E18;
    
     
    uint constant public maxSaleSupply =             340000000 * E18;
    
    uint constant public PublicSaleSupply =          10000000 * E18;
    uint constant public PrivateSaleSupply =         330000000 * E18;

     
    uint constant public maxMKTBDSupply =          245000000 * E18;

     
    uint constant public maxPartnerSupply =          130000000 * E18;

     
    uint constant public maxTechSupply =          195000000 * E18;

     
    uint constant public maxTeamSupply =          195000000 * E18;

     
    uint constant public maxRsvSupply =          130000000 * E18;

     
    uint constant public maxAdvSupply =          65000000 * E18;
       
    
     
    uint constant public TechVestingSupply           = 16250000 * E18;
    uint constant public TechVestingTime = 12;
    
    uint constant public TeamVestingSupply          = 195000000 * E18;
    uint constant public TeamVestingLockDate       = 24 * month;

    uint constant public RsvVestingSupply       = 130000000 * E18;
    uint constant public RsvVestingLockDate    = 12 * month;
    
    uint constant public AdvVestingSupply       = 65000000 * E18;
    uint constant public AdvVestingLockDate    = 6 * month;
    
    uint public totalTokenSupply;
    uint public tokenIssuedSale;
    uint public tokenIssuedMKTBD;
    uint public tokenIssuedPartner;
    uint public tokenIssuedTech;
    uint public tokenIssuedTeam;
    uint public tokenIssuedRsv;
    uint public tokenIssuedAdv;
    
    uint public burnTokenSupply;
    
    mapping (address => uint) public balances;
    mapping (address => mapping ( address => uint )) public approvals;
    
    uint public TeamVestingTime;
    uint public RsvVestingTime;
    uint public AdvVestingTime;
    
    mapping (uint => uint) public TechVestingTimer;
    mapping (uint => uint) public TechVestingBalances;
    
    bool public tokenLock = true;
    bool public saleTime = true;
    uint public endSaleTime = 0;
    
    event SaleIssue(address indexed _to, uint _tokens);
    event MKTBDIssue(address indexed _to, uint _tokens);
    event PartnerIssue(address indexed _to, uint _tokens);
    event TechIssue(address indexed _to, uint _tokens);
    event TeamIssue(address indexed _to, uint _tokens);
    event RsvIssue(address indexed _to, uint _tokens);
    event AdvIssue(address indexed _to, uint _tokens);
    
    event Burn(address indexed _from, uint _tokens);
    
    event TokenUnlock(address indexed _to, uint _tokens);
    event EndSale(uint _date);
    
    constructor() public
    {
        name        = "Medibeu";
        decimals    = 18;
        symbol      = "MDB";
        
        totalTokenSupply    = 0;
        
        tokenIssuedSale   = 0;
        tokenIssuedMKTBD   = 0;
        tokenIssuedPartner   = 0;
        tokenIssuedTech   = 0;
        tokenIssuedTeam    = 0;
        tokenIssuedRsv    = 0;
        tokenIssuedAdv     = 0;

        burnTokenSupply     = 0;
        
        require(maxTechSupply == TechVestingSupply.mul(TechVestingTime));
        require(maxTeamSupply == TeamVestingSupply);
        require(maxRsvSupply == RsvVestingSupply);
        require(maxAdvSupply == AdvVestingSupply);

        require(maxSaleSupply == PublicSaleSupply + PrivateSaleSupply);
        require(maxTotalSupply == maxSaleSupply + maxMKTBDSupply + maxPartnerSupply + maxTechSupply + maxTeamSupply + maxRsvSupply + maxAdvSupply);
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
    
       
     
    
    function teamIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        
        uint nowTime = now;
        require(nowTime > TeamVestingTime);
        
        uint tokens = TeamVestingSupply;

        require(maxTeamSupply >= tokenIssuedTeam.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedTeam = tokenIssuedTeam.add(tokens);
        
        emit TeamIssue(_to, tokens);
    }

    function rsvIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        
        uint nowTime = now;
        require(nowTime > RsvVestingTime);
        
        uint tokens = RsvVestingSupply;

        require(maxRsvSupply >= tokenIssuedRsv.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedRsv = tokenIssuedRsv.add(tokens);
        
        emit RsvIssue(_to, tokens);
    }

    function advIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        
        uint nowTime = now;
        require(nowTime > AdvVestingTime);
        
        uint tokens = AdvVestingSupply;

        require(maxAdvSupply >= tokenIssuedAdv.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedAdv = tokenIssuedAdv.add(tokens);
        
        emit AdvIssue(_to, tokens);
    }
    
     
    function techIssue(address _to, uint _time) onlyOwner public
    {
        require(saleTime == false);
        require(_time < TechVestingTime);
        
        uint nowTime = now;
        require( nowTime > TechVestingTimer[_time] );
        
        uint tokens = TechVestingSupply;

        require(tokens == TechVestingBalances[_time]);
        require(maxTechSupply >= tokenIssuedTech.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        TechVestingBalances[_time] = 0;
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedTech = tokenIssuedTech.add(tokens);
        
        emit TechIssue(_to, tokens);
    }
        
     

    function mktbdIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedMKTBD == 0);
        
        uint tokens = maxMKTBDSupply;
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedMKTBD = tokenIssuedMKTBD.add(tokens);
        
        emit MKTBDIssue(_to, tokens);
    }
    
    function partnerIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedPartner == 0);
        
        uint tokens = maxPartnerSupply;
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedPartner = tokenIssuedPartner.add(tokens);
        
        emit PartnerIssue(_to, tokens);
    }
       
    function PrivateSaleIssue(address _to) onlyOwner public
    {
        require(tokenIssuedSale == 0);
        
        uint tokens = PrivateSaleSupply;
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedSale = tokenIssuedSale.add(tokens);
        
        emit SaleIssue(_to, tokens);
    }
    
    function PublicSaleIssue(address _to) onlyOwner public
    {
        require(tokenIssuedSale == PrivateSaleSupply);
        
        uint tokens = PublicSaleSupply;
        
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
        
        TeamVestingTime = endSaleTime + TeamVestingLockDate;
        RsvVestingTime = endSaleTime + RsvVestingLockDate;
        AdvVestingTime = endSaleTime + AdvVestingLockDate;        

        for(uint i = 0; i < TechVestingTime; i++)
        {
            TechVestingTimer[i] =  endSaleTime + (month * i);
            TechVestingBalances[i] = TechVestingSupply;
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