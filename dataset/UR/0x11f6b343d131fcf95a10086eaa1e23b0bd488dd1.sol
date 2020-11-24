 

pragma solidity ^0.4.24;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract ERC20 {
    uint256 public totalSupply;

    function balanceOf(address who) public view returns(uint256);

    function transfer(address to, uint256 value) public returns(bool);

    function allowance(address owner, address spender) public view returns(uint256);

    function transferFrom(address from, address to, uint256 value) public returns(bool);

    function approve(address spender, uint256 value) public returns(bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20 {
    using SafeMath
    for uint256;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;


     
    function balanceOf(address _owner) public view returns(uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns(bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract PPCToken is StandardToken {
    string public constant name = "PurpleChain";
    string public constant symbol = "PPC";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 20000000000 * (10 ** uint256(decimals));
     
    address public marketAddress = 0x3172f12a77402BB52001A766E1d09b573967De61;
     
    constructor() public {
        totalSupply = INITIAL_SUPPLY;
        balances[marketAddress] = totalSupply;
        emit Transfer(address(0), marketAddress, totalSupply);
    }
}