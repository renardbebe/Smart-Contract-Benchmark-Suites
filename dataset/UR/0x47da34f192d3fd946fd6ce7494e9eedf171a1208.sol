 

pragma solidity ^0.4.24;

 
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

 
interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool);
    function increaseApproval(address _spender, uint _addedValue) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
interface IModule {

     
    function getInitFunction() external pure returns (bytes4);

     
    function getPermissions() external view returns(bytes32[]);

     
    function takeFee(uint256 _amount) external returns(bool);

}

 
interface IModuleFactory {

    event ChangeFactorySetupFee(uint256 _oldSetupCost, uint256 _newSetupCost, address _moduleFactory);
    event ChangeFactoryUsageFee(uint256 _oldUsageCost, uint256 _newUsageCost, address _moduleFactory);
    event ChangeFactorySubscriptionFee(uint256 _oldSubscriptionCost, uint256 _newMonthlySubscriptionCost, address _moduleFactory);
    event GenerateModuleFromFactory(
        address _module,
        bytes32 indexed _moduleName,
        address indexed _moduleFactory,
        address _creator,
        uint256 _setupCost,
        uint256 _timestamp
    );
    event ChangeSTVersionBound(string _boundType, uint8 _major, uint8 _minor, uint8 _patch);

     
    function deploy(bytes _data) external returns(address);

     
    function getTypes() external view returns(uint8[]);

     
    function getName() external view returns(bytes32);

     
    function getInstructions() external view returns (string);

     
    function getTags() external view returns (bytes32[]);

     
    function changeFactorySetupFee(uint256 _newSetupCost) external;

     
    function changeFactoryUsageFee(uint256 _newUsageCost) external;

     
    function changeFactorySubscriptionFee(uint256 _newSubscriptionCost) external;

     
    function changeSTVersionBounds(string _boundType, uint8[] _newVersion) external;

    
    function getSetupCost() external view returns (uint256);

     
    function getLowerSTVersionBounds() external view returns(uint8[]);

      
    function getUpperSTVersionBounds() external view returns(uint8[]);

}

 
interface IModuleRegistry {

     
    function useModule(address _moduleFactory) external;

     
    function registerModule(address _moduleFactory) external;

     
    function removeModule(address _moduleFactory) external;

     
    function verifyModule(address _moduleFactory, bool _verified) external;

     
    function getReputationByFactory(address _factoryAddress) external view returns(address[]);

     
    function getTagsByTypeAndToken(uint8 _moduleType, address _securityToken) external view returns(bytes32[], address[]);

     
    function getTagsByType(uint8 _moduleType) external view returns(bytes32[], address[]);

     
    function getModulesByType(uint8 _moduleType) external view returns(address[]);

     
    function getModulesByTypeAndToken(uint8 _moduleType, address _securityToken) external view returns (address[]);

     
    function updateFromRegistry() external;

     
    function owner() external view returns(address);

     
    function isPaused() external view returns(bool);

}

 
interface IFeatureRegistry {

     
    function getFeatureStatus(string _nameKey) external view returns(bool);

}

 
contract Pausable {

    event Pause(uint256 _timestammp);
    event Unpause(uint256 _timestamp);

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

     
    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    
    function _pause() internal whenNotPaused {
        paused = true;
         
        emit Pause(now);
    }

     
    function _unpause() internal whenPaused {
        paused = false;
         
        emit Unpause(now);
    }

}

 
interface ISecurityToken {

     
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool);
    function increaseApproval(address _spender, uint _addedValue) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    function verifyTransfer(address _from, address _to, uint256 _value) external returns (bool success);

     
    function mint(address _investor, uint256 _value) external returns (bool success);

     
    function mintWithData(address _investor, uint256 _value, bytes _data) external returns (bool success);

     
    function burnFromWithData(address _from, uint256 _value, bytes _data) external;

     
    function burnWithData(uint256 _value, bytes _data) external;

    event Minted(address indexed _to, uint256 _value);
    event Burnt(address indexed _burner, uint256 _value);

     
     
     
    function checkPermission(address _delegate, address _module, bytes32 _perm) external view returns (bool);

     
    function getModule(address _module) external view returns(bytes32, address, address, bool, uint8, uint256, uint256);

     
    function getModulesByName(bytes32 _name) external view returns (address[]);

     
    function getModulesByType(uint8 _type) external view returns (address[]);

     
    function totalSupplyAt(uint256 _checkpointId) external view returns (uint256);

     
    function balanceOfAt(address _investor, uint256 _checkpointId) external view returns (uint256);

     
    function createCheckpoint() external returns (uint256);

     
    function getInvestors() external view returns (address[]);

     
    function getInvestorsAt(uint256 _checkpointId) external view returns(address[]);

     
    function iterateInvestors(uint256 _start, uint256 _end) external view returns(address[]);
    
     
    function currentCheckpointId() external view returns (uint256);

     
    function investors(uint256 _index) external view returns (address);

    
    function withdrawERC20(address _tokenContract, uint256 _value) external;

     
    function changeModuleBudget(address _module, uint256 _budget) external;

     
    function updateTokenDetails(string _newTokenDetails) external;

     
    function changeGranularity(uint256 _granularity) external;

     
    function pruneInvestors(uint256 _start, uint256 _iters) external;

     
    function freezeTransfers() external;

     
    function unfreezeTransfers() external;

     
    function freezeMinting() external;

     
    function mintMulti(address[] _investors, uint256[] _values) external returns (bool success);

     
    function addModule(
        address _moduleFactory,
        bytes _data,
        uint256 _maxCost,
        uint256 _budget
    ) external;

     
    function archiveModule(address _module) external;

     
    function unarchiveModule(address _module) external;

     
    function removeModule(address _module) external;

     
    function setController(address _controller) external;

     
    function forceTransfer(address _from, address _to, uint256 _value, bytes _data, bytes _log) external;

     
    function forceBurn(address _from, uint256 _value, bytes _data, bytes _log) external;

     
     function disableController() external;

      
     function getVersion() external view returns(uint8[]);

      
     function getInvestorCount() external view returns(uint256);

      
     function transferWithData(address _to, uint256 _value, bytes _data) external returns (bool success);

      
     function transferFromWithData(address _from, address _to, uint256 _value, bytes _data) external returns(bool);

      
     function granularity() external view returns(uint256);
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

 
contract Module is IModule {

    address public factory;

    address public securityToken;

    bytes32 public constant FEE_ADMIN = "FEE_ADMIN";

    IERC20 public polyToken;

     
    constructor (address _securityToken, address _polyAddress) public {
        securityToken = _securityToken;
        factory = msg.sender;
        polyToken = IERC20(_polyAddress);
    }

     
    modifier withPerm(bytes32 _perm) {
        bool isOwner = msg.sender == Ownable(securityToken).owner();
        bool isFactory = msg.sender == factory;
        require(isOwner||isFactory||ISecurityToken(securityToken).checkPermission(msg.sender, address(this), _perm), "Permission check failed");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == Ownable(securityToken).owner(), "Sender is not owner");
        _;
    }

    modifier onlyFactory {
        require(msg.sender == factory, "Sender is not factory");
        _;
    }

    modifier onlyFactoryOwner {
        require(msg.sender == Ownable(factory).owner(), "Sender is not factory owner");
        _;
    }

    modifier onlyFactoryOrOwner {
        require((msg.sender == Ownable(securityToken).owner()) || (msg.sender == factory), "Sender is not factory or owner");
        _;
    }

     
    function takeFee(uint256 _amount) public withPerm(FEE_ADMIN) returns(bool) {
        require(polyToken.transferFrom(securityToken, Ownable(factory).owner(), _amount), "Unable to take fee");
        return true;
    }
}

 
contract ITransferManager is Module, Pausable {

     
     
     
     
     
    enum Result {INVALID, NA, VALID, FORCE_VALID}

    function verifyTransfer(address _from, address _to, uint256 _amount, bytes _data, bool _isTransfer) public returns(Result);

    function unpause() public onlyOwner {
        super._unpause();
    }

    function pause() public onlyOwner {
        super._pause();
    }
}

 
contract ReclaimTokens is Ownable {

     
    function reclaimERC20(address _tokenContract) external onlyOwner {
        require(_tokenContract != address(0), "Invalid address");
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner, balance), "Transfer failed");
    }
}

 
contract PolymathRegistry is ReclaimTokens {

    mapping (bytes32 => address) public storedAddresses;

    event ChangeAddress(string _nameKey, address indexed _oldAddress, address indexed _newAddress);

     
    function getAddress(string _nameKey) external view returns(address) {
        bytes32 key = keccak256(bytes(_nameKey));
        require(storedAddresses[key] != address(0), "Invalid address key");
        return storedAddresses[key];
    }

     
    function changeAddress(string _nameKey, address _newAddress) external onlyOwner {
        bytes32 key = keccak256(bytes(_nameKey));
        emit ChangeAddress(_nameKey, storedAddresses[key], _newAddress);
        storedAddresses[key] = _newAddress;
    }


}

contract RegistryUpdater is Ownable {

    address public polymathRegistry;
    address public moduleRegistry;
    address public securityTokenRegistry;
    address public featureRegistry;
    address public polyToken;

    constructor (address _polymathRegistry) public {
        require(_polymathRegistry != address(0), "Invalid address");
        polymathRegistry = _polymathRegistry;
    }

    function updateFromRegistry() public onlyOwner {
        moduleRegistry = PolymathRegistry(polymathRegistry).getAddress("ModuleRegistry");
        securityTokenRegistry = PolymathRegistry(polymathRegistry).getAddress("SecurityTokenRegistry");
        featureRegistry = PolymathRegistry(polymathRegistry).getAddress("FeatureRegistry");
        polyToken = PolymathRegistry(polymathRegistry).getAddress("PolyToken");
    }

}

 
library Util {

    
    function upper(string _base) internal pure returns (string) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            bytes1 b1 = _baseBytes[i];
            if (b1 >= 0x61 && b1 <= 0x7A) {
                b1 = bytes1(uint8(b1)-32);
            }
            _baseBytes[i] = b1;
        }
        return string(_baseBytes);
    }

     
     
    function stringToBytes32(string memory _source) internal pure returns (bytes32) {
        return bytesToBytes32(bytes(_source), 0);
    }

     
     
    function bytesToBytes32(bytes _b, uint _offset) internal pure returns (bytes32) {
        bytes32 result;

        for (uint i = 0; i < _b.length; i++) {
            result |= bytes32(_b[_offset + i] & 0xFF) >> (i * 8);
        }
        return result;
    }

     
    function bytes32ToString(bytes32 _source) internal pure returns (string result) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(_source) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

     
    function getSig(bytes _data) internal pure returns (bytes4 sig) {
        uint len = _data.length < 4 ? _data.length : 4;
        for (uint i = 0; i < len; i++) {
            sig = bytes4(uint(sig) + uint(_data[i]) * (2 ** (8 * (len - 1 - i))));
        }
    }


}

 
contract ReentrancyGuard {

   
  bool private reentrancyLock = false;

   
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
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

   
  function increaseApproval(
    address _spender,
    uint _addedValue
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
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

 
interface IPermissionManager {

     
    function checkPermission(address _delegate, address _module, bytes32 _perm) external view returns(bool);

     
    function addDelegate(address _delegate, bytes32 _details) external;

     
    function deleteDelegate(address _delegate) external;

     
    function checkDelegate(address _potentialDelegate) external view returns(bool);

     
    function changePermission(
        address _delegate,
        address _module,
        bytes32 _perm,
        bool _valid
    )
    external;

     
    function changePermissionMulti(
        address _delegate,
        address[] _modules,
        bytes32[] _perms,
        bool[] _valids
    )
    external;

     
    function getAllDelegatesWithPerm(address _module, bytes32 _perm) external view returns(address[]);

      
    function getAllModulesAndPermsFromTypes(address _delegate, uint8[] _types) external view returns(address[], bytes32[]);

     
    function getPermissions() external view returns(bytes32[]);

     
    function getAllDelegates() external view returns(address[]);

}

library TokenLib {

    using SafeMath for uint256;

     
    struct ModuleData {
        bytes32 name;
        address module;
        address moduleFactory;
        bool isArchived;
        uint8[] moduleTypes;
        uint256[] moduleIndexes;
        uint256 nameIndex;
    }

     
    struct Checkpoint {
        uint256 checkpointId;
        uint256 value;
    }

    struct InvestorDataStorage {
         
        mapping (address => bool) investorListed;
         
        address[] investors;
         
        uint256 investorCount;
    }

     
    event ModuleArchived(uint8[] _types, address _module, uint256 _timestamp);
     
    event ModuleUnarchived(uint8[] _types, address _module, uint256 _timestamp);

     
    function archiveModule(ModuleData storage _moduleData, address _module) public {
        require(!_moduleData.isArchived, "Module archived");
        require(_moduleData.module != address(0), "Module missing");
         
        emit ModuleArchived(_moduleData.moduleTypes, _module, now);
        _moduleData.isArchived = true;
    }

     
    function unarchiveModule(ModuleData storage _moduleData, address _module) public {
        require(_moduleData.isArchived, "Module unarchived");
         
        emit ModuleUnarchived(_moduleData.moduleTypes, _module, now);
        _moduleData.isArchived = false;
    }

     
    function checkPermission(address[] storage _modules, address _delegate, address _module, bytes32 _perm) public view returns(bool) {
        if (_modules.length == 0) {
            return false;
        }

        for (uint8 i = 0; i < _modules.length; i++) {
            if (IPermissionManager(_modules[i]).checkPermission(_delegate, _module, _perm)) {
                return true;
            }
        }

        return false;
    }

     
    function getValueAt(Checkpoint[] storage _checkpoints, uint256 _checkpointId, uint256 _currentValue) public view returns(uint256) {
         
        if (_checkpointId == 0) {
            return 0;
        }
        if (_checkpoints.length == 0) {
            return _currentValue;
        }
        if (_checkpoints[0].checkpointId >= _checkpointId) {
            return _checkpoints[0].value;
        }
        if (_checkpoints[_checkpoints.length - 1].checkpointId < _checkpointId) {
            return _currentValue;
        }
        if (_checkpoints[_checkpoints.length - 1].checkpointId == _checkpointId) {
            return _checkpoints[_checkpoints.length - 1].value;
        }
        uint256 min = 0;
        uint256 max = _checkpoints.length - 1;
        while (max > min) {
            uint256 mid = (max + min) / 2;
            if (_checkpoints[mid].checkpointId == _checkpointId) {
                max = mid;
                break;
            }
            if (_checkpoints[mid].checkpointId < _checkpointId) {
                min = mid + 1;
            } else {
                max = mid;
            }
        }
        return _checkpoints[max].value;
    }

     
    function adjustCheckpoints(TokenLib.Checkpoint[] storage _checkpoints, uint256 _newValue, uint256 _currentCheckpointId) public {
         
        if (_currentCheckpointId == 0) {
            return;
        }
         
        if ((_checkpoints.length > 0) && (_checkpoints[_checkpoints.length - 1].checkpointId == _currentCheckpointId)) {
            return;
        }
         
        _checkpoints.push(
            TokenLib.Checkpoint({
                checkpointId: _currentCheckpointId,
                value: _newValue
            })
        );
    }

     
    function adjustInvestorCount(
        InvestorDataStorage storage _investorData,
        address _from,
        address _to,
        uint256 _value,
        uint256 _balanceTo,
        uint256 _balanceFrom
        ) public  {
        if ((_value == 0) || (_from == _to)) {
            return;
        }
         
        if ((_balanceTo == 0) && (_to != address(0))) {
            _investorData.investorCount = (_investorData.investorCount).add(1);
        }
         
        if (_value == _balanceFrom) {
            _investorData.investorCount = (_investorData.investorCount).sub(1);
        }
         
        if (!_investorData.investorListed[_to] && (_to != address(0))) {
            _investorData.investors.push(_to);
            _investorData.investorListed[_to] = true;
        }

    }

}

 
contract SecurityToken is StandardToken, DetailedERC20, ReentrancyGuard, RegistryUpdater {
    using SafeMath for uint256;

    TokenLib.InvestorDataStorage investorData;

     
    struct SemanticVersion {
        uint8 major;
        uint8 minor;
        uint8 patch;
    }

    SemanticVersion securityTokenVersion;

     
    string public tokenDetails;

    uint8 constant PERMISSION_KEY = 1;
    uint8 constant TRANSFER_KEY = 2;
    uint8 constant MINT_KEY = 3;
    uint8 constant CHECKPOINT_KEY = 4;
    uint8 constant BURN_KEY = 5;

    uint256 public granularity;

     
    uint256 public currentCheckpointId;

     
    bool public transfersFrozen;

     
    bool public mintingFrozen;

     
    bool public controllerDisabled;

     
    address public controller;

     
    mapping (uint8 => address[]) modules;

     
    mapping (address => TokenLib.ModuleData) modulesToData;

     
    mapping (bytes32 => address[]) names;

     
    mapping (address => TokenLib.Checkpoint[]) checkpointBalances;

     
    TokenLib.Checkpoint[] checkpointTotalSupply;

     
    uint256[] checkpointTimes;

     
    event ModuleAdded(
        uint8[] _types,
        bytes32 _name,
        address _moduleFactory,
        address _module,
        uint256 _moduleCost,
        uint256 _budget,
        uint256 _timestamp
    );

     
    event UpdateTokenDetails(string _oldDetails, string _newDetails);
     
    event GranularityChanged(uint256 _oldGranularity, uint256 _newGranularity);
     
    event ModuleArchived(uint8[] _types, address _module, uint256 _timestamp);
     
    event ModuleUnarchived(uint8[] _types, address _module, uint256 _timestamp);
     
    event ModuleRemoved(uint8[] _types, address _module, uint256 _timestamp);
     
    event ModuleBudgetChanged(uint8[] _moduleTypes, address _module, uint256 _oldBudget, uint256 _budget);
     
    event FreezeTransfers(bool _status, uint256 _timestamp);
     
    event CheckpointCreated(uint256 indexed _checkpointId, uint256 _timestamp);
     
    event FreezeMinting(uint256 _timestamp);
     
    event Minted(address indexed _to, uint256 _value);
    event Burnt(address indexed _from, uint256 _value);

     
    event SetController(address indexed _oldController, address indexed _newController);
    event ForceTransfer(
        address indexed _controller,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bool _verifyTransfer,
        bytes _data
    );
    event ForceBurn(
        address indexed _controller,
        address indexed _from,
        uint256 _value,
        bool _verifyTransfer,
        bytes _data
    );
    event DisableController(uint256 _timestamp);

    function _isModule(address _module, uint8 _type) internal view returns (bool) {
        require(modulesToData[_module].module == _module, "Wrong address");
        require(!modulesToData[_module].isArchived, "Module archived");
        for (uint256 i = 0; i < modulesToData[_module].moduleTypes.length; i++) {
            if (modulesToData[_module].moduleTypes[i] == _type) {
                return true;
            }
        }
        return false;
    }

     
    modifier onlyModule(uint8 _type) {
        require(_isModule(msg.sender, _type));
        _;
    }

     
    modifier onlyModuleOrOwner(uint8 _type) {
        if (msg.sender == owner) {
            _;
        } else {
            require(_isModule(msg.sender, _type));
            _;
        }
    }

    modifier checkGranularity(uint256 _value) {
        require(_value % granularity == 0, "Invalid granularity");
        _;
    }

    modifier isMintingAllowed() {
        require(!mintingFrozen, "Minting frozen");
        _;
    }

    modifier isEnabled(string _nameKey) {
        require(IFeatureRegistry(featureRegistry).getFeatureStatus(_nameKey));
        _;
    }

     
    modifier onlyController() {
        require(msg.sender == controller, "Not controller");
        require(!controllerDisabled, "Controller disabled");
        _;
    }

     
    constructor (
        string _name,
        string _symbol,
        uint8 _decimals,
        uint256 _granularity,
        string _tokenDetails,
        address _polymathRegistry
    )
    public
    DetailedERC20(_name, _symbol, _decimals)
    RegistryUpdater(_polymathRegistry)
    {
         
        updateFromRegistry();
        tokenDetails = _tokenDetails;
        granularity = _granularity;
        securityTokenVersion = SemanticVersion(2,0,0);
    }

     
    function addModule(
        address _moduleFactory,
        bytes _data,
        uint256 _maxCost,
        uint256 _budget
    ) external onlyOwner nonReentrant {
         
        IModuleRegistry(moduleRegistry).useModule(_moduleFactory);
        IModuleFactory moduleFactory = IModuleFactory(_moduleFactory);
        uint8[] memory moduleTypes = moduleFactory.getTypes();
        uint256 moduleCost = moduleFactory.getSetupCost();
        require(moduleCost <= _maxCost, "Invalid cost");
         
        ERC20(polyToken).approve(_moduleFactory, moduleCost);
         
        address module = moduleFactory.deploy(_data);
        require(modulesToData[module].module == address(0), "Module exists");
         
        ERC20(polyToken).approve(module, _budget);
         
        bytes32 moduleName = moduleFactory.getName();
        uint256[] memory moduleIndexes = new uint256[](moduleTypes.length);
        uint256 i;
        for (i = 0; i < moduleTypes.length; i++) {
            moduleIndexes[i] = modules[moduleTypes[i]].length;
            modules[moduleTypes[i]].push(module);
        }
        modulesToData[module] = TokenLib.ModuleData(
            moduleName, module, _moduleFactory, false, moduleTypes, moduleIndexes, names[moduleName].length
        );
        names[moduleName].push(module);
         
         
        emit ModuleAdded(moduleTypes, moduleName, _moduleFactory, module, moduleCost, _budget, now);
    }

     
    function archiveModule(address _module) external onlyOwner {
        TokenLib.archiveModule(modulesToData[_module], _module);
    }

     
    function unarchiveModule(address _module) external onlyOwner {
        TokenLib.unarchiveModule(modulesToData[_module], _module);
    }

     
    function removeModule(address _module) external onlyOwner {
        require(modulesToData[_module].isArchived, "Not archived");
        require(modulesToData[_module].module != address(0), "Module missing");
         
        emit ModuleRemoved(modulesToData[_module].moduleTypes, _module, now);
         
        uint8[] memory moduleTypes = modulesToData[_module].moduleTypes;
        for (uint256 i = 0; i < moduleTypes.length; i++) {
            _removeModuleWithIndex(moduleTypes[i], modulesToData[_module].moduleIndexes[i]);
             
        }
         
        uint256 index = modulesToData[_module].nameIndex;
        bytes32 name = modulesToData[_module].name;
        uint256 length = names[name].length;
        names[name][index] = names[name][length - 1];
        names[name].length = length - 1;
        if ((length - 1) != index) {
            modulesToData[names[name][index]].nameIndex = index;
        }
         
        delete modulesToData[_module];
    }

     
    function _removeModuleWithIndex(uint8 _type, uint256 _index) internal {
        uint256 length = modules[_type].length;
        modules[_type][_index] = modules[_type][length - 1];
        modules[_type].length = length - 1;

        if ((length - 1) != _index) {
             
            uint8[] memory newTypes = modulesToData[modules[_type][_index]].moduleTypes;
            for (uint256 i = 0; i < newTypes.length; i++) {
                if (newTypes[i] == _type) {
                    modulesToData[modules[_type][_index]].moduleIndexes[i] = _index;
                }
            }
        }
    }

     
    function getModule(address _module) external view returns (bytes32, address, address, bool, uint8[]) {
        return (modulesToData[_module].name,
        modulesToData[_module].module,
        modulesToData[_module].moduleFactory,
        modulesToData[_module].isArchived,
        modulesToData[_module].moduleTypes);
    }

     
    function getModulesByName(bytes32 _name) external view returns (address[]) {
        return names[_name];
    }

     
    function getModulesByType(uint8 _type) external view returns (address[]) {
        return modules[_type];
    }

    
    function withdrawERC20(address _tokenContract, uint256 _value) external onlyOwner {
        require(_tokenContract != address(0));
        IERC20 token = IERC20(_tokenContract);
        require(token.transfer(owner, _value));
    }

     
    function changeModuleBudget(address _module, uint256 _change, bool _increase) external onlyOwner {
        require(modulesToData[_module].module != address(0), "Module missing");
        uint256 currentAllowance = IERC20(polyToken).allowance(address(this), _module);
        uint256 newAllowance;
        if (_increase) {
            require(IERC20(polyToken).increaseApproval(_module, _change), "IncreaseApproval fail");
            newAllowance = currentAllowance.add(_change);
        } else {
            require(IERC20(polyToken).decreaseApproval(_module, _change), "Insufficient allowance");
            newAllowance = currentAllowance.sub(_change);
        }
        emit ModuleBudgetChanged(modulesToData[_module].moduleTypes, _module, currentAllowance, newAllowance);
    }

     
    function updateTokenDetails(string _newTokenDetails) external onlyOwner {
        emit UpdateTokenDetails(tokenDetails, _newTokenDetails);
        tokenDetails = _newTokenDetails;
    }

     
    function changeGranularity(uint256 _granularity) external onlyOwner {
        require(_granularity != 0, "Invalid granularity");
        emit GranularityChanged(granularity, _granularity);
        granularity = _granularity;
    }

     
    function _adjustInvestorCount(address _from, address _to, uint256 _value) internal {
        TokenLib.adjustInvestorCount(investorData, _from, _to, _value, balanceOf(_to), balanceOf(_from));
    }

     
    function getInvestors() external view returns(address[]) {
        return investorData.investors;
    }

     
    function getInvestorsAt(uint256 _checkpointId) external view returns(address[]) {
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < investorData.investors.length; i++) {
            if (balanceOfAt(investorData.investors[i], _checkpointId) > 0) {
                count++;
            }
        }
        address[] memory investors = new address[](count);
        count = 0;
        for (i = 0; i < investorData.investors.length; i++) {
            if (balanceOfAt(investorData.investors[i], _checkpointId) > 0) {
                investors[count] = investorData.investors[i];
                count++;
            }
        }
        return investors;
    }

     
    function iterateInvestors(uint256 _start, uint256 _end) external view returns(address[]) {
        require(_end <= investorData.investors.length, "Invalid end");
        address[] memory investors = new address[](_end.sub(_start));
        uint256 index = 0;
        for (uint256 i = _start; i < _end; i++) {
            investors[index] = investorData.investors[i];
            index++;
        }
        return investors;
    }

     
    function getInvestorCount() external view returns(uint256) {
        return investorData.investorCount;
    }

     
    function freezeTransfers() external onlyOwner {
        require(!transfersFrozen, "Already frozen");
        transfersFrozen = true;
         
        emit FreezeTransfers(true, now);
    }

     
    function unfreezeTransfers() external onlyOwner {
        require(transfersFrozen, "Not frozen");
        transfersFrozen = false;
         
        emit FreezeTransfers(false, now);
    }

     
    function _adjustTotalSupplyCheckpoints() internal {
        TokenLib.adjustCheckpoints(checkpointTotalSupply, totalSupply(), currentCheckpointId);
    }

     
    function _adjustBalanceCheckpoints(address _investor) internal {
        TokenLib.adjustCheckpoints(checkpointBalances[_investor], balanceOf(_investor), currentCheckpointId);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        return transferWithData(_to, _value, "");
    }

     
    function transferWithData(address _to, uint256 _value, bytes _data) public returns (bool success) {
        require(_updateTransfer(msg.sender, _to, _value, _data), "Transfer invalid");
        require(super.transfer(_to, _value));
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        return transferFromWithData(_from, _to, _value, "");
    }

     
    function transferFromWithData(address _from, address _to, uint256 _value, bytes _data) public returns(bool) {
        require(_updateTransfer(_from, _to, _value, _data), "Transfer invalid");
        require(super.transferFrom(_from, _to, _value));
        return true;
    }

     
    function _updateTransfer(address _from, address _to, uint256 _value, bytes _data) internal nonReentrant returns(bool) {
         
         
         
         
         
         
         
        _adjustInvestorCount(_from, _to, _value);
        bool verified = _verifyTransfer(_from, _to, _value, _data, true);
        _adjustBalanceCheckpoints(_from);
        _adjustBalanceCheckpoints(_to);
        return verified;
    }

     
    function _verifyTransfer(
        address _from,
        address _to,
        uint256 _value,
        bytes _data,
        bool _isTransfer
    ) internal checkGranularity(_value) returns (bool) {
        if (!transfersFrozen) {
            bool isInvalid = false;
            bool isValid = false;
            bool isForceValid = false;
            bool unarchived = false;
            address module;
            for (uint256 i = 0; i < modules[TRANSFER_KEY].length; i++) {
                module = modules[TRANSFER_KEY][i];
                if (!modulesToData[module].isArchived) {
                    unarchived = true;
                    ITransferManager.Result valid = ITransferManager(module).verifyTransfer(_from, _to, _value, _data, _isTransfer);
                    if (valid == ITransferManager.Result.INVALID) {
                        isInvalid = true;
                    } else if (valid == ITransferManager.Result.VALID) {
                        isValid = true;
                    } else if (valid == ITransferManager.Result.FORCE_VALID) {
                        isForceValid = true;
                    }
                }
            }
             
            return unarchived ? (isForceValid ? true : (isInvalid ? false : isValid)) : true;
        }
        return false;
    }

     
    function verifyTransfer(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
        return _verifyTransfer(_from, _to, _value, _data, false);
    }

     
    function freezeMinting() external isMintingAllowed() isEnabled("freezeMintingAllowed") onlyOwner {
        mintingFrozen = true;
         
        emit FreezeMinting(now);
    }

     
    function mint(address _investor, uint256 _value) public returns (bool success) {
        return mintWithData(_investor, _value, "");
    }

     
    function mintWithData(
        address _investor,
        uint256 _value,
        bytes _data
        ) public onlyModuleOrOwner(MINT_KEY) isMintingAllowed() returns (bool success) {
        require(_investor != address(0), "Investor is 0");
        require(_updateTransfer(address(0), _investor, _value, _data), "Transfer invalid");
        _adjustTotalSupplyCheckpoints();
        totalSupply_ = totalSupply_.add(_value);
        balances[_investor] = balances[_investor].add(_value);
        emit Minted(_investor, _value);
        emit Transfer(address(0), _investor, _value);
        return true;
    }

     
    function mintMulti(address[] _investors, uint256[] _values) external returns (bool success) {
        require(_investors.length == _values.length, "Incorrect inputs");
        for (uint256 i = 0; i < _investors.length; i++) {
            mint(_investors[i], _values[i]);
        }
        return true;
    }

     
    function checkPermission(address _delegate, address _module, bytes32 _perm) public view returns(bool) {
        for (uint256 i = 0; i < modules[PERMISSION_KEY].length; i++) {
            if (!modulesToData[modules[PERMISSION_KEY][i]].isArchived)
                return TokenLib.checkPermission(modules[PERMISSION_KEY], _delegate, _module, _perm);
        }
        return false;
    }

    function _burn(address _from, uint256 _value, bytes _data) internal returns(bool) {
        require(_value <= balances[_from], "Value too high");
        bool verified = _updateTransfer(_from, address(0), _value, _data);
        _adjustTotalSupplyCheckpoints();
        balances[_from] = balances[_from].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burnt(_from, _value);
        emit Transfer(_from, address(0), _value);
        return verified;
    }

     
    function burnWithData(uint256 _value, bytes _data) public onlyModule(BURN_KEY) {
        require(_burn(msg.sender, _value, _data), "Burn invalid");
    }

     
    function burnFromWithData(address _from, uint256 _value, bytes _data) public onlyModule(BURN_KEY) {
        require(_value <= allowed[_from][msg.sender], "Value too high");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        require(_burn(_from, _value, _data), "Burn invalid");
    }

     
    function createCheckpoint() external onlyModuleOrOwner(CHECKPOINT_KEY) returns(uint256) {
        require(currentCheckpointId < 2**256 - 1);
        currentCheckpointId = currentCheckpointId + 1;
         
        checkpointTimes.push(now);
         
        emit CheckpointCreated(currentCheckpointId, now);
        return currentCheckpointId;
    }

     
    function getCheckpointTimes() external view returns(uint256[]) {
        return checkpointTimes;
    }

     
    function totalSupplyAt(uint256 _checkpointId) external view returns(uint256) {
        require(_checkpointId <= currentCheckpointId);
        return TokenLib.getValueAt(checkpointTotalSupply, _checkpointId, totalSupply());
    }

     
    function balanceOfAt(address _investor, uint256 _checkpointId) public view returns(uint256) {
        require(_checkpointId <= currentCheckpointId);
        return TokenLib.getValueAt(checkpointBalances[_investor], _checkpointId, balanceOf(_investor));
    }

     
    function setController(address _controller) public onlyOwner {
        require(!controllerDisabled);
        emit SetController(controller, _controller);
        controller = _controller;
    }

     
    function disableController() external isEnabled("disableControllerAllowed") onlyOwner {
        require(!controllerDisabled);
        controllerDisabled = true;
        delete controller;
         
        emit DisableController(now);
    }

     
    function forceTransfer(address _from, address _to, uint256 _value, bytes _data, bytes _log) public onlyController {
        require(_to != address(0));
        require(_value <= balances[_from]);
        bool verified = _updateTransfer(_from, _to, _value, _data);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit ForceTransfer(msg.sender, _from, _to, _value, verified, _log);
        emit Transfer(_from, _to, _value);
    }

     
    function forceBurn(address _from, uint256 _value, bytes _data, bytes _log) public onlyController {
        bool verified = _burn(_from, _value, _data);
        emit ForceBurn(msg.sender, _from, _value, verified, _log);
    }

     
    function getVersion() external view returns(uint8[]) {
        uint8[] memory _version = new uint8[](3);
        _version[0] = securityTokenVersion.major;
        _version[1] = securityTokenVersion.minor;
        _version[2] = securityTokenVersion.patch;
        return _version;
    }

}

 
interface ISTFactory {

     
    function deployToken(
        string _name,
        string _symbol,
        uint8 _decimals,
        string _tokenDetails,
        address _issuer,
        bool _divisible,
        address _polymathRegistry
    )
        external
        returns (address);
}

 
contract STFactory is ISTFactory {

    address public transferManagerFactory;

    constructor (address _transferManagerFactory) public {
        transferManagerFactory = _transferManagerFactory;
    }

     
    function deployToken(
        string _name,
        string _symbol,
        uint8 _decimals,
        string _tokenDetails,
        address _issuer,
        bool _divisible,
        address _polymathRegistry
        ) external returns (address) {
        address newSecurityTokenAddress = new SecurityToken(
            _name,
            _symbol,
            _decimals,
            _divisible ? 1 : uint256(10)**_decimals,
            _tokenDetails,
            _polymathRegistry
        );
        SecurityToken(newSecurityTokenAddress).addModule(transferManagerFactory, "", 0, 0);
        SecurityToken(newSecurityTokenAddress).transferOwnership(_issuer);
        return newSecurityTokenAddress;
    }
}