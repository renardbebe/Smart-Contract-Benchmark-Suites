 

pragma solidity ^0.4.24;


contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}


contract SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Pausable is Owned {
    bool public paused = false;
    event Pause();
    event Unpause();

    modifier notPaused {
        require(!paused);
        _;
    }

    function pause() public onlyOwner {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner {
        paused = false;
        emit Unpause();
    }
}

contract EIP20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract Qobit is Owned, SafeMath, Pausable, EIP20Interface {
    uint256 private totalSupply_;
    string public name;
    string public symbol;
    uint8 public decimals;
    
    mapping (address => uint256) public balances;
    mapping (address => uint256) public frozen;
    mapping (address => mapping (address => uint256)) public allowed;

    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);
    event Burned(address indexed from, uint256 value);

    constructor() public {
        name = "Qobit.com Token";
        symbol = "QOBI";
        decimals = 8;
        totalSupply_ = 1500000000 * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply_;
    }

     
    function mint(address _addr, uint256 _amount) onlyOwner public returns (bool success) {
        require(_addr != 0x0);
        totalSupply_ = add(totalSupply_, _amount);
        balances[_addr] = add(balances[_addr], _amount);
        emit Transfer(address(0), _addr, _amount);
        return true;
    }

     
    function burn(address _addr, uint256 _amount) onlyOwner public returns (bool success) {
        require(_addr != 0);
        require(_amount <= balances[_addr]);

        totalSupply_ = sub(totalSupply_, _amount);
        balances[_addr] = sub(balances[_addr], _amount);
        emit Transfer(_addr, address(0), _amount);
        emit Burned(_addr, _amount);
        return true;
    }

     
    function freeze(address _addr, uint256 _value) public onlyOwner returns (bool success) {
        require(balances[_addr] >= _value);
        require(_value > 0);
        balances[_addr] = sub(balances[_addr], _value);
        frozen[_addr] = add(frozen[_addr], _value);
        emit Freeze(_addr, _value);
        return true;
    }
    
    function unfreeze(address _addr, uint256 _value) public onlyOwner returns (bool success) {
        require(frozen[_addr] >= _value);
        require(_value > 0);
        frozen[_addr] = sub(frozen[_addr], _value);
        balances[_addr] = add(balances[_addr], _value);
        emit Unfreeze(_addr, _value);
        return true;
    }

    function frozenOf(address _addr) public view returns (uint256 balance) {
        return frozen[_addr];
    }
    
     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _addr) public view returns (uint256 balance) {
        return balances[_addr];
    }

    function transfer(address _to, uint256 _value) public notPaused returns (bool success) {
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public notPaused returns (bool success) {
        require(balances[_from] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        require(allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public notPaused returns (bool success) {
        require(_value > 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    } 
}