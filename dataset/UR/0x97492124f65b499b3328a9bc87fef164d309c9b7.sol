 

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.0;



 
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}

 

pragma solidity ^0.5.0;



 
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

     
    function allowance(address owner, address spender) public view returns (uint256) {
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

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

 

pragma solidity ^0.5.0;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
        address[] potentialBearers;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
        role.potentialBearers.push(account);
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function reset(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        for (uint i = 0; i < role.potentialBearers.length; i++) {
            role.bearer[role.potentialBearers[i]] = false;
        }
        
        role.potentialBearers.length = 0;
        add(role, account);
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

pragma solidity ^0.5.0;


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

 

pragma solidity ^0.5.0;



 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}

 

pragma solidity ^0.5.0;

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
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

 

pragma solidity ^0.5.0;



 
contract WhitelistAdminRole is Ownable {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(msg.sender);
    }

    modifier onlyAdmin() {
        require(isWhitelistAdmin(msg.sender) || isOwner(), "Only Whitelist Admin or Owner");
        _;
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(msg.sender), "Only Whitelist Admin");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyAdmin {
        require(_whitelistAdmins.potentialBearers.length < 20, "Not more than 20 admins are allowed");
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _addWhitelistAdmin(newOwner);
        Ownable.transferOwnership(newOwner);
    }

    function resetWhitelist() public onlyOwner {
        _whitelistAdmins.reset(owner());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

 

pragma solidity ^0.5.0;



 
contract WhitelistedRole is WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(msg.sender);
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

 

pragma solidity ^0.5.0;


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 

pragma solidity ^0.5.0;


 
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
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

 

pragma solidity ^0.5.0;



 
contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

 

pragma solidity ^0.5.0;


 
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}

 

pragma solidity ^0.5.0;



contract FundamentToken is ERC20Mintable, ERC20Pausable, ERC20Burnable {
    string public constant name = "Fundament RE 1"; 
    string public constant symbol = "FUND"; 
    uint8 public constant decimals = 0;
}

 

pragma solidity ^0.5.0;


 
contract ConverterRole is Ownable {
    using Roles for Roles.Role;

    event ConverterAdded(address indexed account);
    event ConverterRemoved(address indexed account);

    Roles.Role private _converters;

    constructor () internal {
        _addConverter(msg.sender);
    }

    modifier onlyConverterAdmin() {
        require(isConverter(msg.sender) || isOwner(), "Only Converter or Owner");
        _;
    }

    modifier onlyConverter() {
        require(isConverter(msg.sender), "Only Converter");
        _;
    }

    function isConverter(address account) public view returns (bool) {
        return _converters.has(account);
    }

    function addConverter(address account) public onlyConverterAdmin {
        require(_converters.potentialBearers.length < 20, "Not more than 20 admins are allowed");
        _addConverter(account);
    }

    function renounceConverter() public {
        _removeConverter(msg.sender);
    }

    function resetWhitelist() public onlyOwner {
        _converters.reset(owner());
    }

    function _addConverter(address account) internal {
        _converters.add(account);
        emit ConverterAdded(account);
    }

    function _removeConverter(address account) internal {
        _converters.remove(account);
        emit ConverterRemoved(account);
    }
}

 

pragma solidity ^0.5.0;







 

 
contract Crowdsale is ReentrancyGuard, WhitelistedRole, ConverterRole {
  using SafeMath for uint256;
  using SafeERC20 for FundamentToken;

  struct Period {
    bool converted;
    address[] investors;
    mapping(address => uint256) balances;
  }

  Period[] periods;
  uint currentPeriodIndex;

  bool private _running;
   
  FundamentToken private _token;

   
  address payable private _treasury;

   
  uint256 private _weiRaised;

   
  uint256 _maxInvestors;

    
  event Payout (address investor, uint256 amount);

   
  event Committed
  (address indexed investor, uint256 value);

   
  constructor (address payable treasury, FundamentToken token, uint256 maxInvestors) public {
      require(treasury != address(0));
      require(address(token) != address(0));
      require(maxInvestors > 0);

      periods.push(Period(true, new address[](0)));
      periods.push(Period(false, new address[](0)));
      currentPeriodIndex = 1;

      _treasury = treasury;
      _token = token;
      _maxInvestors = maxInvestors;
      _running = true; 
  }

   
  function token() public view returns (FundamentToken) {
      return _token;
  }
   
  function end() public onlyOwner {
    _running = false;
  }

  modifier onlyWhenRunning() {
    require(_running == true, "Sale has ended!");
    _;
  }

   
  function treasury() public view returns (address payable) {
      return _treasury;
  }

   
  function weiRaised() public view returns (uint256) {
      return _weiRaised;
  }

   
  function commit() public nonReentrant payable onlyWhenRunning {
      require(msg.value > 0, 'You need to give some money');
      address from = msg.sender;
      uint256 weiAmount = msg.value;
      _preValidatePurchase(from, weiAmount);
      _token.mint(from, 0);  
      if (periods[currentPeriodIndex].balances[from] == 0) {
        require(periods[currentPeriodIndex].investors.length < _maxInvestors, 'The limit of investors for this period has been reached.');
        periods[currentPeriodIndex].investors.push(from);
      }
      periods[currentPeriodIndex].balances[from] += weiAmount;

       
      _weiRaised = _weiRaised.add(weiAmount);

      emit Committed(from, weiAmount);

      _updatePurchasingState(from, weiAmount);

      _forwardFunds();
      _postValidatePurchase(from, weiAmount);
  }

  function committedBalance(address investor) public view returns (uint256 committedAmount) {
      uint256 balanceInClosedPeriod = periods[1-currentPeriodIndex].balances[investor];
      uint256 balanceInCurrentPeriod = periods[currentPeriodIndex].balances[investor];

      if (periods[1-currentPeriodIndex].converted) {
        committedAmount = balanceInCurrentPeriod;  
      } else {
        committedAmount = balanceInClosedPeriod + balanceInCurrentPeriod;
      }
  }

   
  function _preValidatePurchase(address investor, uint256 weiAmount) internal view {
      require(isWhitelisted(investor));
      require(investor != address(0));
      require(weiAmount != 0);
  }

   
  function _postValidatePurchase(address investor, uint256 weiAmount) internal view {
       
  }

   
    function _deliverTokens(address investor, uint256 tokenAmount) internal {
         
        _token.mint(investor, tokenAmount);
    }

   
  function _processPurchase(address investor, uint256 tokenAmount) internal {
      _deliverTokens(investor, tokenAmount);
  }

   
  function _updatePurchasingState(address investor, uint256 weiAmount) internal {
       
  }

   
  function _forwardFunds() internal {
      _treasury.transfer(msg.value);
  }

  function closePeriod() public onlyConverter {
    require(periods[1-currentPeriodIndex].converted, 'Please convert old period first.');
    periods[1-currentPeriodIndex].converted = false;
    currentPeriodIndex = (currentPeriodIndex + 1) % 2;
  }

  function convert(uint256 rate) public onlyConverter {
    require(!periods[1-currentPeriodIndex].converted, 'You already converted');
    for (uint i = 0; i < periods[1-currentPeriodIndex].investors.length; i++) {
      address investor = periods[1-currentPeriodIndex].investors[i];
      uint256 etherBalance = periods[1-currentPeriodIndex].balances[investor];

      uint256 tokenAmount = (rate * etherBalance) / 1 ether;

      emit Payout(investor, tokenAmount);

      _processPurchase(investor, tokenAmount);
      periods[1-currentPeriodIndex].balances[investor] = 0;
    }
    periods[1-currentPeriodIndex].investors.length = 0;
    periods[1-currentPeriodIndex].converted = true;
  }

  function transferOwnership(address newOwner) public onlyOwner {
        _addWhitelistAdmin(newOwner);
        _addConverter(newOwner);
        Ownable.transferOwnership(newOwner);
  }
}