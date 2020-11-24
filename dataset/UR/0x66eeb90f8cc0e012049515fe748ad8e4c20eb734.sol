 

pragma solidity ^0.4.25;

import "./oracle.sol";
import "./ownable.sol";
import "./controllable.sol";
import "./PublicResolver.sol";
import "./SafeMath.sol";
import "./Address.sol";

 
interface ERC20 {
    function transfer(address, uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
}


 
interface ERC165 {
    function supportsInterface(bytes4) external view returns (bool);
}


 
contract Whitelist is Controllable, Ownable {
    event AddedToWhitelist(address _sender, address[] _addresses);
    event SubmittedWhitelistAddition(address[] _addresses, bytes32 _hash);
    event CancelledWhitelistAddition(address _sender, bytes32 _hash);

    event RemovedFromWhitelist(address _sender, address[] _addresses);
    event SubmittedWhitelistRemoval(address[] _addresses, bytes32 _hash);
    event CancelledWhitelistRemoval(address _sender, bytes32 _hash);

    mapping(address => bool) public isWhitelisted;
    address[] private _pendingWhitelistAddition;
    address[] private _pendingWhitelistRemoval;
    bool public submittedWhitelistAddition;
    bool public submittedWhitelistRemoval;
    bool public initializedWhitelist;

     
    modifier hasNoOwnerOrZeroAddress(address[] _addresses) {
        for (uint i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != owner(), "provided whitelist contains the owner address");
            require(_addresses[i] != address(0), "provided whitelist contains the zero address");
        }
        _;
    }

     
    modifier noActiveSubmission() {
        require(!submittedWhitelistAddition && !submittedWhitelistRemoval, "whitelist operation has already been submitted");
        _;
    }

     
    function pendingWhitelistAddition() external view returns(address[]) {
        return _pendingWhitelistAddition;
    }

     
    function pendingWhitelistRemoval() external view returns(address[]) {
        return _pendingWhitelistRemoval;
    }

     
    function pendingWhitelistHash(address[] _pendingWhitelist) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_pendingWhitelist));
    }

     
     
    function initializeWhitelist(address[] _addresses) external onlyOwner hasNoOwnerOrZeroAddress(_addresses) {
         
        require(!initializedWhitelist, "whitelist has already been initialized");
         
        for (uint i = 0; i < _addresses.length; i++) {
            isWhitelisted[_addresses[i]] = true;
        }
        initializedWhitelist = true;
         
        emit AddedToWhitelist(msg.sender, _addresses);
    }

     
     
    function submitWhitelistAddition(address[] _addresses) external onlyOwner noActiveSubmission hasNoOwnerOrZeroAddress(_addresses) {
         
        require(initializedWhitelist, "whitelist has not been initialized");
         
        require(_addresses.length > 0, "pending whitelist addition is empty");
         
        _pendingWhitelistAddition = _addresses;
         
        submittedWhitelistAddition = true;
         
        emit SubmittedWhitelistAddition(_addresses, pendingWhitelistHash(_pendingWhitelistAddition));
    }

     
    function confirmWhitelistAddition(bytes32 _hash) external onlyController {
         
        require(submittedWhitelistAddition, "whitelist addition has not been submitted");

         
        require(_hash == pendingWhitelistHash(_pendingWhitelistAddition), "hash of the pending whitelist addition do not match");

         
        for (uint i = 0; i < _pendingWhitelistAddition.length; i++) {
            isWhitelisted[_pendingWhitelistAddition[i]] = true;
        }
         
        emit AddedToWhitelist(msg.sender, _pendingWhitelistAddition);
         
        delete _pendingWhitelistAddition;
         
        submittedWhitelistAddition = false;
    }

     
    function cancelWhitelistAddition(bytes32 _hash) external onlyController {
         
        require(submittedWhitelistAddition, "whitelist addition has not been submitted");
         
        require(_hash == pendingWhitelistHash(_pendingWhitelistAddition), "hash of the pending whitelist addition does not match");
         
        delete _pendingWhitelistAddition;
         
        submittedWhitelistAddition = false;
         
        emit CancelledWhitelistAddition(msg.sender, _hash);
    }

     
     
    function submitWhitelistRemoval(address[] _addresses) external onlyOwner noActiveSubmission {
         
        require(initializedWhitelist, "whitelist has not been initialized");
         
        require(_addresses.length > 0, "submitted whitelist removal is empty");
         
        _pendingWhitelistRemoval = _addresses;
         
        submittedWhitelistRemoval = true;
         
        emit SubmittedWhitelistRemoval(_addresses, pendingWhitelistHash(_pendingWhitelistRemoval));
    }

     
    function confirmWhitelistRemoval(bytes32 _hash) external onlyController {
         
        require(submittedWhitelistRemoval, "whitelist removal has not been submitted");
         
        require(_hash == pendingWhitelistHash(_pendingWhitelistRemoval), "hash of the pending whitelist removal does not match the confirmed hash");
         
        for (uint i = 0; i < _pendingWhitelistRemoval.length; i++) {
            isWhitelisted[_pendingWhitelistRemoval[i]] = false;
        }
         
        emit RemovedFromWhitelist(msg.sender, _pendingWhitelistRemoval);
         
        delete _pendingWhitelistRemoval;
         
        submittedWhitelistRemoval = false;
    }

     
    function cancelWhitelistRemoval(bytes32 _hash) external onlyController {
         
        require(submittedWhitelistRemoval, "whitelist removal has not been submitted");
         
        require(_hash == pendingWhitelistHash(_pendingWhitelistRemoval), "hash of the pending whitelist removal does not match");
         
        delete _pendingWhitelistRemoval;
         
        submittedWhitelistRemoval = false;
         
        emit CancelledWhitelistRemoval(msg.sender, _hash);
    }
}


 
contract SpendLimit is Controllable, Ownable {
    event SetSpendLimit(address _sender, uint _amount);
    event SubmittedSpendLimitChange(uint _amount);
    event CancelledSpendLimitChange(address _sender, uint _amount);

    using SafeMath for uint256;

    uint public spendLimit;
    uint private _spendLimitDay;
    uint private _spendAvailable;

    uint public pendingSpendLimit;
    bool public submittedSpendLimit;
    bool public initializedSpendLimit;

     
    constructor(uint _spendLimit) internal {
        spendLimit = _spendLimit;
        _spendLimitDay = now;
        _spendAvailable = spendLimit;
    }

     
     
    function spendAvailable() public view returns (uint) {
        if (now > _spendLimitDay + 24 hours) {
            return spendLimit;
        } else {
            return _spendAvailable;
        }
    }

     
     
    function initializeSpendLimit(uint _amount) external onlyOwner {
         
        require(!initializedSpendLimit, "spend limit has already been initialized");
         
        _modifySpendLimit(_amount);
         
        initializedSpendLimit = true;
         
        emit SetSpendLimit(msg.sender, _amount);
    }

     
     
    function submitSpendLimit(uint _amount) external onlyOwner {
         
        require(initializedSpendLimit, "spend limit has not been initialized");
         
        pendingSpendLimit = _amount;
         
        submittedSpendLimit = true;
         
        emit SubmittedSpendLimitChange(_amount);
    }

     
    function confirmSpendLimit(uint _amount) external onlyController {
         
        require(submittedSpendLimit, "spend limit has not been submitted");
         
        require(pendingSpendLimit == _amount, "confirmed and submitted spend limits dont match");
         
        _modifySpendLimit(pendingSpendLimit);
         
        emit SetSpendLimit(msg.sender, pendingSpendLimit);
         
        submittedSpendLimit = false;
         
        pendingSpendLimit = 0;
    }

     
    function cancelSpendLimit(uint _amount) external onlyController {
         
        require(submittedSpendLimit, "a spendlimit needs to be submitted");
         
        require(pendingSpendLimit == _amount, "pending and cancelled spend limits dont match");
         
        pendingSpendLimit = 0;
         
        submittedSpendLimit = false;
         
        emit CancelledSpendLimitChange(msg.sender, _amount);
    }

     
    function _setSpendAvailable(uint _amount) internal {
        _spendAvailable = _amount;
    }

     
    function _updateSpendAvailable() internal {
        if (now > _spendLimitDay.add(24 hours)) {
             
            uint extraDays = now.sub(_spendLimitDay).div(24 hours);
            _spendLimitDay = _spendLimitDay.add(extraDays.mul(24 hours));
             
            _spendAvailable = spendLimit;
        }
    }

     
     
    function _modifySpendLimit(uint _amount) private {
         
        _updateSpendAvailable();
         
        spendLimit = _amount;
         
        if (_spendAvailable > spendLimit) {
            _spendAvailable = spendLimit;
        }
    }
}


 
contract Vault is Whitelist, SpendLimit, ERC165 {
    event Received(address _from, uint _amount);
    event Transferred(address _to, address _asset, uint _amount);
    event BulkTransferred(address _to, address[] _assets);

    using SafeMath for uint256;

     
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;  

     
    ENS internal _ENS;
     
    bytes32 internal _oracleNode;

     
     
     
     
     
     
     
    constructor(address _owner, bool _transferable, address _ens, bytes32 _oracleName, bytes32 _controllerName, uint _spendLimit) SpendLimit(_spendLimit) Ownable(_owner, _transferable) Controllable(_ens, _controllerName) public {
        _ENS = ENS(_ens);
        _oracleNode = _oracleName;
    }

     
    modifier isNotZero(uint _value) {
        require(_value != 0, "provided value cannot be zero");
        _;
    }

     
    function() public payable {
         
        require(msg.data.length == 0, "data in fallback");
        emit Received(msg.sender, msg.value);
    }

     
     
     
    function balance(address _asset) external view returns (uint) {
        if (_asset != address(0)) {
            return ERC20(_asset).balanceOf(this);
        } else {
            return address(this).balance;
        }
    }

     
     
     
     
    function bulkTransfer(address _to, address[] _assets) public onlyOwner {
         
        require(_assets.length != 0, "asset array should be non-empty");
         
        for (uint i = 0; i < _assets.length; i++) {
            uint amount;
             
            if (_assets[i] == address(0)) {
                amount = address(this).balance;
            } else {
                amount = ERC20(_assets[i]).balanceOf(address(this));
            }
             
            transfer(_to, _assets[i], amount);
        }
        emit BulkTransferred(_to, _assets);
    }

     
     
     
     
    function transfer(address _to, address _asset, uint _amount) public onlyOwner isNotZero(_amount) {
         
        require(_to != address(0), "_to address cannot be set to 0x0");

         
        if (!isWhitelisted[_to]) {
             
            _updateSpendAvailable();
             
            uint etherValue;
            bool tokenExists;
            if (_asset != address(0)) {
                (tokenExists, etherValue) = IOracle(PublicResolver(_ENS.resolver(_oracleNode)).addr(_oracleNode)).convert(_asset, _amount);
            } else {
                etherValue = _amount;
            }

             
             
            if (tokenExists || _asset == address(0)) {
                 
                require(etherValue <= spendAvailable(), "transfer amount exceeds available spend limit");
                 
                _setSpendAvailable(spendAvailable().sub(etherValue));
            }
        }
         
        if (_asset != address(0)) {
            require(ERC20(_asset).transfer(_to, _amount), "ERC20 token transfer was unsuccessful");
        } else {
            _to.transfer(_amount);
        }
         
        emit Transferred(_to, _asset, _amount);
    }

     
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return interfaceID == _ERC165_INTERFACE_ID;
    }
}


 
contract Wallet is Vault {

    using Address for address;

    event SetTopUpLimit(address _sender, uint _amount);
    event SubmittedTopUpLimitChange(uint _amount);
    event CancelledTopUpLimitChange(address _sender, uint _amount);

    event ToppedUpGas(address _sender, address _owner, uint _amount);

    event ExecutedTransaction(address _destination, uint _value, bytes _data);

    using SafeMath for uint256;

    uint constant private MINIMUM_TOPUP_LIMIT = 1 finney;  
    uint constant private MAXIMUM_TOPUP_LIMIT = 500 finney;  

     
    uint32 private constant _TRANSFER= 0xa9059cbb;
    uint32 private constant _APPROVE = 0x095ea7b3;

    uint public topUpLimit;
    uint private _topUpLimitDay;
    uint private _topUpAvailable;

    uint public pendingTopUpLimit;
    bool public submittedTopUpLimit;
    bool public initializedTopUpLimit;

     
     
     
     
     
     
     
    constructor(address _owner, bool _transferable, address _ens, bytes32 _oracleName, bytes32 _controllerName, uint _spendLimit) Vault(_owner, _transferable, _ens, _oracleName, _controllerName, _spendLimit) public {
        _topUpLimitDay = now;
        topUpLimit = MAXIMUM_TOPUP_LIMIT;
        _topUpAvailable = topUpLimit;
    }

     
     
    function topUpAvailable() external view returns (uint) {
        if (now > _topUpLimitDay + 24 hours) {
            return topUpLimit;
        } else {
            return _topUpAvailable;
        }
    }

     
     
    function initializeTopUpLimit(uint _amount) external onlyOwner {
         
        require(!initializedTopUpLimit, "top up limit has already been initialized");
         
        require(MINIMUM_TOPUP_LIMIT <= _amount && _amount <= MAXIMUM_TOPUP_LIMIT, "top up amount is outside of the min/max range");
         
        _modifyTopUpLimit(_amount);
         
        initializedTopUpLimit = true;
         
        emit SetTopUpLimit(msg.sender, _amount);
    }

     
     
    function submitTopUpLimit(uint _amount) external onlyOwner {
         
        require(initializedTopUpLimit, "top up limit has not been initialized");
         
        require(MINIMUM_TOPUP_LIMIT <= _amount && _amount <= MAXIMUM_TOPUP_LIMIT, "top up amount is outside of the min/max range");
         
        pendingTopUpLimit = _amount;
         
        submittedTopUpLimit = true;
         
        emit SubmittedTopUpLimitChange(_amount);
    }

     
    function confirmTopUpLimit(uint _amount) external onlyController {
         
        require(submittedTopUpLimit, "top up limit has not been submitted");
         
        require(MINIMUM_TOPUP_LIMIT <= pendingTopUpLimit && pendingTopUpLimit <= MAXIMUM_TOPUP_LIMIT, "top up amount is outside the min/max range");
         
        require(_amount == pendingTopUpLimit, "confirmed and pending topup limit are not same");
         
        _modifyTopUpLimit(pendingTopUpLimit);
         
        emit SetTopUpLimit(msg.sender, pendingTopUpLimit);
         
        pendingTopUpLimit = 0;
         
        submittedTopUpLimit = false;
    }

     
    function cancelTopUpLimit(uint _amount) external onlyController {
         
        require(submittedTopUpLimit, "a topup limit has to be submitted");
         
        require(pendingTopUpLimit == _amount, "pending and cancelled top up limits dont match");
         
        pendingTopUpLimit = 0;
         
        submittedTopUpLimit = false;
         
        emit CancelledTopUpLimitChange(msg.sender, _amount);
    }

     
     
     
    function topUpGas(uint _amount) external isNotZero(_amount) {
         
        require(_isOwner() || _isController(msg.sender), "sender is neither an owner nor a controller");
         
        _updateTopUpAvailable();
         
        require(_topUpAvailable != 0, "available top up limit cannot be zero");
         
        require(_amount <= _topUpAvailable, "available top up limit less than amount passed in");
         
         
        _topUpAvailable = _topUpAvailable.sub(_amount);
        owner().transfer(_amount);
         
        emit ToppedUpGas(tx.origin, owner(), _amount);
    }

     
     
    function _modifyTopUpLimit(uint _amount) private {
         
        _updateTopUpAvailable();
         
        topUpLimit = _amount;
         
        if (_topUpAvailable > topUpLimit) {
            _topUpAvailable = topUpLimit;
        }
    }

     
    function _updateTopUpAvailable() private {
        if (now > _topUpLimitDay.add(24 hours)) {
             
            uint extraDays = now.sub(_topUpLimitDay).div(24 hours);
            _topUpLimitDay = _topUpLimitDay.add(extraDays.mul(24 hours));
             
            _topUpAvailable = topUpLimit;
        }
    }

     
     
     
     
     
    function executeTransaction(address _destination, uint _value, bytes _data, bool _destinationIsContract) external onlyOwner {

         
         
        if (_destinationIsContract) {
            require(address(_destination).isContract(), "executeTransaction for a contract: call to non-contract");
        } else {
            require(!address(_destination).isContract(), "executeTransaction for a non-contract: call to contract");
        }

         
        if (_data.length >= 4) {
             
            uint32 signature = bytesToUint32(_data, 0);

             
            if (signature == _TRANSFER || signature == _APPROVE) {
                require(_data.length >= 4 + 32 + 32, "invalid transfer / approve transaction data");
                uint amount = sliceUint(_data, 4 + 32);
                 
                 
                address toOrSpender = bytesToAddress(_data, 4 + 12);

                 
                if (!isWhitelisted[toOrSpender]) {
                    (bool tokenExists,uint etherValue) = IOracle(PublicResolver(_ENS.resolver(_oracleNode)).addr(_oracleNode)).convert(_destination, amount);
                     
                     
                    if (tokenExists) {
                         
                        require(etherValue <= spendAvailable(), "transfer amount exceeds available spend limit");
                         
                        _setSpendAvailable(spendAvailable().sub(etherValue));
                    }
                }
            }
        }

         
         
        if (!isWhitelisted[_destination]) {
             
            require(_value <= spendAvailable(), "transfer amount exceeds available spend limit");
             
            _setSpendAvailable(spendAvailable().sub(_value));
        }

        require(externalCall(_destination, _value, _data.length, _data), "executing transaction failed");

        emit ExecutedTransaction(_destination, _value, _data);
    }

     
     
     
     
     
     
     
     
     
     
    function externalCall(address _destination, uint _value, uint _dataLength, bytes _data) private returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40)    
            let d := add(_data, 32)  
            result := call(
                sub(gas, 34710),     
                                     
                                     
               _destination,
               _value,
               d,
               _dataLength,         
               x,
               0                    
               )
        }
        return result;
    }

     
     
     
    function bytesToAddress(bytes _bts, uint _from) private pure returns (address) {
        require(_bts.length >= _from + 20, "slicing out of range");

        uint160 m = 0;
        uint160 b = 0;

        for (uint8 i = 0; i < 20; i++) {
            m *= 256;
            b = uint160 (_bts[_from + i]);
            m += (b);
        }

        return address(m);
    }

     
     
     
    function bytesToUint32(bytes _bts, uint _from) private pure returns (uint32) {
        require(_bts.length >= _from + 4, "slicing out of range");

        uint32 m = 0;
        uint32 b = 0;

        for (uint8 i = 0; i < 4; i++) {
            m *= 256;
            b = uint32 (_bts[_from + i]);
            m += (b);
        }

        return m;
    }

     
     
     
     
     
    function sliceUint(bytes _bts, uint _from) private pure returns (uint) {
        require(_bts.length >= _from + 32, "slicing out of range");

        uint x;
        assembly {
           x := mload(add(_bts, add(0x20, _from)))
        }

        return x;
    }
}
