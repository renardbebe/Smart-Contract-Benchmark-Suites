 

pragma solidity 0.5.4;


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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
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

    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }

     
    function allowance(address _owner, address _spender) public view returns(uint256) {
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

     
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function increaseApproval(address _spender, uint256 _addedValue) public returns(bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns(bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0));
        totalSupply = totalSupply.sub(value);
        balances[account] = balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
         
         
        allowed[account][msg.sender] = allowed[account][msg.sender].sub(value);
        _burn(account, value);
    }

}


contract BurnableToken is StandardToken {

     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}


 
contract PausableToken is StandardToken, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseApproval(address spender, uint256 addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(spender, addedValue);
    }

    function decreaseApproval(address spender, uint256 subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(spender, subtractedValue);
    }
}


 
contract Token is PausableToken, BurnableToken {
    string public name; 
    string public symbol; 
    uint8 public decimals;

     
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _INIT_TOTALSUPPLY) public {
        totalSupply = _INIT_TOTALSUPPLY * 10 ** uint256(_decimals);
        balances[owner] = totalSupply;  
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}


 
interface BDRContract {
    function tokenFallback(address _from, uint256 _value, bytes calldata _data) external;
    function transfer(address _to, uint256 _value) external returns (bool);
    function decimals() external returns (uint8);
}


 
contract IOAEX is Token {
     
    BDRContract public BDRInstance;
     
    mapping(address => uint256) public totalLockAmount;
     
    mapping(address => uint256) public releasedAmount;
     
    mapping(address => timeAndAmount[]) public allocations;
     
    struct timeAndAmount {
        uint256 releaseTime;
        uint256 releaseAmount;
    }
    
     
    event LockToken(address _beneficiary, uint256 totalLockAmount);
    event ReleaseToken(address indexed user, uint256 releaseAmount, uint256 releaseTime);
    event ExchangeBDR(address from, uint256 value);
    event SetBDRContract(address BDRInstanceess);

     
    modifier onlyBDRContract() {
        require(msg.sender == address(BDRInstance));
        _;
    }

     
    constructor (string memory _name, string memory _symbol, uint8 _decimals, uint256 _INIT_TOTALSUPPLY) Token (_name, _symbol, _decimals, _INIT_TOTALSUPPLY) public {

    }

     
    function setBDRContract(address BDRAddress) public onlyOwner {
        require(BDRAddress != address(0));
        BDRInstance = BDRContract(BDRAddress);
        emit SetBDRContract(BDRAddress);
    }
    
     
    function lockToken(address _beneficiary, uint256[] memory _releaseTimes, uint256[] memory _releaseAmount) public onlyOwner returns(bool) {
        
        require(totalLockAmount[_beneficiary] == 0);  
        require(_beneficiary != address(0));  
        require(_releaseTimes.length == _releaseAmount.length);  
        releasedAmount[_beneficiary] = 0;
        for (uint256 i = 0; i < _releaseTimes.length; i++) {
            totalLockAmount[_beneficiary] = totalLockAmount[_beneficiary].add(_releaseAmount[i]);
            require(_releaseAmount[i] > 0);  
            require(_releaseTimes[i] >= now);  
             
            allocations[_beneficiary].push(timeAndAmount(_releaseTimes[i], _releaseAmount[i]));
        }
        balances[owner] = balances[owner].sub(totalLockAmount[_beneficiary]);  
        emit LockToken(_beneficiary, totalLockAmount[_beneficiary]);
        return true;
    }

     
    function releaseToken() public returns (bool) {
        release(msg.sender); 
    }

     
    function release(address addr) internal {
        require(totalLockAmount[addr] > 0);  

        uint256 amount = releasableAmount(addr);  
         
        balances[addr] = balances[addr].add(amount);
         
        releasedAmount[addr] = releasedAmount[addr].add(amount);
         
        if (releasedAmount[addr] == totalLockAmount[addr]) {
            delete allocations[addr];
            totalLockAmount[addr] = 0;
        }
        emit ReleaseToken(addr, amount, now);
    }

     
    function releasableAmount(address addr) public view returns (uint256) {
        if(totalLockAmount[addr] == 0) {
            return 0;
        }
        uint256 num = 0;
        for (uint256 i = 0; i < allocations[addr].length; i++) {
            if (now >= allocations[addr][i].releaseTime) {  
                num = num.add(allocations[addr][i].releaseAmount);
            }
        }
        return num.sub(releasedAmount[addr]);  
    }
    
     
    function balanceOfLocked(address addr) public view returns(uint256) {
        if (totalLockAmount[addr] > releasedAmount[addr]) {
            return totalLockAmount[addr].sub(releasedAmount[addr]);
        } else {
            return 0;
        }
        
    }

     
    function transfer(address to, uint value) public returns (bool) {
        if(releasableAmount(msg.sender) > 0) {
            release(msg.sender);  
        }
        super.transfer(to, value);  
        if(to == address(BDRInstance)) {
            BDRInstance.tokenFallback(msg.sender, value, bytes(""));  
            emit ExchangeBDR(msg.sender, value);
        }
        return true;
    }

     
    function transferFrom(address from, address to, uint value) public returns (bool) {
        if(releasableAmount(from) > 0) {
            release(from);  
        }
        super.transferFrom(from, to, value);  
        if(to == address(BDRInstance)) {
            BDRInstance.tokenFallback(from, value, bytes(""));  
            emit ExchangeBDR(from, value);
        }
        return true;
    }

     
    function tokenFallback(address from, uint256 value, bytes calldata) external onlyBDRContract {
        require(from != address(0));
        require(value != uint256(0));
        
        uint256 AbcValue = value.mul(10**uint256(decimals)).div(10**uint256(BDRInstance.decimals()));  
        require(AbcValue <= balances[address(BDRInstance)]);
        balances[address(BDRInstance)] = balances[address(BDRInstance)].sub(AbcValue);
        balances[from] = balances[from].add(AbcValue);
        emit Transfer(owner, from, AbcValue);
    }
    
}