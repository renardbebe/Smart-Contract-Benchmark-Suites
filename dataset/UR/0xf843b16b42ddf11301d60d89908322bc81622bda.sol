 

pragma solidity ^0.4.18;

 

 
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

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

 

 
contract Distribution is Ownable {
  using SafeMath for uint256;

  uint16 public stages;
  uint256 public stageDuration;
  uint256 public startTime;

  uint256 public soldTokens;
  uint256 public bonusClaimedTokens;
  uint256 public raisedETH;
  uint256 public raisedUSD;

  uint256 public weiUsdRate;

  BurnableToken public token;

  bool public isActive;
  uint256 public cap;
  uint256 public stageCap;

  mapping (address => mapping (uint16 => uint256)) public contributions;
  mapping (uint16 => uint256) public sold;
  mapping (uint16 => bool) public burned;
  mapping (address => mapping (uint16 => bool)) public claimed;

  event NewPurchase(
    address indexed purchaser,
    uint256 sdtAmount,
    uint256 usdAmount,
    uint256 ethAmount
  );

  event NewBonusClaim(
    address indexed purchaser,
    uint256 sdtAmount
  );

  function Distribution(
      uint16 _stages,
      uint256 _stageDuration,
      address _token
  ) public {
    stages = _stages;
    stageDuration = _stageDuration;
    isActive = false;
    token = BurnableToken(_token);
  }

   
  function () external payable {
    require(isActive);
    require(weiUsdRate > 0);
    require(getStage() < stages);

    uint256 usd = msg.value / weiUsdRate;
    uint256 tokens = computeTokens(usd);
    uint16 stage = getStage();

    sold[stage] = sold[stage].add(tokens);
    require(sold[stage] < stageCap);

    contributions[msg.sender][stage] = contributions[msg.sender][stage].add(tokens);
    soldTokens = soldTokens.add(tokens);
    raisedETH = raisedETH.add(msg.value);
    raisedUSD = raisedUSD.add(usd);

    NewPurchase(msg.sender, tokens, usd, msg.value);
    token.transfer(msg.sender, tokens);
  }

   
  function init(uint256 _cap, uint256 _startTime) public onlyOwner {
    require(!isActive);
    require(token.balanceOf(this) == _cap);
    require(_startTime > block.timestamp);

    startTime = _startTime;
    cap = _cap;
    stageCap = cap / stages;
    isActive = true;
  }

   
  function claimBonus(uint16 _stage) public {
    require(!claimed[msg.sender][_stage]);
    require(getStage() > _stage);

    if (!burned[_stage]) {
      token.burn(stageCap.sub(sold[_stage]).sub(sold[_stage].mul(computeBonus(_stage)).div(1 ether)));
      burned[_stage] = true;
    }

    uint256 tokens = computeAddressBonus(_stage);
    token.transfer(msg.sender, tokens);
    bonusClaimedTokens = bonusClaimedTokens.add(tokens);
    claimed[msg.sender][_stage] = true;

    NewBonusClaim(msg.sender, tokens);
  }

   
  function setWeiUsdRate(uint256 _rate) public onlyOwner {
    require(_rate > 0);
    weiUsdRate = _rate;
  }

   
  function forwardFunds(uint256 _amount, address _address) public onlyOwner {
    _address.transfer(_amount);
  }

   
  function computeTokens(uint256 _usd) public view returns(uint256) {
    return _usd.mul(1000000000000000000 ether).div(
      soldTokens.mul(19800000000000000000).div(cap).add(200000000000000000)
    );
  }

   
  function getStage() public view returns(uint16) {
    require(block.timestamp >= startTime);
    return uint16(uint256(block.timestamp).sub(startTime).div(stageDuration));
  }

   
  function computeBonus(uint16 _stage) public view returns(uint256) {
    return uint256(100000000000000000).sub(sold[_stage].mul(100000).div(441095890411));
  }

   
  function computeAddressBonus(uint16 _stage) public view returns(uint256) {
    return contributions[msg.sender][_stage].mul(computeBonus(_stage)).div(1 ether);
  }

   
   
   
   
   
   
   
  function claimTokens(address _token) public onlyOwner {
     
    require(_token != address(token));
    if (_token == 0x0) {
      owner.transfer(this.balance);
      return;
    }

    ERC20Basic erc20token = ERC20Basic(_token);
    uint256 balance = erc20token.balanceOf(this);
    erc20token.transfer(owner, balance);
    ClaimedTokens(_token, owner, balance);
  }

  event ClaimedTokens(
    address indexed _token,
    address indexed _controller,
    uint256 _amount
  );
}