 

 

pragma solidity 0.5.10;
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

     

     
    struct TotalPar {
        uint128 borrow;
        uint128 supply;
    }

     
    struct Par {
        bool sign;  
        uint128 value;
    }

    function zeroPar()
        internal
        pure
        returns (Par memory)
    {
        return Par({
            sign: false,
            value: 0
        });
    }

    function sub(
        Par memory a,
        Par memory b
    )
        internal
        pure
        returns (Par memory)
    {
        return add(a, negative(b));
    }

    function add(
        Par memory a,
        Par memory b
    )
        internal
        pure
        returns (Par memory)
    {
        Par memory result;
        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = SafeMath.add(a.value, b.value).to128();
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = SafeMath.sub(a.value, b.value).to128();
            } else {
                result.sign = b.sign;
                result.value = SafeMath.sub(b.value, a.value).to128();
            }
        }
        return result;
    }

    function equals(
        Par memory a,
        Par memory b
    )
        internal
        pure
        returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        Par memory a
    )
        internal
        pure
        returns (Par memory)
    {
        return Par({
            sign: !a.sign,
            value: a.value
        });
    }

    function isNegative(
        Par memory a
    )
        internal
        pure
        returns (bool)
    {
        return !a.sign && a.value > 0;
    }

    function isPositive(
        Par memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.sign && a.value > 0;
    }

    function isZero(
        Par memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.value == 0;
    }

     

     
    struct Wei {
        bool sign;  
        uint256 value;
    }

    function zeroWei()
        internal
        pure
        returns (Wei memory)
    {
        return Wei({
            sign: false,
            value: 0
        });
    }

    function sub(
        Wei memory a,
        Wei memory b
    )
        internal
        pure
        returns (Wei memory)
    {
        return add(a, negative(b));
    }

    function add(
        Wei memory a,
        Wei memory b
    )
        internal
        pure
        returns (Wei memory)
    {
        Wei memory result;
        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = SafeMath.add(a.value, b.value);
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = SafeMath.sub(a.value, b.value);
            } else {
                result.sign = b.sign;
                result.value = SafeMath.sub(b.value, a.value);
            }
        }
        return result;
    }

    function equals(
        Wei memory a,
        Wei memory b
    )
        internal
        pure
        returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        Wei memory a
    )
        internal
        pure
        returns (Wei memory)
    {
        return Wei({
            sign: !a.sign,
            value: a.value
        });
    }

    function isNegative(
        Wei memory a
    )
        internal
        pure
        returns (bool)
    {
        return !a.sign && a.value > 0;
    }

    function isPositive(
        Wei memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.sign && a.value > 0;
    }

    function isZero(
        Wei memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.value == 0;
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

     
    struct Storage {
        mapping (uint256 => Types.Par) balances;  
        Status status;
    }

     

    function equals(
        Info memory a,
        Info memory b
    )
        internal
        pure
        returns (bool)
    {
        return a.owner == b.owner && a.number == b.number;
    }
}

 

 
contract IAutoTrader {

     

     
    function getTradeCost(
        uint256 inputMarketId,
        uint256 outputMarketId,
        Account.Info memory makerAccount,
        Account.Info memory takerAccount,
        Types.Par memory oldInputPar,
        Types.Par memory newInputPar,
        Types.Wei memory inputWei,
        bytes memory data
    )
        public
        returns (Types.AssetAmount memory);
}

 

 
contract ICallee {

     

     
    function callFunction(
        address sender,
        Account.Info memory accountInfo,
        bytes memory data
    )
        public;
}

 

contract SoloMargin {   }

 

 
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

 

 
contract LimitOrders is
    Ownable,
    OnlySolo,
    IAutoTrader,
    ICallee
{
    using Math for uint256;
    using SafeMath for uint256;
    using Types for Types.Par;
    using Types for Types.Wei;

     

    bytes32 constant FILE = "LimitOrders";

     
    bytes2 constant private EIP191_HEADER = 0x1901;

     
    string constant private EIP712_DOMAIN_NAME = "LimitOrders";

     
    string constant private EIP712_DOMAIN_VERSION = "1.0";

     
     
    bytes32 constant public EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = keccak256(abi.encodePacked(
        "EIP712Domain(",
        "string name,",
        "string version,",
        "uint256 chainId,",
        "address verifyingContract",
        ")"
    ));

     
     
    bytes32 constant public EIP712_LIMIT_ORDER_STRUCT_SCHEMA_HASH = keccak256(abi.encodePacked(
        "LimitOrder(",
        "uint256 makerMarket,",
        "uint256 takerMarket,",
        "uint256 makerAmount,",
        "uint256 takerAmount,",
        "address makerAccountOwner,",
        "uint256 makerAccountNumber,",
        "address takerAccountOwner,",
        "uint256 takerAccountNumber,",
        "uint256 expiration,",
        "uint256 salt",
        ")"
    ));

     
    uint256 constant private NUM_ORDER_BYTES = 320;

     
    uint256 constant private NUM_SIGNATURE_BYTES = 66;

     
    uint256 constant private NUM_CALLFUNCTIONDATA_BYTES = 64;

     

    enum OrderStatus {
        Null,
        Approved,
        Canceled
    }

    enum CallFunctionType {
        Approve,
        Cancel
    }

     

    struct Order {
        uint256 makerMarket;
        uint256 takerMarket;
        uint256 makerAmount;
        uint256 takerAmount;
        address makerAccountOwner;
        uint256 makerAccountNumber;
        address takerAccountOwner;
        uint256 takerAccountNumber;
        uint256 expiration;
        uint256 salt;
        bytes32 orderHash;
    }

    struct CallFunctionData {
        CallFunctionType callType;
        bytes32 orderHash;
    }

    struct OrderQueryInput {
        bytes32 orderHash;
        address orderMaker;
    }

    struct OrderQueryOutput {
        OrderStatus orderStatus;
        uint256 orderMakerFilledAmount;
    }

     

    event ContractStatusSet(
        bool operational
    );

    event LogLimitOrderCanceled(
        bytes32 indexed orderHash,
        address indexed canceler
    );

    event LogLimitOrderApproved(
        bytes32 indexed orderHash,
        address indexed approver
    );

    event LogLimitOrderFilled(
        bytes32 indexed orderHash,
        address indexed orderMaker,
        uint256 makerFillAmount,
        uint256 totalMakerFilledAmount
    );

     

     
    bytes32 public EIP712_DOMAIN_HASH;

     

     
    bool public g_isOperational;

     
    mapping (bytes32 => uint256) public g_makerFilledAmount;

     
    mapping (address => mapping (bytes32 => OrderStatus)) public g_status;

     

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

     

     
    function cancelOrder(
        bytes32 orderHash
    )
        external
    {
        cancelOrderInternal(msg.sender, orderHash);
    }

     
    function approveOrder(
        bytes32 orderHash
    )
        external
    {
        approveOrderInternal(msg.sender, orderHash);
    }

     

     
    function getTradeCost(
        uint256 inputMarketId,
        uint256 outputMarketId,
        Account.Info memory makerAccount,
        Account.Info memory takerAccount,
        Types.Par memory  ,
        Types.Par memory  ,
        Types.Wei memory inputWei,
        bytes memory data
    )
        public
        onlySolo(msg.sender)
        returns (Types.AssetAmount memory)
    {
        Require.that(
            g_isOperational,
            FILE,
            "Contract is not operational"
        );

        Order memory order = getOrderAndValidateSignature(data);

        verifyOrderAndAccountsAndMarkets(
            order,
            makerAccount,
            takerAccount,
            inputMarketId,
            outputMarketId,
            inputWei
        );

        return getOutputAssetAmount(
            inputMarketId,
            outputMarketId,
            inputWei,
            order
        );
    }

     
    function callFunction(
        address  ,
        Account.Info memory accountInfo,
        bytes memory data
    )
        public
        onlySolo(msg.sender)
    {
        CallFunctionData memory cfd = parseCallFunctionData(data);
        if (cfd.callType == CallFunctionType.Approve) {
            approveOrderInternal(accountInfo.owner, cfd.orderHash);
        } else {
            assert(cfd.callType == CallFunctionType.Cancel);
            cancelOrderInternal(accountInfo.owner, cfd.orderHash);
        }
    }

     

     
    function getOrderStates(
        OrderQueryInput[] memory orders
    )
        public
        view
        returns(OrderQueryOutput[] memory)
    {
        uint256 numOrders = orders.length;
        OrderQueryOutput[] memory output = new OrderQueryOutput[](orders.length);

         
        for (uint256 i = 0; i < numOrders; i++) {
             
            OrderQueryInput memory order = orders[i];

             
            output[i] = OrderQueryOutput({
                orderStatus: g_status[order.orderMaker][order.orderHash],
                orderMakerFilledAmount: g_makerFilledAmount[order.orderHash]
            });
        }
        return output;
    }

     

     
    function cancelOrderInternal(
        address canceler,
        bytes32 orderHash
    )
        private
    {
        g_status[canceler][orderHash] = OrderStatus.Canceled;
        emit LogLimitOrderCanceled(orderHash, canceler);
    }

     
    function approveOrderInternal(
        address approver,
        bytes32 orderHash
    )
        private
    {
        Require.that(
            g_status[approver][orderHash] != OrderStatus.Canceled,
            FILE,
            "Cannot approve canceled order",
            orderHash
        );
        g_status[approver][orderHash] = OrderStatus.Approved;
        emit LogLimitOrderApproved(orderHash, approver);
    }

     

     
    function verifyOrderAndAccountsAndMarkets(
        Order memory order,
        Account.Info memory makerAccount,
        Account.Info memory takerAccount,
        uint256 inputMarketId,
        uint256 outputMarketId,
        Types.Wei memory inputWei
    )
        private
        view
    {
         
        Require.that(
            order.expiration == 0 || order.expiration >= block.timestamp,
            FILE,
            "Order expired",
            order.orderHash
        );

         
        Require.that(
            makerAccount.owner == order.makerAccountOwner &&
            makerAccount.number == order.makerAccountNumber,
            FILE,
            "Order maker account mismatch",
            order.orderHash
        );

         
        Require.that(
            (order.takerAccountOwner == address(0) && order.takerAccountNumber == 0 ) ||
            (order.takerAccountOwner == takerAccount.owner && order.takerAccountNumber == takerAccount.number),
            FILE,
            "Order taker account mismatch",
            order.orderHash
        );

         
        Require.that(
            (order.makerMarket == outputMarketId && order.takerMarket == inputMarketId) ||
            (order.takerMarket == outputMarketId && order.makerMarket == inputMarketId),
            FILE,
            "Market mismatch",
            order.orderHash
        );

         
        Require.that(
            !inputWei.isZero(),
            FILE,
            "InputWei is zero",
            order.orderHash
        );
        Require.that(
            inputWei.sign == (order.takerMarket == inputMarketId),
            FILE,
            "InputWei sign mismatch",
            order.orderHash
        );
    }

     
    function getOutputAssetAmount(
        uint256 inputMarketId,
        uint256 outputMarketId,
        Types.Wei memory inputWei,
        Order memory order
    )
        private
        returns (Types.AssetAmount memory)
    {
        uint256 outputAmount;
        uint256 makerFillAmount;

        if (order.takerMarket == inputMarketId) {
            outputAmount = inputWei.value.getPartial(order.makerAmount, order.takerAmount);
            makerFillAmount = outputAmount;
        } else {
            assert(order.takerMarket == outputMarketId);
            outputAmount = inputWei.value.getPartialRoundUp(order.takerAmount, order.makerAmount);
            makerFillAmount = inputWei.value;
        }

        uint256 totalMakerFilledAmount = updateMakerFilledAmount(order, makerFillAmount);

        emit LogLimitOrderFilled(
            order.orderHash,
            order.makerAccountOwner,
            makerFillAmount,
            totalMakerFilledAmount
        );

        return Types.AssetAmount({
            sign: order.takerMarket == outputMarketId,
            denomination: Types.AssetDenomination.Wei,
            ref: Types.AssetReference.Delta,
            value: outputAmount
        });
    }

     
    function updateMakerFilledAmount(
        Order memory order,
        uint256 makerFillAmount
    )
        private
        returns (uint256)
    {
        uint256 oldMakerFilledAmount = g_makerFilledAmount[order.orderHash];
        uint256 totalMakerFilledAmount = oldMakerFilledAmount.add(makerFillAmount);
        Require.that(
            totalMakerFilledAmount <= order.makerAmount,
            FILE,
            "Cannot overfill order",
            order.orderHash,
            oldMakerFilledAmount,
            makerFillAmount
        );
        g_makerFilledAmount[order.orderHash] = totalMakerFilledAmount;
        return totalMakerFilledAmount;
    }

     
    function getOrderAndValidateSignature(
        bytes memory data
    )
        private
        view
        returns (Order memory)
    {
        Order memory order = parseOrder(data);

        OrderStatus orderStatus = g_status[order.makerAccountOwner][order.orderHash];

         
        if (orderStatus == OrderStatus.Null) {
            bytes memory signature = parseSignature(data);
            address signer = TypedSignature.recover(order.orderHash, signature);
            Require.that(
                order.makerAccountOwner == signer,
                FILE,
                "Order invalid signature",
                order.orderHash
            );
        } else {
            Require.that(
                orderStatus != OrderStatus.Canceled,
                FILE,
                "Order canceled",
                order.orderHash
            );
            assert(orderStatus == OrderStatus.Approved);
        }

        return order;
    }

     

     
    function parseOrder(
        bytes memory data
    )
        private
        view
        returns (Order memory)
    {
        Require.that(
            data.length >= NUM_ORDER_BYTES,
            FILE,
            "Cannot parse order from data"
        );

        Order memory order;

         
        assembly {
            mstore(add(order, 0x000), mload(add(data, 0x020)))
            mstore(add(order, 0x020), mload(add(data, 0x040)))
            mstore(add(order, 0x040), mload(add(data, 0x060)))
            mstore(add(order, 0x060), mload(add(data, 0x080)))
            mstore(add(order, 0x080), mload(add(data, 0x0a0)))
            mstore(add(order, 0x0a0), mload(add(data, 0x0c0)))
            mstore(add(order, 0x0c0), mload(add(data, 0x0e0)))
            mstore(add(order, 0x0e0), mload(add(data, 0x100)))
            mstore(add(order, 0x100), mload(add(data, 0x120)))
            mstore(add(order, 0x120), mload(add(data, 0x140)))
        }

         
         
        bytes32 structHash = keccak256(abi.encode(
            EIP712_LIMIT_ORDER_STRUCT_SCHEMA_HASH,
            order.makerMarket,
            order.takerMarket,
            order.makerAmount,
            order.takerAmount,
            order.makerAccountOwner,
            order.makerAccountNumber,
            order.takerAccountOwner,
            order.takerAccountNumber,
            order.expiration,
            order.salt
        ));

         
         
        order.orderHash = keccak256(abi.encodePacked(
            EIP191_HEADER,
            EIP712_DOMAIN_HASH,
            structHash
        ));

        return order;
    }

     
    function parseSignature(
        bytes memory data
    )
        private
        pure
        returns (bytes memory)
    {
        Require.that(
            data.length >= NUM_ORDER_BYTES + NUM_SIGNATURE_BYTES,
            FILE,
            "Cannot parse signature from data"
        );

        bytes memory signature = new bytes(NUM_SIGNATURE_BYTES);

         
        assembly {
            mstore(add(signature, 0x020), mload(add(data, 0x160)))
            mstore(add(signature, 0x040), mload(add(data, 0x180)))
            mstore(add(signature, 0x042), mload(add(data, 0x182)))
        }

        return signature;
    }

     
    function parseCallFunctionData(
        bytes memory data
    )
        private
        pure
        returns (CallFunctionData memory)
    {
        Require.that(
            data.length >= NUM_CALLFUNCTIONDATA_BYTES,
            FILE,
            "Cannot parse CallFunctionData"
        );

        CallFunctionData memory cfd;

         
        assembly {
            mstore(add(cfd, 0x00), mload(add(data, 0x20)))
            mstore(add(cfd, 0x20), mload(add(data, 0x40)))
        }

        return cfd;
    }
}