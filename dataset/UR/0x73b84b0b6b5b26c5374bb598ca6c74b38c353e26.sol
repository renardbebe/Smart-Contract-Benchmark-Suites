 

pragma solidity ^0.4.23;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract MultistageCrowdsale {
  using SafeMath for uint256;

   
  event TokenPurchase(address indexed purchaser, address indexed affiliate, uint256 value, uint256 amount, bytes4 indexed orderID);

  struct Stage {
    uint32 time;
    uint64 rate;
  }

  Stage[] stages;

  address wallet;
  address token;
  address signer;
  uint32 saleEndTime;

   
  constructor(
    uint256[] _timesAndRates,
    address _wallet,
    address _token,
    address _signer
  )
    public
  {
    require(_wallet != address(0));
    require(_token != address(0));

    storeStages(_timesAndRates);

    saleEndTime = uint32(_timesAndRates[_timesAndRates.length - 1]);
     
    require(saleEndTime > stages[stages.length - 1].time);

    wallet = _wallet;
    token = _token;
    signer = _signer;
  }

   

  function invest(bytes32 _r, bytes32 _s, bytes32 _a, bytes32 _b) public payable {
     
    uint32 time = uint32(_b >> 224);
    address beneficiary = address(_a);
    uint256 oobpa = uint64(_b >> 160);
    address affiliate = address(_b);
     
    require(uint56(_a >> 192) == uint56(this));
    if (oobpa == 0) {
      oobpa = msg.value;
    }
    bytes4 orderID = bytes4(uint32(_a >> 160));
     
    require(ecrecover(keccak256(abi.encodePacked(uint8(0), uint248(_a), _b)), uint8(_a >> 248), _r, _s) == signer);
    require(beneficiary != address(0));

     
    uint256 rate = getRateAt(now);  
     
    require(rate == getRateAt(time));
     
    uint256 tokens = rate.mul(oobpa).div(1000000000);
     
    require(tokens > 0);

     
    if (msg.value > 0) {
      wallet.transfer(oobpa);
    }

     
    ERC20(token).transferFrom(wallet, beneficiary, tokens);
    emit TokenPurchase(beneficiary, affiliate, oobpa, tokens, orderID);
  }

  function getParams() view public returns (uint256[] _times, uint256[] _rates, address _wallet, address _token, address _signer) {
    _times = new uint256[](stages.length + 1);
    _rates = new uint256[](stages.length);
    for (uint256 i = 0; i < stages.length; i++) {
      _times[i] = stages[i].time;
      _rates[i] = stages[i].rate;
    }
    _times[stages.length] = saleEndTime;
    _wallet = wallet;
    _token = token;
    _signer = signer;
  }

  function storeStages(uint256[] _timesAndRates) internal {
     
    require(_timesAndRates.length % 2 == 1);
     
    require(_timesAndRates.length >= 3);

    for (uint256 i = 0; i < _timesAndRates.length / 2; i++) {
      stages.push(Stage(uint32(_timesAndRates[i * 2]), uint64(_timesAndRates[(i * 2) + 1])));
      if (i > 0) {
         
        require(stages[i-1].time < stages[i].time);
         
        require(stages[i-1].rate > stages[i].rate);
      }
    }

     
    require(stages[0].time > now);  

     
    require(stages[stages.length - 1].rate > 0);
  }

  function getRateAt(uint256 _now) view internal returns (uint256 rate) {
     
    if (_now < stages[0].time) {
      return 0;
    }

    for (uint i = 1; i < stages.length; i++) {
      if (_now < stages[i].time)
        return stages[i - 1].rate;
    }

     
    if (_now < saleEndTime)
      return stages[stages.length - 1].rate;

     
    return 0;
  }

}

library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}