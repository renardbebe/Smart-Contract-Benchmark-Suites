 

pragma solidity ^0.4.24;

 

 
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

 

 
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string name, string symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

   
  function name() public view returns(string) {
    return _name;
  }

   
  function symbol() public view returns(string) {
    return _symbol;
  }

   
  function decimals() public view returns(uint8) {
    return _decimals;
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

 

contract KDO is Ownable, ERC20Detailed, ERC20Mintable {
  struct Ticket {
     
    string tType;

     
    uint createdAt;
    uint expireAt;

    address contractor;

     
    bool hasReviewed;
  }

   
  struct Contractor {
     
    mapping (uint => uint) reviews;

     
    uint256 nbCredittedTickets;

     
    uint256 debittedBalance;
  }

   
   
  uint8[5] public commissions;

  mapping (address => Ticket) public tickets;

   
  mapping (address => Contractor) public contractors;

  event CreditEvt(address ticket, address contractor, string tType, uint256 date);
  event DebitEvt(address contractor, uint256 amount, uint256 commission, uint256 date);
  event ReviewEvt(address reviewer, address contractor, uint rate, uint256 date);
  event CommissionsChangeEvt(uint8[5] commissions, uint256 date);

  mapping (uint256 => string) public ticketTypes;

   
  uint256 constant public MIN_TICKET_BASE_VALUE = 150000000000000;

   
  uint256 constant public MIN_COMMISSION = 8;
  uint256 constant public MAX_COMMISSION = 30;

   
  uint256 public ticketBaseValue;

   
  uint256 public ticketCostBase;

  address private _businessOwner;

  constructor(uint8[5] _commissions, address __businessOwner)
    ERC20Detailed("KDO Coin", "KDO", 0)
    public
  {
    ticketBaseValue = MIN_TICKET_BASE_VALUE;
    ticketCostBase = 3;

    updateCommissions(_commissions);

    _businessOwner = __businessOwner;
  }

   
  modifier onlyExistingTicketAmount(uint256 _amount) {
    require(bytes(ticketTypes[_amount]).length > 0, '{error: UNKNOWN_TICKET}');
    _;
  }

   
   
   
  function updateTicketCostBase(uint256 _value) public
    onlyOwner()
  {
    require(_value > 0 && _value <= 500, '{error: BAD_VALUE, message: "Should be > 0 and <= 500"}');
    ticketCostBase = _value;
  }

   
   
   
   
  function updateTicketBaseValue(uint256 _value) public
    onlyOwner()
  {
     
    require(_value >= MIN_TICKET_BASE_VALUE, '{error: BAD_VALUE, message: "Value too low"}');
    ticketBaseValue = _value;
  }

   
   
  function updateCommissions(uint8[5] _c) public
    onlyOwner()
  {
    for (uint i = 0; i <= 4; i++) {
        require(_c[i] <= MAX_COMMISSION && _c[i] >= MIN_COMMISSION, '{error: BAD_VALUE, message: "A commission it too low or too high"}');
    }
    commissions = _c;
    emit CommissionsChangeEvt(_c, now);
  }

   
   
   
   
   
   
   
   
  function addTicketType(uint256 _amount, string _key) public
    onlyOwner()
  {
    ticketTypes[_amount] = _key;
  }

   
   
   
  function allocateNewTicketWithKDO(address _to, uint256 _KDOAmount)
    public
    payable
    onlyExistingTicketAmount(_KDOAmount)
    returns (bool success)
  {
      require(msg.value >= ticketBaseValue, '{error: BAD_VALUE, message: "Value too low"}');

      _to.transfer(ticketBaseValue);

      super.transfer(_to, _KDOAmount);

      _createTicket(_to, _KDOAmount);

      return true;
  }

   
   
   
  function allocateNewTicket(address _to, uint256 _amount)
    public
    payable
    onlyExistingTicketAmount(_amount)
    returns (bool success)
  {
    uint256 costInWei = costOfTicket(_amount);
    require(msg.value == costInWei, '{error: BAD_VALUE, message: "Value should be equal to the cost of the ticket"}');

     
    _to.transfer(ticketBaseValue);

     
    _businessOwner.transfer(costInWei - ticketBaseValue);

    super.mint(_to, _amount);

    _createTicket(_to, _amount);

    return true;
  }

   
   
  function isTicketValid(address _ticketAddr)
    public
    view
    returns (bool valid)
  {
    if (tickets[_ticketAddr].contractor == 0x0 && now < tickets[_ticketAddr].expireAt) {
      return true;
    }
    return false;
  }

   
   
   
   
  function creditContractor(address _contractor, uint256 amount)
    public
    onlyExistingTicketAmount(amount)
    returns (bool success)
  {
    require(isTicketValid(msg.sender), '{error: INVALID_TICKET}');

    super.transfer(_contractor, amount);

    contractors[_contractor].nbCredittedTickets += 1;

    tickets[msg.sender].contractor = _contractor;

    emit CreditEvt(msg.sender, _contractor, tickets[msg.sender].tType, now);

    return true;
  }

   
   
   
  function publishReview(uint _reviewRate) public {
     
    require(!tickets[msg.sender].hasReviewed && tickets[msg.sender].contractor != 0x0, '{error: INVALID_TICKET}');

     
    require(_reviewRate >= 0 && _reviewRate <= 5, '{error: INVALID_RATE, message: "A rate should be between 0 and 5 included"}');

     
    contractors[tickets[msg.sender].contractor].reviews[_reviewRate] += 1;

    tickets[msg.sender].hasReviewed = true;

    emit ReviewEvt(msg.sender, tickets[msg.sender].contractor, _reviewRate, now);
  }

   
   
  function reviewAverageOfContractor(address _address) public view returns (uint avg) {
     
    uint decreaseThreshold = 60;

     
    int totReviews = int(contractors[_address].reviews[0]) * -1;

    uint nbReviews = contractors[_address].reviews[0];

    for (uint i = 1; i <= 5; i++) {
      totReviews += int(contractors[_address].reviews[i] * i);
      nbReviews += contractors[_address].reviews[i];
    }

    if (nbReviews == 0) {
      return 250;
    }

     
     
    if (totReviews < 0) {
      totReviews = 0;
    }

    uint percReviewsTickets = (nbReviews * 100 / contractors[_address].nbCredittedTickets);

    avg = (uint(totReviews) * 100) / nbReviews;

    if (percReviewsTickets >= decreaseThreshold) {
      return avg;
    }

     
     
     
     
     
     
     
    uint decreasePercent = decreaseThreshold - percReviewsTickets;

    return avg - (avg / decreasePercent);
  }

   
   
  function commissionForContractor(address _address) public view returns (uint8 c) {
    return commissionForReviewAverageOf(reviewAverageOfContractor(_address));
  }

   
   
  function infoOfTicket(address _address) public view returns (uint256 balance, string tType, bool isValid, uint createdAt, uint expireAt, address contractor, bool hasReviewed) {
    return (super.balanceOf(_address), tickets[_address].tType, isTicketValid(_address), tickets[_address].createdAt, tickets[_address].expireAt, tickets[_address].contractor, tickets[_address].hasReviewed);
  }

   
   
  function infoOfContractor(address _address) public view returns(uint256 balance, uint256 debittedBalance, uint256 nbReviews, uint256 nbCredittedTickets, uint256 avg) {
    for (uint i = 0; i <= 5; i++) {
      nbReviews += contractors[_address].reviews[i];
    }

    return (super.balanceOf(_address), contractors[_address].debittedBalance, nbReviews, contractors[_address].nbCredittedTickets, reviewAverageOfContractor(_address));
  }

   
   
   
  function debit(uint256 _amount) public {
    super.transfer(super.owner(), _amount);

    emit DebitEvt(msg.sender, _amount, commissionForContractor(msg.sender), now);
  }

   
   
   
  function costOfTicket(uint256 _amount) public view returns(uint256 cost) {
    return (_amount * (ticketCostBase * 1000000000000000)) + ticketBaseValue;
  }

   
   
   
   
   
   
   
  function commissionForReviewAverageOf(uint _avg) public view returns (uint8 c) {
    if (_avg >= 500) {
      return commissions[4];
    }

    for (uint i = 0; i < 5; i++) {
      if (_avg <= i * 100 || _avg < (i + 1) * 100) {
        return commissions[i];
      }
    }

     
    return commissions[0];
  }

  function _createTicket(address _address, uint256 _amount) private {
    tickets[_address] = Ticket({
      tType: ticketTypes[_amount],
      createdAt: now,
      expireAt: now + 2 * 365 days,
      contractor: 0x0,
      hasReviewed: false
    });
  }
}