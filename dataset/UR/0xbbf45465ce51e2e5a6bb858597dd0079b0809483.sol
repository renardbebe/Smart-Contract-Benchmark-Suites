 

pragma solidity 0.5.8;

 
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
}

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "The caller must be owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Cannot transfer control of the contract to the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
contract StandardToken is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowed;

    uint256 internal _totalSupply;
    
     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "Cannot transfer to the zero address");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0), "Cannot approve to the zero address");
        require(owner != address(0), "Setter cannot be the zero address");

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused, "Only when the contract is not paused");
        _;
    }

     
    modifier whenPaused() {
        require(paused, "Only when the contract is paused");
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

 
contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseAllowance(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseAllowance(_spender, _addedValue);
    }

    function decreaseAllowance(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseAllowance(_spender, _subtractedValue);
    }
}
 
contract FreezableToken is PausableToken {
    mapping(address=>bool) internal _frozenAccount;

    event FrozenAccount(address indexed target, bool frozen);

     
    function frozenAccount(address account) public view returns(bool){
        return _frozenAccount[account];
    }

     
    function frozenCheck(address account) internal view {
        require(!frozenAccount(account), "Address has been frozen");
    }

     
    function freeze(address account, bool frozen) public onlyOwner {
  	    _frozenAccount[account] = frozen;
  	    emit FrozenAccount(account, frozen);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        frozenCheck(msg.sender);
        frozenCheck(_to);
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        frozenCheck(msg.sender);
        frozenCheck(_from);
        frozenCheck(_to);
        return super.transferFrom(_from, _to, _value);
    }   
}

contract AICCToken is FreezableToken {
    string public constant name = "AICloudChain";  
    string public constant symbol = "AICC";  
    uint8 public constant decimals = 18;
    uint256 private constant INIT_TOTALSUPPLY = 30000000;

    mapping (address => uint256) public releaseTime;
    mapping (address => uint256) public lockAmount;

    event LockToken(address indexed beneficiary, uint256 releaseTime, uint256 releaseAmount);
    event ReleaseToken(address indexed user, uint256 releaseAmount);

     
    constructor() public {
        _totalSupply = INIT_TOTALSUPPLY * 10 ** uint256(decimals);
        _owner = 0x06C7B9Ce4f2Fee058DE2A79F75DEC55092C229Aa;
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

     
    function lockToken(address _beneficiary, uint256 _releaseTime, uint256 _releaseAmount) public onlyOwner returns(bool) {
        require(lockAmount[_beneficiary] == 0, "The address has been locked");
        require(_beneficiary != address(0), "The target address cannot be the zero address");
        require(_releaseAmount > 0, "The amount must be greater than 0");
        require(_releaseTime > now, "The time must be greater than current time");
        frozenCheck(_beneficiary);
        lockAmount[_beneficiary] = _releaseAmount;
        releaseTime[_beneficiary] = _releaseTime;
        _balances[_owner] = _balances[_owner].sub(_releaseAmount);  
        emit LockToken(_beneficiary, _releaseTime, _releaseAmount);
        return true;
    }

     
    function releaseToken(address _owner) public whenNotPaused returns(bool) {
        frozenCheck(_owner);
        uint256 amount = releasableAmount(_owner);
        require(amount > 0, "No releasable tokens");
        _balances[_owner] = _balances[_owner].add(amount);
        lockAmount[_owner] = 0;
        emit ReleaseToken(_owner, amount);
        return true;
    }

     
    function releasableAmount(address addr) public view returns(uint256) {
        if(lockAmount[addr] != 0 && now > releaseTime[addr]) {
            return lockAmount[addr];
        } else {
            return 0;
        }
     }
    
     
    function transfer(address to, uint256 value) public returns (bool) {
        if(releasableAmount(msg.sender) > 0) {
            releaseToken(msg.sender);
        }
        return super.transfer(to, value);
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        if(releasableAmount(from) > 0) {
            releaseToken(from);
        }
        return super.transferFrom(from, to, value);
    }

     
    function batchTransfer(address[] memory addressList, uint256[] memory amountList) public onlyOwner returns (bool) {
        uint256 length = addressList.length;
        require(addressList.length == amountList.length, "Inconsistent array length");
        require(length > 0 && length <= 150, "Invalid number of transfer objects");
        uint256 amount;
        for (uint256 i = 0; i < length; i++) {
            frozenCheck(addressList[i]);
            require(amountList[i] > 0, "The transfer amount cannot be 0");
            require(addressList[i] != address(0), "Cannot transfer to the zero address");
            amount = amount.add(amountList[i]);
            _balances[addressList[i]] = _balances[addressList[i]].add(amountList[i]);
            emit Transfer(msg.sender, addressList[i], amountList[i]);
        }
        require(_balances[msg.sender] >= amount, "Not enough tokens to transfer");
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        return true;
    }
}