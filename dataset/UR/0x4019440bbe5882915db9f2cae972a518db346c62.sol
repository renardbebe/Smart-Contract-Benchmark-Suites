 

 
pragma solidity 0.4.21;
 
 
 
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
 
 
 
library AddressUtil {
    function isContract(address addr)
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
    function balanceOf(address who) view public returns (uint256);
    function allowance(address owner, address spender) view public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}
 
 
 
 
contract LoopringProtocol {
     
     
     
    uint8   public constant MARGIN_SPLIT_PERCENTAGE_BASE = 100;
     
     
     
     
     
     
    event RingMined(
        uint                _ringIndex,
        bytes32     indexed _ringHash,
        address             _miner,
        address             _feeRecipient,
        bytes32[]           _orderHashList,
        uint[6][]           _amountsList
    );
    event OrderCancelled(
        bytes32     indexed _orderHash,
        uint                _amountCancelled
    );
    event AllOrdersCancelled(
        address     indexed _address,
        uint                _cutoff
    );
    event OrdersCancelled(
        address     indexed _address,
        address             _token1,
        address             _token2,
        uint                _cutoff
    );
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function cancelOrder(
        address[4] addresses,
        uint[7]    orderValues,
        bool       buyNoMoreThanAmountB,
        uint8      marginSplitPercentage,
        uint8      v,
        bytes32    r,
        bytes32    s
        ) external;
     
     
     
     
     
    function cancelAllOrdersByTradingPair(
        address token1,
        address token2,
        uint cutoff
        ) external;
     
     
     
     
     
    function cancelAllOrders(uint cutoff) external;
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function submitRing(
        address[3][]    addressList,
        uint[7][]       uintArgsList,
        uint8[1][]      uint8ArgsList,
        bool[]          buyNoMoreThanAmountBList,
        uint8[]         vList,
        bytes32[]       rList,
        bytes32[]       sList,
        uint            minerId,
        uint16          feeSelections
        ) public;
}
 
 
 
 
 
contract NameRegistry {
    uint public nextId = 0;
    mapping (uint    => Participant) public participantMap;
    mapping (address => NameInfo)    public nameInfoMap;
    mapping (bytes12 => address)     public ownerMap;
    mapping (address => string)      public nameMap;
    struct NameInfo {
        bytes12  name;
        uint[]   participantIds;
    }
    struct Participant {
        address feeRecipient;
        address signer;
        bytes12 name;
        address owner;
    }
    event NameRegistered (
        string            name,
        address   indexed owner
    );
    event NameUnregistered (
        string             name,
        address    indexed owner
    );
    event OwnershipTransfered (
        bytes12            name,
        address            oldOwner,
        address            newOwner
    );
    event ParticipantRegistered (
        bytes12           name,
        address   indexed owner,
        uint      indexed participantId,
        address           singer,
        address           feeRecipient
    );
    event ParticipantUnregistered (
        uint    participantId,
        address owner
    );
    function registerName(string name)
        external
    {
        require(isNameValid(name));
        bytes12 nameBytes = stringToBytes12(name);
        require(ownerMap[nameBytes] == 0x0);
        require(stringToBytes12(nameMap[msg.sender]) == bytes12(0x0));
        nameInfoMap[msg.sender] = NameInfo(nameBytes, new uint[](0));
        ownerMap[nameBytes] = msg.sender;
        nameMap[msg.sender] = name;
        emit NameRegistered(name, msg.sender);
    }
    function unregisterName(string name)
        external
    {
        NameInfo storage nameInfo = nameInfoMap[msg.sender];
        uint[] storage participantIds = nameInfo.participantIds;
        bytes12 nameBytes = stringToBytes12(name);
        require(nameInfo.name == nameBytes);
        for (uint i = 0; i < participantIds.length; i++) {
            delete participantMap[participantIds[i]];
        }
        delete nameInfoMap[msg.sender];
        delete nameMap[msg.sender];
        delete ownerMap[nameBytes];
        emit NameUnregistered(name, msg.sender);
    }
    function transferOwnership(address newOwner)
        external
    {
        require(newOwner != 0x0);
        require(nameInfoMap[newOwner].name.length == 0);
        NameInfo storage nameInfo = nameInfoMap[msg.sender];
        string storage name = nameMap[msg.sender];
        uint[] memory participantIds = nameInfo.participantIds;
        for (uint i = 0; i < participantIds.length; i ++) {
            Participant storage p = participantMap[participantIds[i]];
            p.owner = newOwner;
        }
        delete nameInfoMap[msg.sender];
        delete nameMap[msg.sender];
        nameInfoMap[newOwner] = nameInfo;
        nameMap[newOwner] = name;
        emit OwnershipTransfered(nameInfo.name, msg.sender, newOwner);
    }
     
     
     
     
     
     
    function addParticipant(
        address feeRecipient,
        address singer
        )
        external
        returns (uint)
    {
        require(feeRecipient != 0x0 && singer != 0x0);
        NameInfo storage nameInfo = nameInfoMap[msg.sender];
        bytes12 name = nameInfo.name;
        require(name.length > 0);
        Participant memory participant = Participant(
            feeRecipient,
            singer,
            name,
            msg.sender
        );
        uint participantId = ++nextId;
        participantMap[participantId] = participant;
        nameInfo.participantIds.push(participantId);
        emit ParticipantRegistered(
            name,
            msg.sender,
            participantId,
            singer,
            feeRecipient
        );
        return participantId;
    }
    function removeParticipant(uint participantId)
        external
    {
        require(msg.sender == participantMap[participantId].owner);
        NameInfo storage nameInfo = nameInfoMap[msg.sender];
        uint[] storage participantIds = nameInfo.participantIds;
        delete participantMap[participantId];
        uint len = participantIds.length;
        for (uint i = 0; i < len; i ++) {
            if (participantId == participantIds[i]) {
                participantIds[i] = participantIds[len - 1];
                participantIds.length -= 1;
            }
        }
        emit ParticipantUnregistered(participantId, msg.sender);
    }
    function getParticipantById(uint id)
        external
        view
        returns (address feeRecipient, address signer)
    {
        Participant storage addressSet = participantMap[id];
        feeRecipient = addressSet.feeRecipient;
        signer = addressSet.signer;
    }
    function getFeeRecipientById(uint id)
        external
        view
        returns (address feeRecipient)
    {
        Participant storage addressSet = participantMap[id];
        feeRecipient = addressSet.feeRecipient;
    }
    function getParticipantIds(string name, uint start, uint count)
        external
        view
        returns (uint[] idList)
    {
        bytes12 nameBytes = stringToBytes12(name);
        address owner = ownerMap[nameBytes];
        require(owner != 0x0);
        NameInfo storage nameInfo = nameInfoMap[owner];
        uint[] storage pIds = nameInfo.participantIds;
        uint len = pIds.length;
        if (start >= len) {
            return;
        }
        uint end = start + count;
        if (end > len) {
            end = len;
        }
        if (start == end) {
            return;
        }
        idList = new uint[](end - start);
        for (uint i = start; i < end; i ++) {
            idList[i - start] = pIds[i];
        }
    }
    function getOwner(string name)
        external
        view
        returns (address)
    {
        bytes12 nameBytes = stringToBytes12(name);
        return ownerMap[nameBytes];
    }
    function isNameValid(string name)
        internal
        pure
        returns (bool)
    {
        bytes memory temp = bytes(name);
        return temp.length >= 6 && temp.length <= 12;
    }
    function stringToBytes12(string str)
        internal
        pure
        returns (bytes12 result)
    {
        assembly {
            result := mload(add(str, 32))
        }
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
        emit OwnershipTransferred(owner, newOwner);
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
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = 0x0;
    }
}
 
 
 
 
contract TokenRegistry is Claimable {
    using AddressUtil for address;
    address tokenMintAddr;
    address[] public addresses;
    mapping (address => TokenInfo) addressMap;
    mapping (string => address) symbolMap;
     
     
     
    struct TokenInfo {
        uint   pos;       
                          
        string symbol;    
    }
     
     
     
    event TokenRegistered(address addr, string symbol);
    event TokenUnregistered(address addr, string symbol);
     
     
     
     
    function () payable public {
        revert();
    }
    function TokenRegistry(address _tokenMintAddr) public
    {
        require(_tokenMintAddr.isContract());
        tokenMintAddr = _tokenMintAddr;
    }
    function registerToken(
        address addr,
        string  symbol
        )
        external
        onlyOwner
    {
        registerTokenInternal(addr, symbol);
    }
    function registerMintedToken(
        address addr,
        string  symbol
        )
        external
    {
        require(msg.sender == tokenMintAddr);
        registerTokenInternal(addr, symbol);
    }
    function unregisterToken(
        address addr,
        string  symbol
        )
        external
        onlyOwner
    {
        require(addr != 0x0);
        require(symbolMap[symbol] == addr);
        delete symbolMap[symbol];
        uint pos = addressMap[addr].pos;
        require(pos != 0);
        delete addressMap[addr];
         
         
        address lastToken = addresses[addresses.length - 1];
         
        if (addr != lastToken) {
             
            addresses[pos - 1] = lastToken;
            addressMap[lastToken].pos = pos;
        }
        addresses.length--;
        emit TokenUnregistered(addr, symbol);
    }
    function areAllTokensRegistered(address[] addressList)
        external
        view
        returns (bool)
    {
        for (uint i = 0; i < addressList.length; i++) {
            if (addressMap[addressList[i]].pos == 0) {
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
        return symbolMap[symbol];
    }
    function isTokenRegisteredBySymbol(string symbol)
        public
        view
        returns (bool)
    {
        return symbolMap[symbol] != 0x0;
    }
    function isTokenRegistered(address addr)
        public
        view
        returns (bool)
    {
        return addressMap[addr].pos != 0;
    }
    function getTokens(
        uint start,
        uint count
        )
        public
        view
        returns (address[] addressList)
    {
        uint num = addresses.length;
        if (start >= num) {
            return;
        }
        uint end = start + count;
        if (end > num) {
            end = num;
        }
        if (start == num) {
            return;
        }
        addressList = new address[](end - start);
        for (uint i = start; i < end; i++) {
            addressList[i - start] = addresses[i];
        }
    }
    function registerTokenInternal(
        address addr,
        string  symbol
        )
        internal
    {
        require(0x0 != addr);
        require(bytes(symbol).length > 0);
        require(0x0 == symbolMap[symbol]);
        require(0 == addressMap[addr].pos);
        addresses.push(addr);
        symbolMap[symbol] = addr;
        addressMap[addr] = TokenInfo(addresses.length, symbol);
        emit TokenRegistered(addr, symbol);
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
     
     
     
     
    function () payable public {
        revert();
    }
     
     
    function authorizeAddress(address addr)
        onlyOwner
        external
    {
        AddressInfo storage addrInfo = addressInfos[addr];
        if (addrInfo.index != 0) {  
            if (addrInfo.authorized == false) {  
                addrInfo.authorized = true;
                emit AddressAuthorized(addr, addrInfo.index);
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
            emit AddressAuthorized(addr, addrInfo.index);
        }
    }
     
     
    function deauthorizeAddress(address addr)
        onlyOwner
        external
    {
        uint32 index = addressInfos[addr].index;
        if (index != 0) {
            addressInfos[addr].authorized = false;
            emit AddressDeauthorized(addr, index);
        }
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
        if (value > 0 && from != to && to != 0x0) {
            require(
                ERC20(token).transferFrom(from, to, value)
            );
        }
    }
    function batchTransferToken(
        address lrcTokenAddress,
        address minerFeeRecipient,
        uint8 walletSplitPercentage,
        bytes32[] batch)
        onlyAuthorized
        external
    {
        uint len = batch.length;
        require(len % 7 == 0);
        require(walletSplitPercentage > 0 && walletSplitPercentage < 100);
        ERC20 lrc = ERC20(lrcTokenAddress);
        for (uint i = 0; i < len; i += 7) {
            address owner = address(batch[i]);
            address prevOwner = address(batch[(i + len - 7) % len]);
             
             
            ERC20 token = ERC20(address(batch[i + 1]));
             
            if (owner != prevOwner) {
                require(
                    token.transferFrom(
                        owner,
                        prevOwner,
                        uint(batch[i + 2])
                    )
                );
            }
             
            uint lrcReward = uint(batch[i + 4]);
            if (lrcReward != 0 && minerFeeRecipient != owner) {
                require(
                    lrc.transferFrom(
                        minerFeeRecipient,
                        owner,
                        lrcReward
                    )
                );
            }
             
            splitPayFee(
                token,
                uint(batch[i + 3]),
                owner,
                minerFeeRecipient,
                address(batch[i + 6]),
                walletSplitPercentage
            );
             
            splitPayFee(
                lrc,
                uint(batch[i + 5]),
                owner,
                minerFeeRecipient,
                address(batch[i + 6]),
                walletSplitPercentage
            );
        }
    }
    function isAddressAuthorized(address addr)
        public
        view
        returns (bool)
    {
        return addressInfos[addr].authorized;
    }
    function splitPayFee(
        ERC20   token,
        uint    fee,
        address owner,
        address minerFeeRecipient,
        address walletFeeRecipient,
        uint    walletSplitPercentage
        )
        internal
    {
        if (fee == 0) {
            return;
        }
        uint walletFee = (walletFeeRecipient == 0x0) ? 0 : fee.mul(walletSplitPercentage) / 100;
        uint minerFee = fee - walletFee;
        if (walletFee > 0 && walletFeeRecipient != owner) {
            require(
                token.transferFrom(
                    owner,
                    walletFeeRecipient,
                    walletFee
                )
            );
        }
        if (minerFee > 0 && minerFeeRecipient != 0x0 && minerFeeRecipient != owner) {
            require(
                token.transferFrom(
                    owner,
                    minerFeeRecipient,
                    minerFee
                )
            );
        }
    }
}
 
 
 
 
 
 
 
 
 
contract LoopringProtocolImpl is LoopringProtocol {
    using AddressUtil   for address;
    using MathBytes32   for bytes32[];
    using MathUint      for uint;
    using MathUint8     for uint8[];
     
     
     
    address public  lrcTokenAddress             = 0xEF68e7C694F40c8202821eDF525dE3782458639f;
    address public  tokenRegistryAddress        = 0xaD3407deDc56A1F69389Edc191b770F0c935Ea37;
    address public  delegateAddress             = 0x7b126ab811f278f288bf1d62d47334351dA20d1d;
    address public  nameRegistryAddress         = 0xC897816C1A6DB4A2923b7D75d9B812e2f62cF504;
    uint64  public  ringIndex                   = 0;
    uint8   public  walletSplitPercentage       = 20;
     
     
     
     
     
     
     
     
     
    uint    public constant rateRatioCVSThreshold        = 62500;

    uint    public constant MAX_RING_SIZE       = 16;
    uint    public constant RATE_RATIO_SCALE    = 10000;
    uint64  public constant ENTERED_MASK        = 1 << 63;
     
     
    mapping (bytes32 => uint) public cancelledOrFilled;
     
    mapping (bytes32 => uint) public cancelled;
     
    mapping (address => uint) public cutoffs;
     
    mapping (address => mapping (bytes20 => uint)) public tradingPairCutoffs;
     
     
     
    struct Rate {
        uint amountS;
        uint amountB;
    }
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    struct Order {
        address owner;
        address tokenS;
        address tokenB;
        address authAddr;
        uint    validSince;
        uint    validUntil;
        uint    amountS;
        uint    amountB;
        uint    lrcFee;
        bool    buyNoMoreThanAmountB;
        uint    walletId;
        uint8   marginSplitPercentage;
    }
     
     
     
     
     
     
     
     
     
     
     
     
     
    struct OrderState {
        Order   order;
        bytes32 orderHash;
        bool    marginSplitAsFee;
        Rate    rate;
        uint    fillAmountS;
        uint    lrcReward;
        uint    lrcFee;
        uint    splitS;
        uint    splitB;
    }
     
     
    struct RingParams {
        address[3][]  addressList;
        uint[7][]     uintArgsList;
        uint8[1][]    uint8ArgsList;
        bool[]        buyNoMoreThanAmountBList;
        uint8[]       vList;
        bytes32[]     rList;
        bytes32[]     sList;
        uint          minerId;
        uint          ringSize;          
        uint16        feeSelections;
        address       ringMiner;         
        address       feeRecipient;      
        bytes32       ringHash;          
    }
     
     
     

     
     
     
     
    function () payable public {
        revert();
    }
    function cancelOrder(
        address[4] addresses,
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
        Order memory order = Order(
            addresses[0],
            addresses[1],
            addresses[2],
            addresses[3],
            orderValues[2],
            orderValues[3],
            orderValues[0],
            orderValues[1],
            orderValues[4],
            buyNoMoreThanAmountB,
            orderValues[5],
            marginSplitPercentage
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
        cancelled[orderHash] = cancelled[orderHash].add(cancelAmount);
        cancelledOrFilled[orderHash] = cancelledOrFilled[orderHash].add(cancelAmount);
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
        require(tradingPairCutoffs[msg.sender][tokenPair] < t);  
        tradingPairCutoffs[msg.sender][tokenPair] = t;
        emit OrdersCancelled(
            msg.sender,
            token1,
            token2,
            t
        );
    }
    function cancelAllOrders(uint cutoff)
        external
    {
        uint t = (cutoff == 0 || cutoff >= block.timestamp) ? block.timestamp : cutoff;
        require(cutoffs[msg.sender] < t);  
        cutoffs[msg.sender] = t;
        emit AllOrdersCancelled(msg.sender, t);
    }
    function submitRing(
        address[3][]  addressList,
        uint[7][]     uintArgsList,
        uint8[1][]    uint8ArgsList,
        bool[]        buyNoMoreThanAmountBList,
        uint8[]       vList,
        bytes32[]     rList,
        bytes32[]     sList,
        uint          minerId,
        uint16        feeSelections
        )
        public
    {
         
        require(ringIndex & ENTERED_MASK != ENTERED_MASK);  
         
        ringIndex |= ENTERED_MASK;
        RingParams memory params = RingParams(
            addressList,
            uintArgsList,
            uint8ArgsList,
            buyNoMoreThanAmountBList,
            vList,
            rList,
            sList,
            minerId,
            addressList.length,
            feeSelections,
            0x0,         
            0x0,         
            0x0          
        );
        verifyInputDataIntegrity(params);
        updateFeeRecipient(params);
         
         
         
        OrderState[] memory orders = assembleOrders(params);
        verifyRingSignatures(params);
        verifyTokensRegistered(params);
        handleRing(params, orders);
        ringIndex = (ringIndex ^ ENTERED_MASK) + 1;
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
     
     
    function verifyRingSignatures(RingParams params)
        private
        pure
    {
        uint j;
        for (uint i = 0; i < params.ringSize; i++) {
            j = i + params.ringSize;
            verifySignature(
                params.addressList[i][2],   
                params.ringHash,
                params.vList[j],
                params.rList[j],
                params.sList[j]
            );
        }
        if (params.ringMiner != 0x0) {
            j++;
            verifySignature(
                params.ringMiner,
                params.ringHash,
                params.vList[j],
                params.rList[j],
                params.sList[j]
            );
        }
    }
    function verifyTokensRegistered(RingParams params)
        private
        view
    {
         
        address[] memory tokens = new address[](params.ringSize);
        for (uint i = 0; i < params.ringSize; i++) {
            tokens[i] = params.addressList[i][1];
        }
         
        require(
            TokenRegistry(tokenRegistryAddress).areAllTokensRegistered(tokens)
        );  
    }
    function updateFeeRecipient(RingParams params)
        private
        view
    {
        if (params.minerId == 0) {
            params.feeRecipient = msg.sender;
        } else {
            (params.feeRecipient, params.ringMiner) = NameRegistry(
                nameRegistryAddress
            ).getParticipantById(
                params.minerId
            );
            if (params.feeRecipient == 0x0) {
                params.feeRecipient = msg.sender;
            }
        }
        uint sigSize = params.ringSize * 2;
        if (params.ringMiner != 0x0) {
            sigSize += 1;
        }
        require(sigSize == params.vList.length);  
        require(sigSize == params.rList.length);  
        require(sigSize == params.sList.length);  
    }
    function handleRing(
        RingParams    params,
        OrderState[]  orders
        )
        private
    {
        uint64 _ringIndex = ringIndex ^ ENTERED_MASK;
        address _lrcTokenAddress = lrcTokenAddress;
        TokenTransferDelegate delegate = TokenTransferDelegate(delegateAddress);
         
        verifyRingHasNoSubRing(params.ringSize, orders);
         
         
         
        verifyMinerSuppliedFillRates(params.ringSize, orders);
         
         
         
        scaleRingBasedOnHistoricalRecords(delegate, params.ringSize, orders);
         
         
         
         
        calculateRingFillAmount(params.ringSize, orders);
         
         
         
        calculateRingFees(
            delegate,
            params.ringSize,
            orders,
            params.feeRecipient,
            _lrcTokenAddress
        );
         
        bytes32[] memory orderHashList;
        uint[6][] memory amountsList;
        (orderHashList, amountsList) = settleRing(
            delegate,
            params.ringSize,
            orders,
            params.feeRecipient,
            _lrcTokenAddress
        );
        emit RingMined(
            _ringIndex,
            params.ringHash,
            params.ringMiner,
            params.feeRecipient,
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
        returns (
        bytes32[] memory orderHashList,
        uint[6][] memory amountsList)
    {
        bytes32[] memory batch = new bytes32[](ringSize * 7);  
        orderHashList = new bytes32[](ringSize);
        amountsList = new uint[6][](ringSize);
        uint p = 0;
        for (uint i = 0; i < ringSize; i++) {
            OrderState memory state = orders[i];
            Order memory order = state.order;
            uint prevSplitB = orders[(i + ringSize - 1) % ringSize].splitB;
            uint nextFillAmountS = orders[(i + 1) % ringSize].fillAmountS;
             
            batch[p] = bytes32(order.owner);
            batch[p + 1] = bytes32(order.tokenS);
             
            batch[p + 2] = bytes32(state.fillAmountS - prevSplitB);
            batch[p + 3] = bytes32(prevSplitB + state.splitS);
            batch[p + 4] = bytes32(state.lrcReward);
            batch[p + 5] = bytes32(state.lrcFee);
            if (order.walletId != 0) {
                batch[p + 6] = bytes32(NameRegistry(nameRegistryAddress).getFeeRecipientById(order.walletId));
            } else {
                batch[p + 6] = bytes32(0x0);
            }
            p += 7;
             
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
            amountsList[i][4] = state.splitS;
            amountsList[i][5] = state.splitB;
        }
         
        delegate.batchTransferToken(
            _lrcTokenAddress,
            feeRecipient,
            walletSplitPercentage,
            batch
        );
    }
     
    function verifyMinerSuppliedFillRates(
        uint          ringSize,
        OrderState[]  orders
        )
        private
        view
    {
        uint[] memory rateRatios = new uint[](ringSize);
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
            OrderState memory state = orders[i];
            uint lrcReceiable = 0;
            if (state.lrcFee == 0) {
                 
                 
                state.marginSplitAsFee = true;
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
                    state.marginSplitAsFee = true;
                }
            }
            if (!state.marginSplitAsFee) {
                if (lrcReceiable > 0) {
                    if (lrcReceiable >= state.lrcFee) {
                        state.splitB = state.lrcFee;
                        state.lrcFee = 0;
                    } else {
                        state.splitB = lrcReceiable;
                        state.lrcFee -= lrcReceiable;
                    }
                }
            } else {
                 
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
            OrderState memory state = orders[i];
            Order memory order = state.order;
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
        ERC20 token = ERC20(tokenAddress);
        uint allowance = token.allowance(
            tokenOwner,
            address(delegate)
        );
        uint balance = token.balanceOf(tokenOwner);
        return (allowance < balance ? allowance : balance);
    }
     
    function verifyInputDataIntegrity(RingParams params)
        private
        pure
    {
        require(params.ringSize == params.addressList.length);  
        require(params.ringSize == params.uintArgsList.length);  
        require(params.ringSize == params.uint8ArgsList.length);  
        require(params.ringSize == params.buyNoMoreThanAmountBList.length);  
         
        for (uint i = 0; i < params.ringSize; i++) {
            require(params.uintArgsList[i][5] > 0);  
        }
         
        require(params.ringSize > 1 && params.ringSize <= MAX_RING_SIZE);  
    }
     
     
    function assembleOrders(RingParams params)
        private
        view
        returns (OrderState[] memory orders)
    {
        orders = new OrderState[](params.ringSize);
        for (uint i = 0; i < params.ringSize; i++) {
            Order memory order = Order(
                params.addressList[i][0],
                params.addressList[i][1],
                params.addressList[(i + 1) % params.ringSize][1],
                params.addressList[i][2],
                params.uintArgsList[i][2],
                params.uintArgsList[i][3],
                params.uintArgsList[i][0],
                params.uintArgsList[i][1],
                params.uintArgsList[i][4],
                params.buyNoMoreThanAmountBList[i],
                params.uintArgsList[i][6],
                params.uint8ArgsList[i][0]
            );
            validateOrder(order);
            bytes32 orderHash = calculateOrderHash(order);
            verifySignature(
                order.owner,
                orderHash,
                params.vList[i],
                params.rList[i],
                params.sList[i]
            );
            bool marginSplitAsFee = (params.feeSelections & (uint16(1) << i)) > 0;
            orders[i] = OrderState(
                order,
                orderHash,
                marginSplitAsFee,
                Rate(params.uintArgsList[i][5], order.amountB),
                0,    
                0,    
                0,    
                0,    
                0     
            );
            params.ringHash ^= orderHash;
        }
        params.ringHash = keccak256(
            params.ringHash,
            params.minerId,
            params.feeSelections
        );
    }
     
    function validateOrder(Order order)
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
        bytes20 tradingPair = bytes20(order.tokenS) ^ bytes20(order.tokenB);
        require(order.validSince > tradingPairCutoffs[order.owner][tradingPair]);  
        require(order.validSince > cutoffs[order.owner]);  
    }
     
    function calculateOrderHash(Order order)
        private
        view
        returns (bytes32)
    {
        return keccak256(
            address(this),
            order.owner,
            order.tokenS,
            order.tokenB,
            order.authAddr,
            order.amountS,
            order.amountB,
            order.validSince,
            order.validUntil,
            order.lrcFee,
            order.buyNoMoreThanAmountB,
            order.walletId,
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
    function getTradingPairCutoffs(address orderOwner, address token1, address token2)
        public
        view
        returns (uint)
    {
        bytes20 tokenPair = bytes20(token1) ^ bytes20(token2);
        return tradingPairCutoffs[orderOwner][tokenPair];
    }
}