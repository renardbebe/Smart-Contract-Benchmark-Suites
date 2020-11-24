 

pragma solidity ^0.4.24;



contract IStorage {
  function processPreSaleBonus(uint minTotalUsdAmountInCents, uint bonusPercent, uint _start, uint _limit) external returns(uint);
  function checkNeedProcessPreSaleBonus(uint minTotalUsdAmountInCents) external view returns(bool);
  function getCountNeedProcessPreSaleBonus(uint minTotalUsdAmountInCents, uint start, uint limit) external view returns(uint);
  function reCountUserPreSaleBonus(uint uId, uint minTotalUsdAmountInCents, uint bonusPercent, uint maxPayTime) external returns(uint, uint);
  function getContributorIndexes(uint index) external view returns(uint);
  function checkNeedSendSHPC(bool proc) external view returns(bool);
  function getCountNeedSendSHPC(uint start, uint limit) external view returns(uint);
  function checkETHRefund(bool proc) external view returns(bool);
  function getCountETHRefund(uint start, uint limit) external view returns(uint);
  function addPayment(address _addr, string pType, uint _value, uint usdAmount, uint currencyUSD, uint tokenWithoutBonus, uint tokenBonus, uint bonusPercent, uint payId) public returns(bool);
  function addPayment(uint uId, string pType, uint _value, uint usdAmount, uint currencyUSD, uint tokenWithoutBonus, uint tokenBonus, uint bonusPercent, uint payId) public returns(bool);
  function checkUserIdExists(uint uId) public view returns(bool);
  function getContributorAddressById(uint uId) public view returns(address);
  function editPaymentByUserId(uint uId, uint payId, uint _payValue, uint _usdAmount, uint _currencyUSD, uint _totalToken, uint _tokenWithoutBonus, uint _tokenBonus, uint _bonusPercent) public returns(bool);
  function getUserPaymentById(uint uId, uint payId) public view returns(uint time, bytes32 pType, uint currencyUSD, uint bonusPercent, uint payValue, uint totalToken, uint tokenBonus, uint tokenWithoutBonus, uint usdAbsRaisedInCents, bool refund);
  function checkWalletExists(address addr) public view returns(bool result);
  function checkReceivedCoins(address addr) public view returns(bool);
  function getContributorId(address addr) public view returns(uint);
  function getTotalCoin(address addr) public view returns(uint);
  function setReceivedCoin(uint uId) public returns(bool);
  function checkPreSaleReceivedBonus(address addr) public view returns(bool);
  function checkRefund(address addr) public view returns(bool);
  function setRefund(uint uId) public returns(bool);
  function getEthPaymentContributor(address addr) public view returns(uint);
  function refundPaymentByUserId(uint uId, uint payId) public returns(bool);
  function changeSupportChangeMainWallet(bool support) public returns(bool);
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

 
contract String {

  function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string memory) {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    bytes memory _bc = bytes(_c);
    bytes memory _bd = bytes(_d);
    bytes memory _be = bytes(_e);
    bytes memory abcde = bytes(new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length));
    uint k = 0;
    uint i;
    for (i = 0; i < _ba.length; i++) {
      abcde[k++] = _ba[i];
    }
    for (i = 0; i < _bb.length; i++) {
      abcde[k++] = _bb[i];
    }
    for (i = 0; i < _bc.length; i++) {
      abcde[k++] = _bc[i];
    }
    for (i = 0; i < _bd.length; i++) {
      abcde[k++] = _bd[i];
    }
    for (i = 0; i < _be.length; i++) {
      abcde[k++] = _be[i];
    }
    return string(abcde);
  }

  function strConcat(string _a, string _b, string _c, string _d) internal pure returns(string) {
    return strConcat(_a, _b, _c, _d, "");
  }

  function strConcat(string _a, string _b, string _c) internal pure returns(string) {
    return strConcat(_a, _b, _c, "", "");
  }

  function strConcat(string _a, string _b) internal pure returns(string) {
    return strConcat(_a, _b, "", "", "");
  }

  function uint2str(uint i) internal pure returns(string) {
    if (i == 0) {
      return "0";
    }
    uint j = i;
    uint length;
    while (j != 0) {
      length++;
      j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint k = length - 1;
    while (i != 0) {
      bstr[k--] = byte(uint8(48 + i % 10));
      i /= 10;
    }
    return string(bstr);
  }

  function stringsEqual(string memory _a, string memory _b) internal pure returns(bool) {
    bytes memory a = bytes(_a);
    bytes memory b = bytes(_b);

    if (a.length != b.length)
      return false;

    for (uint i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }

    return true;
  }

  function stringToBytes32(string memory source) internal pure returns(bytes32 result) {
    bytes memory _tmp = bytes(source);
    if (_tmp.length == 0) {
      return 0x0;
    }
    assembly {
      result := mload(add(source, 32))
    }
  }

  function bytes32ToString(bytes32 x) internal pure returns (string) {
    bytes memory bytesString = new bytes(32);
    uint charCount = 0;
    uint j;
    for (j = 0; j < 32; j++) {
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

  function inArray(string[] _array, string _value) internal pure returns(bool result) {
    if (_array.length == 0 || bytes(_value).length == 0) {
      return false;
    }
    result = false;
    for (uint i = 0; i < _array.length; i++) {
      if (stringsEqual(_array[i],_value)) {
        result = true;
        return true;
      }
    }
  }
}

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor () public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

 
contract MultiOwnable is Ownable {

  struct Types {
    mapping (address => bool) access;
  }
  mapping (uint => Types) private multiOwnersTypes;

  event AddOwner(uint _type, address addr);
  event AddOwner(uint[] types, address addr);
  event RemoveOwner(uint _type, address addr);

  modifier onlyMultiOwnersType(uint _type) {
    require(multiOwnersTypes[_type].access[msg.sender] || msg.sender == owner, "403");
    _;
  }

  function onlyMultiOwnerType(uint _type, address _sender) public view returns(bool) {
    if (multiOwnersTypes[_type].access[_sender] || _sender == owner) {
      return true;
    }
    return false;
  }

  function addMultiOwnerType(uint _type, address _owner) public onlyOwner returns(bool) {
    require(_owner != address(0));
    multiOwnersTypes[_type].access[_owner] = true;
    emit AddOwner(_type, _owner);
    return true;
  }
  
  function addMultiOwnerTypes(uint[] types, address _owner) public onlyOwner returns(bool) {
    require(_owner != address(0));
    require(types.length > 0);
    for (uint i = 0; i < types.length; i++) {
      multiOwnersTypes[types[i]].access[_owner] = true;
    }
    emit AddOwner(types, _owner);
    return true;
  }

  function removeMultiOwnerType(uint types, address _owner) public onlyOwner returns(bool) {
    require(_owner != address(0));
    multiOwnersTypes[types].access[_owner] = false;
    emit RemoveOwner(types, _owner);
    return true;
  }
}

 
contract ShipCoinStorage is IStorage, MultiOwnable, String {
  using SafeMath for uint256;

   
  event WhitelistAddressAdded(address addr);
  event WhitelistAddressRemoved(address addr);
  event AddPayment(address addr);
  event GotPreSaleBonus(address addr);
  event EditUserPayments(address addr, uint payId);
  event RefundPayment(address addr, uint payId);
  event ReceivedCoin(address addr);
  event Refund(address addr);
  event ChangeMainWallet(address addr);

  struct PaymentData {
    uint time;
    bytes32 pType;
    uint currencyUSD;
    uint payValue;
    uint totalToken;
    uint tokenWithoutBonus;
    uint tokenBonus;
    uint bonusPercent;
    uint usdAbsRaisedInCents;
  }

  struct StorageData {
    bool active;
    mapping(bytes32 => uint) payInCurrency;
    uint totalToken;
    uint tokenWithoutBonus;
    uint tokenBonus;
    uint usdAbsRaisedInCents;
    mapping(uint => PaymentData) paymentInfo;
    address mainWallet;
    address[] wallet;
  }
   
  mapping(uint => StorageData) private contributorList;
   
  mapping(address => uint) private contributorIds;
   
  mapping(uint => uint) private contributorIndexes;
   
  mapping(uint => uint[]) private contributorPayIds;
  uint public nextContributorIndex;

  bytes32[] private currencyTicker;
   
  mapping(uint => uint) private receivedPreSaleBonus;
   
  mapping(uint => bool) private receivedCoin;
   
  mapping(uint => bool) private payIds;
   
  mapping(uint => bool) private refundPayIds;
   
  mapping(uint => bool) private refundUserIds;

  uint private startGenId = 100000;

  bool public supportChangeMainWallet = true;

   
  function processPreSaleBonus(uint minTotalUsdAmountInCents, uint bonusPercent, uint _start, uint _limit) external onlyMultiOwnersType(12) returns(uint) {
    require(minTotalUsdAmountInCents > 10000);
    require(bonusPercent > 20 && bonusPercent < 50);
    require(_limit >= 10);

    uint start = _start;
    uint limit = _limit;
    uint bonusTokenAll = 0;
    for (uint i = start; i < limit; i++) {
      uint uId = contributorIndexes[i];
      if (contributorList[uId].active && !checkPreSaleReceivedBonus(uId) && contributorList[uId].usdAbsRaisedInCents >= minTotalUsdAmountInCents) {
        uint bonusToken = contributorList[uId].tokenWithoutBonus.mul(bonusPercent).div(100);

        contributorList[uId].totalToken += bonusToken;
        contributorList[uId].tokenBonus = bonusToken;
        receivedPreSaleBonus[uId] = bonusToken;
        bonusTokenAll += bonusToken;
        emit GotPreSaleBonus(contributorList[uId].mainWallet);
      }
    }

    return bonusTokenAll;
  }

   
  function checkNeedProcessPreSaleBonus(uint minTotalUsdAmountInCents) external view returns(bool) {
    require(minTotalUsdAmountInCents > 10000);
    bool processed = false;
    for (uint i = 0; i < nextContributorIndex; i++) {
      if (processed) {
        break;
      }
      uint uId = contributorIndexes[i];
      if (contributorList[uId].active && !refundUserIds[uId] && !checkPreSaleReceivedBonus(uId) && contributorList[uId].usdAbsRaisedInCents >= minTotalUsdAmountInCents) {
        processed = true;
      }
    }
    return processed;
  }

   
  function getCountNeedProcessPreSaleBonus(uint minTotalUsdAmountInCents, uint start, uint limit) external view returns(uint) {
    require(minTotalUsdAmountInCents > 10000);
    require(start >= 0 && limit >= 10);
    uint processed = 0;
    for (uint i = start; i < (limit > nextContributorIndex ? nextContributorIndex : limit); i++) {
      uint uId = contributorIndexes[i];
      if (contributorList[uId].active && !refundUserIds[uId] && !checkPreSaleReceivedBonus(uId) && contributorList[uId].usdAbsRaisedInCents >= minTotalUsdAmountInCents) {
        processed++;
      }
    }
    return processed;
  }

   
  function checkNeedSendSHPC(bool proc) external view returns(bool) {
    bool processed = false;
    if (proc) {
      for (uint i = 0; i < nextContributorIndex; i++) {
        if (processed) {
          break;
        }
        uint uId = contributorIndexes[i];
        if (contributorList[uId].active && !refundUserIds[uId] && !checkReceivedCoins(uId) && contributorList[uId].totalToken > 0) {
          processed = true;
        }
      }
    }
    return processed;
  }

   
  function getCountNeedSendSHPC(uint start, uint limit) external view returns(uint) {
    require(start >= 0 && limit >= 10);
    uint processed = 0;
    for (uint i = start; i < (limit > nextContributorIndex ? nextContributorIndex : limit); i++) {
      uint uId = contributorIndexes[i];
      if (contributorList[uId].active && !refundUserIds[uId] && !checkReceivedCoins(uId) && contributorList[uId].totalToken > 0) {
        processed++;
      }
    }
    return processed;
  }

   
  function checkETHRefund(bool proc) external view returns(bool) {
    bool processed = false;
    if (proc) {
      for (uint i = 0; i < nextContributorIndex; i++) {
        if (processed) {
          break;
        }
        uint uId = contributorIndexes[i];
        if (contributorList[uId].active && !refundUserIds[uId] && getEthPaymentContributor(uId) > 0) {
          processed = true;
        }
      }
    }
    return processed;
  }

   
  function getCountETHRefund(uint start, uint limit) external view returns(uint) {
    require(start >= 0 && limit >= 10);
    uint processed = 0;
    for (uint i = start; i < (limit > nextContributorIndex ? nextContributorIndex : limit); i++) {
      uint uId = contributorIndexes[i];
      if (contributorList[uId].active && !refundUserIds[uId] && getEthPaymentContributor(uId) > 0) {
        processed++;
      }
    }
    return processed;
  }

   
  function getContributorIndexes(uint index) external onlyMultiOwnersType(7) view returns(uint) {
    return contributorIndexes[index];
  }

   
  function reCountUserPreSaleBonus(uint _uId, uint minTotalUsdAmountInCents, uint bonusPercent, uint maxPayTime) external onlyMultiOwnersType(13) returns(uint, uint) {
    require(_uId > 0);
    require(contributorList[_uId].active);
    require(!refundUserIds[_uId]);
    require(minTotalUsdAmountInCents > 10000);
    require(bonusPercent > 20 && bonusPercent < 50);
    uint bonusToken = 0;
    uint uId = _uId;
    uint beforeBonusToken = receivedPreSaleBonus[uId];

    if (beforeBonusToken > 0) {
      contributorList[uId].totalToken -= beforeBonusToken;
      contributorList[uId].tokenBonus -= beforeBonusToken;
      receivedPreSaleBonus[uId] = 0;
    }

    if (contributorList[uId].usdAbsRaisedInCents >= minTotalUsdAmountInCents) {
      if (maxPayTime > 0) {
        for (uint i = 0; i < contributorPayIds[uId].length; i++) {
          PaymentData memory _payment = contributorList[uId].paymentInfo[contributorPayIds[uId][i]];
          if (!refundPayIds[contributorPayIds[uId][i]] && _payment.bonusPercent == 0 && _payment.time < maxPayTime) {
            bonusToken += _payment.tokenWithoutBonus.mul(bonusPercent).div(100);
          }
        }
      } else {
        bonusToken = contributorList[uId].tokenWithoutBonus.mul(bonusPercent).div(100);
      }

      if (bonusToken > 0) {
        contributorList[uId].totalToken += bonusToken;
        contributorList[uId].tokenBonus += bonusToken;
        receivedPreSaleBonus[uId] = bonusToken;
        emit GotPreSaleBonus(contributorList[uId].mainWallet);
      }
    }
    return (beforeBonusToken, bonusToken);
  }

   
  function addWhiteList(uint uId, address addr) public onlyMultiOwnersType(1) returns(bool success) {
    require(addr != address(0), "1");
    require(uId > 0, "2");
    require(!refundUserIds[uId]);

    if (contributorIds[addr] > 0 && contributorIds[addr] != uId) {
      success = false;
      revert("3");
    }

    if (contributorList[uId].active != true) {
      contributorList[uId].active = true;
      contributorIndexes[nextContributorIndex] = uId;
      nextContributorIndex++;
      contributorList[uId].mainWallet = addr;
    }

    if (inArray(contributorList[uId].wallet, addr) != true && contributorList[uId].wallet.length < 3) {
      contributorList[uId].wallet.push(addr);
      contributorIds[addr] = uId;
      emit WhitelistAddressAdded(addr);
      success = true;
    } else {
      success = false;
    }
  }

   
  function removeWhiteList(uint uId, address addr) public onlyMultiOwnersType(2) returns(bool success) {
    require(contributorList[uId].active, "1");
    require(addr != address(0), "2");
    require(uId > 0, "3");
    require(inArray(contributorList[uId].wallet, addr));

    if (contributorPayIds[uId].length > 0 || contributorList[uId].mainWallet == addr) {
      success = false;
      revert("5");
    }


    contributorList[uId].wallet = removeValueFromArray(contributorList[uId].wallet, addr);
    delete contributorIds[addr];

    emit WhitelistAddressRemoved(addr);
    success = true;
  }

   
  function changeMainWallet(uint uId, address addr) public onlyMultiOwnersType(3) returns(bool) {
    require(supportChangeMainWallet);
    require(addr != address(0));
    require(uId > 0);
    require(contributorList[uId].active);
    require(!refundUserIds[uId]);
    require(inArray(contributorList[uId].wallet, addr));

    contributorList[uId].mainWallet = addr;
    emit ChangeMainWallet(addr);
    return true;
  }

   
  function changeSupportChangeMainWallet(bool support) public onlyMultiOwnersType(21) returns(bool) {
    supportChangeMainWallet = support;
    return supportChangeMainWallet;
  }

   
  function getContributionInfoById(uint _uId) public onlyMultiOwnersType(4) view returns(
      bool active,
      string payInCurrency,
      uint totalToken,
      uint tokenWithoutBonus,
      uint tokenBonus,
      uint usdAbsRaisedInCents,
      uint[] paymentInfoIds,
      address mainWallet,
      address[] wallet,
      uint preSaleReceivedBonus,
      bool receivedCoins,
      bool refund
    )
  {
    uint uId = _uId;
    return getContributionInfo(contributorList[uId].mainWallet);
  }

   
  function getContributionInfo(address _addr)
    public
    view
    returns(
      bool active,
      string payInCurrency,
      uint totalToken,
      uint tokenWithoutBonus,
      uint tokenBonus,
      uint usdAbsRaisedInCents,
      uint[] paymentInfoIds,
      address mainWallet,
      address[] wallet,
      uint preSaleReceivedBonus,
      bool receivedCoins,
      bool refund
    )
  {

    address addr = _addr;
    StorageData memory storData = contributorList[contributorIds[addr]];

    (preSaleReceivedBonus, receivedCoins, refund) = getInfoAdditionl(addr);

    return(
    storData.active,
    (contributorPayIds[contributorIds[addr]].length > 0 ? getContributorPayInCurrency(contributorIds[addr]) : "[]"),
    storData.totalToken,
    storData.tokenWithoutBonus,
    storData.tokenBonus,
    storData.usdAbsRaisedInCents,
    contributorPayIds[contributorIds[addr]],
    storData.mainWallet,
    storData.wallet,
    preSaleReceivedBonus,
    receivedCoins,
    refund
    );
  }

   
  function getContributorId(address addr) public onlyMultiOwnersType(5) view returns(uint) {
    return contributorIds[addr];
  }

   
  function getContributorAddressById(uint uId) public onlyMultiOwnersType(6) view returns(address) {
    require(uId > 0);
    require(contributorList[uId].active);
    return contributorList[uId].mainWallet;
  }

   
  function checkWalletExists(address addr) public view returns(bool result) {
    result = false;
    if (contributorList[contributorIds[addr]].wallet.length > 0) {
      result = inArray(contributorList[contributorIds[addr]].wallet, addr);
    }
  }

   
  function checkUserIdExists(uint uId) public onlyMultiOwnersType(8) view returns(bool) {
    return contributorList[uId].active;
  }

   
  function addPayment(
    address _addr,
    string pType,
    uint _value,
    uint usdAmount,
    uint currencyUSD,
    uint tokenWithoutBonus,
    uint tokenBonus,
    uint bonusPercent,
    uint payId
  )
  public
  onlyMultiOwnersType(9)
  returns(bool)
  {
    require(_value > 0);
    require(usdAmount > 0);
    require(tokenWithoutBonus > 0);
    require(bytes(pType).length > 0);
    assert((payId == 0 && stringsEqual(pType, "ETH")) || (payId > 0 && !payIds[payId]));

    address addr = _addr;
    uint uId = contributorIds[addr];

    assert(addr != address(0));
    assert(checkWalletExists(addr));
    assert(uId > 0);
    assert(contributorList[uId].active);
    assert(!refundUserIds[uId]);
    assert(!receivedCoin[uId]);

    if (payId == 0) {
      payId = genId(addr, _value, 0);
    }

    bytes32 _pType = stringToBytes32(pType);
    PaymentData memory userPayment;
    uint totalToken = tokenWithoutBonus.add(tokenBonus);

     
    userPayment.time = block.timestamp;
    userPayment.pType = _pType;
    userPayment.currencyUSD = currencyUSD;
    userPayment.payValue = _value;
    userPayment.totalToken = totalToken;
    userPayment.tokenWithoutBonus = tokenWithoutBonus;
    userPayment.tokenBonus = tokenBonus;
    userPayment.bonusPercent = bonusPercent;
    userPayment.usdAbsRaisedInCents = usdAmount;

    if (!inArray(currencyTicker, _pType)) {
      currencyTicker.push(_pType);
    }
    if (payId > 0) {
      payIds[payId] = true;
    }

    contributorList[uId].usdAbsRaisedInCents += usdAmount;
    contributorList[uId].totalToken += totalToken;
    contributorList[uId].tokenWithoutBonus += tokenWithoutBonus;
    contributorList[uId].tokenBonus += tokenBonus;

    contributorList[uId].payInCurrency[_pType] += _value;
    contributorList[uId].paymentInfo[payId] = userPayment;
    contributorPayIds[uId].push(payId);

    emit AddPayment(addr);
    return true;
  }

   
  function addPayment(
    uint uId,
    string pType,
    uint _value,
    uint usdAmount,
    uint currencyUSD,
    uint tokenWithoutBonus,
    uint tokenBonus,
    uint bonusPercent,
    uint payId
  )
  public
  returns(bool)
  {
    require(contributorList[uId].active);
    require(contributorList[uId].mainWallet != address(0));
    return addPayment(contributorList[uId].mainWallet, pType, _value, usdAmount, currencyUSD, tokenWithoutBonus, tokenBonus, bonusPercent, payId);
  }

   
  function editPaymentByUserId(
    uint uId,
    uint payId,
    uint _payValue,
    uint _usdAmount,
    uint _currencyUSD,
    uint _totalToken,
    uint _tokenWithoutBonus,
    uint _tokenBonus,
    uint _bonusPercent
  )
  public
  onlyMultiOwnersType(10)
  returns(bool)
  {
    require(contributorList[uId].active);
    require(inArray(contributorPayIds[uId], payId));
    require(!refundPayIds[payId]);
    require(!refundUserIds[uId]);
    require(!receivedCoin[uId]);

    PaymentData memory oldPayment = contributorList[uId].paymentInfo[payId];

    contributorList[uId].usdAbsRaisedInCents -= oldPayment.usdAbsRaisedInCents;
    contributorList[uId].totalToken -= oldPayment.totalToken;
    contributorList[uId].tokenWithoutBonus -= oldPayment.tokenWithoutBonus;
    contributorList[uId].tokenBonus -= oldPayment.tokenBonus;
    contributorList[uId].payInCurrency[oldPayment.pType] -= oldPayment.payValue;

    contributorList[uId].paymentInfo[payId] = PaymentData(
      oldPayment.time,
      oldPayment.pType,
      _currencyUSD,
      _payValue,
      _totalToken,
      _tokenWithoutBonus,
      _tokenBonus,
      _bonusPercent,
      _usdAmount
    );

    contributorList[uId].usdAbsRaisedInCents += _usdAmount;
    contributorList[uId].totalToken += _totalToken;
    contributorList[uId].tokenWithoutBonus += _tokenWithoutBonus;
    contributorList[uId].tokenBonus += _tokenBonus;
    contributorList[uId].payInCurrency[oldPayment.pType] += _payValue;

    emit EditUserPayments(contributorList[uId].mainWallet, payId);

    return true;
  }

   
  function refundPaymentByUserId(uint uId, uint payId) public onlyMultiOwnersType(20) returns(bool) {
    require(contributorList[uId].active);
    require(inArray(contributorPayIds[uId], payId));
    require(!refundPayIds[payId]);
    require(!refundUserIds[uId]);
    require(!receivedCoin[uId]);

    PaymentData memory oldPayment = contributorList[uId].paymentInfo[payId];

    assert(oldPayment.pType != stringToBytes32("ETH"));

    contributorList[uId].usdAbsRaisedInCents -= oldPayment.usdAbsRaisedInCents;
    contributorList[uId].totalToken -= oldPayment.totalToken;
    contributorList[uId].tokenWithoutBonus -= oldPayment.tokenWithoutBonus;
    contributorList[uId].tokenBonus -= oldPayment.tokenBonus;
    contributorList[uId].payInCurrency[oldPayment.pType] -= oldPayment.payValue;

    refundPayIds[payId] = true;

    emit RefundPayment(contributorList[uId].mainWallet, payId);

    return true;
  }

   
  function getUserPaymentById(uint _uId, uint _payId) public onlyMultiOwnersType(11) view returns(
    uint time,
    bytes32 pType,
    uint currencyUSD,
    uint bonusPercent,
    uint payValue,
    uint totalToken,
    uint tokenBonus,
    uint tokenWithoutBonus,
    uint usdAbsRaisedInCents,
    bool refund
  )
  {
    uint uId = _uId;
    uint payId = _payId;
    require(contributorList[uId].active);
    require(inArray(contributorPayIds[uId], payId));

    PaymentData memory payment = contributorList[uId].paymentInfo[payId];

    return (
      payment.time,
      payment.pType,
      payment.currencyUSD,
      payment.bonusPercent,
      payment.payValue,
      payment.totalToken,
      payment.tokenBonus,
      payment.tokenWithoutBonus,
      payment.usdAbsRaisedInCents,
      refundPayIds[payId] ? true : false
    );
  }

   
  function getUserPayment(address addr, uint _payId) public view returns(
    uint time,
    string pType,
    uint currencyUSD,
    uint bonusPercent,
    uint payValue,
    uint totalToken,
    uint tokenBonus,
    uint tokenWithoutBonus,
    uint usdAbsRaisedInCents,
    bool refund
  )
  {
    address _addr = addr;
    require(contributorList[contributorIds[_addr]].active);
    require(inArray(contributorPayIds[contributorIds[_addr]], _payId));

    uint payId = _payId;

    PaymentData memory payment = contributorList[contributorIds[_addr]].paymentInfo[payId];

    return (
      payment.time,
      bytes32ToString(payment.pType),
      payment.currencyUSD,
      payment.bonusPercent,
      payment.payValue,
      payment.totalToken,
      payment.tokenBonus,
      payment.tokenWithoutBonus,
      payment.usdAbsRaisedInCents,
      refundPayIds[payId] ? true : false
    );
  }

   
  function getEthPaymentContributor(address addr) public view returns(uint) {
    return contributorList[contributorIds[addr]].payInCurrency[stringToBytes32("ETH")];
  }

   
  function getTotalCoin(address addr) public view returns(uint) {
    return contributorList[contributorIds[addr]].totalToken;
  }

   
  function checkPreSaleReceivedBonus(address addr) public view returns(bool) {
    return receivedPreSaleBonus[contributorIds[addr]] > 0 ? true : false;
  }

   
  function checkPaymentRefund(uint payId) public view returns(bool) {
    return refundPayIds[payId];
  }

   
  function checkRefund(address addr) public view returns(bool) {
    return refundUserIds[contributorIds[addr]];
  }

   
  function setStartGenId(uint startId) public onlyMultiOwnersType(14) {
    require(startId > 0);
    startGenId = startId;
  }

   
  function setReceivedCoin(uint uId) public onlyMultiOwnersType(15) returns(bool) {
    require(contributorList[uId].active);
    require(!refundUserIds[uId]);
    require(!receivedCoin[uId]);
    receivedCoin[uId] = true;
    emit ReceivedCoin(contributorList[uId].mainWallet);
    return true;
  }

   
  function setRefund(uint uId) public onlyMultiOwnersType(16) returns(bool) {
    require(contributorList[uId].active);
    require(!refundUserIds[uId]);
    require(!receivedCoin[uId]);
    refundUserIds[uId] = true;
    emit Refund(contributorList[uId].mainWallet);
    return true;
  }

   
  function checkReceivedCoins(address addr) public view returns(bool) {
    return receivedCoin[contributorIds[addr]];
  }

   
  function checkReceivedEth(address addr) public view returns(bool) {
    return refundUserIds[contributorIds[addr]];
  }

   
  function getContributorPayInCurrency(uint uId) private view returns(string) {
    require(uId > 0);
    require(contributorList[uId].active);
    string memory payInCurrency = "{";
    for (uint i = 0; i < currencyTicker.length; i++) {
      payInCurrency = strConcat(payInCurrency, strConcat("\"", bytes32ToString(currencyTicker[i]), "\":\""), uint2str(contributorList[uId].payInCurrency[currencyTicker[i]]), (i+1 < currencyTicker.length) ? "\"," : "\"}");
    }
    return payInCurrency;
  }

   
  function checkPreSaleReceivedBonus(uint uId) private view returns(bool) {
    return receivedPreSaleBonus[uId] > 0 ? true : false;
  }

   
  function checkRefund(uint uId) private view returns(bool) {
    return refundUserIds[uId];
  }

   
  function checkReceivedCoins(uint id) private view returns(bool) {
    return receivedCoin[id];
  }

   
  function checkReceivedEth(uint id) private view returns(bool) {
    return refundUserIds[id];
  }

   
  function genId(address addr, uint ammount, uint rand) private view returns(uint) {
    uint id = startGenId + uint8(keccak256(abi.encodePacked(addr, blockhash(block.number), ammount, rand))) + contributorPayIds[contributorIds[addr]].length;
    if (!payIds[id]) {
      return id;
    } else {
      return genId(addr, ammount, id);
    }
  }

   
  function getEthPaymentContributor(uint uId) private view returns(uint) {
    return contributorList[uId].payInCurrency[stringToBytes32("ETH")];
  }

   
  function getInfoAdditionl(address addr) private view returns(uint, bool, bool) {
    return(receivedPreSaleBonus[contributorIds[addr]], receivedCoin[contributorIds[addr]], refundUserIds[contributorIds[addr]]);
  }

   
  function getArrayjsonPaymentInfo(uint uId) private view returns (string) {
    string memory _array = "{";
    for (uint i = 0; i < contributorPayIds[uId].length; i++) {
      _array = strConcat(_array, getJsonPaymentInfo(contributorList[uId].paymentInfo[contributorPayIds[uId][i]], contributorPayIds[uId][i]), (i+1 == contributorPayIds[uId].length) ? "}" : ",");
    }
    return _array;
  }

   
  function getJsonPaymentInfo(PaymentData memory _obj, uint payId) private view returns (string) {
    return strConcat(
      strConcat("\"", uint2str(payId), "\":{", strConcat("\"", "time", "\":"), uint2str(_obj.time)),
      strConcat(",\"pType\":\"", bytes32ToString(_obj.pType), "\",\"currencyUSD\":", uint2str(_obj.currencyUSD), ",\"payValue\":\""),
      strConcat(uint2str(_obj.payValue), "\",\"totalToken\":\"", uint2str(_obj.totalToken), "\",\"tokenWithoutBonus\":\"", uint2str(_obj.tokenWithoutBonus)),
      strConcat("\",\"tokenBonus\":\"", uint2str(_obj.tokenBonus), "\",\"bonusPercent\":", uint2str(_obj.bonusPercent)),
      strConcat(",\"usdAbsRaisedInCents\":\"", uint2str(_obj.usdAbsRaisedInCents), "\",\"refund\":\"", (refundPayIds[payId] ? "1" : "0"), "\"}")
    );
  }

   
  function inArray(address[] _array, address _value) private pure returns(bool result) {
    if (_array.length == 0 || _value == address(0)) {
      return false;
    }
    result = false;
    for (uint i = 0; i < _array.length; i++) {
      if (_array[i] == _value) {
        result = true;
        return true;
      }
    }
  }

   
  function inArray(uint[] _array, uint _value) private pure returns(bool result) {
    if (_array.length == 0 || _value == 0) {
      return false;
    }
    result = false;
    for (uint i = 0; i < _array.length; i++) {
      if (_array[i] == _value) {
        result = true;
        return true;
      }
    }
  }

   
  function inArray(bytes32[] _array, bytes32 _value) private pure returns(bool result) {
    if (_array.length == 0 || _value.length == 0) {
      return false;
    }
    result = false;
    for (uint i = 0; i < _array.length; i++) {
      if (_array[i] == _value) {
        result = true;
        return true;
      }
    }
  }

   
  function removeValueFromArray(address[] _array, address _value) private pure returns(address[]) {
    address[] memory arrayNew = new address[](_array.length-1);
    if (arrayNew.length == 0) {
      return arrayNew;
    }
    uint i1 = 0;
    for (uint i = 0; i < _array.length; i++) {
      if (_array[i] != _value) {
        arrayNew[i1++] = _array[i];
      }
    }
    return arrayNew;
  }

}