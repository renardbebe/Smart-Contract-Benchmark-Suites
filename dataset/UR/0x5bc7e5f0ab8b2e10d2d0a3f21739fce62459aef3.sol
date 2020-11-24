 

 

pragma solidity ^0.4.17;

contract Hut34Config
{
     
    string  public constant name            = "Hut34 Entropy Token";
    
     
    string  public constant symbol          = "ENTRP";

     
    uint8   public constant decimals        = 18;

     
    uint    public constant TOTAL_TOKENS    = 100000000;

     
    address public constant OWNER           = 0xdA3780Cff2aE3a59ae16eC1734DEec77a7fd8db2;

     
    address public constant HUT34_RETAIN    = 0x3135F4acA3C1Ad4758981500f8dB20EbDc5A1caB;
    
     
    address public constant HUT34_WALLET    = 0xA70d04dC4a64960c40CD2ED2CDE36D76CA4EDFaB;
    
     
    uint    public constant VESTED_PERCENT  = 20;

     
    uint    public constant VESTING_PERIOD  = 26 weeks;

     
    address public constant REPLACES        = 0x9901ed1e649C4a77C7Fff3dFd446ffE3464da747;
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


contract Hut34ENTRPAbstract
{
     
     
     
    event ChangedOwner(address indexed _from, address indexed _to);
    
     
     
    event ChangeOwnerTo(address indexed _to);
    
     
     
     
    event VestingReleased(uint _releaseDate);

 
 
 

     
     
     
     
    address public constant HUT34_VEST_ADDR = address(bytes20("Hut34 Vesting"));

 
 
 

     
     
    address public owner;
    
     
     
    address public newOwner;

     
    uint public nextReleaseDate;

 
 
 

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

 
 
 


     
     
     
     
    function transferToMany(address[] _addrs, uint[] _amounts)
        public returns (bool);

     
     
    function releaseVested() public returns (bool);

     
     
     
     
     
    function transferExternalToken(address _kAddr, address _to, uint _amount)
        public returns (bool);
}


 

contract Hut34ENTRP is 
    ERC20Token,
    Hut34ENTRPAbstract,
    Hut34Config
{
    using SafeMath for uint;

 
 
 

     
    uint constant TOKEN = uint(10)**decimals; 

     
    uint public constant VESTED_TOKENS =
            TOTAL_TOKENS * TOKEN * VESTED_PERCENT / 100;
            
 
 
 

    function Hut34ENTRP()
        public
    {
         
        require(TOTAL_TOKENS != 0);
        require(OWNER != 0x0);
        require(HUT34_RETAIN != 0x0);
        require(HUT34_WALLET != 0x0);
        require(bytes(name).length != 0);
        require(bytes(symbol).length != 0);

        owner = OWNER;
        totalSupply = TOTAL_TOKENS.mul(TOKEN);

         
        balances[HUT34_RETAIN] = totalSupply;
        Transfer(0x0, HUT34_RETAIN, totalSupply);

         
        xfer(HUT34_RETAIN, HUT34_VEST_ADDR, VESTED_TOKENS);

         
        nextReleaseDate = now.add(VESTING_PERIOD);
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

 
 
 

     
    function transferToMany(address[] _addrs, uint[] _amounts)
        public
        returns (bool)
    {
        require(_addrs.length == _amounts.length);
        uint len = _addrs.length;
        for(uint i = 0; i < len; i++) {
            xfer(msg.sender, _addrs[i], _amounts[i]);
        }
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

     
    function transferExternalToken(address _kAddr, address _to, uint _amount)
        public
        onlyOwner
        returns (bool) 
    {
        require(ERC20Token(_kAddr).transfer(_to, _amount));
        return true;
    }
}