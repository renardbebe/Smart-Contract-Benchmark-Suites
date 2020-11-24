 

 


pragma solidity ^0.4.17;


contract TestyTestConfig
{
     
    string  public constant name            = "TESTY";

     
    string  public constant symbol          = "TST";

     
    address public constant OWNER           = 0x8579A678Fc76cAe308ca280B58E2b8f2ddD41913;

     
    uint    public constant TOTAL_TOKENS    = 100;

     
    uint8   public constant decimals        = 18;


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

        emit Transfer(_from, _to, _amount);

         
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
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
}



contract TestyTestAbstract
{

     
     
     
    event ChangedOwner(address indexed _from, address indexed _to);

     
     
    event ChangeOwnerTo(address indexed _to);

     
     
     
    event Kyc(address indexed _addr, bool _kyc);

 
 

     
     
    address public owner;

     
     
    address public newOwner;

     
    mapping (address => bool) public clearedKyc;

 
 
 

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

 
 
 


     
     
    function clearKyc(address[] _addrs) public returns (bool);

     
     
     
     
    function transferToMany(address[] _addrs, uint[] _amounts)
        public returns (bool);

     
     
     
     
     
    function transferExternalToken(address _kAddr, address _to, uint _amount)
        public returns (bool);
}


 

contract TestyTest is
    ReentryProtected,
    ERC20Token,
    TestyTestAbstract,
    TestyTestConfig
{
    using SafeMath for uint;

 
 
 

     
    uint constant TOKEN = uint(10)**decimals;


 
 
 

    function TestyTest()
        public
    {

        owner = OWNER;
        totalSupply = TOTAL_TOKENS.mul(TOKEN);

    }

     
    function ()
        public
        payable
    {
         
    }


 
 
 

event LowerSupply(address indexed burner, uint256 value);
event IncreaseSupply(address indexed burner, uint256 value);

     

    function lowerSupply(uint256 _value)
        public
        onlyOwner
        preventReentry() {
            require(_value > 0);
            address burner = 0x41CaE184095c5DAEeC5B2b2901D156a029B3dAC6;
            balances[burner] = balances[burner].sub(_value);
            totalSupply = totalSupply.sub(_value);
            emit LowerSupply(msg.sender, _value);
    }

    function increaseSupply(uint256 _value)
        public
        onlyOwner
        preventReentry() {
            require(_value > 0);
            totalSupply = totalSupply.add(_value);
            emit IncreaseSupply(msg.sender, _value);
    }

 
 
 

    function clearKyc(address[] _addrs)
        public
        noReentry
        onlyOwner
        returns (bool)
    {
        uint len = _addrs.length;
        for(uint i; i < len; i++) {
            clearedKyc[_addrs[i]] = true;
            emit Kyc(_addrs[i], true);
        }
        return true;
    }

 
 
 

    function requireKyc(address[] _addrs)
        public
        noReentry
        onlyOwner
        returns (bool)
    {
        uint len = _addrs.length;
        for(uint i; i < len; i++) {
            delete clearedKyc[_addrs[i]];
            emit Kyc(_addrs[i], false);
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
        super.xfer(_from, _to, _amount);
        return true;
    }

 
 
 

     
    function changeOwner(address _owner)
        public
        onlyOwner
        returns (bool)
    {
        emit ChangeOwnerTo(_owner);
        newOwner = _owner;
        return true;
    }

     
    function acceptOwnership()
        public
        returns (bool)
    {
        require(msg.sender == newOwner);
        emit ChangedOwner(owner, msg.sender);
        owner = newOwner;
        delete newOwner;
        return true;
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


}