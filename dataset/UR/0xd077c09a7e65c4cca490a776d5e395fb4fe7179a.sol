 

pragma solidity ^0.4.24;

 

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      return ecrecover(hash, v, r, s);
    }
  }

   
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(
      "\x19Ethereum Signed Message:\n32",
      hash
    );
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


 
contract TokenDestructible is Ownable {

  constructor() public payable { }

   
  function destroy(address[] tokens) onlyOwner public {

     
    for (uint256 i = 0; i < tokens.length; i++) {
      ERC20Basic token = ERC20Basic(tokens[i]);
      uint256 balance = token.balanceOf(this);
      token.transfer(owner, balance);
    }

     
    selfdestruct(owner);
  }
}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


 
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


 
contract WIBToken is StandardToken {
  string public constant name = "WIBSON";  
  string public constant symbol = "WIB";  
  uint8 public constant decimals = 9;  

   
  uint256 public constant INITIAL_SUPPLY = 9000000000 * (10 ** uint256(decimals));

  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
  }
}


 
contract DataOrder is Ownable {
  modifier validAddress(address addr) {
    require(addr != address(0));
    require(addr != address(this));
    _;
  }

  enum OrderStatus {
    OrderCreated,
    NotaryAdded,
    TransactionCompleted
  }

  enum DataResponseStatus {
    DataResponseAdded,
    RefundedToBuyer,
    TransactionCompleted
  }

   
  struct NotaryInfo {
    uint256 responsesPercentage;
    uint256 notarizationFee;
    string notarizationTermsOfService;
    uint32 addedAt;
  }

   
  struct SellerInfo {
    address notary;
    string dataHash;
    uint32 createdAt;
    uint32 closedAt;
    DataResponseStatus status;
  }

  address public buyer;
  string public filters;
  string public dataRequest;
  uint256 public price;
  string public termsAndConditions;
  string public buyerURL;
  string public buyerPublicKey;
  uint32 public createdAt;
  uint32 public transactionCompletedAt;
  OrderStatus public orderStatus;

  mapping(address => SellerInfo) public sellerInfo;
  mapping(address => NotaryInfo) internal notaryInfo;

  address[] public sellers;
  address[] public notaries;

   
  constructor(
    address _buyer,
    string _filters,
    string _dataRequest,
    uint256 _price,
    string _termsAndConditions,
    string _buyerURL,
    string _buyerPublicKey
  ) public validAddress(_buyer) {
    require(bytes(_buyerURL).length > 0);
    require(bytes(_buyerPublicKey).length > 0);

    buyer = _buyer;
    filters = _filters;
    dataRequest = _dataRequest;
    price = _price;
    termsAndConditions = _termsAndConditions;
    buyerURL = _buyerURL;
    buyerPublicKey = _buyerPublicKey;
    orderStatus = OrderStatus.OrderCreated;
    createdAt = uint32(block.timestamp);
    transactionCompletedAt = 0;
  }

   
  function addNotary(
    address notary,
    uint256 responsesPercentage,
    uint256 notarizationFee,
    string notarizationTermsOfService
  ) public onlyOwner validAddress(notary) returns (bool) {
    require(transactionCompletedAt == 0);
    require(responsesPercentage <= 100);
    require(!hasNotaryBeenAdded(notary));

    notaryInfo[notary] = NotaryInfo(
      responsesPercentage,
      notarizationFee,
      notarizationTermsOfService,
      uint32(block.timestamp)
    );
    notaries.push(notary);
    orderStatus = OrderStatus.NotaryAdded;
    return true;
  }

    
  function addDataResponse(
    address seller,
    address notary,
    string dataHash
  ) public onlyOwner validAddress(seller) validAddress(notary) returns (bool) {
    require(orderStatus == OrderStatus.NotaryAdded);
    require(transactionCompletedAt == 0);
    require(!hasSellerBeenAccepted(seller));
    require(hasNotaryBeenAdded(notary));

    sellerInfo[seller] = SellerInfo(
      notary,
      dataHash,
      uint32(block.timestamp),
      0,
      DataResponseStatus.DataResponseAdded
    );

    sellers.push(seller);

    return true;
  }

   
  function closeDataResponse(
    address seller,
    bool transactionCompleted
  ) public onlyOwner validAddress(seller) returns (bool) {
    require(orderStatus != OrderStatus.TransactionCompleted);
    require(transactionCompletedAt == 0);
    require(hasSellerBeenAccepted(seller));
    require(sellerInfo[seller].status == DataResponseStatus.DataResponseAdded);

    sellerInfo[seller].status = transactionCompleted
      ? DataResponseStatus.TransactionCompleted
      : DataResponseStatus.RefundedToBuyer;
    sellerInfo[seller].closedAt = uint32(block.timestamp);
    return true;
  }

   
  function close() public onlyOwner returns (bool) {
    require(orderStatus != OrderStatus.TransactionCompleted);
    require(transactionCompletedAt == 0);
    orderStatus = OrderStatus.TransactionCompleted;
    transactionCompletedAt = uint32(block.timestamp);
    return true;
  }

   
  function hasSellerBeenAccepted(
    address seller
  ) public view validAddress(seller) returns (bool) {
    return sellerInfo[seller].createdAt != 0;
  }

   
  function hasNotaryBeenAdded(
    address notary
  ) public view validAddress(notary) returns (bool) {
    return notaryInfo[notary].addedAt != 0;
  }

   
  function getNotaryInfo(
    address notary
  ) public view validAddress(notary) returns (
    address,
    uint256,
    uint256,
    string,
    uint32
  ) {
    require(hasNotaryBeenAdded(notary));
    NotaryInfo memory info = notaryInfo[notary];
    return (
      notary,
      info.responsesPercentage,
      info.notarizationFee,
      info.notarizationTermsOfService,
      uint32(info.addedAt)
    );
  }

   
  function getSellerInfo(
    address seller
  ) public view validAddress(seller) returns (
    address,
    address,
    string,
    uint32,
    uint32,
    bytes32
  ) {
    require(hasSellerBeenAccepted(seller));
    SellerInfo memory info = sellerInfo[seller];
    return (
      seller,
      info.notary,
      info.dataHash,
      uint32(info.createdAt),
      uint32(info.closedAt),
      getDataResponseStatusAsString(info.status)
    );
  }

   
  function getNotaryForSeller(
    address seller
  ) public view validAddress(seller) returns (address) {
    require(hasSellerBeenAccepted(seller));
    SellerInfo memory info = sellerInfo[seller];
    return info.notary;
  }

  function getDataResponseStatusAsString(
    DataResponseStatus drs
  ) internal pure returns (bytes32) {
    if (drs == DataResponseStatus.DataResponseAdded) {
      return bytes32("DataResponseAdded");
    }

    if (drs == DataResponseStatus.RefundedToBuyer) {
      return bytes32("RefundedToBuyer");
    }

    if (drs == DataResponseStatus.TransactionCompleted) {
      return bytes32("TransactionCompleted");
    }

    throw;  
  }

}


 
library MultiMap {

  struct MapStorage {
    mapping(address => uint) addressToIndex;
    address[] addresses;
  }

   
  function get(
    MapStorage storage self,
    uint index
  ) public view returns (address) {
    require(index < self.addresses.length);
    return self.addresses[index];
  }

   
  function exist(
    MapStorage storage self,
    address _key
  ) public view returns (bool) {
    if (_key != address(0)) {
      uint targetIndex = self.addressToIndex[_key];
      return targetIndex < self.addresses.length && self.addresses[targetIndex] == _key;
    } else {
      return false;
    }
  }

   
  function insert(
    MapStorage storage self,
    address _key
  ) public returns (bool) {
    require(_key != address(0));
    if (exist(self, _key)) {
      return true;
    }

    self.addressToIndex[_key] = self.addresses.length;
    self.addresses.push(_key);

    return true;
  }

   
  function removeAt(MapStorage storage self, uint index) public returns (bool) {
    return remove(self, self.addresses[index]);
  }

   
  function remove(MapStorage storage self, address _key) public returns (bool) {
    require(_key != address(0));
    if (!exist(self, _key)) {
      return false;
    }

    uint currentIndex = self.addressToIndex[_key];

    uint lastIndex = SafeMath.sub(self.addresses.length, 1);
    address lastAddress = self.addresses[lastIndex];
    self.addressToIndex[lastAddress] = currentIndex;
    self.addresses[currentIndex] = lastAddress;

    delete self.addresses[lastIndex];
    delete self.addressToIndex[_key];

    self.addresses.length--;
    return true;
  }

   
  function length(MapStorage storage self) public view returns (uint) {
    return self.addresses.length;
  }
}


 
library CryptoUtils {

   
  function isSignedBy(
    bytes32 hash,
    address signer,
    bytes signature
  ) private pure returns (bool) {
    require(signer != address(0));
    bytes32 prefixedHash = ECRecovery.toEthSignedMessageHash(hash);
    address recovered = ECRecovery.recover(prefixedHash, signature);
    return recovered == signer;
  }

   
  function isNotaryAdditionValid(
    address order,
    address notary,
    uint256 responsesPercentage,
    uint256 notarizationFee,
    string notarizationTermsOfService,
    bytes notarySignature
  ) public pure returns (bool) {
    require(order != address(0));
    require(notary != address(0));
    bytes32 hash = keccak256(
      abi.encodePacked(
        order,
        responsesPercentage,
        notarizationFee,
        notarizationTermsOfService
      )
    );

    return isSignedBy(hash, notary, notarySignature);
  }

   
  function isDataResponseValid(
    address order,
    address seller,
    address notary,
    string dataHash,
    bytes signature
  ) public pure returns (bool) {
    require(order != address(0));
    require(seller != address(0));
    require(notary != address(0));

    bytes memory packed = bytes(dataHash).length > 0
      ? abi.encodePacked(order, notary, dataHash)
      : abi.encodePacked(order, notary);

    bytes32 hash = keccak256(packed);
    return isSignedBy(hash, seller, signature);
  }

   
  function isNotaryVeredictValid(
    address order,
    address seller,
    address notary,
    bool wasAudited,
    bool isDataValid,
    bytes notarySignature
  ) public pure returns (bool) {
    require(order != address(0));
    require(seller != address(0));
    require(notary != address(0));
    bytes32 hash = keccak256(
      abi.encodePacked(
        order,
        seller,
        wasAudited,
        isDataValid
      )
    );

    return isSignedBy(hash, notary, notarySignature);
  }
}



 
contract DataExchange is TokenDestructible, Pausable {
  using SafeMath for uint256;
  using MultiMap for MultiMap.MapStorage;

  event NotaryRegistered(address indexed notary);
  event NotaryUpdated(address indexed notary);
  event NotaryUnregistered(address indexed notary);

  event NewOrder(address indexed orderAddr);
  event NotaryAddedToOrder(address indexed orderAddr, address indexed notary);
  event DataAdded(address indexed orderAddr, address indexed seller);
  event TransactionCompleted(address indexed orderAddr, address indexed seller);
  event RefundedToBuyer(address indexed orderAddr, address indexed buyer);
  event OrderClosed(address indexed orderAddr);

  struct NotaryInfo {
    address addr;
    string name;
    string notaryUrl;
    string publicKey;
  }

  MultiMap.MapStorage openOrders;
  MultiMap.MapStorage allowedNotaries;

  mapping(address => address[]) public ordersBySeller;
  mapping(address => address[]) public ordersByNotary;
  mapping(address => address[]) public ordersByBuyer;
  mapping(address => NotaryInfo) internal notaryInfo;
   
  mapping(address => bool) private orders;

   
   
  mapping(
    address => mapping(address => mapping(address => uint256))
  ) public buyerBalance;

   
   
  mapping(address => mapping(address => uint256)) public buyerRemainingBudgetForAudits;

  modifier validAddress(address addr) {
    require(addr != address(0));
    require(addr != address(this));
    _;
  }

  modifier isOrderLegit(address order) {
    require(orders[order]);
    _;
  }

   
  WIBToken token;

   
  uint256 public minimumInitialBudgetForAudits;

   
  constructor(
    address tokenAddress,
    address ownerAddress
  ) public validAddress(tokenAddress) validAddress(ownerAddress) {
    require(tokenAddress != ownerAddress);

    token = WIBToken(tokenAddress);
    minimumInitialBudgetForAudits = 0;
    transferOwnership(ownerAddress);
  }

   
  function registerNotary(
    address notary,
    string name,
    string notaryUrl,
    string publicKey
  ) public onlyOwner whenNotPaused validAddress(notary) returns (bool) {
    bool isNew = notaryInfo[notary].addr == address(0);

    require(allowedNotaries.insert(notary));
    notaryInfo[notary] = NotaryInfo(
      notary,
      name,
      notaryUrl,
      publicKey
    );

    if (isNew) {
      emit NotaryRegistered(notary);
    } else {
      emit NotaryUpdated(notary);
    }
    return true;
  }

   
  function unregisterNotary(
    address notary
  ) public onlyOwner whenNotPaused validAddress(notary) returns (bool) {
    require(allowedNotaries.remove(notary));

    emit NotaryUnregistered(notary);
    return true;
  }

   
  function setMinimumInitialBudgetForAudits(
    uint256 _minimumInitialBudgetForAudits
  ) public onlyOwner whenNotPaused returns (bool) {
    minimumInitialBudgetForAudits = _minimumInitialBudgetForAudits;
    return true;
  }

   
  function newOrder(
    string filters,
    string dataRequest,
    uint256 price,
    uint256 initialBudgetForAudits,
    string termsAndConditions,
    string buyerURL,
    string publicKey
  ) public whenNotPaused returns (address) {
    require(initialBudgetForAudits >= minimumInitialBudgetForAudits);
    require(token.allowance(msg.sender, this) >= initialBudgetForAudits);

    address newOrderAddr = new DataOrder(
      msg.sender,
      filters,
      dataRequest,
      price,
      termsAndConditions,
      buyerURL,
      publicKey
    );

    token.transferFrom(msg.sender, this, initialBudgetForAudits);
    buyerRemainingBudgetForAudits[msg.sender][newOrderAddr] = initialBudgetForAudits;

    ordersByBuyer[msg.sender].push(newOrderAddr);
    orders[newOrderAddr] = true;

    emit NewOrder(newOrderAddr);
    return newOrderAddr;
  }

   
  function addNotaryToOrder(
    address orderAddr,
    address notary,
    uint256 responsesPercentage,
    uint256 notarizationFee,
    string notarizationTermsOfService,
    bytes notarySignature
  ) public whenNotPaused isOrderLegit(orderAddr) validAddress(notary) returns (bool) {
    DataOrder order = DataOrder(orderAddr);
    address buyer = order.buyer();
    require(msg.sender == buyer);

    require(!order.hasNotaryBeenAdded(notary));
    require(allowedNotaries.exist(notary));

    require(
      CryptoUtils.isNotaryAdditionValid(
        orderAddr,
        notary,
        responsesPercentage,
        notarizationFee,
        notarizationTermsOfService,
        notarySignature
      )
    );

    bool okay = order.addNotary(
      notary,
      responsesPercentage,
      notarizationFee,
      notarizationTermsOfService
    );

    if (okay) {
      openOrders.insert(orderAddr);
      ordersByNotary[notary].push(orderAddr);
      emit NotaryAddedToOrder(order, notary);
    }
    return okay;
  }

   
  function addDataResponseToOrder(
    address orderAddr,
    address seller,
    address notary,
    string dataHash,
    bytes signature
  ) public whenNotPaused isOrderLegit(orderAddr) returns (bool) {
    DataOrder order = DataOrder(orderAddr);
    address buyer = order.buyer();
    require(msg.sender == buyer);
    allDistinct(
      [
        orderAddr,
        buyer,
        seller,
        notary,
        address(this)
      ]
    );
    require(order.hasNotaryBeenAdded(notary));

    require(
      CryptoUtils.isDataResponseValid(
        orderAddr,
        seller,
        notary,
        dataHash,
        signature
      )
    );

    bool okay = order.addDataResponse(
      seller,
      notary,
      dataHash
    );
    require(okay);

    chargeBuyer(order, seller);

    ordersBySeller[seller].push(orderAddr);
    emit DataAdded(order, seller);
    return true;
  }

   
  function closeDataResponse(
    address orderAddr,
    address seller,
    bool wasAudited,
    bool isDataValid,
    bytes notarySignature
  ) public whenNotPaused isOrderLegit(orderAddr) returns (bool) {
    DataOrder order = DataOrder(orderAddr);
    address buyer = order.buyer();
    require(order.hasSellerBeenAccepted(seller));

    address notary = order.getNotaryForSeller(seller);
    require(msg.sender == buyer || msg.sender == notary);
    require(
      CryptoUtils.isNotaryVeredictValid(
        orderAddr,
        seller,
        notary,
        wasAudited,
        isDataValid,
        notarySignature
      )
    );
    bool transactionCompleted = !wasAudited || isDataValid;
    require(order.closeDataResponse(seller, transactionCompleted));
    payPlayers(
      order,
      buyer,
      seller,
      notary,
      wasAudited,
      isDataValid
    );

    if (transactionCompleted) {
      emit TransactionCompleted(order, seller);
    } else {
      emit RefundedToBuyer(order, buyer);
    }
    return true;
  }

   
  function closeOrder(
    address orderAddr
  ) public whenNotPaused isOrderLegit(orderAddr) returns (bool) {
    require(openOrders.exist(orderAddr));
    DataOrder order = DataOrder(orderAddr);
    address buyer = order.buyer();
    require(msg.sender == buyer || msg.sender == owner);

    bool okay = order.close();
    if (okay) {
       
      uint256 remainingBudget = buyerRemainingBudgetForAudits[buyer][order];
      buyerRemainingBudgetForAudits[buyer][order] = 0;
      require(token.transfer(buyer, remainingBudget));

      openOrders.remove(orderAddr);
      emit OrderClosed(orderAddr);
    }

    return okay;
  }

   
  function getOrdersForNotary(
    address notary
  ) public view validAddress(notary) returns (address[]) {
    return ordersByNotary[notary];
  }

   
  function getOrdersForSeller(
    address seller
  ) public view validAddress(seller) returns (address[]) {
    return ordersBySeller[seller];
  }

   
  function getOrdersForBuyer(
    address buyer
  ) public view validAddress(buyer) returns (address[]) {
    return ordersByBuyer[buyer];
  }

   
  function getOpenOrders() public view returns (address[]) {
    return openOrders.addresses;
  }

   
  function getAllowedNotaries() public view returns (address[]) {
    return allowedNotaries.addresses;
  }

   
  function getNotaryInfo(
    address notary
  ) public view validAddress(notary) returns (address, string, string, string, bool) {
    NotaryInfo memory info = notaryInfo[notary];

    return (
      info.addr,
      info.name,
      info.notaryUrl,
      info.publicKey,
      allowedNotaries.exist(notary)
    );
  }

   
  function allDistinct(address[5] addresses) private pure {
    for (uint i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0));
      for (uint j = i + 1; j < addresses.length; j++) {  
        require(addresses[i] != addresses[j]);
      }
    }
  }

   
  function chargeBuyer(DataOrder order, address seller) private whenNotPaused {
    address buyer = order.buyer();
    address notary = order.getNotaryForSeller(seller);
    uint256 remainingBudget = buyerRemainingBudgetForAudits[buyer][order];

    uint256 orderPrice = order.price();
    (,, uint256 notarizationFee,,) = order.getNotaryInfo(notary);
    uint256 totalCharges = orderPrice.add(notarizationFee);

    uint256 prePaid = Math.min256(notarizationFee, remainingBudget);
    uint256 finalCharges = totalCharges.sub(prePaid);

    buyerRemainingBudgetForAudits[buyer][order] = remainingBudget.sub(prePaid);
    require(token.transferFrom(buyer, this, finalCharges));

     
     
    buyerBalance[buyer][order][seller] = buyerBalance[buyer][order][seller].add(totalCharges);
  }

   
  function payPlayers(
    DataOrder order,
    address buyer,
    address seller,
    address notary,
    bool wasAudited,
    bool isDataValid
  ) private whenNotPaused {
    uint256 orderPrice = order.price();
    (,, uint256 notarizationFee,,) = order.getNotaryInfo(notary);
    uint256 totalCharges = orderPrice.add(notarizationFee);

    require(buyerBalance[buyer][order][seller] >= totalCharges);
    buyerBalance[buyer][order][seller] = buyerBalance[buyer][order][seller].sub(totalCharges);

     
    address notarizationFeeReceiver = wasAudited ? notary : buyer;

     
    address orderPriceReceiver = (!wasAudited || isDataValid) ? seller : buyer;

    require(token.transfer(notarizationFeeReceiver, notarizationFee));
    require(token.transfer(orderPriceReceiver, orderPrice));
  }

}