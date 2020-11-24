 

 


 

pragma solidity >=0.5.0 <0.6.0;


 
contract IRatesProvider {

  function defineRatesExternal(uint256[] calldata _rates) external returns (bool);

  function name() public view returns (string memory);

  function rate(bytes32 _currency) public view returns (uint256);

  function currencies() public view
    returns (bytes32[] memory, uint256[] memory, uint256);
  function rates() public view returns (uint256, uint256[] memory);

  function convert(uint256 _amount, bytes32 _fromCurrency, bytes32 _toCurrency)
    public view returns (uint256);

  function defineCurrencies(
    bytes32[] memory _currencies,
    uint256[] memory _decimals,
    uint256 _rateOffset) public returns (bool);
  function defineRates(uint256[] memory _rates) public returns (bool);

  event RateOffset(uint256 rateOffset);
  event Currencies(bytes32[] currencies, uint256[] decimals);
  event Rate(bytes32 indexed currency, uint256 rate);
}

 

pragma solidity >=0.5.0 <0.6.0;


 
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

 

pragma solidity >=0.5.0 <0.6.0;


 
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

 

pragma solidity >=0.5.0 <0.6.0;



 
contract Operable is Ownable {

  mapping (address => bool) private operators_;

   
  modifier onlyOperator {
    require(operators_[msg.sender], "OP01");
    _;
  }

   
  constructor() public {
    defineOperator("Owner", msg.sender);
  }

   
  function isOperator(address _address) public view returns (bool) {
    return operators_[_address];
  }

   
  function removeOperator(address _address) public onlyOwner {
    require(operators_[_address], "OP02");
    operators_[_address] = false;
    emit OperatorRemoved(_address);
  }

   
  function defineOperator(string memory _role, address _address)
    public onlyOwner
  {
    require(!operators_[_address], "OP03");
    operators_[_address] = true;
    emit OperatorDefined(_role, _address);
  }

  event OperatorRemoved(address address_);
  event OperatorDefined(
    string role,
    address address_
  );
}

 

pragma solidity >=0.5.0 <0.6.0;





 
contract RatesProvider is IRatesProvider, Operable {
  using SafeMath for uint256;

  string internal name_;

   
   
   
   
  uint256 internal rateOffset_ = 1;

   
  bytes32[] internal currencies_ =
    [ bytes32("ETH"), "BTC", "EOS", "GBP", "USD", "CHF", "EUR", "CNY", "JPY", "CAD", "AUD" ];
  uint256[] internal decimals_ = [ uint256(18), 8, 4, 2, 2, 2, 2, 2, 2, 2, 2 ];

  mapping(bytes32 => uint256) internal ratesMap;
  uint256[] internal rates_ = new uint256[](currencies_.length-1);
  uint256 internal updatedAt_;

   
  constructor(string memory _name) public {
    name_ = _name;
    for (uint256 i=0; i < currencies_.length; i++) {
      ratesMap[currencies_[i]] = i;
    }
  }

   
  function defineRatesExternal(uint256[] calldata _rates)
    external onlyOperator returns (bool)
  {
    require(_rates.length < currencies_.length, "RP03");

     
    updatedAt_ = now;
    for (uint256 i=0; i < _rates.length; i++) {
      if (rates_[i] != _rates[i]) {
        rates_[i] = _rates[i];
        emit Rate(currencies_[i+1], _rates[i]);
      }
    }
    return true;
  }

   
  function name() public view returns (string memory) {
    return name_;
  }

   
  function rate(bytes32 _currency) public view returns (uint256) {
    return ratePrivate(_currency);
  }

   
  function currencies() public view
    returns (bytes32[] memory, uint256[] memory, uint256)
  {
    return (currencies_, decimals_, rateOffset_);
  }

   
  function rates() public view returns (uint256, uint256[] memory) {
    return (updatedAt_, rates_);
  }

   
  function convert(uint256 _amount, bytes32 _fromCurrency, bytes32 _toCurrency)
    public view returns (uint256)
  {
    if (_fromCurrency == _toCurrency) {
      return _amount;
    }

    uint256 rateFrom = (_fromCurrency != currencies_[0]) ?
      ratePrivate(_fromCurrency) : rateOffset_;
    uint256 rateTo = (_toCurrency != currencies_[0]) ?
      ratePrivate(_toCurrency) : rateOffset_;

    return (rateTo != 0) ?
      _amount.mul(rateFrom).div(rateTo) : 0;
  }

   
  function defineCurrencies(
    bytes32[] memory _currencies,
    uint256[] memory _decimals,
    uint256 _rateOffset) public onlyOperator returns (bool)
  {
    require(_currencies.length == _decimals.length, "RP01");
    require(_rateOffset != 0, "RP02");

    for (uint256 i= _currencies.length; i < currencies_.length; i++) {
      delete ratesMap[currencies_[i]];
      emit Rate(currencies_[i], 0);
    }
    rates_.length = _currencies.length-1;

    bool hasBaseCurrencyChanged = _currencies[0] != currencies_[0];
    for (uint256 i=1; i < _currencies.length; i++) {
      bytes32 currency = _currencies[i];
      if (rateOffset_ != _rateOffset
        || ratesMap[currency] != i
        || hasBaseCurrencyChanged)
      {
        ratesMap[currency] = i;
        rates_[i-1] = 0;

        if (i < currencies_.length) {
          emit Rate(currencies_[i], 0);
        }
      }
    }

    if (rateOffset_ != _rateOffset) {
      emit RateOffset(_rateOffset);
      rateOffset_ = _rateOffset;
    }

     
    updatedAt_ = now;
    currencies_ = _currencies;
    decimals_ = _decimals;

    emit Currencies(_currencies, _decimals);
    return true;
  }
  
   
  function defineRates(uint256[] memory _rates)
    public onlyOperator returns (bool)
  {
    require(_rates.length < currencies_.length, "RP03");

     
    updatedAt_ = now;
    for (uint256 i=0; i < _rates.length; i++) {
      if (rates_[i] != _rates[i]) {
        rates_[i] = _rates[i];
        emit Rate(currencies_[i+1], _rates[i]);
      }
    }
    return true;
  }

   
  function ratePrivate(bytes32 _currency) private view returns (uint256) {
    if (_currency == currencies_[0]) {
      return 1;
    }

    uint256 id = ratesMap[_currency];
    return (id > 0) ? rates_[id-1] : 0;
  }
}