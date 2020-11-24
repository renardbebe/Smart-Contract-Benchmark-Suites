 

pragma solidity ^0.5.11;

contract Ownable {
    address payable public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address payable public newOwner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable otherOwner) onlyOwner public {
        require(otherOwner != address(0));
        newOwner = otherOwner;
    }

    function approveOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
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
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address payable to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address payable from, address payable to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MyToken is ERC20, Pausable {
    using SafeMath for uint256;

    string public constant version = "0.1";
    string public name = "The NOTHING with BOOLEAN";
    string public symbol = "NTHGwB";
    uint256 public constant decimals = 2;
    uint256 internal _totalSupply = 500000000;

    struct Balance {
        uint256 value;
        bool exists;
    }

    mapping(address => Balance) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    function addAllowance(address _owner, address _spender, uint256 _value) internal returns (uint256) {
        allowed[_owner][_spender] = allowed[_owner][_spender].add(_value);
        return allowed[_owner][_spender];
    }

    function subAllowance(address _owner, address _spender, uint256 _value) internal returns (uint256) {
        require(_value <= allowed[_owner][_spender]);
        allowed[_owner][_spender] = allowed[_owner][_spender].sub(_value);
        return allowed[_owner][_spender];
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner].value;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        addAllowance(msg.sender, _spender, _value);
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address payable _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address payable _from, address payable _to, uint256 _value) public returns (bool) {
        _transfer(_from, _to, _value);
        emit Transfer(_from, _to, _value);
        subAllowance(_from, msg.sender, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_value <= balances[_from].value);
        balances[_from].value = balances[_from].value.sub(_value);
        balances[_to].value = balances[_to].value.add(_value);
    }

    function issue(address payable _to, uint256 _value) public onlyOwner returns (bool) {
        balances[_to].value = balances[_to].value.add(_value);
        _totalSupply = _totalSupply.add(_value);
        emit Transfer(address(0x0), _to, _value);
        return true;
    }

    function burn(address _from, uint256 _value) public onlyOwner returns (bool) {
        require(_value <= balances[_from].value);
        balances[_from].value = balances[_from].value.sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        return true;
    }
}