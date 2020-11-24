 

pragma solidity ^0.4.23;

contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
     
    constructor() public {
        owner = msg.sender;
    }
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
contract ERC827 is ERC20 {
    function approveAndCall(address _spender, uint256 _value, bytes _data) public payable returns (bool);

    function transferAndCall(address _to, uint256 _value, bytes _data) public payable returns (bool);

    function transferFromAndCall(address _from, address _to, uint256 _value, bytes _data) public payable returns (bool);
}

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }
     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract ERC20Token is ERC20 {
    using SafeMath for uint256;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => uint256) balances;
    uint256 totalSupply_;
     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

 
contract ERC827Token is ERC827, ERC20Token {
     
    function approveAndCall(address _spender, uint256 _value, bytes _data) public payable returns (bool) {
        require(_spender != address(this));
        super.approve(_spender, _value);
         
        require(_spender.call.value(msg.value)(_data));
        return true;
    }
     
    function transferAndCall(address _to, uint256 _value, bytes _data) public payable returns (bool) {
        require(_to != address(this));
        super.transfer(_to, _value);
        require(_to.call.value(msg.value)(_data));
        return true;
    }
     
    function transferFromAndCall(address _from, address _to, uint256 _value, bytes _data) public payable returns (bool) {
        require(_to != address(this));
        super.transferFrom(_from, _to, _value);
        require(_to.call.value(msg.value)(_data));
        return true;
    }
     
    function increaseApprovalAndCall(address _spender, uint _addedValue, bytes _data) public payable returns (bool) {
        require(_spender != address(this));
        super.increaseApproval(_spender, _addedValue);
        require(_spender.call.value(msg.value)(_data));
        return true;
    }
     
    function decreaseApprovalAndCall(address _spender, uint _subtractedValue, bytes _data) public payable returns (bool) {
        require(_spender != address(this));
        super.decreaseApproval(_spender, _subtractedValue);
        require(_spender.call.value(msg.value)(_data));
        return true;
    }
}

 
contract PauseBurnableERC827Token is ERC827Token, Ownable {
    using SafeMath for uint256;
    event Pause();
    event Unpause();
    event PauseOperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event Burn(address indexed burner, uint256 value);

    bool public paused = false;
    address public pauseOperator;
     
    modifier onlyPauseOperator() {
        require(msg.sender == pauseOperator || msg.sender == owner);
        _;
    }
     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
     
    modifier whenPaused() {
        require(paused);
        _;
    }
     
    constructor() public {
        pauseOperator = msg.sender;
    }
     
    function transferPauseOperator(address newPauseOperator) onlyPauseOperator public {
        require(newPauseOperator != address(0));
        emit PauseOperatorTransferred(pauseOperator, newPauseOperator);
        pauseOperator = newPauseOperator;
    }
     
    function pause() onlyPauseOperator whenNotPaused public {
        paused = true;
        emit Pause();
    }
     
    function unpause() onlyPauseOperator whenPaused public {
        paused = false;
        emit Unpause();
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
     
    function burn(uint256 _value) public whenNotPaused {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
         
         
        balances[_who] = balances[_who].sub(_value);
         
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
     
    function burnFrom(address _from, uint256 _value) public whenNotPaused {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _burn(_from, _value);
    }
}

contract ICOTH is PauseBurnableERC827Token {
    string  public constant name = "ICOTH";
    string  public constant symbol = "i";
    uint8   public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 10000000000 * (10 ** uint256(decimals));
     
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
    function batchTransfer(address[] _tos, uint256 _value) public whenNotPaused returns (bool) {
        uint256 all = _value.mul(_tos.length);
        require(balances[msg.sender] >= all);
        for (uint i = 0; i < _tos.length; i++) {
            require(_tos[i] != address(0));
            require(_tos[i] != msg.sender);
            balances[_tos[i]] = balances[_tos[i]].add(_value);
            emit Transfer(msg.sender, _tos[i], _value);
        }
        balances[msg.sender] = balances[msg.sender].sub(all);
        return true;
    }

    function multiTransfer(address[] _tos, uint256[] _values) public whenNotPaused returns (bool) {
        require(_tos.length == _values.length);
        uint256 all = 0;
        for (uint i = 0; i < _tos.length; i++) {
            require(_tos[i] != address(0));
            require(_tos[i] != msg.sender);
            all = all.add(_values[i]);
            balances[_tos[i]] = balances[_tos[i]].add(_values[i]);
            emit Transfer(msg.sender, _tos[i], _values[i]);
        }
        balances[msg.sender] = balances[msg.sender].sub(all);
        return true;
    }
}