 

pragma solidity ^0.4.24;


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
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


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


 
contract VeloxToken is ERC20, Ownable {
    using SafeMath for uint256;

    string public constant name = "Velox";
    string public constant symbol = "VLX";
    uint8 public constant decimals = 2;

    uint256 public constant STAKE_MIN_AGE = 64 seconds * 20;  
    uint256 public constant STAKE_APR = 13;  
    uint256 public constant MAX_TOTAL_SUPPLY = 100 * (10 ** (6 + uint256(decimals)));  
    
    bool public balancesInitialized = false;
    
    struct transferIn {
        uint64 amount;
        uint64 time;
    }

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    mapping (address => transferIn[]) transferIns;
    uint256 private totalSupply_;

    event Mint(address indexed to, uint256 amount);

    modifier canMint() {
        require(totalSupply_ < MAX_TOTAL_SUPPLY);
        _;
    }

     
    constructor() public {
        totalSupply_ = 0;
    }

     
    function mint() public canMint returns (bool) {
        if (balances[msg.sender] <= 0) return false;
        if (transferIns[msg.sender].length <= 0) return false;

        uint reward = _getStakingReward(msg.sender);
        if (reward <= 0) return false;

        _mint(msg.sender, reward);
        emit Mint(msg.sender, reward);
        return true;
    }

     
    function getCoinAge() external view returns (uint256) {
        return _getCoinAge(msg.sender, block.timestamp);
    }

     
    function _getStakingReward(address _address) internal view returns (uint256) {
        uint256 coinAge = _getCoinAge(_address, block.timestamp);  
        if (coinAge <= 0) return 0;
        return (coinAge * STAKE_APR).div(365 * 100);  
    }

     
    function _getCoinAge(address _address, uint256 _now) internal view returns (uint256 _coinAge) {
        if (transferIns[_address].length <= 0) return 0;

        for (uint256 i = 0; i < transferIns[_address].length; i++) {
            if (_now < uint256(transferIns[_address][i].time).add(STAKE_MIN_AGE)) continue;
            uint256 coinSeconds = _now.sub(uint256(transferIns[_address][i].time));
            _coinAge = _coinAge.add(uint256(transferIns[_address][i].amount).mul(coinSeconds).div(1 days));
        }
    }

     
    function initBalances(address[] _accounts, uint64[] _amounts) external onlyOwner {
        require(!balancesInitialized);
        require(_accounts.length > 0 && _accounts.length == _amounts.length);

        uint256 total = 0;
        for (uint256 i = 0; i < _amounts.length; i++) total = total.add(uint256(_amounts[i]));
        require(total <= MAX_TOTAL_SUPPLY);

        for (uint256 j = 0; j < _accounts.length; j++) _mint(_accounts[j], uint256(_amounts[j]));
    }

     
    function completeInitialization() external onlyOwner {
        require(!balancesInitialized);
        balancesInitialized = true;
    }

     
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
        if (msg.sender == _to) return mint();
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        if (transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 time = uint64(block.timestamp);
        transferIns[msg.sender].push(transferIn(uint64(balances[msg.sender]), time));
        transferIns[_to].push(transferIn(uint64(_value), time));
        return true;
    }

     
    function batchTransfer(address[] _to, uint256[] _values) public returns (bool) {
        require(_to.length == _values.length);
        for (uint256 i = 0; i < _to.length; i++) require(transfer(_to[i], _values[i]));
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
        if (transferIns[_from].length > 0) delete transferIns[_from];
        uint64 time = uint64(block.timestamp);
        transferIns[_from].push(transferIn(uint64(balances[_from]), time));
        transferIns[_to].push(transferIn(uint64(_value), time));
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

     
    function _mint(address _account, uint256 _amount) internal {
        require(_account != 0);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_account] = balances[_account].add(_amount);
        if (transferIns[_account].length > 0) delete transferIns[_account];
        transferIns[_account].push(transferIn(uint64(balances[_account]), uint64(block.timestamp)));
        emit Transfer(address(0), _account, _amount);
    }
}