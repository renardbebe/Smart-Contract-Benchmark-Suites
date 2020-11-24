 

pragma solidity ^0.4.18;

library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
 
 
 

 
contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract Notes is Token {

    using SafeMath for uint256;

     

     
    uint256 public constant TOTAL_SUPPLY = 2000 * (10**6) * 10**uint256(decimals);

     
    string public constant name = "NOTES";
    string public constant symbol = "NOTES";
    uint8 public constant decimals = 18;
    string public version = "1.0";

     

    address admin;
    bool public activated = false;
    mapping (address => bool) public activeGroup;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) allowed;

     

    modifier active()
    {
        require(activated || activeGroup[msg.sender]);
        _;
    }

    modifier onlyAdmin()
    {
        require(msg.sender == admin);
        _;
    }

     

    function Notes(address fund, address _admin)
    {
        admin = _admin;
        totalSupply = TOTAL_SUPPLY;
        balances[fund] = TOTAL_SUPPLY;     
        Transfer(address(this), fund, TOTAL_SUPPLY);
        activeGroup[fund] = true;   
    }

     

    function addToActiveGroup(address a) onlyAdmin {
        activeGroup[a] = true;
    }

    function activate() onlyAdmin {
        activated = true;
    }

     

    function transfer(address _to, uint256 _value) active returns (bool success) {
        require(_to != address(0));
        require(_value > 0);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) active returns (bool success) {
        require(_to != address(0));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) active returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}