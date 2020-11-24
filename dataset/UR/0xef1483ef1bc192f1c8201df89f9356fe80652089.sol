 

pragma solidity ^0.5.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


contract StandardToken is IERC20 {
    uint256 public totalSupply;

    using SafeMath for uint;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(balances[_to] + _value > balances[_to]);   
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require( _value > 0 , "No negative value");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value > balances[_to]);   
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

}

contract GPS is StandardToken {
    string public constant name = "Coinscious Network";
    string public constant symbol = "GPS";
    uint8 public constant decimals = 8;
    uint256 public constant initialSupply = 2100000000 * 10 ** uint256(decimals);

    mapping (address => uint256) internal locks;
    address internal tokenOwner;

    string internal constant ALREADY_LOCKED = 'Already locked';
    string internal constant AMOUNT_ZERO = 'Amount must be greater than 0';
    string internal constant TIME_ZERO = 'Time must be greater than 0';

    event Burn(address indexed from, uint256 value);

    constructor () public {
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
        tokenOwner = msg.sender;
    }

    function burn(uint256 _value) public returns (bool) {
        require( balances[msg.sender] >= _value, "Insufficient balance");
        require( _value > 0 , AMOUNT_ZERO);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function lockTimeOf(address _owner) public view returns (uint256 time) {
        return locks[_owner];
    }

    modifier isNotLocked() {
        require( locks[msg.sender] < now , "Locked");
        _;
    }

    modifier isNotLockedFrom(address _from) {
        require( locks[_from] < now , "Locked");
        _;
    }

    modifier isOwner() {
        require( msg.sender == tokenOwner , "Not Owner");
        _;
    }

    function transferWithLockTime(address _to, uint256 _value, uint256 _time)
    public isOwner
    returns (bool)
    {
        uint256 validUntil = now.add(_time);

        require(_time > 0, TIME_ZERO);
        require(locks[_to] < now , ALREADY_LOCKED);
        require(_value > 0, AMOUNT_ZERO);

        locks[_to] = validUntil;
        return super.transfer(_to, _value);
    }

    function transfer(address _to, uint256 _value) public isNotLocked() returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public isNotLockedFrom(_from)  returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

}