 

 

pragma solidity 0.4.19;  

contract Owned { address public owner; }  

interface Token {

     
     
     
     
    function transfer(address _to, uint _value) public returns (bool);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value) public returns (bool);

     
     
     
     
    function approve(address _spender, uint _value) public returns (bool);

     
     
    function balanceOf(address _owner) public view returns (uint);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint);

    event Transfer(address indexed _from, address indexed _to, uint _value);  
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


 
 
 
contract TokenTransferProxy {

    modifier onlyExchange {
        require(msg.sender == exchangeAddress);
        _;
    }

    address public exchangeAddress;


    event LogAuthorizedAddressAdded(address indexed target, address indexed caller);

    function TokenTransferProxy() public {
        setExchange(msg.sender);
    }
     

     
     
     
     
     
     
    function transferFrom(
        address token,
        address from,
        address to,
        uint value)
        public
        onlyExchange
        returns (bool)
    {
        return Token(token).transferFrom(from, to, value);
    }

     
     
    function setExchange(address _exchange) internal {
        require(exchangeAddress == address(0));
        exchangeAddress = _exchange;
    }
}

contract SafeMath {
    function safeMul(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        uint c = a / b;
        return c;
    }

    function safeSub(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}


 
 
 
contract ExchangeEfx is SafeMath {

     
    enum Errors {
        ORDER_EXPIRED,                     
        ORDER_FULLY_FILLED_OR_CANCELLED,   
        ROUNDING_ERROR_TOO_LARGE,          
        INSUFFICIENT_BALANCE_OR_ALLOWANCE  
    }

    string constant public VERSION = "ETHFX.0.0";
    uint16 constant public EXTERNAL_QUERY_GAS_LIMIT = 4999;     
    uint constant public ETHFINEX_FEE = 400;  

     
    address public TOKEN_TRANSFER_PROXY_CONTRACT;

     
    mapping (bytes32 => uint) public filled;
    mapping (bytes32 => uint) public cancelled;

     
     
    mapping (address => mapping (address => bool)) public allowedValidators;

    event LogFill(
        address indexed maker,
        address taker,
        address indexed feeRecipient,
        address makerToken,
        address takerToken,
        uint filledMakerTokenAmount,
        uint filledTakerTokenAmount,
        uint paidMakerFee,
        uint paidTakerFee,
        bytes32 indexed tokens,  
        bytes32 orderHash
    );

    event LogCancel(
        address indexed maker,
        address indexed feeRecipient,
        address makerToken,
        address takerToken,
        uint cancelledMakerTokenAmount,
        uint cancelledTakerTokenAmount,
        bytes32 indexed tokens,
        bytes32 orderHash
    );

    event LogError(uint8 indexed errorId, bytes32 indexed orderHash);

    event SignatureValidatorApproval(
        address indexed signerAddress,      
        address indexed validatorAddress,   
        bool approved                       
    );

    struct Order {
        address maker;
        address taker;
        address makerToken;
        address takerToken;
        address feeRecipient;
        uint makerTokenAmount;
        uint takerTokenAmount;
        uint makerFee;
        uint takerFee;
        uint expirationTimestampInSec;
        bytes32 orderHash;
    }

     
    function ExchangeEfx() public {
         
        TOKEN_TRANSFER_PROXY_CONTRACT = address(new TokenTransferProxy());
    }

     

     
     
     
     
     
     
     
     
     
    function fillOrder(
          address[5] orderAddresses,
          uint[6] orderValues,
          uint fillTakerTokenAmount,
          bool shouldThrowOnInsufficientBalanceOrAllowance,
          uint8 v,
          bytes32 r,
          bytes32 s)
          public
          returns (uint filledTakerTokenAmount)
    {
        Order memory order = Order({
            maker: orderAddresses[0],
            taker: orderAddresses[1],
            makerToken: orderAddresses[2],
            takerToken: orderAddresses[3],
            feeRecipient: orderAddresses[4],
            makerTokenAmount: orderValues[0],
            takerTokenAmount: orderValues[1],
            makerFee: orderValues[2],
            takerFee: orderValues[3],
            expirationTimestampInSec: orderValues[4],
            orderHash: getOrderHash(orderAddresses, orderValues)
        });

        require(order.taker == address(0) || order.taker == msg.sender);
        require(order.makerTokenAmount > 0 && order.takerTokenAmount > 0 && fillTakerTokenAmount > 0);

        require(isValidSignature(
            order.maker,
            order.orderHash,
            v,
            r,
            s
        ));

        if (block.timestamp >= order.expirationTimestampInSec) {
            LogError(uint8(Errors.ORDER_EXPIRED), order.orderHash);
            return 0;
        }

        uint remainingTakerTokenAmount = safeSub(order.takerTokenAmount, getUnavailableTakerTokenAmount(order.orderHash));
        filledTakerTokenAmount = min256(fillTakerTokenAmount, remainingTakerTokenAmount);
        if (filledTakerTokenAmount == 0) {
            LogError(uint8(Errors.ORDER_FULLY_FILLED_OR_CANCELLED), order.orderHash);
            return 0;
        }

        if (isRoundingError(filledTakerTokenAmount, order.takerTokenAmount, order.makerTokenAmount)) {
            LogError(uint8(Errors.ROUNDING_ERROR_TOO_LARGE), order.orderHash);
            return 0;
        }

        if (!shouldThrowOnInsufficientBalanceOrAllowance && !isTransferable(order, filledTakerTokenAmount)) {
            LogError(uint8(Errors.INSUFFICIENT_BALANCE_OR_ALLOWANCE), order.orderHash);
            return 0;
        }

         
        uint filledMakerTokenAmount = getPartialAmount(filledTakerTokenAmount, order.takerTokenAmount, order.makerTokenAmount);
         

        uint paidMakerFee;
        uint paidTakerFee;
        filled[order.orderHash] = safeAdd(filled[order.orderHash], filledTakerTokenAmount);
        require(transferViaTokenTransferProxy(
            order.makerToken,
            order.maker,
            msg.sender,
            filledMakerTokenAmount
        ));
        require(transferViaTokenTransferProxy(
            order.takerToken,
            msg.sender,
            order.maker,
            filledTakerTokenAmount - safeDiv(filledTakerTokenAmount, ETHFINEX_FEE)
        ));
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         

        LogFill(
            order.maker,
            msg.sender,
            order.feeRecipient,
            order.makerToken,
            order.takerToken,
            filledMakerTokenAmount,
            filledTakerTokenAmount,
            paidMakerFee,
            paidTakerFee,
            keccak256(order.makerToken, order.takerToken),
            order.orderHash
        );
        return filledTakerTokenAmount;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
     

     
     
     
     

     
     
     
     
     
     

     

     
     
     
     
     
     
     
     
     
     
     
     

     

     
     
     
     
     
     
     
    function fillOrKillOrder(
        address[5] orderAddresses,
        uint[6] orderValues,
        uint fillTakerTokenAmount,
        uint8 v,
        bytes32 r,
        bytes32 s)
        public
    {
        require(fillOrder(
            orderAddresses,
            orderValues,
            fillTakerTokenAmount,
            false,
            v,
            r,
            s
        ) == fillTakerTokenAmount);
    }

     
     
     
     
     
     
     
     
    function batchFillOrders(
        address[5][] orderAddresses,
        uint[6][] orderValues,
        uint[] fillTakerTokenAmounts,
        bool shouldThrowOnInsufficientBalanceOrAllowance,
        uint8[] v,
        bytes32[] r,
        bytes32[] s)
        public
    {
        for (uint i = 0; i < orderAddresses.length; i++) {
            fillOrder(
                orderAddresses[i],
                orderValues[i],
                fillTakerTokenAmounts[i],
                shouldThrowOnInsufficientBalanceOrAllowance,
                v[i],
                r[i],
                s[i]
            );
        }
    }

     
     
     
     
     
     
     
    function batchFillOrKillOrders(
        address[5][] orderAddresses,
        uint[6][] orderValues,
        uint[] fillTakerTokenAmounts,
        uint8[] v,
        bytes32[] r,
        bytes32[] s)
        public
    {
        for (uint i = 0; i < orderAddresses.length; i++) {
            fillOrKillOrder(
                orderAddresses[i],
                orderValues[i],
                fillTakerTokenAmounts[i],
                v[i],
                r[i],
                s[i]
            );
        }
    }

     
     
     
     
     
     
     
     
     
    function fillOrdersUpTo(
        address[5][] orderAddresses,
        uint[6][] orderValues,
        uint fillTakerTokenAmount,
        bool shouldThrowOnInsufficientBalanceOrAllowance,
        uint8[] v,
        bytes32[] r,
        bytes32[] s)
        public
        returns (uint)
    {
        uint filledTakerTokenAmount = 0;
        for (uint i = 0; i < orderAddresses.length; i++) {
            require(orderAddresses[i][3] == orderAddresses[0][3]);  
            filledTakerTokenAmount = safeAdd(filledTakerTokenAmount, fillOrder(
                orderAddresses[i],
                orderValues[i],
                safeSub(fillTakerTokenAmount, filledTakerTokenAmount),
                shouldThrowOnInsufficientBalanceOrAllowance,
                v[i],
                r[i],
                s[i]
            ));
            if (filledTakerTokenAmount == fillTakerTokenAmount) break;
        }
        return filledTakerTokenAmount;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     

     
     
     
     
    function getOrderHash(address[5] orderAddresses, uint[6] orderValues)
        public
        constant
        returns (bytes32)
    {
        return keccak256(
            address(this),
            orderAddresses[0],  
            orderAddresses[1],  
            orderAddresses[2],  
            orderAddresses[3],  
            orderAddresses[4],  
            orderValues[0],     
            orderValues[1],     
            orderValues[2],     
            orderValues[3],     
            orderValues[4],     
            orderValues[5]      
        );
    }


     
     
     
     
     
     
     
    function isValidSignature(
        address maker,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s)
        public
         
        view  
        returns (bool)
    {
        address validator = ecrecover(
            keccak256("\x19Ethereum Signed Message:\n32", hash),
            v,
            r,
            s
        );

        if (allowedValidators[maker][validator]) {
            return true;
        } else if (isContract(maker)) {
            return Owned(maker).owner() == validator;
        } else {
            return maker == validator;
        }
    }

     
     
     
     
     
    function isRoundingError(uint numerator, uint denominator, uint target)
        public
        pure
        returns (bool)
    {
        uint remainder = mulmod(target, numerator, denominator);
        if (remainder == 0) return false;  

        uint errPercentageTimes1000000 = safeDiv(
            safeMul(remainder, 1000000),
            safeMul(numerator, target)
        );
        return errPercentageTimes1000000 > 1000;
    }

     
     
     
     
     
    function getPartialAmount(uint numerator, uint denominator, uint target)
        public
        pure
        returns (uint)
    {
        return safeDiv(safeMul(numerator, target), denominator);
    }

     
     
     
    function getUnavailableTakerTokenAmount(bytes32 orderHash)
        public
        constant
        returns (uint)
    {
        return safeAdd(filled[orderHash], cancelled[orderHash]);
    }


     

     
     
     
     
     
     
    function transferViaTokenTransferProxy(
        address token,
        address from,
        address to,
        uint value)
        internal
        returns (bool)
    {
        return TokenTransferProxy(TOKEN_TRANSFER_PROXY_CONTRACT).transferFrom(token, from, to, value);
    }

     
     
     
     
    function isTransferable(Order order, uint fillTakerTokenAmount)
        internal
        constant   
        returns (bool)
    {
        address taker = msg.sender;
        uint fillMakerTokenAmount = getPartialAmount(fillTakerTokenAmount, order.takerTokenAmount, order.makerTokenAmount);

         
         
         
         
         
         
         

         
         
         
         
         

         
         
         
         
         
         
         
         
         
         
         

         

        if (   getBalance(order.makerToken, order.maker) < fillMakerTokenAmount
                   || getAllowance(order.makerToken, order.maker) < fillMakerTokenAmount
                   || getBalance(order.takerToken, taker) < fillTakerTokenAmount
                   || getAllowance(order.takerToken, taker) < fillTakerTokenAmount
        ) return false;

        return true;
    }

     
     
     
     
    function getBalance(address token, address owner)
        internal
        constant   
        returns (uint)
    {
        return Token(token).balanceOf.gas(EXTERNAL_QUERY_GAS_LIMIT)(owner);  
    }

     
     
     
     
    function getAllowance(address token, address owner)
        internal
        constant   
        returns (uint)
    {
        return Token(token).allowance.gas(EXTERNAL_QUERY_GAS_LIMIT)(owner, TOKEN_TRANSFER_PROXY_CONTRACT);  
    }

     
     
     
     
     
    function isContract(address _target)
        internal view
        returns (bool)
    {
        uint size;
        assembly {
            size := extcodesize(_target)
        }
        return size > 0;
    }

     
     
     
    function setSignatureValidatorApproval(
        address validatorAddress,
        bool approval
    )
        external
    {
        address signerAddress = msg.sender;
        allowedValidators[signerAddress][validatorAddress] = approval;
        SignatureValidatorApproval(
            signerAddress,
            validatorAddress,
            approval
        );
    }
}