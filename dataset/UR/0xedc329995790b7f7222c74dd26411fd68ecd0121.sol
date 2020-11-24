 

pragma solidity 0.4.19;

 
 
contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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
 

 
 
contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 

 
contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
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


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
}
 

 
 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require (!paused);
    _;
  }

   
  modifier whenPaused {
    require (paused) ;
    _;
  }

   
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}
 

 
contract TomoCoin is StandardToken, Pausable {
  string public constant name = 'Tomocoin';
  string public constant symbol = 'TOMO';
  uint256 public constant decimals = 18;
  address public tokenSaleAddress;
  address public tomoDepositAddress;  

  uint256 public constant tomoDeposit = 100000000 * 10**decimals;

  function TomoCoin(address _tomoDepositAddress) public { 
    tomoDepositAddress = _tomoDepositAddress;

    balances[tomoDepositAddress] = tomoDeposit;
    Transfer(0x0, tomoDepositAddress, tomoDeposit);
    totalSupply_ = tomoDeposit;
  }

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
    return super.transfer(_to,_value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
    return super.approve(_spender, _value);
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return super.balanceOf(_owner);
  }

   
  function setTokenSaleAddress(address _tokenSaleAddress) public onlyOwner {
    if (_tokenSaleAddress != address(0)) {
      tokenSaleAddress = _tokenSaleAddress;
    }
  }

  function mint(address _recipient, uint256 _value) public whenNotPaused returns (bool success) {
      require(_value > 0);
       
      require(msg.sender == tokenSaleAddress);

      balances[tomoDepositAddress] = balances[tomoDepositAddress].sub(_value);
      balances[ _recipient ] = balances[_recipient].add(_value);

      Transfer(tomoDepositAddress, _recipient, _value);
      return true;
  }
}
 


 
contract TomoContributorWhitelist is Ownable {
    mapping(address => uint256) public whitelist;

    function TomoContributorWhitelist() public {}

    event ListAddress( address _user, uint256 cap, uint256 _time );

    function listAddress( address _user, uint256 cap ) public onlyOwner {
        whitelist[_user] = cap;
        ListAddress( _user, cap, now );
    }

    function listAddresses( address[] _users, uint256[] _caps ) public onlyOwner {
        for( uint i = 0 ; i < _users.length ; i++ ) {
            listAddress( _users[i], _caps[i] );
        }
    }

    function getCap( address _user ) public view returns(uint) {
        return whitelist[_user];
    }
}
 

 
contract TomoTokenSale is Pausable {
  using SafeMath for uint256;

  TomoCoin tomo;
  TomoContributorWhitelist whitelist;
  mapping(address => uint256) public participated;

  address public ethFundDepositAddress;
  address public tomoDepositAddress;

  uint256 public constant tokenCreationCap = 4000000 * 10**18;
  uint256 public totalTokenSold = 0;
  uint256 public constant fundingStartTime = 1519876800;  
  uint256 public constant fundingPoCEndTime = 1519963200;  
  uint256 public constant fundingEndTime = 1520136000;  
  uint256 public constant minContribution = 0.1 ether;
  uint256 public constant maxContribution = 10 ether;
  uint256 public constant tokenExchangeRate = 3200;
  uint256 public constant maxCap = tokenExchangeRate * maxContribution;

  bool public isFinalized;

  event MintTomo(address from, address to, uint256 val);
  event RefundTomo(address to, uint256 val);

  function TomoTokenSale(
    TomoCoin _tomoCoinAddress,
    TomoContributorWhitelist _tomoContributorWhitelistAddress,
    address _ethFundDepositAddress,
    address _tomoDepositAddress
  ) public
  {
    tomo = TomoCoin(_tomoCoinAddress);
    whitelist = TomoContributorWhitelist(_tomoContributorWhitelistAddress);
    ethFundDepositAddress = _ethFundDepositAddress;
    tomoDepositAddress = _tomoDepositAddress;

    isFinalized = false;
  }

  function buy(address to, uint256 val) internal returns (bool success) {
    MintTomo(tomoDepositAddress, to, val);
    return tomo.mint(to, val);
  }

  function () public payable {    
    createTokens(msg.sender, msg.value);
  }

  function createTokens(address _beneficiary, uint256 _value) internal whenNotPaused {
    require (now >= fundingStartTime);
    require (now <= fundingEndTime);
    require (_value >= minContribution);
    require (_value <= maxContribution);
    require (!isFinalized);

    uint256 tokens = _value.mul(tokenExchangeRate);

    uint256 cap = whitelist.getCap(_beneficiary);
    require (cap > 0);

    uint256 tokensToAllocate = 0;
    uint256 tokensToRefund = 0;
    uint256 etherToRefund = 0;

     
    if (now <= fundingPoCEndTime) {
      tokensToAllocate = cap.sub(participated[_beneficiary]);
    } else {
      tokensToAllocate = maxCap.sub(participated[_beneficiary]);
    }

     
    if (tokens > tokensToAllocate) {
      tokensToRefund = tokens.sub(tokensToAllocate);
      etherToRefund = tokensToRefund.div(tokenExchangeRate);
    } else {
       
      tokensToAllocate = tokens;
    }

    uint256 checkedTokenSold = totalTokenSold.add(tokensToAllocate);

     
    if (tokenCreationCap < checkedTokenSold) {
      tokensToAllocate = tokenCreationCap.sub(totalTokenSold);
      tokensToRefund   = tokens.sub(tokensToAllocate);
      etherToRefund = tokensToRefund.div(tokenExchangeRate);
      totalTokenSold = tokenCreationCap;
    } else {
      totalTokenSold = checkedTokenSold;
    }

     
    participated[_beneficiary] = participated[_beneficiary].add(tokensToAllocate);

     
    require(buy(_beneficiary, tokensToAllocate));
    if (etherToRefund > 0) {
       
      RefundTomo(msg.sender, etherToRefund);
      msg.sender.transfer(etherToRefund);
    }
    ethFundDepositAddress.transfer(this.balance);
    return;
  }

   
  function finalize() external onlyOwner {
    require (!isFinalized);
     
    isFinalized = true;
    ethFundDepositAddress.transfer(this.balance);
  }
}