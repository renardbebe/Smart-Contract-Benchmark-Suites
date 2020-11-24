 

pragma solidity ^0.4.24;



contract ICurrency {
  function getUsdAbsRaisedInCents() external view returns(uint);
  function getCoinRaisedBonusInWei() external view returns(uint);
  function getCoinRaisedInWei() public view returns(uint);
  function getUsdFromETH(uint ethWei) public view returns(uint);
  function getTokenFromETH(uint ethWei) public view returns(uint);
  function getCurrencyRate(string _ticker) public view returns(uint);
  function addPay(string _ticker, uint value, uint usdAmount, uint coinRaised, uint coinRaisedBonus) public returns(bool);
  function checkTickerExists(string ticker) public view returns(bool);
  function getUsdFromCurrency(string ticker, uint value) public view returns(uint);
  function getUsdFromCurrency(string ticker, uint value, uint usd) public view returns(uint);
  function getUsdFromCurrency(bytes32 ticker, uint value) public view returns(uint);
  function getUsdFromCurrency(bytes32 ticker, uint value, uint usd) public view returns(uint);
  function getTokenWeiFromUSD(uint usdCents) public view returns(uint);
  function editPay(bytes32 ticker, uint currencyValue, uint currencyUsdRaised, uint _usdAbsRaisedInCents, uint _coinRaisedInWei, uint _coinRaisedBonusInWei) public returns(bool);
  function getCurrencyList(string ticker) public view returns(bool active, uint usd, uint devision, uint raised, uint usdRaised, uint usdRaisedExchangeRate, uint counter, uint lastUpdate);
  function getCurrencyList(bytes32 ticker) public view returns(bool active, uint usd, uint devision, uint raised, uint usdRaised, uint usdRaisedExchangeRate, uint counter, uint lastUpdate);
  function getTotalUsdRaisedInCents() public view returns(uint);
  function getAllCurrencyTicker() public view returns(string);
  function getCoinUSDRate() public view  returns(uint);
  function addPreSaleBonus(uint bonusToken) public returns(bool);
  function editPreSaleBonus(uint beforeBonus, uint afterBonus) public returns(bool);
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

 
contract ShipCoinCurrency is ICurrency, MultiOwnable, String {
  using SafeMath for uint256;

  uint private coinUSDRate = 12;  
  uint private currVolPercent = 5;  

   
  uint256 private coinRaisedInWei = 0;
   
  uint private usdAbsRaisedInCents = 0;
  uint private coinRaisedBonusInWei = 0;

  struct CurrencyData {
    bool active;
    uint usd;
    uint devision;
    uint raised;
    uint usdRaised;
    uint counter;
    uint lastUpdate;
  }

  mapping(bytes32 => CurrencyData) private currencyList;

  bytes32[] private currencyTicker;

   
  event ChangeCoinUSDRate(uint oldPrice, uint newPrice);
  event ChangeCurrVolPercent(uint oldPercent, uint newPercent);
  event ChangeCurrency();
  event AddPay();
  event EditPay();

   
  constructor(uint _ethPrice, uint _btcPrice, uint _eurPrice, uint _ambPrice) public {

    require(addUpdateCurrency("ETH", _ethPrice, (1 ether)));
    require(addUpdateCurrency("BTC", _btcPrice, (10**8)));
    require(addUpdateCurrency("USD", 1, 1));
    require(addUpdateCurrency("EUR", _eurPrice, 100));
    require(addUpdateCurrency("AMB", _ambPrice, (1 ether)));

  }

   
  function getUsdAbsRaisedInCents() external view returns(uint) {
    return usdAbsRaisedInCents;
  }

   
  function getCoinRaisedBonusInWei() external view returns(uint) {
    return coinRaisedBonusInWei;
  }

   
  function addUpdateCurrency(string _ticker, uint _usd, uint _devision) public returns(bool) {
    return addUpdateCurrency(_ticker, _usd, _devision, 0, 0);
  }

   
  function addUpdateCurrency(string _ticker, uint _usd) public returns(bool) {
    return addUpdateCurrency(_ticker, _usd, 0, 0, 0);
  }

   
  function addUpdateCurrency(string _ticker, uint _usd, uint _devision, uint _raised, uint _usdRaised) public onlyMultiOwnersType(1) returns(bool) {
    require(_usd > 0, "1");

    bytes32 ticker = stringToBytes32(_ticker);

    if (!currencyList[ticker].active) {
      currencyTicker.push(ticker);
    }
    currencyList[ticker] = CurrencyData({
      active : true,
      usd : _usd,
      devision : (_devision == 0) ? currencyList[ticker].devision : _devision,
      raised : currencyList[ticker].raised > 0 ? currencyList[ticker].raised : _raised,
      usdRaised: currencyList[ticker].usdRaised > 0 ? currencyList[ticker].usdRaised : _usdRaised,
      counter: currencyList[ticker].counter > 0 ? currencyList[ticker].counter : 0,
      lastUpdate: block.timestamp
    });

    return true;
  }

   
  function setCoinUSDRate(uint _value) public onlyOwner returns(bool) {
    require(_value > 0);
    uint oldCoinUSDRate = coinUSDRate;
    coinUSDRate = _value;
    emit ChangeCoinUSDRate(oldCoinUSDRate, coinUSDRate);
    return true;
  }

   
  function setCurrVolPercent(uint _value) public onlyOwner returns(bool) {
    require(_value > 0 && _value <= 10);
    uint oldCurrVolPercent = currVolPercent;
    currVolPercent = _value;
    emit ChangeCurrVolPercent(oldCurrVolPercent, currVolPercent);
    return true;
  }

   
  function getTokenWeiFromUSD(uint usdCents) public view returns(uint) {
    return usdCents.mul(1 ether).div(coinUSDRate);  
  }

   
  function getTokenFromETH(uint ethWei) public view returns(uint) {
    return ethWei.mul(currencyList["ETH"].usd).div(coinUSDRate);  
  }

   
  function getUsdFromETH(uint ethWei) public view returns(uint) {
    return ethWei.mul(currencyList["ETH"].usd).div(1 ether);
  }

   
  function addPay(string _ticker, uint value, uint usdAmount, uint coinRaised, uint coinRaisedBonus) public onlyMultiOwnersType(2) returns(bool) {
    require(value > 0);
    require(usdAmount > 0);
    require(coinRaised > 0);

    bytes32 ticker = stringToBytes32(_ticker);
    assert(currencyList[ticker].active);

    coinRaisedInWei += coinRaised;
    coinRaisedBonusInWei += coinRaisedBonus;
    usdAbsRaisedInCents += usdAmount;

    currencyList[ticker].usdRaised += usdAmount;
    currencyList[ticker].raised += value;
    currencyList[ticker].counter++;

    emit AddPay();
    return true;
  }

   
  function editPay(
    bytes32 ticker,
    uint currencyValue,
    uint currencyUsdRaised,
    uint _usdAbsRaisedInCents,
    uint _coinRaisedInWei,
    uint _coinRaisedBonusInWei
  )
  public
  onlyMultiOwnersType(3)
  returns(bool)
  {
    require(currencyValue > 0);
    require(currencyUsdRaised > 0);
    require(_usdAbsRaisedInCents > 0);
    require(_coinRaisedInWei > 0);
    assert(currencyList[ticker].active);

    coinRaisedInWei = _coinRaisedInWei;
    coinRaisedBonusInWei = _coinRaisedBonusInWei;
    usdAbsRaisedInCents = _usdAbsRaisedInCents;

    currencyList[ticker].usdRaised = currencyUsdRaised;
    currencyList[ticker].raised = currencyValue;


    emit EditPay();

    return true;
  }

   
  function addPreSaleBonus(uint bonusToken) public onlyMultiOwnersType(4) returns(bool) {
    coinRaisedInWei += bonusToken;
    coinRaisedBonusInWei += bonusToken;
    emit EditPay();
    return true;
  }

   
  function editPreSaleBonus(uint beforeBonus, uint afterBonus) public onlyMultiOwnersType(5) returns(bool) {
    coinRaisedInWei -= beforeBonus;
    coinRaisedBonusInWei -= beforeBonus;

    coinRaisedInWei += afterBonus;
    coinRaisedBonusInWei += afterBonus;
    emit EditPay();
    return true;
  }

   
  function getTotalUsdRaisedInCents() public view returns(uint) {
    uint totalUsdAmount = 0;
    if (currencyTicker.length > 0) {
      for (uint i = 0; i < currencyTicker.length; i++) {
        if (currencyList[currencyTicker[i]].raised > 0) {
          totalUsdAmount += getUsdFromCurrency(currencyTicker[i], currencyList[currencyTicker[i]].raised);
        }
      }
    }
    return subPercent(totalUsdAmount, currVolPercent);
  }

   
  function getUsdFromCurrency(string ticker, uint value) public view returns(uint) {
    return getUsdFromCurrency(stringToBytes32(ticker), value);
  }

   
  function getUsdFromCurrency(string ticker, uint value, uint usd) public view returns(uint) {
    return getUsdFromCurrency(stringToBytes32(ticker), value, usd);
  }

   
  function getUsdFromCurrency(bytes32 ticker, uint value) public view returns(uint) {
    return getUsdFromCurrency(ticker, value, 0);
  }

   
  function getUsdFromCurrency(bytes32 ticker, uint value, uint usd) public view returns(uint) {
    if (currencyList[ticker].active && value > 0) {
      return value.mul(usd > 0 ? usd : currencyList[ticker].usd).div(currencyList[ticker].devision);
    }
    return 0;
  }

   
  function getAllCurrencyTicker() public view returns(string) {
    string memory _tickers = "{";
    for (uint i = 0; i < currencyTicker.length; i++) {
      _tickers = strConcat(_tickers, strConcat("\"", bytes32ToString(currencyTicker[i]), "\":"), uint2str(currencyList[currencyTicker[i]].usd), (i+1 < currencyTicker.length) ? "," : "}");
    }
    return _tickers;
  }

   
  function updateCurrency(string ticker, uint value) public onlyMultiOwnersType(6) returns(bool) {
    bytes32 _ticker = stringToBytes32(ticker);
    require(currencyList[_ticker].active);
    require(value > 0);

    currencyList[_ticker].usd = value;
    currencyList[_ticker].lastUpdate = block.timestamp;
    emit ChangeCurrency();
    return true;
  }

   
  function checkTickerExists(string ticker) public view returns(bool) {
    return currencyList[stringToBytes32(ticker)].active;
  }

   
  function getCurrencyList(string ticker)
    public
    view
    returns(
      bool active,
      uint usd,
      uint devision,
      uint raised,
      uint usdRaised,
      uint usdRaisedExchangeRate,
      uint counter,
      uint lastUpdate
    )
  {
    return getCurrencyList(stringToBytes32(ticker));
  }

   
  function getCurrencyList(bytes32 ticker)
    public
    view
    returns(
      bool active,
      uint usd,
      uint devision,
      uint raised,
      uint usdRaised,
      uint usdRaisedExchangeRate,
      uint counter,
      uint lastUpdate
    )
  {
    CurrencyData memory _obj = currencyList[ticker];
    uint _usdRaisedExchangeRate = getUsdFromCurrency(ticker, _obj.raised);
    return (
      _obj.active,
      _obj.usd,
      _obj.devision,
      _obj.raised,
      _obj.usdRaised,
      _usdRaisedExchangeRate,
      _obj.counter,
      _obj.lastUpdate
    );
  }

  function getCurrencyRate(string _ticker) public view returns(uint) {
    return currencyList[stringToBytes32(_ticker)].usd;
  }

   
  function getCurrencyData() public view returns(string) {
    string memory _array = "{";

    if (currencyTicker.length > 0) {
      for (uint i = 0; i < currencyTicker.length; i++) {
        if (currencyList[currencyTicker[i]].active) {
          _array = strConcat(_array, strConcat("\"", bytes32ToString(currencyTicker[i]), "\":"), getJsonCurrencyData(currencyList[currencyTicker[i]]), (i+1 == currencyTicker.length) ? "}" : ",");
        }
      }
    } else {
      return "[]";
    }

    return _array;
  }

   
  function getCoinRaisedInWei() public view returns(uint) {
    return coinRaisedInWei;
  }

   
  function getCoinUSDRate() public view returns(uint) {
    return coinUSDRate;
  }

   
  function getCurrVolPercent() public view returns(uint) {
    return currVolPercent;
  }

   
  function getJsonCurrencyData(CurrencyData memory _obj) private pure returns (string) {
    return strConcat(
      strConcat("{\"usd\":", uint2str(_obj.usd), ",\"devision\":", uint2str(_obj.devision), ",\"raised\":\""),
      strConcat(uint2str(_obj.raised), "\",\"usdRaised\":", uint2str(_obj.usdRaised), ",\"usdRaisedCurrency\":", uint2str((_obj.raised.mul(_obj.usd).div(_obj.devision)))),
      strConcat(",\"counter\":", uint2str(_obj.counter), ",\"lastUpdate\":", uint2str(_obj.lastUpdate), "}")
    );
  }

   
  function subPercent(uint a, uint b) private pure returns(uint) {
    uint c = (a / 100) * b;
    assert(c <= a);
    return a - c;
  }

}