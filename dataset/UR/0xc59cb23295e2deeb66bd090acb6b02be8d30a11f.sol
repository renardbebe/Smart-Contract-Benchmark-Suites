 

 

pragma solidity ^0.4.15;
 
contract Utils {
     
    function Utils() {
    }

     
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

     
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

     

     
    function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

 
contract IERC20Token {
     
    function name() public constant returns (string) { name; }
    function symbol() public constant returns (string) { symbol; }
    function decimals() public constant returns (uint8) { decimals; }
    function totalSupply() public constant returns (uint256) { totalSupply; }
    function balanceOf(address _owner) public constant returns (uint256 balance) { _owner; balance; }
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) { _owner; _spender; remaining; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}


 
contract ERC20Token is IERC20Token, Utils {
    string public standard = "Token 0.1";
    string public name = "";
    string public symbol = "";
    uint8 public decimals = 0;
    uint256 public totalSupply = 0;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function ERC20Token(string _name, string _symbol, uint8 _decimals) {
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0);  

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

     
    function transfer(address _to, uint256 _value)
        public
        validAddress(_to)
        returns (bool success)
    {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool success)
    {
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value)
        public
        validAddress(_spender)
        returns (bool success)
    {
         
        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

 
contract IOwned {
     
    function owner() public constant returns (address) { owner; }

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

 
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

     
    function Owned() {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

 
contract ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
}

 
contract TokenHolder is ITokenHolder, Owned, Utils {
     
    function TokenHolder() {
    }

     
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        assert(_token.transfer(_to, _amount));
    }
}


contract KUBToken is ERC20Token, TokenHolder {

 

    uint256 constant public KUB_UNIT = 10 ** 10;
    uint256 public totalSupply = 500 * (10**6) * KUB_UNIT;

     
    address public kublaiWalletOwner;                                             

     

    uint256 public totalAllocated = 0;                                            
    uint256 constant public endTime = 1509494340;                                 

    bool internal isReleasedToPublic = false;                          

    uint256 internal teamTranchesReleased = 0;                           
    uint256 internal maxTeamTranches = 8;                                

 

     
    modifier safeTimelock() {
        require(now >= endTime + 6 * 4 weeks);
        _;
    }

     
    modifier advisorTimelock() {
        require(now >= endTime + 2 * 4 weeks);
        _;
    }

    function KUBToken(address _kublaiWalletOwner)
    ERC20Token("kublaicoin", "KUB", 10)
     {
        kublaiWalletOwner = _kublaiWalletOwner;
         
         
         
         
         
    }


    function releaseApolloTokens(uint256 _value) safeTimelock ownerOnly returns(bool success) {
        uint256 apolloAmount = _value * KUB_UNIT;
        require(apolloAmount + totalAllocated < totalSupply);
        balanceOf[kublaiWalletOwner] = safeAdd(balanceOf[kublaiWalletOwner], apolloAmount);
        Transfer(0x0, kublaiWalletOwner, apolloAmount);
        totalAllocated = safeAdd(totalAllocated, apolloAmount);
        return true;
    }


    function allowTransfers() ownerOnly {
        isReleasedToPublic = true;
    }

    function isTransferAllowed() internal constant returns(bool) {
        if (now > endTime || isReleasedToPublic == true) {
            return true;
        }
        return false;
    }
}