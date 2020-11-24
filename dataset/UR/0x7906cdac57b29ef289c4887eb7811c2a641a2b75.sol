 

pragma solidity 0.4.24;

 
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

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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
    uint256 _addedValue
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
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

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

 
contract Pausable is Ownable  {
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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

contract NIX is StandardToken, Pausable {

    string public name; 
    string public symbol;
    uint8 public decimals;
     
    uint256 public TOKEN_RESERVED = 35e5 * 10 **18;
    uint256 public TOKEN_FOUNDERS_TEAMS = 525e4 * 10 **18;
    uint256 public TOKEN_ADVISORS = 175e4 * 10 **18;
    uint256 public TOKEN_MARKETING = 175e3 * 10 **18;

   constructor () public {
        name = "Encrypt Index";
        symbol = "NIX";
        decimals = 18;
        totalSupply_ = 35e6 * 10  **  uint256(decimals);  
        balances[owner] = totalSupply_;
   }
}

contract Sale is NIX{

    using SafeMath for uint256;
     
    uint256 public saleStatus; 
     
    uint256 public saleType; 
     
    uint256 public tokenCostPrivate = 8;  
     
    uint256 public tokenCostPre = 9;  
     
    uint256 public tokenCostPublic = 10;  
     
    uint256 public ETH_USD;
     
    uint256 public minContribution = 1000000;  
     
    address public wallet;
     
    uint256 public softCap = 500000000;  
     
    uint256 public hardCap = 1500000000;  
     
    uint256 public weiRaised;
     
    bool public whitelistingEnabled = false;

     
    struct Investor {
        uint256 weiReceived;
        uint256 tokenSent;
    }

     
    mapping(address => Investor) public investors;
     
    mapping (address => bool) public whitelisted;

    
     
    constructor (address _wallet, uint256 _ETH_USD) public{
      require(_wallet != address(0x0), "wallet address must not be zero");
      wallet = _wallet;
      ETH_USD = _ETH_USD;
    }
    
     
    function () external payable{
        createTokens(msg.sender);
    }

     
    function changeWallet(address _wallet) public onlyOwner{
      require(_wallet != address(0x0), "wallet address must not be zero");
      wallet = _wallet;
    }

     
    function drain() external onlyOwner{
      wallet.transfer(address(this).balance);
    }

     
    function toggleWhitelist() public onlyOwner{
        whitelistingEnabled = !whitelistingEnabled;
    }

     
    function changeETH_USD(uint256 _ETH_USD) public onlyOwner{
        ETH_USD = _ETH_USD;
    }

     
    function whitelistAddress(address investor) public onlyOwner{
        require(!whitelisted[investor], "users is already whitelisted");
        whitelisted[investor] = true;
    }

     
    function startPrivateSale(uint256 _ETH_USD) public onlyOwner{
      require (saleStatus == 0);
      ETH_USD = _ETH_USD;
      saleStatus = 1;
    }

     
    function startPreSale(uint256 _ETH_USD) public onlyOwner{
      require (saleStatus == 1 && saleType == 0);
      ETH_USD = _ETH_USD;
      saleType = 1;
    }

     
    function startPublicSale(uint256 _ETH_USD) public onlyOwner{
      require (saleStatus == 1 && saleType == 1);
      ETH_USD = _ETH_USD;
      saleType = 2;
    }

     
    function changeMinContribution(uint256 _minContribution) public onlyOwner {
        require(_minContribution > 0, "min contribution should be greater than 0");
        minContribution = _minContribution;
    }

     
    function createTokens(address _beneficiary) internal {
       _preValidatePurchase(_beneficiary, msg.value);
       
      uint256 totalNumberOfTokenTransferred = _getTokenAmount(msg.value);

       
      transferTokens(_beneficiary, totalNumberOfTokenTransferred);

       
      Investor storage _investor = investors[_beneficiary];
       
      _investor.tokenSent = _investor.tokenSent.add(totalNumberOfTokenTransferred);
      _investor.weiReceived = _investor.weiReceived.add(msg.value);
      weiRaised = weiRaised.add(msg.value);
      wallet.transfer(msg.value);
    }
    
    function transferTokens(address toAddr, uint256 value) private{
        balances[owner] = balances[owner].sub(value);
        balances[toAddr] = balances[toAddr].add(value);
        emit Transfer(owner, toAddr, value);
    }

     

    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
      if(saleType == 0){
        return (_weiAmount.mul(ETH_USD).mul(100)).div((tokenCostPrivate).mul(80));  
      }else if(saleType == 1){
        return (_weiAmount.mul(ETH_USD).mul(100)).div((tokenCostPrivate).mul(90));  
      }else if (saleType == 2){
        return (_weiAmount.mul(ETH_USD).mul(100)).div((tokenCostPrivate).mul(95));  
      }
    }

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) whenNotPaused internal view{
      require(_beneficiary != address(0), "beneficiary address must not be zero");
      require(whitelistingEnabled == false || whitelisted[_beneficiary],
                "whitelisting should be disabled or users should be whitelisted");
       
      assert(saleStatus == 1);
      require(_weiAmount >= getMinContributionInWei(), "amount is less than min contribution" );
    }

     
    function getMinContributionInWei() public view returns(uint256){
      return (minContribution.mul(1e18)).div(ETH_USD);
    }

     
    function usdRaised() public view returns (uint256) {
      return weiRaised.mul(ETH_USD).div(1e18);
    }

     
    function isSoftCapReached() public view returns (bool) {
      if(usdRaised() >= softCap){
        return true;
      }
    }

     
    function isHardCapReached() public view returns (bool) {
      if(usdRaised() >= hardCap){
        return true;
      }
    }

}