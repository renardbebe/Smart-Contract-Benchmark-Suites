 

pragma solidity ^0.4.24;

 
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

 
interface IModule {

     
    function getInitFunction() external pure returns (bytes4);

     
    function getPermissions() external view returns(bytes32[]);

     
    function takeFee(uint256 _amount) external returns(bool);

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

 
contract GeneralTransferManager is ITransferManager {

    using SafeMath for uint256;

     
    address public issuanceAddress = address(0);

     
    address public signingAddress = address(0);

    bytes32 public constant WHITELIST = "WHITELIST";
    bytes32 public constant FLAGS = "FLAGS";

     
    struct TimeRestriction {
        uint256 fromTime;
        uint256 toTime;
        uint256 expiryTime;
        bool canBuyFromSTO;
    }

     
     
    mapping (address => TimeRestriction) public whitelist;
     
    mapping(address => mapping(uint256 => bool)) public nonceMap;  

     
    bool public allowAllTransfers = false;
     
    bool public allowAllWhitelistTransfers = false;
     
    bool public allowAllWhitelistIssuances = true;
     
    bool public allowAllBurnTransfers = false;

     
    event ChangeIssuanceAddress(address _issuanceAddress);
     
    event AllowAllTransfers(bool _allowAllTransfers);
     
    event AllowAllWhitelistTransfers(bool _allowAllWhitelistTransfers);
     
    event AllowAllWhitelistIssuances(bool _allowAllWhitelistIssuances);
     
    event AllowAllBurnTransfers(bool _allowAllBurnTransfers);
     
    event ChangeSigningAddress(address _signingAddress);
     
    event ModifyWhitelist(
        address _investor,
        uint256 _dateAdded,
        address _addedBy,
        uint256 _fromTime,
        uint256 _toTime,
        uint256 _expiryTime,
        bool _canBuyFromSTO
    );

     
    constructor (address _securityToken, address _polyAddress)
    public
    Module(_securityToken, _polyAddress)
    {
    }

     
    function getInitFunction() public pure returns (bytes4) {
        return bytes4(0);
    }

     
    function changeIssuanceAddress(address _issuanceAddress) public withPerm(FLAGS) {
        issuanceAddress = _issuanceAddress;
        emit ChangeIssuanceAddress(_issuanceAddress);
    }

     
    function changeSigningAddress(address _signingAddress) public withPerm(FLAGS) {
        signingAddress = _signingAddress;
        emit ChangeSigningAddress(_signingAddress);
    }

     
    function changeAllowAllTransfers(bool _allowAllTransfers) public withPerm(FLAGS) {
        allowAllTransfers = _allowAllTransfers;
        emit AllowAllTransfers(_allowAllTransfers);
    }

     
    function changeAllowAllWhitelistTransfers(bool _allowAllWhitelistTransfers) public withPerm(FLAGS) {
        allowAllWhitelistTransfers = _allowAllWhitelistTransfers;
        emit AllowAllWhitelistTransfers(_allowAllWhitelistTransfers);
    }

     
    function changeAllowAllWhitelistIssuances(bool _allowAllWhitelistIssuances) public withPerm(FLAGS) {
        allowAllWhitelistIssuances = _allowAllWhitelistIssuances;
        emit AllowAllWhitelistIssuances(_allowAllWhitelistIssuances);
    }

     
    function changeAllowAllBurnTransfers(bool _allowAllBurnTransfers) public withPerm(FLAGS) {
        allowAllBurnTransfers = _allowAllBurnTransfers;
        emit AllowAllBurnTransfers(_allowAllBurnTransfers);
    }

     
    function verifyTransfer(address _from, address _to, uint256  , bytes  , bool  ) public returns(Result) {
        if (!paused) {
            if (allowAllTransfers) {
                 
                return Result.VALID;
            }
            if (allowAllBurnTransfers && (_to == address(0))) {
                return Result.VALID;
            }
            if (allowAllWhitelistTransfers) {
                 
                return (_onWhitelist(_to) && _onWhitelist(_from)) ? Result.VALID : Result.NA;
            }
            if (allowAllWhitelistIssuances && _from == issuanceAddress) {
                if (!whitelist[_to].canBuyFromSTO && _isSTOAttached()) {
                    return Result.NA;
                }
                return _onWhitelist(_to) ? Result.VALID : Result.NA;
            }
             
             
            return ((_onWhitelist(_from) && whitelist[_from].fromTime <= now) &&
                (_onWhitelist(_to) && whitelist[_to].toTime <= now)) ? Result.VALID : Result.NA;  
        }
        return Result.NA;
    }

     
    function modifyWhitelist(
        address _investor,
        uint256 _fromTime,
        uint256 _toTime,
        uint256 _expiryTime,
        bool _canBuyFromSTO
    )
        public
        withPerm(WHITELIST)
    {
         
        whitelist[_investor] = TimeRestriction(_fromTime, _toTime, _expiryTime, _canBuyFromSTO);
         
        emit ModifyWhitelist(_investor, now, msg.sender, _fromTime, _toTime, _expiryTime, _canBuyFromSTO);
    }

     
    function modifyWhitelistMulti(
        address[] _investors,
        uint256[] _fromTimes,
        uint256[] _toTimes,
        uint256[] _expiryTimes,
        bool[] _canBuyFromSTO
    ) public withPerm(WHITELIST) {
        require(_investors.length == _fromTimes.length, "Mismatched input lengths");
        require(_fromTimes.length == _toTimes.length, "Mismatched input lengths");
        require(_toTimes.length == _expiryTimes.length, "Mismatched input lengths");
        require(_canBuyFromSTO.length == _toTimes.length, "Mismatched input length");
        for (uint256 i = 0; i < _investors.length; i++) {
            modifyWhitelist(_investors[i], _fromTimes[i], _toTimes[i], _expiryTimes[i], _canBuyFromSTO[i]);
        }
    }

     
    function modifyWhitelistSigned(
        address _investor,
        uint256 _fromTime,
        uint256 _toTime,
        uint256 _expiryTime,
        bool _canBuyFromSTO,
        uint256 _validFrom,
        uint256 _validTo,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
         
        require(_validFrom <= now, "ValidFrom is too early");
         
        require(_validTo >= now, "ValidTo is too late");
        require(!nonceMap[_investor][_nonce], "Already used signature");
        nonceMap[_investor][_nonce] = true;
        bytes32 hash = keccak256(
            abi.encodePacked(this, _investor, _fromTime, _toTime, _expiryTime, _canBuyFromSTO, _validFrom, _validTo, _nonce)
        );
        _checkSig(hash, _v, _r, _s);
         
        whitelist[_investor] = TimeRestriction(_fromTime, _toTime, _expiryTime, _canBuyFromSTO);
         
        emit ModifyWhitelist(_investor, now, msg.sender, _fromTime, _toTime, _expiryTime, _canBuyFromSTO);
    }

     
    function _checkSig(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) internal view {
         
         
        address signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)), _v, _r, _s);
        require(signer == Ownable(securityToken).owner() || signer == signingAddress, "Incorrect signer");
    }

     
    function _onWhitelist(address _investor) internal view returns(bool) {
        return (((whitelist[_investor].fromTime != 0) || (whitelist[_investor].toTime != 0)) &&
            (whitelist[_investor].expiryTime >= now));  
    }

     
    function _isSTOAttached() internal view returns(bool) {
        bool attached = ISecurityToken(securityToken).getModulesByType(3).length > 0;
        return attached;
    }

     
    function getPermissions() public view returns(bytes32[]) {
        bytes32[] memory allPermissions = new bytes32[](2);
        allPermissions[0] = WHITELIST;
        allPermissions[1] = FLAGS;
        return allPermissions;
    }

}