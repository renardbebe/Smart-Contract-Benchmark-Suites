 

pragma solidity ^0.4.24;


library SafeMath {
   
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }
        uint256 c = _a * _b;
        require(c / _a == _b);
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a / _b;
        return c;
    }
  
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;
        return c;
    }
    
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);
        return c;
    }
}

contract Ownable {
    address public owner;
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() public {
        owner = msg.sender;
    }
  
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function renounceOwnership() public onlyOwner {
emit OwnershipRenounced(owner);
owner = address(0);
    }
   
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }
   
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0)); 
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
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
   
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }
    
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function allowance(address _owner, address _spender)
    public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value)
    public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
contract StandardToken is ERC20 {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    uint256 totalSupply_;
    function totalSupply() public view returns (uint256) {
return totalSupply_;
    }
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns (uint256)
    {
        return allowed[_owner][_spender];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
require(_value <= balances[msg.sender]);
require(_to != address(0)); 
balances[msg.sender] = balances[msg.sender].sub(_value);
balances[_to] = balances[_to].add(_value);
emit Transfer(msg.sender, _to, _value);
        return true; 
    }
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true; 
    }
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
{
require(_value <= balances[_from]);
require(_value <= allowed[_from][msg.sender]);
require(_to != address(0)); 
balances[_from] = balances[_from].sub(_value);
balances[_to] = balances[_to].add(_value);
allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true; 
}
  
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
    public
    returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
    public
    returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract PausableERC20Token is StandardToken, Pausable {
    function transfer(
        address _to,
        uint256 _value
    )
    public
    whenNotPaused
    returns (bool)
    {
        return super.transfer(_to, _value);
    }
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    whenNotPaused
    returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }
    function approve(
        address _spender,
        uint256 _value
    )
    public
    whenNotPaused
    returns (bool)
    {
        return super.approve(_spender, _value);
    }
    function increaseApproval(
        address _spender,
        uint _addedValue
    )
    public
    whenNotPaused
    returns (bool success)
    {
        return super.increaseApproval(_spender, _addedValue);
    }
    function decreaseApproval(
        address _spender,
        uint _subtractedValue
    )
    public
    whenNotPaused
    returns (bool success)
    {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract BurnablePausableERC20Token is PausableERC20Token {
    mapping (address => mapping (address => uint256)) internal allowedBurn;
    event Burn(address indexed burner, uint256 value);
    event ApprovalBurn(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    function allowanceBurn(
        address _owner,
        address _spender
    )
    public
    view
    returns (uint256)
    {
        return allowedBurn[_owner][_spender];
    }
    function approveBurn(address _spender, uint256 _value)
    public
    whenNotPaused
    returns (bool)
    {
        allowedBurn[msg.sender][_spender] = _value;
        emit ApprovalBurn(msg.sender, _spender, _value);
        return true;
    }

    function burn(
        uint256 _value
    )
    public
    whenNotPaused
{
_burn(msg.sender, _value);
}
   
    function burnFrom(
        address _from,
        uint256 _value
    )
    public
    whenNotPaused
    {
        require(_value <= allowedBurn[_from][msg.sender]);
        allowedBurn[_from][msg.sender] = allowedBurn[_from][msg.sender].sub(_value);
        _burn(_from, _value);
    }
    function _burn(
        address _who,
        uint256 _value
    )
    internal
    whenNotPaused
    {
        require(_value <= balances[_who]);
        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
    function increaseBurnApproval(
        address _spender,
        uint256 _addedValue
    )
    public
    whenNotPaused
    returns (bool)
    {
        allowedBurn[msg.sender][_spender] = (
        allowedBurn[msg.sender][_spender].add(_addedValue));
        emit ApprovalBurn(msg.sender, _spender, allowedBurn[msg.sender][_spender]);
        return true;
    }
    function decreaseBurnApproval(
        address _spender,
        uint256 _subtractedValue
    )
    public
    whenNotPaused
    returns (bool)
    {
        uint256 oldValue = allowedBurn[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowedBurn[msg.sender][_spender] = 0;
        } else {
            allowedBurn[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit ApprovalBurn(msg.sender, _spender, allowedBurn[msg.sender][_spender]);
        return true;
    }
}
contract FreezableBurnablePausableERC20Token is BurnablePausableERC20Token {
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);
    function freezeAccount(
        address target,
        bool freeze
    )
    public
    onlyOwner
{
frozenAccount[target] = freeze;
    emit FrozenFunds(target, freeze);
}
    function transfer(
        address _to,
        uint256 _value
    )
    public
    whenNotPaused
    returns (bool)
    {
        require(!frozenAccount[msg.sender], "Sender account freezed");
        require(!frozenAccount[_to], "Receiver account freezed");
        return super.transfer(_to, _value);
    }
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    whenNotPaused
    returns (bool)
    {
        require(!frozenAccount[msg.sender], "Spender account freezed");
        require(!frozenAccount[_from], "Sender account freezed");
        require(!frozenAccount[_to], "Receiver account freezed");
        return super.transferFrom(_from, _to, _value);
    }
    function burn(
        uint256 _value
    )
    public
    whenNotPaused
{
require(!frozenAccount[msg.sender], "Sender account freezed");
return super.burn(_value);
}
    function burnFrom(
        address _from,
        uint256 _value
    )
    public
    whenNotPaused
    {
        require(!frozenAccount[msg.sender], "Spender account freezed");
        require(!frozenAccount[_from], "Sender account freezed");
        return super.burnFrom(_from, _value);
    }
}

contract EFT is FreezableBurnablePausableERC20Token {
    string public constant name = "EduFriend Token";
    string public constant symbol = "EFT";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 10000000000 * (10 ** uint256(decimals));
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }
}