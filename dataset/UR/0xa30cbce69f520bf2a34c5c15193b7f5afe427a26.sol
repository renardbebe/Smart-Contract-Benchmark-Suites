 

pragma solidity 0.4.24;

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = false;
  }

   
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

 

contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() public {
    pausers.add(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function renouncePauser() public {
    pausers.remove(msg.sender);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

 

 
contract Pausable is PauserRole {
  event Paused();
  event Unpaused();

  bool private _paused = false;


   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

   
  modifier whenPaused() {
    require(_paused);
    _;
  }

   
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused();
  }

   
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused();
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

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 

 
contract Ownable {
  address private _owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    _owner = msg.sender;
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 

contract OperatorRole is Ownable {
    using Roles for Roles.Role;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    Roles.Role private operators;

    constructor() public {
        operators.add(msg.sender);
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender));
        _;
    }
    
    function isOperator(address account) public view returns (bool) {
        return operators.has(account);
    }

    function addOperator(address account) public onlyOwner() {
        operators.add(account);
        emit OperatorAdded(account);
    }

    function removeOperator(address account) public onlyOwner() {
        operators.remove(account);
        emit OperatorRemoved(account);
    }

}

 

contract ReferrerRole is OperatorRole {
    using Roles for Roles.Role;

    event ReferrerAdded(address indexed account);
    event ReferrerRemoved(address indexed account);

    Roles.Role private referrers;

    uint32 internal index;
    mapping(uint32 => address) internal indexToAddress;
    mapping(address => uint32) internal addressToIndex;

    modifier onlyReferrer() {
        require(isReferrer(msg.sender));
        _;
    }

    function getNumberOfAddresses() public view onlyOperator() returns (uint32) {
        return index;
    }

    function addressOfIndex(uint32 _index) onlyOperator() public view returns (address) {
        return indexToAddress[_index];
    }
    
    function isReferrer(address _account) public view returns (bool) {
        return referrers.has(_account);
    }

    function addReferrer(address _account) public onlyOperator() {
        referrers.add(_account);
        indexToAddress[index] = _account;
        addressToIndex[_account] = index;
        index++;
        emit ReferrerAdded(_account);
    }

    function removeReferrer(address _account) public onlyOperator() {
        referrers.remove(_account);
        indexToAddress[addressToIndex[_account]] = address(0x0);
        emit ReferrerRemoved(_account);
    }

}

 

contract DailyAction is Ownable, Pausable {
    using SafeMath for uint256;

    mapping(address => uint256) public latestActionTime;
    uint256 public term;

    event Action(
        address indexed user,
        address indexed referrer,
        uint256 at
    );

    event UpdateTerm(
        uint256 term
    );
    
    constructor() public {
        term = 86400;
    }

    function withdrawEther() external onlyOwner() {
        owner().transfer(address(this).balance);
    }

    function updateTerm(uint256 num) external onlyOwner() {
        term = num;

        emit UpdateTerm(
            term
        );
    }

    function requestDailyActionReward(address referrer) external whenNotPaused() {
        require(!isInTerm(msg.sender), "this sender got daily reward within term");

        emit Action(
            msg.sender,
            referrer,
            block.timestamp
        );

        latestActionTime[msg.sender] = block.timestamp;
    }

    function isInTerm(address sender) public view returns (bool) {
        if (latestActionTime[sender] == 0) {
            return false;
        } else if (block.timestamp >= latestActionTime[sender].add(term)) {
            return false;
        }
        return true;
    }
}

 

contract GumGateway is ReferrerRole, Pausable, DailyAction {
    using SafeMath for uint256;

    uint256 internal ethBackRate;
    uint256 public minimumAmount;

    event Sold(
        address indexed user,
        address indexed referrer,
        uint256 value,
        uint256 at
    );
    
    constructor() public {
        minimumAmount = 10000000000000000;
    }
    
    function updateEthBackRate(uint256 _newEthBackRate) external onlyOwner() {
        ethBackRate = _newEthBackRate;
    }

    function updateMinimumAmount(uint256 _newMinimumAmount) external onlyOwner() {
        minimumAmount = _newMinimumAmount;
    }

    function getEthBackRate() external onlyOwner() view returns (uint256) {
        return ethBackRate;
    }

    function withdrawEther() external onlyOwner() {
        owner().transfer(address(this).balance);
    }

    function buy(address _referrer) external payable whenNotPaused() {
        require(msg.value >= minimumAmount, "msg.value should be more than minimum ether amount");
        
        address referrer;
        if (_referrer == msg.sender){
            referrer = address(0x0);
        } else {
            referrer = _referrer;
        }
        if ((referrer != address(0x0)) && isReferrer(referrer)) {
            referrer.transfer(msg.value.mul(ethBackRate).div(100));
        }
        emit Sold(
            msg.sender,
            referrer,
            msg.value,
            block.timestamp
        );
    }

}