 

 

pragma solidity ^0.4.17;


contract TRUConfig
{
     
    string  public constant name            = "Trullion-e";

     
    string  public constant symbol          = "Tru-e";

     
    address public constant OWNER = 0x262f01741f2b6e6fda97bce85a6756a89c099e43;

     
    address public constant ADMIN_TOO  = 0x262f01741f2b6e6fda97bce85a6756a89c099e43;

     
    uint    public constant TOTAL_TOKENS    = 0 ;

     
    uint8   public constant decimals        = 8;


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

     
    function currentSupply()
        public
        view
        returns (uint)
    {
        return totalSupply;
    }


     
    function allowance(address _owner, address _spender)
        public
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



contract TRUAbstract
{

     
     
     
    event ChangedOwner(address indexed _from, address indexed _to);

     
     
    event ChangeOwnerTo(address indexed _to);

     
     
     
    event ChangedAdminToo(address indexed _from, address indexed _to);

     
     
    event ChangeAdminToo(address indexed _to);

 
 
     
     
    address public owner;

     
     
    address public newOwner;

     
     
    address public adminToo;

     
     
    address public newAdminToo;

 
 
 

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

 
 
 


     
     
     
     
 
    function transferToMany(address[] _addrs, uint[] _amounts)
        public returns (bool);

     
     
     
     
     
    function transferExternalToken(address _kAddr, address _to, uint _amount)
        public returns (bool);
}


 

contract TRU is
    ReentryProtected,
    ERC20Token,
   TRUAbstract,
   TRUConfig
{
    using SafeMath for uint;

 
 
 

     
    uint constant TOKEN = uint(10)**decimals;


 
 
 

    constructor()
        public
    {

        owner = OWNER;
        adminToo = ADMIN_TOO;
        totalSupply = TOTAL_TOKENS.mul(TOKEN);
        balances[owner] = totalSupply;

    }

     
    function ()
        public
        payable
    {
         
    }


 
 
 

event DecreaseSupply(address indexed burner, uint256 value);
event IncreaseSupply(address indexed burner, uint256 value);

     

    function decreaseSupply(uint256 _value)
        public
        onlyOwner {
            require(_value > 0);
            address burner = adminToo;
            balances[burner] = balances[burner].sub(_value);
            totalSupply = totalSupply.sub(_value);
            emit DecreaseSupply(msg.sender, _value);
    }

    function increaseSupply(uint256 _value)
        public
        onlyOwner {
            require(_value > 0);
            totalSupply = totalSupply.add(_value);
            balances[owner] = balances[owner].add(_value);
            emit IncreaseSupply(msg.sender, _value);
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

     
    function changeAdminToo(address _adminToo)
        public
        onlyOwner
        returns (bool)
    {
        emit ChangeAdminToo(_adminToo);
        newAdminToo = _adminToo;
        return true;
    }

     
    function acceptAdminToo()
        public
        returns (bool)
    {
        require(msg.sender == newAdminToo);
        emit ChangedAdminToo(adminToo, msg.sender);
        adminToo = newAdminToo;
        delete newAdminToo;
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