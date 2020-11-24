 

 
 
 
 
 
 
 
 
 
 
 
 

pragma solidity ^0.4.25;

contract ERC20ext
{
     
    function totalSupply() public constant returns (uint supply);
    function balanceOf(address who) public constant returns (uint value);
    function allowance(address owner, address spender) public constant returns (uint _allowance);

    function transfer(address to, uint value) public returns (bool ok);
    function transferFrom(address from, address to, uint value) public returns (bool ok);
    function approve(address spender, uint value) public returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

     
    function setCtrlToken(address newToken) public returns (bool ok);
    function approveAuto(address spender, uint value ) public returns (bool ok);

    function appointNewCFO(address newCFO) public returns (bool ok);
    function melt(address dst, uint256 wad) public returns (bool ok);
    function mint(address dst, uint256 wad) public returns (bool ok);
    function freeze(address dst, bool flag) public returns (bool ok);

    event MeltEvent(address indexed dst, uint256 wad);
    event MintEvent(address indexed dst, uint256 wad);
    event FreezeEvent(address indexed dst, bool flag);
}

 
 
 
contract SafeMath
{
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c)
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c)
    {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
 
 
contract atToken is ERC20ext,SafeMath
{
    string public name;
    string public symbol;
    uint8  public decimals = 18;

     
    address _token;

    address _cfo;
    uint256 _supply;

     
    mapping (address => uint256) _balances;

     
    mapping (address => mapping (address => uint256)) _allowance;

     
    mapping (address => bool) public _frozen;

     
     
     
     
     
     
     
    constructor(uint256 initialSupply,string tokenName,string tokenSymbol) public
    {
         
        require(bytes(tokenName).length > 0 && bytes(tokenSymbol).length > 0);

        _token  = msg.sender;
        _cfo    = msg.sender;

        _supply = initialSupply * 10 ** uint256(decimals);
        _balances[_cfo] = _supply;

        name   = tokenName;
        symbol = tokenSymbol;
    }

     
     
     
    modifier onlyCFO()
    {
        require(msg.sender == _cfo);
        _;
    }

     
     
     
    modifier onlyCtrlToken()
    {
        require(msg.sender == _token);
        _;
    }

     
     
     
    function totalSupply() public constant returns (uint256)
    {
        return _supply;
    }

     
     
     
     
     
    function balanceOf(address src) public constant returns (uint256)
    {
        return _balances[src];
    }

     
     
     
     
     
     
    function allowance(address src, address dst) public constant returns (uint256)
    {
        return _allowance[src][dst];
    }

     
     
     
     
     
     
    function transfer(address dst, uint wad) public returns (bool)
    {
         
        require(!_frozen[msg.sender]);
        require(!_frozen[dst]);

         
        require(_balances[msg.sender] >= wad);

        _balances[msg.sender] = sub(_balances[msg.sender],wad);
        _balances[dst]        = add(_balances[dst], wad);

        emit Transfer(msg.sender, dst, wad);

        return true;
    }


     
     
     
     
     
     
     
    function transferFrom(address src, address dst, uint wad) public returns (bool)
    {
         
        require(!_frozen[msg.sender]);
        require(!_frozen[dst]);

         
        require(_balances[src] >= wad);

         
        require(_allowance[src][msg.sender] >= wad);

        _allowance[src][msg.sender] = sub(_allowance[src][msg.sender],wad);

        _balances[src] = sub(_balances[src],wad);
        _balances[dst] = add(_balances[dst],wad);

         
        emit Transfer(src, dst, wad);

        return true;
    }

     
     
     
     
     
     
    function approve(address dst, uint256 wad) public returns (bool)
    {
        _allowance[msg.sender][dst] = wad;

         
        emit Approval(msg.sender, dst, wad);
        return true;
    }

     
     
     
     
     
     
    function approveAuto(address src, uint256 wad) onlyCtrlToken public returns (bool)
    {
        _allowance[src][msg.sender] = wad;
        return true;
    }

     
     
     
     
     
    function setCtrlToken(address NewToken) onlyCFO public returns (bool)
    {
        if (NewToken != _token)
        {
            _token = NewToken;
            return true;
        }
        else
        {
            return false;
        }
    }

     
     
     
     
     
    function appointNewCFO(address newCFO) onlyCFO public returns (bool)
    {
        if (newCFO != _cfo)
        {
            _cfo = newCFO;
            return true;
        }
        else
        {
            return false;
        }
    }

     
     
     
     
     
     
    function freeze(address dst, bool flag) onlyCFO public returns (bool)
    {
        _frozen[dst] = flag;

         
        emit FreezeEvent(dst, flag);
        return true;
    }

     
     
     
     
     
     
    function mint(address dst, uint256 wad) onlyCFO public returns (bool)
    {
         
        _balances[dst] = add(_balances[dst],wad);
        _supply        = add(_supply,wad);

         
        emit MintEvent(dst, wad);
        return true;
    }

     
     
     
     
     
     
    function melt(address dst, uint256 wad) onlyCFO public returns (bool)
    {
         
        require(_balances[dst] >= wad);

         
        _balances[dst] = sub(_balances[dst],wad);
        _supply        = sub(_supply,wad);

         
        emit MeltEvent(dst, wad);
        return true;
    }
}