 

 

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

 

pragma solidity ^0.4.24;


 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

   
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

   
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

   
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

 

pragma solidity ^0.4.24;



 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    public
    view
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

 

pragma solidity ^0.4.24;




 
contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";

   
  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }

   
  function addAddressToWhitelist(address _operator)
    public
    onlyOwner
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
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

   
  function removeAddressFromWhitelist(address _operator)
    public
    onlyOwner
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

   
  function removeAddressesFromWhitelist(address[] _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}

 

pragma solidity ^0.4.24;



 
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

 

pragma solidity 0.4.24;

interface IKODAV2SelfServiceEditionCuration {

  function createActiveEdition(
    uint256 _editionNumber,
    bytes32 _editionData,
    uint256 _editionType,
    uint256 _startDate,
    uint256 _endDate,
    address _artistAccount,
    uint256 _artistCommission,
    uint256 _priceInWei,
    string _tokenUri,
    uint256 _totalAvailable
  ) external returns (bool);

  function artistsEditions(address _artistsAccount) external returns (uint256[1] _editionNumbers);

  function totalAvailableEdition(uint256 _editionNumber) external returns (uint256);

  function highestEditionNumber() external returns (uint256);

  function updateOptionalCommission(uint256 _editionNumber, uint256 _rate, address _recipient) external;

  function updateStartDate(uint256 _editionNumber, uint256 _startDate) external;

  function updateEndDate(uint256 _editionNumber, uint256 _endDate) external;

  function updateEditionType(uint256 _editionNumber, uint256 _editionType) external;
}

 

pragma solidity 0.4.24;

interface IKODAAuction {
  function setArtistsControlAddressAndEnabledEdition(uint256 _editionNumber, address _address) external;
}

 

pragma solidity 0.4.24;

interface ISelfServiceAccessControls {

  function isEnabledForAccount(address account) public view returns (bool);

}

 

pragma solidity 0.4.24;

interface ISelfServiceFrequencyControls {

   
  function canCreateNewEdition(address artist) external view returns (bool);

   
  function recordSuccessfulMint(address artist, uint256 totalAvailable, uint256 priceInWei) external returns (bool);
}

 

pragma solidity 0.4.24;








 
contract SelfServiceEditionCurationV4 is Whitelist, Pausable {
  using SafeMath for uint256;

  event SelfServiceEditionCreated(
    uint256 indexed _editionNumber,
    address indexed _creator,
    uint256 _priceInWei,
    uint256 _totalAvailable,
    bool _enableAuction
  );

   
  IKODAV2SelfServiceEditionCuration public kodaV2;
  IKODAAuction public auction;
  ISelfServiceAccessControls public accessControls;
  ISelfServiceFrequencyControls public frequencyControls;

   
  uint256 public koCommission = 15;

   
  uint256 public maxEditionSize = 100;

   
  uint256 public minPricePerEdition = 0.01 ether;

   
  constructor(
    IKODAV2SelfServiceEditionCuration _kodaV2,
    IKODAAuction _auction,
    ISelfServiceAccessControls _accessControls,
    ISelfServiceFrequencyControls _frequencyControls
  ) public {
    super.addAddressToWhitelist(msg.sender);
    kodaV2 = _kodaV2;
    auction = _auction;
    accessControls = _accessControls;
    frequencyControls = _frequencyControls;
  }

   
  function createEdition(
    bool _enableAuction,
    address _optionalSplitAddress,
    uint256 _optionalSplitRate,
    uint256 _totalAvailable,
    uint256 _priceInWei,
    uint256 _startDate,
    uint256 _endDate,
    uint256 _artistCommission,
    uint256 _editionType,
    string _tokenUri
  )
  public
  whenNotPaused
  returns (uint256 _editionNumber)
  {
    require(frequencyControls.canCreateNewEdition(msg.sender), 'Sender currently frozen out of creation');
    require(_artistCommission.add(_optionalSplitRate).add(koCommission) <= 100, "Total commission exceeds 100");

    uint256 editionNumber = _createEdition(
      msg.sender,
      _enableAuction,
      [_totalAvailable, _priceInWei, _startDate, _endDate, _artistCommission, _editionType],
      _tokenUri
    );

    if (_optionalSplitRate > 0 && _optionalSplitAddress != address(0)) {
      kodaV2.updateOptionalCommission(editionNumber, _optionalSplitRate, _optionalSplitAddress);
    }

    frequencyControls.recordSuccessfulMint(msg.sender, _totalAvailable, _priceInWei);

    return editionNumber;
  }

   
  function createEditionSimple(
    bool _enableAuction,
    uint256 _totalAvailable,
    uint256 _priceInWei,
    uint256 _startDate,
    uint256 _endDate,
    uint256 _artistCommission,
    uint256 _editionType,
    string _tokenUri
  )
  public
  whenNotPaused
  returns (uint256 _editionNumber)
  {
    require(frequencyControls.canCreateNewEdition(msg.sender), 'Sender currently frozen out of creation');
    require(_artistCommission.add(koCommission) <= 100, "Total commission exceeds 100");

    uint256 editionNumber = _createEdition(
      msg.sender,
      _enableAuction,
      [_totalAvailable, _priceInWei, _startDate, _endDate, _artistCommission, _editionType],
      _tokenUri
    );

    frequencyControls.recordSuccessfulMint(msg.sender, _totalAvailable, _priceInWei);

    return editionNumber;
  }

   
  function createEditionFor(
    address _artist,
    bool _enableAuction,
    address _optionalSplitAddress,
    uint256 _optionalSplitRate,
    uint256 _totalAvailable,
    uint256 _priceInWei,
    uint256 _startDate,
    uint256 _endDate,
    uint256 _artistCommission,
    uint256 _editionType,
    string _tokenUri
  )
  public
  onlyIfWhitelisted(msg.sender)
  returns (uint256 _editionNumber)
  {
    require(_artistCommission.add(_optionalSplitRate).add(koCommission) <= 100, "Total commission exceeds 100");

    uint256 editionNumber = _createEdition(
      _artist,
      _enableAuction,
      [_totalAvailable, _priceInWei, _startDate, _endDate, _artistCommission, _editionType],
      _tokenUri
    );

    if (_optionalSplitRate > 0 && _optionalSplitAddress != address(0)) {
      kodaV2.updateOptionalCommission(editionNumber, _optionalSplitRate, _optionalSplitAddress);
    }

    frequencyControls.recordSuccessfulMint(_artist, _totalAvailable, _priceInWei);

    return editionNumber;
  }

   
  function _createEdition(
    address _artist,
    bool _enableAuction,
    uint256[6] memory _params,
    string _tokenUri
  )
  internal
  returns (uint256 _editionNumber) {

    uint256 _totalAvailable = _params[0];
    uint256 _priceInWei = _params[1];

     
    require(msg.sender == owner || (_totalAvailable > 0 && _totalAvailable <= maxEditionSize), "Invalid edition size");

     
    require(msg.sender == owner || _priceInWei >= minPricePerEdition, "Invalid price");

     
    require(msg.sender == owner || accessControls.isEnabledForAccount(_artist), "Not allowed to create edition");

     
    uint256 editionNumber = getNextAvailableEditionNumber();

    require(
      kodaV2.createActiveEdition(
        editionNumber,
        0x0,  
        _params[5],  
        _params[2],  
        _params[3],  
        _artist,
        _params[4],  
        _priceInWei,
        _tokenUri,
        _totalAvailable
      ),
      "Failed to create new edition"
    );

     
    if (_enableAuction) {
      auction.setArtistsControlAddressAndEnabledEdition(editionNumber, _artist);
    }

     
    emit SelfServiceEditionCreated(editionNumber, _artist, _priceInWei, _totalAvailable, _enableAuction);

    return editionNumber;
  }

   
  function getNextAvailableEditionNumber() internal returns (uint256 editionNumber) {

     
    uint256 highestEditionNumber = kodaV2.highestEditionNumber();
    uint256 totalAvailableEdition = kodaV2.totalAvailableEdition(highestEditionNumber);

     
    uint256 nextAvailableEditionNumber = highestEditionNumber.add(totalAvailableEdition).add(1);

     
    return ((nextAvailableEditionNumber + maxEditionSize - 1) / maxEditionSize) * maxEditionSize;
  }

   
  function setKodavV2(IKODAV2SelfServiceEditionCuration _kodaV2) onlyIfWhitelisted(msg.sender) public {
    kodaV2 = _kodaV2;
  }

   
  function setAuction(IKODAAuction _auction) onlyIfWhitelisted(msg.sender) public {
    auction = _auction;
  }

   
  function setKoCommission(uint256 _koCommission) onlyIfWhitelisted(msg.sender) public {
    koCommission = _koCommission;
  }

   
  function setMaxEditionSize(uint256 _maxEditionSize) onlyIfWhitelisted(msg.sender) public {
    maxEditionSize = _maxEditionSize;
  }

   
  function setMinPricePerEdition(uint256 _minPricePerEdition) onlyIfWhitelisted(msg.sender) public {
    minPricePerEdition = _minPricePerEdition;
  }

   
  function isFrozen(address account) public view returns (bool) {
    return frequencyControls.canCreateNewEdition(account);
  }

   
  function isEnabledForAccount(address account) public view returns (bool) {
    return accessControls.isEnabledForAccount(account);
  }

   
  function canCreateAnotherEdition(address account) public view returns (bool) {
    if (!accessControls.isEnabledForAccount(account)) {
      return false;
    }
    return frequencyControls.canCreateNewEdition(account);
  }

   
  function withdrawStuckEther(address _withdrawalAccount) onlyIfWhitelisted(msg.sender) public {
    require(_withdrawalAccount != address(0), "Invalid address provided");
    _withdrawalAccount.transfer(address(this).balance);
  }
}