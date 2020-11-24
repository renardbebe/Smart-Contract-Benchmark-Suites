 

 

pragma solidity >=0.4.24 <0.6.0;


 
contract Initializable {

   
  bool private initialized;

   
  bool private initializing;

   
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

   
  function isConstructor() private view returns (bool) {
     
     
     
     
     
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

   
  uint256[50] private ______gap;
}

 

pragma solidity ^0.5.0;

 
contract IRelayRecipient {
     
    function getHubAddr() public view returns (address);

    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256 maxPossibleCharge
    )
        external
        view
        returns (uint256, bytes memory);

    function preRelayedCall(bytes calldata context) external returns (bytes32);

    function postRelayedCall(bytes calldata context, bool success, uint actualCharge, bytes32 preRetVal) external;
}

 

pragma solidity ^0.5.0;


 
contract GSNBouncerBase is IRelayRecipient {
    uint256 constant private RELAYED_CALL_ACCEPTED = 0;
    uint256 constant private RELAYED_CALL_REJECTED = 11;

     
    uint256 constant internal POST_RELAYED_CALL_MAX_GAS = 100000;

     
     

     
    function preRelayedCall(bytes calldata context) external returns (bytes32) {
        require(msg.sender == getHubAddr(), "GSNBouncerBase: caller is not RelayHub");
        return _preRelayedCall(context);
    }

     
    function postRelayedCall(bytes calldata context, bool success, uint256 actualCharge, bytes32 preRetVal) external {
        require(msg.sender == getHubAddr(), "GSNBouncerBase: caller is not RelayHub");
        _postRelayedCall(context, success, actualCharge, preRetVal);
    }

     
    function _approveRelayedCall() internal pure returns (uint256, bytes memory) {
        return _approveRelayedCall("");
    }

     
    function _approveRelayedCall(bytes memory context) internal pure returns (uint256, bytes memory) {
        return (RELAYED_CALL_ACCEPTED, context);
    }

     
    function _rejectRelayedCall(uint256 errorCode) internal pure returns (uint256, bytes memory) {
        return (RELAYED_CALL_REJECTED + errorCode, "");
    }

     

    function _preRelayedCall(bytes memory) internal returns (bytes32) {
         
    }

    function _postRelayedCall(bytes memory, bool, uint256, bytes32) internal {
         
    }

     
    function _computeCharge(uint256 gas, uint256 gasPrice, uint256 serviceFee) internal pure returns (uint256) {
         
         
        return (gas * gasPrice * (100 + serviceFee)) / 100;
    }
}

 

pragma solidity ^0.5.2;

 

library ECDSA {
     
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
         
        if (signature.length != 65) {
            return (address(0));
        }

         
        bytes32 r;
        bytes32 s;
        uint8 v;

         
         
         
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

         
         
         
         
         
         
         
         
         
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

         
        return ecrecover(hash, v, r, s);
    }

     
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
         
         
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

 

pragma solidity ^0.5.0;




contract GSNBouncerSignature is Initializable, GSNBouncerBase {
    using ECDSA for bytes32;

     
     
    bytes32 constant private TRUSTED_SIGNER_STORAGE_SLOT = 0xe7b237a4017a399d277819456dce32c2356236bbc518a6d84a9a8d1cfdf1e9c5;

    enum GSNBouncerSignatureErrorCodes {
        INVALID_SIGNER
    }

    function initialize(address trustedSigner) public initializer {
        _setTrustedSigner(trustedSigner);
    }

    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256
    )
        external
        view
        returns (uint256, bytes memory)
    {
        bytes memory blob = abi.encodePacked(
            relay,
            from,
            encodedFunction,
            transactionFee,
            gasPrice,
            gasLimit,
            nonce,  
            getHubAddr(),  
            address(this)  
        );
        if (keccak256(blob).toEthSignedMessageHash().recover(approvalData) == _getTrustedSigner()) {
            return _approveRelayedCall();
        } else {
            return _rejectRelayedCall(uint256(GSNBouncerSignatureErrorCodes.INVALID_SIGNER));
        }
    }

    function _getTrustedSigner() private view returns (address trustedSigner) {
      bytes32 slot = TRUSTED_SIGNER_STORAGE_SLOT;
       
      assembly {
        trustedSigner := sload(slot)
      }
    }

    function _setTrustedSigner(address trustedSigner) private {
      bytes32 slot = TRUSTED_SIGNER_STORAGE_SLOT;
       
      assembly {
        sstore(slot, trustedSigner)
      }
    }
}

 

pragma solidity ^0.5.0;

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

 

pragma solidity ^0.5.0;



 
contract GSNContext is Initializable, Context {
     
     
    bytes32 private constant RELAY_HUB_ADDRESS_STORAGE_SLOT = 0x06b7792c761dcc05af1761f0315ce8b01ac39c16cc934eb0b2f7a8e71414f262;

    event RelayHubChanged(address indexed oldRelayHub, address indexed newRelayHub);

    function initialize() public initializer {
        _upgradeRelayHub(0xD216153c06E857cD7f72665E0aF1d7D82172F494);
    }

    function _getRelayHub() internal view returns (address relayHub) {
        bytes32 slot = RELAY_HUB_ADDRESS_STORAGE_SLOT;
         
        assembly {
            relayHub := sload(slot)
        }
    }

    function _upgradeRelayHub(address newRelayHub) internal {
        address currentRelayHub = _getRelayHub();
        require(newRelayHub != address(0), "GSNContext: new RelayHub is the zero address");
        require(newRelayHub != currentRelayHub, "GSNContext: new RelayHub is the current one");

        emit RelayHubChanged(currentRelayHub, newRelayHub);

        bytes32 slot = RELAY_HUB_ADDRESS_STORAGE_SLOT;
         
        assembly {
            sstore(slot, newRelayHub)
        }
    }

     
     
     
     

    function _msgSender() internal view returns (address) {
        if (msg.sender != _getRelayHub()) {
            return msg.sender;
        } else {
            return _getRelayedCallSender();
        }
    }

    function _msgData() internal view returns (bytes memory) {
        if (msg.sender != _getRelayHub()) {
            return msg.data;
        } else {
            return _getRelayedCallData();
        }
    }

    function _getRelayedCallSender() private pure returns (address result) {
         
         
         
         
         

         
         

         
        bytes memory array = msg.data;
        uint256 index = msg.data.length;

         
        assembly {
             
            result := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    function _getRelayedCallData() private pure returns (bytes memory) {
         
         

        uint256 actualDataLength = msg.data.length - 20;
        bytes memory actualData = new bytes(actualDataLength);

        for (uint256 i = 0; i < actualDataLength; ++i) {
            actualData[i] = msg.data[i];
        }

        return actualData;
    }
}

 

pragma solidity ^0.5.0;

contract IRelayHub {
     

     
     
     
     
     
     
     
    function stake(address relayaddr, uint256 unstakeDelay) external payable;

     
    event Staked(address indexed relay, uint256 stake, uint256 unstakeDelay);

     
     
     
     
     
    function registerRelay(uint256 transactionFee, string memory url) public;

     
     
    event RelayAdded(address indexed relay, address indexed owner, uint256 transactionFee, uint256 stake, uint256 unstakeDelay, string url);

     
     
     
    function removeRelayByOwner(address relay) public;

     
    event RelayRemoved(address indexed relay, uint256 unstakeTime);

     
     
     
    function unstake(address relay) public;

     
    event Unstaked(address indexed relay, uint256 stake);

     
    enum RelayState {
        Unknown,  
        Staked,  
        Registered,  
        Removed     
    }

     
    function getRelay(address relay) external view returns (uint256 totalStake, uint256 unstakeDelay, uint256 unstakeTime, address payable owner, RelayState state);

     

     
     
     
    function depositFor(address target) public payable;

     
    event Deposited(address indexed recipient, address indexed from, uint256 amount);

     
    function balanceOf(address target) external view returns (uint256);

     
     
     
    function withdraw(uint256 amount, address payable dest) public;

     
    event Withdrawn(address indexed account, address indexed dest, uint256 amount);

     

     
     
     
     
     
     
    function canRelay(
        address relay,
        address from,
        address to,
        bytes memory encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes memory signature,
        bytes memory approvalData
    ) public view returns (uint256 status, bytes memory recipientContext);

     
    enum PreconditionCheck {
        OK,                          
        WrongSignature,              
        WrongNonce,                  
        AcceptRelayedCallReverted,   
        InvalidRecipientStatusCode   
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function relayCall(
        address from,
        address to,
        bytes memory encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes memory signature,
        bytes memory approvalData
    ) public;

     
     
     
     
    event CanRelayFailed(address indexed relay, address indexed from, address indexed to, bytes4 selector, uint256 reason);

     
     
     
     
    event TransactionRelayed(address indexed relay, address indexed from, address indexed to, bytes4 selector, RelayCallStatus status, uint256 charge);

     
    enum RelayCallStatus {
        OK,                       
        RelayedCallFailed,        
        PreRelayedFailed,         
        PostRelayedFailed,        
        RecipientBalanceChanged   
    }

     
     
    function requiredGas(uint256 relayedCallStipend) public view returns (uint256);

     
    function maxPossibleCharge(uint256 relayedCallStipend, uint256 gasPrice, uint256 transactionFee) public view returns (uint256);

     
     
     

     
     
     
    function penalizeRepeatedNonce(bytes memory unsignedTx1, bytes memory signature1, bytes memory unsignedTx2, bytes memory signature2) public;

     
    function penalizeIllegalTransaction(bytes memory unsignedTx, bytes memory signature) public;

    event Penalized(address indexed relay, address sender, uint256 amount);

    function getNonce(address from) external view returns (uint256);
}

 

pragma solidity ^0.5.0;






 
contract GSNRecipient is Initializable, IRelayRecipient, GSNContext, GSNBouncerBase {
    function initialize() public initializer {
        GSNContext.initialize();
    }

    function getHubAddr() public view returns (address) {
        return _getRelayHub();
    }

     
     
    function relayHubVersion() public view returns (string memory) {
        this;  
        return "1.0.0";
    }

    function _withdrawDeposits(uint256 amount, address payable payee) internal {
        IRelayHub(_getRelayHub()).withdraw(amount, payee);
    }
}

 

pragma solidity ^0.5.2;

 
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

 

pragma solidity ^0.5.2;


 
contract ReentrancyGuard is Initializable {
     
    uint256 private _guardCounter;

    function initialize() public initializer {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }

    uint256[50] private ______gap;
}

 

pragma solidity ^0.5.8;

 
contract CarefulMath {

     
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

     
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

     
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

     
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

     
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

     
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

 

pragma solidity ^0.5.8;


 
contract Exponential is CarefulMath {
    uint constant expScale = 1e18;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

     
    function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

     
    function addExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

     
    function subExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

     
    function mulScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

     
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

     
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

     
    function divScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

     
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (MathError, Exp memory) {
         
        (MathError err0, uint numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

     
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (MathError, uint) {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction));
    }

     
    function mulExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {

        (MathError err0, uint doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

         
         
         
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
         
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }

     
    function mulExp(uint a, uint b) pure internal returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }

     
    function mulExp3(Exp memory a, Exp memory b, Exp memory c) pure internal returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

     
    function divExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }

     
    function truncate(Exp memory exp) pure internal returns (uint) {
         
        return exp.mantissa / expScale;
    }

     
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;  
    }

     
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

     
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

     
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }
}

 

pragma solidity 0.5.11;

 
interface ICERC20 {
    function balanceOf(address who) external view returns (uint256);

    function isCToken() external view returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOfUnderlying(address account) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

 

pragma solidity 0.5.11;



 
contract OwnableWithoutRenounce is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

 

pragma solidity ^0.5.2;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

pragma solidity ^0.5.0;




 

contract PauserRoleWithoutRenounce is Initializable, Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    function initialize(address sender) public initializer {
        if (!isPauser(sender)) {
            _addPauser(sender);
        }
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }

    uint256[50] private ______gap;
}

 

pragma solidity 0.5.11;




 
contract PausableWithoutRenounce is Initializable, Context, PauserRoleWithoutRenounce {
     
    event Paused(address account);

     
    event Unpaused(address account);

    bool private _paused;

     
    function initialize(address sender) public initializer {
        PauserRoleWithoutRenounce.initialize(sender);
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

 

pragma solidity 0.5.11;

 
interface ICTokenManager {
     
    event DiscardCToken(address indexed tokenAddress);

     
    event WhitelistCToken(address indexed tokenAddress);

    function whitelistCToken(address tokenAddress) external;

    function discardCToken(address tokenAddress) external;

    function isCToken(address tokenAddress) external view returns (bool);
}

 

pragma solidity 0.5.11;

 
interface IERC1620 {
     
    event CreateStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    );

     
    event WithdrawFromStream(uint256 indexed streamId, address indexed recipient, uint256 amount);

     
    event CancelStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 senderBalance,
        uint256 recipientBalance
    );

    function balanceOf(uint256 streamId, address who) external view returns (uint256 balance);

    function getStream(uint256 streamId)
        external
        view
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address token,
            uint256 startTime,
            uint256 stopTime,
            uint256 balance,
            uint256 rate
        );

    function createStream(address recipient, uint256 deposit, address tokenAddress, uint256 startTime, uint256 stopTime)
        external
        returns (uint256 streamId);

    function withdrawFromStream(uint256 streamId, uint256 funds) external returns (bool);

    function cancelStream(uint256 streamId) external returns (bool);
}

 

pragma solidity 0.5.11;


 
library Types {
    struct Stream {
        uint256 deposit;
        uint256 ratePerSecond;
        uint256 remainingBalance;
        uint256 startTime;
        uint256 stopTime;
        address recipient;
        address sender;
        address tokenAddress;
        bool isEntity;
    }

    struct CompoundingStreamVars {
        Exponential.Exp exchangeRateInitial;
        Exponential.Exp senderShare;
        Exponential.Exp recipientShare;
        bool isEntity;
    }
}

 

pragma solidity 0.5.11;










 
contract Sablier is IERC1620, OwnableWithoutRenounce, PausableWithoutRenounce, Exponential, ReentrancyGuard {
     

     
    uint256 constant hundredPercent = 1e18;

     
    uint256 constant onePercent = 1e16;

     
    mapping(uint256 => Types.CompoundingStreamVars) private compoundingStreamsVars;

     
    ICTokenManager public cTokenManager;

     
    mapping(address => uint256) private earnings;

     
    Exp public fee;

     
    uint256 public nextStreamId;

     
    mapping(uint256 => Types.Stream) private streams;

     

     
    event CreateCompoundingStream(
        uint256 indexed streamId,
        uint256 exchangeRate,
        uint256 senderSharePercentage,
        uint256 recipientSharePercentage
    );

     
    event PayInterest(
        uint256 indexed streamId,
        uint256 senderInterest,
        uint256 recipientInterest,
        uint256 sablierInterest
    );

     
    event TakeEarnings(address indexed tokenAddress, uint256 indexed amount);

     
    event UpdateFee(uint256 indexed fee);

     

     
    modifier onlySenderOrRecipient(uint256 streamId) {
        require(
            msg.sender == streams[streamId].sender || msg.sender == streams[streamId].recipient,
            "caller is not the sender or the recipient of the stream"
        );
        _;
    }

     
    modifier streamExists(uint256 streamId) {
        require(streams[streamId].isEntity, "stream does not exist");
        _;
    }

     
    modifier compoundingStreamExists(uint256 streamId) {
        require(compoundingStreamsVars[streamId].isEntity, "compounding stream does not exist");
        _;
    }

     

    constructor(address cTokenManagerAddress) public {
        require(cTokenManagerAddress != address(0x00), "cTokenManager contract is the zero address");
        OwnableWithoutRenounce.initialize(msg.sender);
        PausableWithoutRenounce.initialize(msg.sender);
        cTokenManager = ICTokenManager(cTokenManagerAddress);
        nextStreamId = 1;
    }

     

    struct UpdateFeeLocalVars {
        MathError mathErr;
        uint256 feeMantissa;
    }

     
    function updateFee(uint256 feePercentage) external onlyOwner {
        require(feePercentage <= 100, "fee percentage higher than 100%");
        UpdateFeeLocalVars memory vars;

         
        (vars.mathErr, vars.feeMantissa) = mulUInt(feePercentage, onePercent);
         
        assert(vars.mathErr == MathError.NO_ERROR);

        fee = Exp({ mantissa: vars.feeMantissa });
        emit UpdateFee(feePercentage);
    }

    struct TakeEarningsLocalVars {
        MathError mathErr;
    }

     
    function takeEarnings(address tokenAddress, uint256 amount) external onlyOwner nonReentrant {
        require(cTokenManager.isCToken(tokenAddress), "cToken is not whitelisted");
        require(amount > 0, "amount is zero");
        require(earnings[tokenAddress] >= amount, "amount exceeds the available balance");

        TakeEarningsLocalVars memory vars;
        (vars.mathErr, earnings[tokenAddress]) = subUInt(earnings[tokenAddress], amount);
         
        assert(vars.mathErr == MathError.NO_ERROR);

        emit TakeEarnings(tokenAddress, amount);
        require(IERC20(tokenAddress).transfer(msg.sender, amount), "token transfer failure");
    }

     

     
    function getStream(uint256 streamId)
        external
        view
        streamExists(streamId)
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond
        )
    {
        sender = streams[streamId].sender;
        recipient = streams[streamId].recipient;
        deposit = streams[streamId].deposit;
        tokenAddress = streams[streamId].tokenAddress;
        startTime = streams[streamId].startTime;
        stopTime = streams[streamId].stopTime;
        remainingBalance = streams[streamId].remainingBalance;
        ratePerSecond = streams[streamId].ratePerSecond;
    }

     
    function deltaOf(uint256 streamId) public view streamExists(streamId) returns (uint256 delta) {
        Types.Stream memory stream = streams[streamId];
        if (block.timestamp <= stream.startTime) return 0;
        if (block.timestamp < stream.stopTime) return block.timestamp - stream.startTime;
        return stream.stopTime - stream.startTime;
    }

    struct BalanceOfLocalVars {
        MathError mathErr;
        uint256 recipientBalance;
        uint256 withdrawalAmount;
        uint256 senderBalance;
    }

     
    function balanceOf(uint256 streamId, address who) public view streamExists(streamId) returns (uint256 balance) {
        Types.Stream memory stream = streams[streamId];
        BalanceOfLocalVars memory vars;

        uint256 delta = deltaOf(streamId);
        (vars.mathErr, vars.recipientBalance) = mulUInt(delta, stream.ratePerSecond);
        require(vars.mathErr == MathError.NO_ERROR, "recipient balance calculation error");

         
        if (stream.deposit > stream.remainingBalance) {
            (vars.mathErr, vars.withdrawalAmount) = subUInt(stream.deposit, stream.remainingBalance);
            assert(vars.mathErr == MathError.NO_ERROR);
            (vars.mathErr, vars.recipientBalance) = subUInt(vars.recipientBalance, vars.withdrawalAmount);
             
            assert(vars.mathErr == MathError.NO_ERROR);
        }

        if (who == stream.recipient) return vars.recipientBalance;
        if (who == stream.sender) {
            (vars.mathErr, vars.senderBalance) = subUInt(stream.remainingBalance, vars.recipientBalance);
             
            assert(vars.mathErr == MathError.NO_ERROR);
            return vars.senderBalance;
        }
        return 0;
    }

     
    function isCompoundingStream(uint256 streamId) public view returns (bool) {
        return compoundingStreamsVars[streamId].isEntity;
    }

     
    function getCompoundingStream(uint256 streamId)
        external
        view
        streamExists(streamId)
        compoundingStreamExists(streamId)
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond,
            uint256 exchangeRateInitial,
            uint256 senderSharePercentage,
            uint256 recipientSharePercentage
        )
    {
        sender = streams[streamId].sender;
        recipient = streams[streamId].recipient;
        deposit = streams[streamId].deposit;
        tokenAddress = streams[streamId].tokenAddress;
        startTime = streams[streamId].startTime;
        stopTime = streams[streamId].stopTime;
        remainingBalance = streams[streamId].remainingBalance;
        ratePerSecond = streams[streamId].ratePerSecond;
        exchangeRateInitial = compoundingStreamsVars[streamId].exchangeRateInitial.mantissa;
        senderSharePercentage = compoundingStreamsVars[streamId].senderShare.mantissa;
        recipientSharePercentage = compoundingStreamsVars[streamId].recipientShare.mantissa;
    }

    struct InterestOfLocalVars {
        MathError mathErr;
        Exp exchangeRateDelta;
        Exp underlyingInterest;
        Exp netUnderlyingInterest;
        Exp senderUnderlyingInterest;
        Exp recipientUnderlyingInterest;
        Exp sablierUnderlyingInterest;
        Exp senderInterest;
        Exp recipientInterest;
        Exp sablierInterest;
    }

     
    function interestOf(uint256 streamId, uint256 amount)
        public
        streamExists(streamId)
        returns (uint256 senderInterest, uint256 recipientInterest, uint256 sablierInterest)
    {
        if (!compoundingStreamsVars[streamId].isEntity) {
            return (0, 0, 0);
        }
        Types.Stream memory stream = streams[streamId];
        Types.CompoundingStreamVars memory compoundingStreamVars = compoundingStreamsVars[streamId];
        InterestOfLocalVars memory vars;

         
        Exp memory exchangeRateCurrent = Exp({ mantissa: ICERC20(stream.tokenAddress).exchangeRateCurrent() });
        if (exchangeRateCurrent.mantissa <= compoundingStreamVars.exchangeRateInitial.mantissa) {
            return (0, 0, 0);
        }
        (vars.mathErr, vars.exchangeRateDelta) = subExp(exchangeRateCurrent, compoundingStreamVars.exchangeRateInitial);
        assert(vars.mathErr == MathError.NO_ERROR);

         
        (vars.mathErr, vars.underlyingInterest) = mulScalar(vars.exchangeRateDelta, amount);
        require(vars.mathErr == MathError.NO_ERROR, "interest calculation error");

         
        if (fee.mantissa == hundredPercent) {
            (vars.mathErr, vars.sablierInterest) = divExp(vars.underlyingInterest, exchangeRateCurrent);
            require(vars.mathErr == MathError.NO_ERROR, "sablier interest conversion error");
            return (0, 0, truncate(vars.sablierInterest));
        } else if (fee.mantissa == 0) {
            vars.sablierUnderlyingInterest = Exp({ mantissa: 0 });
            vars.netUnderlyingInterest = vars.underlyingInterest;
        } else {
            (vars.mathErr, vars.sablierUnderlyingInterest) = mulExp(vars.underlyingInterest, fee);
            require(vars.mathErr == MathError.NO_ERROR, "sablier interest calculation error");

             
            (vars.mathErr, vars.netUnderlyingInterest) = subExp(
                vars.underlyingInterest,
                vars.sablierUnderlyingInterest
            );
             
            assert(vars.mathErr == MathError.NO_ERROR);
        }

         
        (vars.mathErr, vars.senderUnderlyingInterest) = mulExp(
            vars.netUnderlyingInterest,
            compoundingStreamVars.senderShare
        );
        require(vars.mathErr == MathError.NO_ERROR, "sender interest calculation error");

         
        (vars.mathErr, vars.recipientUnderlyingInterest) = subExp(
            vars.netUnderlyingInterest,
            vars.senderUnderlyingInterest
        );
         
        assert(vars.mathErr == MathError.NO_ERROR);

         
        (vars.mathErr, vars.senderInterest) = divExp(vars.senderUnderlyingInterest, exchangeRateCurrent);
        require(vars.mathErr == MathError.NO_ERROR, "sender interest conversion error");

        (vars.mathErr, vars.recipientInterest) = divExp(vars.recipientUnderlyingInterest, exchangeRateCurrent);
        require(vars.mathErr == MathError.NO_ERROR, "recipient interest conversion error");

        (vars.mathErr, vars.sablierInterest) = divExp(vars.sablierUnderlyingInterest, exchangeRateCurrent);
        require(vars.mathErr == MathError.NO_ERROR, "sablier interest conversion error");

         
        return (truncate(vars.senderInterest), truncate(vars.recipientInterest), truncate(vars.sablierInterest));
    }

     
    function getEarnings(address tokenAddress) external view returns (uint256) {
        require(cTokenManager.isCToken(tokenAddress), "token is not cToken");
        return earnings[tokenAddress];
    }

     

    struct CreateStreamLocalVars {
        MathError mathErr;
        uint256 duration;
        uint256 ratePerSecond;
    }

     
    function createStream(address recipient, uint256 deposit, address tokenAddress, uint256 startTime, uint256 stopTime)
        public
        whenNotPaused
        returns (uint256)
    {
        require(recipient != address(0x00), "stream to the zero address");
        require(recipient != address(this), "stream to the contract itself");
        require(recipient != msg.sender, "stream to the caller");
        require(deposit > 0, "deposit is zero");
        require(startTime >= block.timestamp, "start time before block.timestamp");
        require(stopTime > startTime, "stop time before the start time");

        CreateStreamLocalVars memory vars;
        (vars.mathErr, vars.duration) = subUInt(stopTime, startTime);
         
        assert(vars.mathErr == MathError.NO_ERROR);

         
        require(deposit >= vars.duration, "deposit smaller than time delta");

         
        require(deposit % vars.duration == 0, "deposit not multiple of time delta");

        (vars.mathErr, vars.ratePerSecond) = divUInt(deposit, vars.duration);
         
        assert(vars.mathErr == MathError.NO_ERROR);

         
        uint256 streamId = nextStreamId;
        streams[streamId] = Types.Stream({
            remainingBalance: deposit,
            deposit: deposit,
            isEntity: true,
            ratePerSecond: vars.ratePerSecond,
            recipient: recipient,
            sender: msg.sender,
            startTime: startTime,
            stopTime: stopTime,
            tokenAddress: tokenAddress
        });

         
        (vars.mathErr, nextStreamId) = addUInt(nextStreamId, uint256(1));
        require(vars.mathErr == MathError.NO_ERROR, "next stream id calculation error");

        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), deposit), "token transfer failure");
        emit CreateStream(streamId, msg.sender, recipient, deposit, tokenAddress, startTime, stopTime);
        return streamId;
    }

    struct CreateCompoundingStreamLocalVars {
        MathError mathErr;
        uint256 shareSum;
        uint256 underlyingBalance;
        uint256 senderShareMantissa;
        uint256 recipientShareMantissa;
    }

     
    function createCompoundingStream(
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        uint256 senderSharePercentage,
        uint256 recipientSharePercentage
    ) external whenNotPaused returns (uint256) {
        require(cTokenManager.isCToken(tokenAddress), "cToken is not whitelisted");
        CreateCompoundingStreamLocalVars memory vars;

         
        (vars.mathErr, vars.shareSum) = addUInt(senderSharePercentage, recipientSharePercentage);
        require(vars.mathErr == MathError.NO_ERROR, "share sum calculation error");
        require(vars.shareSum == 100, "shares do not sum up to 100");

        uint256 streamId = createStream(recipient, deposit, tokenAddress, startTime, stopTime);

         
        (vars.mathErr, vars.senderShareMantissa) = mulUInt(senderSharePercentage, onePercent);
         
        assert(vars.mathErr == MathError.NO_ERROR);

        (vars.mathErr, vars.recipientShareMantissa) = mulUInt(recipientSharePercentage, onePercent);
         
        assert(vars.mathErr == MathError.NO_ERROR);

         
        uint256 exchangeRateCurrent = ICERC20(tokenAddress).exchangeRateCurrent();
        compoundingStreamsVars[streamId] = Types.CompoundingStreamVars({
            exchangeRateInitial: Exp({ mantissa: exchangeRateCurrent }),
            isEntity: true,
            recipientShare: Exp({ mantissa: vars.recipientShareMantissa }),
            senderShare: Exp({ mantissa: vars.senderShareMantissa })
        });

        emit CreateCompoundingStream(streamId, exchangeRateCurrent, senderSharePercentage, recipientSharePercentage);
        return streamId;
    }

     
    function withdrawFromStream(uint256 streamId, uint256 amount)
        external
        whenNotPaused
        nonReentrant
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns (bool)
    {
        require(amount > 0, "amount is zero");
        Types.Stream memory stream = streams[streamId];
        uint256 balance = balanceOf(streamId, stream.recipient);
        require(balance >= amount, "amount exceeds the available balance");

        if (!compoundingStreamsVars[streamId].isEntity) {
            withdrawFromStreamInternal(streamId, amount);
        } else {
            withdrawFromCompoundingStreamInternal(streamId, amount);
        }
        return true;
    }

     
    function cancelStream(uint256 streamId)
        external
        nonReentrant
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns (bool)
    {
        if (!compoundingStreamsVars[streamId].isEntity) {
            cancelStreamInternal(streamId);
        } else {
            cancelCompoundingStreamInternal(streamId);
        }
        return true;
    }

     

    struct WithdrawFromStreamInternalLocalVars {
        MathError mathErr;
    }

     
    function withdrawFromStreamInternal(uint256 streamId, uint256 amount) internal {
        Types.Stream memory stream = streams[streamId];
        WithdrawFromStreamInternalLocalVars memory vars;
        (vars.mathErr, streams[streamId].remainingBalance) = subUInt(stream.remainingBalance, amount);
         
        assert(vars.mathErr == MathError.NO_ERROR);

        if (streams[streamId].remainingBalance == 0) delete streams[streamId];

        require(IERC20(stream.tokenAddress).transfer(stream.recipient, amount), "token transfer failure");
        emit WithdrawFromStream(streamId, stream.recipient, amount);
    }

    struct WithdrawFromCompoundingStreamInternalLocalVars {
        MathError mathErr;
        uint256 amountWithoutSenderInterest;
        uint256 netWithdrawalAmount;
    }

     
    function withdrawFromCompoundingStreamInternal(uint256 streamId, uint256 amount) internal {
        Types.Stream memory stream = streams[streamId];
        WithdrawFromCompoundingStreamInternalLocalVars memory vars;

         
        (uint256 senderInterest, uint256 recipientInterest, uint256 sablierInterest) = interestOf(streamId, amount);

         
        (vars.mathErr, vars.amountWithoutSenderInterest) = subUInt(amount, senderInterest);
        require(vars.mathErr == MathError.NO_ERROR, "amount without sender interest calculation error");
        (vars.mathErr, vars.netWithdrawalAmount) = subUInt(vars.amountWithoutSenderInterest, sablierInterest);
        require(vars.mathErr == MathError.NO_ERROR, "net withdrawal amount calculation error");

         
        (vars.mathErr, streams[streamId].remainingBalance) = subUInt(stream.remainingBalance, amount);
        require(vars.mathErr == MathError.NO_ERROR, "balance subtraction calculation error");

         
        if (streams[streamId].remainingBalance == 0) {
            delete streams[streamId];
            delete compoundingStreamsVars[streamId];
        }

         
        (vars.mathErr, earnings[stream.tokenAddress]) = addUInt(earnings[stream.tokenAddress], sablierInterest);
        require(vars.mathErr == MathError.NO_ERROR, "earnings addition calculation error");

         
        ICERC20 cToken = ICERC20(stream.tokenAddress);
        if (senderInterest > 0)
            require(cToken.transfer(stream.sender, senderInterest), "sender token transfer failure");
        require(cToken.transfer(stream.recipient, vars.netWithdrawalAmount), "recipient token transfer failure");

        emit WithdrawFromStream(streamId, stream.recipient, vars.netWithdrawalAmount);
        emit PayInterest(streamId, senderInterest, recipientInterest, sablierInterest);
    }

     
    function cancelStreamInternal(uint256 streamId) internal {
        Types.Stream memory stream = streams[streamId];
        uint256 senderBalance = balanceOf(streamId, stream.sender);
        uint256 recipientBalance = balanceOf(streamId, stream.recipient);

        delete streams[streamId];

        IERC20 token = IERC20(stream.tokenAddress);
        if (recipientBalance > 0)
            require(token.transfer(stream.recipient, recipientBalance), "recipient token transfer failure");
        if (senderBalance > 0) require(token.transfer(stream.sender, senderBalance), "sender token transfer failure");

        emit CancelStream(streamId, stream.sender, stream.recipient, senderBalance, recipientBalance);
    }

    struct CancelCompoundingStreamInternal {
        MathError mathErr;
        uint256 netSenderBalance;
        uint256 recipientBalanceWithoutSenderInterest;
        uint256 netRecipientBalance;
    }

     
    function cancelCompoundingStreamInternal(uint256 streamId) internal {
        Types.Stream memory stream = streams[streamId];
        CancelCompoundingStreamInternal memory vars;

         
        uint256 senderBalance = balanceOf(streamId, stream.sender);
        uint256 recipientBalance = balanceOf(streamId, stream.recipient);

         
        (uint256 senderInterest, uint256 recipientInterest, uint256 sablierInterest) = interestOf(
            streamId,
            recipientBalance
        );

         
        (vars.mathErr, vars.netSenderBalance) = addUInt(senderBalance, senderInterest);
        require(vars.mathErr == MathError.NO_ERROR, "net sender balance calculation error");

         
        (vars.mathErr, vars.recipientBalanceWithoutSenderInterest) = subUInt(recipientBalance, senderInterest);
        require(vars.mathErr == MathError.NO_ERROR, "recipient balance without sender interest calculation error");
        (vars.mathErr, vars.netRecipientBalance) = subUInt(vars.recipientBalanceWithoutSenderInterest, sablierInterest);
        require(vars.mathErr == MathError.NO_ERROR, "net recipient balance calculation error");

         
        (vars.mathErr, earnings[stream.tokenAddress]) = addUInt(earnings[stream.tokenAddress], sablierInterest);
        require(vars.mathErr == MathError.NO_ERROR, "earnings addition calculation error");

         
        delete streams[streamId];
        delete compoundingStreamsVars[streamId];

         
        IERC20 token = IERC20(stream.tokenAddress);
        if (vars.netSenderBalance > 0)
            require(token.transfer(stream.sender, vars.netSenderBalance), "sender token transfer failure");
        if (vars.netRecipientBalance > 0)
            require(token.transfer(stream.recipient, vars.netRecipientBalance), "recipient token transfer failure");

        emit CancelStream(streamId, stream.sender, stream.recipient, vars.netSenderBalance, vars.netRecipientBalance);
        emit PayInterest(streamId, senderInterest, recipientInterest, sablierInterest);
    }
}

 

pragma solidity 0.5.11;










 
contract Payroll is Initializable, OwnableWithoutRenounce, Exponential, GSNRecipient, GSNBouncerSignature {
     

     
    struct Salary {
        address company;
        bool isEntity;
        uint256 streamId;
    }

     
    uint256 public nextSalaryId;

     
    mapping(address => mapping(uint256 => bool)) public relayers;

     
    Sablier public sablier;

     
    mapping(uint256 => Salary) private salaries;

     

     
    event CreateSalary(uint256 indexed salaryId, uint256 indexed streamId, address indexed company);

     
    event WithdrawFromSalary(uint256 indexed salaryId, uint256 indexed streamId, address indexed company);

     
    event CancelSalary(uint256 indexed salaryId, uint256 indexed streamId, address indexed company);

     
    modifier onlyCompanyOrEmployee(uint256 salaryId) {
        Salary memory salary = salaries[salaryId];
        (, address employee, , , , , , ) = sablier.getStream(salary.streamId);
        require(
            _msgSender() == salary.company || _msgSender() == employee,
            "caller is not the company or the employee"
        );
        _;
    }

     
    modifier onlyEmployeeOrRelayer(uint256 salaryId) {
        Salary memory salary = salaries[salaryId];
        (, address employee, , , , , , ) = sablier.getStream(salary.streamId);
        require(
            _msgSender() == employee || relayers[_msgSender()][salaryId],
            "caller is not the employee or a relayer"
        );
        _;
    }

     
    modifier salaryExists(uint256 salaryId) {
        require(salaries[salaryId].isEntity, "salary does not exist");
        _;
    }

     

     
    function initialize(address ownerAddress, address signerAddress, address sablierAddress) public initializer {
        require(ownerAddress != address(0x00), "owner is the zero address");
        require(signerAddress != address(0x00), "signer is the zero address");
        require(sablierAddress != address(0x00), "sablier contract is the zero address");
        OwnableWithoutRenounce.initialize(ownerAddress);
        GSNRecipient.initialize();
        GSNBouncerSignature.initialize(signerAddress);
        sablier = Sablier(sablierAddress);
        nextSalaryId = 1;
    }

     

     
    function whitelistRelayer(address relayer, uint256 salaryId) external onlyOwner salaryExists(salaryId) {
        require(!relayers[relayer][salaryId], "relayer is whitelisted");
        relayers[relayer][salaryId] = true;
    }

     
    function discardRelayer(address relayer, uint256 salaryId) external onlyOwner {
        require(relayers[relayer][salaryId], "relayer is not whitelisted");
        relayers[relayer][salaryId] = false;
    }

     

     
    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256
    ) external view returns (uint256, bytes memory) {
         
        bytes memory blob = abi.encodePacked(
            relay,
            from,
            encodedFunction,
            transactionFee,
            gasPrice,
            gasLimit,
            nonce,
            getHubAddr(),
            address(this)
        );
        if (keccak256(blob).toEthSignedMessageHash().recover(approvalData) == owner()) {
            return _approveRelayedCall();
        } else {
            return _rejectRelayedCall(uint256(GSNBouncerSignatureErrorCodes.INVALID_SIGNER));
        }
    }

     
    function getSalary(uint256 salaryId)
        public
        view
        salaryExists(salaryId)
        returns (
            address company,
            address employee,
            uint256 salary,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 rate
        )
    {
        company = salaries[salaryId].company;
        (, employee, salary, tokenAddress, startTime, stopTime, remainingBalance, rate) = sablier.getStream(
            salaries[salaryId].streamId
        );
    }

     

    struct CreateSalaryLocalVars {
        MathError mathErr;
    }

     
    function createSalary(address employee, uint256 salary, address tokenAddress, uint256 startTime, uint256 stopTime)
        external
        returns (uint256 salaryId)
    {
         
        require(IERC20(tokenAddress).transferFrom(_msgSender(), address(this), salary), "token transfer failure");

         
        require(IERC20(tokenAddress).approve(address(sablier), salary), "token approval failure");

         
        uint256 streamId = sablier.createStream(employee, salary, tokenAddress, startTime, stopTime);
        salaryId = nextSalaryId;
        salaries[nextSalaryId] = Salary({ company: _msgSender(), isEntity: true, streamId: streamId });

         
        CreateSalaryLocalVars memory vars;
        (vars.mathErr, nextSalaryId) = addUInt(nextSalaryId, uint256(1));
        require(vars.mathErr == MathError.NO_ERROR, "next stream id calculation error");

        emit CreateSalary(salaryId, streamId, _msgSender());
    }

     
    function createCompoundingSalary(
        address employee,
        uint256 salary,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        uint256 senderSharePercentage,
        uint256 recipientSharePercentage
    ) external returns (uint256 salaryId) {
         
        require(IERC20(tokenAddress).transferFrom(_msgSender(), address(this), salary), "token transfer failure");

         
        require(IERC20(tokenAddress).approve(address(sablier), salary), "token approval failure");

         
        uint256 streamId = sablier.createCompoundingStream(
            employee,
            salary,
            tokenAddress,
            startTime,
            stopTime,
            senderSharePercentage,
            recipientSharePercentage
        );
        salaryId = nextSalaryId;
        salaries[nextSalaryId] = Salary({ company: _msgSender(), isEntity: true, streamId: streamId });

         
        CreateSalaryLocalVars memory vars;
        (vars.mathErr, nextSalaryId) = addUInt(nextSalaryId, uint256(1));
        require(vars.mathErr == MathError.NO_ERROR, "next stream id calculation error");

         
        emit CreateSalary(salaryId, streamId, _msgSender());
    }

    struct CancelSalaryLocalVars {
        MathError mathErr;
        uint256 netCompanyBalance;
    }

     
    function withdrawFromSalary(uint256 salaryId, uint256 amount)
        external
        salaryExists(salaryId)
        onlyEmployeeOrRelayer(salaryId)
        returns (bool success)
    {
        Salary memory salary = salaries[salaryId];
        success = sablier.withdrawFromStream(salary.streamId, amount);
        emit WithdrawFromSalary(salaryId, salary.streamId, salary.company);
    }

     
    function cancelSalary(uint256 salaryId)
        external
        salaryExists(salaryId)
        onlyCompanyOrEmployee(salaryId)
        returns (bool success)
    {
        Salary memory salary = salaries[salaryId];

         
        (, address employee, , address tokenAddress, , , , ) = sablier.getStream(salary.streamId);
        uint256 companyBalance = sablier.balanceOf(salary.streamId, address(this));

         
        CancelSalaryLocalVars memory vars;
        if (!sablier.isCompoundingStream(salary.streamId)) {
            vars.netCompanyBalance = companyBalance;
        } else {
            uint256 employeeBalance = sablier.balanceOf(salary.streamId, employee);
            (uint256 companyInterest, , ) = sablier.interestOf(salary.streamId, employeeBalance);
            (vars.mathErr, vars.netCompanyBalance) = addUInt(companyBalance, companyInterest);
            require(vars.mathErr == MathError.NO_ERROR, "net company balance calculation error");
        }

         
        delete salaries[salaryId];
        success = sablier.cancelStream(salary.streamId);

         
        if (vars.netCompanyBalance > 0)
            require(
                IERC20(tokenAddress).transfer(salary.company, vars.netCompanyBalance),
                "company token transfer failure"
            );

        emit CancelSalary(salaryId, salary.streamId, salary.company);
    }
}