 

pragma solidity ^0.4.13;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract WETH9_ {
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    function() public payable {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return this.balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        Transfer(src, dst, wad);

        return true;
    }
}

interface FundInterface {

     

    event PortfolioContent(uint holdings, uint price, uint decimals);
    event RequestUpdated(uint id);
    event Invested(address indexed ofParticipant, uint atTimestamp, uint shareQuantity);
    event Redeemed(address indexed ofParticipant, uint atTimestamp, uint shareQuantity);
    event SpendingApproved(address onConsigned, address ofAsset, uint amount);
    event FeesConverted(uint atTimestamp, uint shareQuantityConverted, uint unclaimed);
    event CalculationUpdate(uint atTimestamp, uint managementFee, uint performanceFee, uint nav, uint sharePrice, uint totalSupply);
    event OrderUpdated(uint id);
    event LogError(uint ERROR_CODE);
    event ErrorMessage(string errorMessage);

     
     
    function requestInvestment(uint giveQuantity, uint shareQuantity, bool isNativeAsset) external;
    function requestRedemption(uint shareQuantity, uint receiveQuantity, bool isNativeAsset) external;
    function executeRequest(uint requestId) external;
    function cancelRequest(uint requestId) external;
    function redeemAllOwnedAssets(uint shareQuantity) external returns (bool);
     
    function enableInvestment() external;
    function disableInvestment() external;
    function enableRedemption() external;
    function disableRedemption() external;
    function shutDown() external;
     
    function makeOrder(uint exchangeId, address sellAsset, address buyAsset, uint sellQuantity, uint buyQuantity) external;
    function takeOrder(uint exchangeId, uint id, uint quantity) external;
    function cancelOrder(uint exchangeId, uint id) external;

     
    function emergencyRedeem(uint shareQuantity, address[] requestedAssets) public returns (bool success);
     
    function allocateUnclaimedFees();

     
     
    function getModules() view returns (address, address, address);
    function getLastOrderId() view returns (uint);
    function getLastRequestId() view returns (uint);
    function getNameHash() view returns (bytes32);
    function getManager() view returns (address);

     
    function performCalculations() view returns (uint, uint, uint, uint, uint, uint, uint);
    function calcSharePrice() view returns (uint);
}

interface AssetInterface {
     

     
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

     

     
     
    function transfer(address _to, uint _value, bytes _data) public returns (bool success);

     
     
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
     
    function balanceOf(address _owner) view public returns (uint balance);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
}

interface ERC223Interface {
    function balanceOf(address who) constant returns (uint);
    function transfer(address to, uint value) returns (bool);
    function transfer(address to, uint value, bytes data) returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

contract Asset is DSMath, AssetInterface, ERC223Interface {

     

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalSupply;

     

     
    function transfer(address _to, uint _value)
        public
        returns (bool success)
    {
        uint codeLength;
        bytes memory empty;

        assembly {
             
            codeLength := extcodesize(_to)
        }
 
        require(balances[msg.sender] >= _value);  
        require(balances[_to] + _value >= balances[_to]);

        balances[msg.sender] = sub(balances[msg.sender], _value);
        balances[_to] = add(balances[_to], _value);
         
         
         
         
        Transfer(msg.sender, _to, _value, empty);
        return true;
    }

     
    function transfer(address _to, uint _value, bytes _data)
        public
        returns (bool success)
    {
        uint codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        require(balances[msg.sender] >= _value);  
        require(balances[_to] + _value >= balances[_to]);

        balances[msg.sender] = sub(balances[msg.sender], _value);
        balances[_to] = add(balances[_to], _value);
         
         
         
         
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value)
        public
        returns (bool)
    {
        require(_from != 0x0);
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);
         

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        Transfer(_from, _to, _value);
        return true;
    }

     
     
     
     
     
    function approve(address _spender, uint _value) public returns (bool) {
        require(_spender != 0x0);

         
         
         
         
         

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     

     
     
     
     
     
    function allowance(address _owner, address _spender)
        constant
        public
        returns (uint)
    {
        return allowed[_owner][_spender];
    }

     
     
     
    function balanceOf(address _owner) constant public returns (uint) {
        return balances[_owner];
    }

}

interface ERC223ReceivingContract {

     
     
     
     
    function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

interface NativeAssetInterface {

     
    function deposit() public payable;
    function withdraw(uint wad) public;
}

interface SharesInterface {

    event Created(address indexed ofParticipant, uint atTimestamp, uint shareQuantity);
    event Annihilated(address indexed ofParticipant, uint atTimestamp, uint shareQuantity);

     

    function getName() view returns (string);
    function getSymbol() view returns (string);
    function getDecimals() view returns (uint);
    function getCreationTime() view returns (uint);
    function toSmallestShareUnit(uint quantity) view returns (uint);
    function toWholeShareUnit(uint quantity) view returns (uint);

}

contract Shares is Asset, SharesInterface {

     

     
    string public name;
    string public symbol;
    uint public decimal;
    uint public creationTime;

     

     

     
     
     
     
    function Shares(string _name, string _symbol, uint _decimal, uint _creationTime) {
        name = _name;
        symbol = _symbol;
        decimal = _decimal;
        creationTime = _creationTime;
    }

     
     

    function getName() view returns (string) { return name; }
    function getSymbol() view returns (string) { return symbol; }
    function getDecimals() view returns (uint) { return decimal; }
    function getCreationTime() view returns (uint) { return creationTime; }
    function toSmallestShareUnit(uint quantity) view returns (uint) { return mul(quantity, 10 ** getDecimals()); }
    function toWholeShareUnit(uint quantity) view returns (uint) { return quantity / (10 ** getDecimals()); }

     

     
     
    function createShares(address recipient, uint shareQuantity) internal {
        totalSupply = add(totalSupply, shareQuantity);
        balances[recipient] = add(balances[recipient], shareQuantity);
        Created(msg.sender, now, shareQuantity);
    }

     
     
    function annihilateShares(address recipient, uint shareQuantity) internal {
        totalSupply = sub(totalSupply, shareQuantity);
        balances[recipient] = sub(balances[recipient], shareQuantity);
        Annihilated(msg.sender, now, shareQuantity);
    }
}

contract RestrictedShares is Shares {

     

     
     
     
     
    function RestrictedShares(
        string _name,
        string _symbol,
        uint _decimal,
        uint _creationTime
    ) Shares(_name, _symbol, _decimal, _creationTime) {}

     

     
    function transfer(address _to, uint _value)
        public
        returns (bool success)
    {
        require(msg.sender == address(this) || _to == address(this));
        uint codeLength;
        bytes memory empty;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        require(balances[msg.sender] >= _value);  
        require(balances[_to] + _value >= balances[_to]);

        balances[msg.sender] = sub(balances[msg.sender], _value);
        balances[_to] = add(balances[_to], _value);
        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        Transfer(msg.sender, _to, _value, empty);
        return true;
    }

     
    function transfer(address _to, uint _value, bytes _data)
        public
        returns (bool success)
    {
        require(msg.sender == address(this) || _to == address(this));
        uint codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        require(balances[msg.sender] >= _value);  
        require(balances[_to] + _value >= balances[_to]);

        balances[msg.sender] = sub(balances[msg.sender], _value);
        balances[_to] = add(balances[_to], _value);
        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
     
    function approve(address _spender, uint _value) public returns (bool) {
        require(msg.sender == address(this));
        require(_spender != 0x0);

         
         
         
         
        require(_value == 0 || allowed[msg.sender][_spender] == 0);

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

}

interface ComplianceInterface {

     

     
     
     
     
     
    function isInvestmentPermitted(
        address ofParticipant,
        uint256 giveQuantity,
        uint256 shareQuantity
    ) view returns (bool);

     
     
     
     
     
    function isRedemptionPermitted(
        address ofParticipant,
        uint256 shareQuantity,
        uint256 receiveQuantity
    ) view returns (bool);
}

contract DBC {

     

    modifier pre_cond(bool condition) {
        require(condition);
        _;
    }

    modifier post_cond(bool condition) {
        _;
        assert(condition);
    }

    modifier invariant(bool condition) {
        require(condition);
        _;
        assert(condition);
    }
}

contract Owned is DBC {

     

    address public owner;

     

    function Owned() { owner = msg.sender; }

    function changeOwner(address ofNewOwner) pre_cond(isOwner()) { owner = ofNewOwner; }

     

    function isOwner() internal returns (bool) { return msg.sender == owner; }

}

contract Fund is DSMath, DBC, Owned, RestrictedShares, FundInterface, ERC223ReceivingContract {
     

    struct Modules {  
        PriceFeedInterface pricefeed;  
        ComplianceInterface compliance;  
        RiskMgmtInterface riskmgmt;  
    }

    struct Calculations {  
        uint gav;  
        uint managementFee;  
        uint performanceFee;  
        uint unclaimedFees;  
        uint nav;  
        uint highWaterMark;  
        uint totalSupply;  
        uint timestamp;  
    }

    enum RequestStatus { active, cancelled, executed }
    enum RequestType { invest, redeem, tokenFallbackRedeem }
    struct Request {  
        address participant;  
        RequestStatus status;  
        RequestType requestType;  
        address requestAsset;  
        uint shareQuantity;  
        uint giveQuantity;  
        uint receiveQuantity;  
        uint timestamp;      
        uint atUpdateId;     
    }

    enum OrderStatus { active, partiallyFilled, fullyFilled, cancelled }
    enum OrderType { make, take }
    struct Order {  
        uint exchangeId;  
        OrderStatus status;  
        OrderType orderType;  
        address sellAsset;  
        address buyAsset;  
        uint sellQuantity;  
        uint buyQuantity;  
        uint timestamp;  
        uint fillQuantity;  
    }

    struct Exchange {
        address exchange;  
        ExchangeInterface exchangeAdapter;  
        bool isApproveOnly;  
    }

     

     
    uint public constant MAX_FUND_ASSETS = 90;  
     
    uint public MANAGEMENT_FEE_RATE;  
    uint public PERFORMANCE_FEE_RATE;  
    address public VERSION;  
    Asset public QUOTE_ASSET;  
    NativeAssetInterface public NATIVE_ASSET;  
     
    Modules public module;  
    Exchange[] public exchanges;  
    Calculations public atLastUnclaimedFeeAllocation;  
    bool public isShutDown;  
    Request[] public requests;  
    bool public isInvestAllowed;  
    bool public isRedeemAllowed;  
    Order[] public orders;  
    mapping (uint => mapping(address => uint)) public exchangeIdsToOpenMakeOrderIds;  
    address[] public ownedAssets;  
    mapping (address => bool) public isInAssetList;  
    mapping (address => bool) public isInOpenMakeOrder;  

     

     

     
     
     
     
     
     
     
     
     
     
     
    function Fund(
        address ofManager,
        string withName,
        address ofQuoteAsset,
        uint ofManagementFee,
        uint ofPerformanceFee,
        address ofNativeAsset,
        address ofCompliance,
        address ofRiskMgmt,
        address ofPriceFeed,
        address[] ofExchanges,
        address[] ofExchangeAdapters
    )
        RestrictedShares(withName, "MLNF", 18, now)
    {
        isInvestAllowed = true;
        isRedeemAllowed = true;
        owner = ofManager;
        require(ofManagementFee < 10 ** 18);  
        MANAGEMENT_FEE_RATE = ofManagementFee;  
        require(ofPerformanceFee < 10 ** 18);  
        PERFORMANCE_FEE_RATE = ofPerformanceFee;  
        VERSION = msg.sender;
        module.compliance = ComplianceInterface(ofCompliance);
        module.riskmgmt = RiskMgmtInterface(ofRiskMgmt);
        module.pricefeed = PriceFeedInterface(ofPriceFeed);
         
        for (uint i = 0; i < ofExchanges.length; ++i) {
            ExchangeInterface adapter = ExchangeInterface(ofExchangeAdapters[i]);
            bool isApproveOnly = adapter.isApproveOnly();
            exchanges.push(Exchange({
                exchange: ofExchanges[i],
                exchangeAdapter: adapter,
                isApproveOnly: isApproveOnly
            }));
        }
         
        QUOTE_ASSET = Asset(ofQuoteAsset);
        NATIVE_ASSET = NativeAssetInterface(ofNativeAsset);
        require(address(QUOTE_ASSET) == module.pricefeed.getQuoteAsset());  
        atLastUnclaimedFeeAllocation = Calculations({
            gav: 0,
            managementFee: 0,
            performanceFee: 0,
            unclaimedFees: 0,
            nav: 0,
            highWaterMark: 10 ** getDecimals(),
            totalSupply: totalSupply,
            timestamp: now
        });
    }

     

     

    function enableInvestment() external pre_cond(isOwner()) { isInvestAllowed = true; }
    function disableInvestment() external pre_cond(isOwner()) { isInvestAllowed = false; }
    function enableRedemption() external pre_cond(isOwner()) { isRedeemAllowed = true; }
    function disableRedemption() external pre_cond(isOwner()) { isRedeemAllowed = false; }
    function shutDown() external pre_cond(msg.sender == VERSION) { isShutDown = true; }


     

     
     
     
     
    function requestInvestment(
        uint giveQuantity,
        uint shareQuantity,
        bool isNativeAsset
    )
        external
        pre_cond(!isShutDown)
        pre_cond(isInvestAllowed)  
        pre_cond(module.compliance.isInvestmentPermitted(msg.sender, giveQuantity, shareQuantity))     
    {
        requests.push(Request({
            participant: msg.sender,
            status: RequestStatus.active,
            requestType: RequestType.invest,
            requestAsset: isNativeAsset ? address(NATIVE_ASSET) : address(QUOTE_ASSET),
            shareQuantity: shareQuantity,
            giveQuantity: giveQuantity,
            receiveQuantity: shareQuantity,
            timestamp: now,
            atUpdateId: module.pricefeed.getLastUpdateId()
        }));
        RequestUpdated(getLastRequestId());
    }

     
     
     
     
    function requestRedemption(
        uint shareQuantity,
        uint receiveQuantity,
        bool isNativeAsset
      )
        external
        pre_cond(!isShutDown)
        pre_cond(isRedeemAllowed)  
        pre_cond(module.compliance.isRedemptionPermitted(msg.sender, shareQuantity, receiveQuantity))  
    {
        requests.push(Request({
            participant: msg.sender,
            status: RequestStatus.active,
            requestType: RequestType.redeem,
            requestAsset: isNativeAsset ? address(NATIVE_ASSET) : address(QUOTE_ASSET),
            shareQuantity: shareQuantity,
            giveQuantity: shareQuantity,
            receiveQuantity: receiveQuantity,
            timestamp: now,
            atUpdateId: module.pricefeed.getLastUpdateId()
        }));
        RequestUpdated(getLastRequestId());
    }

     
     
     
     
    function executeRequest(uint id)
        external
        pre_cond(!isShutDown)
        pre_cond(requests[id].status == RequestStatus.active)
        pre_cond(requests[id].requestType != RequestType.redeem || requests[id].shareQuantity <= balances[requests[id].participant])  
        pre_cond(
            totalSupply == 0 ||
            (
                now >= add(requests[id].timestamp, module.pricefeed.getInterval()) &&
                module.pricefeed.getLastUpdateId() >= add(requests[id].atUpdateId, 2)
            )
        )    
          
    {
         
         
        require(module.pricefeed.hasRecentPrice(address(QUOTE_ASSET)));
        require(module.pricefeed.hasRecentPrices(ownedAssets));
        var (isRecent, , ) = module.pricefeed.getInvertedPrice(address(QUOTE_ASSET));
         
         
        Request request = requests[id];

        uint costQuantity = toWholeShareUnit(mul(request.shareQuantity, calcSharePrice()));
        if (request.requestAsset == address(NATIVE_ASSET)) {
            var (isPriceRecent, invertedNativeAssetPrice, nativeAssetDecimal) = module.pricefeed.getInvertedPrice(address(NATIVE_ASSET));
            if (!isPriceRecent) {
                revert();
            }
            costQuantity = mul(costQuantity, invertedNativeAssetPrice) / 10 ** nativeAssetDecimal;
        }

        if (
            isInvestAllowed &&
            request.requestType == RequestType.invest &&
            costQuantity <= request.giveQuantity
        ) {
            if (!isInAssetList[address(QUOTE_ASSET)]) {
                ownedAssets.push(address(QUOTE_ASSET));
                isInAssetList[address(QUOTE_ASSET)] = true;
            }
            request.status = RequestStatus.executed;
            assert(AssetInterface(request.requestAsset).transferFrom(request.participant, this, costQuantity));  
            createShares(request.participant, request.shareQuantity);  
        } else if (
            isRedeemAllowed &&
            request.requestType == RequestType.redeem &&
            request.receiveQuantity <= costQuantity
        ) {
            request.status = RequestStatus.executed;
            assert(AssetInterface(request.requestAsset).transfer(request.participant, costQuantity));  
            annihilateShares(request.participant, request.shareQuantity);  
        } else if (
            isRedeemAllowed &&
            request.requestType == RequestType.tokenFallbackRedeem &&
            request.receiveQuantity <= costQuantity
        ) {
            request.status = RequestStatus.executed;
            assert(AssetInterface(request.requestAsset).transfer(request.participant, costQuantity));  
            annihilateShares(this, request.shareQuantity);  
        } else {
            revert();  
        }
    }

     
     
    function cancelRequest(uint id)
        external
        pre_cond(requests[id].status == RequestStatus.active)  
        pre_cond(requests[id].participant == msg.sender || isShutDown)  
    {
        requests[id].status = RequestStatus.cancelled;
    }

     
     
     
     
    function redeemAllOwnedAssets(uint shareQuantity)
        external
        returns (bool success)
    {
        return emergencyRedeem(shareQuantity, ownedAssets);
    }

     

     
     
     
     
     
     
    function makeOrder(
        uint exchangeNumber,
        address sellAsset,
        address buyAsset,
        uint sellQuantity,
        uint buyQuantity
    )
        external
        pre_cond(isOwner())
        pre_cond(!isShutDown)
    {
        require(buyAsset != address(this));  
        require(quantityHeldInCustodyOfExchange(sellAsset) == 0);  
        require(module.pricefeed.existsPriceOnAssetPair(sellAsset, buyAsset));  
        var (isRecent, referencePrice, ) = module.pricefeed.getReferencePrice(sellAsset, buyAsset);
        require(isRecent);   
        require(
            module.riskmgmt.isMakePermitted(
                module.pricefeed.getOrderPrice(
                    sellAsset,
                    buyAsset,
                    sellQuantity,
                    buyQuantity
                ),
                referencePrice,
                sellAsset,
                buyAsset,
                sellQuantity,
                buyQuantity
            )
        );  
        require(isInAssetList[buyAsset] || ownedAssets.length < MAX_FUND_ASSETS);  
        require(AssetInterface(sellAsset).approve(exchanges[exchangeNumber].exchange, sellQuantity));  

         
        require(address(exchanges[exchangeNumber].exchangeAdapter).delegatecall(bytes4(keccak256("makeOrder(address,address,address,uint256,uint256)")), exchanges[exchangeNumber].exchange, sellAsset, buyAsset, sellQuantity, buyQuantity));
        exchangeIdsToOpenMakeOrderIds[exchangeNumber][sellAsset] = exchanges[exchangeNumber].exchangeAdapter.getLastOrderId(exchanges[exchangeNumber].exchange);

         
        require(exchangeIdsToOpenMakeOrderIds[exchangeNumber][sellAsset] != 0);

         
        isInOpenMakeOrder[sellAsset] = true;
        if (!isInAssetList[buyAsset]) {
            ownedAssets.push(buyAsset);
            isInAssetList[buyAsset] = true;
        }

        orders.push(Order({
            exchangeId: exchangeIdsToOpenMakeOrderIds[exchangeNumber][sellAsset],
            status: OrderStatus.active,
            orderType: OrderType.make,
            sellAsset: sellAsset,
            buyAsset: buyAsset,
            sellQuantity: sellQuantity,
            buyQuantity: buyQuantity,
            timestamp: now,
            fillQuantity: 0
        }));

        OrderUpdated(exchangeIdsToOpenMakeOrderIds[exchangeNumber][sellAsset]);
    }

     
     
     
     
    function takeOrder(uint exchangeNumber, uint id, uint receiveQuantity)
        external
        pre_cond(isOwner())
        pre_cond(!isShutDown)
    {
         
        Order memory order;  
        (
            order.sellAsset,
            order.buyAsset,
            order.sellQuantity,
            order.buyQuantity
        ) = exchanges[exchangeNumber].exchangeAdapter.getOrder(exchanges[exchangeNumber].exchange, id);
         
        require(order.sellAsset != address(this));  
        require(module.pricefeed.existsPriceOnAssetPair(order.buyAsset, order.sellAsset));  
        require(isInAssetList[order.sellAsset] || ownedAssets.length < MAX_FUND_ASSETS);  
        var (isRecent, referencePrice, ) = module.pricefeed.getReferencePrice(order.buyAsset, order.sellAsset);
        require(isRecent);  
        require(receiveQuantity <= order.sellQuantity);  
        uint spendQuantity = mul(receiveQuantity, order.buyQuantity) / order.sellQuantity;
        require(AssetInterface(order.buyAsset).approve(exchanges[exchangeNumber].exchange, spendQuantity));  
        require(
            module.riskmgmt.isTakePermitted(
            module.pricefeed.getOrderPrice(
                order.buyAsset,
                order.sellAsset,
                order.buyQuantity,  
                order.sellQuantity  
            ),
            referencePrice,
            order.buyAsset,
            order.sellAsset,
            order.buyQuantity,
            order.sellQuantity
        ));  

         
        require(address(exchanges[exchangeNumber].exchangeAdapter).delegatecall(bytes4(keccak256("takeOrder(address,uint256,uint256)")), exchanges[exchangeNumber].exchange, id, receiveQuantity));

         
        if (!isInAssetList[order.sellAsset]) {
            ownedAssets.push(order.sellAsset);
            isInAssetList[order.sellAsset] = true;
        }

        order.exchangeId = id;
        order.status = OrderStatus.fullyFilled;
        order.orderType = OrderType.take;
        order.timestamp = now;
        order.fillQuantity = receiveQuantity;
        orders.push(order);
        OrderUpdated(id);
    }

     
     
     
    function cancelOrder(uint exchangeNumber, uint id)
        external
        pre_cond(isOwner() || isShutDown)
    {
         
        Order order = orders[id];

         
        require(address(exchanges[exchangeNumber].exchangeAdapter).delegatecall(bytes4(keccak256("cancelOrder(address,uint256)")), exchanges[exchangeNumber].exchange, order.exchangeId));

        order.status = OrderStatus.cancelled;
        OrderUpdated(id);
    }


     

     

     
     
     
     
     
    function tokenFallback(
        address ofSender,
        uint tokenAmount,
        bytes metadata
    ) {
        if (msg.sender != address(this)) {
             
            for (uint i; i < exchanges.length; i++) {
                if (exchanges[i].exchange == ofSender) return;  
            }
            revert();
        } else {     
            requests.push(Request({
                participant: ofSender,
                status: RequestStatus.active,
                requestType: RequestType.tokenFallbackRedeem,
                requestAsset: address(QUOTE_ASSET),  
                shareQuantity: tokenAmount,
                giveQuantity: tokenAmount,               
                receiveQuantity: 0,           
                timestamp: now,
                atUpdateId: module.pricefeed.getLastUpdateId()
            }));
            RequestUpdated(getLastRequestId());
        }
    }


     

     
     
     
     
    function calcGav() returns (uint gav) {
         
        address[] memory tempOwnedAssets;  
        tempOwnedAssets = ownedAssets;
        delete ownedAssets;
        for (uint i = 0; i < tempOwnedAssets.length; ++i) {
            address ofAsset = tempOwnedAssets[i];
             
            uint assetHoldings = add(
                uint(AssetInterface(ofAsset).balanceOf(this)),  
                quantityHeldInCustodyOfExchange(ofAsset)
            );
             
            var (isRecent, assetPrice, assetDecimals) = module.pricefeed.getPrice(ofAsset);
            if (!isRecent) {
                revert();
            }
             
            gav = add(gav, mul(assetHoldings, assetPrice) / (10 ** uint256(assetDecimals)));    
            if (assetHoldings != 0 || ofAsset == address(QUOTE_ASSET) || isInOpenMakeOrder[ofAsset]) {  
                ownedAssets.push(ofAsset);
            } else {
                isInAssetList[ofAsset] = false;  
            }
            PortfolioContent(assetHoldings, assetPrice, assetDecimals);
        }
    }

     
    function calcUnclaimedFees(uint gav)
        view
        returns (
            uint managementFee,
            uint performanceFee,
            uint unclaimedFees)
    {
         
        uint timePassed = sub(now, atLastUnclaimedFeeAllocation.timestamp);
        uint gavPercentage = mul(timePassed, gav) / (1 years);
        managementFee = wmul(gavPercentage, MANAGEMENT_FEE_RATE);

         
         
        uint valuePerShareExclMgmtFees = totalSupply > 0 ? calcValuePerShare(sub(gav, managementFee), totalSupply) : toSmallestShareUnit(1);
        if (valuePerShareExclMgmtFees > atLastUnclaimedFeeAllocation.highWaterMark) {
            uint gainInSharePrice = sub(valuePerShareExclMgmtFees, atLastUnclaimedFeeAllocation.highWaterMark);
            uint investmentProfits = wmul(gainInSharePrice, totalSupply);
            performanceFee = wmul(investmentProfits, PERFORMANCE_FEE_RATE);
        }

         
        unclaimedFees = add(managementFee, performanceFee);
    }

     
     
     
     
    function calcNav(uint gav, uint unclaimedFees)
        view
        returns (uint nav)
    {
        nav = sub(gav, unclaimedFees);
    }

     
     
     
     
     
     
    function calcValuePerShare(uint totalValue, uint numShares)
        view
        pre_cond(numShares > 0)
        returns (uint valuePerShare)
    {
        valuePerShare = toSmallestShareUnit(totalValue) / numShares;
    }

     
    function performCalculations()
        view
        returns (
            uint gav,
            uint managementFee,
            uint performanceFee,
            uint unclaimedFees,
            uint feesShareQuantity,
            uint nav,
            uint sharePrice
        )
    {
        gav = calcGav();  
        (managementFee, performanceFee, unclaimedFees) = calcUnclaimedFees(gav);
        nav = calcNav(gav, unclaimedFees);

         
        feesShareQuantity = (gav == 0) ? 0 : mul(totalSupply, unclaimedFees) / gav;
         
        uint totalSupplyAccountingForFees = add(totalSupply, feesShareQuantity);
        sharePrice = nav > 0 ? calcValuePerShare(nav, totalSupplyAccountingForFees) : toSmallestShareUnit(1);  
    }

     
     
    function allocateUnclaimedFees()
        pre_cond(isOwner())
    {
        var (
            gav,
            managementFee,
            performanceFee,
            unclaimedFees,
            feesShareQuantity,
            nav,
            sharePrice
        ) = performCalculations();

        createShares(owner, feesShareQuantity);  

         
        uint highWaterMark = atLastUnclaimedFeeAllocation.highWaterMark >= sharePrice ? atLastUnclaimedFeeAllocation.highWaterMark : sharePrice;
        atLastUnclaimedFeeAllocation = Calculations({
            gav: gav,
            managementFee: managementFee,
            performanceFee: performanceFee,
            unclaimedFees: unclaimedFees,
            nav: nav,
            highWaterMark: highWaterMark,
            totalSupply: totalSupply,
            timestamp: now
        });

        FeesConverted(now, feesShareQuantity, unclaimedFees);
        CalculationUpdate(now, managementFee, performanceFee, nav, sharePrice, totalSupply);
    }

     

     
     
     
     
     
    function emergencyRedeem(uint shareQuantity, address[] requestedAssets)
        public
        pre_cond(balances[msg.sender] >= shareQuantity)   
        returns (bool)
    {
        uint[] memory ownershipQuantities = new uint[](requestedAssets.length);

         
        for (uint i = 0; i < requestedAssets.length; ++i) {
            address ofAsset = requestedAssets[i];
            uint assetHoldings = add(
                uint(AssetInterface(ofAsset).balanceOf(this)),
                quantityHeldInCustodyOfExchange(ofAsset)
            );

            if (assetHoldings == 0) continue;

             
            ownershipQuantities[i] = mul(assetHoldings, shareQuantity) / totalSupply;

             
            if (uint(AssetInterface(ofAsset).balanceOf(this)) < ownershipQuantities[i]) {
                isShutDown = true;
                ErrorMessage("CRITICAL ERR: Not enough assetHoldings for owed ownershipQuantitiy");
                return false;
            }
        }

         
        annihilateShares(msg.sender, shareQuantity);

         
        for (uint j = 0; j < ownershipQuantities.length; ++j) {
             
            if (!AssetInterface(ofAsset).transfer(msg.sender, ownershipQuantities[j])) {
                revert();
            }
        }
        Redeemed(msg.sender, now, shareQuantity);
        return true;
    }

     

     
     
     
    function quantityHeldInCustodyOfExchange(address ofAsset) returns (uint) {
        uint totalSellQuantity;      
        uint totalSellQuantityInApprove;  
        for (uint i; i < exchanges.length; i++) {
            if (exchangeIdsToOpenMakeOrderIds[i][ofAsset] == 0) {
                continue;
            }
            var (sellAsset, , sellQuantity, ) = exchanges[i].exchangeAdapter.getOrder(exchanges[i].exchange, exchangeIdsToOpenMakeOrderIds[i][ofAsset]);
            if (sellQuantity == 0) {
                exchangeIdsToOpenMakeOrderIds[i][ofAsset] = 0;
            }
            totalSellQuantity = add(totalSellQuantity, sellQuantity);
            if (exchanges[i].isApproveOnly) {
                totalSellQuantityInApprove += sellQuantity;
            }
        }
        if (totalSellQuantity == 0) {
            isInOpenMakeOrder[sellAsset] = false;
        }
        return sub(totalSellQuantity, totalSellQuantityInApprove);  
    }

     

     
     
    function calcSharePrice() view returns (uint sharePrice) {
        (, , , , , sharePrice) = performCalculations();
        return sharePrice;
    }

    function getModules() view returns (address, address, address) {
        return (
            address(module.pricefeed),
            address(module.compliance),
            address(module.riskmgmt)
        );
    }

    function getLastOrderId() view returns (uint) { return orders.length - 1; }
    function getLastRequestId() view returns (uint) { return requests.length - 1; }
    function getNameHash() view returns (bytes32) { return bytes32(keccak256(name)); }
    function getManager() view returns (address) { return owner; }
}

interface ExchangeInterface {

     

    event OrderUpdated(uint id);

     
     

    function makeOrder(
        address onExchange,
        address sellAsset,
        address buyAsset,
        uint sellQuantity,
        uint buyQuantity
    ) external returns (uint);
    function takeOrder(address onExchange, uint id, uint quantity) external returns (bool);
    function cancelOrder(address onExchange, uint id) external returns (bool);


     
     

    function isApproveOnly() view returns (bool);
    function getLastOrderId(address onExchange) view returns (uint);
    function isActive(address onExchange, uint id) view returns (bool);
    function getOwner(address onExchange, uint id) view returns (address);
    function getOrder(address onExchange, uint id) view returns (address, address, uint, uint);
    function getTimestamp(address onExchange, uint id) view returns (uint);

}

interface PriceFeedInterface {

     

    event PriceUpdated(uint timestamp);

     

    function update(address[] ofAssets, uint[] newPrices);

     

     
    function getName(address ofAsset) view returns (string);
    function getSymbol(address ofAsset) view returns (string);
    function getDecimals(address ofAsset) view returns (uint);
     
    function getQuoteAsset() view returns (address);
    function getInterval() view returns (uint);
    function getValidity() view returns (uint);
    function getLastUpdateId() view returns (uint);
     
    function hasRecentPrice(address ofAsset) view returns (bool isRecent);
    function hasRecentPrices(address[] ofAssets) view returns (bool areRecent);
    function getPrice(address ofAsset) view returns (bool isRecent, uint price, uint decimal);
    function getPrices(address[] ofAssets) view returns (bool areRecent, uint[] prices, uint[] decimals);
    function getInvertedPrice(address ofAsset) view returns (bool isRecent, uint invertedPrice, uint decimal);
    function getReferencePrice(address ofBase, address ofQuote) view returns (bool isRecent, uint referencePrice, uint decimal);
    function getOrderPrice(
        address sellAsset,
        address buyAsset,
        uint sellQuantity,
        uint buyQuantity
    ) view returns (uint orderPrice);
    function existsPriceOnAssetPair(address sellAsset, address buyAsset) view returns (bool isExistent);
}

interface RiskMgmtInterface {

     
     

     
     
     
     
     
     
     
     
    function isMakePermitted(
        uint orderPrice,
        uint referencePrice,
        address sellAsset,
        address buyAsset,
        uint sellQuantity,
        uint buyQuantity
    ) view returns (bool);

     
     
     
     
     
     
     
     
    function isTakePermitted(
        uint orderPrice,
        uint referencePrice,
        address sellAsset,
        address buyAsset,
        uint sellQuantity,
        uint buyQuantity
    ) view returns (bool);
}

interface VersionInterface {

     

    event FundUpdated(uint id);

     

    function shutDown() external;

    function setupFund(
        string ofFundName,
        address ofQuoteAsset,
        uint ofManagementFee,
        uint ofPerformanceFee,
        address ofCompliance,
        address ofRiskMgmt,
        address ofPriceFeed,
        address[] ofExchanges,
        address[] ofExchangeAdapters,
        uint8 v,
        bytes32 r,
        bytes32 s
    );
    function shutDownFund(address ofFund);

     

    function getNativeAsset() view returns (address);
    function getFundById(uint withId) view returns (address);
    function getLastFundId() view returns (uint);
    function getFundByManager(address ofManager) view returns (address);
    function termsAndConditionsAreSigned(uint8 v, bytes32 r, bytes32 s) view returns (bool signed);

}

contract Version is DBC, Owned, VersionInterface {
     

     
    bytes32 public constant TERMS_AND_CONDITIONS = 0x47173285a8d7341e5e972fc677286384f802f8ef42a5ec5f03bbfa254cb01fad;  
     
    string public VERSION_NUMBER;  
    address public NATIVE_ASSET;  
    address public GOVERNANCE;  
     
    bool public isShutDown;  
    address[] public listOfFunds;  
    mapping (address => address) public managerToFunds;  

     

    event FundUpdated(address ofFund);

     

     

     
     
     
    function Version(
        string versionNumber,
        address ofGovernance,
        address ofNativeAsset
    ) {
        VERSION_NUMBER = versionNumber;
        GOVERNANCE = ofGovernance;
        NATIVE_ASSET = ofNativeAsset;
    }

     

    function shutDown() external pre_cond(msg.sender == GOVERNANCE) { isShutDown = true; }

     

     
     
     
     
     
     
     
     
     
     
     
     
    function setupFund(
        string ofFundName,
        address ofQuoteAsset,
        uint ofManagementFee,
        uint ofPerformanceFee,
        address ofCompliance,
        address ofRiskMgmt,
        address ofPriceFeed,
        address[] ofExchanges,
        address[] ofExchangeAdapters,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) {
        require(!isShutDown);
        require(termsAndConditionsAreSigned(v, r, s));
         
        require(managerToFunds[msg.sender] == 0);  
        address ofFund = new Fund(
            msg.sender,
            ofFundName,
            ofQuoteAsset,
            ofManagementFee,
            ofPerformanceFee,
            NATIVE_ASSET,
            ofCompliance,
            ofRiskMgmt,
            ofPriceFeed,
            ofExchanges,
            ofExchangeAdapters
        );
        listOfFunds.push(ofFund);
        managerToFunds[msg.sender] = ofFund;
        FundUpdated(ofFund);
    }

     
     
    function shutDownFund(address ofFund)
        pre_cond(isShutDown || managerToFunds[msg.sender] == ofFund)
    {
        Fund fund = Fund(ofFund);
        delete managerToFunds[msg.sender];
        fund.shutDown();
        FundUpdated(ofFund);
    }

     

     
     
     
     
     
    function termsAndConditionsAreSigned(uint8 v, bytes32 r, bytes32 s) view returns (bool signed) {
        return ecrecover(
             
             
             
             
             
             
             
            keccak256("\x19Ethereum Signed Message:\n32", TERMS_AND_CONDITIONS),
            v,
            r,
            s
        ) == msg.sender;  
    }

    function getNativeAsset() view returns (address) { return NATIVE_ASSET; }
    function getFundById(uint withId) view returns (address) { return listOfFunds[withId]; }
    function getLastFundId() view returns (uint) { return listOfFunds.length - 1; }
    function getFundByManager(address ofManager) view returns (address) { return managerToFunds[ofManager]; }
}