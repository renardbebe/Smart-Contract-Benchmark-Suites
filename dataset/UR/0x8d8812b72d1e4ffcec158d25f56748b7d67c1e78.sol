 

 
pragma solidity 0.4.21;
 
 
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
        require(a == 0 || c / a == b);
    }
    function sub(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint)
    {
        require(b <= a);
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
        require(c >= a);
    }
    function tolerantSub(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        return (a >= b) ? a - b : 0;
    }
     
     
    function cvsquare(
        uint[] arr,
        uint scale
        )
        internal
        pure
        returns (uint)
    {
        uint len = arr.length;
        require(len > 1);
        require(scale > 0);
        uint avg = 0;
        for (uint i = 0; i < len; i++) {
            avg = add(avg, arr[i]);
        }
        avg = avg / len;
        if (avg == 0) {
            return 0;
        }
        uint cvs = 0;
        uint s;
        uint item;
        for (i = 0; i < len; i++) {
            item = arr[i];
            s = item > avg ? item - avg : avg - item;
            cvs = add(cvs, mul(s, s));
        }
        return ((mul(mul(cvs, scale), scale) / avg) / avg) / (len - 1);
    }
}
 
 
 
library AddressUtil {
    function isContract(
        address addr
        )
        internal
        view
        returns (bool)
    {
        if (addr == 0x0) {
            return false;
        } else {
            uint size;
            assembly { size := extcodesize(addr) }
            return size > 0;
        }
    }
}
 
 
 
 
 
contract ERC20 {
    function balanceOf(
        address who
        )
        view
        public
        returns (uint256);
    function allowance(
        address owner,
        address spender
        )
        view
        public
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
}
 
 
 
 
contract LoopringProtocol {
    uint8   public constant MARGIN_SPLIT_PERCENTAGE_BASE = 100;
     
     
     
    event RingMined(
        uint            _ringIndex,
        bytes32 indexed _ringHash,
        address         _miner,
        address         _feeRecipient,
        bytes32[]       _orderInfoList
    );
    event OrderCancelled(
        bytes32 indexed _orderHash,
        uint            _amountCancelled
    );
    event AllOrdersCancelled(
        address indexed _address,
        uint            _cutoff
    );
    event OrdersCancelled(
        address indexed _address,
        address         _token1,
        address         _token2,
        uint            _cutoff
    );
     
     
     
     
     
     
     
     
     
     
     
     
     
    function cancelOrder(
        address[5] addresses,
        uint[6]    orderValues,
        bool       buyNoMoreThanAmountB,
        uint8      marginSplitPercentage,
        uint8      v,
        bytes32    r,
        bytes32    s
        )
        external;
     
     
     
     
     
    function cancelAllOrdersByTradingPair(
        address token1,
        address token2,
        uint cutoff
        )
        external;
     
     
     
     
     
    function cancelAllOrders(
        uint cutoff
        )
        external;
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function submitRing(
        address[4][]    addressList,
        uint[6][]       uintArgsList,
        uint8[1][]      uint8ArgsList,
        bool[]          buyNoMoreThanAmountBList,
        uint8[]         vList,
        bytes32[]       rList,
        bytes32[]       sList,
        address         feeRecipient,
        uint16          feeSelections
        )
        public;
}
 
 
 
 
 
contract TokenRegistry {
    event TokenRegistered(
        address indexed addr,
        string          symbol
    );
    event TokenUnregistered(
        address indexed addr,
        string          symbol
    );
    function registerToken(
        address addr,
        string  symbol
        )
        external;
    function unregisterToken(
        address addr,
        string  symbol
        )
        external;
    function areAllTokensRegistered(
        address[] addressList
        )
        external
        view
        returns (bool);
    function getAddressBySymbol(
        string symbol
        )
        external
        view
        returns (address);
    function isTokenRegisteredBySymbol(
        string symbol
        )
        public
        view
        returns (bool);
    function isTokenRegistered(
        address addr
        )
        public
        view
        returns (bool);
    function getTokens(
        uint start,
        uint count
        )
        public
        view
        returns (address[] addressList);
}
 
 
 
 
 
contract TokenTransferDelegate {
    event AddressAuthorized(
        address indexed addr,
        uint32          number
    );
    event AddressDeauthorized(
        address indexed addr,
        uint32          number
    );
     
     
    mapping (bytes32 => uint) public cancelledOrFilled;
     
    mapping (bytes32 => uint) public cancelled;
     
    mapping (address => uint) public cutoffs;
     
    mapping (address => mapping (bytes20 => uint)) public tradingPairCutoffs;
     
     
    function authorizeAddress(
        address addr
        )
        external;
     
     
    function deauthorizeAddress(
        address addr
        )
        external;
    function getLatestAuthorizedAddresses(
        uint max
        )
        external
        view
        returns (address[] addresses);
     
     
     
     
     
    function transferToken(
        address token,
        address from,
        address to,
        uint    value
        )
        external;
    function batchTransferToken(
        address lrcTokenAddress,
        address miner,
        address minerFeeRecipient,
        uint8 walletSplitPercentage,
        bytes32[] batch
        )
        external;
    function isAddressAuthorized(
        address addr
        )
        public
        view
        returns (bool);
    function addCancelled(bytes32 orderHash, uint cancelAmount)
        external;
    function addCancelledOrFilled(bytes32 orderHash, uint cancelOrFillAmount)
        public;
    function batchAddCancelledOrFilled(bytes32[] batch)
        public;
    function setCutoffs(uint t)
        external;
    function setTradingPairCutoffs(bytes20 tokenPair, uint t)
        external;
    function checkCutoffsBatch(address[] owners, bytes20[] tradingPairs, uint[] validSince)
        external
        view;
    function suspend() external;
    function resume() external;
    function kill() external;
}
 
 
 
 
 
 
 
 
 
 
contract LoopringProtocolImpl is LoopringProtocol {
    using AddressUtil   for address;
    using MathUint      for uint;
    address public constant lrcTokenAddress             = 0xEF68e7C694F40c8202821eDF525dE3782458639f;
    address public constant tokenRegistryAddress        = 0xAbe12e3548fDb334D11fcc962c413d91Ef12233F;
    address public constant delegateAddress             = 0x17233e07c67d086464fD408148c3ABB56245FA64;
    uint64  public  ringIndex                   = 0;
    uint8   public constant walletSplitPercentage       = 20;
     
     
     
     
     
     
     
     
     
    uint    public constant rateRatioCVSThreshold        = 62500;
    uint    public constant MAX_RING_SIZE       = 16;
    uint    public constant RATE_RATIO_SCALE    = 10000;
     
     
     
     
     
     
     
     
     
     
     
     
     
    struct OrderState {
        address owner;
        address tokenS;
        address tokenB;
        address wallet;
        address authAddr;
        uint    validSince;
        uint    validUntil;
        uint    amountS;
        uint    amountB;
        uint    lrcFee;
        bool    buyNoMoreThanAmountB;
        bool    marginSplitAsFee;
        bytes32 orderHash;
        uint8   marginSplitPercentage;
        uint    rateS;
        uint    rateB;
        uint    fillAmountS;
        uint    lrcReward;
        uint    lrcFeeState;
        uint    splitS;
        uint    splitB;
    }
     
     
    struct RingParams {
        uint8[]       vList;
        bytes32[]     rList;
        bytes32[]     sList;
        address       feeRecipient;
        uint16        feeSelections;
        uint          ringSize;          
        bytes32       ringHash;          
    }
     
    function ()
        payable
        public
    {
        revert();
    }
    function cancelOrder(
        address[5] addresses,
        uint[6]    orderValues,
        bool       buyNoMoreThanAmountB,
        uint8      marginSplitPercentage,
        uint8      v,
        bytes32    r,
        bytes32    s
        )
        external
    {
        uint cancelAmount = orderValues[5];
        require(cancelAmount > 0);  
        OrderState memory order = OrderState(
            addresses[0],
            addresses[1],
            addresses[2],
            addresses[3],
            addresses[4],
            orderValues[2],
            orderValues[3],
            orderValues[0],
            orderValues[1],
            orderValues[4],
            buyNoMoreThanAmountB,
            false,
            0x0,
            marginSplitPercentage,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        );
        require(msg.sender == order.owner);  
        bytes32 orderHash = calculateOrderHash(order);
        verifySignature(
            order.owner,
            orderHash,
            v,
            r,
            s
        );
        TokenTransferDelegate delegate = TokenTransferDelegate(delegateAddress);
        delegate.addCancelled(orderHash, cancelAmount);
        delegate.addCancelledOrFilled(orderHash, cancelAmount);
        emit OrderCancelled(orderHash, cancelAmount);
    }
    function cancelAllOrdersByTradingPair(
        address token1,
        address token2,
        uint    cutoff
        )
        external
    {
        uint t = (cutoff == 0 || cutoff >= block.timestamp) ? block.timestamp : cutoff;
        bytes20 tokenPair = bytes20(token1) ^ bytes20(token2);
        TokenTransferDelegate delegate = TokenTransferDelegate(delegateAddress);
        require(delegate.tradingPairCutoffs(msg.sender, tokenPair) < t);
         
        delegate.setTradingPairCutoffs(tokenPair, t);
        emit OrdersCancelled(
            msg.sender,
            token1,
            token2,
            t
        );
    }
    function cancelAllOrders(
        uint cutoff
        )
        external
    {
        uint t = (cutoff == 0 || cutoff >= block.timestamp) ? block.timestamp : cutoff;
        TokenTransferDelegate delegate = TokenTransferDelegate(delegateAddress);
        require(delegate.cutoffs(msg.sender) < t);  
        delegate.setCutoffs(t);
        emit AllOrdersCancelled(msg.sender, t);
    }
    function submitRing(
        address[4][]  addressList,
        uint[6][]     uintArgsList,
        uint8[1][]    uint8ArgsList,
        bool[]        buyNoMoreThanAmountBList,
        uint8[]       vList,
        bytes32[]     rList,
        bytes32[]     sList,
        address       feeRecipient,
        uint16        feeSelections
        )
        public
    {
         
        require((ringIndex >> 63) == 0);  
         
        uint64 _ringIndex = ringIndex;
        ringIndex |= (1 << 63);
        RingParams memory params = RingParams(
            vList,
            rList,
            sList,
            feeRecipient,
            feeSelections,
            addressList.length,
            0x0  
        );
        verifyInputDataIntegrity(
            params,
            addressList,
            uintArgsList,
            uint8ArgsList,
            buyNoMoreThanAmountBList
        );
         
         
         
        TokenTransferDelegate delegate = TokenTransferDelegate(delegateAddress);
        OrderState[] memory orders = assembleOrders(
            params,
            delegate,
            addressList,
            uintArgsList,
            uint8ArgsList,
            buyNoMoreThanAmountBList
        );
        verifyRingSignatures(params, orders);
        verifyTokensRegistered(params, orders);
        handleRing(_ringIndex, params, orders, delegate);
        ringIndex = _ringIndex + 1;
    }
     
    function verifyRingHasNoSubRing(
        uint          ringSize,
        OrderState[]  orders
        )
        private
        pure
    {
         
        for (uint i = 0; i < ringSize - 1; i++) {
            address tokenS = orders[i].tokenS;
            for (uint j = i + 1; j < ringSize; j++) {
                require(tokenS != orders[j].tokenS);  
            }
        }
    }
     
     
    function verifyRingSignatures(
        RingParams params,
        OrderState[] orders
        )
        private
        pure
    {
        uint j;
        for (uint i = 0; i < params.ringSize; i++) {
            j = i + params.ringSize;
            verifySignature(
                orders[i].authAddr,
                params.ringHash,
                params.vList[j],
                params.rList[j],
                params.sList[j]
            );
        }
    }
    function verifyTokensRegistered(
        RingParams params,
        OrderState[] orders
        )
        private
        view
    {
         
        address[] memory tokens = new address[](params.ringSize);
        for (uint i = 0; i < params.ringSize; i++) {
            tokens[i] = orders[i].tokenS;
        }
         
        require(
            TokenRegistry(tokenRegistryAddress).areAllTokensRegistered(tokens)
        );  
    }
    function handleRing(
        uint64       _ringIndex,
        RingParams   params,
        OrderState[] orders,
        TokenTransferDelegate delegate
        )
        private
    {
        address _lrcTokenAddress = lrcTokenAddress;
         
        verifyRingHasNoSubRing(params.ringSize, orders);
         
         
         
        verifyMinerSuppliedFillRates(params.ringSize, orders);
         
         
         
        scaleRingBasedOnHistoricalRecords(delegate, params.ringSize, orders);
         
         
         
         
        calculateRingFillAmount(params.ringSize, orders);
         
         
         
        calculateRingFees(
            delegate,
            params.ringSize,
            orders,
            _lrcTokenAddress
        );
         
        bytes32[] memory orderInfoList = settleRing(
            delegate,
            params.ringSize,
            orders,
            params.feeRecipient,
            _lrcTokenAddress
        );
        emit RingMined(
            _ringIndex,
            params.ringHash,
            tx.origin,
            params.feeRecipient,
            orderInfoList
        );
    }
    function settleRing(
        TokenTransferDelegate delegate,
        uint          ringSize,
        OrderState[]  orders,
        address       feeRecipient,
        address       _lrcTokenAddress
        )
        private
        returns (bytes32[] memory orderInfoList)
    {
        bytes32[] memory batch = new bytes32[](ringSize * 7);  
        bytes32[] memory historyBatch = new bytes32[](ringSize * 2);  
        orderInfoList = new bytes32[](ringSize * 7);
        uint p = 0;
        uint q = 0;
        uint r = 0;
        uint prevSplitB = orders[ringSize - 1].splitB;
        for (uint i = 0; i < ringSize; i++) {
            OrderState memory state = orders[i];
            uint nextFillAmountS = orders[(i + 1) % ringSize].fillAmountS;
             
            batch[p++] = bytes32(state.owner);
            batch[p++] = bytes32(state.tokenS);
             
            batch[p++] = bytes32(state.fillAmountS.sub(prevSplitB));
            batch[p++] = bytes32(prevSplitB.add(state.splitS));
            batch[p++] = bytes32(state.lrcReward);
            batch[p++] = bytes32(state.lrcFeeState);
            batch[p++] = bytes32(state.wallet);
            historyBatch[r++] = state.orderHash;
            historyBatch[r++] = bytes32(
                state.buyNoMoreThanAmountB ? nextFillAmountS : state.fillAmountS);
            orderInfoList[q++] = bytes32(state.orderHash);
            orderInfoList[q++] = bytes32(state.owner);
            orderInfoList[q++] = bytes32(state.tokenS);
            orderInfoList[q++] = bytes32(state.fillAmountS);
            orderInfoList[q++] = bytes32(state.lrcReward);
            orderInfoList[q++] = bytes32(
                state.lrcFeeState > 0 ? int(state.lrcFeeState) : -int(state.lrcReward)
            );
            orderInfoList[q++] = bytes32(
                state.splitS > 0 ? int(state.splitS) : -int(state.splitB)
            );
            prevSplitB = state.splitB;
        }
         
        delegate.batchAddCancelledOrFilled(historyBatch);
         
        delegate.batchTransferToken(
            _lrcTokenAddress,
            tx.origin,
            feeRecipient,
            walletSplitPercentage,
            batch
        );
    }
     
    function verifyMinerSuppliedFillRates(
        uint         ringSize,
        OrderState[] orders
        )
        private
        pure
    {
        uint[] memory rateRatios = new uint[](ringSize);
        uint _rateRatioScale = RATE_RATIO_SCALE;
        for (uint i = 0; i < ringSize; i++) {
            uint s1b0 = orders[i].rateS.mul(orders[i].amountB);
            uint s0b1 = orders[i].amountS.mul(orders[i].rateB);
            require(s1b0 <= s0b1);  
            rateRatios[i] = _rateRatioScale.mul(s1b0) / s0b1;
        }
        uint cvs = MathUint.cvsquare(rateRatios, _rateRatioScale);
        require(cvs <= rateRatioCVSThreshold);
         
    }
     
    function calculateRingFees(
        TokenTransferDelegate delegate,
        uint            ringSize,
        OrderState[]    orders,
        address         _lrcTokenAddress
        )
        private
        view
    {
        bool checkedMinerLrcSpendable = false;
        uint minerLrcSpendable = 0;
        uint8 _marginSplitPercentageBase = MARGIN_SPLIT_PERCENTAGE_BASE;
        uint nextFillAmountS;
        for (uint i = 0; i < ringSize; i++) {
            OrderState memory state = orders[i];
            uint lrcReceiable = 0;
            if (state.lrcFeeState == 0) {
                 
                 
                state.marginSplitAsFee = true;
                state.marginSplitPercentage = _marginSplitPercentageBase;
            } else {
                uint lrcSpendable = getSpendable(
                    delegate,
                    _lrcTokenAddress,
                    state.owner
                );
                 
                 
                if (state.tokenS == _lrcTokenAddress) {
                    lrcSpendable = lrcSpendable.sub(state.fillAmountS);
                }
                 
                if (state.tokenB == _lrcTokenAddress) {
                    nextFillAmountS = orders[(i + 1) % ringSize].fillAmountS;
                    lrcReceiable = nextFillAmountS;
                }
                uint lrcTotal = lrcSpendable.add(lrcReceiable);
                 
                if (lrcTotal < state.lrcFeeState) {
                    state.lrcFeeState = lrcTotal;
                    state.marginSplitPercentage = _marginSplitPercentageBase;
                }
                if (state.lrcFeeState == 0) {
                    state.marginSplitAsFee = true;
                }
            }
            if (!state.marginSplitAsFee) {
                if (lrcReceiable > 0) {
                    if (lrcReceiable >= state.lrcFeeState) {
                        state.splitB = state.lrcFeeState;
                        state.lrcFeeState = 0;
                    } else {
                        state.splitB = lrcReceiable;
                        state.lrcFeeState = state.lrcFeeState.sub(lrcReceiable);
                    }
                }
            } else {
                 
                if (!checkedMinerLrcSpendable && minerLrcSpendable < state.lrcFeeState) {
                    checkedMinerLrcSpendable = true;
                    minerLrcSpendable = getSpendable(delegate, _lrcTokenAddress, tx.origin);
                }
                 
                 
                if (minerLrcSpendable >= state.lrcFeeState) {
                    nextFillAmountS = orders[(i + 1) % ringSize].fillAmountS;
                    uint split;
                    if (state.buyNoMoreThanAmountB) {
                        split = (nextFillAmountS.mul(
                            state.amountS
                        ) / state.amountB).sub(
                            state.fillAmountS
                        );
                    } else {
                        split = nextFillAmountS.sub(
                            state.fillAmountS.mul(
                                state.amountB
                            ) / state.amountS
                        );
                    }
                    if (state.marginSplitPercentage != _marginSplitPercentageBase) {
                        split = split.mul(
                            state.marginSplitPercentage
                        ) / _marginSplitPercentageBase;
                    }
                    if (state.buyNoMoreThanAmountB) {
                        state.splitS = split;
                    } else {
                        state.splitB = split;
                    }
                     
                     
                     
                    if (split > 0) {
                        minerLrcSpendable = minerLrcSpendable.sub(state.lrcFeeState);
                        state.lrcReward = state.lrcFeeState;
                    }
                }
                state.lrcFeeState = 0;
            }
        }
    }
     
    function calculateRingFillAmount(
        uint          ringSize,
        OrderState[]  orders
        )
        private
        pure
    {
        uint smallestIdx = 0;
        uint i;
        uint j;
        for (i = 0; i < ringSize; i++) {
            j = (i + 1) % ringSize;
            smallestIdx = calculateOrderFillAmount(
                orders[i],
                orders[j],
                i,
                j,
                smallestIdx
            );
        }
        for (i = 0; i < smallestIdx; i++) {
            calculateOrderFillAmount(
                orders[i],
                orders[(i + 1) % ringSize],
                0,                
                0,                
                0                 
            );
        }
    }
     
    function calculateOrderFillAmount(
        OrderState state,
        OrderState next,
        uint       i,
        uint       j,
        uint       smallestIdx
        )
        private
        pure
        returns (uint newSmallestIdx)
    {
         
        newSmallestIdx = smallestIdx;
        uint fillAmountB = state.fillAmountS.mul(
            state.rateB
        ) / state.rateS;
        if (state.buyNoMoreThanAmountB) {
            if (fillAmountB > state.amountB) {
                fillAmountB = state.amountB;
                state.fillAmountS = fillAmountB.mul(
                    state.rateS
                ) / state.rateB;
                require(state.fillAmountS > 0);
                newSmallestIdx = i;
            }
            state.lrcFeeState = state.lrcFee.mul(
                fillAmountB
            ) / state.amountB;
        } else {
            state.lrcFeeState = state.lrcFee.mul(
                state.fillAmountS
            ) / state.amountS;
        }
        if (fillAmountB <= next.fillAmountS) {
            next.fillAmountS = fillAmountB;
        } else {
            newSmallestIdx = j;
        }
    }
     
     
    function scaleRingBasedOnHistoricalRecords(
        TokenTransferDelegate delegate,
        uint ringSize,
        OrderState[] orders
        )
        private
        view
    {
        for (uint i = 0; i < ringSize; i++) {
            OrderState memory state = orders[i];
            uint amount;
            if (state.buyNoMoreThanAmountB) {
                amount = state.amountB.tolerantSub(
                    delegate.cancelledOrFilled(state.orderHash)
                );
                state.amountS = amount.mul(state.amountS) / state.amountB;
                state.lrcFee = amount.mul(state.lrcFee) / state.amountB;
                state.amountB = amount;
            } else {
                amount = state.amountS.tolerantSub(
                    delegate.cancelledOrFilled(state.orderHash)
                );
                state.amountB = amount.mul(state.amountB) / state.amountS;
                state.lrcFee = amount.mul(state.lrcFee) / state.amountS;
                state.amountS = amount;
            }
            require(state.amountS > 0);  
            require(state.amountB > 0);  
            uint availableAmountS = getSpendable(delegate, state.tokenS, state.owner);
            require(availableAmountS > 0);  
            state.fillAmountS = (
                state.amountS < availableAmountS ?
                state.amountS : availableAmountS
            );
            require(state.fillAmountS > 0);
        }
    }
     
    function getSpendable(
        TokenTransferDelegate delegate,
        address tokenAddress,
        address tokenOwner
        )
        private
        view
        returns (uint)
    {
        ERC20 token = ERC20(tokenAddress);
        uint allowance = token.allowance(
            tokenOwner,
            address(delegate)
        );
        uint balance = token.balanceOf(tokenOwner);
        return (allowance < balance ? allowance : balance);
    }
     
    function verifyInputDataIntegrity(
        RingParams params,
        address[4][]  addressList,
        uint[6][]     uintArgsList,
        uint8[1][]    uint8ArgsList,
        bool[]        buyNoMoreThanAmountBList
        )
        private
        pure
    {
        require(params.feeRecipient != 0x0);
        require(params.ringSize == addressList.length);
        require(params.ringSize == uintArgsList.length);
        require(params.ringSize == uint8ArgsList.length);
        require(params.ringSize == buyNoMoreThanAmountBList.length);
         
        for (uint i = 0; i < params.ringSize; i++) {
            require(uintArgsList[i][5] > 0);  
        }
         
        require(params.ringSize > 1 && params.ringSize <= MAX_RING_SIZE);  
        uint sigSize = params.ringSize << 1;
        require(sigSize == params.vList.length);
        require(sigSize == params.rList.length);
        require(sigSize == params.sList.length);
    }
     
     
    function assembleOrders(
        RingParams params,
        TokenTransferDelegate delegate,
        address[4][]  addressList,
        uint[6][]     uintArgsList,
        uint8[1][]    uint8ArgsList,
        bool[]        buyNoMoreThanAmountBList
        )
        private
        view
        returns (OrderState[] memory orders)
    {
        orders = new OrderState[](params.ringSize);
        for (uint i = 0; i < params.ringSize; i++) {
            uint[6] memory uintArgs = uintArgsList[i];
            bool marginSplitAsFee = (params.feeSelections & (uint16(1) << i)) > 0;
            orders[i] = OrderState(
                addressList[i][0],
                addressList[i][1],
                addressList[(i + 1) % params.ringSize][1],
                addressList[i][2],
                addressList[i][3],
                uintArgs[2],
                uintArgs[3],
                uintArgs[0],
                uintArgs[1],
                uintArgs[4],
                buyNoMoreThanAmountBList[i],
                marginSplitAsFee,
                bytes32(0),
                uint8ArgsList[i][0],
                uintArgs[5],
                uintArgs[1],
                0,    
                0,    
                0,    
                0,    
                0     
            );
            validateOrder(orders[i]);
            bytes32 orderHash = calculateOrderHash(orders[i]);
            orders[i].orderHash = orderHash;
            verifySignature(
                orders[i].owner,
                orderHash,
                params.vList[i],
                params.rList[i],
                params.sList[i]
            );
            params.ringHash ^= orderHash;
        }
        validateOrdersCutoffs(orders, delegate);
        params.ringHash = keccak256(
            params.ringHash,
            params.feeRecipient,
            params.feeSelections
        );
    }
     
    function validateOrder(
        OrderState order
        )
        private
        view
    {
        require(order.owner != 0x0);  
        require(order.tokenS != 0x0);  
        require(order.tokenB != 0x0);  
        require(order.amountS != 0);  
        require(order.amountB != 0);  
        require(order.marginSplitPercentage <= MARGIN_SPLIT_PERCENTAGE_BASE);
         
        require(order.validSince <= block.timestamp);  
        require(order.validUntil > block.timestamp);  
    }
    function validateOrdersCutoffs(OrderState[] orders, TokenTransferDelegate delegate)
        private
        view
    {
        address[] memory owners = new address[](orders.length);
        bytes20[] memory tradingPairs = new bytes20[](orders.length);
        uint[] memory validSinceTimes = new uint[](orders.length);
        for (uint i = 0; i < orders.length; i++) {
            owners[i] = orders[i].owner;
            tradingPairs[i] = bytes20(orders[i].tokenS) ^ bytes20(orders[i].tokenB);
            validSinceTimes[i] = orders[i].validSince;
        }
        delegate.checkCutoffsBatch(owners, tradingPairs, validSinceTimes);
    }
     
    function calculateOrderHash(
        OrderState order
        )
        private
        pure
        returns (bytes32)
    {
        return keccak256(
            delegateAddress,
            order.owner,
            order.tokenS,
            order.tokenB,
            order.wallet,
            order.authAddr,
            order.amountS,
            order.amountB,
            order.validSince,
            order.validUntil,
            order.lrcFee,
            order.buyNoMoreThanAmountB,
            order.marginSplitPercentage
        );
    }
     
    function verifySignature(
        address signer,
        bytes32 hash,
        uint8   v,
        bytes32 r,
        bytes32 s
        )
        private
        pure
    {
        require(
            signer == ecrecover(
                keccak256("\x19Ethereum Signed Message:\n32", hash),
                v,
                r,
                s
            )
        );  
    }
    function getTradingPairCutoffs(
        address orderOwner,
        address token1,
        address token2
        )
        public
        view
        returns (uint)
    {
        bytes20 tokenPair = bytes20(token1) ^ bytes20(token2);
        TokenTransferDelegate delegate = TokenTransferDelegate(delegateAddress);
        return delegate.tradingPairCutoffs(orderOwner, tokenPair);
    }
}