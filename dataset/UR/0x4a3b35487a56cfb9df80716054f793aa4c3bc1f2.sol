 

 


pragma solidity ^0.4.18;

 

 
contract depositofferTokenConfig
{
     
    string public           name            = "USPat7376612 depositoffer";
    string public           symbol          = "DO";

     
     
    address public          owner           = 0xB353cF41A0CAa38D6597A7a1337debf0b09dd8ae;  
    
     
     
     
     address public           fundWallet      = 0x46FF7006F8EA5AD7570A84D7BE0ed78224D3ab5e;  
     
    
     
    
     
    uint public constant    TOKENS_PER_USD  = 2;

     
    uint public constant    USD_PER_ETH     = 380;  
    
     
    uint public constant    MIN_USD_FUND    = 1;   
    uint public constant    MAX_USD_FUND    = 2000000;  
    
     
    uint public constant    KYC_USD_LMT     = 50000;
    
     
     
    uint public constant    MAX_TOKENS      = 4000000;  
    
     
    
     
      uint public constant    START_DATE      = 1520776337;  
      
     
    uint public constant    FUNDING_PERIOD  = 180 days;
}


library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract ReentryProtected
{
     
    bool __reMutex;

     
    modifier preventReentry() {
        require(!__reMutex);
        __reMutex = true;
        _;
        delete __reMutex;
    }

     
    modifier noReentry() {
        require(!__reMutex);
        _;
    }
}

contract ERC20Token
{
    using SafeMath for uint;

 

     
    
 

     
    uint public totalSupply;
    
     
    string public symbol;
    
     
    mapping (address => uint) balances;
    
     
    mapping (address => mapping (address => uint)) allowed;

 

     
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _amount);

     
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount);

 

     
    
 

     
    function balanceOf(address _addr)
        public
        constant
        returns (uint)
    {
        return balances[_addr];
    }
    
     
    function allowance(address _owner, address _spender)
        public
        constant
        returns (uint)
    {
        return allowed[_owner][_spender];
    }

     
    function transfer(address _to, uint256 _amount)
        public
        returns (bool)
    {
        return xfer(msg.sender, _to, _amount);
    }

     
    function transferFrom(address _from, address _to, uint256 _amount)
        public
        returns (bool)
    {
        require(_amount <= allowed[_from][msg.sender]);
        
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        return xfer(_from, _to, _amount);
    }

     
    function xfer(address _from, address _to, uint _amount)
        internal
        returns (bool)
    {
        require(_amount <= balances[_from]);

        Transfer(_from, _to, _amount);
        
         
        if(_amount == 0) return true;
        
        balances[_from] = balances[_from].sub(_amount);
        balances[_to]   = balances[_to].add(_amount);
        
        return true;
    }

     
    function approve(address _spender, uint256 _amount)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
}



 

contract depositofferTokenAbstract
{
 

 
    event KYCAddress(address indexed _addr, bool indexed _kyc);

 
    event Refunded(address indexed _addr, uint indexed _value);

 
    event ChangedOwner(address indexed _from, address indexed _to);
    
 
    event ChangeOwnerTo(address indexed _to);

 
    event FundsTransferred(address indexed _wallet, uint indexed _value);


     
    bool public __abortFuse = true;
    
     
     
    bool public icoSuccessful;

     
    uint8 public constant decimals = 18;

     
    address public newOwner;
    
     
    address public deposito;
    
     
    uint public etherRaised;
    
     
     
    mapping (address => bool) public kycAddresses;
    
     
    mapping (address => uint) public etherContributed;

     
    function fundSucceeded() public constant returns (bool);
    
     
    function fundFailed() public constant returns (bool);

     
    function usdRaised() public constant returns (uint);

     
    function usdToEth(uint) public constant returns(uint);
    
     
    function ethToUsd(uint _wei) public constant returns (uint);

     
    function ethToTokens(uint _eth)
        public constant returns (uint);

     
    function proxyPurchase(address _addr) payable returns (bool);

     
    function finaliseICO() public returns (bool);
    
     
    function addKycAddress(address _addr, bool _kyc)
        public returns (bool);

     
    function refund(address _addr) public returns (bool);

     
    function abort() public returns (bool);
    
     
    function changedeposito(address _addr) public returns (bool);
    
     
    function transferAnyERC20Token(address tokenAddress, uint amount)
        returns (bool);
}


 

contract depositofferToken is 
    ReentryProtected,
    ERC20Token,
    depositofferTokenAbstract,
    depositofferTokenConfig
{
    using SafeMath for uint;

 
 
 

     
    uint public constant TOKENS_PER_ETH = TOKENS_PER_USD * USD_PER_ETH;
    uint public constant MIN_ETH_FUND   = 1 ether * MIN_USD_FUND / USD_PER_ETH;
    uint public constant MAX_ETH_FUND   = 1 ether * MAX_USD_FUND / USD_PER_ETH;
    uint public constant KYC_ETH_LMT    = 1 ether * KYC_USD_LMT  / USD_PER_ETH;

     
    uint public END_DATE  = START_DATE + FUNDING_PERIOD;

 
 
 

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

 
 
 

     
    function depositofferToken()
    {
         
         
        require(bytes(symbol).length > 0);
        require(bytes(name).length > 0);
        require(owner != 0x0);
        require(fundWallet != 0x0);
        require(TOKENS_PER_USD > 0);
        require(USD_PER_ETH > 0);
        require(MIN_USD_FUND > 0);
        require(MAX_USD_FUND > MIN_USD_FUND);
        require(START_DATE > 0);
        require(FUNDING_PERIOD > 0);
        
         
        totalSupply = MAX_TOKENS * 1e18;
        balances[fundWallet] = totalSupply;
        Transfer(0x0, fundWallet, totalSupply);
    }
    
     
    function ()
        payable
    {
         
         
        proxyPurchase(msg.sender);
    }

 
 
 

     
    function fundFailed() public constant returns (bool)
    {
        return !__abortFuse
            || (now > END_DATE && etherRaised < MIN_ETH_FUND);
    }
    
     
    function fundSucceeded() public constant returns (bool)
    {
        return !fundFailed()
            && etherRaised >= MIN_ETH_FUND;
    }

     
    function ethToUsd(uint _wei) public constant returns (uint)
    {
        return USD_PER_ETH.mul(_wei).div(1 ether);
    }
    
     
    function usdToEth(uint _usd) public constant returns (uint)
    {
        return _usd.mul(1 ether).div(USD_PER_ETH);
    }
    
     
    function usdRaised() public constant returns (uint)
    {
        return ethToUsd(etherRaised);
    }
    
     
    function ethToTokens(uint _wei) public constant returns (uint)
    {
        uint usd = ethToUsd(_wei);
        
         
        uint bonus = 0;
     
     
     
     
     
     
     
        
         
        return _wei.mul(TOKENS_PER_ETH).mul(bonus + 100).div(100);
    }

 
 
 

     
     
     
    function abort()
        public
        noReentry
        onlyOwner
        returns (bool)
    {
        require(!icoSuccessful);
        delete __abortFuse;
        return true;
    }
    
     
    function proxyPurchase(address _addr)
        payable
        noReentry
        returns (bool)
    {
        require(!fundFailed());
        require(!icoSuccessful);
        require(now <= END_DATE);
        require(msg.value > 0);
        
         
        if(!kycAddresses[_addr])
        {
            require(now >= START_DATE);
            require((etherContributed[_addr].add(msg.value)) <= KYC_ETH_LMT);
        }

         
        uint tokens = ethToTokens(msg.value);
        
         
        
        xfer(fundWallet, _addr, tokens);
        
         
        etherContributed[_addr] = etherContributed[_addr].add(msg.value);
        
         
        etherRaised = etherRaised.add(msg.value);
        
         
        require(etherRaised <= MAX_ETH_FUND);

        return true;
    }
    
     
    function addKycAddress(address _addr, bool _kyc)
    public
        noReentry
        onlyOwner
        returns (bool)
    {
       require(!fundFailed());

        kycAddresses[_addr] = _kyc;
        KYCAddress(_addr, _kyc);
      return true;
    }
    
     
     
     
     
 
    
    function finaliseICO()
        public
        onlyOwner
        preventReentry()
        returns (bool)
    {
        require(fundSucceeded());

        icoSuccessful = true;

        FundsTransferred(fundWallet, this.balance);
        fundWallet.transfer(this.balance);
        return true;
    }
    
     
    function refund(address _addr)
        public
        preventReentry()
        returns (bool)
    {
        require(fundFailed());
        
        uint value = etherContributed[_addr];

         
         
        xfer(_addr, fundWallet, balances[_addr]);

         
        delete etherContributed[_addr];
        delete kycAddresses[_addr];
        
        Refunded(_addr, value);
        if (value > 0) {
            _addr.transfer(value);
        }
        return true;
    }

 
 
 

    function transfer(address _to, uint _amount)
        public
        preventReentry
        returns (bool)
    {
         
        require(icoSuccessful);
        super.transfer(_to, _amount);

        if (_to == deposito)
             
            require(Notify(deposito).notify(msg.sender, _amount));
        return true;
    }

    function transferFrom(address _from, address _to, uint _amount)
        public
        preventReentry
        returns (bool)
    {
         
        require(icoSuccessful);
        super.transferFrom(_from, _to, _amount);

        if (_to == deposito)
             
            require(Notify(deposito).notify(msg.sender, _amount));
        return true;
    }
    
    function approve(address _spender, uint _amount)
        public
        noReentry
        returns (bool)
    {
         
        require(icoSuccessful);
        super.approve(_spender, _amount);
        return true;
    }

 
 
 

     
    function changeOwner(address _newOwner)
        public
        noReentry
        onlyOwner
        returns (bool)
    {
        ChangeOwnerTo(_newOwner);
        newOwner = _newOwner;
        return true;
    }

     
    function acceptOwnership()
        public
        noReentry
        returns (bool)
    {
        require(msg.sender == newOwner);
        ChangedOwner(owner, newOwner);
        owner = newOwner;
        return true;
    }

     
     
    function changedeposito(address _addr)
        public
        noReentry
        onlyOwner
        returns (bool)
    {
        deposito = _addr;
        return true;
    }
    
     
    function destroy()
        public
        noReentry
        onlyOwner
    {
        require(!__abortFuse);
        require(this.balance == 0);
        selfdestruct(owner);
    }
    
     
    function transferAnyERC20Token(address tokenAddress, uint amount)
        public
        onlyOwner
        preventReentry
        returns (bool) 
    {
        require(ERC20Token(tokenAddress).transfer(owner, amount));
        return true;
    }
}


interface Notify
{
    event Notified(address indexed _from, uint indexed _amount);
    
    function notify(address _from, uint _amount) public returns (bool);
}


contract depositoTest is Notify
{
    address public dot;
    
    function setdot(address _addr) { dot = _addr; }
    
    function notify(address _from, uint _amount) public returns (bool)
    {
        require(msg.sender == dot);
        Notified(_from, _amount);
        return true;
    }
}