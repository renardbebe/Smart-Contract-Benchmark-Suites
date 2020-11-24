 

pragma solidity ^0.4.19;

contract ERC20 {

event Transfer(address indexed _from, address indexed _to, uint256 _value);

event Approval(address indexed _owner, address indexed _spender, uint256 _value);

function totalSupply() external constant returns (uint);

function balanceOf(address _owner) external constant returns (uint256);

function transfer(address _to, uint256 _value) external returns (bool);

function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

function approve(address _spender, uint256 _value) external returns (bool);

function allowance(address _owner, address _spender) external constant returns (uint256);
    
}

library SafeMath {

     
    function ADD (uint256 a, uint256 b) pure internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

     
    function SUB (uint256 a, uint256 b) pure internal returns (uint256) {
        assert(a >= b);
        return a - b;
    }
    
}

contract Ownable {

    address owner;

    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

    function Ownable() public {
        owner = msg.sender;
        OwnershipTransferred (address(0), owner);
    }

    function transferOwnership(address _newOwner)
        public
        onlyOwner
        notZeroAddress(_newOwner)
    {
        owner = _newOwner;
        OwnershipTransferred(msg.sender, _newOwner);
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0));
        _;
    }

}

contract StandardToken is ERC20, Ownable{

    using SafeMath for uint256;
    
     
    uint256 _totalSupply = 5000000000; 

     
    mapping (address => uint256)  balances;
     
    mapping (address => mapping (address => uint256)) allowed;

     
    event Burn(address indexed _from, uint256 _value);

     
    function totalSupply() external constant returns (uint256 totalTokenSupply) {
        totalTokenSupply = _totalSupply;
    }

     
    function balanceOf(address _owner)
        external
        constant
        returns (uint256 balance)
    {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _amount)
        external
        notZeroAddress(_to)
        returns (bool success)
    {
        balances[msg.sender] = balances[msg.sender].SUB(_amount);
        balances[_to] = balances[_to].ADD(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount)
        external
        notZeroAddress(_to)
        returns (bool success)
    {
         
        require(allowed[_from][msg.sender] >= _amount);
        balances[_from] = balances[_from].SUB(_amount);
        balances[_to] = balances[_to].ADD(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].SUB(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }

     
     
    function approve(address _spender, uint256 _amount)
        external
        notZeroAddress(_spender)
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function allowance(address _owner, address _spender)
        external
        constant
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint256 _addedValue)
        external
        returns (bool success)
    {
        uint256 increased = allowed[msg.sender][_spender].ADD(_addedValue);
        require(increased <= balances[msg.sender]);
         
        allowed[msg.sender][_spender] = increased;
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue)
        external
        returns (bool success)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.SUB(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function burn(uint256 _value) external returns (bool success) {
         
        balances[msg.sender] = balances[msg.sender].SUB(_value);
         
        _totalSupply = _totalSupply.SUB(_value);
        Burn(msg.sender, _value);
        return true;
    }

}

contract TheWolfCoin is StandardToken {

    function ()
   	public
    {
     
    revert();
    }

     
    string public constant name = "TheWolfCoin";
     
    string public constant symbol = "TWC";
     
    uint8 public constant decimals = 2;

     
	 

     
    address public constant WOLF2 = 0xDB9504AC2E451f8dbB8990564e44B83B7be29045;
     
    address public constant WOLF3 = 0xe623bED2b3A4cE7ba286737C8A03Ae0b27e01d8A;
     
    address public constant WOLF4 = 0x7bB34Edb32024C7Ce01a1c2C9A02bf9d3B5BdEf1;

     
    uint256 public wolf2Balance;
     
    uint256 public wolf3Balance;
     
    uint256 public wolf4Balance;

     
    uint256 private constant WOLF1_THOUSANDTH = 250;
     
    uint256 private constant WOLF2_THOUSANDTH = 250;
     
    uint256 private constant WOLF3_THOUSANDTH = 250;
     
    uint256 private constant WOLF4_THOUSANDTH = 250;
     
    uint256 private constant DENOMINATOR = 1000;

    function TheWolfCoin() public {
         
        balances[msg.sender] = _totalSupply * WOLF1_THOUSANDTH / DENOMINATOR;
         
        wolf2Balance = _totalSupply * WOLF2_THOUSANDTH / DENOMINATOR;
         
        wolf3Balance = _totalSupply * WOLF3_THOUSANDTH / DENOMINATOR;
         
        wolf4Balance = _totalSupply * WOLF4_THOUSANDTH / DENOMINATOR;

        Transfer (this, msg.sender, balances[msg.sender]);

        balances[WOLF2] = wolf2Balance;
        Transfer (this, WOLF2, balances[WOLF2]);

        balances[WOLF3] = wolf3Balance;
        Transfer (this, WOLF3, balances[WOLF3]);

        balances[WOLF4] = wolf4Balance;
        Transfer (this, WOLF4, balances[WOLF4]);

    }
}