 

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MultistageCrowdsale {
  using SafeMath for uint256;

   
  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

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

   
  function purchase(bytes32 _r, bytes32 _s, bytes32 _payload) public payable {
     
    uint32 time = uint32(_payload >> 160);
    address beneficiary = address(_payload);
     
    require(uint56(_payload >> 192) == uint56(this));
     
    require(ecrecover(keccak256(uint8(0), uint56(_payload >> 192), time, beneficiary), uint8(_payload >> 248), _r, _s) == signer);
    require(beneficiary != address(0));

     
    uint256 rate = getRateAt(now);  
     
    require(rate == getRateAt(time));
     
    uint256 tokens = rate.mul(msg.value).div(1000000000);
     
    require(tokens > 0);

     
    wallet.transfer(msg.value);

     
    ERC20(token).transferFrom(wallet, beneficiary, tokens);
    emit TokenPurchase(beneficiary, msg.value, tokens);
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