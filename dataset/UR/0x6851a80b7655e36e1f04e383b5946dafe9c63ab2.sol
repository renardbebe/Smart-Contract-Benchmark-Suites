 

pragma solidity ^0.4.24;

 
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



 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

   
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

   
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

   
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}



 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    view
    public
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    view
    public
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}


 
contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";

   
  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }

   
  function addAddressToWhitelist(address _operator)
    onlyOwner
    public
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

   
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

   
  function addAddressesToWhitelist(address[] _operators)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

   
  function removeAddressFromWhitelist(address _operator)
    onlyOwner
    public
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

   
  function removeAddressesFromWhitelist(address[] _operators)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}

contract ClubAccessControl is Whitelist {
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }
}

contract HKHcoinInterface {
    mapping (address => uint256) public balanceOf;
    function mintToken(address target, uint256 mintedAmount) public;
    function burnFrom(address _from, uint256 _value) public returns (bool success);
}

contract PlayerFactory is ClubAccessControl {
    struct Player {
        bool isFreezed;
        bool isExist;
    }

    mapping (address => Player) public players;
    HKHcoinInterface hkhconinContract;
    uint initCoins = 1000000;

    modifier onlyIfPlayerNotFreezed(address _playerAddress) { 
        require (!players[_playerAddress].isFreezed);
        _; 
    }
    
    modifier onlyIfPlayerExist(address _playerAddress) { 
        require (players[_playerAddress].isExist);
        _; 
    }

    event NewPlayer(address indexed _playerAddress);

    function setHKHcoinAddress(address _address) 
        external
        onlyIfWhitelisted(msg.sender)
    {
        hkhconinContract = HKHcoinInterface(_address);
    }

    function getBalanceOfPlayer(address _playerAddress)
        public
        onlyIfPlayerExist(_playerAddress)
        view
        returns (uint)
    {
        return hkhconinContract.balanceOf(_playerAddress);
    }

    function joinClub(address _playerAddress)
        external
        onlyIfWhitelisted(msg.sender)
        whenNotPaused
    {
        require(!players[_playerAddress].isExist);
        players[_playerAddress] = Player(false, true);
        hkhconinContract.mintToken(_playerAddress, initCoins);
        emit NewPlayer(_playerAddress);
    }

    function reset(address _playerAddress)
        external
        onlyIfWhitelisted(msg.sender)
        onlyIfPlayerExist(_playerAddress)
        whenNotPaused
    {
        uint balance = hkhconinContract.balanceOf(_playerAddress);

        if(balance > initCoins)
            _destroy(_playerAddress, balance - initCoins);
        else if(balance < initCoins)
            _recharge(_playerAddress, initCoins - balance);

        emit NewPlayer(_playerAddress);
    }

    function recharge(address _playerAddress, uint _amount)
        public
        onlyIfWhitelisted(msg.sender)
        onlyIfPlayerExist(_playerAddress)
        whenNotPaused
    {
        _recharge(_playerAddress, _amount);
    }

    function destroy(address _playerAddress, uint _amount)
        public
        onlyIfWhitelisted(msg.sender)
        onlyIfPlayerExist(_playerAddress)
        whenNotPaused
    {
        _destroy(_playerAddress, _amount);
    }

    function freezePlayer(address _playerAddress)
        public
        onlyIfWhitelisted(msg.sender)
        onlyIfPlayerExist(_playerAddress)
        whenNotPaused
    {
        players[_playerAddress].isFreezed = true;
    }

    function resumePlayer(address _playerAddress)
        public
        onlyIfWhitelisted(msg.sender)
        onlyIfPlayerExist(_playerAddress)
        whenNotPaused
    {
        players[_playerAddress].isFreezed = false;
    }

    function _recharge(address _playerAddress, uint _amount)
        internal
    {
        hkhconinContract.mintToken(_playerAddress, _amount);
    }

    function _destroy(address _playerAddress, uint _amount)
        internal
    {
        hkhconinContract.burnFrom(_playerAddress, _amount);
    }
}

 
contract LotteryFactory is PlayerFactory {

    event BuyLottery(
        uint32 _id,
        address indexed _playerAddress,
        string _betline,
        string _place,
        uint32 _betAmount,
        uint32 indexed _date,
        uint8 indexed _race
    );

    event Dividend(
        uint32 _id,
        uint32 _dividend
    );

    event Refund(
        uint32 _id,
        uint32 _refund
    );

    struct Lottery {
        uint32 betAmount;
        uint32 dividend;
        uint32 refund;
        uint32 date;
        uint8 race;
        bool isPaid;
        string betline;
        string place;
    }

    Lottery[] public lotteries;

    mapping (uint => address) public lotteryToOwner;
    mapping (address => uint) ownerLotteryCount;

    constructor() public {
        addAddressToWhitelist(msg.sender);
    }

    function getLotteriesByOwner(address _owner) 
        view 
        external 
        onlyIfPlayerExist(_owner) 
        returns(uint[]) 
    {
        uint[] memory result = new uint[](ownerLotteryCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < lotteries.length; i++) {
            if (lotteryToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function createLottery(
        address _playerAddress,
        string _betline, 
        string _place,
        uint32 _betAmount,
        uint32 _date,
        uint8 _race
    )
        external
        onlyIfWhitelisted(msg.sender)
        onlyIfPlayerExist(_playerAddress)
        onlyIfPlayerNotFreezed(_playerAddress)
        whenNotPaused
    {
        uint32 id = uint32(lotteries.push(Lottery(_betAmount, 0, 0, _date, _race, false, _betline, _place))) - 1;
        lotteryToOwner[id] = _playerAddress;
        ownerLotteryCount[_playerAddress]++;
        _destroy(_playerAddress, _betAmount);
        emit BuyLottery(
            id,
            _playerAddress,
            _betline,
            _place,
            _betAmount,
            _date,
            _race
        );
    }

    function setDividendAndPayOut(
        uint32 _id,
        uint32 _dividend,
        uint32 _refund
    )
        external
        onlyIfWhitelisted(msg.sender)
        whenNotPaused
    {
        if(lotteries[_id].isPaid == false) {
            lotteries[_id].dividend = _dividend;
            lotteries[_id].refund = _refund;

            if(lotteries[_id].dividend > 0) {
                emit Dividend(
                    _id,
                    lotteries[_id].dividend
                );
            }

            if(lotteries[_id].refund > 0) {
                emit Refund(
                    _id,
                    lotteries[_id].refund
                );
            }

            _recharge(lotteryToOwner[_id], lotteries[_id].dividend + lotteries[_id].refund);
            lotteries[_id].isPaid = true;
        }
    }
}