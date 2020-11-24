 

 

 
pragma solidity ^0.5.11;


 
 
 
library AddressUtil
{
    using AddressUtil for *;

    function isContract(
        address addr
        )
        internal
        view
        returns (bool)
    {
        uint32 size;
        assembly { size := extcodesize(addr) }
        return (size > 0);
    }

    function toPayable(
        address addr
        )
        internal
        pure
        returns (address payable)
    {
        return address(uint160(addr));
    }

     
     
    function sendETH(
        address to,
        uint    amount,
        uint    gasLimit
        )
        internal
        returns (bool success)
    {
        if (amount == 0) {
            return true;
        }
        address payable recipient = to.toPayable();
         
        (success, ) = recipient.call.value(amount).gas(gasLimit)("");
    }

     
     
    function transferETH(
        address to,
        uint    amount,
        uint    gasLimit
        )
        internal
        returns (bool success)
    {
        success = to.sendETH(amount, gasLimit);
        require(success, "TRANSFER_FAILURE");
    }
}

 

 
pragma solidity ^0.5.11;


 
 
 
contract ERC20
{
    function totalSupply()
        public
        view
        returns (uint);

    function balanceOf(
        address who
        )
        public
        view
        returns (uint);

    function allowance(
        address owner,
        address spender
        )
        public
        view
        returns (uint);

    function transfer(
        address to,
        uint value
        )
        public
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint    value
        )
        public
        returns (bool);

    function approve(
        address spender,
        uint    value
        )
        public
        returns (bool);
}

 

 
pragma solidity ^0.5.11;



 
 
contract BurnableERC20 is ERC20
{
    function burn(
        uint value
        )
        public
        returns (bool);

    function burnFrom(
        address from,
        uint value
        )
        public
        returns (bool);
}

 

 
pragma solidity ^0.5.11;


 
 
 
library ERC20SafeTransfer
{

    function safeTransfer(
        address token,
        address to,
        uint    value
        )
        internal
        returns (bool)
    {
        return safeTransferWithGasLimit(
            token,
            to,
            value,
            gasleft()
        );
    }

    function safeTransferWithGasLimit(
        address token,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
        returns (bool)
    {
         
         
         

         
        bytes memory callData = abi.encodeWithSelector(
            bytes4(0xa9059cbb),
            to,
            value
        );
        (bool success, ) = token.call.gas(gasLimit)(callData);
        return checkReturnValue(success);
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint    value
        )
        internal
        returns (bool)
    {
        return safeTransferFromWithGasLimit(
            token,
            from,
            to,
            value,
            gasleft()
        );
    }

    function safeTransferFromWithGasLimit(
        address token,
        address from,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
        returns (bool)
    {
         
         
         

         
        bytes memory callData = abi.encodeWithSelector(
            bytes4(0x23b872dd),
            from,
            to,
            value
        );
        (bool success, ) = token.call.gas(gasLimit)(callData);
        return checkReturnValue(success);
    }

    function checkReturnValue(
        bool success
        )
        internal
        pure
        returns (bool)
    {
         
         
         
        if (success) {
            assembly {
                switch returndatasize()
                 
                case 0 {
                    success := 1
                }
                 
                case 32 {
                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }
                 
                default {
                    success := 0
                }
            }
        }
        return success;
    }

}

 

 
pragma solidity ^0.5.11;


 
 
library MathUint
{
    function mul(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a * b;
        require(a == 0 || c / a == b, "MUL_OVERFLOW");
    }

    function sub(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint)
    {
        require(b <= a, "SUB_UNDERFLOW");
        return a - b;
    }

    function add(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }

    function decodeFloat(
        uint f
        )
        internal
        pure
        returns (uint value)
    {
        uint numBitsMantissa = 23;
        uint exponent = f >> numBitsMantissa;
        uint mantissa = f & ((1 << numBitsMantissa) - 1);
        value = mantissa * (10 ** exponent);
    }
}

 

 

pragma solidity ^0.5.11;


library Cloneable {
    function clone(address a)
        external
        returns (address)
    {

     
        address retval;
        assembly{
            mstore(0x0, or (0x5880730000000000000000000000000000000000000000803b80938091923cF3 ,mul(a,0x1000000000000000000)))
            retval := create(0,0, 32)
        }
        return retval;
    }
}

 

 
pragma solidity ^0.5.11;


 
 
 
 
 
contract Ownable
{
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
     
    constructor()
        public
    {
        owner = msg.sender;
    }

     
    modifier onlyOwner()
    {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

     
     
     
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership()
        public
        onlyOwner
    {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

 

 
pragma solidity ^0.5.11;



 
 
 
 
contract Claimable is Ownable
{
    address public pendingOwner;

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }

     
     
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }

     
    function claimOwnership()
        public
        onlyPendingOwner
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

 

 
pragma solidity ^0.5.11;


 
 
 
 
 
 
contract ReentrancyGuard
{
     
    uint private _guardValue;

     
    modifier nonReentrant()
    {
         
        require(_guardValue == 0, "REENTRANCY");

         
        _guardValue = 1;

         
        _;

         
        _guardValue = 0;
    }
}

 

 
pragma solidity ^0.5.11;





 
 
contract IExchange is Claimable, ReentrancyGuard
{
    string  constant public version          = "";  
    bytes32 constant public genesisBlockHash = 0;   

     
     
    function clone()
        external
        nonReentrant
        returns (address cloneAddress)
    {
        address origin = address(this);
        cloneAddress = Cloneable.clone(origin);

        assert(cloneAddress != origin);
        assert(cloneAddress != address(0));
    }
}

 

 
pragma solidity ^0.5.11;



 
 
 
 
 
 
 
 
 
 
contract IExchangeV3 is IExchange
{
     
     
     
    event AccountCreated(
        address indexed owner,
        uint24  indexed id,
        uint            pubKeyX,
        uint            pubKeyY
    );

    event AccountUpdated(
        address indexed owner,
        uint24  indexed id,
        uint            pubKeyX,
        uint            pubKeyY
    );

    event TokenRegistered(
        address indexed token,
        uint16  indexed tokenId
    );

    event OperatorChanged(
        uint    indexed exchangeId,
        address         oldOperator,
        address         newOperator
    );

    event AddressWhitelistChanged(
        uint    indexed exchangeId,
        address         oldAddressWhitelist,
        address         newAddressWhitelist
    );

    event FeesUpdated(
        uint    indexed exchangeId,
        uint            accountCreationFeeETH,
        uint            accountUpdateFeeETH,
        uint            depositFeeETH,
        uint            withdrawalFeeETH
    );

    event Shutdown(
        uint            timestamp
    );

    event BlockCommitted(
        uint    indexed blockIdx,
        bytes32 indexed publicDataHash
    );

    event BlockVerified(
        uint    indexed blockIdx
    );

    event BlockFinalized(
        uint    indexed blockIdx
    );

    event Revert(
        uint    indexed blockIdx
    );

    event DepositRequested(
        uint    indexed depositIdx,
        uint24  indexed accountID,
        uint16  indexed tokenID,
        uint96          amount,
        uint            pubKeyX,
        uint            pubKeyY
    );

    event BlockFeeWithdrawn(
        uint    indexed blockIdx,
        uint            amount
    );

    event WithdrawalRequested(
        uint    indexed withdrawalIdx,
        uint24  indexed accountID,
        uint16  indexed tokenID,
        uint96          amount
    );

    event WithdrawalCompleted(
        uint24  indexed accountID,
        uint16  indexed tokenID,
        address         to,
        uint96          amount
    );

    event WithdrawalFailed(
        uint24  indexed accountID,
        uint16  indexed tokenID,
        address         to,
        uint96          amount
    );

    event ProtocolFeesUpdated(
        uint8 takerFeeBips,
        uint8 makerFeeBips,
        uint8 previousTakerFeeBips,
        uint8 previousMakerFeeBips
    );

     
     
     
     
     
     
     
     
     
    function initialize(
        address loopringAddress,
        address owner,
        uint    exchangeId,
        address payable operator,
        bool    onchainDataAvailability
        )
        external;

     
     
     
    function isInWithdrawalMode()
        external
        view
        returns (bool);

     
     
    function isShutdown()
        external
        view
        returns (bool);

     

     
     
    function getNumAccounts()
        external
        view
        returns (uint);

     
     
     
     
     
    function getAccount(
        address owner
        )
        external
        view
        returns (
            uint24 accountID,
            uint   pubKeyX,
            uint   pubKeyY
        );

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function createOrUpdateAccount(
        uint  pubKeyX,
        uint  pubKeyY,
        bytes calldata permission
        )
        external
        payable
        returns (
            uint24 accountID,
            bool   isAccountNew,
            bool   isAccountUpdated
        );

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function isAccountBalanceCorrect(
        uint     merkleRoot,
        uint24   accountID,
        uint16   tokenID,
        uint     pubKeyX,
        uint     pubKeyY,
        uint32   nonce,
        uint96   balance,
        uint     tradeHistoryRoot,
        uint[30] calldata accountMerkleProof,
        uint[12] calldata balanceMerkleProof
        )
        external
        pure
        returns (bool);

     

     
     
    function getLRCFeeForRegisteringOneMoreToken()
        external
        view
        returns (uint feeLRC);

     
     
     
     
     
     
     
     
     
     
     
    function registerToken(
        address tokenAddress
        )
        external
        returns (uint16 tokenID);

     
     
     
    function getTokenID(
        address tokenAddress
        )
        external
        view
        returns (uint16 tokenID);

     
     
     
    function getTokenAddress(
        uint16 tokenID
        )
        external
        view
        returns (address tokenAddress);

     
     
     
    function disableTokenDeposit(
        address tokenAddress
        )
        external;

     
     
     
    function enableTokenDeposit(
        address tokenAddress
        )
        external;

     
     
     
     
     
     
     
    function getExchangeStake()
        external
        view
        returns (uint);

     
     
     
     
     
     
     
     
     
    function withdrawExchangeStake(
        address recipient
        )
        external
        returns (uint);

     
     
     
     
     
     
    function withdrawTokenNotOwnedByUsers(
        address tokenAddress,
        address payable recipient
        )
        external
        returns (uint);

     
     
     
     
     
    function withdrawProtocolFeeStake(
        address recipient,
        uint    amount
        )
        external;

     
     
     
     
     
    function burnExchangeStake()
        external;

     
     
     
     
    function getBlockHeight()
        external
        view
        returns (uint);

     
     
    function getNumBlocksFinalized()
        external
        view
        returns (uint);

     
     
     
     
     
     
     
     
     
     
     
     
     
    function getBlock(
        uint blockIdx
        )
        external
        view
        returns (
            bytes32 merkleRoot,
            bytes32 publicDataHash,
            uint8   blockState,
            uint8   blockType,
            uint16  blockSize,
            uint32  timestamp,
            uint32  numDepositRequestsCommitted,
            uint32  numWithdrawalRequestsCommitted,
            bool    blockFeeWithdrawn,
            uint16  numWithdrawalsDistributed
        );

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function commitBlock(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion,
        bytes  calldata data,
        bytes  calldata offchainData
        )
        external;

     
     
     
     
     
     
     
     
     
     
     
    function verifyBlocks(
        uint[] calldata blockIndices,
        uint[] calldata proofs
        )
        external;

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function revertBlock(
        uint blockIdx
        )
        external;

     
     
     
     
     
    function getNumDepositRequestsProcessed()
        external
        view
        returns (uint);

     
     
    function getNumAvailableDepositSlots()
        external
        view
        returns (uint);

     
     
     
     
     
    function getDepositRequest(
        uint index
        )
        external
        view
        returns (
          bytes32 accumulatedHash,
          uint    accumulatedFee,
          uint32  timestamp
        );

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function updateAccountAndDeposit(
        uint    pubKeyX,
        uint    pubKeyY,
        address tokenAddress,
        uint96  amount,
        bytes   calldata permission
        )
        external
        payable
        returns (
            uint24 accountID,
            bool   isAccountNew,
            bool   isAccountUpdated
        );

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function deposit(
        address tokenAddress,
        uint96  amount
        )
        external
        payable;

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function depositTo(
        address recipient,
        address tokenAddress,
        uint96  amount
        )
        external
        payable;

     
     
     
     
     
    function getNumWithdrawalRequestsProcessed()
        external
        view
        returns (uint);

     
     
    function getNumAvailableWithdrawalSlots(
        )
        external
        view
        returns (uint);

     
     
     
     
     
    function getWithdrawRequest(
        uint index
        )
        external
        view
        returns (
            bytes32 accumulatedHash,
            uint    accumulatedFee,
            uint32  timestamp
        );

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function withdraw(
        address tokenAddress,
        uint96  amount
        )
        external
        payable;

     
     
     
     
     
     
     
     
     
     
    function withdrawProtocolFees(
        address tokenAddress
        )
        external
        payable;

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function withdrawFromMerkleTree(
        address  token,
        uint     pubKeyX,
        uint     pubKeyY,
        uint32   nonce,
        uint96   balance,
        uint     tradeHistoryRoot,
        uint[30] calldata accountMerkleProof,
        uint[12] calldata balanceMerkleProof
        )
        external;

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function withdrawFromMerkleTreeFor(
        address  owner,
        address  token,
        uint     pubKeyX,
        uint     pubKeyY,
        uint32   nonce,
        uint96   balance,
        uint     tradeHistoryRoot,
        uint[30] calldata accountMerkleProof,
        uint[12] calldata balanceMerkleProof
        )
        external;

     
     
     
     
     
     
     
     
     
     
     
     
    function withdrawFromDepositRequest(
        uint depositIdx
        )
        external;

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function withdrawFromApprovedWithdrawal(
        uint blockIdx,
        uint slotIdx
        )
        external;

     
     
     
     
     
     
     
     
     
     
     
    function withdrawBlockFee(
        uint    blockIdx,
        address payable feeRecipient
        )
        external
        returns (uint feeAmount);

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function distributeWithdrawals(
        uint blockIdx,
        uint maxNumWithdrawals
        )
        external;

     

     
     
     
    function setOperator(
        address payable _operator
        )
        external
        returns (address payable oldOperator);

     
     
     
     
    function setAddressWhitelist(
        address _addressWhitelist
        )
        external
        returns (address oldAddressWhitelist);

     
     
     
     
     
     
    function setFees(
        uint _accountCreationFeeETH,
        uint _accountUpdateFeeETH,
        uint _depositFeeETH,
        uint _withdrawalFeeETH
        )
        external;

     
     
     
     
     
    function getFees()
        external
        view
        returns (
            uint _accountCreationFeeETH,
            uint _accountUpdateFeeETH,
            uint _depositFeeETH,
            uint _withdrawalFeeETH
        );

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function startOrContinueMaintenanceMode(
        uint durationMinutes
        )
        external;

     
     
     
    function stopMaintenanceMode()
        external;

     
     
    function getRemainingDowntime()
        external
        view
        returns (uint durationMinutes);

     
     
    function getDowntimeCostLRC(
        uint durationMinutes
        )
        external
        view
        returns (uint costLRC);

     
     
    function getTotalTimeInMaintenanceSeconds()
        external
        view
        returns (uint timeInSeconds);

     
     
    function getExchangeCreationTimestamp()
        external
        view
        returns (uint timestamp);

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function shutdown()
        external
        returns (bool success);

     
     
     
     
     
    function getRequestStats()
        external
        view
        returns(
            uint numDepositRequestsProcessed,
            uint numAvailableDepositSlots,
            uint numWithdrawalRequestsProcessed,
            uint numAvailableWithdrawalSlots
        );

     
     
     
     
     
     
    function getProtocolFeeValues()
        external
        view
        returns (
            uint32 timestamp,
            uint8 takerFeeBips,
            uint8 makerFeeBips,
            uint8 previousTakerFeeBips,
            uint8 previousMakerFeeBips
        );
}

 

 
pragma solidity ^0.5.11;




 
 
contract ILoopring is Claimable, ReentrancyGuard
{
    address public protocolRegistry;
    address public lrcAddress;
    uint    public exchangeCreationCostLRC;

    event ExchangeInitialized(
        uint    indexed exchangeId,
        address indexed exchangeAddress,
        address indexed owner,
        address         operator,
        bool            onchainDataAvailability
    );

     
     
     
     
     
     
     
     
     
     
    function initializeExchange(
        address exchangeAddress,
        uint    exchangeId,
        address owner,
        address payable operator,
        bool    onchainDataAvailability
        )
        external;
}

 

 
pragma solidity ^0.5.11;



 
 
 
contract ILoopringV3 is ILoopring
{
     

    event ExchangeStakeDeposited(
        uint    indexed exchangeId,
        uint            amount
    );

    event ExchangeStakeWithdrawn(
        uint    indexed exchangeId,
        uint            amount
    );

    event ExchangeStakeBurned(
        uint    indexed exchangeId,
        uint            amount
    );

    event ProtocolFeeStakeDeposited(
        uint    indexed exchangeId,
        uint            amount
    );

    event ProtocolFeeStakeWithdrawn(
        uint    indexed exchangeId,
        uint            amount
    );

    event SettingsUpdated(
        uint            time
    );

     
    struct Exchange
    {
        address exchangeAddress;
        uint    exchangeStake;
        uint    protocolFeeStake;
    }

    mapping (uint => Exchange) internal exchanges;

    uint    public totalStake;

    address public wethAddress;
    address public exchangeDeployerAddress;
    address public blockVerifierAddress;
    address public downtimeCostCalculator;
    uint    public maxWithdrawalFee;
    uint    public withdrawalFineLRC;
    uint    public tokenRegistrationFeeLRCBase;
    uint    public tokenRegistrationFeeLRCDelta;
    uint    public minExchangeStakeWithDataAvailability;
    uint    public minExchangeStakeWithoutDataAvailability;
    uint    public revertFineLRC;
    uint8   public minProtocolTakerFeeBips;
    uint8   public maxProtocolTakerFeeBips;
    uint8   public minProtocolMakerFeeBips;
    uint8   public maxProtocolMakerFeeBips;
    uint    public targetProtocolTakerFeeStake;
    uint    public targetProtocolMakerFeeStake;

    address payable public protocolFeeVault;

     
     
     
     
     
     
    function updateSettings(
        address payable _protocolFeeVault,    
        address _blockVerifierAddress,        
        address _downtimeCostCalculator,      
        uint    _exchangeCreationCostLRC,
        uint    _maxWithdrawalFee,
        uint    _tokenRegistrationFeeLRCBase,
        uint    _tokenRegistrationFeeLRCDelta,
        uint    _minExchangeStakeWithDataAvailability,
        uint    _minExchangeStakeWithoutDataAvailability,
        uint    _revertFineLRC,
        uint    _withdrawalFineLRC
        )
        external;

     
     
     
     
     
    function updateProtocolFeeSettings(
        uint8 _minProtocolTakerFeeBips,
        uint8 _maxProtocolTakerFeeBips,
        uint8 _minProtocolMakerFeeBips,
        uint8 _maxProtocolMakerFeeBips,
        uint  _targetProtocolTakerFeeStake,
        uint  _targetProtocolMakerFeeStake
        )
        external;

     
     
     
     
     
     
     
     
     
    function canExchangeCommitBlocks(
        uint exchangeId,
        bool onchainDataAvailability
        )
        external
        view
        returns (bool);

     
     
     
    function getExchangeStake(
        uint exchangeId
        )
        public
        view
        returns (uint stakedLRC);

     
     
     
     
     
    function burnExchangeStake(
        uint exchangeId,
        uint amount
        )
        external
        returns (uint burnedLRC);

     
     
     
     
    function depositExchangeStake(
        uint exchangeId,
        uint amountLRC
        )
        external
        returns (uint stakedLRC);

     
     
     
     
     
     
    function withdrawExchangeStake(
        uint    exchangeId,
        address recipient,
        uint    requestedAmount
        )
        external
        returns (uint amount);

     
     
     
     
    function depositProtocolFeeStake(
        uint exchangeId,
        uint amountLRC
        )
        external
        returns (uint stakedLRC);

     
     
     
     
     
    function withdrawProtocolFeeStake(
        uint    exchangeId,
        address recipient,
        uint    amount
        )
        external;

     
     
     
     
     
     
    function getProtocolFeeValues(
        uint exchangeId,
        bool onchainDataAvailability
        )
        external
        view
        returns (
            uint8 takerFeeBips,
            uint8 makerFeeBips
        );

     
     
     
    function getProtocolFeeStake(
        uint exchangeId
        )
        external
        view
        returns (uint protocolFeeStake);
}

 

 
pragma solidity ^0.5.11;








 
 
 
 
contract LoopringV3 is ILoopringV3
{
    using AddressUtil       for address payable;
    using MathUint          for uint;
    using ERC20SafeTransfer for address;

     
    constructor(
        address _protocolRegistry,
        address _lrcAddress,
        address _wethAddress,
        address payable _protocolFeeVault,
        address _blockVerifierAddress,
        address _downtimeCostCalculator
        )
        Claimable()
        public
    {
        require(address(0) != _protocolRegistry, "ZERO_ADDRESS");
        require(address(0) != _lrcAddress, "ZERO_ADDRESS");
        require(address(0) != _wethAddress, "ZERO_ADDRESS");

        protocolRegistry = _protocolRegistry;
        lrcAddress = _lrcAddress;
        wethAddress = _wethAddress;

        updateSettingsInternal(
            _protocolFeeVault,
            _blockVerifierAddress,
            _downtimeCostCalculator,
            0, 0, 0, 0, 0, 0, 0, 0
        );
    }

     

    modifier onlyProtocolRegistry()
    {
        require(msg.sender == protocolRegistry, "UNAUTHORIZED");
        _;
    }

    function initializeExchange(
        address exchangeAddress,
        uint    exchangeId,
        address owner,
        address payable operator,
        bool    onchainDataAvailability
        )
        external
        nonReentrant
        onlyProtocolRegistry
    {
        require(exchangeId != 0, "ZERO_ID");
        require(exchangeAddress != address(0), "ZERO_ADDRESS");
        require(owner != address(0), "ZERO_ADDRESS");
        require(operator != address(0), "ZERO_ADDRESS");
        require(exchanges[exchangeId].exchangeAddress == address(0), "ID_USED_ALREADY");

        IExchangeV3 exchange = IExchangeV3(exchangeAddress);

         
        exchange.initialize(
            address(this),
            owner,
            exchangeId,
            operator,
            onchainDataAvailability
        );

        exchanges[exchangeId] = Exchange(exchangeAddress, 0, 0);

        emit ExchangeInitialized(
            exchangeId,
            exchangeAddress,
            owner,
            operator,
            onchainDataAvailability
        );
    }

     
    function updateSettings(
        address payable _protocolFeeVault,
        address _blockVerifierAddress,
        address _downtimeCostCalculator,
        uint    _exchangeCreationCostLRC,
        uint    _maxWithdrawalFee,
        uint    _tokenRegistrationFeeLRCBase,
        uint    _tokenRegistrationFeeLRCDelta,
        uint    _minExchangeStakeWithDataAvailability,
        uint    _minExchangeStakeWithoutDataAvailability,
        uint    _revertFineLRC,
        uint    _withdrawalFineLRC
        )
        external
        onlyOwner
    {
        updateSettingsInternal(
            _protocolFeeVault,
            _blockVerifierAddress,
            _downtimeCostCalculator,
            _exchangeCreationCostLRC,
            _maxWithdrawalFee,
            _tokenRegistrationFeeLRCBase,
            _tokenRegistrationFeeLRCDelta,
            _minExchangeStakeWithDataAvailability,
            _minExchangeStakeWithoutDataAvailability,
            _revertFineLRC,
            _withdrawalFineLRC
        );
    }

    function updateProtocolFeeSettings(
        uint8 _minProtocolTakerFeeBips,
        uint8 _maxProtocolTakerFeeBips,
        uint8 _minProtocolMakerFeeBips,
        uint8 _maxProtocolMakerFeeBips,
        uint  _targetProtocolTakerFeeStake,
        uint  _targetProtocolMakerFeeStake
        )
        external
        onlyOwner
    {
        minProtocolTakerFeeBips = _minProtocolTakerFeeBips;
        maxProtocolTakerFeeBips = _maxProtocolTakerFeeBips;
        minProtocolMakerFeeBips = _minProtocolMakerFeeBips;
        maxProtocolMakerFeeBips = _maxProtocolMakerFeeBips;
        targetProtocolTakerFeeStake = _targetProtocolTakerFeeStake;
        targetProtocolMakerFeeStake = _targetProtocolMakerFeeStake;

        emit SettingsUpdated(now);
    }

    function canExchangeCommitBlocks(
        uint exchangeId,
        bool onchainDataAvailability
        )
        external
        view
        returns (bool)
    {
        uint amountStaked = getExchangeStake(exchangeId);
        if (onchainDataAvailability) {
            return amountStaked >= minExchangeStakeWithDataAvailability;
        } else {
            return amountStaked >= minExchangeStakeWithoutDataAvailability;
        }
    }

    function getExchangeStake(
        uint exchangeId
        )
        public
        view
        returns (uint)
    {
        Exchange storage exchange = exchanges[exchangeId];
        require(exchange.exchangeAddress != address(0), "INVALID_EXCHANGE_ID");
        return exchange.exchangeStake;
    }

    function burnExchangeStake(
        uint exchangeId,
        uint amount
        )
        external
        nonReentrant
        returns (uint burnedLRC)
    {
        Exchange storage exchange = exchanges[exchangeId];
        address exchangeAddress = exchange.exchangeAddress;

        require(exchangeAddress != address(0), "INVALID_EXCHANGE_ID");
        require(exchangeAddress == msg.sender, "UNAUTHORIZED");

        burnedLRC = exchange.exchangeStake;

        if (amount < burnedLRC) {
            burnedLRC = amount;
        }
        if (burnedLRC > 0) {
            require(
                BurnableERC20(lrcAddress).burn(burnedLRC),
                "BURN_FAILURE"
            );

            exchange.exchangeStake = exchange.exchangeStake.sub(burnedLRC);
            totalStake = totalStake.sub(burnedLRC);
        }
        emit ExchangeStakeBurned(exchangeId, burnedLRC);
    }

    function depositExchangeStake(
        uint exchangeId,
        uint amountLRC
        )
        external
        nonReentrant
        returns (uint stakedLRC)
    {
        require(amountLRC > 0, "ZERO_VALUE");

        Exchange storage exchange = exchanges[exchangeId];
        require(exchange.exchangeAddress != address(0), "INVALID_EXCHANGE_ID");

        require(
            lrcAddress.safeTransferFrom(msg.sender, address(this), amountLRC),
            "TRANSFER_FAILURE"
        );

        stakedLRC = exchange.exchangeStake.add(amountLRC);
        exchange.exchangeStake = stakedLRC;
        totalStake = totalStake.add(amountLRC);

        emit ExchangeStakeDeposited(exchangeId, amountLRC);
    }

    function withdrawExchangeStake(
        uint    exchangeId,
        address recipient,
        uint    requestedAmount
        )
        external
        nonReentrant
        returns (uint amountLRC)
    {
        Exchange storage exchange = exchanges[exchangeId];
        require(exchange.exchangeAddress != address(0), "INVALID_EXCHANGE_ID");
        require(exchange.exchangeAddress == msg.sender, "UNAUTHORIZED");

        amountLRC = (exchange.exchangeStake > requestedAmount) ?
            requestedAmount : exchange.exchangeStake;

        if (amountLRC > 0) {
            require(
                lrcAddress.safeTransfer(recipient, amountLRC),
                "WITHDRAWAL_FAILURE"
            );
            exchange.exchangeStake = exchange.exchangeStake.sub(amountLRC);
            totalStake = totalStake.sub(amountLRC);
        }

        emit ExchangeStakeWithdrawn(exchangeId, amountLRC);
    }

    function depositProtocolFeeStake(
        uint exchangeId,
        uint amountLRC
        )
        external
        nonReentrant
        returns (uint stakedLRC)
    {
        require(amountLRC > 0, "ZERO_VALUE");

        Exchange storage exchange = exchanges[exchangeId];
        require(exchange.exchangeAddress != address(0), "INVALID_EXCHANGE_ID");

        require(
            lrcAddress.safeTransferFrom(msg.sender, address(this), amountLRC),
            "TRANSFER_FAILURE"
        );

        stakedLRC = exchange.protocolFeeStake.add(amountLRC);
        exchange.protocolFeeStake = stakedLRC;
        totalStake = totalStake.add(amountLRC);

        emit ProtocolFeeStakeDeposited(exchangeId, amountLRC);
    }

    function withdrawProtocolFeeStake(
        uint    exchangeId,
        address recipient,
        uint    amountLRC
        )
        external
        nonReentrant
    {
        Exchange storage exchange = exchanges[exchangeId];
        require(exchange.exchangeAddress != address(0), "INVALID_EXCHANGE_ID");
        require(exchange.exchangeAddress == msg.sender, "UNAUTHORIZED");
        require(amountLRC <= exchange.protocolFeeStake, "INSUFFICIENT_STAKE");

        if (amountLRC > 0) {
            require(
                lrcAddress.safeTransfer(recipient, amountLRC),
                "WITHDRAWAL_FAILURE"
            );
            exchange.protocolFeeStake = exchange.protocolFeeStake.sub(amountLRC);
            totalStake = totalStake.sub(amountLRC);
        }
        emit ProtocolFeeStakeWithdrawn(exchangeId, amountLRC);
    }

    function getProtocolFeeValues(
        uint exchangeId,
        bool onchainDataAvailability
        )
        external
        view
        returns (
            uint8 takerFeeBips,
            uint8 makerFeeBips
        )
    {
        Exchange storage exchange = exchanges[exchangeId];
        require(exchange.exchangeAddress != address(0), "INVALID_EXCHANGE_ID");

         
        uint stake = 0;
        if (onchainDataAvailability && exchange.exchangeStake > minExchangeStakeWithDataAvailability) {
            stake = exchange.exchangeStake - minExchangeStakeWithDataAvailability;
        } else if (!onchainDataAvailability && exchange.exchangeStake > minExchangeStakeWithoutDataAvailability) {
            stake = exchange.exchangeStake - minExchangeStakeWithoutDataAvailability;
        }

         
         
        uint protocolFeeStake = stake.add(exchange.protocolFeeStake / 2);

        takerFeeBips = calculateProtocolFee(
            minProtocolTakerFeeBips, maxProtocolTakerFeeBips, protocolFeeStake, targetProtocolTakerFeeStake
        );
        makerFeeBips = calculateProtocolFee(
            minProtocolMakerFeeBips, maxProtocolMakerFeeBips, protocolFeeStake, targetProtocolMakerFeeStake
        );
    }

    function getProtocolFeeStake(
        uint exchangeId
        )
        external
        view
        returns (uint)
    {
        Exchange storage exchange = exchanges[exchangeId];
        require(exchange.exchangeAddress != address(0), "INVALID_EXCHANGE_ID");
        return exchange.protocolFeeStake;
    }

     
    function updateSettingsInternal(
        address payable  _protocolFeeVault,
        address _blockVerifierAddress,
        address _downtimeCostCalculator,
        uint    _exchangeCreationCostLRC,
        uint    _maxWithdrawalFee,
        uint    _tokenRegistrationFeeLRCBase,
        uint    _tokenRegistrationFeeLRCDelta,
        uint    _minExchangeStakeWithDataAvailability,
        uint    _minExchangeStakeWithoutDataAvailability,
        uint    _revertFineLRC,
        uint    _withdrawalFineLRC
        )
        private
    {
        require(address(0) != _protocolFeeVault, "ZERO_ADDRESS");
        require(address(0) != _blockVerifierAddress, "ZERO_ADDRESS");
        require(address(0) != _downtimeCostCalculator, "ZERO_ADDRESS");

        protocolFeeVault = _protocolFeeVault;
        blockVerifierAddress = _blockVerifierAddress;
        downtimeCostCalculator = _downtimeCostCalculator;
        exchangeCreationCostLRC = _exchangeCreationCostLRC;
        maxWithdrawalFee = _maxWithdrawalFee;
        tokenRegistrationFeeLRCBase = _tokenRegistrationFeeLRCBase;
        tokenRegistrationFeeLRCDelta = _tokenRegistrationFeeLRCDelta;
        minExchangeStakeWithDataAvailability = _minExchangeStakeWithDataAvailability;
        minExchangeStakeWithoutDataAvailability = _minExchangeStakeWithoutDataAvailability;
        revertFineLRC = _revertFineLRC;
        withdrawalFineLRC = _withdrawalFineLRC;

        emit SettingsUpdated(now);
    }

    function calculateProtocolFee(
        uint minFee,
        uint maxFee,
        uint stake,
        uint targetStake
        )
        internal
        pure
        returns (uint8)
    {
        if (targetStake > 0) {
             
            uint maxReduction = maxFee.sub(minFee);
            uint reduction = maxReduction.mul(stake) / targetStake;
            if (reduction > maxReduction) {
                reduction = maxReduction;
            }
            return uint8(maxFee.sub(reduction));
        } else {
            return uint8(minFee);
        }
    }
}