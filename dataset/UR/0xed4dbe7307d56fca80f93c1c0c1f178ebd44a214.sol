 

 

pragma solidity ^0.5.10;
 
contract ERC20Basic 
{
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
 
library SafeMath 
{
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c  / a == b);
        return c;
    }
     
    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return a  / b;
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
pragma solidity ^0.5.10;
 
contract ERC20 is ERC20Basic 
{
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract Owner
{
    address internal owner;
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function changeOwner(address newOwner) public onlyOwner returns(bool)
    {
        owner = newOwner;
        return true;
    }
}

pragma solidity ^0.5.10;
 
contract BasicToken is ERC20Basic, Owner
{
    using SafeMath for uint256;
    uint256 internal totalSupply_;
    mapping (address => bool) internal locked;
	mapping(address => uint256) internal balances;
     
    function lockAccount(address _addr) public onlyOwner returns (bool)
    {
        require(_addr != address(0));
        locked[_addr] = true;
        return true;
    }
    function unlockAccount(address _addr) public onlyOwner returns (bool)
    {
        require(_addr != address(0));
        locked[_addr] = false;
        return true;
    }
     
    function isLocked(address addr) public view returns(bool) 
    {
        return locked[addr];
    }
    bool internal stopped = false;
    modifier running {
        assert (!stopped);
        _;
    }
    function stop() public onlyOwner 
    {
        stopped = true;
    }
    function start() public onlyOwner 
    {
        stopped = false;
    }
    function isStopped() public view returns(bool)
    {
        return stopped;
    }
     
    function totalSupply() public view returns (uint256) 
    {
        return totalSupply_;
    }
     
    function transfer(address _to, uint256 _value) public running returns (bool) 
    {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require( locked[msg.sender] != true);
        require( locked[_to] != true);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
     
    function balanceOf(address _owner) public view returns (uint256) 
    {
        return balances[_owner];
    }
}
pragma solidity ^0.5.10;
 
contract StandardToken is ERC20, BasicToken 
{
    mapping (address => mapping (address => uint256)) internal allowed;
     
    function transferFrom(address _from, address _to, uint256 _value) public running returns (bool) 
    {
        require(_to != address(0));
        require( locked[_from] != true && locked[_to] != true);
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
     
    function approve(address _spender, uint256 _value) public running returns (bool) 
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
     
    function allowance(address _owner, address _spender) public view returns (uint256) 
    {
        return allowed[_owner][_spender];
    }
}

contract NNDToken is StandardToken
{
    function additional(uint amount) public onlyOwner running returns(bool)
    {
        totalSupply_ = totalSupply_.add(amount);
        balances[owner] = balances[owner].add(amount);
        return true;
    }
    event Burn(address indexed from, uint256 value);
     
    function burn(uint256 _value) public onlyOwner running returns (bool success) 
    {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }
     
    function burnFrom(address _from, uint256 _value) public onlyOwner returns (bool success) 
    {
        require(balances[_from] >= _value);
        if (_value <= allowed[_from][msg.sender]) {
            allowed[_from][msg.sender] -= _value;
        }
        else {
            allowed[_from][msg.sender] = 0;
        }
        balances[_from] -= _value;
        totalSupply_ -= _value;
        emit Burn(_from, _value);
        return true;
    }
}

pragma solidity ^0.5.10;
contract NND is NNDToken 
{
    string public constant name = "NND";
    string public constant symbol = "NND";
    uint8 public constant decimals = 18;
    uint256 private constant INITIAL_SUPPLY = 990000000 * (10 ** uint256(decimals));

    constructor(uint totalSupply) public 
    {
        owner = msg.sender;
        totalSupply_ = totalSupply > 0 ? totalSupply : INITIAL_SUPPLY;
        balances[owner] = totalSupply_;
    }
}