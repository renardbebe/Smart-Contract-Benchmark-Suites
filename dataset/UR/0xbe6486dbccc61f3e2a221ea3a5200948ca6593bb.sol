 

pragma solidity ^0.4.13;

contract ERC20 {
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

contract StandardToken is ERC20, SafeMath {

   
  event Minted(address receiver, uint amount);

   
  mapping(address => uint) balances;

   
  mapping (address => mapping (address => uint)) allowed;

   
  function isToken() public constant returns (bool Yes) {
    return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _address) constant returns (uint balance) {
    return balances[_address];
  }

  function approve(address _spender, uint _value) returns (bool success) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract DESToken is StandardToken {

    string public name = "Decentralized Escrow Service";
    string public symbol = "DES";
    uint public decimals = 18; 
	uint public HardCapEthereum = 66666000000000000000000 wei; 
    
     
    mapping (address => bool) public noTransfer;
	
	 
	uint constant public TimeStart = 1511956800; 
	uint public TimeEnd = 1514375999; 
	
	 
	uint public TimeWeekOne = 1512561600; 
	uint public TimeWeekTwo = 1513166400; 
	uint public TimeWeekThree = 1513771200; 
    
	uint public TimeTransferAllowed = 1516967999; 
	
	 
	uint public PoolPreICO = 0; 
	uint public PoolICO = 0; 
	uint public PoolTeam = 0; 
	uint public PoolAdvisors = 0; 
	uint public PoolBounty = 0; 
	    
	 
	uint public PriceWeekOne = 1000000000000000 wei; 
	uint public PriceWeekTwo = 1250000000000000 wei; 
	uint public PriceWeekThree = 1500000000000000 wei; 
	uint public PriceWeekFour = 1750000000000000 wei; 
	uint public PriceManual = 0 wei; 
	
	 
    bool public ICOPaused = false;  
    bool public ICOFinished = false;  
	
     
	uint public StatsEthereumRaised = 0 wei; 
	uint public StatsTotalSupply = 0; 

     
    event Buy(address indexed sender, uint eth, uint fbt); 
    event TokensSent(address indexed to, uint value); 
    event ContributionReceived(address indexed to, uint value); 
    event PriceChanged(string _text, uint _tokenPrice); 
    event TimeEndChanged(string _text, uint _timeEnd); 
    event TimeTransferAllowanceChanged(string _text, uint _timeAllowance); 
 
    
    address public owner = 0x0; 
    address public wallet = 0x0; 
 
function DESToken(address _owner, address _wallet) payable {
        
      owner = _owner;
      wallet = _wallet;
    
      balances[owner] = 0;
      balances[wallet] = 0;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

	 
    modifier isActive() {
        require(!ICOPaused);
        _;
    }

     
    function() payable {
        buy();
    }
    
     
    function setTokenPrice(uint _tokenPrice) external onlyOwner {
        PriceManual = _tokenPrice;
        PriceChanged("New price is ", _tokenPrice);
    }
    
     
    function setTimeEnd(uint _timeEnd) external onlyOwner {
        TimeEnd = _timeEnd;
        TimeEndChanged("New ICO End Time is ", _timeEnd);
    }
    
     
 
 
 
 
     
     
    function setTimeTransferAllowance(uint _timeAllowance) external onlyOwner {
        TimeTransferAllowed = _timeAllowance;
        TimeTransferAllowanceChanged("Token transfers will be allowed at ", _timeAllowance);
    }
    
     
     
     
    function disallowTransfer(address target, bool disallow) external onlyOwner {
        noTransfer[target] = disallow;
    }
    
     
    function finishCrowdsale() external onlyOwner returns (bool) {
        if (ICOFinished == false) {
            
            PoolTeam = StatsTotalSupply*15/100; 
            PoolAdvisors = StatsTotalSupply*7/100; 
            PoolBounty = StatsTotalSupply*3/100; 
            
            uint poolTokens = 0;
            poolTokens = safeAdd(poolTokens,PoolTeam);
            poolTokens = safeAdd(poolTokens,PoolAdvisors);
            poolTokens = safeAdd(poolTokens,PoolBounty);
            
             
            require(poolTokens>0); 
            balances[owner] = safeAdd(balances[owner], poolTokens);
            StatsTotalSupply = safeAdd(StatsTotalSupply, poolTokens); 
            Transfer(0, this, poolTokens);
            Transfer(this, owner, poolTokens);
                        
            ICOFinished = true; 
            
            }
        }

     
    function price() constant returns (uint) {
        if(PriceManual > 0){return PriceManual;}
        if(now >= TimeStart && now < TimeWeekOne){return PriceWeekOne;}
        if(now >= TimeWeekOne && now < TimeWeekTwo){return PriceWeekTwo;}
        if(now >= TimeWeekTwo && now < TimeWeekThree){return PriceWeekThree;}
        if(now >= TimeWeekThree){return PriceWeekFour;}
    }
    
     
     
     
    function sendPreICOTokens(address target, uint amount) onlyOwner external {
        
        require(amount>0); 
        balances[target] = safeAdd(balances[target], amount);
        StatsTotalSupply = safeAdd(StatsTotalSupply, amount); 
        Transfer(0, this, amount);
        Transfer(this, target, amount);
        
        PoolPreICO = safeAdd(PoolPreICO,amount); 
    }
    
     
     
     
    function sendICOTokens(address target, uint amount) onlyOwner external {
        
        require(amount>0); 
        balances[target] = safeAdd(balances[target], amount);
        StatsTotalSupply = safeAdd(StatsTotalSupply, amount); 
        Transfer(0, this, amount);
        Transfer(this, target, amount);
        
        PoolICO = safeAdd(PoolICO,amount); 
    }
    
     
     
     
    function sendTeamTokens(address target, uint amount) onlyOwner external {
        
        require(ICOFinished); 
        require(amount>0); 
        require(amount>=PoolTeam); 
        require(balances[owner]>=PoolTeam); 
        
        balances[owner] = safeSub(balances[owner], amount); 
        balances[target] = safeAdd(balances[target], amount); 
        PoolTeam = safeSub(PoolTeam, amount); 
        TokensSent(target, amount); 
        Transfer(owner, target, amount); 
        
        noTransfer[target] = true; 
    }
    
     
     
     
    function sendAdvisorsTokens(address target, uint amount) onlyOwner external {
        
        require(ICOFinished); 
        require(amount>0); 
        require(amount>=PoolAdvisors); 
        require(balances[owner]>=PoolAdvisors); 
        
        balances[owner] = safeSub(balances[owner], amount); 
        balances[target] = safeAdd(balances[target], amount); 
        PoolAdvisors = safeSub(PoolAdvisors, amount); 
        TokensSent(target, amount); 
        Transfer(owner, target, amount); 
        
        noTransfer[target] = true; 
    }
    
     
     
     
    function sendBountyTokens(address target, uint amount) onlyOwner external {
        
        require(ICOFinished); 
        require(amount>0); 
        require(amount>=PoolBounty); 
        require(balances[owner]>=PoolBounty); 
        
        balances[owner] = safeSub(balances[owner], amount); 
        balances[target] = safeAdd(balances[target], amount); 
        PoolBounty = safeSub(PoolBounty, amount); 
        TokensSent(target, amount); 
        Transfer(owner, target, amount); 
        
        noTransfer[target] = true; 
    }

     
    function buy() public payable returns(bool) {

        require(msg.sender != owner); 
        require(msg.sender != wallet); 
        require(!ICOPaused); 
        require(!ICOFinished); 
        require(msg.value >= price()); 
        require(now >= TimeStart); 
        require(now <= TimeEnd); 
        uint tokens = msg.value/price(); 
        require(safeAdd(StatsEthereumRaised, msg.value) <= HardCapEthereum); 
        
        require(tokens>0); 
        
        wallet.transfer(msg.value); 
        
         
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        StatsTotalSupply = safeAdd(StatsTotalSupply, tokens); 
        Transfer(0, this, tokens);
        Transfer(this, msg.sender, tokens);
        
        StatsEthereumRaised = safeAdd(StatsEthereumRaised, msg.value); 
        PoolICO = safeAdd(PoolICO, tokens); 
        
         
        Buy(msg.sender, msg.value, tokens);
        TokensSent(msg.sender, tokens);
        ContributionReceived(msg.sender, msg.value);

        return true;
    }
    
    function EventEmergencyStop() onlyOwner() {ICOPaused = true;} 
    function EventEmergencyContinue() onlyOwner() {ICOPaused = false;} 

     
    function transfer(address _to, uint _value) isActive() returns (bool success) {
        
    if(now >= TimeTransferAllowed){
        if(noTransfer[msg.sender]){noTransfer[msg.sender] = false;} 
    }
        
    if(now < TimeTransferAllowed){require(!noTransfer[msg.sender]);} 
        
    return super.transfer(_to, _value);
    }
     
    function transferFrom(address _from, address _to, uint _value) isActive() returns (bool success) {
        
    if(now >= TimeTransferAllowed){
        if(noTransfer[msg.sender]){noTransfer[msg.sender] = false;} 
    }
        
    if(now < TimeTransferAllowed){require(!noTransfer[msg.sender]);} 
        
        return super.transferFrom(_from, _to, _value);
    }

     
    function changeOwner(address _to) onlyOwner() {
        balances[_to] = balances[owner];
        balances[owner] = 0;
        owner = _to;
    }

     
    function changeWallet(address _to) onlyOwner() {
        balances[_to] = balances[wallet];
        balances[wallet] = 0;
        wallet = _to;
    }
}