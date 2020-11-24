 

pragma solidity ^0.4.23;

 

interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external  view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external  returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 

library Utils {

    uint  constant PRECISION = (10**18);
    uint  constant MAX_DECIMALS = 18;

    function calcDstQty(uint srcQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns(uint) {
        if( dstDecimals >= srcDecimals ) {
            require((dstDecimals-srcDecimals) <= MAX_DECIMALS);
            return (srcQty * rate * (10**(dstDecimals-srcDecimals))) / PRECISION;
        } else {
            require((srcDecimals-dstDecimals) <= MAX_DECIMALS);
            return (srcQty * rate) / (PRECISION * (10**(srcDecimals-dstDecimals)));
        }
    }

     
     
     
     
     
     
     
     
     
}

 

contract Manageable {
    event ProviderUpdated (uint8 name, address hash);

     
    mapping (uint8 => address) public subContracts;
    modifier onlyOwner() {
         
        require(true == false);
        _;
    }

    function setProvider(uint8 _id, address _providerAddress) public onlyOwner returns (bool success) {
        require(_providerAddress != address(0));
        subContracts[_id] = _providerAddress;
        emit ProviderUpdated(_id, _providerAddress);

        return true;
    }
}

 

library TypeDefinitions {

    enum ProviderType {
        Strategy,
        Price,
        Exchange,
        Storage,
        ExtendedStorage,
        Whitelist
    }

    struct ProviderStatistic {
        uint counter;
        uint amountInEther;
        uint reputation;
    }

    struct ERC20Token {
        string symbol;
        address tokenAddress;
        uint decimal;
    }
}

contract Provider is Manageable {
    string public name;
    TypeDefinitions.ProviderType public providerType;
    string public description;
    mapping(string => bool) internal properties;
    TypeDefinitions.ProviderStatistic public statistics;
}

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

   
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

   
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

   
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

 

 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

   
  string public constant ROLE_ADMIN = "admin";

   
  function RBAC()
    public
  {
    addRole(msg.sender, ROLE_ADMIN);
  }

   
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

   
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

   
  function adminAddRole(address addr, string roleName)
    onlyAdmin
    public
  {
    addRole(addr, roleName);
  }

   
  function adminRemoveRole(address addr, string roleName)
    onlyAdmin
    public
  {
    removeRole(addr, roleName);
  }

   
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    RoleAdded(addr, roleName);
  }

   
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    RoleRemoved(addr, roleName);
  }

   
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

   
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

 

contract PermissionProviderInterface is Provider, RBAC {
    string public constant ROLE_ADMIN = "admin";
    string public constant ROLE_CORE = "core";
    string public constant ROLE_STORAGE = "storage";
    string public constant ROLE_CORE_OWNER = "CoreOwner";
    string public constant ROLE_STRATEGY_OWNER = "StrategyOwner";
    string public constant ROLE_PRICE_OWNER = "PriceOwner";
    string public constant ROLE_EXCHANGE_OWNER = "ExchangeOwner";
    string public constant ROLE_EXCHANGE_ADAPTER_OWNER = "ExchangeAdapterOwner";
    string public constant ROLE_STORAGE_OWNER = "StorageOwner";
    string public constant ROLE_WHITELIST_OWNER = "WhitelistOwner";

    modifier onlyAdmin()
    {
        checkRole(msg.sender, ROLE_ADMIN);
        _;
    }

    function changeAdmin(address _newAdmin) onlyAdmin public returns (bool success);
    function adminAdd(address _addr, string _roleName) onlyAdmin public;
    function adminRemove(address _addr, string _roleName) onlyAdmin public;

    function has(address _addr, string _roleName) public view returns(bool success);
}

 

contract ExchangeAdapterBase {

    address internal adapterManager;
    address internal exchangeExchange;

    enum Status {
        ENABLED, 
        DISABLED
    }

    enum OrderStatus {
        Pending,
        Approved,
        PartiallyCompleted,
        Completed,
        Cancelled,
        Errored
    }

    function ExchangeAdapterBase(address _manager,address _exchange) public {
        adapterManager = _manager;
        exchangeExchange = _exchange;
    }

    function getExpectAmount(uint eth, uint destDecimals, uint rate) internal pure returns(uint){
        return Utils.calcDstQty(eth, 18, destDecimals, rate);
    }

    modifier onlyAdaptersManager(){
        require(msg.sender == adapterManager);
        _;
    }

    modifier onlyExchangeProvider(){
        require(msg.sender == exchangeExchange);
        _;
    }
}

 

contract ExchangeProviderInterface {
    function startPlaceOrder(uint orderId, address deposit) external returns(bool);
    function addPlaceOrderItem(uint orderId, ERC20 token, uint amount, uint rate) external returns(bool);
    function endPlaceOrder(uint orderId) external payable returns(bool);
    function getSubOrderStatus(uint orderId, ERC20 token) external view returns (ExchangeAdapterBase.OrderStatus);
    function cancelOrder(uint orderId) external returns (bool success);
    function checkTokenSupported(ERC20 token) external view returns (bool);
}

 

library Converter {
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(bytes32 x) internal pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }

        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

contract PriceProviderInterface {

    function updatePrice(address _tokenAddress,bytes32[] _exchanges,uint[] _prices,uint _nonce) public returns(bool success);
    function getNewDefaultPrice(address _tokenAddress) public view returns(uint);
    function getNewCustomPrice(address _provider,address _tokenAddress) public view returns(uint);

    function getNonce(address providerAddress,address tokenAddress) public view returns(uint);

    function checkTokenSupported(address tokenAddress)  public view returns(bool success);
    function checkExchangeSupported(bytes32 Exchanges)  public view returns(bool success);
    function checkProviderSupported(address providerAddress,address tokenAddress)  public view returns(bool success);

    function getRates(address dest, uint srcQty)  public view returns (uint expectedRate, uint slippageRate);
}

 

 
contract OlympusStorageExtendedInterface {
     
    function setCustomExtraData(bytes32 dataKind, uint objectId, bytes32 key, bytes32 value) external returns(bool success);
     
    function getCustomExtraData(bytes32 dataKind, uint objectId, bytes32 key) external view returns(bytes32 result);
     
    function getAccessor(bytes32 dataKind, uint id) private pure returns(string accessor);
}

 

library StorageTypeDefinitions {
    enum OrderStatus {
        New,
        Placed,
        PartiallyCompleted,
        Completed,
        Cancelled,
        Errored
    }
}

 

contract OlympusStorageInterface {

    function addTokenDetails(
        uint indexOrderId,
        address[] tokens,
        uint[] weights,
        uint[] totalTokenAmounts,
        uint[] estimatedPrices) external;

    function addOrderBasicFields(
        uint strategyId,
        address buyer,
        uint amountInWei,
        uint feeInWei,
        bytes32 exchangeId) external returns (uint indexOrderId);

    function getOrderTokenCompletedAmount(
        uint _orderId,
        address _tokenAddress) external view returns (uint, uint);

    function getIndexOrder1(uint _orderId) external view returns(
        uint strategyId,
        address buyer,
        StorageTypeDefinitions.OrderStatus status,
        uint dateCreated
        );

    function getIndexOrder2(uint _orderId) external view returns(
        uint dateCompleted,
        uint amountInWei,
        uint tokensLength,
        bytes32 exchangeId
        );

    function updateIndexOrderToken(
        uint _orderId,
        uint _tokenIndex,
        uint _actualPrice,
        uint _totalTokenAmount,
        uint _completedQuantity,
        ExchangeAdapterBase.OrderStatus status) external;

    function getIndexToken(uint _orderId, uint tokenPosition) external view returns (address token);

    function updateOrderStatus(uint _orderId, StorageTypeDefinitions.OrderStatus _status)
        external returns (bool success);

    function resetOrderIdTo(uint _orderId) external returns(uint);

    function addCustomField(
        uint _orderId,
        bytes32 key,
        bytes32 value
        ) external returns (bool success);

    function getCustomField(
        uint _orderId,
        bytes32 key
        ) external view returns (bytes32 result);
}

 

contract OlympusStorage is Manageable, OlympusStorageInterface {
    using SafeMath for uint256;

    event IndexOrderUpdated (uint orderId);
    event Log(string message);

    struct IndexOrder {
        address buyer;
        uint strategyId;
        uint amountInWei;
        uint feeInWei;
        uint dateCreated;
        uint dateCompleted;
        address[] tokens;
        uint[] weights;
        uint[] estimatedPrices;
        uint[] dealtPrices;
        uint[] totalTokenAmounts;
        uint[] completedTokenAmounts;
        ExchangeAdapterBase.OrderStatus[] subStatuses;
        StorageTypeDefinitions.OrderStatus status;
        bytes32 exchangeId;
    }
    mapping(uint => IndexOrder) public orders;
    mapping(uint => mapping(address => uint)) public orderTokenAmounts;
    uint public orderId = 1000000;
    bytes32 constant private dataKind = "Order";
    OlympusStorageExtendedInterface internal olympusStorageExtended = OlympusStorageExtendedInterface(address(0xcEb51bD598ABb0caa8d2Da30D4D760f08936547B));

    modifier onlyOwner() {
        require(permissionProvider.has(msg.sender, permissionProvider.ROLE_STORAGE_OWNER()));
        _;
    }
    modifier onlyCore() {
        require(permissionProvider.has(msg.sender, permissionProvider.ROLE_CORE()));
        _;
    }
    PermissionProviderInterface internal permissionProvider;
    constructor(address _permissionProvider) public {
        permissionProvider = PermissionProviderInterface(_permissionProvider);
    }

    function addTokenDetails(
        uint indexOrderId,
        address[] tokens,
        uint[] weights,
        uint[] totalTokenAmounts,
        uint[] estimatedPrices
    ) external onlyCore {
        orders[indexOrderId].tokens = tokens;
        orders[indexOrderId].weights = weights;
        orders[indexOrderId].estimatedPrices = estimatedPrices;
        orders[indexOrderId].totalTokenAmounts = totalTokenAmounts;
        uint i;

        for (i = 0; i < tokens.length; i++ ) {
            orders[indexOrderId].subStatuses.push(ExchangeAdapterBase.OrderStatus.Pending);
            orders[indexOrderId].dealtPrices.push(0);
            orders[indexOrderId].completedTokenAmounts.push(0);

            orderTokenAmounts[indexOrderId][tokens[i]] = weights[i];
        }
    }

    function addOrderBasicFields(
        uint strategyId,
        address buyer,
        uint amountInWei,
        uint feeInWei,
        bytes32 exchangeId
        ) external onlyCore returns (uint indexOrderId) {
        indexOrderId = getOrderId();

        IndexOrder memory order = IndexOrder({
            buyer: buyer,
            strategyId: strategyId,
            amountInWei: amountInWei,
            feeInWei: feeInWei,
            dateCreated: now,
            dateCompleted: 0,
            tokens: new address[](0),
            weights: new uint[](0),
            estimatedPrices: new uint[](0),
            dealtPrices: new uint[](0),
            totalTokenAmounts: new uint[](0),
            completedTokenAmounts: new uint[](0),
            subStatuses: new ExchangeAdapterBase.OrderStatus[](0),
            status: StorageTypeDefinitions.OrderStatus.New,
            exchangeId: exchangeId
        });

        orders[indexOrderId] = order;
        return indexOrderId;
    }

    function getIndexOrder1(uint _orderId) external view returns(
        uint strategyId,
        address buyer,
        StorageTypeDefinitions.OrderStatus status,
        uint dateCreated
        ) {
        IndexOrder memory order = orders[_orderId];
        return (
            order.strategyId,
            order.buyer,
            order.status,
            order.dateCreated
        );
    }
    function getIndexOrder2(uint _orderId) external view returns(
        uint dateCompleted,
        uint amountInWei,
        uint tokensLength,
        bytes32 exchangeId
        ) {
        IndexOrder memory order = orders[_orderId];
        return (
            order.dateCompleted,
            order.amountInWei,
            order.tokens.length,
            order.exchangeId
        );
    }

    function getIndexToken(uint _orderId, uint tokenPosition) external view returns (address token){
        return orders[_orderId].tokens[tokenPosition];
    }

    function getOrderTokenCompletedAmount(uint _orderId, address _tokenAddress) external view returns (uint, uint){
        IndexOrder memory order = orders[_orderId];

        int index = -1;
        for(uint i = 0 ; i < order.tokens.length; i++){
            if(order.tokens[i] == _tokenAddress) {
                index = int(i);
                break;
            }
        }

        if(index == -1) {
             
            revert();
        }

        return (order.completedTokenAmounts[uint(index)], uint(index));

    }

    function updateIndexOrderToken(
        uint _orderId,
        uint _tokenIndex,
        uint _actualPrice,
        uint _totalTokenAmount,
        uint _completedQuantity,
        ExchangeAdapterBase.OrderStatus _status) external onlyCore {

        orders[_orderId].totalTokenAmounts[_tokenIndex] = _totalTokenAmount;
        orders[_orderId].dealtPrices[_tokenIndex] = _actualPrice;
        orders[_orderId].completedTokenAmounts[_tokenIndex] = _completedQuantity;
        orders[_orderId].subStatuses[_tokenIndex] = _status;
    }

    function addCustomField(
        uint _orderId,
        bytes32 key,
        bytes32 value
    ) external onlyCore returns (bool success){
        return olympusStorageExtended.setCustomExtraData(dataKind,_orderId,key,value);
    }

    function getCustomField(
        uint _orderId,
        bytes32 key
    ) external view returns (bytes32 result){
        return olympusStorageExtended.getCustomExtraData(dataKind,_orderId,key);
    }

    function updateOrderStatus(uint _orderId, StorageTypeDefinitions.OrderStatus _status)
        external onlyCore returns (bool success){

        orders[_orderId].status = _status;
        return true;
    }

    function getOrderId() private returns (uint) {
        return orderId++;
    }

    function resetOrderIdTo(uint _start) external onlyOwner returns (uint) {
        orderId = _start;
        return orderId;
    }

    function setProvider(uint8 _id, address _providerAddress) public onlyOwner returns (bool success) {
        bool result = super.setProvider(_id, _providerAddress);
        TypeDefinitions.ProviderType _type = TypeDefinitions.ProviderType(_id);

        if(_type == TypeDefinitions.ProviderType.ExtendedStorage) {
            emit Log("ExtendedStorage");
            olympusStorageExtended = OlympusStorageExtendedInterface(_providerAddress);
        } else {
            emit Log("Unknown provider type supplied.");
            revert();
        }

        return result;
    }


}

 

contract StrategyProviderInterface is Provider {

    struct Combo {
        uint id;
        string name;
        string description;
        string category;
        address[] tokenAddresses;
        uint[] weights;       
        uint follower;
        uint amount;
        bytes32 exchangeId;
    }

    Combo[] public comboHub;
    modifier _checkIndex(uint _index) {
        require(_index < comboHub.length);
        _;
    }

    
    function getStrategyCount() public view returns (uint length);

    function getStrategyTokenCount(uint strategyId) public view returns (uint length);
    function getStrategyTokenByIndex(uint strategyId, uint tokenIndex) public view returns (address token, uint weight);

    function getStrategy(uint _index) public _checkIndex(_index) view returns (
        uint id,
        string name,
        string description,
        string category,
        address[] memory tokenAddresses,
        uint[] memory weights,
        uint followers,
        uint amount,
        bytes32 exchangeId);

    function createStrategy(
        string name,
        string description,
        string category,
        address[] tokenAddresses,
        uint[] weights,
        bytes32 exchangeId)
        public returns (uint strategyId);

    function updateStrategy(
        uint strategyId,
        string name,
        string description,
        string category,
        address[] tokenAddresses,
        uint[] weights,
        bytes32 exchangeId)
        public returns (bool success);

     
    function incrementStatistics(uint id, uint amountInEther) external returns (bool success);
    function updateFollower(uint id, bool follow) external returns (bool success);
}

 

contract WhitelistProviderInterface is Provider {
    function isAllowed(address account) external view returns(bool);
}

 

contract OlympusLabsCore is Manageable {
    using SafeMath for uint256;

    event IndexOrderUpdated (uint orderId);
    event Log(string message);
    event LogNumber(uint number);
    event LogAddress(address message);
    event LogAddresses(address[] message);
    event LogNumbers(uint[] numbers);
    event LOGDEBUG(address);

    ExchangeProviderInterface internal exchangeProvider =  ExchangeProviderInterface(address(0x0));
    StrategyProviderInterface internal strategyProvider = StrategyProviderInterface(address(0x0));
    PriceProviderInterface internal priceProvider = PriceProviderInterface(address(0x0));
    OlympusStorageInterface internal olympusStorage = OlympusStorageInterface(address(0x0));
    WhitelistProviderInterface internal whitelistProvider;
    ERC20 private constant MOT = ERC20(address(0x263c618480DBe35C300D8d5EcDA19bbB986AcaeD));
     

    uint public feePercentage = 100;
    uint public MOTDiscount = 25;
    uint public constant DENOMINATOR = 10000;

    uint public minimumInWei = 0;
    uint public maximumInWei;

    modifier allowProviderOnly(TypeDefinitions.ProviderType _type) {
        require(msg.sender == subContracts[uint8(_type)]);
        _;
    }

    modifier onlyOwner() {
        require(permissionProvider.has(msg.sender, permissionProvider.ROLE_CORE_OWNER()));
        _;
    }

    modifier onlyAllowed(){
        require(address(whitelistProvider) == 0x0 || whitelistProvider.isAllowed(msg.sender));
        _;
    }

    PermissionProviderInterface internal permissionProvider;

    function OlympusLabsCore(address _permissionProvider) public {
        permissionProvider = PermissionProviderInterface(_permissionProvider);
    }

    function() payable public {
        revert();
    }

    function getStrategyCount() public view returns (uint length)
    {
        return strategyProvider.getStrategyCount();
    }

    function getStrategy(uint strategyId) public view returns (
        string name,
        string description,
        string category,
        address[] memory tokens,
        uint[] memory weights,
        uint followers,
        uint amount,
        string exchangeName)
    {
        bytes32 _exchangeName;
        uint tokenLength = strategyProvider.getStrategyTokenCount(strategyId);
        tokens = new address[](tokenLength);
        weights = new uint[](tokenLength);

        (,name,description,category,,,followers,amount,_exchangeName) = strategyProvider.getStrategy(strategyId);
        (,,,,tokens,weights,,,) = strategyProvider.getStrategy(strategyId);
        exchangeName = Converter.bytes32ToString(_exchangeName);
    }

    function getStrategyTokenAndWeightByIndex(uint strategyId, uint index) public view returns (
        address token,
        uint weight
        )
    {
        uint tokenLength = strategyProvider.getStrategyTokenCount(strategyId);
        require(index < tokenLength);

        (token, weight) = strategyProvider.getStrategyTokenByIndex(strategyId, index);
    }

     
    function getPrice(address tokenAddress, uint srcQty) public view returns (uint price){
        require(tokenAddress != address(0));
        (, price) = priceProvider.getRates(tokenAddress, srcQty);
        return price;
    }

    function getStrategyTokenPrice(uint strategyId, uint tokenIndex) public view returns (uint price) {
        uint totalLength;

        uint tokenLength = strategyProvider.getStrategyTokenCount(strategyId);
        require(tokenIndex <= totalLength);
        address[] memory tokens;
        uint[] memory weights;
        (,,,,tokens,weights,,,) = strategyProvider.getStrategy(strategyId);

         

        return getPrice(tokens[tokenIndex], 10**18);
    }

    function setProvider(uint8 _id, address _providerAddress) public onlyOwner returns (bool success) {
        bool result = super.setProvider(_id, _providerAddress);
        TypeDefinitions.ProviderType _type = TypeDefinitions.ProviderType(_id);

        if(_type == TypeDefinitions.ProviderType.Strategy) {
            emit Log("StrategyProvider");
            strategyProvider = StrategyProviderInterface(_providerAddress);
        } else if(_type == TypeDefinitions.ProviderType.Exchange) {
            emit Log("ExchangeProvider");
            exchangeProvider = ExchangeProviderInterface(_providerAddress);
        } else if(_type == TypeDefinitions.ProviderType.Price) {
            emit Log("PriceProvider");
            priceProvider = PriceProviderInterface(_providerAddress);
        } else if(_type == TypeDefinitions.ProviderType.Storage) {
            emit Log("StorageProvider");
            olympusStorage = OlympusStorageInterface(_providerAddress);
        } else if(_type == TypeDefinitions.ProviderType.Whitelist) {
            emit Log("WhitelistProvider");
            whitelistProvider = WhitelistProviderInterface(_providerAddress);
        } else {
            emit Log("Unknown provider type supplied.");
            revert();
        }

        return result;
    }

    function buyIndex(uint strategyId, address depositAddress, bool feeIsMOT)
    public onlyAllowed payable returns (uint indexOrderId)
    {
        require(msg.value > minimumInWei);
        if(maximumInWei > 0){
            require(msg.value <= maximumInWei);
        }
        uint tokenLength = strategyProvider.getStrategyTokenCount(strategyId);
         
        require(tokenLength > 0);
        address[] memory tokens = new address[](tokenLength);
        uint[] memory weights = new uint[](tokenLength);
        bytes32 exchangeId;

        (,,,,tokens,weights,,,exchangeId) = strategyProvider.getStrategy(strategyId);

        uint[3] memory amounts;
        amounts[0] = msg.value;  
        amounts[1] = getFeeAmount(amounts[0], feeIsMOT);  
        amounts[2] = payFee(amounts[0], amounts[1], msg.sender, feeIsMOT);

         
        indexOrderId = olympusStorage.addOrderBasicFields(
          strategyId,
          msg.sender,
          amounts[0],
          amounts[1],
          exchangeId
        );

        uint[][4] memory subOrderTemp;
         
         
        subOrderTemp[0] = initializeArray(tokenLength);
        subOrderTemp[1] = initializeArray(tokenLength);

        emit LogNumber(indexOrderId);


        require(exchangeProvider.startPlaceOrder(indexOrderId, depositAddress));

        for (uint i = 0; i < tokenLength; i ++ ) {

             
            if(weights[i] <= 0) {
                continue;
            }
             
            if(!exchangeProvider.checkTokenSupported(ERC20(tokens[i]))){
                emit Log("Exchange provider doesn't support");
                revert();
            }

             
            if(!priceProvider.checkTokenSupported(tokens[i])){
                emit Log("Price provider doesn't support");
                revert();
            }

            subOrderTemp[0][i] = amounts[2] * weights[i] / 100;
            subOrderTemp[1][i] = getPrice(tokens[i], subOrderTemp[0][i]);

            emit LogAddress(tokens[i]);
            emit LogNumber(subOrderTemp[0][i]);
            emit LogNumber(subOrderTemp[1][i]);
            require(exchangeProvider.addPlaceOrderItem(indexOrderId, ERC20(tokens[i]), subOrderTemp[0][i], subOrderTemp[1][i]));
        }

        olympusStorage.addTokenDetails(
            indexOrderId,
            tokens, weights, subOrderTemp[0], subOrderTemp[1]
        );


        emit LogNumber(amounts[2]);
        require((exchangeProvider.endPlaceOrder.value(amounts[2])(indexOrderId)));


        strategyProvider.updateFollower(strategyId, true);

        strategyProvider.incrementStatistics(strategyId, msg.value);

        return indexOrderId;
    }

    function initializeArray(uint length) private pure returns (uint[]){
        return new uint[](length);
    }

    function resetOrderIdTo(uint _start) external onlyOwner returns (uint) {
        return olympusStorage.resetOrderIdTo(_start);
    }

     
    function getIndexOrder(uint _orderId) public view returns
    (uint[])
    {
         
         
         
         
         
        uint[] memory orderPartial = new uint[](5);
        address[] memory buyer = new address[](1);
        bytes32[] memory exchangeId = new bytes32[](1);
        StorageTypeDefinitions.OrderStatus[] memory status = new StorageTypeDefinitions.OrderStatus[](1);


        (orderPartial[0], buyer[0], status[0], orderPartial[1]) = olympusStorage.getIndexOrder1(_orderId);
        (orderPartial[2], orderPartial[3], orderPartial[4], exchangeId[0]) = olympusStorage.getIndexOrder2(_orderId);
        address[] memory tokens = new address[](orderPartial[4]);

        for(uint i = 0; i < orderPartial[4]; i++){
            tokens[i] = olympusStorage.getIndexToken(_orderId, i);
        }
        return (
          orderPartial
        );
    }

    function updateIndexOrderToken(
        uint _orderId,
        address _tokenAddress,
        uint _actualPrice,
        uint _totalTokenAmount,
        uint _completedQuantity
    ) external allowProviderOnly(TypeDefinitions.ProviderType.Exchange) returns (bool success)
    {
        uint completedTokenAmount;
        uint tokenIndex;
        (completedTokenAmount, tokenIndex) = olympusStorage.getOrderTokenCompletedAmount(_orderId,_tokenAddress);

        ExchangeAdapterBase.OrderStatus status;

        if(completedTokenAmount == 0 && _completedQuantity < completedTokenAmount){
            status = ExchangeAdapterBase.OrderStatus.PartiallyCompleted;
        }

        if(_completedQuantity >= completedTokenAmount){
            status = ExchangeAdapterBase.OrderStatus.Completed;
        }
        olympusStorage.updateIndexOrderToken(_orderId, tokenIndex, _totalTokenAmount, _actualPrice, _completedQuantity, status);

        return true;
    }

    function updateOrderStatus(uint _orderId, StorageTypeDefinitions.OrderStatus _status)
        external allowProviderOnly(TypeDefinitions.ProviderType.Exchange)
        returns (bool success)
    {
        olympusStorage.updateOrderStatus(_orderId, _status);

        return true;
    }

    function getSubOrderStatus(uint _orderId, address _tokenAddress)
        external view returns (ExchangeAdapterBase.OrderStatus)
    {
        return exchangeProvider.getSubOrderStatus(_orderId, ERC20(_tokenAddress));
    }

    function adjustFee(uint _newFeePercentage) public onlyOwner returns (bool success) {
        require(_newFeePercentage < DENOMINATOR);
        feePercentage = _newFeePercentage;
        return true;
    }

    function adjustMOTFeeDiscount(uint _newDiscountPercentage) public onlyOwner returns(bool success) {
        require(_newDiscountPercentage <= 100);
        MOTDiscount = _newDiscountPercentage;
        return true;
    }

    function adjustTradeRange(uint _minInWei, uint _maxInWei) public onlyOwner returns (bool success) {
        require(_minInWei > 0);
        require(_maxInWei > _minInWei);
        minimumInWei = _minInWei;
        maximumInWei = _maxInWei;

        return true;
    }

    function getFeeAmount(uint amountInWei, bool feeIsMOT) private view returns (uint){
        if(feeIsMOT){
            return ((amountInWei * feePercentage / DENOMINATOR) * (100 - MOTDiscount)) / 100;
        } else {
            return amountInWei * feePercentage / DENOMINATOR;
        }
    }

    function payFee(uint totalValue, uint feeValueInETH, address sender, bool feeIsMOT) private returns (uint){
        if(feeIsMOT){
             
            uint MOTPrice;
            uint allowance = MOT.allowance(sender,address(this));
            (MOTPrice,) = priceProvider.getRates(address(MOT), feeValueInETH);
            uint amount = (feeValueInETH * MOTPrice) / 10**18;
            require(allowance >= amount);
            require(MOT.transferFrom(sender,address(this),amount));
            return totalValue;  
        } else {  
            return totalValue - feeValueInETH;
        }
    }

    function withdrawERC20(address receiveAddress,address _tokenAddress) public onlyOwner returns(bool success)
    {
        uint _balance = ERC20(_tokenAddress).balanceOf(address(this));
        require(_tokenAddress != 0x0 && receiveAddress != 0x0 && _balance != 0);
        require(ERC20(_tokenAddress).transfer(receiveAddress,_balance));
        return true;
    }
    function withdrawETH(address receiveAddress) public onlyOwner returns(bool success)
    {
        require(receiveAddress != 0x0);
        receiveAddress.transfer(this.balance);
        return true;
    }
}