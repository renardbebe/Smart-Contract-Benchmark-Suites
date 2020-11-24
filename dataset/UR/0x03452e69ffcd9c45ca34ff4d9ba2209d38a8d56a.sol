 

pragma solidity 0.5.1; 


library SafeMath {

    uint256 constant internal MAX_UINT = 2 ** 256 - 1;  

     
    function mul(uint256 _a, uint256 _b) internal pure returns(uint256) {
        if (_a == 0) {
            return 0;
        }
        require(MAX_UINT / _a >= _b);
        return _a * _b;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns(uint256) {
        require(_b != 0);
        return _a / _b;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns(uint256) {
        require(_b <= _a);
        return _a - _b;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns(uint256) {
        require(MAX_UINT - _a >= _b);
        return _a + _b;
    }

}


contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
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


contract StandardToken {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    uint256 internal totalSupply_;

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

     
    function totalSupply() public view returns(uint256) {
        return totalSupply_;
    }

     
    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }

     
    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns(uint256) {
        return allowed[_owner][_spender];
    }

     
    function transfer(address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns(bool) {
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
    returns(bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

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
    returns(bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
    public
    returns(bool) {
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


contract BurnableToken is StandardToken {
    event Burn(address indexed account, uint256 value);

     
    function burn(uint256 value) public {
        require(balances[msg.sender] >= value);
        totalSupply_ = totalSupply_.sub(value);
        balances[msg.sender] = balances[msg.sender].sub(value);
        emit Burn(msg.sender, value);
        emit Transfer(msg.sender, address(0), value);
    }

     
    function burnFrom(address account, uint256 value) public {
        require(account != address(0)); 
        require(balances[account] >= value);
        require(allowed[account][msg.sender] >= value);
        totalSupply_ = totalSupply_.sub(value);
        balances[account] = balances[account].sub(value);
        allowed[account][msg.sender] = allowed[account][msg.sender].sub(value);
        emit Burn(account, value);
        emit Transfer(account, address(0), value);
    }
}


 
contract PausableToken is StandardToken, Pausable {
    function transfer(
        address _to,
        uint256 _value
    )
    public
    whenNotPaused
    returns(bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    whenNotPaused
    returns(bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(
        address _spender,
        uint256 _value
    )
    public
    whenNotPaused
    returns(bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(
        address _spender,
        uint _addedValue
    )
    public
    whenNotPaused
    returns(bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(
        address _spender,
        uint _subtractedValue
    )
    public
    whenNotPaused
    returns(bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}


 
contract VESTELLAToken is PausableToken, BurnableToken {
    using SafeMath for uint256;

    string public constant name = "VESTELLA";  
    string public constant symbol = "VES";  
    uint8 public constant decimals = 18;  
    uint256 constant _INIT_TOTALSUPPLY = 15000000000; 

    mapping (address => uint256[]) internal locktime;
    mapping (address => uint256[]) internal lockamount;

    event AddLockPosition(address indexed account, uint256 amount, uint256 time);

     
    constructor() public {
        totalSupply_ = _INIT_TOTALSUPPLY * 10 ** uint256(decimals); 
        owner = 0x0F1b590cD3155571C8680B363867e20b8E4303bE;
        balances[owner] = totalSupply_;
    }

     
    function addLockPosition(address account, uint256[] memory amount, uint256[] memory time) public onlyOwner returns(bool) { 
        require(account != address(0));
        require(amount.length == time.length);
        uint256 _lockamount = 0;
        for(uint i = 0; i < amount.length; i++) {
            uint256 _amount = amount[i] * 10 ** uint256(decimals);
            require(time[i] > now);
            locktime[account].push(time[i]);
            lockamount[account].push(_amount);
            emit AddLockPosition(account, _amount, time[i]);
            _lockamount = _lockamount.add(_amount);
        }
        require(balances[msg.sender] >= _lockamount);
        balances[account] = balances[account].add(_lockamount);
        balances[msg.sender] = balances[msg.sender].sub(_lockamount);
        emit Transfer(msg.sender, account, _lockamount);
        return true;
    }

     
    function getLockPosition(address account) public view returns(uint256[] memory _locktime, uint256[] memory _lockamount) {
        return (locktime[account], lockamount[account]);
    }

     
    function getLockedAmount(address account) public view returns(uint256 _lockedAmount) {
        uint256 _Amount = 0;
        uint256 _lockAmount = 0;
        for(uint i = 0; i < locktime[account].length; i++) {
            if(now < locktime[account][i]) {
                _Amount = lockamount[account][i]; 
                _lockAmount = _lockAmount.add(_Amount);
            }
        }
        return _lockAmount;   
    }

     
    function transfer(
        address _to,
        uint256 _value
    )
    public
    returns(bool) {
        require(balances[msg.sender].sub(_value) >= getLockedAmount(msg.sender));
        return super.transfer(_to, _value);
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns(bool) {
        require(balances[_from].sub(_value) >= getLockedAmount(_from));
        return super.transferFrom(_from, _to, _value);
    }

     
    function burn(uint256 value) public {
        require(balances[msg.sender].sub(value) >= getLockedAmount(msg.sender));
        super.burn(value);
    }  

     
    function burnFrom(address account, uint256 value) public {
        require(balances[account].sub(value) >= getLockedAmount(account));
        super.burnFrom(account, value);
    } 

     
    function _batchTransfer(address[] memory _to, uint256[] memory _amount) internal whenNotPaused {
        require(_to.length == _amount.length);
        uint256 sum = 0; 
        for(uint i = 0;i < _to.length;i += 1){
            require(_to[i] != address(0));  
            sum = sum.add(_amount[i]);
            require(sum <= balances[msg.sender]);  
            balances[_to[i]] = balances[_to[i]].add(_amount[i]); 
            emit Transfer(msg.sender, _to[i], _amount[i]);
        } 
        balances[msg.sender] = balances[msg.sender].sub(sum); 
    }

     
    function airdrop(address[] memory _to, uint256[] memory _amount) public onlyOwner returns(bool){
        _batchTransfer(_to, _amount);
        return true;
    }
}