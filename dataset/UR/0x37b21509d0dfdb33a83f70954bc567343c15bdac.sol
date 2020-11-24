 

pragma solidity ^0.4.24;

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

   
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

   
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

   
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

 

 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
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

 

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

contract COE is MintableToken, BurnableToken, RBAC {
  using SafeMath for uint256;

  string public constant name = "CoinMarketCap Coeval by Synthchain";
  string public constant symbol = "CMC-COE";
  uint8 public constant decimals = 18;

   
  uint public ethRaised = 58124022054610641246;

  string public constant ROLE_WHITELISTED = "whitelist";
  string public constant ROLE_ADMIN = "admin";
  string public constant ROLE_SUPER = "super";

  uint public swapLimit;
  uint public constant CYCLE_CAP = 100000 * (10 ** uint256(decimals));
  uint public constant BILLION = 10 ** 9;

  event SwapStarted(uint256 startTime);
  event MiningRestart(uint256 endTime);
  event CMCUpdate(string updateType, uint value);

  uint offset = 10**18;
   
  uint public exchangeRateMNY;
  uint public exchangeRateFUTX;

   
  uint public cycleMintSupply = 0;
  bool public isMiningOpen = false;
  uint public CMC = 236346228108;
  uint public cycleEndTime;

  address public constant ZUR = 0x3A4b527dcd618cCea50aDb32B3369117e5442A2F;
  address public constant MNY = 0xD2354AcF1a2f06D69D8BC2e2048AaBD404445DF6;
  address public constant FUTX = 0x8b7d07b6ffB9364e97B89cEA8b84F94249bE459F;

  constructor() public {
     
    owner = this;
    totalSupply_ = 0;
    addRole(msg.sender, ROLE_ADMIN);
    addRole(msg.sender, ROLE_SUPER);
    addRole(msg.sender, ROLE_WHITELISTED);

     
    exchangeRateMNY = offset.mul(offset).div(CMC.mul(offset).div(BILLION)).mul(65).div(100);
    exchangeRateFUTX = offset.mul(offset).div(uint(29997535964).mul(offset).div(uint(123943034521)).mul(CMC).div(BILLION)).mul(65).div(100);
  }

  function () external payable {
    buyTokens(msg.sender);
  }

  function donateEth() external payable {
     
    ethRaised += msg.value;
  }

  uint public presaleFee = 0;
  uint8 public presaleLevel = 11;
  uint public coePerEthOffset = offset.div(presaleLevel).mul(650);
  bool public presaleOpen = true;
  uint public ethRateExpiration = now + 1 days;
  uint public coeRemainingAtCurrentRate = 715997995035396254194;

  function startPresale() onlyAdmin public {
    require(!presaleOpen && presaleLevel == 1);
    ethRateExpiration = now + 1 days;
    presaleOpen = true;
  }

  function buyTokens(address _beneficiary) public payable {
    require(presaleOpen);
    require(msg.value > 0);
    ethRaised += msg.value;
    uint buyingPower = msg.value;
    presaleFee += buyingPower.mul(65).div(100);
    uint tokens = 0;
    uint zurFeed = 0;

    if (now > ethRateExpiration) {
      incrementLevel(buyingPower);
    }

    while(buyingPower > 0) {
      uint ethToFillLevel = coeRemainingAtCurrentRate.mul(65).div(100).mul(offset).div(coePerEthOffset);
      if (buyingPower >= ethToFillLevel) {
        buyingPower -= ethToFillLevel;
        tokens += coeRemainingAtCurrentRate.mul(65).div(100);
        zurFeed += coeRemainingAtCurrentRate.mul(35).div(100);
        coeRemainingAtCurrentRate = 0;
      } else {
        tokens += buyingPower.mul(coePerEthOffset).div(offset);
        zurFeed += buyingPower.mul(coePerEthOffset).div(offset).mul(35).div(65);
        coeRemainingAtCurrentRate = coeRemainingAtCurrentRate.sub(buyingPower.mul(coePerEthOffset).mul(100).div(65).div(offset));
        buyingPower = 0;
      }

      if (coeRemainingAtCurrentRate == 0) {
        incrementLevel(buyingPower);

        if (!presaleOpen) {
           
          tokens += (CYCLE_CAP - cycleMintSupply - tokens - zurFeed);
          break;
        }
      }
    }

    cycleMintSupply += (tokens + zurFeed);
    if (!presaleOpen) {
       
      _startSwap();
    }
    MintableToken(this).mint(_beneficiary, tokens);
    MintableToken(this).mint(ZUR, zurFeed);
  }

  function incrementLevel(uint buyingPower) private {
    if (presaleLevel == 100) {
      if (buyingPower > 0) {
         
        presaleFee -= buyingPower.mul(65).div(100);
        ethRaised -= buyingPower;
        msg.sender.transfer(buyingPower);
      }
      presaleOpen = false;
    } else {
      presaleLevel++;
      coeRemainingAtCurrentRate += 1000 ether;
      coePerEthOffset = offset.div(presaleLevel).mul(650);
      ethRateExpiration = now + 1 days;
    }
  }

  modifier canMine() {
    require(isMiningOpen);
    _;
  }

   
  function mine(uint amount) canMine public {
    require(amount > 0);
    require(cycleMintSupply < CYCLE_CAP);
    require(ERC20(MNY).transferFrom(msg.sender, address(this), amount));

    uint refund = _mine(exchangeRateMNY, amount);
    if(refund > 0) {
      ERC20(MNY).transfer(msg.sender, refund);
    }
    if (cycleMintSupply == CYCLE_CAP) {
       
      _startSwap();
    }
  }

   
  function whitelistMine(uint amount) canMine onlyIfWhitelisted public {
    require(amount > 0);
    require(cycleMintSupply < CYCLE_CAP);
    require(ERC20(FUTX).transferFrom(msg.sender, address(this), amount));

    uint refund = _mine(exchangeRateFUTX, amount);
    if(refund > 0) {
      ERC20(FUTX).transfer(msg.sender, refund);
    }
    if (cycleMintSupply == CYCLE_CAP) {
       
      _startSwap();
    }
  }

  function _mine(uint _rate, uint _inAmount) private returns (uint) {
    assert(_rate > 0);

     
    if (now > cycleEndTime && cycleMintSupply > 0) {
      _startSwap();
      return _inAmount;
    }
    uint tokens = _rate.mul(_inAmount).div(offset);
    uint refund = 0;

     
    uint zurFeed = tokens.mul(35).div(65);

    if (tokens + zurFeed + cycleMintSupply > CYCLE_CAP) {
      uint overage = tokens + zurFeed + cycleMintSupply - CYCLE_CAP;
      uint tokenOverage = overage.mul(65).div(100);
      zurFeed -= (overage - tokenOverage);
      tokens -= tokenOverage;

       
      refund = tokenOverage.mul(offset).div(_rate);
    }
    cycleMintSupply += (tokens + zurFeed);
    require(zurFeed > 0, "Mining payment too small.");
    MintableToken(this).mint(msg.sender, tokens);
    MintableToken(this).mint(ZUR, zurFeed);

    return refund;
  }

   
  bool public swapOpen = false;
  uint public ethSwapRate;
  mapping(address => uint) public swapRates;

  function _startSwap() private {
    swapOpen = true;
    isMiningOpen = false;

     
     
    swapLimit = cycleMintSupply.mul(35).div(100);
    ethSwapRate = (address(this).balance.sub(presaleFee)).mul(offset).mul(35).div(100).div(swapLimit);
    swapRates[FUTX] = ERC20(FUTX).balanceOf(address(this)).mul(offset).mul(35).div(100).div(swapLimit);
    swapRates[MNY] = ERC20(MNY).balanceOf(address(this)).mul(offset).mul(35).div(100).div(swapLimit);

    emit SwapStarted(now);
  }

  function swap(uint amt) public {
    require(swapOpen && swapLimit > 0);
    if (amt > swapLimit) {
      amt = swapLimit;
    }
    swapLimit -= amt;
     
    burn(amt);

    if (amt.mul(ethSwapRate) > 0) {
      msg.sender.transfer(amt.mul(ethSwapRate).div(offset));
    }

    if (amt.mul(swapRates[FUTX]) > 0) {
      ERC20(FUTX).transfer(msg.sender, amt.mul(swapRates[FUTX]).div(offset));
    }

    if (amt.mul(swapRates[MNY]) > 0) {
      ERC20(MNY).transfer(msg.sender, amt.mul(swapRates[MNY]).div(offset));
    }

    if (swapLimit == 0) {
      _restart();
    }
  }

  function _restart() private {
    require(swapOpen);
    require(swapLimit == 0);

    cycleMintSupply = 0;
    swapOpen = false;
    isMiningOpen = true;
    cycleEndTime = now + 100 days;

    emit MiningRestart(cycleEndTime);
  }

  function updateCMC(uint _cmc) private {
    require(_cmc > 0);
    CMC = _cmc;
    emit CMCUpdate("TOTAL_CMC", _cmc);
    exchangeRateMNY = offset.mul(offset).div(CMC.mul(offset).div(BILLION)).mul(65).div(100);
  }

  function updateCMC(uint _cmc, uint _btc, uint _eth) public onlyAdmin{
    require(_btc > 0 && _eth > 0);
    updateCMC(_cmc);
    emit CMCUpdate("BTC_CMC", _btc);
    emit CMCUpdate("ETH_CMC", _eth);
    exchangeRateFUTX = offset.mul(offset).div(_eth.mul(offset).div(_btc).mul(CMC).div(BILLION)).mul(65).div(100);
  }

  modifier onlyIfWhitelisted() {
    checkRole(msg.sender, ROLE_WHITELISTED);
    _;
  }

  modifier onlySuper() {
    checkRole(msg.sender, ROLE_SUPER);
    _;
  }

  modifier onlyAdmin() {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }

  function addAdmin(address _addr) public onlySuper {
    addRole(_addr, ROLE_ADMIN);
  }

  function removeAdmin(address _addr) public onlySuper {
    removeRole(_addr, ROLE_ADMIN);
  }

  function changeSuper(address _addr) public onlySuper {
    addRole(_addr, ROLE_SUPER);
    removeRole(msg.sender, ROLE_SUPER);
  }

  function addAddressToWhitelist(address _operator)
    public
    onlySuper
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

  function addAddressesToWhitelist(address[] _operators)
    public
    onlySuper
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

  function removeAddressFromWhitelist(address _operator)
    public
    onlySuper
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

  function removeAddressesFromWhitelist(address[] _operators)
    public
    onlySuper
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

   
  bool public distributing = true;

  function endDistribution() onlySuper public {
    distributing = false;
  }

  function distribute(address _payee, uint _amt) onlySuper public {
    require(_payee != address(0));
    require(distributing);
    cycleMintSupply += _amt;
    MintableToken(this).mint(_payee, _amt);
  }

  function distributeList(address[] _payees, uint[] _amts) onlySuper external {
    require(_payees.length == _amts.length);
    require(_payees.length > 0);

    for (uint i = 0; i < _payees.length; i++) {
      distribute(_payees[i], _amts[i]);
    }

  }

  function payFees() public {
    require(presaleFee > 0);
    uint feeShare = presaleFee.div(13);
    if (feeShare > 0) {
      address(0x17F619855432168f2aB5A1B2133888d9ffCC3946).transfer(feeShare);
      address(0xAaf47A27BBd9B82ee0f1f77C7b437A36160c4242).transfer(feeShare * 4);
      address(0x38eEE50cd8FAB1426C2c5baCF9b1C2A3740c024B).transfer(feeShare * 4);
      address(0x5d2b9f5345e69E2390cE4C26ccc9C2910A097520).transfer(feeShare);
      address(0xcf5Ee528278a57Ba087684f685D99A6a5EC4c439).transfer(feeShare * 3);
    }
    presaleFee = 0;
  }
}