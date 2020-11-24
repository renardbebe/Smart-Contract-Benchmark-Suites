 

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

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

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

 

 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}

 

 
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

 

 
contract TokenTimelock {
    using SafeERC20 for IERC20;

     
    IERC20 private _token;

     
    address private _beneficiary;

     
    uint256 private _releaseTime;

    constructor (IERC20 token, address beneficiary, uint256 releaseTime) public {
         
        require(releaseTime > block.timestamp);
        _token = token;
        _beneficiary = beneficiary;
        _releaseTime = releaseTime;
    }

     
    function token() public view returns (IERC20) {
        return _token;
    }

     
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

     
    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

     
    function release() public {
         
        require(block.timestamp >= _releaseTime);

        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0);

        _token.safeTransfer(_beneficiary, amount);
    }
}

 

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

 

 
contract Crowdsale is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

     
    IERC20 private _token;

     
    address payable private _wallet;

     
     
     
     
    uint256 private _rate;

     
    uint256 private _weiRaised;

     
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    constructor (uint256 rate, address payable wallet, IERC20 token) public {
        require(rate > 0);
        require(wallet != address(0));
        require(address(token) != address(0));

        _rate = rate;
        _wallet = wallet;
        _token = token;
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function token() public view returns (IERC20) {
        return _token;
    }

     
    function wallet() public view returns (address payable) {
        return _wallet;
    }

     
    function rate() public view returns (uint256) {
        return _rate;
    }

     
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

     
    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

         
        uint256 tokens = _getTokenAmount(weiAmount);

         
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

     
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0));
        require(weiAmount != 0);
    }

     
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
         
    }

     
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

     
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

     
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
         
    }

     
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }

     
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
}

 

 
contract MintedCrowdsale is Crowdsale {
     
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
         
        require(ERC20Mintable(address(token())).mint(beneficiary, tokenAmount));
    }
}

 

 
contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 private _cap;

     
    constructor (uint256 cap) public {
        require(cap > 0);
        _cap = cap;
    }

     
    function cap() public view returns (uint256) {
        return _cap;
    }

     
    function capReached() public view returns (bool) {
        return weiRaised() >= _cap;
    }

     
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(weiRaised().add(weiAmount) <= _cap);
    }
}

 

 
contract TimedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 private _openingTime;
    uint256 private _closingTime;

     
    modifier onlyWhileOpen {
        require(isOpen());
        _;
    }

     
    constructor (uint256 openingTime, uint256 closingTime) public {
         
        require(openingTime >= block.timestamp);
        require(closingTime > openingTime);

        _openingTime = openingTime;
        _closingTime = closingTime;
    }

     
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

     
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

     
    function isOpen() public view returns (bool) {
         
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

     
    function hasClosed() public view returns (bool) {
         
        return block.timestamp > _closingTime;
    }

     
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal onlyWhileOpen view {
        super._preValidatePurchase(beneficiary, weiAmount);
    }
}

 

 
contract FinalizableCrowdsale is TimedCrowdsale {
    using SafeMath for uint256;

    bool private _finalized;

    event CrowdsaleFinalized();

    constructor () internal {
        _finalized = false;
    }

     
    function finalized() public view returns (bool) {
        return _finalized;
    }

     
    function finalize() public {
        require(!_finalized);
        require(hasClosed());

        _finalized = true;

        _finalization();
        emit CrowdsaleFinalized();
    }

     
    function _finalization() internal {
         
    }
}

 

 
contract Secondary {
    address private _primary;

    event PrimaryTransferred(
        address recipient
    );

     
    constructor () internal {
        _primary = msg.sender;
        emit PrimaryTransferred(_primary);
    }

     
    modifier onlyPrimary() {
        require(msg.sender == _primary);
        _;
    }

     
    function primary() public view returns (address) {
        return _primary;
    }

     
    function transferPrimary(address recipient) public onlyPrimary {
        require(recipient != address(0));
        _primary = recipient;
        emit PrimaryTransferred(_primary);
    }
}

 

 
contract Escrow is Secondary {
    using SafeMath for uint256;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

     
    function deposit(address payee) public onlyPrimary payable {
        uint256 amount = msg.value;
        _deposits[payee] = _deposits[payee].add(amount);

        emit Deposited(payee, amount);
    }

     
    function withdraw(address payable payee) public onlyPrimary {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.transfer(payment);

        emit Withdrawn(payee, payment);
    }
}

 

 
contract ConditionalEscrow is Escrow {
     
    function withdrawalAllowed(address payee) public view returns (bool);

    function withdraw(address payable payee) public {
        require(withdrawalAllowed(payee));
        super.withdraw(payee);
    }
}

 

 
contract RefundEscrow is ConditionalEscrow {
    enum State { Active, Refunding, Closed }

    event RefundsClosed();
    event RefundsEnabled();

    State private _state;
    address payable private _beneficiary;

     
    constructor (address payable beneficiary) public {
        require(beneficiary != address(0));
        _beneficiary = beneficiary;
        _state = State.Active;
    }

     
    function state() public view returns (State) {
        return _state;
    }

     
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

     
    function deposit(address refundee) public payable {
        require(_state == State.Active);
        super.deposit(refundee);
    }

     
    function close() public onlyPrimary {
        require(_state == State.Active);
        _state = State.Closed;
        emit RefundsClosed();
    }

     
    function enableRefunds() public onlyPrimary {
        require(_state == State.Active);
        _state = State.Refunding;
        emit RefundsEnabled();
    }

     
    function beneficiaryWithdraw() public {
        require(_state == State.Closed);
        _beneficiary.transfer(address(this).balance);
    }

     
    function withdrawalAllowed(address) public view returns (bool) {
        return _state == State.Refunding;
    }
}

 

 
contract RefundableCrowdsale is FinalizableCrowdsale {
    using SafeMath for uint256;

     
    uint256 private _goal;

     
    RefundEscrow private _escrow;

     
    constructor (uint256 goal) public {
        require(goal > 0);
        _escrow = new RefundEscrow(wallet());
        _goal = goal;
    }

     
    function goal() public view returns (uint256) {
        return _goal;
    }

     
    function claimRefund(address payable refundee) public {
        require(finalized());
        require(!goalReached());

        _escrow.withdraw(refundee);
    }

     
    function goalReached() public view returns (bool) {
        return weiRaised() >= _goal;
    }

     
    function _finalization() internal {
        if (goalReached()) {
            _escrow.close();
            _escrow.beneficiaryWithdraw();
        } else {
            _escrow.enableRefunds();
        }

        super._finalization();
    }

     
    function _forwardFunds() internal {
        _escrow.deposit.value(msg.value)(msg.sender);
    }
}

 

 
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

 

contract WiseTokenCrowdsale is Crowdsale, MintedCrowdsale, CappedCrowdsale, TimedCrowdsale, RefundableCrowdsale, Ownable {
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    event EthTransferred(string text);
    event RateChanged(uint256 rate);
    event StageChanged(uint256 stage);
    event TokensQuantityChanged(uint256 stage, uint256 _tokens);
    event MintTokens(address _beneficiary, uint256 _tokens);
    event MintFullTeamDone();

     
    enum CrowdsaleStage { PrivateICO, PreICO, ICO }
    CrowdsaleStage public stage = CrowdsaleStage.PrivateICO;
    uint256 private _wserate;

     
    uint256 public totalTokens                = 100000000;
    uint256 public crowdsaleFundDistribution  = 35;
    uint256 public airdroppedFundDistribution = 5;
    uint256 public advisorsFundDistribution   = 3;
    uint256 public teamFundDistribution       = 7;
    uint256 public bussinesFundDistribution   = 30;
    uint256 public reserveFundDistribution    = 20;
    uint256 public privateFundDistribution    = 20;
    uint256 public preFundDistribution        = 10;
    uint256 public publicFundDistribution     = 5;

     
    address public crowdsaleFund;
    address public airdroppedFund;
    address public advisorsFund;
    address public teamFund;
    address public bussinesFund;
    address public reserveFund;

     
    uint256 public totalPrivateTokens = 0;
    uint256 public totalPreTokens     = 0;
    uint256 public totalPublicTokens  = 0;

    constructor(
      uint256 _rate,
      address payable _wallet,
      ERC20Mintable _token,
      uint256 _cap,
      uint256 _goal,
      address[] memory _fundAddresses,
      uint256 _openingTime,
      uint256 _closingTime
    )
      Crowdsale(_rate, _wallet, _token)
      CappedCrowdsale(_cap)
      TimedCrowdsale(_openingTime, _closingTime)
      RefundableCrowdsale(_goal)
      public
    {
        require(_goal <= _cap, "goal must be equal or less than cap");
        _wserate = _rate;
        airdroppedFund = _fundAddresses[0];
        advisorsFund = _fundAddresses[1];
        teamFund = _fundAddresses[2];
        bussinesFund = _fundAddresses[3];
        reserveFund = _fundAddresses[4];
    }

     
    function setCurrentRate(uint256 _rate, uint256 _multiplier) public onlyOwner {
         
        _wserate = _rate.mul(10**_multiplier);
        emit RateChanged(_wserate);
    }

     
    function setCrowdsaleStage(uint _stage) public onlyOwner {
        if(uint(CrowdsaleStage.PrivateICO) == _stage) {
            stage = CrowdsaleStage.PrivateICO;
        } else if (uint(CrowdsaleStage.PreICO) == _stage) {
            stage = CrowdsaleStage.PreICO;
        } else if (uint(CrowdsaleStage.ICO) == _stage) {
            stage = CrowdsaleStage.ICO;
        }
        emit StageChanged(uint(stage));
    }

     
    function updateTokensQuantity(uint256 _tokens) internal {
        if(stage == CrowdsaleStage.PrivateICO) {
            totalPrivateTokens = totalPrivateTokens.add(_tokens);
        } else if (stage == CrowdsaleStage.PreICO) {
            totalPreTokens = totalPreTokens.add(_tokens);
        } else if (stage == CrowdsaleStage.ICO) {
            totalPublicTokens = totalPublicTokens.add(_tokens);
        }
        emit TokensQuantityChanged(uint(stage), _tokens);
    }

     
    function updateTokensQuantityAdmin(uint _stage, uint256 _tokens) public onlyOwner  {
        if(_stage == uint(CrowdsaleStage.PrivateICO)) {
            totalPrivateTokens = _tokens;
        } else if (_stage == uint(CrowdsaleStage.PreICO)) {
            totalPreTokens = _tokens;
        } else if (_stage == uint(CrowdsaleStage.ICO)) {
            totalPublicTokens = _tokens;
        }
        emit TokensQuantityChanged(_stage, _tokens);
    }

     
    function getCurrentRate() public view returns (uint256) {
        return _wserate;
    }

     
    function rate() public view returns (uint256) {
        return getCurrentRate();
    }

     
    function _preValidatePurchase( address payable _beneficiary, uint256 _weiAmount ) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(_validateTokenLimits(_getTokenAmount(_weiAmount)),"max tokens reached");
    }

     
    function _validateTokenLimits(uint256 tokens) internal view returns (bool) {
        if(stage == CrowdsaleStage.PrivateICO) {
            require(totalPrivateTokens.add(tokens) <= privateFundDistribution.mul(10**6),"max tokens reached 0");
        } else if (stage == CrowdsaleStage.PreICO) {
            require(totalPreTokens.add(tokens) <= preFundDistribution.mul(10**6),"max tokens reached 1");
        } 
         
         
         
         
         
        return true;
    }


     
    function calculateTokens(uint256 rateP, uint256 rateMultiplierP, uint weiAmountP, uint weiAmountMultiplierP) public view returns (uint256) {
        uint256 currentRate = getCurrentRate();
        uint256 rateLocal = rateP;
        uint256 rateMultiplier = rateMultiplierP;
        uint256 weiAmount = weiAmountP;
        uint256 weiAmountMultiplier = weiAmountMultiplierP;
        if(rateLocal == 0){
            rateLocal = currentRate;
        }
        if(rateMultiplier != 0){
            rateLocal = rateLocal.mul(10**rateMultiplier);
        }
        if(weiAmountMultiplier != 0){
            weiAmount = weiAmount.mul(10**weiAmountMultiplier);
        }
        return weiAmount.div(rateLocal);
    }

     
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 currentRate = getCurrentRate();
        uint256 count = weiAmount.div(currentRate);
        return count * 1 ether;
    }

     
    function _getTokenAmountSimple(uint256 weiAmount) internal view returns (uint256) {
        return _getTokenAmount(weiAmount);
    }

     
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        updateTokensQuantity(_getTokenAmount(weiAmount).div(10**18));
    }

     
    function _forwardFunds() internal {
        if(stage == CrowdsaleStage.PrivateICO) {
            address(wallet()).transfer(msg.value);
            emit EthTransferred("forwarding funds to wallet PrivateICO");
        } else if (stage == CrowdsaleStage.PreICO) {
            address(wallet()).transfer(msg.value);
            emit EthTransferred("forwarding funds to wallet PreICO");
        } else if (stage == CrowdsaleStage.ICO) {
            emit EthTransferred("forwarding funds to refundable vault");
            super._forwardFunds();
        }
    }

     
    function mintTokensInvestors(address _beneficiary, uint256 _tokens) public onlyOwner  {
        uint tokensInWei = _tokens.mul(10**18);
        require(_beneficiary != address(0), "beneficiary cant be address 0");
        require(_tokens > 0, "invalid # of tokens");
        require(_validateTokenLimits(_tokens), "max tokens reached");
        require(ERC20Mintable(address(token())).mint(_beneficiary, tokensInWei), "mint error");
        updateTokensQuantity(_tokens);
        emit MintTokens(_beneficiary, _tokens);
    }

     
    function mintFullTeam() public onlyOwner {
        if(goalReached()) {
            ERC20Mintable _mintableToken = ERC20Mintable(address(token()));
            _mintableToken.mint(address(airdroppedFund), airdroppedFundDistribution * (10**6) * 10**18);
            _mintableToken.mint(address(advisorsFund), advisorsFundDistribution * (10**6) * 10**18);
            _mintableToken.mint(address(teamFund), teamFundDistribution * (10**6) * 10**18);
            _mintableToken.mint(address(bussinesFund), bussinesFundDistribution * (10**6) * 10**18);
            _mintableToken.mint(address(reserveFund), reserveFundDistribution * (10**6) * 10**18);
            emit MintFullTeamDone();
        }
    }

     
    function _finalization() internal {
        if(goalReached()) {
            mintFullTeam();
        }
        super._finalization();
    }
}

 

 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

 

contract WiseToken is  ERC20, ERC20Detailed, ERC20Mintable, ERC20Pausable, Ownable{
    constructor () public ERC20Detailed("WISE TOKEN", "WSE", 18) {
    }
}

 

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  constructor() public {
    owner = msg.sender;
  }

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}