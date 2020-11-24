 

pragma solidity ^0.4.24;

 
library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        assert(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        assert(c >= _a);

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

    function approveBurn(address _spender, uint256 _value) public returns (bool) {
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
        require(!frozenAccount[msg.sender], "Sender account freezed");
        require(!frozenAccount[_from], "From account freezed");
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
        require(!frozenAccount[msg.sender], "Sender account freezed");
        require(!frozenAccount[_from], "From account freezed");

        return super.burnFrom(_from, _value);
    }
}


 
contract LockableFreezableBurnablePausableERC20Token is FreezableBurnablePausableERC20Token {
    struct LockAtt {
    uint256 initLockAmount;     
    uint256 lockAmount;         
    uint256 startLockTime;      
    uint256 cliff;              
    uint256 interval;           
    uint256 releaseCount;       
    bool revocable;             
    address revocAddress;       
    }
    mapping (address => LockAtt) public lockAtts;

    event RefreshedLockStatus(address _account);
     
    function refreshLockStatus(address _account) public whenNotPaused returns (bool)
    { 
        if(lockAtts[_account].lockAmount <= 0)
            return false;

        require(lockAtts[_account].interval > 0, "Interval error");

        uint256 initlockamount = lockAtts[_account].initLockAmount;
        uint256 startlocktime = lockAtts[_account].startLockTime;
        uint256 cliff = lockAtts[_account].cliff;
        uint256 interval = lockAtts[_account].interval;
        uint256 releasecount = lockAtts[_account].releaseCount;

        uint256 releaseamount = 0;
	if(block.timestamp < startlocktime + cliff)
	    return false;

        uint256 exceedtime = block.timestamp-startlocktime-cliff;
        if(exceedtime >= 0)
        {
            releaseamount = (exceedtime/interval+1)*initlockamount/releasecount;
            uint256 lockamount = initlockamount - releaseamount;
            if(lockamount<0)
                lockamount=0;
            if(lockamount>initlockamount)
                lockamount=initlockamount;
            lockAtts[_account].lockAmount = lockamount;
        }

        emit RefreshedLockStatus(_account);
        return true;
    }

    event LockTransfered(address _from, address _to, uint256 _value, uint256 _cliff, uint256 _interval, uint _releaseCount);
     
    function lockTransfer(address _to, uint256 _value, uint256 _cliff, uint256 _interval, uint _releaseCount) 
    public whenNotPaused returns (bool)
    {
        require(!frozenAccount[msg.sender], "Sender account freezed");
        require(!frozenAccount[_to], "Receiver account freezed");
        require(balances[_to] == 0, "Revceiver not a new account");     
        require(_cliff>0, "Cliff error"); 
        require(_interval>0, "Interval error"); 
        require(_releaseCount>0, "Release count error"); 

        refreshLockStatus(msg.sender);
        uint256 balance = balances[msg.sender];
        uint256 lockbalance = lockAtts[msg.sender].lockAmount;
        require(_value <= balance && _value <= balance.sub(lockbalance), "Unlocked balance insufficient");
        require(_to != address(0));

        LockAtt memory lockatt = LockAtt(_value, _value, block.timestamp, _cliff, _interval, _releaseCount, false, msg.sender);
        lockAtts[_to] = lockatt;     

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit LockTransfered(msg.sender, _to, _value, _cliff, _interval, _releaseCount);
        return true; 
    } 

    event SetRevocable(bool _revocable);
     
    function setRevocable(bool _revocable) public whenNotPaused 
    {
        require(!frozenAccount[msg.sender], "Account freezed");

        lockAtts[msg.sender].revocable = _revocable;
        emit SetRevocable(_revocable);
    }

    event Revoced(address _account);
     
    function revoc(address _account) public whenNotPaused returns (uint256)
    {
        require(!frozenAccount[msg.sender], "Account freezed");
        require(!frozenAccount[_account], "Sender account freezed");
        require(lockAtts[_account].revocable, "Account not revocable");         
        require(lockAtts[_account].revocAddress == msg.sender, "No permission to revoc");     
        refreshLockStatus(_account);
        uint256 balance = balances[_account];
        uint256 lockbalance = lockAtts[_account].lockAmount;
        require(balance >= balance.sub(lockbalance), "Unlocked balance insufficient");
    
         
        balances[msg.sender] = balances[msg.sender].add(lockbalance);
        balances[_account] = balances[_account].sub(lockbalance); 

	 
        lockAtts[_account].lockAmount = 0;
        lockAtts[_account].initLockAmount = 0;


        emit Revoced(_account);
        return lockbalance;
    }

     

    function transfer(
        address _to,
        uint256 _value
    )
        public
        whenNotPaused
        returns (bool)
    { 
        refreshLockStatus(msg.sender);
        uint256 balance = balances[msg.sender];
        uint256 lockbalance = lockAtts[msg.sender].lockAmount;
        require(_value <= balance && _value <= balance.sub(lockbalance), "Unlocked balance insufficient");

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
        refreshLockStatus(_from);
        uint256 balance = balances[_from];
        uint256 lockbalance = lockAtts[_from].lockAmount;
        require(_value <= balance && _value <= balance.sub(lockbalance), "Unlocked balance insufficient");

        return super.transferFrom(_from, _to, _value);
    }

    function burn(
        uint256 _value
    ) 
        public
        whenNotPaused
    {  
        refreshLockStatus(msg.sender);
        uint256 balance = balances[msg.sender];
        uint256 lockbalance = lockAtts[msg.sender].lockAmount;
        require(_value <= balance && _value <= balance.sub(lockbalance), "Unlocked balance insufficient");

        return super.burn(_value);
    }

    function burnFrom(
        address _from, 
        uint256 _value
    ) 
        public 
        whenNotPaused
    {  
        refreshLockStatus(_from);
        uint256 balance = balances[_from];
        uint256 lockbalance = lockAtts[_from].lockAmount;
        require(_value <= balance && _value <= balance.sub(lockbalance), "Unlocked balance insufficient");

        return super.burnFrom(_from, _value);
    }

 
}


 
contract AWNC is LockableFreezableBurnablePausableERC20Token {

     
    string public constant name = "Action Wellness Chain";
    string public constant symbol = "AWNC";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 10000000000 * (10 ** uint256(decimals));

     
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }
}