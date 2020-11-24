 

contract AirSwap {
    function fill(
      address makerAddress,
      uint makerAmount,
      address makerToken,
      address takerAddress,
      uint takerAmount,
      address takerToken,
      uint256 expiration,
      uint256 nonce,
      uint8 v,
      bytes32 r,
      bytes32 s
    ) payable {}
}

contract P3D {
  uint256 public stakingRequirement;
  function buy(address _referredBy) public payable returns(uint256) {}
  function balanceOf(address _customerAddress) view public returns(uint256) {}
  function exit() public {}
  function calculateTokensReceived(uint256 _ethereumToSpend) public view returns(uint256) {}
  function calculateEthereumReceived(uint256 _tokensToSell) public view returns(uint256) { }
  function myDividends(bool _includeReferralBonus) public view returns(uint256) {}
  function withdraw() public {}
  function totalSupply() public view returns(uint256);
}

contract Pool {
  P3D constant public p3d = P3D(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);

  address public owner;
  uint256 public minimum;

  event Contribution(address indexed caller, address indexed receiver, uint256 contribution, uint256 payout);
  event Approved(address addr);
  event Removed(address addr);
  event OwnerChanged(address owner);
  event MinimumChanged(uint256 minimum);

  constructor() public {
    owner = msg.sender;
  }

  function() external payable {
     
    if (msg.sender != address(p3d)) {
      p3d.buy.value(msg.value)(msg.sender);
      emit Contribution(msg.sender, address(0), msg.value, 0);
    }
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  mapping (address => bool) public approved;

  function approve(address _addr) external onlyOwner() {
    approved[_addr] = true;
    emit Approved(_addr);
  }

  function remove(address _addr) external onlyOwner() {
    approved[_addr] = false;
    emit Removed(_addr);
  }

  function changeOwner(address _newOwner) external onlyOwner() {
    owner = _newOwner;
    emit OwnerChanged(owner);
  }
  
  function changeMinimum(uint256 _minimum) external onlyOwner() {
    minimum = _minimum;
    emit MinimumChanged(minimum);
  }

  function contribute(address _masternode, address _receiver) external payable {
     
    p3d.buy.value(msg.value)(_masternode);
    
    uint256 payout;
    
     
    if (approved[msg.sender] && msg.value >= minimum) {
      payout = p3d.myDividends(true);
      if (payout != 0) {
        p3d.withdraw();
         
        _receiver.transfer(payout);
      }
    }
    
    emit Contribution(msg.sender, _receiver, msg.value, payout);
  }

  function getInfo() external view returns (uint256, uint256) {
    return (
      p3d.balanceOf(address(this)),
      p3d.myDividends(true)
    );
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

contract Dex {
  using SafeMath for uint256;

  AirSwap constant airswap = AirSwap(0x8fd3121013A07C57f0D69646E86E7a4880b467b7);
  Pool constant pool = Pool(0xE00c09fEdD3d3Ed09e2D6F6F6E9B1597c1A99bc8);
  
  function fill(
    address masternode,
    address makerAddress,
    uint256 makerAmount,
    address makerToken,
    uint256 takerAmount,
    address takerToken,
    uint256 expiration,
    uint256 nonce,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public payable {
     
    require(takerToken == address(0));
    
     
    require(makerToken != address(0));
    
     
     
     
     
    uint256[] memory settings = new uint256[](3);
    
     
    settings[0] = takerAmount / 100;

     
    settings[1] = msg.value.sub(settings[0]);
    
     
    settings[2] = makerAddress.balance;
      
     
    require(settings[1] == takerAmount);
    
     
    airswap.fill.value(settings[1])(
      makerAddress,
      makerAmount,
      makerToken,
      msg.sender,
      settings[1],
      takerToken,
      expiration,
      nonce,
      v,
      r,
      s
    );
    
     
    require(makerAddress.balance == (settings[2].add(settings[1])));

     
    if (settings[0] != 0) {
      pool.contribute.value(settings[0])(masternode, msg.sender);
    }
  }
}