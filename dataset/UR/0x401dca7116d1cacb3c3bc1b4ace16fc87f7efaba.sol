 

 

pragma solidity 0.5.7;
pragma experimental ABIEncoderV2;

 

 
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
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
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
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

 

 
library Require {

     

    uint256 constant ASCII_ZERO = 48;  
    uint256 constant ASCII_RELATIVE_ZERO = 87;  
    uint256 constant ASCII_LOWER_EX = 120;  
    bytes2 constant COLON = 0x3a20;  
    bytes2 constant COMMA = 0x2c20;  
    bytes2 constant LPAREN = 0x203c;  
    byte constant RPAREN = 0x3e;  
    uint256 constant FOUR_BIT_MASK = 0xf;

     

    function that(
        bool must,
        bytes32 file,
        bytes32 reason
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason)
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA,
        uint256 payloadB
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        COMMA,
                        stringify(payloadC),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        COMMA,
                        stringify(payloadC),
                        RPAREN
                    )
                )
            );
        }
    }

     

    function stringifyTruncated(
        bytes32 input
    )
        private
        pure
        returns (bytes memory)
    {
         
        bytes memory result = abi.encodePacked(input);

         
        for (uint256 i = 32; i > 0; ) {
             
             
            i--;

             
            if (result[i] != 0) {
                uint256 length = i + 1;

                 
                assembly {
                    mstore(result, length)  
                }

                return result;
            }
        }

         
        return new bytes(0);
    }

    function stringify(
        uint256 input
    )
        private
        pure
        returns (bytes memory)
    {
        if (input == 0) {
            return "0";
        }

         
        uint256 j = input;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

         
        bytes memory bstr = new bytes(length);

         
        j = input;
        for (uint256 i = length; i > 0; ) {
             
             
            i--;

             
            bstr[i] = byte(uint8(ASCII_ZERO + (j % 10)));

             
            j /= 10;
        }

        return bstr;
    }

    function stringify(
        address input
    )
        private
        pure
        returns (bytes memory)
    {
        uint256 z = uint256(input);

         
        bytes memory result = new bytes(42);

         
        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));

         
        for (uint256 i = 0; i < 20; i++) {
             
            uint256 shift = i * 2;

             
            result[41 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;

             
            result[40 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function stringify(
        bytes32 input
    )
        private
        pure
        returns (bytes memory)
    {
        uint256 z = uint256(input);

         
        bytes memory result = new bytes(66);

         
        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));

         
        for (uint256 i = 0; i < 32; i++) {
             
            uint256 shift = i * 2;

             
            result[65 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;

             
            result[64 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function char(
        uint256 input
    )
        private
        pure
        returns (byte)
    {
         
        if (input < 10) {
            return byte(uint8(input + ASCII_ZERO));
        }

         
        return byte(uint8(input + ASCII_RELATIVE_ZERO));
    }
}

 

 
library Math {
    using SafeMath for uint256;

     

    bytes32 constant FILE = "Math";

     

     
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

     
    function getPartialRoundUp(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        if (target == 0 || numerator == 0) {
             
            return SafeMath.div(0, denominator);
        }
        return target.mul(numerator).sub(1).div(denominator).add(1);
    }

    function to128(
        uint256 number
    )
        internal
        pure
        returns (uint128)
    {
        uint128 result = uint128(number);
        Require.that(
            result == number,
            FILE,
            "Unsafe cast to uint128"
        );
        return result;
    }

    function to96(
        uint256 number
    )
        internal
        pure
        returns (uint96)
    {
        uint96 result = uint96(number);
        Require.that(
            result == number,
            FILE,
            "Unsafe cast to uint96"
        );
        return result;
    }

    function to32(
        uint256 number
    )
        internal
        pure
        returns (uint32)
    {
        uint32 result = uint32(number);
        Require.that(
            result == number,
            FILE,
            "Unsafe cast to uint32"
        );
        return result;
    }

    function min(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a > b ? a : b;
    }
}

 

 
library Types {
    using Math for uint256;

     

    enum AssetDenomination {
        Wei,  
        Par   
    }

    enum AssetReference {
        Delta,  
        Target  
    }

    struct AssetAmount {
        bool sign;  
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

     

     

     
    struct Par {
        bool sign;  
        uint128 value;
    }

     

     

     
    struct Wei {
        bool sign;  
        uint256 value;
    }

     
}

 

 
library Account {
     

     
    enum Status {
        Normal,
        Liquid,
        Vapor
    }

     

     
    struct Info {
        address owner;   
        uint256 number;  
    }

     
}

 

 
library Actions {

     

    bytes32 constant FILE = "Actions";

     

    enum ActionType {
        Deposit,    
        Withdraw,   
        Transfer,   
        Buy,        
        Sell,       
        Trade,      
        Liquidate,  
        Vaporize,   
        Call        
    }

    enum AccountLayout {
        OnePrimary,
        TwoPrimary,
        PrimaryAndSecondary
    }

    enum MarketLayout {
        ZeroMarkets,
        OneMarket,
        TwoMarkets
    }

     

     
    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

     

    function getMarketLayout(
        ActionType actionType
    )
        internal
        pure
        returns (MarketLayout)
    {
        if (
            actionType == Actions.ActionType.Deposit
            || actionType == Actions.ActionType.Withdraw
            || actionType == Actions.ActionType.Transfer
        ) {
            return MarketLayout.OneMarket;
        }
        else if (actionType == Actions.ActionType.Call) {
            return MarketLayout.ZeroMarkets;
        }
        return MarketLayout.TwoMarkets;
    }

    function getAccountLayout(
        ActionType actionType
    )
        internal
        pure
        returns (AccountLayout)
    {
        if (
            actionType == Actions.ActionType.Transfer
            || actionType == Actions.ActionType.Trade
        ) {
            return AccountLayout.TwoPrimary;
        } else if (
            actionType == Actions.ActionType.Liquidate
            || actionType == Actions.ActionType.Vaporize
        ) {
            return AccountLayout.PrimaryAndSecondary;
        }
        return AccountLayout.OnePrimary;
    }

     
}

 


 
contract SoloMargin {
     

     
    function operate(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    )
        public;

     

     
    function getIsLocalOperator(
        address owner,
        address operator
    )
        public
        view
        returns (bool);

     
}

 

 
contract OnlySolo {

     

    bytes32 constant FILE = "OnlySolo";

     

    SoloMargin public SOLO_MARGIN;

     

    constructor (
        address soloMargin
    )
        public
    {
        SOLO_MARGIN = SoloMargin(soloMargin);
    }

     

    modifier onlySolo(address from) {
        Require.that(
            from == address(SOLO_MARGIN),
            FILE,
            "Only Solo can call function",
            from
        );
        _;
    }
}

 

 
library TypedSignature {

     

    bytes32 constant private FILE = "TypedSignature";

     
    bytes constant private PREPEND_DEC = "\x19Ethereum Signed Message:\n32";

     
    bytes constant private PREPEND_HEX = "\x19Ethereum Signed Message:\n\x20";

     
    uint256 constant private NUM_SIGNATURE_BYTES = 66;

     

    enum SignatureType {
        NoPrepend,
        Decimal,
        Hexadecimal,
        Invalid
    }

     

     
    function recover(
        bytes32 hash,
        bytes memory signatureWithType
    )
        internal
        pure
        returns (address)
    {
        Require.that(
            signatureWithType.length == NUM_SIGNATURE_BYTES,
            FILE,
            "Invalid signature length"
        );

        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 rawSigType;

         
        assembly {
            r := mload(add(signatureWithType, 0x20))
            s := mload(add(signatureWithType, 0x40))
            let lastSlot := mload(add(signatureWithType, 0x60))
            v := byte(0, lastSlot)
            rawSigType := byte(1, lastSlot)
        }

        Require.that(
            rawSigType < uint8(SignatureType.Invalid),
            FILE,
            "Invalid signature type"
        );

        SignatureType sigType = SignatureType(rawSigType);

        bytes32 signedHash;
        if (sigType == SignatureType.NoPrepend) {
            signedHash = hash;
        } else if (sigType == SignatureType.Decimal) {
            signedHash = keccak256(abi.encodePacked(PREPEND_DEC, hash));
        } else {
            assert(sigType == SignatureType.Hexadecimal);
            signedHash = keccak256(abi.encodePacked(PREPEND_HEX, hash));
        }

        return ecrecover(
            signedHash,
            v,
            r,
            s
        );
    }
}

 

 
contract SignedOperationProxy is
    OnlySolo,
    Ownable
{
    using SafeMath for uint256;

     

    bytes32 constant private FILE = "SignedOperationProxy";

     
    bytes2 constant private EIP191_HEADER = 0x1901;

     
    string constant private EIP712_DOMAIN_NAME = "SignedOperationProxy";

     
    string constant private EIP712_DOMAIN_VERSION = "1.0";

     
    bytes constant private EIP712_DOMAIN_STRING = abi.encodePacked(
        "EIP712Domain(",
        "string name,",
        "string version,",
        "uint256 chainId,",
        "address verifyingContract",
        ")"
    );

     
    bytes constant private EIP712_OPERATION_STRING = abi.encodePacked(
        "Operation(",
        "Action[] actions,",
        "uint256 expiration,",
        "uint256 salt,",
        "address sender",
        ")"
    );

     
    bytes constant private EIP712_ACTION_STRING = abi.encodePacked(
        "Action(",
        "uint8 actionType,",
        "address accountOwner,",
        "uint256 accountNumber,",
        "AssetAmount assetAmount,",
        "uint256 primaryMarketId,",
        "uint256 secondaryMarketId,",
        "address otherAddress,",
        "address otherAccountOwner,",
        "uint256 otherAccountNumber,",
        "bytes data",
        ")"
    );

     
    bytes constant private EIP712_ASSET_AMOUNT_STRING = abi.encodePacked(
        "AssetAmount(",
        "bool sign,",
        "uint8 denomination,",
        "uint8 ref,",
        "uint256 value",
        ")"
    );

     
     
    bytes32 constant private EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = keccak256(abi.encodePacked(
        EIP712_DOMAIN_STRING
    ));

     
     
    bytes32 constant private EIP712_OPERATION_HASH = keccak256(abi.encodePacked(
        EIP712_OPERATION_STRING,
        EIP712_ACTION_STRING,
        EIP712_ASSET_AMOUNT_STRING
    ));

     
     
    bytes32 constant private EIP712_ACTION_HASH = keccak256(abi.encodePacked(
        EIP712_ACTION_STRING,
        EIP712_ASSET_AMOUNT_STRING
    ));

     
     
    bytes32 constant private EIP712_ASSET_AMOUNT_HASH = keccak256(abi.encodePacked(
        EIP712_ASSET_AMOUNT_STRING
    ));

     

    struct Authorization {
        uint256 numActions;
        uint256 expiration;
        uint256 salt;
        address sender;
        bytes signature;
    }

    struct OperationQueryInput {
        bytes32 operationHash;
        address operationSigner;
    }

     

    event ContractStatusSet(
        bool operational
    );

    event LogOperationExecuted(
        bytes32 indexed operationHash,
        address indexed signer,
        address indexed sender
    );

    event LogOperationCanceled(
        bytes32 indexed operationHash,
        address indexed canceler
    );

     

     
    bytes32 public EIP712_DOMAIN_HASH;

     

      
    bool public g_isOperational;

     
    mapping (address => mapping (bytes32 => bool)) public g_invalidated;

     

    constructor (
        address soloMargin,
        uint256 chainId
    )
        public
        OnlySolo(soloMargin)
    {
        g_isOperational = true;

         
        EIP712_DOMAIN_HASH = keccak256(abi.encode(
            EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
            keccak256(bytes(EIP712_DOMAIN_NAME)),
            keccak256(bytes(EIP712_DOMAIN_VERSION)),
            chainId,
            address(this)
        ));
    }

     

      
    function shutDown()
        external
        onlyOwner
    {
        g_isOperational = false;
        emit ContractStatusSet(false);
    }

      
    function startUp()
        external
        onlyOwner
    {
        g_isOperational = true;
        emit ContractStatusSet(true);
    }

     

     
    function cancel(
        bytes32 operationHash
    )
        external
    {
        g_invalidated[msg.sender][operationHash] = true;
        emit LogOperationCanceled(operationHash, msg.sender);
    }

     
    function operate(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions,
        Authorization[] memory auths
    )
        public
    {
        Require.that(
            g_isOperational,
            FILE,
            "Contract is not operational"
        );

         
        uint256 actionStartIdx = 0;

         
        for (uint256 authIdx = 0; authIdx < auths.length; authIdx++) {
            Authorization memory auth = auths[authIdx];

             
            Require.that(
                auth.expiration == 0 || auth.expiration >= block.timestamp,
                FILE,
                "Signed operation is expired",
                authIdx
            );

             
            Require.that(
                auth.sender == address(0) || auth.sender == msg.sender,
                FILE,
                "Operation sender mismatch",
                authIdx
            );

             
            address signer = getSigner(
                accounts,
                actions,
                auth,
                actionStartIdx
            );

             
            uint256 actionEndIdx = actionStartIdx.add(auth.numActions);

             
            for (uint256 actionIdx = actionStartIdx; actionIdx < actionEndIdx; actionIdx++) {
                 
                Actions.ActionArgs memory action = actions[actionIdx];
                validateAccountOwner(accounts[action.accountId].owner, signer);

                 
                if (action.actionType == Actions.ActionType.Transfer) {
                    validateAccountOwner(accounts[action.otherAccountId].owner, signer);
                }
            }

             
            actionStartIdx = actionEndIdx;
        }

         
        Require.that(
            actionStartIdx == actions.length,
            FILE,
            "Not all actions are signed"
        );

         
        SOLO_MARGIN.operate(accounts, actions);
    }

     

     
    function getOperationsAreInvalid(
        OperationQueryInput[] memory operations
    )
        public
        view
        returns(bool[] memory)
    {
        uint256 numOperations = operations.length;
        bool[] memory output = new bool[](numOperations);

        for (uint256 i = 0; i < numOperations; i++) {
            OperationQueryInput memory operation = operations[i];
            output[i] = g_invalidated[operation.operationSigner][operation.operationHash];
        }
        return output;
    }

     

     
    function getSigner(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions,
        Authorization memory auth,
        uint256 startIdx
    )
        private
        returns (address)
    {
         
        if (auth.signature.length == 0) {
            return msg.sender;
        }

         
        bytes32 operationHash = getOperationHash(
            accounts,
            actions,
            auth,
            startIdx
        );

         
        address signer = TypedSignature.recover(operationHash, auth.signature);

         
        Require.that(
            !g_invalidated[signer][operationHash],
            FILE,
            "Hash already used or canceled",
            operationHash
        );

         
        g_invalidated[signer][operationHash] = true;
        emit LogOperationExecuted(operationHash, signer, msg.sender);

        return signer;
    }

     
    function validateAccountOwner(
        address accountOwner,
        address signer
    )
        private
        view
    {
        bool valid =
            msg.sender == accountOwner
            || signer == accountOwner
            || SOLO_MARGIN.getIsLocalOperator(accountOwner, msg.sender)
            || SOLO_MARGIN.getIsLocalOperator(accountOwner, signer);

        Require.that(
            valid,
            FILE,
            "Invalid signer",
            signer
        );
    }

     
    function getOperationHash(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions,
        Authorization memory auth,
        uint256 startIdx
    )
        private
        view
        returns (bytes32)
    {
         
        bytes32 actionsEncoding = getActionsEncoding(
            accounts,
            actions,
            auth,
            startIdx
        );

         
         
        bytes32 structHash = keccak256(abi.encode(
            EIP712_OPERATION_HASH,
            actionsEncoding,
            auth.expiration,
            auth.salt,
            auth.sender
        ));

         
         
        return keccak256(abi.encodePacked(
            EIP191_HEADER,
            EIP712_DOMAIN_HASH,
            structHash
        ));
    }

     
    function getActionsEncoding(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions,
        Authorization memory auth,
        uint256 startIdx
    )
        private
        pure
        returns (bytes32)
    {
         
        bytes32[] memory actionsBytes = new bytes32[](auth.numActions);

         
        for (uint256 i = 0; i < auth.numActions; i++) {
            Actions.ActionArgs memory action = actions[startIdx + i];

             
            Account.Info memory otherAccount =
                (Actions.getAccountLayout(action.actionType) == Actions.AccountLayout.OnePrimary)
                ? Account.Info({ owner: address(0), number: 0 })
                : accounts[action.otherAccountId];

             
             
            actionsBytes[i] = getActionHash(
                action,
                accounts[action.accountId],
                otherAccount
            );
        }

        return keccak256(abi.encodePacked(actionsBytes));
    }

     
    function getActionHash(
        Actions.ActionArgs memory action,
        Account.Info memory primaryAccount,
        Account.Info memory secondaryAccount
    )
        private
        pure
        returns (bytes32)
    {
         
        return keccak256(abi.encode(
            EIP712_ACTION_HASH,
            action.actionType,
            primaryAccount.owner,
            primaryAccount.number,
            getAssetAmountHash(action.amount),
            action.primaryMarketId,
            action.secondaryMarketId,
            action.otherAddress,
            secondaryAccount.owner,
            secondaryAccount.number,
            keccak256(action.data)
        ));
    }

     
    function getAssetAmountHash(
        Types.AssetAmount memory amount
    )
        private
        pure
        returns (bytes32)
    {
         
        return keccak256(abi.encode(
            EIP712_ASSET_AMOUNT_HASH,
            amount.sign,
            amount.denomination,
            amount.ref,
            amount.value
        ));
    }
}