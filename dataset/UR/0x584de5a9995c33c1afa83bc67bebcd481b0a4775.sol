 

pragma solidity ^0.4.24;


 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



 
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}


 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

   
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}


contract CapperRole {
  using Roles for Roles.Role;

  event CapperAdded(address indexed account);
  event CapperRemoved(address indexed account);

  Roles.Role private cappers;

  constructor() internal {
    _addCapper(msg.sender);
  }

  modifier onlyCapper() {
    require(isCapper(msg.sender));
    _;
  }

  function isCapper(address account) public view returns (bool) {
    return cappers.has(account);
  }

  function addCapper(address account) public onlyCapper {
    _addCapper(account);
  }

  function renounceCapper() public {
    _removeCapper(msg.sender);
  }

  function _addCapper(address account) internal {
    cappers.add(account);
    emit CapperAdded(account);
  }

  function _removeCapper(address account) internal {
    cappers.remove(account);
    emit CapperRemoved(account);
  }
}

 
contract Depot is CapperRole {

  mapping(address => bool) private _depotAddress;

  modifier onlyDepot(address depot) {
    require(_isDepot(depot), "not a depot address");
    _;
  }

  function addDepot(address depot)
    public
    onlyCapper
  {
    _addDepot(depot);
  }

  function removeDepot(address depot)
    public
    onlyCapper
    onlyDepot(depot)
  {
    _removeDepot(depot);
  }

  function isDepot(address someAddr) public view returns (bool) {
    return _isDepot(someAddr);
  }

   
  function _addDepot(address depot) internal {
    require(depot != address(0), "depot cannot be null");
    _depotAddress[depot] = true;
  }

  function _removeDepot(address depot) internal {
    _depotAddress[depot] = false;
  }

  function _isDepot(address someAddr) internal view returns (bool) {
    return _depotAddress[someAddr];
  }

}


contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() internal {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}



contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() internal {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}


 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


 
contract ERC20Mintable is ERC20, MinterRole {
   
  function mint(
    address to,
    uint256 value
  )
    public
    onlyMinter
    returns (bool)
  {
    _mint(to, value);
    return true;
  }
}



 
contract Pausable is PauserRole {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor() internal {
    _paused = false;
  }

   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

   
  modifier whenPaused() {
    require(_paused);
    _;
  }

   
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

   
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}



 
contract ERC20Pausable is ERC20, Pausable {

  function transfer(
    address to,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(to, value);
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(from, to, value);
  }

  function approve(
    address spender,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(spender, value);
  }

  function increaseAllowance(
    address spender,
    uint addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseAllowance(spender, addedValue);
  }

  function decreaseAllowance(
    address spender,
    uint subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseAllowance(spender, subtractedValue);
  }
}


 
contract Capped is Depot, ERC20Mintable {

  uint256 private _cap;

  constructor(uint256 cap)
    public
  {
    require(cap > 0, 'Cap cannot be zero');
    _cap = cap;
  }

   
  function cap() public view returns(uint256) {
    return _cap;
  }

  function setCap(uint256 newCap)
    public
    onlyCapper
  {
    _setCap(newCap);
  }

   
  function _setCap(uint256 newCap) internal {
    if (newCap > _cap) _cap = newCap;
  }

   
  function mint(
    address to,
    uint256 value
  )
    public
    onlyMinter
    onlyDepot(to)
    returns (bool)
  {
    require(totalSupply().add(value) <= _cap, "mint value limit exceeded");

    return super.mint(to, value);
  }

}


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


 

 

 
 

 
 
 


contract Constants {
    uint public constant DENOMINATOR = 10000;  
    uint public constant DECIMALS = 18;
    uint public constant WAD = 10**DECIMALS;
}

contract Token is Constants, Ownable, ERC20Pausable, Capped {
    string  public symbol;
    uint256 public decimals;
    string  public name;

    modifier condition(bool _condition) {
      require(_condition, "condition not met");
      _;
    }

    constructor(address _owner, uint256 _cap)
        public
        Capped(_cap)
    {
      require(_owner != 0, "proposed owner is null");
      if (msg.sender != _owner) {
        super.transferOwnership(_owner);
        super.addCapper(_owner);
        super.addPauser(_owner);
      }
    }

}




 
contract UniversalToken is Token {
    using SafeMath for uint256;

    uint public xactionFeeNumerator;
    uint public xactionFeeShare;

    event ModifyTransFeeCalled(uint newFee);
    event ModifyFeeShareCalled(uint newShare);

     
     
    constructor( 
        uint initialCap,
        uint feeMult,
        uint feeShare
        )
          public
          Token(msg.sender, initialCap)
    {
        require(initialCap > 0, "initial supply must be greater than 0");
        require(feeMult > 0, "fee multiplier must be non-zero");
        symbol = "UETR";
        name = "Universal Evangelist Token - by Rock Stable Token Inc";
        decimals = DECIMALS;
        xactionFeeNumerator = feeMult;
        xactionFeeShare = feeShare;
    }

    function modifyTransFee(uint _xactionFeeMult) public
        onlyOwner
    {
        require(DENOMINATOR > _xactionFeeMult.mul(4), 'cannot modify transaction fee to more than 0.25');
        xactionFeeNumerator = _xactionFeeMult;
        emit ModifyTransFeeCalled(_xactionFeeMult);
    }

    function modifyFeeShare(uint _share) public
        onlyOwner
    {
        require(DENOMINATOR > _share.mul(3), 'RSTI share must be less than one-third');
        xactionFeeShare = _share;
        emit ModifyFeeShareCalled(_share);
    }
}



 
contract LocalToken is Token {
    using SafeMath for uint256;

    string  public localityCode;
    uint    public taxRateNumerator = 0;
    address public govtAccount = 0;
    address public pmtAccount = 0;
    UniversalToken public universalToken;

    constructor(
            uint _maxTokens,
            uint _taxRateMult,
            string _tokenSymbol,
            string _tokenName,
            string _localityCode,
            address _govt,
            address _pmt,
            address _universalToken
            )
            public
            condition(_maxTokens > 0)
            condition(DENOMINATOR > _taxRateMult.mul(2))
            condition((_taxRateMult > 0 && _govt != 0) || _taxRateMult == 0)
            condition(_universalToken != 0)
            Token(msg.sender, _maxTokens)
    {
        universalToken = UniversalToken(_universalToken);
         
        decimals = DECIMALS;
        symbol = _tokenSymbol;
        name = _tokenName;
        localityCode = _localityCode;
        govtAccount = _govt;
        pmtAccount = _pmt;
        if (_taxRateMult > 0) {
            taxRateNumerator = _taxRateMult;
        }
    }

     
     
     
     
     
    function modifyLocality(string newLocality) public
        onlyMinter
    {
        localityCode = newLocality;
    }

    function modifyTaxRate(uint _taxMult) public
        onlyMinter
        condition(DENOMINATOR > _taxMult.mul(2))
    {
        taxRateNumerator = _taxMult;
    }

     
     
     
     
    function modifyGovtAccount(address govt) public
        onlyMinter
    {
        if ((taxRateNumerator > 0 && govt == address(0)) 
            || (taxRateNumerator == 0 && govt != address(0))) revert('invalid input');
        govtAccount = govt;
    }

    function modifyPMTAccount(address _pmt) public
        onlyOwner
    {
        require(_pmt != 0, 'cannot set RockStable address to zero');
        pmtAccount = _pmt;
    }
}



interface IPayment2 {
     
    event PaymentConfirmed(address indexed _customerAddr, address indexed _paymentContract, uint _ethValue, uint _roks);

     
    event PaymentContract(bool _payTax, address _evangelist, address _localToken, address _vendor, address _pmntCenter);

     
    event PaymentContractRefreshed(address _contract);

     
    event VendorTransferred(address _fromEvangelist, address _toEvangelist);

     
    event DebugEvent(address from, address to, uint value);

    function getVendor() external view returns (address);

    function getPmtAccount() external view returns (address);

     
     
    function transferThisVendor(address toAnotherEvangelist) external;

    function setPayTax(bool pay) external;

     
     
     
     
    function refreshFeeParams() external;

    function depositLocalToken() external;

    function destroy() external;

    function getEthPrice() external view returns (uint);

    function setEthPrice(uint ethPrice) external;

    function getRoksExpected() external view returns (uint);

    function setRoksExpected(uint roksExpected) external;

    function getLocalToken() external view returns (LocalToken);
}



contract PureMoney2 is Token {

    event DebugEvent(address from, address to, uint value);

     
    event PaymentContractRegistered(address _contract, uint amountApproved);

    constructor( 
        uint initialCap)
          public
          condition(initialCap > 0)
          Token(msg.sender, initialCap)
    {
        symbol = "ROKS";
        name = "Rock Stable Token";
        decimals = DECIMALS;
    }

     
     
     
     
     
     
     
    function registerVendor(address _contract, uint amountToApprove)
        public
        onlyOwner
    {
        require(_contract != address(0), 'null contract address');
        require(!this.isRegistered(_contract), 'payment contract is already registered');
         
         
        IPayment2 pmnt = IPayment2(_contract);  
        require(pmnt.getVendor() != address(0), 'vendor not set in payment contract');
        require(pmnt.getPmtAccount() != address(0), 'RSTI account not set in payment contract');
        pmnt.depositLocalToken();
        super.approve(address(pmnt), amountToApprove);
         
        emit PaymentContractRegistered(_contract, amountToApprove);
    }

     
     
     
     
     
     
     
    function deregisterVendor(address _contract)
        public
        onlyOwner
    {
        require(_contract != address(0), 'null contract address');
        IPayment2 pmnt = IPayment2(_contract);  
        pmnt.destroy();
        emit DebugEvent(pmnt.getPmtAccount(), address(0), 0);
    }

     
    function isRegistered(address _contract)
        public
        view
        returns (bool)
    {
        return (this.allowance(this.owner(), _contract) > WAD);
    }

     
     
     
     
     
     
     
     
     
     
    function getAccountIfContract(address to) internal view returns (address account)
    {
         
        require(to != address(0), 'destination address is null');
         
        if (this.isRegistered(to)) {
            IPayment2 pmnt = IPayment2(to);
            LocalToken local = LocalToken(pmnt.getLocalToken());
            require(local.balanceOf(to) >= WAD, 'destination address is an unregistered payment contract');
            return pmnt.getVendor();
        } else {
            return to;  
        }
    }

     
    function transfer(address to, uint tokens) public returns (bool success)
    {
        emit DebugEvent(msg.sender, to, tokens);
        address addr = getAccountIfContract(to);
        require(addr != address(0), 'vendor address is zero');
        require(balanceOf(msg.sender) > tokens, 'not enough tokens');
        super._transfer(msg.sender, addr, tokens);
        return true;
    }

     
    function transferFrom(address from, address to, uint tokens) public returns (bool success)
    {
        emit DebugEvent(from, to, tokens);
        return super.transferFrom(from, getAccountIfContract(to), tokens);
    }

}