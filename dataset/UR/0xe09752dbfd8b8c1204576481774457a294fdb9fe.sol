 

pragma solidity 0.4.24;

 

 
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

 

 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

 

 
interface DelegateReference {
     
    function stake(uint256 _amount) external;

     
    function unstake(uint256 _amount) external;

     
    function stakeOf(address _staker) external view returns (uint256);

     
    function setAerumAddress(address _aerum) external;
}

 

 
contract MultiVestingWallet is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    event Released(address indexed account, uint256 amount);
    event Revoked(address indexed account);
    event UnRevoked(address indexed account);
    event ReturnTokens(uint256 amount);
    event Promise(address indexed account, uint256 amount);
    event Stake(address indexed delegate, uint256 amount);
    event Unstake(address indexed delegate, uint256 amount);

    ERC20 public token;

    uint256 public cliff;
    uint256 public start;
    uint256 public duration;
    uint256 public staked;

    bool public revocable;

    address[] public accounts;
    mapping(address => bool) public known;
    mapping(address => uint256) public promised;
    mapping(address => uint256) public released;
    mapping(address => bool) public revoked;

     
    constructor(
        address _token,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        bool _revocable
    )
    public
    {
        require(_token != address(0));
        require(_cliff <= _duration);

        token = ERC20(_token);
        revocable = _revocable;
        duration = _duration;
        cliff = _start.add(_cliff);
        start = _start;
    }

     
    function release() external {
        _release(msg.sender);
    }

     
    function releaseBatch(address[] _addresses) external {
        for (uint256 index = 0; index < _addresses.length; index++) {
            _release(_addresses[index]);
        }
    }

     
    function releaseBatchPaged(uint256 _start, uint256 _count) external {
        uint256 last = _start.add(_count);
        if (last > accounts.length) {
            last = accounts.length;
        }

        for (uint256 index = _start; index < last; index++) {
            _release(accounts[index]);
        }
    }

     
    function releaseAll() external {
        for (uint256 index = 0; index < accounts.length; index++) {
            _release(accounts[index]);
        }
    }

     
    function _release(address _beneficiary) internal {
        uint256 amount = releasableAmount(_beneficiary);
        if (amount > 0) {
            released[_beneficiary] = released[_beneficiary].add(amount);
            token.safeTransfer(_beneficiary, amount);

            emit Released(_beneficiary, amount);
        }
    }

     
    function revoke(address _beneficiary) public onlyOwner {
        require(revocable);
        require(!revoked[_beneficiary]);

        promised[_beneficiary] = vestedAmount(_beneficiary);
        revoked[_beneficiary] = true;

        emit Revoked(_beneficiary);
    }

     
    function revokeBatch(address[] _addresses) external onlyOwner {
        for (uint256 index = 0; index < _addresses.length; index++) {
            revoke(_addresses[index]);
        }
    }

     
    function unRevoke(address _beneficiary) public onlyOwner {
        require(revocable);
        require(revoked[_beneficiary]);

        revoked[_beneficiary] = false;

        emit UnRevoked(_beneficiary);
    }

     
    function unrevokeBatch(address[] _addresses) external onlyOwner {
        for (uint256 index = 0; index < _addresses.length; index++) {
            unRevoke(_addresses[index]);
        }
    }

     
    function releasableAmount(address _beneficiary) public view returns (uint256) {
        return vestedAmount(_beneficiary).sub(released[_beneficiary]);
    }

     
    function vestedAmount(address _beneficiary) public view returns (uint256) {
        uint256 totalPromised = promised[_beneficiary];

        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= start.add(duration) || revoked[_beneficiary]) {
            return totalPromised;
        } else {
            return totalPromised.mul(block.timestamp.sub(start)).div(duration);
        }
    }

     
    function remainingBalance() public view returns (uint256) {
        uint256 tokenBalance = token.balanceOf(address(this));
        uint256 totalPromised = 0;
        uint256 totalReleased = 0;

        for (uint256 index = 0; index < accounts.length; index++) {
            address account = accounts[index];
            totalPromised = totalPromised.add(promised[account]);
            totalReleased = totalReleased.add(released[account]);
        }

        uint256 promisedNotReleased = totalPromised.sub(totalReleased);
        if (promisedNotReleased > tokenBalance) {
            return 0;
        }
        return tokenBalance.sub(promisedNotReleased);
    }

     
    function totalPromised() public view returns (uint256) {
        uint256 total = 0;

        for (uint256 index = 0; index < accounts.length; index++) {
            address account = accounts[index];
            total = total.add(promised[account]);
        }

        return total;
    }

     
    function totalReleased() public view returns (uint256) {
        uint256 total = 0;

        for (uint256 index = 0; index < accounts.length; index++) {
            address account = accounts[index];
            total = total.add(released[account]);
        }

        return total;
    }

     
    function returnRemaining() external onlyOwner {
        uint256 remaining = remainingBalance();
        require(remaining > 0);

        token.safeTransfer(owner, remaining);

        emit ReturnTokens(remaining);
    }

     
    function returnAll() external onlyOwner {
        uint256 remaining = token.balanceOf(address(this));
        token.safeTransfer(owner, remaining);

        emit ReturnTokens(remaining);
    }

     
    function promise(address _beneficiary, uint256 _amount) public onlyOwner {
        if (!known[_beneficiary]) {
            known[_beneficiary] = true;
            accounts.push(_beneficiary);
        }

        promised[_beneficiary] = _amount;

        emit Promise(_beneficiary, _amount);
    }

     
    function promiseBatch(address[] _addresses, uint256[] _amounts) external onlyOwner {
        require(_addresses.length == _amounts.length);

        for (uint256 index = 0; index < _addresses.length; index++) {
            promise(_addresses[index], _amounts[index]);
        }
    }

     
    function getBeneficiaries() external view returns (address[]) {
        return accounts;
    }

     
    function getBeneficiariesCount() external view returns (uint256) {
        return accounts.length;
    }

     
    function stake(address _delegate, uint256 _amount) external onlyOwner {
        staked = staked.add(_amount);
        token.approve(_delegate, _amount);
        DelegateReference(_delegate).stake(_amount);

        emit Stake(_delegate, _amount);
    }

     
    function unstake(address _delegate, uint256 _amount) external onlyOwner {
        staked = staked.sub(_amount);
        DelegateReference(_delegate).unstake(_amount);

        emit Unstake(_delegate, _amount);
    }
}

 

 
contract ContractRegistry is Ownable {

    struct ContractRecord {
        address addr;
        bytes32 name;
        bool enabled;
    }

    address private token;

     
    mapping(bytes32 => ContractRecord) private contracts;
     
    bytes32[] private contractsName;

    event ContractAdded(bytes32 indexed _name);
    event ContractRemoved(bytes32 indexed _name);

    constructor(address _token) public {
        require(_token != address(0), "Token is required");
        token = _token;
    }

     
    function getContractByName(bytes32 _name) external view returns (address, bytes32, bool) {
        ContractRecord memory record = contracts[_name];
        if(record.addr == address(0) || !record.enabled) {
            return;
        }
        return (record.addr, record.name, record.enabled);
    }

     
    function getContractNames() external view returns (bytes32[]) {
        uint count = 0;
        for(uint i = 0; i < contractsName.length; i++) {
            if(contracts[contractsName[i]].enabled) {
                count++;
            }
        }
        bytes32[] memory result = new bytes32[](count);
        uint j = 0;
        for(i = 0; i < contractsName.length; i++) {
            if(contracts[contractsName[i]].enabled) {
                result[j] = contractsName[i];
                j++;
            }
        }
        return result;
    }

     
    function addContract(
        bytes32 _name,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        bool _revocable) external onlyOwner {
        require(contracts[_name].addr == address(0), "Contract's name should be unique");
        require(_cliff <= _duration, "Cliff shall be bigger than duration");

        MultiVestingWallet wallet = new MultiVestingWallet(token, _start, _cliff, _duration, _revocable);
        wallet.transferOwnership(msg.sender);
        address walletAddr = address(wallet);
        
        ContractRecord memory record = ContractRecord({
            addr: walletAddr,
            name: _name,
            enabled: true
        });
        contracts[_name] = record;
        contractsName.push(_name);

        emit ContractAdded(_name);
    }

     
    function setEnabled(bytes32 _name, bool enabled) external onlyOwner {
        ContractRecord memory record = contracts[_name];
        require(record.addr != address(0), "Contract with specified address does not exist");

        contracts[_name].enabled = enabled;
    }

      
    function setNewName(bytes32 _oldName, bytes32 _newName) external onlyOwner {
        require(contracts[_newName].addr == address(0), "Contract's name should be unique");

        ContractRecord memory record = contracts[_oldName];
        require(record.addr != address(0), "Contract's old name should be defined");

        record.name = _newName;
        contracts[_newName] = record;
        contractsName.push(_newName);

        delete contracts[_oldName];
        contractsName = removeByValue(contractsName, _oldName);
    }

    function removeByValue(bytes32[] memory _array, bytes32 _name) private pure returns(bytes32[]) {
        uint i = 0;
        uint j = 0;
        bytes32[] memory outArray = new bytes32[](_array.length - 1);
        while (i < _array.length) {
            if(_array[i] != _name) {
                outArray[j] = _array[i];
                j++;
            }
            i++;
        }
        return outArray;
    }
}