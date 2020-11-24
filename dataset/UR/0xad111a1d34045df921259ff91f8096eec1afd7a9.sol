 

 
pragma solidity 0.4.18;
 
 
library MathUint {
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function tolerantSub(uint a, uint b) internal pure returns (uint c) {
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
            avg += arr[i];
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
            cvs += mul(s, s);
        }
        return ((mul(mul(cvs, scale), scale) / avg) / avg) / (len - 1);
    }
}
 
 
 
 
 
contract ERC20 {
    uint public totalSupply;
	
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function balanceOf(address who) view public returns (uint256);
    function allowance(address owner, address spender) view public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}
 
 
 
 
contract LoopringProtocol {
     
     
     
    uint8   public constant FEE_SELECT_LRC               = 0;
    uint8   public constant FEE_SELECT_MARGIN_SPLIT      = 1;
    uint8   public constant FEE_SELECT_MAX_VALUE         = 1;
    uint8   public constant MARGIN_SPLIT_PERCENTAGE_BASE = 100;
     
     
     
     
     
     
    event RingMined(
        uint                _ringIndex,
        bytes32     indexed _ringhash,
        address             _miner,
        address             _feeRecipient,
        bool                _isRinghashReserved,
        bytes32[]           _orderHashList,
        uint[4][]           _amountsList
    );
    event OrderCancelled(
        bytes32     indexed _orderHash,
        uint                _amountCancelled
    );
    event CutoffTimestampChanged(
        address     indexed _address,
        uint                _cutoff
    );
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function submitRing(
        address[2][]    addressList,
        uint[7][]       uintArgsList,
        uint8[2][]      uint8ArgsList,
        bool[]          buyNoMoreThanAmountBList,
        uint8[]         vList,
        bytes32[]       rList,
        bytes32[]       sList,
        address         ringminer,
        address         feeRecepient
        ) public;
     
     
     
     
     
     
     
     
     
     
     
     
     
    function cancelOrder(
        address[3] addresses,
        uint[7]    orderValues,
        bool       buyNoMoreThanAmountB,
        uint8      marginSplitPercentage,
        uint8      v,
        bytes32    r,
        bytes32    s
        ) external;
     
     
     
     
     
    function setCutoff(uint cutoff) external;
}
 
 
 
 
 
library MathBytes32 {
    function xorReduce(
        bytes32[]   arr,
        uint        len
        )
        internal
        pure
        returns (bytes32 res)
    {
        res = arr[0];
        for (uint i = 1; i < len; i++) {
            res ^= arr[i];
        }
    }
}
 
 
 
 
library MathUint8 {
    function xorReduce(
        uint8[] arr,
        uint    len
        )
        internal
        pure
        returns (uint8 res)
    {
        res = arr[0];
        for (uint i = 1; i < len; i++) {
            res ^= arr[i];
        }
    }
}
 
 
 
 
contract RinghashRegistry {
    using MathBytes32   for bytes32[];
    using MathUint8     for uint8[];
    uint public blocksToLive;
    struct Submission {
        address ringminer;
        uint block;
    }
    mapping (bytes32 => Submission) submissions;
     
     
     
    event RinghashSubmitted(
        address indexed _ringminer,
        bytes32 indexed _ringhash
    );
     
     
     
    function RinghashRegistry(uint _blocksToLive)
        public
    {
        require(_blocksToLive > 0);
        blocksToLive = _blocksToLive;
    }
     
     
     
    function submitRinghash(
        address     ringminer,
        bytes32     ringhash
        )
        public
    {
        require(canSubmit(ringhash, ringminer));  
        submissions[ringhash] = Submission(ringminer, block.number);
        RinghashSubmitted(ringminer, ringhash);
    }
    function batchSubmitRinghash(
        address[]     ringminerList,
        bytes32[]     ringhashList
        )
        external
    {
        uint size = ringminerList.length;
        require(size > 0);
        require(size == ringhashList.length);
        for (uint i = 0; i < size; i++) {
            submitRinghash(ringminerList[i], ringhashList[i]);
        }
    }
     
    function calculateRinghash(
        uint        ringSize,
        uint8[]     vList,
        bytes32[]   rList,
        bytes32[]   sList
        )
        private
        pure
        returns (bytes32)
    {
        require(
            ringSize == vList.length - 1 && (
            ringSize == rList.length - 1 && (
            ringSize == sList.length - 1))
        );  
        return keccak256(
            vList.xorReduce(ringSize),
            rList.xorReduce(ringSize),
            sList.xorReduce(ringSize)
        );
    }
      
      
    function computeAndGetRinghashInfo(
        uint        ringSize,
        address     ringminer,
        uint8[]     vList,
        bytes32[]   rList,
        bytes32[]   sList
        )
        external
        view
        returns (bytes32 ringhash, bool[2] attributes)
    {
        ringhash = calculateRinghash(
            ringSize,
            vList,
            rList,
            sList
        );
        attributes[0] = canSubmit(ringhash, ringminer);
        attributes[1] = isReserved(ringhash, ringminer);
    }
     
     
    function canSubmit(
        bytes32 ringhash,
        address ringminer)
        public
        view
        returns (bool)
    {
        require(ringminer != 0x0);
        var submission = submissions[ringhash];
        address miner = submission.ringminer;
        return (
            miner == 0x0 || (
            submission.block + blocksToLive < block.number) || (
            miner == ringminer)
        );
    }
     
     
    function isReserved(
        bytes32 ringhash,
        address ringminer)
        public
        view
        returns (bool)
    {
        var submission = submissions[ringhash];
        return (
            submission.block + blocksToLive >= block.number && (
            submission.ringminer == ringminer)
        );
    }
}
 
 
 
 
 
 
 
contract Ownable {
    address public owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
     
     
    function Ownable() public {
        owner = msg.sender;
    }
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
     
     
     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != 0x0);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
 
 
 
contract Claimable is Ownable {
    address public pendingOwner;
     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }
     
     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != 0x0 && newOwner != owner);
        pendingOwner = newOwner;
    }
     
    function claimOwnership() onlyPendingOwner public {
        OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = 0x0;
    }
}
 
 
 
 
contract TokenRegistry is Claimable {
    address[] public tokens;
    mapping (address => bool) tokenMap;
    mapping (string => address) tokenSymbolMap;
    function registerToken(address _token, string _symbol)
        external
        onlyOwner
    {
        require(_token != 0x0);
        require(!isTokenRegisteredBySymbol(_symbol));
        require(!isTokenRegistered(_token));
        tokens.push(_token);
        tokenMap[_token] = true;
        tokenSymbolMap[_symbol] = _token;
    }
    function unregisterToken(address _token, string _symbol)
        external
        onlyOwner
    {
        require(_token != 0x0);
        require(tokenSymbolMap[_symbol] == _token);
        delete tokenSymbolMap[_symbol];
        delete tokenMap[_token];
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == _token) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.length --;
                break;
            }
        }
    }
    function isTokenRegisteredBySymbol(string symbol)
        public
        view
        returns (bool)
    {
        return tokenSymbolMap[symbol] != 0x0;
    }
    function isTokenRegistered(address _token)
        public
        view
        returns (bool)
    {
        return tokenMap[_token];
    }
    function areAllTokensRegistered(address[] tokenList)
        external
        view
        returns (bool)
    {
        for (uint i = 0; i < tokenList.length; i++) {
            if (!tokenMap[tokenList[i]]) {
                return false;
            }
        }
        return true;
    }
    function getAddressBySymbol(string symbol)
        external
        view
        returns (address)
    {
        return tokenSymbolMap[symbol];
    }
}
 
 
 
 
 
contract TokenTransferDelegate is Claimable {
    using MathUint for uint;
     
     
     
    mapping(address => AddressInfo) private addressInfos;
    address public latestAddress;
     
     
     
    struct AddressInfo {
        address previous;
        uint32  index;
        bool    authorized;
    }
     
     
     
    modifier onlyAuthorized() {
        require(addressInfos[msg.sender].authorized);
        _;
    }
     
     
     
    event AddressAuthorized(address indexed addr, uint32 number);
    event AddressDeauthorized(address indexed addr, uint32 number);
     
     
     
     
     
    function authorizeAddress(address addr)
        onlyOwner
        external
    {
        var addrInfo = addressInfos[addr];
        if (addrInfo.index != 0) {  
            if (addrInfo.authorized == false) {  
                addrInfo.authorized = true;
                AddressAuthorized(addr, addrInfo.index);
            }
        } else {
            address prev = latestAddress;
            if (prev == 0x0) {
                addrInfo.index = 1;
                addrInfo.authorized = true;
            } else {
                addrInfo.previous = prev;
                addrInfo.index = addressInfos[prev].index + 1;
            }
            addrInfo.authorized = true;
            latestAddress = addr;
            AddressAuthorized(addr, addrInfo.index);
        }
    }
     
     
    function deauthorizeAddress(address addr)
        onlyOwner
        external
    {
        uint32 index = addressInfos[addr].index;
        if (index != 0) {
            addressInfos[addr].authorized = false;
            AddressDeauthorized(addr, index);
        }
    }
    function isAddressAuthorized(address addr)
        public
        view
        returns (bool)
    {
        return addressInfos[addr].authorized;
    }
    function getLatestAuthorizedAddresses(uint max)
        external
        view
        returns (address[] addresses)
    {
        addresses = new address[](max);
        address addr = latestAddress;
        AddressInfo memory addrInfo;
        uint count = 0;
        while (addr != 0x0 && count < max) {
            addrInfo = addressInfos[addr];
            if (addrInfo.index == 0) {
                break;
            }
            addresses[count++] = addr;
            addr = addrInfo.previous;
        }
    }
     
     
     
     
     
    function transferToken(
        address token,
        address from,
        address to,
        uint    value)
        onlyAuthorized
        external
    {
        if (value > 0 && from != to) {
            require(
                ERC20(token).transferFrom(from, to, value)
            );
        }
    }
    function batchTransferToken(
        address lrcTokenAddress,
        address feeRecipient,
        bytes32[] batch)
        onlyAuthorized
        external
    {
        uint len = batch.length;
        require(len % 6 == 0);
        var lrc = ERC20(lrcTokenAddress);
        for (uint i = 0; i < len; i += 6) {
            address owner = address(batch[i]);
            address prevOwner = address(batch[(i + len - 6) % len]);
            
             
             
            var token = ERC20(address(batch[i + 1]));
             
            if (owner != prevOwner) {
                require(
                    token.transferFrom(owner, prevOwner, uint(batch[i + 2]))
                );
            }
            if (owner != feeRecipient) {
                bytes32 item = batch[i + 3];
                if (item != 0) {
                    require(
                        token.transferFrom(owner, feeRecipient, uint(item))
                    );
                } 
                item = batch[i + 4];
                if (item != 0) {
                    require(
                        lrc.transferFrom(feeRecipient, owner, uint(item))
                    );
                }
                item = batch[i + 5];
                if (item != 0) {
                    require(
                        lrc.transferFrom(owner, feeRecipient, uint(item))
                    );
                }
            }
        }
    }
}
 
 
 
 
 
 
 
 
 
contract LoopringProtocolImpl is LoopringProtocol {
    using MathUint for uint;
     
     
     
    address public  lrcTokenAddress             = 0x0;
    address public  tokenRegistryAddress        = 0x0;
    address public  ringhashRegistryAddress     = 0x0;
    address public  delegateAddress             = 0x0;
    uint    public  maxRingSize                 = 0;
    uint64  public  ringIndex                   = 0;
     
     
     
     
     
     
     
     
     
    uint    public  rateRatioCVSThreshold       = 0;
    uint    public constant RATE_RATIO_SCALE    = 10000;
    uint64  public constant ENTERED_MASK        = 1 << 63;
     
     
    mapping (bytes32 => uint) public cancelledOrFilled;
     
    mapping (address => uint) public cutoffs;
     
     
     
    struct Rate {
        uint amountS;
        uint amountB;
    }
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    struct Order {
        address owner;
        address tokenS;
        address tokenB;
        uint    amountS;
        uint    amountB;
        uint    lrcFee;
        bool    buyNoMoreThanAmountB;
        uint8   marginSplitPercentage;
    }
     
     
     
     
     
     
     
     
     
     
     
     
     
    struct OrderState {
        Order   order;
        bytes32 orderHash;
        uint8   feeSelection;
        Rate    rate;
        uint    fillAmountS;
        uint    lrcReward;
        uint    lrcFee;
        uint    splitS;
        uint    splitB;
    }
     
     
     
    function LoopringProtocolImpl(
        address _lrcTokenAddress,
        address _tokenRegistryAddress,
        address _ringhashRegistryAddress,
        address _delegateAddress,
        uint    _maxRingSize,
        uint    _rateRatioCVSThreshold
        )
        public
    {
        require(0x0 != _lrcTokenAddress);
        require(0x0 != _tokenRegistryAddress);
        require(0x0 != _ringhashRegistryAddress);
        require(0x0 != _delegateAddress);
        require(_maxRingSize > 1);
        require(_rateRatioCVSThreshold > 0);
        lrcTokenAddress = _lrcTokenAddress;
        tokenRegistryAddress = _tokenRegistryAddress;
        ringhashRegistryAddress = _ringhashRegistryAddress;
        delegateAddress = _delegateAddress;
        maxRingSize = _maxRingSize;
        rateRatioCVSThreshold = _rateRatioCVSThreshold;
    }
     
     
     
     
    function ()
        payable
        public
    {
        revert();
    }
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function submitRing(
        address[2][]  addressList,
        uint[7][]     uintArgsList,
        uint8[2][]    uint8ArgsList,
        bool[]        buyNoMoreThanAmountBList,
        uint8[]       vList,
        bytes32[]     rList,
        bytes32[]     sList,
        address       ringminer,
        address       feeRecipient
        )
        public
    {
         
        require(ringIndex & ENTERED_MASK != ENTERED_MASK);  
         
        ringIndex |= ENTERED_MASK;
         
        uint ringSize = addressList.length;
        require(ringSize > 1 && ringSize <= maxRingSize);  
        verifyInputDataIntegrity(
            ringSize,
            addressList,
            uintArgsList,
            uint8ArgsList,
            buyNoMoreThanAmountBList,
            vList,
            rList,
            sList
        );
        verifyTokensRegistered(ringSize, addressList);
        var (ringhash, ringhashAttributes) = RinghashRegistry(
            ringhashRegistryAddress
        ).computeAndGetRinghashInfo(
            ringSize,
            ringminer,
            vList,
            rList,
            sList
        );
         
        require(ringhashAttributes[0]);  
        verifySignature(
            ringminer,
            ringhash,
            vList[ringSize],
            rList[ringSize],
            sList[ringSize]
        );
         
        var orders = assembleOrders(
            addressList,
            uintArgsList,
            uint8ArgsList,
            buyNoMoreThanAmountBList,
            vList,
            rList,
            sList
        );
        if (feeRecipient == 0x0) {
            feeRecipient = ringminer;
        }
        handleRing(
            ringSize,
            ringhash,
            orders,
            ringminer,
            feeRecipient,
            ringhashAttributes[1]
        );
        ringIndex = (ringIndex ^ ENTERED_MASK) + 1;
    }
     
     
     
     
     
     
     
     
     
     
     
     
     
    function cancelOrder(
        address[3] addresses,
        uint[7]    orderValues,
        bool       buyNoMoreThanAmountB,
        uint8      marginSplitPercentage,
        uint8      v,
        bytes32    r,
        bytes32    s
        )
        external
    {
        uint cancelAmount = orderValues[6];
        require(cancelAmount > 0);  
        var order = Order(
            addresses[0],
            addresses[1],
            addresses[2],
            orderValues[0],
            orderValues[1],
            orderValues[5],
            buyNoMoreThanAmountB,
            marginSplitPercentage
        );
        require(msg.sender == order.owner);  
        bytes32 orderHash = calculateOrderHash(
            order,
            orderValues[2],  
            orderValues[3],  
            orderValues[4]   
        );
        verifySignature(
            order.owner,
            orderHash,
            v,
            r,
            s
        );
        cancelledOrFilled[orderHash] = cancelledOrFilled[orderHash].add(cancelAmount);
        OrderCancelled(orderHash, cancelAmount);
    }
     
     
     
     
     
    function setCutoff(uint cutoff)
        external
    {
        uint t = (cutoff == 0 || cutoff >= block.timestamp) ? block.timestamp : cutoff;
        require(cutoffs[msg.sender] < t);  
        cutoffs[msg.sender] = t;
        CutoffTimestampChanged(msg.sender, t);
    }
     
     
     
     
    function verifyRingHasNoSubRing(
        uint          ringSize,
        OrderState[]  orders
        )
        private
        pure
    {
         
        for (uint i = 0; i < ringSize - 1; i++) {
            address tokenS = orders[i].order.tokenS;
            for (uint j = i + 1; j < ringSize; j++) {
                require(tokenS != orders[j].order.tokenS);  
            }
        }
    }
    function verifyTokensRegistered(
        uint          ringSize,
        address[2][]  addressList
        )
        private
        view
    {
         
        var tokens = new address[](ringSize);
        for (uint i = 0; i < ringSize; i++) {
            tokens[i] = addressList[i][1];
        }
         
        require(
            TokenRegistry(tokenRegistryAddress).areAllTokensRegistered(tokens)
        );  
    }
    function handleRing(
        uint          ringSize,
        bytes32       ringhash,
        OrderState[]  orders,
        address       miner,
        address       feeRecipient,
        bool          isRinghashReserved
        )
        private
    {
        uint64 _ringIndex = ringIndex ^ ENTERED_MASK;
        address _lrcTokenAddress = lrcTokenAddress;
        var delegate = TokenTransferDelegate(delegateAddress);
                
         
        verifyRingHasNoSubRing(ringSize, orders);
         
         
         
        verifyMinerSuppliedFillRates(ringSize, orders);
         
         
         
        scaleRingBasedOnHistoricalRecords(delegate, ringSize, orders);
         
         
         
         
        calculateRingFillAmount(ringSize, orders);
         
         
         
        calculateRingFees(
            delegate,
            ringSize,
            orders,
            feeRecipient,
            _lrcTokenAddress
        );
         
        var (orderHashList, amountsList) = settleRing(
            delegate,
            ringSize,
            orders,
            feeRecipient,
            _lrcTokenAddress
        );
        RingMined(
            _ringIndex,
            ringhash,
            miner,
            feeRecipient,
            isRinghashReserved,
            orderHashList,
            amountsList
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
        returns(
        bytes32[] memory orderHashList,
        uint[4][] memory amountsList)
    {
        bytes32[] memory batch = new bytes32[](ringSize * 6);  
        orderHashList = new bytes32[](ringSize);
        amountsList = new uint[4][](ringSize);
        uint p = 0;
        for (uint i = 0; i < ringSize; i++) {
            var state = orders[i];
            var order = state.order;
            uint prevSplitB = orders[(i + ringSize - 1) % ringSize].splitB;
            uint nextFillAmountS = orders[(i + 1) % ringSize].fillAmountS;
             
            batch[p] = bytes32(order.owner);
            batch[p+1] = bytes32(order.tokenS);
             
            batch[p+2] = bytes32(state.fillAmountS - prevSplitB);
            batch[p+3] = bytes32(prevSplitB + state.splitS);
            batch[p+4] = bytes32(state.lrcReward);
            batch[p+5] = bytes32(state.lrcFee);
            p += 6;
             
            if (order.buyNoMoreThanAmountB) {
                cancelledOrFilled[state.orderHash] += nextFillAmountS;
            } else {
                cancelledOrFilled[state.orderHash] += state.fillAmountS;
            }
            orderHashList[i] = state.orderHash;
            amountsList[i][0] = state.fillAmountS + state.splitS;
            amountsList[i][1] = nextFillAmountS - state.splitB;
            amountsList[i][2] = state.lrcReward;
            amountsList[i][3] = state.lrcFee;
        }
         
        delegate.batchTransferToken(_lrcTokenAddress, feeRecipient, batch);
    }
     
    function verifyMinerSuppliedFillRates(
        uint          ringSize,
        OrderState[]  orders
        )
        private
        view
    {
        var rateRatios = new uint[](ringSize);
        uint _rateRatioScale = RATE_RATIO_SCALE;
        for (uint i = 0; i < ringSize; i++) {
            uint s1b0 = orders[i].rate.amountS.mul(orders[i].order.amountB);
            uint s0b1 = orders[i].order.amountS.mul(orders[i].rate.amountB);
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
        address         feeRecipient,
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
            var state = orders[i];
            uint lrcReceiable = 0;
            if (state.lrcFee == 0) {
                 
                 
                state.feeSelection = FEE_SELECT_MARGIN_SPLIT;
                state.order.marginSplitPercentage = _marginSplitPercentageBase;
            } else {
                uint lrcSpendable = getSpendable(
                    delegate,
                    _lrcTokenAddress,
                    state.order.owner
                );
                 
                 
                if (state.order.tokenS == _lrcTokenAddress) {
                    lrcSpendable -= state.fillAmountS;
                }
                 
                if (state.order.tokenB == _lrcTokenAddress) {
                    nextFillAmountS = orders[(i + 1) % ringSize].fillAmountS;
                    lrcReceiable = nextFillAmountS;
                }
                uint lrcTotal = lrcSpendable + lrcReceiable;
                 
                if (lrcTotal < state.lrcFee) {
                    state.lrcFee = lrcTotal;
                    state.order.marginSplitPercentage = _marginSplitPercentageBase;
                }
                if (state.lrcFee == 0) {
                    state.feeSelection = FEE_SELECT_MARGIN_SPLIT;
                }
            }
            if (state.feeSelection == FEE_SELECT_LRC) {
                if (lrcReceiable > 0) {
                    if (lrcReceiable >= state.lrcFee) {
                        state.splitB = state.lrcFee;
                        state.lrcFee = 0;
                    } else {
                        state.splitB = lrcReceiable;
                        state.lrcFee -= lrcReceiable;
                    }
                }
            } else if (state.feeSelection == FEE_SELECT_MARGIN_SPLIT) {
                 
                if (!checkedMinerLrcSpendable && minerLrcSpendable < state.lrcFee) {
                    checkedMinerLrcSpendable = true;
                    minerLrcSpendable = getSpendable(delegate, _lrcTokenAddress, feeRecipient);
                }
                 
                 
                if (minerLrcSpendable >= state.lrcFee) {
                    nextFillAmountS = orders[(i + 1) % ringSize].fillAmountS;
                    uint split;
                    if (state.order.buyNoMoreThanAmountB) {
                        split = (nextFillAmountS.mul(
                            state.order.amountS
                        ) / state.order.amountB).sub(
                            state.fillAmountS
                        );
                    } else {
                        split = nextFillAmountS.sub(
                            state.fillAmountS.mul(
                                state.order.amountB
                            ) / state.order.amountS
                        );
                    }
                    if (state.order.marginSplitPercentage != _marginSplitPercentageBase) {
                        split = split.mul(
                            state.order.marginSplitPercentage
                        ) / _marginSplitPercentageBase;
                    }
                    if (state.order.buyNoMoreThanAmountB) {
                        state.splitS = split;
                    } else {
                        state.splitB = split;
                    }
                     
                     
                     
                    if (split > 0) {
                        minerLrcSpendable -= state.lrcFee;
                        state.lrcReward = state.lrcFee;
                    }
                }
                state.lrcFee = 0;
            } else {
                revert();  
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
        OrderState        state,
        OrderState        next,
        uint              i,
        uint              j,
        uint              smallestIdx
        )
        private
        pure
        returns (uint newSmallestIdx)
    {
         
        newSmallestIdx = smallestIdx;
        uint fillAmountB = state.fillAmountS.mul(
            state.rate.amountB
        ) / state.rate.amountS;
        if (state.order.buyNoMoreThanAmountB) {
            if (fillAmountB > state.order.amountB) {
                fillAmountB = state.order.amountB;
                state.fillAmountS = fillAmountB.mul(
                    state.rate.amountS
                ) / state.rate.amountB;
                newSmallestIdx = i;
            }
            state.lrcFee = state.order.lrcFee.mul(
                fillAmountB
            ) / state.order.amountB;
        } else {
            state.lrcFee = state.order.lrcFee.mul(
                state.fillAmountS
            ) / state.order.amountS;
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
            var state = orders[i];
            var order = state.order;
            uint amount;
            if (order.buyNoMoreThanAmountB) {
                amount = order.amountB.tolerantSub(
                    cancelledOrFilled[state.orderHash]
                );
                order.amountS = amount.mul(order.amountS) / order.amountB;
                order.lrcFee = amount.mul(order.lrcFee) / order.amountB;
                order.amountB = amount;
            } else {
                amount = order.amountS.tolerantSub(
                    cancelledOrFilled[state.orderHash]
                );
                order.amountB = amount.mul(order.amountB) / order.amountS;
                order.lrcFee = amount.mul(order.lrcFee) / order.amountS;
                order.amountS = amount;
            }
            require(order.amountS > 0);  
            require(order.amountB > 0);  
            
            uint availableAmountS = getSpendable(delegate, order.tokenS, order.owner);
            require(availableAmountS > 0);  
            state.fillAmountS = (
                order.amountS < availableAmountS ?
                order.amountS : availableAmountS
            );
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
        var token = ERC20(tokenAddress);
        uint allowance = token.allowance(
            tokenOwner,
            address(delegate)
        );
        uint balance = token.balanceOf(tokenOwner);
        return (allowance < balance ? allowance : balance);
    }
     
    function verifyInputDataIntegrity(
        uint          ringSize,
        address[2][]  addressList,
        uint[7][]     uintArgsList,
        uint8[2][]    uint8ArgsList,
        bool[]        buyNoMoreThanAmountBList,
        uint8[]       vList,
        bytes32[]     rList,
        bytes32[]     sList
        )
        private
        pure
    {
        require(ringSize == addressList.length);  
        require(ringSize == uintArgsList.length);  
        require(ringSize == uint8ArgsList.length);  
        require(ringSize == buyNoMoreThanAmountBList.length);  
        require(ringSize + 1 == vList.length);  
        require(ringSize + 1 == rList.length);  
        require(ringSize + 1 == sList.length);  
         
        for (uint i = 0; i < ringSize; i++) {
            require(uintArgsList[i][6] > 0);  
            require(uint8ArgsList[i][1] <= FEE_SELECT_MAX_VALUE);  
        }
    }
     
     
    function assembleOrders(
        address[2][]    addressList,
        uint[7][]       uintArgsList,
        uint8[2][]      uint8ArgsList,
        bool[]          buyNoMoreThanAmountBList,
        uint8[]         vList,
        bytes32[]       rList,
        bytes32[]       sList
        )
        private
        view
        returns (OrderState[] orders)
    {
        uint ringSize = addressList.length;
        orders = new OrderState[](ringSize);
        for (uint i = 0; i < ringSize; i++) {
            var uintArgs = uintArgsList[i];
        
            var order = Order(
                addressList[i][0],
                addressList[i][1],
                addressList[(i + 1) % ringSize][1],
                uintArgs[0],
                uintArgs[1],
                uintArgs[5],
                buyNoMoreThanAmountBList[i],
                uint8ArgsList[i][0]
            );
            bytes32 orderHash = calculateOrderHash(
                order,
                uintArgs[2],  
                uintArgs[3],  
                uintArgs[4]   
            );
            verifySignature(
                order.owner,
                orderHash,
                vList[i],
                rList[i],
                sList[i]
            );
            validateOrder(
                order,
                uintArgs[2],  
                uintArgs[3],  
                uintArgs[4]   
            );
            orders[i] = OrderState(
                order,
                orderHash,
                uint8ArgsList[i][1],   
                Rate(uintArgs[6], order.amountB),
                0,    
                0,    
                0,    
                0,    
                0     
            );
        }
    }
     
    function validateOrder(
        Order        order,
        uint         timestamp,
        uint         ttl,
        uint         salt
        )
        private
        view
    {
        require(order.owner != 0x0);  
        require(order.tokenS != 0x0);  
        require(order.tokenB != 0x0);  
        require(order.amountS != 0);  
        require(order.amountB != 0);  
        require(timestamp <= block.timestamp);  
        require(timestamp > cutoffs[order.owner]);  
        require(ttl != 0);  
        require(timestamp + ttl > block.timestamp);  
        require(salt != 0);  
        require(order.marginSplitPercentage <= MARGIN_SPLIT_PERCENTAGE_BASE);  
    }
     
    function calculateOrderHash(
        Order        order,
        uint         timestamp,
        uint         ttl,
        uint         salt
        )
        private
        view
        returns (bytes32)
    {
        return keccak256(
            address(this),
            order.owner,
            order.tokenS,
            order.tokenB,
            order.amountS,
            order.amountB,
            timestamp,
            ttl,
            salt,
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
}