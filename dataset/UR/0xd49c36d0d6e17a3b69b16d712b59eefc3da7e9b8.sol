 

 


pragma solidity ^0.4.17;

 
contract Hut34Config
{
     
    string  public constant name            = "Hut34 Entropy";
    
     
    string  public constant symbol          = "ENT";

     
    uint8   public constant decimals        = 18;

     
    uint    public constant TOTAL_TOKENS    = 100000000;

     
    address public constant OWNER           = 0xdA3780Cff2aE3a59ae16eC1734DEec77a7fd8db2;

     
    uint    public constant START_DATE      = 1509580800;

     
    address public constant HUT34_RETAIN    = 0x3135F4acA3C1Ad4758981500f8dB20EbDc5A1caB;
    
     
    address public constant HUT34_WALLET    = 0xA70d04dC4a64960c40CD2ED2CDE36D76CA4EDFaB;
    
     
    uint    public constant VESTED_PERCENT  = 20;

     
    uint    public constant VESTING_PERIOD  = 26 weeks;

     
    uint    public constant MIN_CAP         = 3000 * 1 ether;

     
     
    uint    public constant KYC_THRESHOLD   = 150 * 1 ether;

     
     
    uint    public constant WHOLESALE_THRESHOLD  = 150 * 1 ether;
    
     
    uint    public constant WHOLESALE_TOKENS = 12500000;

     
    uint    public constant PRESOLD_TOKENS  = 1817500;
    
     
     
    uint    public constant PRESALE_ETH_RAISE = 2190 * 1 ether;
    
     
    address public constant PRESOLD_ADDRESS = 0x6BF708eF2C1FDce3603c04CE9547AA6E134093b6;
    
     
    uint    public constant RATE_WHOLESALE  = 1000;

     
     
    uint    public constant RATE_DAY_0      = 750;

     
    uint    public constant RATE_DAY_1      = 652;

     
    uint    public constant RATE_DAY_7      = 588;

     
    uint    public constant RATE_DAY_14     = 545;

     
    uint    public constant RATE_DAY_21     = 517;

     
    uint    public constant RATE_DAY_28     = 500;
}


library SafeMath
{
     
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        assert(c >= a);
    }
    
     
    function sub(uint a, uint b) internal pure returns (uint c) {
        c = a - b;
        assert(c <= a);
    }
    
     
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        assert(a == 0 || c / a == b);
    }
    
     
    function div(uint a, uint b) internal pure returns (uint c) {
        assert(b != 0);
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
        view
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


 

contract Hut34ICOAbstract
{
     
     
     
    event Deposit(address indexed _from, uint _value);
    
     
     
     
     
    event Withdrawal(address indexed _from, address indexed _to, uint _value);

     
     
     
    event ChangedOwner(address indexed _from, address indexed _to);
    
     
     
    event ChangeOwnerTo(address indexed _to);
    
     
     
     
    event Kyc(address indexed _addr, bool _kyc);

     
     
     
    event VestingReleased(uint _releaseDate);
    
     
    event Aborted();

 
 
 

     
     
     
     
    address public constant HUT34_VEST_ADDR = address(bytes20("Hut34 Vesting"));

 
 
 

     
     
    bool public __abortFuse = true;
    
     
     
     
    bool public icoSucceeded;

     
     
    address public owner;
    
     
     
    address public newOwner;

     
     
    uint public etherRaised;
    
     
    uint public wholesaleLeft;
    
     
    uint public refunded;
    
     
    uint public nextReleaseDate;

     
    mapping (address => uint) public etherContributed;
    
     
    mapping (address => bool) public mustKyc;

 
 
 

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

 
 
 

     
    function fundRaised() public view returns (bool);
    
     
     
    function fundFailed() public view returns (bool);

     
    function currentRate() public view returns (uint);
    
     
     
     
    function ethToTokens(uint _wei)
        public view returns (uint allTokens_, uint wholesaleTokens_);

     
     
     
     
    function proxyPurchase(address _addr) public payable returns (bool);

     
     
    function finalizeICO() public returns (bool);

     
     
    function clearKyc(address[] _addrs) public returns (bool);
    
     
     
     
     
    function transferToMany(address[] _addrs, uint[] _amounts)
        public returns (bool);

     
     
    function releaseVested() public returns (bool);

     
     
    function refund() public returns (bool);
    
     
     
     
    function refundFor(address[] _addrs) public returns (bool);

     
    function abort() public returns (bool);

     
     
     
     
     
    function transferExternalToken(address _kAddr, address _to, uint _amount)
        public returns (bool);
}


 

contract Hut34ICO is 
    ReentryProtected,
    ERC20Token,
    Hut34ICOAbstract,
    Hut34Config
{
    using SafeMath for uint;

 
 
 

     
    uint constant TOKEN = uint(10)**decimals; 

     
    uint public constant VESTED_TOKENS =
            TOTAL_TOKENS * TOKEN * VESTED_PERCENT / 100;
            
     
    uint public constant RETAINED_TOKENS = TOKEN * TOTAL_TOKENS / 2;

     
    uint public constant END_DATE = START_DATE + 35 days;

     
     
    uint public constant COMMISSION_DIV = 67;

     
    address public constant COMMISSION_WALLET = 
        0x0065D506E475B5DBD76480bAFa57fe7C41c783af;

 
 
 

    function Hut34ICO()
        public
    {
         
        require(TOTAL_TOKENS != 0);
        require(OWNER != 0x0);
        require(HUT34_RETAIN != 0x0);
        require(HUT34_WALLET != 0x0);
        require(PRESOLD_TOKENS <= WHOLESALE_TOKENS);
        require(PRESOLD_TOKENS == 0 || PRESOLD_ADDRESS != 0x0);
        require(MIN_CAP != 0);
        require(START_DATE >= now);
        require(bytes(name).length != 0);
        require(bytes(symbol).length != 0);
        require(KYC_THRESHOLD != 0);
        require(RATE_DAY_0 >= RATE_DAY_1);
        require(RATE_DAY_1 >= RATE_DAY_7);
        require(RATE_DAY_7 >= RATE_DAY_14);
        require(RATE_DAY_14 >= RATE_DAY_21);
        require(RATE_DAY_21 >= RATE_DAY_28);
        
        owner = OWNER;
        totalSupply = TOTAL_TOKENS.mul(TOKEN);
        wholesaleLeft = WHOLESALE_TOKENS.mul(TOKEN);
        uint presold = PRESOLD_TOKENS.mul(TOKEN);
        wholesaleLeft = wholesaleLeft.sub(presold);

         
        etherRaised = PRESALE_ETH_RAISE;

         
        balances[HUT34_RETAIN] = totalSupply;
        Transfer(0x0, HUT34_RETAIN, totalSupply);

         
        balances[HUT34_RETAIN] = balances[HUT34_RETAIN].sub(VESTED_TOKENS);
        balances[HUT34_VEST_ADDR] = balances[HUT34_VEST_ADDR].add(VESTED_TOKENS);
        Transfer(HUT34_RETAIN, HUT34_VEST_ADDR, VESTED_TOKENS);

         
        balances[HUT34_RETAIN] = balances[HUT34_RETAIN].sub(presold);
        balances[PRESOLD_ADDRESS] = balances[PRESOLD_ADDRESS].add(presold);
        Transfer(HUT34_RETAIN, PRESOLD_ADDRESS, presold);
    }

     
    function ()
        public
        payable
    {
         
         
        proxyPurchase(msg.sender);
    }

 
 
 

     
    function fundFailed() public view returns (bool)
    {
        return !__abortFuse
            || (now > END_DATE && etherRaised < MIN_CAP);
    }
    
     
    function fundRaised() public view returns (bool)
    {
        return !fundFailed()
            && etherRaised >= MIN_CAP
            && now > START_DATE;
    }

     
    function wholeSaleValueLeft() public view returns (uint)
    {
        return wholesaleLeft / RATE_WHOLESALE;
    }

    function currentRate()
        public
        view
        returns (uint)
    {
        return
            fundFailed() ? 0 :
            icoSucceeded ? 0 :
            now < START_DATE ? 0 :
            now < START_DATE + 1 days ? RATE_DAY_0 :
            now < START_DATE + 7 days ? RATE_DAY_1 :
            now < START_DATE + 14 days ? RATE_DAY_7 :
            now < START_DATE + 21 days ? RATE_DAY_14 :
            now < START_DATE + 28 days ? RATE_DAY_21 :
            now < END_DATE ? RATE_DAY_28 :
            0;
    }
    
     
     
    function ethToTokens(uint _wei)
        public
        view
        returns (uint allTokens_, uint wholesaleTokens_)
    {
         
        uint wsValueLeft = wholeSaleValueLeft();
        uint wholesaleSpend = 
                fundFailed() ? 0 :
                icoSucceeded ? 0 :
                now < START_DATE ? 0 :
                now > END_DATE ? 0 :
                 
                _wei < WHOLESALE_THRESHOLD ? 0 :
                 
                _wei < wsValueLeft ?  _wei :
                 
                wsValueLeft;
        
        wholesaleTokens_ = wholesaleSpend
                .mul(RATE_WHOLESALE)
                .mul(TOKEN)
                .div(1 ether);

         
        _wei = _wei.sub(wholesaleSpend);

         
        uint saleRate = currentRate();

        allTokens_ = _wei
                .mul(saleRate)
                .mul(TOKEN)
                .div(1 ether)
                .add(wholesaleTokens_);
    }

 
 
 

     
     
     
     
    function abort()
        public
        noReentry
        returns (bool)
    {
        require(!icoSucceeded);
        require(msg.sender == owner || now > END_DATE  + 14 days);
        delete __abortFuse;
        Aborted();
        return true;
    }
    
     
    function proxyPurchase(address _addr)
        public
        payable
        noReentry
        returns (bool)
    {
        require(!fundFailed());
        require(!icoSucceeded);
        require(now > START_DATE);
        require(now <= END_DATE);
        require(msg.value > 0);
        
         
        Deposit (_addr, msg.value);
        
         
        uint tokens;
         
        uint wholesaleTokens;

        (tokens, wholesaleTokens) = ethToTokens(msg.value);

         
        require(tokens > 0);

         
        require(balances[HUT34_RETAIN] - tokens >= RETAINED_TOKENS);

         
        if (wholesaleTokens != 0) {
            wholesaleLeft = wholesaleLeft.sub(wholesaleTokens);
        }
        
         
        balances[HUT34_RETAIN] = balances[HUT34_RETAIN].sub(tokens);
        balances[_addr] = balances[_addr].add(tokens);
        Transfer(HUT34_RETAIN, _addr, tokens);

         
        etherRaised = etherRaised.add(msg.value);

         
        etherContributed[_addr] = etherContributed[_addr].add(msg.value);

         
        if(etherContributed[_addr] >= KYC_THRESHOLD && !mustKyc[_addr]) {
            mustKyc[_addr] = true;
            Kyc(_addr, true);
        }

        return true;
    }
    
     
     
     
     
    function finalizeICO()
        public
        onlyOwner
        preventReentry()
        returns (bool)
    {
         
        require(fundRaised());

         
        if(!icoSucceeded) {
            nextReleaseDate = now + VESTING_PERIOD;
        }

         
        icoSucceeded = true;
        
         
        uint devCommission = calcCommission();
        Withdrawal(this, COMMISSION_WALLET, devCommission);
        COMMISSION_WALLET.transfer(devCommission);

         
        Withdrawal(this, HUT34_WALLET, this.balance);
        HUT34_WALLET.transfer(this.balance);
        return true;
    }

    function clearKyc(address[] _addrs)
        public
        noReentry
        onlyOwner
        returns (bool)
    {
        uint len = _addrs.length;
        for(uint i; i < len; i++) {
            delete mustKyc[_addrs[i]];
            Kyc(_addrs[i], false);
        }
        return true;
    }

     
    function releaseVested()
        public
        returns (bool)
    {
        require(now > nextReleaseDate);
        VestingReleased(nextReleaseDate);
        nextReleaseDate = nextReleaseDate.add(VESTING_PERIOD);
        return xfer(HUT34_VEST_ADDR, HUT34_RETAIN, VESTED_TOKENS / 4);
    }

     
    function refund()
        public
        returns (bool)
    {
        address[] memory addrs = new address[](1);
        addrs[0] = msg.sender;
        return refundFor(addrs);
    }
    
     
    function refundFor(address[] _addrs)
        public
        preventReentry()
        returns (bool)
    {
        require(fundFailed());
        uint i;
        uint len = _addrs.length;
        uint value;
        uint tokens;
        address addr;
        
        for (i; i < len; i++) {
            addr = _addrs[i];
            value = etherContributed[addr];
            tokens = balances[addr];
            if (tokens > 0) {    
                 
                 
                balances[HUT34_RETAIN] = balances[HUT34_RETAIN].add(tokens);
                delete balances[addr];
                Transfer(addr, HUT34_RETAIN, tokens);
            }
    
            if (value > 0) {
                 
                delete etherContributed[addr];
                delete mustKyc[addr];
                refunded = refunded.add(value);
                Withdrawal(this, addr, value);
                addr.transfer(value);
            }
        }
        return true;
    }

 
 
 

     
    function transferToMany(address[] _addrs, uint[] _amounts)
        public
        noReentry
        returns (bool)
    {
        require(_addrs.length == _amounts.length);
        uint len = _addrs.length;
        for(uint i = 0; i < len; i++) {
            xfer(msg.sender, _addrs[i], _amounts[i]);
        }
        return true;
    }
    
     
    function xfer(address _from, address _to, uint _amount)
        internal
        noReentry
        returns (bool)
    {
        require(icoSucceeded);
        require(!mustKyc[_from]);
        super.xfer(_from, _to, _amount);
        return true;
    }

     
    function approve(address _spender, uint _amount)
        public
        noReentry
        returns (bool)
    {
         
        require(icoSucceeded);
        super.approve(_spender, _amount);
        return true;
    }

 
 
 

     
    function changeOwner(address _owner)
        public
        onlyOwner
        returns (bool)
    {
        ChangeOwnerTo(_owner);
        newOwner = _owner;
        return true;
    }
    
     
    function acceptOwnership()
        public
        returns (bool)
    {
        require(msg.sender == newOwner);
        ChangedOwner(owner, msg.sender);
        owner = newOwner;
        delete newOwner;
        return true;
    }

     
     
    function destroy()
        public
        noReentry
        onlyOwner
    {
        require(!__abortFuse);
        require(refunded == (etherRaised - PRESALE_ETH_RAISE));
         
        Transfer(HUT34_RETAIN, 0x0, balances[HUT34_RETAIN]);
        Transfer(HUT34_VEST_ADDR, 0x0, VESTED_TOKENS);
        Transfer(PRESOLD_ADDRESS, 0x0, PRESOLD_TOKENS);
         
        delete balances[HUT34_RETAIN];
        delete balances[PRESOLD_ADDRESS];
        selfdestruct(owner);
    }
    
     
    function transferExternalToken(address _kAddr, address _to, uint _amount)
        public
        onlyOwner
        preventReentry
        returns (bool) 
    {
        require(ERC20Token(_kAddr).transfer(_to, _amount));
        return true;
    }
    
     
    function calcCommission()
        internal
        view
        returns(uint)
    {
        uint commission = (this.balance + PRESALE_ETH_RAISE) / COMMISSION_DIV;
         
        return commission <= this.balance ? commission : this.balance;
    }
}