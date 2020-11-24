 

 
pragma solidity 0.5.2;


 
 
library BytesUtil {
    function bytesToBytes32(
        bytes memory b,
        uint offset
        )
        internal
        pure
        returns (bytes32)
    {
        return bytes32(bytesToUintX(b, offset, 32));
    }

    function bytesToUint(
        bytes memory b,
        uint offset
        )
        internal
        pure
        returns (uint)
    {
        return bytesToUintX(b, offset, 32);
    }

    function bytesToAddress(
        bytes memory b,
        uint offset
        )
        internal
        pure
        returns (address)
    {
        return address(bytesToUintX(b, offset, 20) & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    }

    function bytesToUint16(
        bytes memory b,
        uint offset
        )
        internal
        pure
        returns (uint16)
    {
        return uint16(bytesToUintX(b, offset, 2) & 0xFFFF);
    }

    function bytesToUintX(
        bytes memory b,
        uint offset,
        uint numBytes
        )
        private
        pure
        returns (uint data)
    {
        require(b.length >= offset + numBytes, "INVALID_SIZE");
        assembly {
            data := mload(add(add(b, numBytes), offset))
        }
    }

    function subBytes(
        bytes memory b,
        uint offset
        )
        internal
        pure
        returns (bytes memory data)
    {
        require(b.length >= offset + 32, "INVALID_SIZE");
        assembly {
            data := add(add(b, 32), offset)
        }
    }
}
 



 
 
library MathUint {

    function mul(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a * b;
        require(a == 0 || c / a == b, "INVALID_VALUE");
    }

    function sub(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint)
    {
        require(b <= a, "INVALID_VALUE");
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
        require(c >= a, "INVALID_VALUE");
    }

    function hasRoundingError(
        uint value,
        uint numerator,
        uint denominator
        )
        internal
        pure
        returns (bool)
    {
        uint multiplied = mul(value, numerator);
        uint remainder = multiplied % denominator;
         
        return mul(remainder, 100) > multiplied;
    }
}
 



 
 
 
contract ITradeHistory {

     
     
    mapping (bytes32 => uint) public filled;

     
    mapping (address => mapping (bytes32 => bool)) public cancelled;

     
    mapping (address => uint) public cutoffs;

     
    mapping (address => mapping (bytes20 => uint)) public tradingPairCutoffs;

     
    mapping (address => mapping (address => uint)) public cutoffsOwner;

     
    mapping (address => mapping (address => mapping (bytes20 => uint))) public tradingPairCutoffsOwner;


    function batchUpdateFilled(
        bytes32[] calldata filledInfo
        )
        external;

    function setCancelled(
        address broker,
        bytes32 orderHash
        )
        external;

    function setCutoffs(
        address broker,
        uint cutoff
        )
        external;

    function setTradingPairCutoffs(
        address broker,
        bytes20 tokenPair,
        uint cutoff
        )
        external;

    function setCutoffsOfOwner(
        address broker,
        address owner,
        uint cutoff
        )
        external;

    function setTradingPairCutoffsOfOwner(
        address broker,
        address owner,
        bytes20 tokenPair,
        uint cutoff
        )
        external;

    function batchGetFilledAndCheckCancelled(
        bytes32[] calldata orderInfo
        )
        external
        view
        returns (uint[] memory fills);


     
     
    function authorizeAddress(
        address addr
        )
        external;

     
     
    function deauthorizeAddress(
        address addr
        )
        external;

    function isAddressAuthorized(
        address addr
        )
        public
        view
        returns (bool);


    function suspend()
        external;

    function resume()
        external;

    function kill()
        external;
}
 



 
 
 
 
contract ITradeDelegate {

    function batchTransfer(
        bytes32[] calldata batch
        )
        external;


     
     
    function authorizeAddress(
        address addr
        )
        external;

     
     
    function deauthorizeAddress(
        address addr
        )
        external;

    function isAddressAuthorized(
        address addr
        )
        public
        view
        returns (bool);


    function suspend()
        external;

    function resume()
        external;

    function kill()
        external;
}
 



 
 
contract IOrderRegistry {

     
     
     
     
    function isOrderHashRegistered(
        address broker,
        bytes32 orderHash
        )
        external
        view
        returns (bool);

     
     
     
    function registerOrderHash(
        bytes32 orderHash
        )
        external;
}
 



 
 
 
contract IOrderBook {
     
    mapping(bytes32 => bool) public orderSubmitted;

     
     
     
    event OrderSubmitted(
        bytes32 orderHash,
        bytes   orderData
    );

     
     
     
     
     
     
    function submitOrder(
        bytes calldata orderData
        )
        external
        returns (bytes32);
}
 



 
 
contract IFeeHolder {

    event TokenWithdrawn(
        address owner,
        address token,
        uint value
    );

     
    mapping(address => mapping(address => uint)) public feeBalances;

     
     
     
     
    function withdrawBurned(
        address token,
        uint value
        )
        external
        returns (bool success);

     
     
     
     
     
    function withdrawToken(
        address token,
        uint value
        )
        external
        returns (bool success);

    function batchAddFeeBalances(
        bytes32[] calldata batch
        )
        external;
}
 



 
 
contract IBurnRateTable {

    struct TokenData {
        uint    tier;
        uint    validUntil;
    }

    mapping(address => TokenData) public tokens;

    uint public constant YEAR_TO_SECONDS = 31556952;

     
    uint8 public constant TIER_4 = 0;
    uint8 public constant TIER_3 = 1;
    uint8 public constant TIER_2 = 2;
    uint8 public constant TIER_1 = 3;

    uint16 public constant BURN_BASE_PERCENTAGE           =                 100 * 10;  

     
    uint16 public constant TIER_UPGRADE_COST_PERCENTAGE   =                        1;  

     
     
    uint16 public constant BURN_MATCHING_TIER1            =                       25;  
    uint16 public constant BURN_MATCHING_TIER2            =                  15 * 10;  
    uint16 public constant BURN_MATCHING_TIER3            =                  30 * 10;  
    uint16 public constant BURN_MATCHING_TIER4            =                  50 * 10;  
     
    uint16 public constant BURN_P2P_TIER1                 =                       25;  
    uint16 public constant BURN_P2P_TIER2                 =                  15 * 10;  
    uint16 public constant BURN_P2P_TIER3                 =                  30 * 10;  
    uint16 public constant BURN_P2P_TIER4                 =                  50 * 10;  

    event TokenTierUpgraded(
        address indexed addr,
        uint            tier
    );

     
     
     
     
     
    function getBurnRate(
        address token
        )
        external
        view
        returns (uint32 burnRate);

     
     
     
    function getTokenTier(
        address token
        )
        public
        view
        returns (uint);

     
     
     
     
    function upgradeTokenTier(
        address token
        )
        external
        returns (bool);

}
 



 
 
 
 
 
contract IBrokerRegistry {
    event BrokerRegistered(
        address owner,
        address broker,
        address interceptor
    );

    event BrokerUnregistered(
        address owner,
        address broker,
        address interceptor
    );

    event AllBrokersUnregistered(
        address owner
    );

     
     
     
     
     
     
    function getBroker(
        address owner,
        address broker
        )
        external
        view
        returns(
            bool registered,
            address interceptor
        );

     
     
     
     
     
    function getBrokers(
        address owner,
        uint    start,
        uint    count
        )
        external
        view
        returns (
            address[] memory brokers,
            address[] memory interceptors
        );

     
     
     
     
    function registerBroker(
        address broker,
        address interceptor
        )
        external;

     
     
    function unregisterBroker(
        address broker
        )
        external;

     
    function unregisterAllBrokers(
        )
        external;
}
 





 
 
 
 
 
 
library MultihashUtil {

    enum HashAlgorithm { Ethereum, EIP712 }

    string public constant SIG_PREFIX = "\x19Ethereum Signed Message:\n32";

    function verifySignature(
        address signer,
        bytes32 plaintext,
        bytes memory multihash
        )
        internal
        pure
        returns (bool)
    {
        uint length = multihash.length;
        require(length >= 2, "invalid multihash format");
        uint8 algorithm;
        uint8 size;
        assembly {
            algorithm := mload(add(multihash, 1))
            size := mload(add(multihash, 2))
        }
        require(length == (2 + size), "bad multihash size");

        if (algorithm == uint8(HashAlgorithm.Ethereum)) {
            require(signer != address(0x0), "invalid signer address");
            require(size == 65, "bad Ethereum multihash size");
            bytes32 hash;
            uint8 v;
            bytes32 r;
            bytes32 s;
            assembly {
                let data := mload(0x40)
                mstore(data, 0x19457468657265756d205369676e6564204d6573736167653a0a333200000000)  
                mstore(add(data, 28), plaintext)                                                  
                hash := keccak256(data, 60)                                                       
                 
                v := mload(add(multihash, 3))
                r := mload(add(multihash, 35))
                s := mload(add(multihash, 67))
            }
            return signer == ecrecover(
                hash,
                v,
                r,
                s
            );
        } else if (algorithm == uint8(HashAlgorithm.EIP712)) {
            require(signer != address(0x0), "invalid signer address");
            require(size == 65, "bad EIP712 multihash size");
            uint8 v;
            bytes32 r;
            bytes32 s;
            assembly {
                 
                v := mload(add(multihash, 3))
                r := mload(add(multihash, 35))
                s := mload(add(multihash, 67))
            }
            return signer == ecrecover(
                plaintext,
                v,
                r,
                s
            );
        } else {
            return false;
        }
    }
}

 



 
 
 
contract ERC20 {
    function totalSupply()
        public
        view
        returns (uint256);

    function balanceOf(
        address who
        )
        public
        view
        returns (uint256);

    function allowance(
        address owner,
        address spender
        )
        public
        view
        returns (uint256);

    function transfer(
        address to,
        uint256 value
        )
        public
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
        )
        public
        returns (bool);

    function approve(
        address spender,
        uint256 value
        )
        public
        returns (bool);

    function verifyTransfer(
        address from,
        address to,
        uint256 amount,
        bytes memory data
        )
        public
        returns (bool);
}
 











library Data {

    enum TokenType { ERC20 }

    struct Header {
        uint version;
        uint numOrders;
        uint numRings;
        uint numSpendables;
    }

    struct Context {
        address lrcTokenAddress;
        ITradeDelegate  delegate;
        ITradeHistory   tradeHistory;
        IBrokerRegistry orderBrokerRegistry;
        IOrderRegistry  orderRegistry;
        IFeeHolder feeHolder;
        IOrderBook orderBook;
        IBurnRateTable burnRateTable;
        uint64 ringIndex;
        uint feePercentageBase;
        bytes32[] tokenBurnRates;
        uint feeData;
        uint feePtr;
        uint transferData;
        uint transferPtr;
    }

    struct Mining {
         
        address feeRecipient;

         
        address miner;
        bytes   sig;

         
        bytes32 hash;
        address interceptor;
    }

    struct Spendable {
        bool initialized;
        uint amount;
        uint reserved;
    }

    struct Order {
        uint      version;

         
        address   owner;
        address   tokenS;
        address   tokenB;
        uint      amountS;
        uint      amountB;
        uint      validSince;
        Spendable tokenSpendableS;
        Spendable tokenSpendableFee;

         
        address   dualAuthAddr;
        address   broker;
        Spendable brokerSpendableS;
        Spendable brokerSpendableFee;
        address   orderInterceptor;
        address   wallet;
        uint      validUntil;
        bytes     sig;
        bytes     dualAuthSig;
        bool      allOrNone;
        address   feeToken;
        uint      feeAmount;
        int16     waiveFeePercentage;
        uint16    tokenSFeePercentage;     
        uint16    tokenBFeePercentage;    
        address   tokenRecipient;
        uint16    walletSplitPercentage;

         
        bool    P2P;
        bytes32 hash;
        address brokerInterceptor;
        uint    filledAmountS;
        uint    initialFilledAmountS;
        bool    valid;

        TokenType tokenTypeS;
        TokenType tokenTypeB;
        TokenType tokenTypeFee;
        bytes32 trancheS;
        bytes32 trancheB;
        bytes   transferDataS;
    }

    struct Participation {
         
        Order order;

         
        uint splitS;
        uint feeAmount;
        uint feeAmountS;
        uint feeAmountB;
        uint rebateFee;
        uint rebateS;
        uint rebateB;
        uint fillAmountS;
        uint fillAmountB;
    }

    struct Ring{
        uint size;
        Participation[] participations;
        bytes32 hash;
        uint minerFeesToOrdersPercentage;
        bool valid;
    }

    struct FeeContext {
        Data.Ring ring;
        Data.Context ctx;
        address feeRecipient;
        uint walletPercentage;
        int16 waiveFeePercentage;
        address owner;
        address wallet;
        bool P2P;
    }
}
 



 
 
 
contract IRingSubmitter {
    uint16  public constant FEE_PERCENTAGE_BASE = 1000;

     
     
     
     
     
     
    event RingMined(
        uint            _ringIndex,
        bytes32 indexed _ringHash,
        address indexed _feeRecipient,
        bytes           _fills
    );

     
     
    event InvalidRing(
        bytes32 _ringHash
    );

     
     
    function submitRings(
        bytes calldata data
        )
        external;
}
 


 






 
 
library MiningHelper {

    function updateMinerAndInterceptor(
        Data.Mining memory mining
        )
        internal
        pure
    {

        if (mining.miner == address(0x0)) {
            mining.miner = mining.feeRecipient;
        }

         
         
         
         
         
         
         
         
         
         
    }

    function updateHash(
        Data.Mining memory mining,
        Data.Ring[] memory rings
        )
        internal
        pure
    {
        bytes32 hash;
        assembly {
            let ring := mload(add(rings, 32))                                
            let ringHashes := mload(add(ring, 64))                           
            for { let i := 1 } lt(i, mload(rings)) { i := add(i, 1) } {
                ring := mload(add(rings, mul(add(i, 1), 32)))                
                ringHashes := xor(ringHashes, mload(add(ring, 64)))          
            }
            let data := mload(0x40)
            data := add(data, 12)
             
            mstore(add(data, 40), ringHashes)                                
            mstore(sub(add(data, 20), 12), mload(add(mining, 32)))           
            mstore(sub(data, 12),          mload(add(mining,  0)))           
            hash := keccak256(data, 72)                                      
        }
        mining.hash = hash;
    }

    function checkMinerSignature(
        Data.Mining memory mining
        )
        internal
        view
        returns (bool)
    {
        if (mining.sig.length == 0) {
            return (msg.sender == mining.miner);
        } else {
            return MultihashUtil.verifySignature(
                mining.miner,
                mining.hash,
                mining.sig
            );
        }
    }

}

 








 
 
library OrderHelper {
    using MathUint      for uint;

    string constant internal EIP191_HEADER = "\x19\x01";
    string constant internal EIP712_DOMAIN_NAME = "Loopring Protocol";
    string constant internal EIP712_DOMAIN_VERSION = "2";
    bytes32 constant internal EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = keccak256(
        abi.encodePacked(
            "EIP712Domain(",
            "string name,",
            "string version",
            ")"
        )
    );
    bytes32 constant internal EIP712_ORDER_SCHEMA_HASH = keccak256(
        abi.encodePacked(
            "Order(",
            "uint amountS,",
            "uint amountB,",
            "uint feeAmount,",
            "uint validSince,",
            "uint validUntil,",
            "address owner,",
            "address tokenS,",
            "address tokenB,",
            "address dualAuthAddr,",
            "address broker,",
            "address orderInterceptor,",
            "address wallet,",
            "address tokenRecipient,",
            "address feeToken,",
            "uint16 walletSplitPercentage,",
            "uint16 tokenSFeePercentage,",
            "uint16 tokenBFeePercentage,",
            "bool allOrNone,",
            "uint8 tokenTypeS,",
            "uint8 tokenTypeB,",
            "uint8 tokenTypeFee,",
            "bytes32 trancheS,",
            "bytes32 trancheB,",
            "bytes transferDataS",
            ")"
        )
    );
    bytes32 constant internal EIP712_DOMAIN_HASH = keccak256(
        abi.encodePacked(
            EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
            keccak256(bytes(EIP712_DOMAIN_NAME)),
            keccak256(bytes(EIP712_DOMAIN_VERSION))
        )
    );

    function updateHash(Data.Order memory order)
        internal
        pure
    {
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         

         
         
        bytes32 _EIP712_ORDER_SCHEMA_HASH = 0x40b942178d2a51f1f61934268590778feb8114db632db7d88537c98d2b05c5f2;
        bytes32 _EIP712_DOMAIN_HASH = 0xaea25658c273c666156bd427f83a666135fcde6887a6c25fc1cd1562bc4f3f34;

        bytes32 hash;
        assembly {
             
            let transferDataS := mload(add(order, 1184))               
            let transferDataSHash := keccak256(add(transferDataS, 32), mload(transferDataS))

            let ptr := mload(64)
            mstore(add(ptr,   0), _EIP712_ORDER_SCHEMA_HASH)      
            mstore(add(ptr,  32), mload(add(order, 128)))         
            mstore(add(ptr,  64), mload(add(order, 160)))         
            mstore(add(ptr,  96), mload(add(order, 640)))         
            mstore(add(ptr, 128), mload(add(order, 192)))         
            mstore(add(ptr, 160), mload(add(order, 480)))         
            mstore(add(ptr, 192), mload(add(order,  32)))         
            mstore(add(ptr, 224), mload(add(order,  64)))         
            mstore(add(ptr, 256), mload(add(order,  96)))         
            mstore(add(ptr, 288), mload(add(order, 288)))         
            mstore(add(ptr, 320), mload(add(order, 320)))         
            mstore(add(ptr, 352), mload(add(order, 416)))         
            mstore(add(ptr, 384), mload(add(order, 448)))         
            mstore(add(ptr, 416), mload(add(order, 768)))         
            mstore(add(ptr, 448), mload(add(order, 608)))         
            mstore(add(ptr, 480), mload(add(order, 800)))         
            mstore(add(ptr, 512), mload(add(order, 704)))         
            mstore(add(ptr, 544), mload(add(order, 736)))         
            mstore(add(ptr, 576), mload(add(order, 576)))         
            mstore(add(ptr, 608), mload(add(order, 1024)))        
            mstore(add(ptr, 640), mload(add(order, 1056)))        
            mstore(add(ptr, 672), mload(add(order, 1088)))        
            mstore(add(ptr, 704), mload(add(order, 1120)))        
            mstore(add(ptr, 736), mload(add(order, 1152)))        
            mstore(add(ptr, 768), transferDataSHash)              
            let message := keccak256(ptr, 800)                    

            mstore(add(ptr,  0), 0x1901)                          
            mstore(add(ptr, 32), _EIP712_DOMAIN_HASH)             
            mstore(add(ptr, 64), message)                         
            hash := keccak256(add(ptr, 30), 66)                   
        }
        order.hash = hash;
    }

    function updateBrokerAndInterceptor(
        Data.Order memory order,
        Data.Context memory ctx
        )
        internal
        view
    {
        if (order.broker == address(0x0)) {
            order.broker = order.owner;
        } else {
            bool registered;
            (registered,  ) = ctx.orderBrokerRegistry.getBroker(
                order.owner,
                order.broker
            );
            order.valid = order.valid && registered;
        }
    }

    function check(
        Data.Order memory order,
        Data.Context memory ctx
        )
        internal
        view
    {
         
         
        if(order.filledAmountS == 0) {
            validateAllInfo(order, ctx);
            checkBrokerSignature(order, ctx);
        } else {
            validateUnstableInfo(order, ctx);
        }

        checkP2P(order);
    }

    function validateAllInfo(
        Data.Order memory order,
        Data.Context memory ctx
        )
        internal
        view
    {
        bool valid = true;
        valid = valid && (order.version == 0);  
        valid = valid && (order.owner != address(0x0));  
        valid = valid && (order.tokenS != address(0x0));  
        valid = valid && (order.tokenB != address(0x0));  
        valid = valid && (order.amountS != 0);  
        valid = valid && (order.amountB != 0);  
        valid = valid && (order.feeToken != address(0x0));  

        valid = valid && (order.tokenSFeePercentage < ctx.feePercentageBase);  
        valid = valid && (order.tokenBFeePercentage < ctx.feePercentageBase);  
        valid = valid && (order.walletSplitPercentage <= 100);  

         
        valid = valid && (order.tokenTypeS == Data.TokenType.ERC20 && order.trancheS == 0x0);
        valid = valid && (order.tokenTypeB == Data.TokenType.ERC20 && order.trancheB == 0x0);
        valid = valid && (order.tokenTypeFee == Data.TokenType.ERC20);
        valid = valid && (order.transferDataS.length == 0);

        valid = valid && (order.validSince <= now);  

        order.valid = order.valid && valid;

        validateUnstableInfo(order, ctx);
    }


    function validateUnstableInfo(
        Data.Order memory order,
        Data.Context memory ctx
        )
        internal
        view
    {
        bool valid = true;
        valid = valid && (order.validUntil == 0 || order.validUntil > now);   
        valid = valid && (order.waiveFeePercentage <= int16(ctx.feePercentageBase));  
        valid = valid && (order.waiveFeePercentage >= -int16(ctx.feePercentageBase));  
        if (order.dualAuthAddr != address(0x0)) {  
            valid = valid && (order.dualAuthSig.length > 0);
        }
        order.valid = order.valid && valid;
    }


    function checkP2P(
        Data.Order memory order
        )
        internal
        pure
    {
        order.P2P = (order.tokenSFeePercentage > 0 || order.tokenBFeePercentage > 0);
    }


    function checkBrokerSignature(
        Data.Order memory order,
        Data.Context memory ctx
        )
        internal
        view
    {
        if (order.sig.length == 0) {
            bool registered = ctx.orderRegistry.isOrderHashRegistered(
                order.broker,
                order.hash
            );

            if (!registered) {
                order.valid = order.valid && ctx.orderBook.orderSubmitted(order.hash);
            }
        } else {
            order.valid = order.valid && MultihashUtil.verifySignature(
                order.broker,
                order.hash,
                order.sig
            );
        }
    }

    function checkDualAuthSignature(
        Data.Order memory order,
        bytes32 miningHash
        )
        internal
        pure
    {
        if (order.dualAuthSig.length != 0) {
            order.valid = order.valid && MultihashUtil.verifySignature(
                order.dualAuthAddr,
                miningHash,
                order.dualAuthSig
            );
        }
    }

    function validateAllOrNone(
        Data.Order memory order
        )
        internal
        pure
    {
         
        if(order.allOrNone) {
            order.valid = order.valid && (order.filledAmountS == order.amountS);
        }
    }

    function getSpendableS(
        Data.Order memory order,
        Data.Context memory ctx
        )
        internal
        view
        returns (uint)
    {
        return getSpendable(
            ctx.delegate,
            order.tokenS,
            order.owner,
            order.tokenSpendableS
        );
    }

    function getSpendableFee(
        Data.Order memory order,
        Data.Context memory ctx
        )
        internal
        view
        returns (uint)
    {
        return getSpendable(
            ctx.delegate,
            order.feeToken,
            order.owner,
            order.tokenSpendableFee
        );
    }

    function reserveAmountS(
        Data.Order memory order,
        uint amount
        )
        internal
        pure
    {
        order.tokenSpendableS.reserved += amount;
    }

    function reserveAmountFee(
        Data.Order memory order,
        uint amount
        )
        internal
        pure
    {
        order.tokenSpendableFee.reserved += amount;
    }

    function resetReservations(
        Data.Order memory order
        )
        internal
        pure
    {
        order.tokenSpendableS.reserved = 0;
        order.tokenSpendableFee.reserved = 0;
    }

     
    function getERC20Spendable(
        ITradeDelegate delegate,
        address tokenAddress,
        address owner
        )
        private
        view
        returns (uint spendable)
    {
        ERC20 token = ERC20(tokenAddress);
        spendable = token.allowance(
            owner,
            address(delegate)
        );
        if (spendable != 0) {
            uint balance = token.balanceOf(owner);
            spendable = (balance < spendable) ? balance : spendable;
        }
    }

    function getSpendable(
        ITradeDelegate delegate,
        address tokenAddress,
        address owner,
        Data.Spendable memory tokenSpendable
        )
        private
        view
        returns (uint spendable)
    {
        if (!tokenSpendable.initialized) {
            tokenSpendable.amount = getERC20Spendable(
                delegate,
                tokenAddress,
                owner
            );
            tokenSpendable.initialized = true;
        }
        spendable = tokenSpendable.amount.sub(tokenSpendable.reserved);
    }
}

 








 







 
 
library ParticipationHelper {
    using MathUint for uint;
    using OrderHelper for Data.Order;

    function setMaxFillAmounts(
        Data.Participation memory p,
        Data.Context memory ctx
        )
        internal
        view
    {
        uint spendableS = p.order.getSpendableS(ctx);
        uint remainingS = p.order.amountS.sub(p.order.filledAmountS);
        p.fillAmountS = (spendableS < remainingS) ? spendableS : remainingS;

        if (!p.order.P2P) {
             
             
            if (!(p.order.feeToken == p.order.tokenB &&
                  p.order.owner == p.order.tokenRecipient &&
                  p.order.feeAmount <= p.order.amountB)) {
                 
                 
                uint feeAmount = p.order.feeAmount.mul(p.fillAmountS) / p.order.amountS;
                if (feeAmount > 0) {
                    uint spendableFee = p.order.getSpendableFee(ctx);
                    if (p.order.feeToken == p.order.tokenS && p.fillAmountS + feeAmount > spendableS) {
                        assert(spendableFee == spendableS);
                         
                        uint totalAmount = p.order.amountS.add(p.order.feeAmount);
                        p.fillAmountS = spendableS.mul(p.order.amountS) / totalAmount;
                        feeAmount = spendableS.mul(p.order.feeAmount) / totalAmount;
                    } else if (feeAmount > spendableFee) {
                         
                        feeAmount = spendableFee;
                        p.fillAmountS = feeAmount.mul(p.order.amountS) / p.order.feeAmount;
                    }
                }
            }
        }

        p.fillAmountB = p.fillAmountS.mul(p.order.amountB) / p.order.amountS;
    }

    function calculateFees(
        Data.Participation memory p,
        Data.Participation memory prevP,
        Data.Context memory ctx
        )
        internal
        view
        returns (bool)
    {
        if (p.order.P2P) {
             
            p.feeAmount = 0;
            p.feeAmountS = p.fillAmountS.mul(p.order.tokenSFeePercentage) / ctx.feePercentageBase;
            p.feeAmountB = p.fillAmountB.mul(p.order.tokenBFeePercentage) / ctx.feePercentageBase;
        } else {
             
            p.feeAmount = p.order.feeAmount.mul(p.fillAmountS) / p.order.amountS;
            p.feeAmountS = 0;
            p.feeAmountB = 0;

             

            if (p.order.feeToken == p.order.tokenB &&
                p.order.owner == p.order.tokenRecipient &&
                p.fillAmountB >= p.feeAmount) {
                p.feeAmountB = p.feeAmount;
                p.feeAmount = 0;
            }

            if (p.feeAmount > 0) {
                 
                uint spendableFee = p.order.getSpendableFee(ctx);
                if (p.feeAmount > spendableFee) {
                     
                    return false;
                } else {
                    p.order.reserveAmountFee(p.feeAmount);
                }
            }
        }

        if ((p.fillAmountS - p.feeAmountS) >= prevP.fillAmountB) {
             
            p.splitS = (p.fillAmountS - p.feeAmountS) - prevP.fillAmountB;
            p.fillAmountS = prevP.fillAmountB + p.feeAmountS;
            return true;
        } else {
            return false;
        }
    }

    function checkFills(
        Data.Participation memory p
        )
        internal
        pure
        returns (bool valid)
    {
         
         
         
        valid = !MathUint.hasRoundingError(
            p.fillAmountS,
            p.order.amountB,
            p.order.amountS
        );

         
        valid = valid && p.fillAmountS > 0;
        valid = valid && p.fillAmountB > 0;
    }

    function adjustOrderState(
        Data.Participation memory p
        )
        internal
        pure
    {
         
        p.order.filledAmountS += p.fillAmountS + p.splitS;

         
        uint totalAmountS = p.fillAmountS + p.splitS;
        uint totalAmountFee = p.feeAmount;
        p.order.tokenSpendableS.amount = p.order.tokenSpendableS.amount.sub(totalAmountS);
        p.order.tokenSpendableFee.amount = p.order.tokenSpendableFee.amount.sub(totalAmountFee);
        if (p.order.brokerInterceptor != address(0x0)) {
            p.order.brokerSpendableS.amount = p.order.brokerSpendableS.amount.sub(totalAmountS);
            p.order.brokerSpendableFee.amount = p.order.brokerSpendableFee.amount.sub(totalAmountFee);
        }
    }

    function revertOrderState(
        Data.Participation memory p
        )
        internal
        pure
    {
         
        p.order.filledAmountS = p.order.filledAmountS.sub(p.fillAmountS + p.splitS);

         
    }

}



 
library RingHelper {
    using MathUint for uint;
    using OrderHelper for Data.Order;
    using ParticipationHelper for Data.Participation;

    function updateHash(
        Data.Ring memory ring
        )
        internal
        pure
    {
        uint ringSize = ring.size;
        bytes32 hash;
        assembly {
            let data := mload(0x40)
            let ptr := data
            let participations := mload(add(ring, 32))                                   
            for { let i := 0 } lt(i, ringSize) { i := add(i, 1) } {
                let participation := mload(add(participations, add(32, mul(i, 32))))     
                let order := mload(participation)                                        

                let waiveFeePercentage := and(mload(add(order, 672)), 0xFFFF)            
                let orderHash := mload(add(order, 864))                                  

                mstore(add(ptr, 2), waiveFeePercentage)
                mstore(ptr, orderHash)

                ptr := add(ptr, 34)
            }
            hash := keccak256(data, sub(ptr, data))
        }
        ring.hash = hash;
    }

    function calculateFillAmountAndFee(
        Data.Ring memory ring,
        Data.Context memory ctx
        )
        internal
    {
         
        if (!ring.valid) {
            return;
        }

        uint i;
        int j;
        uint prevIndex;

        for (i = 0; i < ring.size; i++) {
            ring.participations[i].setMaxFillAmounts(
                ctx
            );
        }

        uint smallest = 0;
        for (j = int(ring.size) - 1; j >= 0; j--) {
            prevIndex = (uint(j) + ring.size - 1) % ring.size;
            smallest = calculateOrderFillAmounts(
                ctx,
                ring.participations[uint(j)],
                ring.participations[prevIndex],
                uint(j),
                smallest
            );
        }
        for (j = int(ring.size) - 1; j >= int(smallest); j--) {
            prevIndex = (uint(j) + ring.size - 1) % ring.size;
            calculateOrderFillAmounts(
                ctx,
                ring.participations[uint(j)],
                ring.participations[prevIndex],
                uint(j),
                smallest
            );
        }

        for (i = 0; i < ring.size; i++) {
             
            ring.valid = ring.valid && ring.participations[i].checkFills();

             
             
             
            ring.participations[i].order.reserveAmountS(ring.participations[i].fillAmountS);
        }

        for (i = 0; i < ring.size; i++) {
            prevIndex = (i + ring.size - 1) % ring.size;

             
            ring.valid = ring.valid && verifyTransferProxy(
                ring.participations[i].order.tokenS,
                ring.participations[i].order.owner,
                ring.participations[prevIndex].order.tokenRecipient,
                ring.participations[i].fillAmountS
            );

            bool valid = ring.participations[i].calculateFees(ring.participations[prevIndex], ctx);
            if (!valid) {
                ring.valid = false;
                break;
            }

            int16 waiveFeePercentage = ring.participations[i].order.waiveFeePercentage;
            if (waiveFeePercentage < 0) {
                ring.minerFeesToOrdersPercentage += uint(-waiveFeePercentage);
            }
        }
         
        ring.valid = ring.valid && (ring.minerFeesToOrdersPercentage <= ctx.feePercentageBase);

         
        for (i = 0; i < ring.size; i++) {
            ring.participations[i].order.resetReservations();
        }
    }

     
    function verifyTransferProxy(
        address token,
        address from,
        address to,
        uint256 amount
        )
        internal
        returns (bool)
    {
        bytes memory callData = abi.encodeWithSelector(
            ERC20(token).verifyTransfer.selector,
            from,
            to,
            amount,
            new bytes(0)
        );
        (bool success, bytes memory returnData) = token.call(callData);
         
        if (success && returnData.length == 32) {
             
            assembly {
                success := mload(add(returnData, 32))
            }
            return success;
        } else {
             
            return true;
        }
    }

    function calculateOrderFillAmounts(
        Data.Context memory ctx,
        Data.Participation memory p,
        Data.Participation memory prevP,
        uint i,
        uint smallest
        )
        internal
        pure
        returns (uint smallest_)
    {
         
        smallest_ = smallest;

        uint postFeeFillAmountS = p.fillAmountS;
        uint tokenSFeePercentage = p.order.tokenSFeePercentage;
        if (tokenSFeePercentage > 0) {
            uint feeAmountS = p.fillAmountS.mul(tokenSFeePercentage) / ctx.feePercentageBase;
            postFeeFillAmountS = p.fillAmountS - feeAmountS;
        }

        if (prevP.fillAmountB > postFeeFillAmountS) {
            smallest_ = i;
            prevP.fillAmountB = postFeeFillAmountS;
            prevP.fillAmountS = postFeeFillAmountS.mul(prevP.order.amountS) / prevP.order.amountB;
        }
    }

    function checkOrdersValid(
        Data.Ring memory ring
        )
        internal
        pure
    {
        ring.valid = ring.valid && (ring.size > 1 && ring.size <= 8);  
        for (uint i = 0; i < ring.size; i++) {
            uint prev = (i + ring.size - 1) % ring.size;
            ring.valid = ring.valid && ring.participations[i].order.valid;
            ring.valid = ring.valid && ring.participations[i].order.tokenS == ring.participations[prev].order.tokenB;
        }
    }

    function checkForSubRings(
        Data.Ring memory ring
        )
        internal
        pure
    {
        for (uint i = 0; i < ring.size - 1; i++) {
            address tokenS = ring.participations[i].order.tokenS;
            for (uint j = i + 1; j < ring.size; j++) {
                ring.valid = ring.valid && (tokenS != ring.participations[j].order.tokenS);
            }
        }
    }

    function adjustOrderStates(
        Data.Ring memory ring
        )
        internal
        pure
    {
         
        for (uint i = 0; i < ring.size; i++) {
            ring.participations[i].adjustOrderState();
        }
    }


    function revertOrderStats(
        Data.Ring memory ring
        )
        internal
        pure
    {
        for (uint i = 0; i < ring.size; i++) {
            ring.participations[i].revertOrderState();
        }
    }

    function doPayments(
        Data.Ring memory ring,
        Data.Context memory ctx,
        Data.Mining memory mining
        )
        internal
        view
    {
        payFees(ring, ctx, mining);
        transferTokens(ring, ctx, mining.feeRecipient);
    }

    function generateFills(
        Data.Ring memory ring,
        uint destPtr
        )
        internal
        pure
        returns (uint fill)
    {
        uint ringSize = ring.size;
        uint fillSize = 8 * 32;
        assembly {
            fill := destPtr
            let participations := mload(add(ring, 32))                                  

            for { let i := 0 } lt(i, ringSize) { i := add(i, 1) } {
                let participation := mload(add(participations, add(32, mul(i, 32))))    
                let order := mload(participation)                                       

                 
                let feeAmount := sub(
                    mload(add(participation, 64)),                                       
                    mload(add(participation, 160))                                       
                )
                let feeAmountS := sub(
                    mload(add(participation, 96)),                                       
                    mload(add(participation, 192))                                       
                )
                let feeAmountB := sub(
                    mload(add(participation, 128)),                                      
                    mload(add(participation, 224))                                       
                )

                mstore(add(fill,   0), mload(add(order, 864)))                          
                mstore(add(fill,  32), mload(add(order,  32)))                          
                mstore(add(fill,  64), mload(add(order,  64)))                          
                mstore(add(fill,  96), mload(add(participation, 256)))                  
                mstore(add(fill, 128), mload(add(participation,  32)))                  
                mstore(add(fill, 160), feeAmount)                                       
                mstore(add(fill, 192), feeAmountS)                                      
                mstore(add(fill, 224), feeAmountB)                                      

                fill := add(fill, fillSize)
            }
        }
    }

    function transferTokens(
        Data.Ring memory ring,
        Data.Context memory ctx,
        address feeRecipient
        )
        internal
        pure
    {
        for (uint i = 0; i < ring.size; i++) {
            transferTokensForParticipation(
                ctx,
                feeRecipient,
                ring.participations[i],
                ring.participations[(i + ring.size - 1) % ring.size]
            );
        }
    }

    function transferTokensForParticipation(
        Data.Context memory ctx,
        address feeRecipient,
        Data.Participation memory p,
        Data.Participation memory prevP
        )
        internal
        pure
        returns (uint)
    {
        uint buyerFeeAmountAfterRebateB = prevP.feeAmountB.sub(prevP.rebateB);

         
         
        uint amountSToBuyer = p.fillAmountS
            .sub(p.feeAmountS)
            .sub(buyerFeeAmountAfterRebateB);

        uint amountSToFeeHolder = p.feeAmountS
            .sub(p.rebateS)
            .add(buyerFeeAmountAfterRebateB);

        uint amountFeeToFeeHolder = p.feeAmount
            .sub(p.rebateFee);

        if (p.order.tokenS == p.order.feeToken) {
            amountSToFeeHolder = amountSToFeeHolder.add(amountFeeToFeeHolder);
            amountFeeToFeeHolder = 0;
        }

         
        ctx.transferPtr = addTokenTransfer(
            ctx.transferData,
            ctx.transferPtr,
            p.order.feeToken,
            p.order.owner,
            address(ctx.feeHolder),
            amountFeeToFeeHolder
        );
        ctx.transferPtr = addTokenTransfer(
            ctx.transferData,
            ctx.transferPtr,
            p.order.tokenS,
            p.order.owner,
            address(ctx.feeHolder),
            amountSToFeeHolder
        );
        ctx.transferPtr = addTokenTransfer(
            ctx.transferData,
            ctx.transferPtr,
            p.order.tokenS,
            p.order.owner,
            prevP.order.tokenRecipient,
            amountSToBuyer
        );

         
        ctx.transferPtr = addTokenTransfer(
            ctx.transferData,
            ctx.transferPtr,
            p.order.tokenS,
            p.order.owner,
            feeRecipient,
            p.splitS
        );
    }

    function addTokenTransfer(
        uint data,
        uint ptr,
        address token,
        address from,
        address to,
        uint amount
        )
        internal
        pure
        returns (uint)
    {
        if (amount > 0 && from != to) {
            assembly {
                 
                let addNew := 1
                for { let p := data } lt(p, ptr) { p := add(p, 128) } {
                    let dataToken := mload(add(p,  0))
                    let dataFrom := mload(add(p, 32))
                    let dataTo := mload(add(p, 64))
                     
                    if and(and(eq(token, dataToken), eq(from, dataFrom)), eq(to, dataTo)) {
                        let dataAmount := mload(add(p, 96))
                         
                        dataAmount := add(amount, dataAmount)
                         
                        if lt(dataAmount, amount) {
                            revert(0, 0)
                        }
                        mstore(add(p, 96), dataAmount)
                        addNew := 0
                         
                        p := ptr
                    }
                }
                 
                if eq(addNew, 1) {
                    mstore(add(ptr,  0), token)
                    mstore(add(ptr, 32), from)
                    mstore(add(ptr, 64), to)
                    mstore(add(ptr, 96), amount)
                    ptr := add(ptr, 128)
                }
            }
            return ptr;
        } else {
            return ptr;
        }
    }

    function payFees(
        Data.Ring memory ring,
        Data.Context memory ctx,
        Data.Mining memory mining
        )
        internal
        view
    {
        Data.FeeContext memory feeCtx;
        feeCtx.ring = ring;
        feeCtx.ctx = ctx;
        feeCtx.feeRecipient = mining.feeRecipient;
        for (uint i = 0; i < ring.size; i++) {
            payFeesForParticipation(
                feeCtx,
                ring.participations[i]
            );
        }
    }

    function payFeesForParticipation(
        Data.FeeContext memory feeCtx,
        Data.Participation memory p
        )
        internal
        view
        returns (uint)
    {
        feeCtx.walletPercentage = p.order.P2P ? 100 : (
            (p.order.wallet == address(0x0) ? 0 : p.order.walletSplitPercentage)
        );
        feeCtx.waiveFeePercentage = p.order.waiveFeePercentage;
        feeCtx.owner = p.order.owner;
        feeCtx.wallet = p.order.wallet;
        feeCtx.P2P = p.order.P2P;

        p.rebateFee = payFeesAndBurn(
            feeCtx,
            p.order.feeToken,
            p.feeAmount
        );
        p.rebateS = payFeesAndBurn(
            feeCtx,
            p.order.tokenS,
            p.feeAmountS
        );
        p.rebateB = payFeesAndBurn(
            feeCtx,
            p.order.tokenB,
            p.feeAmountB
        );
    }

    function payFeesAndBurn(
        Data.FeeContext memory feeCtx,
        address token,
        uint totalAmount
        )
        internal
        view
        returns (uint)
    {
        if (totalAmount == 0) {
            return 0;
        }

        uint amount = totalAmount;
         
         
        if (feeCtx.P2P && feeCtx.wallet == address(0x0)) {
            amount = 0;
        }

        uint feeToWallet = 0;
        uint minerFee = 0;
        uint minerFeeBurn = 0;
        uint walletFeeBurn = 0;
        if (amount > 0) {
            feeToWallet = amount.mul(feeCtx.walletPercentage) / 100;
            minerFee = amount - feeToWallet;

             
            if (feeCtx.waiveFeePercentage > 0) {
                minerFee = minerFee.mul(
                    feeCtx.ctx.feePercentageBase - uint(feeCtx.waiveFeePercentage)) /
                    feeCtx.ctx.feePercentageBase;
            } else if (feeCtx.waiveFeePercentage < 0) {
                 
                minerFee = 0;
            }

            uint32 burnRate = getBurnRate(feeCtx, token);
            assert(burnRate <= feeCtx.ctx.feePercentageBase);

             
            minerFeeBurn = minerFee.mul(burnRate) / feeCtx.ctx.feePercentageBase;
            minerFee = minerFee - minerFeeBurn;
             
            walletFeeBurn = feeToWallet.mul(burnRate) / feeCtx.ctx.feePercentageBase;
            feeToWallet = feeToWallet - walletFeeBurn;

             
            feeCtx.ctx.feePtr = addFeePayment(
                feeCtx.ctx.feeData,
                feeCtx.ctx.feePtr,
                token,
                feeCtx.wallet,
                feeToWallet
            );

             
            feeCtx.ctx.feePtr = addFeePayment(
                feeCtx.ctx.feeData,
                feeCtx.ctx.feePtr,
                token,
                address(feeCtx.ctx.feeHolder),
                minerFeeBurn + walletFeeBurn
            );

             
             
             
            uint feeToMiner = minerFee;
            if (feeCtx.ring.minerFeesToOrdersPercentage > 0 && minerFee > 0) {
                 
                distributeMinerFeeToOwners(
                    feeCtx,
                    token,
                    minerFee
                );
                 
                feeToMiner = minerFee.mul(feeCtx.ctx.feePercentageBase -
                    feeCtx.ring.minerFeesToOrdersPercentage) /
                    feeCtx.ctx.feePercentageBase;
            }

             
            feeCtx.ctx.feePtr = addFeePayment(
                feeCtx.ctx.feeData,
                feeCtx.ctx.feePtr,
                token,
                feeCtx.feeRecipient,
                feeToMiner
            );
        }

         
         
        return totalAmount.sub((feeToWallet + minerFee) + (minerFeeBurn + walletFeeBurn));
    }

    function getBurnRate(
        Data.FeeContext memory feeCtx,
        address token
        )
        internal
        view
        returns (uint32)
    {
        bytes32[] memory tokenBurnRates = feeCtx.ctx.tokenBurnRates;
        uint length = tokenBurnRates.length;
        for (uint i = 0; i < length; i += 2) {
            if (token == address(bytes20(tokenBurnRates[i]))) {
                uint32 burnRate = uint32(bytes4(tokenBurnRates[i + 1]));
                return feeCtx.P2P ? (burnRate / 0x10000) : (burnRate & 0xFFFF);
            }
        }
         
        uint32 burnRate = feeCtx.ctx.burnRateTable.getBurnRate(token);
        assembly {
            let ptr := add(tokenBurnRates, mul(add(1, length), 32))
            mstore(ptr, token)                               
            mstore(add(ptr, 32), burnRate)                   
            mstore(tokenBurnRates, add(length, 2))           
        }
        return feeCtx.P2P ? (burnRate / 0x10000) : (burnRate & 0xFFFF);
    }

    function distributeMinerFeeToOwners(
        Data.FeeContext memory feeCtx,
        address token,
        uint minerFee
        )
        internal
        pure
    {
        for (uint i = 0; i < feeCtx.ring.size; i++) {
            if (feeCtx.ring.participations[i].order.waiveFeePercentage < 0) {
                uint feeToOwner = minerFee
                    .mul(uint(-feeCtx.ring.participations[i].order.waiveFeePercentage)) / feeCtx.ctx.feePercentageBase;

                feeCtx.ctx.feePtr = addFeePayment(
                    feeCtx.ctx.feeData,
                    feeCtx.ctx.feePtr,
                    token,
                    feeCtx.ring.participations[i].order.owner,
                    feeToOwner);
            }
        }
    }

    function addFeePayment(
        uint data,
        uint ptr,
        address token,
        address owner,
        uint amount
        )
        internal
        pure
        returns (uint)
    {
        if (amount == 0) {
            return ptr;
        } else {
            assembly {
                 
                let addNew := 1
                for { let p := data } lt(p, ptr) { p := add(p, 96) } {
                    let dataToken := mload(add(p,  0))
                    let dataOwner := mload(add(p, 32))
                     
                    if and(eq(token, dataToken), eq(owner, dataOwner)) {
                        let dataAmount := mload(add(p, 64))
                         
                        dataAmount := add(amount, dataAmount)
                         
                        if lt(dataAmount, amount) {
                            revert(0, 0)
                        }
                        mstore(add(p, 64), dataAmount)
                        addNew := 0
                         
                        p := ptr
                    }
                }
                 
                if eq(addNew, 1) {
                    mstore(add(ptr,  0), token)
                    mstore(add(ptr, 32), owner)
                    mstore(add(ptr, 64), amount)
                    ptr := add(ptr, 96)
                }
            }
            return ptr;
        }
    }

}













 


 



 
contract Errors {
    string constant ZERO_VALUE                 = "ZERO_VALUE";
    string constant ZERO_ADDRESS               = "ZERO_ADDRESS";
    string constant INVALID_VALUE              = "INVALID_VALUE";
    string constant INVALID_ADDRESS            = "INVALID_ADDRESS";
    string constant INVALID_SIZE               = "INVALID_SIZE";
    string constant INVALID_SIG                = "INVALID_SIG";
    string constant INVALID_STATE              = "INVALID_STATE";
    string constant NOT_FOUND                  = "NOT_FOUND";
    string constant ALREADY_EXIST              = "ALREADY_EXIST";
    string constant REENTRY                    = "REENTRY";
    string constant UNAUTHORIZED               = "UNAUTHORIZED";
    string constant UNIMPLEMENTED              = "UNIMPLEMENTED";
    string constant UNSUPPORTED                = "UNSUPPORTED";
    string constant TRANSFER_FAILURE           = "TRANSFER_FAILURE";
    string constant WITHDRAWAL_FAILURE         = "WITHDRAWAL_FAILURE";
    string constant BURN_FAILURE               = "BURN_FAILURE";
    string constant BURN_RATE_FROZEN           = "BURN_RATE_FROZEN";
    string constant BURN_RATE_MINIMIZED        = "BURN_RATE_MINIMIZED";
    string constant UNAUTHORIZED_ONCHAIN_ORDER = "UNAUTHORIZED_ONCHAIN_ORDER";
    string constant INVALID_CANDIDATE          = "INVALID_CANDIDATE";
    string constant ALREADY_VOTED              = "ALREADY_VOTED";
    string constant NOT_OWNER                  = "NOT_OWNER";
}



 
 
contract NoDefaultFunc is Errors {
    function ()
        external
        payable
    {
        revert(UNSUPPORTED);
    }
}



 






 
 
library ExchangeDeserializer {
    using BytesUtil     for bytes;

    function deserialize(
        address lrcTokenAddress,
        bytes memory data
        )
        internal
        view
        returns (
            Data.Mining memory mining,
            Data.Order[] memory orders,
            Data.Ring[] memory rings
        )
    {
         
        Data.Header memory header;
        header.version = data.bytesToUint16(0);
        header.numOrders = data.bytesToUint16(2);
        header.numRings = data.bytesToUint16(4);
        header.numSpendables = data.bytesToUint16(6);

         
        require(header.version == 0, "Unsupported serialization format");
        require(header.numOrders > 0, "Invalid number of orders");
        require(header.numRings > 0, "Invalid number of rings");
        require(header.numSpendables > 0, "Invalid number of spendables");

         
        uint dataPtr;
        assembly {
            dataPtr := data
        }
        uint miningDataPtr = dataPtr + 8;
        uint orderDataPtr = miningDataPtr + 3 * 2;
        uint ringDataPtr = orderDataPtr + (30 * header.numOrders) * 2;
        uint dataBlobPtr = ringDataPtr + (header.numRings * 9) + 32;

         
         
        require(data.length >= (dataBlobPtr - dataPtr) + 32, "Invalid input data");

         
        mining = setupMiningData(dataBlobPtr, miningDataPtr + 2);
        orders = setupOrders(dataBlobPtr, orderDataPtr + 2, header.numOrders, header.numSpendables, lrcTokenAddress);
        rings = assembleRings(ringDataPtr + 1, header.numRings, orders);
    }

    function setupMiningData(
        uint data,
        uint tablesPtr
        )
        internal
        view
        returns (Data.Mining memory mining)
    {
        bytes memory emptyBytes = new bytes(0);
        uint offset;

        assembly {
             
            mstore(add(data, 20), origin)

             
            offset := mul(and(mload(add(tablesPtr,  0)), 0xFFFF), 4)
            mstore(
                add(mining,   0),
                mload(add(add(data, 20), offset))
            )

             
            mstore(add(data, 20), 0)

             
            offset := mul(and(mload(add(tablesPtr,  2)), 0xFFFF), 4)
            mstore(
                add(mining,  32),
                mload(add(add(data, 20), offset))
            )

             
            mstore(add(data, 32), emptyBytes)

             
            offset := mul(and(mload(add(tablesPtr,  4)), 0xFFFF), 4)
            mstore(
                add(mining, 64),
                add(data, add(offset, 32))
            )

             
            mstore(add(data, 32), 0)
        }
    }

    function setupOrders(
        uint data,
        uint tablesPtr,
        uint numOrders,
        uint numSpendables,
        address lrcTokenAddress
        )
        internal
        pure
        returns (Data.Order[] memory orders)
    {
        bytes memory emptyBytes = new bytes(0);
        uint orderStructSize = 38 * 32;
         
        uint arrayDataSize = (1 + numOrders) * 32;
        Data.Spendable[] memory spendableList = new Data.Spendable[](numSpendables);
        uint offset;

        assembly {
             
            orders := mload(0x40)
            mstore(add(orders, 0), numOrders)                        
             
            mstore(0x40, add(orders, add(arrayDataSize, mul(orderStructSize, numOrders))))

            for { let i := 0 } lt(i, numOrders) { i := add(i, 1) } {
                let order := add(orders, add(arrayDataSize, mul(orderStructSize, i)))

                 
                mstore(add(orders, mul(add(1, i), 32)), order)

                 
                offset := and(mload(add(tablesPtr,  0)), 0xFFFF)
                mstore(
                    add(order,   0),
                    offset
                )

                 
                offset := mul(and(mload(add(tablesPtr,  2)), 0xFFFF), 4)
                mstore(
                    add(order,  32),
                    and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                )

                 
                offset := mul(and(mload(add(tablesPtr,  4)), 0xFFFF), 4)
                mstore(
                    add(order,  64),
                    and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                )

                 
                offset := mul(and(mload(add(tablesPtr,  6)), 0xFFFF), 4)
                mstore(
                    add(order,  96),
                    and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                )

                 
                offset := mul(and(mload(add(tablesPtr,  8)), 0xFFFF), 4)
                mstore(
                    add(order, 128),
                    mload(add(add(data, 32), offset))
                )

                 
                offset := mul(and(mload(add(tablesPtr, 10)), 0xFFFF), 4)
                mstore(
                    add(order, 160),
                    mload(add(add(data, 32), offset))
                )

                 
                offset := mul(and(mload(add(tablesPtr, 12)), 0xFFFF), 4)
                mstore(
                    add(order, 192),
                    and(mload(add(add(data, 4), offset)), 0xFFFFFFFF)
                )

                 
                offset := and(mload(add(tablesPtr, 14)), 0xFFFF)
                 
                offset := mul(offset, lt(offset, numSpendables))
                mstore(
                    add(order, 224),
                    mload(add(spendableList, mul(add(offset, 1), 32)))
                )

                 
                offset := and(mload(add(tablesPtr, 16)), 0xFFFF)
                 
                offset := mul(offset, lt(offset, numSpendables))
                mstore(
                    add(order, 256),
                    mload(add(spendableList, mul(add(offset, 1), 32)))
                )

                 
                offset := mul(and(mload(add(tablesPtr, 18)), 0xFFFF), 4)
                mstore(
                    add(order, 288),
                    and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                )

                 
                offset := mul(and(mload(add(tablesPtr, 20)), 0xFFFF), 4)
                mstore(
                    add(order, 320),
                    and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                )

                 
                offset := mul(and(mload(add(tablesPtr, 22)), 0xFFFF), 4)
                mstore(
                    add(order, 416),
                    and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                )

                 
                offset := mul(and(mload(add(tablesPtr, 24)), 0xFFFF), 4)
                mstore(
                    add(order, 448),
                    and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                )

                 
                offset := mul(and(mload(add(tablesPtr, 26)), 0xFFFF), 4)
                mstore(
                    add(order, 480),
                    and(mload(add(add(data,  4), offset)), 0xFFFFFFFF)
                )

                 
                mstore(add(data, 32), emptyBytes)

                 
                offset := mul(and(mload(add(tablesPtr, 28)), 0xFFFF), 4)
                mstore(
                    add(order, 512),
                    add(data, add(offset, 32))
                )

                 
                offset := mul(and(mload(add(tablesPtr, 30)), 0xFFFF), 4)
                mstore(
                    add(order, 544),
                    add(data, add(offset, 32))
                )

                 
                mstore(add(data, 32), 0)

                 
                offset := and(mload(add(tablesPtr, 32)), 0xFFFF)
                mstore(
                    add(order, 576),
                    gt(offset, 0)
                )

                 
                mstore(add(data, 20), lrcTokenAddress)

                 
                offset := mul(and(mload(add(tablesPtr, 34)), 0xFFFF), 4)
                mstore(
                    add(order, 608),
                    and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                )

                 
                mstore(add(data, 20), 0)

                 
                offset := mul(and(mload(add(tablesPtr, 36)), 0xFFFF), 4)
                mstore(
                    add(order, 640),
                    mload(add(add(data, 32), offset))
                )

                 
                offset := and(mload(add(tablesPtr, 38)), 0xFFFF)
                mstore(
                    add(order, 672),
                    offset
                )

                 
                offset := and(mload(add(tablesPtr, 40)), 0xFFFF)
                mstore(
                    add(order, 704),
                    offset
                )

                 
                offset := and(mload(add(tablesPtr, 42)), 0xFFFF)
                mstore(
                    add(order, 736),
                    offset
                )

                 
                mstore(add(data, 20), mload(add(order, 32)))                 

                 
                offset := mul(and(mload(add(tablesPtr, 44)), 0xFFFF), 4)
                mstore(
                    add(order, 768),
                    and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                )

                 
                mstore(add(data, 20), 0)

                 
                offset := and(mload(add(tablesPtr, 46)), 0xFFFF)
                mstore(
                    add(order, 800),
                    offset
                )

                 
                offset := and(mload(add(tablesPtr, 48)), 0xFFFF)
                mstore(
                    add(order, 1024),
                    offset
                )

                 
                offset := and(mload(add(tablesPtr, 50)), 0xFFFF)
                mstore(
                    add(order, 1056),
                    offset
                )

                 
                offset := and(mload(add(tablesPtr, 52)), 0xFFFF)
                mstore(
                    add(order, 1088),
                    offset
                )

                 
                offset := mul(and(mload(add(tablesPtr, 54)), 0xFFFF), 4)
                mstore(
                    add(order, 1120),
                    mload(add(add(data, 32), offset))
                )

                 
                offset := mul(and(mload(add(tablesPtr, 56)), 0xFFFF), 4)
                mstore(
                    add(order, 1152),
                    mload(add(add(data, 32), offset))
                )

                 
                mstore(add(data, 32), emptyBytes)

                 
                offset := mul(and(mload(add(tablesPtr, 58)), 0xFFFF), 4)
                mstore(
                    add(order, 1184),
                    add(data, add(offset, 32))
                )

                 
                mstore(add(data, 32), 0)

                 
                mstore(add(order, 832), 0)          
                mstore(add(order, 864), 0)          
                mstore(add(order, 896), 0)          
                mstore(add(order, 928), 0)          
                mstore(add(order, 960), 0)          
                mstore(add(order, 992), 1)          

                 
                tablesPtr := add(tablesPtr, 60)
            }
        }
    }

    function assembleRings(
        uint data,
        uint numRings,
        Data.Order[] memory orders
        )
        internal
        pure
        returns (Data.Ring[] memory rings)
    {
        uint ringsArrayDataSize = (1 + numRings) * 32;
        uint ringStructSize = 5 * 32;
        uint participationStructSize = 10 * 32;

        assembly {
             
            rings := mload(0x40)
            mstore(add(rings, 0), numRings)                       
             
            mstore(0x40, add(rings, add(ringsArrayDataSize, mul(ringStructSize, numRings))))

            for { let r := 0 } lt(r, numRings) { r := add(r, 1) } {
                let ring := add(rings, add(ringsArrayDataSize, mul(ringStructSize, r)))

                 
                mstore(add(rings, mul(add(r, 1), 32)), ring)

                 
                let ringSize := and(mload(data), 0xFF)
                data := add(data, 1)

                 
                if gt(ringSize, 8) {
                    revert(0, 0)
                }

                 
                let participations := mload(0x40)
                mstore(add(participations, 0), ringSize)          
                 
                let participationsData := add(participations, mul(add(1, ringSize), 32))
                 
                mstore(0x40, add(participationsData, mul(participationStructSize, ringSize)))

                 
                mstore(add(ring,   0), ringSize)                  
                mstore(add(ring,  32), participations)            
                mstore(add(ring,  64), 0)                         
                mstore(add(ring,  96), 0)                         
                mstore(add(ring, 128), 1)                         

                for { let i := 0 } lt(i, ringSize) { i := add(i, 1) } {
                    let participation := add(participationsData, mul(participationStructSize, i))

                     
                    mstore(add(participations, mul(add(i, 1), 32)), participation)

                     
                    let orderIndex := and(mload(data), 0xFF)
                     
                    if iszero(lt(orderIndex, mload(orders))) {
                        revert(0, 0)
                    }
                    data := add(data, 1)

                     
                    mstore(
                        add(participation,   0),
                        mload(add(orders, mul(add(orderIndex, 1), 32)))
                    )

                     
                    mstore(add(participation,  32), 0)           
                    mstore(add(participation,  64), 0)           
                    mstore(add(participation,  96), 0)           
                    mstore(add(participation, 128), 0)           
                    mstore(add(participation, 160), 0)           
                    mstore(add(participation, 192), 0)           
                    mstore(add(participation, 224), 0)           
                    mstore(add(participation, 256), 0)           
                    mstore(add(participation, 288), 0)           
                }

                 
                data := add(data, sub(8, ringSize))
            }
        }
    }
}



 
 
 
 
 
 
 
 
 
contract RingSubmitter is IRingSubmitter, NoDefaultFunc {
    using MathUint      for uint;
    using BytesUtil     for bytes;
    using OrderHelper     for Data.Order;
    using RingHelper      for Data.Ring;
    using MiningHelper    for Data.Mining;

    address public constant lrcTokenAddress             = 0xEF68e7C694F40c8202821eDF525dE3782458639f;
    address public constant wethTokenAddress            = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant delegateAddress             = 0xb258f5C190faDAB30B5fF0D6ab7E32a646A4BaAe;
    address public constant tradeHistoryAddress         = 0xBF5a37670B3DE1E606EC68bE3558c536b2008669;
    address public constant orderBrokerRegistryAddress  = 0x4e1E917F030556788AB3C9d8D0971Ebf0d5439E9;
    address public constant orderRegistryAddress        = 0x6fb707F15Ab3657Dc52776b057B33cB7D95e4E90;
    address public constant feeHolderAddress            = 0x5beaEA36efA78F43a6d61145817FDFf6A9929e60;
    address public constant orderBookAddress            = 0xaC0F8a27012fe8dc5a0bB7f5fc7170934F7e3577;
    address public constant burnRateTableAddress        = 0x20D90aefBA13F044C5d23c48C3b07e2E43a006DB;

    uint64  public  ringIndex                   = 0;

    uint    public constant MAX_RING_SIZE       = 8;

    struct SubmitRingsParam {
        uint16[]    encodeSpecs;
        uint16      miningSpec;
        uint16[]    orderSpecs;
        uint8[][]   ringSpecs;
        address[]   addressList;
        uint[]      uintList;
        bytes[]     bytesList;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
     
     
     
     
     
     
     
     
     

    function submitRings(
        bytes calldata data
        )
        external
    {
        uint i;
        bytes32[] memory tokenBurnRates;
        Data.Context memory ctx = Data.Context(
            lrcTokenAddress,
            ITradeDelegate(delegateAddress),
            ITradeHistory(tradeHistoryAddress),
            IBrokerRegistry(orderBrokerRegistryAddress),
            IOrderRegistry(orderRegistryAddress),
            IFeeHolder(feeHolderAddress),
            IOrderBook(orderBookAddress),
            IBurnRateTable(burnRateTableAddress),
            ringIndex,
            FEE_PERCENTAGE_BASE,
            tokenBurnRates,
            0,
            0,
            0,
            0
        );

         
        require((ctx.ringIndex >> 63) == 0, REENTRY);

         
        ringIndex = ctx.ringIndex | (1 << 63);

        (
            Data.Mining  memory mining,
            Data.Order[] memory orders,
            Data.Ring[]  memory rings
        ) = ExchangeDeserializer.deserialize(lrcTokenAddress, data);

         
        setupLists(ctx, orders, rings);

        for (i = 0; i < orders.length; i++) {
            orders[i].updateHash();
            orders[i].updateBrokerAndInterceptor(ctx);
        }

        batchGetFilledAndCheckCancelled(ctx, orders);

        for (i = 0; i < orders.length; i++) {
            orders[i].check(ctx);
             
            for (uint j = i + 1; j < orders.length; j++) {
                require(orders[i].hash != orders[j].hash, INVALID_VALUE);
            }
        }

        for (i = 0; i < rings.length; i++) {
            rings[i].updateHash();
        }

        mining.updateHash(rings);
        mining.updateMinerAndInterceptor();
        require(mining.checkMinerSignature(), INVALID_SIG);

        for (i = 0; i < orders.length; i++) {
             
             
             
             
            if(i > 0 && orders[i].dualAuthAddr == orders[i - 1].dualAuthAddr) {
                continue;
            }
            orders[i].checkDualAuthSignature(mining.hash);
        }

        for (i = 0; i < rings.length; i++) {
            Data.Ring memory ring = rings[i];
            ring.checkOrdersValid();
            ring.checkForSubRings();
            ring.calculateFillAmountAndFee(ctx);
            if (ring.valid) {
                ring.adjustOrderStates();
            }
        }

         
         
        checkRings(orders, rings);

        for (i = 0; i < rings.length; i++) {
            Data.Ring memory ring = rings[i];
            if (ring.valid) {
                 
                ring.doPayments(ctx, mining);
                emitRingMinedEvent(
                    ring,
                    ctx.ringIndex++,
                    mining.feeRecipient
                );
            } else {
                emit InvalidRing(ring.hash);
            }
        }

         
        batchTransferTokens(ctx);
         
        batchPayFees(ctx);
         
        updateOrdersStats(ctx, orders);

         
        ringIndex = ctx.ringIndex;
    }

    function checkRings(
        Data.Order[] memory orders,
        Data.Ring[] memory rings
        )
        internal
        pure
    {
         
         
         
         
        bool reevaluateRings = true;
        while (reevaluateRings) {
            reevaluateRings = false;
            for (uint i = 0; i < orders.length; i++) {
                if (orders[i].valid) {
                    orders[i].validateAllOrNone();
                     
                    reevaluateRings = reevaluateRings || !orders[i].valid;
                }
            }
            if (reevaluateRings) {
                for (uint i = 0; i < rings.length; i++) {
                    Data.Ring memory ring = rings[i];
                    if (ring.valid) {
                        ring.checkOrdersValid();
                        if (!ring.valid) {
                             
                             
                            ring.revertOrderStats();
                        }
                    }
                }
            }
        }
    }

    function emitRingMinedEvent(
        Data.Ring memory ring,
        uint _ringIndex,
        address feeRecipient
        )
        internal
    {
        bytes32 ringHash = ring.hash;
         
        bytes32 ringMinedSignature = 0xb2ef4bc5209dff0c46d5dfddb2b68a23bd4820e8f33107fde76ed15ba90695c9;
        uint fillsSize = ring.size * 8 * 32;

        uint data;
        uint ptr;
        assembly {
            data := mload(0x40)
            ptr := data
            mstore(ptr, _ringIndex)                      
            mstore(add(ptr, 32), 0x40)                   
            mstore(add(ptr, 64), fillsSize)              
            ptr := add(ptr, 96)
        }
        ptr = ring.generateFills(ptr);

        assembly {
            log3(
                data,                                    
                sub(ptr, data),                          
                ringMinedSignature,                      
                ringHash,                                
                feeRecipient                             
            )
        }
    }

    function setupLists(
        Data.Context memory ctx,
        Data.Order[] memory orders,
        Data.Ring[] memory rings
        )
        internal
        pure
    {
        setupTokenBurnRateList(ctx, orders);
        setupFeePaymentList(ctx, rings);
        setupTokenTransferList(ctx, rings);
    }

    function setupTokenBurnRateList(
        Data.Context memory ctx,
        Data.Order[] memory orders
        )
        internal
        pure
    {
         
         
        uint maxNumTokenBurnRates = orders.length * 2;
        bytes32[] memory tokenBurnRates;
        assembly {
            tokenBurnRates := mload(0x40)
            mstore(tokenBurnRates, 0)                                
            mstore(0x40, add(
                tokenBurnRates,
                add(32, mul(maxNumTokenBurnRates, 64))
            ))
        }
        ctx.tokenBurnRates = tokenBurnRates;
    }

    function setupFeePaymentList(
        Data.Context memory ctx,
        Data.Ring[] memory rings
        )
        internal
        pure
    {
        uint totalMaxSizeFeePayments = 0;
        for (uint i = 0; i < rings.length; i++) {
             
             
            uint ringSize = rings[i].size;
            uint maxSize = (ringSize + 3) * 3 * ringSize * 3;
            totalMaxSizeFeePayments += maxSize;
        }
         
         
         
         
         
        bytes4 batchAddFeeBalancesSelector = ctx.feeHolder.batchAddFeeBalances.selector;
        uint ptr;
        assembly {
            let data := mload(0x40)
            mstore(data, batchAddFeeBalancesSelector)
            mstore(add(data, 4), 32)
            ptr := add(data, 68)
            mstore(0x40, add(ptr, mul(totalMaxSizeFeePayments, 32)))
        }
        ctx.feeData = ptr;
        ctx.feePtr = ptr;
    }

    function setupTokenTransferList(
        Data.Context memory ctx,
        Data.Ring[] memory rings
        )
        internal
        pure
    {
        uint totalMaxSizeTransfers = 0;
        for (uint i = 0; i < rings.length; i++) {
             
             
            uint maxSize = 4 * rings[i].size * 4;
            totalMaxSizeTransfers += maxSize;
        }
         
         
         
         
         
        bytes4 batchTransferSelector = ctx.delegate.batchTransfer.selector;
        uint ptr;
        assembly {
            let data := mload(0x40)
            mstore(data, batchTransferSelector)
            mstore(add(data, 4), 32)
            ptr := add(data, 68)
            mstore(0x40, add(ptr, mul(totalMaxSizeTransfers, 32)))
        }
        ctx.transferData = ptr;
        ctx.transferPtr = ptr;
    }

    function updateOrdersStats(
        Data.Context memory ctx,
        Data.Order[] memory orders
        )
        internal
    {
         
         
         
         
         
         
         
         
        bytes4 batchUpdateFilledSelector = ctx.tradeHistory.batchUpdateFilled.selector;
        address _tradeHistoryAddress = address(ctx.tradeHistory);
        assembly {
            let data := mload(0x40)
            mstore(data, batchUpdateFilledSelector)
            mstore(add(data, 4), 32)
            let ptr := add(data, 68)
            let arrayLength := 0
            for { let i := 0 } lt(i, mload(orders)) { i := add(i, 1) } {
                let order := mload(add(orders, mul(add(i, 1), 32)))
                let filledAmount := mload(add(order, 928))                                
                let initialFilledAmount := mload(add(order, 960))                         
                let filledAmountChanged := iszero(eq(filledAmount, initialFilledAmount))
                 
                if and(gt(mload(add(order, 992)), 0), filledAmountChanged) {              
                    mstore(add(ptr,   0), mload(add(order, 864)))                         
                    mstore(add(ptr,  32), filledAmount)

                    ptr := add(ptr, 64)
                    arrayLength := add(arrayLength, 2)
                }
            }

             
            if gt(arrayLength, 0) {
                mstore(add(data, 36), arrayLength)       

                let success := call(
                    gas,                                 
                    _tradeHistoryAddress,                
                    0,                                   
                    data,                                
                    sub(ptr, data),                      
                    data,                                
                    0                                    
                )
                if eq(success, 0) {
                     
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }

    function batchGetFilledAndCheckCancelled(
        Data.Context memory ctx,
        Data.Order[] memory orders
        )
        internal
    {
         
         
         
         
         
         
         
         
         
         
         
        bytes4 batchGetFilledAndCheckCancelledSelector = ctx.tradeHistory.batchGetFilledAndCheckCancelled.selector;
        address _tradeHistoryAddress = address(ctx.tradeHistory);
        assembly {
            let data := mload(0x40)
            mstore(data, batchGetFilledAndCheckCancelledSelector)
            mstore(add(data,  4), 32)
            mstore(add(data, 36), mul(mload(orders), 5))                 
            let ptr := add(data, 68)
            for { let i := 0 } lt(i, mload(orders)) { i := add(i, 1) } {
                let order := mload(add(orders, mul(add(i, 1), 32)))      
                mstore(add(ptr,   0), mload(add(order, 320)))            
                mstore(add(ptr,  32), mload(add(order,  32)))            
                mstore(add(ptr,  64), mload(add(order, 864)))            
                mstore(add(ptr,  96), mload(add(order, 192)))            
                 
                mstore(add(ptr, 128), mul(
                    xor(
                        mload(add(order, 64)),                  
                        mload(add(order, 96))                   
                    ),
                    0x1000000000000000000000000)                
                )
                ptr := add(ptr, 160)                                     
            }
             
             
             
             
            let returnDataSize := mul(add(2, mload(orders)), 32)
            let success := call(
                gas,                                 
                _tradeHistoryAddress,                
                0,                                   
                data,                                
                sub(ptr, data),                      
                data,                                
                returnDataSize                       
            )
             
            if or(eq(success, 0), iszero(eq(returndatasize(), returnDataSize))) {
                if eq(success, 0) {
                     
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
                revert(0, 0)
            }
            for { let i := 0 } lt(i, mload(orders)) { i := add(i, 1) } {
                let order := mload(add(orders, mul(add(i, 1), 32)))      
                let fill := mload(add(data,  mul(add(i, 2), 32)))        
                mstore(add(order, 928), fill)                            
                mstore(add(order, 960), fill)                            
                 
                 
                mstore(add(order, 992),                                  
                    and(
                        gt(mload(add(order, 992)), 0),                   
                        iszero(eq(fill, not(0)))                         
                    )
                )
            }
        }
    }

    function batchTransferTokens(
        Data.Context memory ctx
        )
        internal
    {
         
        if (ctx.transferData == ctx.transferPtr) {
            return;
        }
         
         
         
        address _tradeDelegateAddress = address(ctx.delegate);
        uint arrayLength = (ctx.transferPtr - ctx.transferData) / 32;
        uint data = ctx.transferData - 68;
        uint ptr = ctx.transferPtr;
        assembly {
            mstore(add(data, 36), arrayLength)       

            let success := call(
                gas,                                 
                _tradeDelegateAddress,               
                0,                                   
                data,                                
                sub(ptr, data),                      
                data,                                
                0                                    
            )
            if eq(success, 0) {
                 
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function batchPayFees(
        Data.Context memory ctx
        )
        internal
    {
         
        if (ctx.feeData == ctx.feePtr) {
            return;
        }
         
         
         
        address _feeHolderAddress = address(ctx.feeHolder);
        uint arrayLength = (ctx.feePtr - ctx.feeData) / 32;
        uint data = ctx.feeData - 68;
        uint ptr = ctx.feePtr;
        assembly {
            mstore(add(data, 36), arrayLength)       

            let success := call(
                gas,                                 
                _feeHolderAddress,                   
                0,                                   
                data,                                
                sub(ptr, data),                      
                data,                                
                0                                    
            )
            if eq(success, 0) {
                 
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

}