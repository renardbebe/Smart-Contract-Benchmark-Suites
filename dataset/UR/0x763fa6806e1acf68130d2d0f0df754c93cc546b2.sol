 

pragma solidity ^0.5.0;


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

contract ERC20Burnable is ERC20 {
     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
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


contract MintableAndPausableToken is ERC20Pausable, Ownable {
    uint8 public constant decimals = 18;
    uint256 public maxTokenSupply = 183500000 * 10 ** uint256(decimals);

    bool public mintingFinished = false;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event MintStarted();

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier checkMaxSupply(uint256 _amount) {
        require(maxTokenSupply >= totalSupply().add(_amount));
        _;
    }

    modifier cannotMint() {
        require(mintingFinished);
        _;
    }

    function mint(address _to, uint256 _amount)
        external
        onlyOwner
        canMint
        checkMaxSupply (_amount)
        whenNotPaused
        returns (bool)
    {
        super._mint(_to, _amount);
        return true;
    }

    function _mint(address _to, uint256 _amount)
        internal
        canMint
        checkMaxSupply (_amount)
    {
        super._mint(_to, _amount);
    }

    function finishMinting() external onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    function startMinting() external onlyOwner cannotMint returns (bool) {
        mintingFinished = false;
        emit MintStarted();
        return true;
    }
}



 
contract TokenUpgrader {
    uint public originalSupply;

     
    function isTokenUpgrader() external pure returns (bool) {
        return true;
    }

    function upgradeFrom(address _from, uint256 _value) public;
}



contract UpgradeableToken is MintableAndPausableToken {
     
    address public upgradeMaster;
    
     
    bool private upgradesAllowed;

     
    TokenUpgrader public tokenUpgrader;

     
    uint public totalUpgraded;

     
    enum UpgradeState { NotAllowed, Waiting, ReadyToUpgrade, Upgrading }

     
    event Upgrade(address indexed _from, address indexed _to, uint256 _value);

     
    event TokenUpgraderIsSet(address _newToken);

    modifier onlyUpgradeMaster {
         
        require(msg.sender == upgradeMaster);
        _;
    }

    modifier notInUpgradingState {
         
        require(getUpgradeState() != UpgradeState.Upgrading);
        _;
    }

     
    constructor(address _upgradeMaster) public {
        upgradeMaster = _upgradeMaster;
    }

     
    function setTokenUpgrader(address _newToken)
        external
        onlyUpgradeMaster
        notInUpgradingState
    {
        require(canUpgrade());
        require(_newToken != address(0));

        tokenUpgrader = TokenUpgrader(_newToken);

         
        require(tokenUpgrader.isTokenUpgrader());

         
        require(tokenUpgrader.originalSupply() == totalSupply());

        emit TokenUpgraderIsSet(address(tokenUpgrader));
    }

     
    function upgrade(uint _value) external {
        UpgradeState state = getUpgradeState();
        
         
        require(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading);
         
        require(_value != 0);

         
         
         
         
        _burn(msg.sender, _value);

        totalUpgraded = totalUpgraded.add(_value);

         
        tokenUpgrader.upgradeFrom(msg.sender, _value);
        emit Upgrade(msg.sender, address(tokenUpgrader), _value);
    }

     
    function setUpgradeMaster(address _newMaster) external onlyUpgradeMaster {
        require(_newMaster != address(0));
        upgradeMaster = _newMaster;
    }

     
    function allowUpgrades() external onlyUpgradeMaster () {
        upgradesAllowed = true;
    }

     
    function rejectUpgrades() external onlyUpgradeMaster () {
        require(!(totalUpgraded > 0));
        upgradesAllowed = false;
    }

     
    function getUpgradeState() public view returns(UpgradeState) {
        if (!canUpgrade()) return UpgradeState.NotAllowed;
        else if (address(tokenUpgrader) == address(0)) return UpgradeState.Waiting;
        else if (totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
        else return UpgradeState.Upgrading;
    }

     
    function canUpgrade() public view returns(bool) {
        return upgradesAllowed;
    }
}



contract Token is UpgradeableToken, ERC20Burnable {
    string public name;
    string public symbol;

     
    uint256 public INITIAL_SUPPLY;
    uint256 public hodlPremiumCap;
    uint256 public hodlPremiumMinted;

     
     
     
    uint256 constant maxBonusDuration = 180 days;

    struct Bonus {
        uint256 hodlTokens;
        uint256 contributionTime;
        uint256 buybackTokens;
    }

    mapping( address => Bonus ) public hodlPremium;

    IERC20 stablecoin;
    address stablecoinPayer;

    uint256 public signupWindowStart;
    uint256 public signupWindowEnd;

    uint256 public refundWindowStart;
    uint256 public refundWindowEnd;

    event UpdatedTokenInformation(string newName, string newSymbol);
    event HodlPremiumSet(address beneficiary, uint256 tokens, uint256 contributionTime);
    event HodlPremiumCapSet(uint256 newhodlPremiumCap);
    event RegisteredForRefund( address holder, uint256 tokens );

    constructor (address _litWallet, address _upgradeMaster, uint256 _INITIAL_SUPPLY, uint256 _hodlPremiumCap)
        public
        UpgradeableToken(_upgradeMaster)
        Ownable()
    {
        require(maxTokenSupply >= _INITIAL_SUPPLY.mul(10 ** uint256(decimals)));
        INITIAL_SUPPLY = _INITIAL_SUPPLY.mul(10 ** uint256(decimals));
        setHodlPremiumCap(_hodlPremiumCap)  ;
        _mint(_litWallet, INITIAL_SUPPLY);
    }

     
    function setTokenInformation(string calldata _name, string calldata _symbol) external onlyOwner {
        name = _name;
        symbol = _symbol;

        emit UpdatedTokenInformation(name, symbol);
    }

    function setRefundSignupDetails( uint256 _startTime,  uint256 _endTime, ERC20 _stablecoin, address _payer ) public onlyOwner {
        require( _startTime < _endTime );
        stablecoin = _stablecoin;
        stablecoinPayer = _payer;
        signupWindowStart = _startTime;
        signupWindowEnd = _endTime;
        refundWindowStart = signupWindowStart + 182 days;
        refundWindowEnd = signupWindowEnd + 182 days;
        require( refundWindowStart > signupWindowEnd);
    }

    function signUpForRefund( uint256 _value ) public {
        require( hodlPremium[msg.sender].hodlTokens != 0 || hodlPremium[msg.sender].buybackTokens != 0, "You must be ICO user to sign up" );  
        require( block.timestamp >= signupWindowStart&& block.timestamp <= signupWindowEnd, "Cannot sign up at this time" );
        uint256 value = _value;
        value = value.add(hodlPremium[msg.sender].buybackTokens);

        if( value > balanceOf(msg.sender))  
            value = balanceOf(msg.sender);

        hodlPremium[ msg.sender].buybackTokens = value;
         
        if( hodlPremium[msg.sender].hodlTokens > 0 ){
            hodlPremium[msg.sender].hodlTokens = 0;
            emit HodlPremiumSet( msg.sender, 0, hodlPremium[msg.sender].contributionTime );
        }

        emit RegisteredForRefund(msg.sender, value);
    }

    function refund( uint256 _value ) public {
        require( block.timestamp >= refundWindowStart && block.timestamp <= refundWindowEnd, "cannot refund now" );
        require( hodlPremium[msg.sender].buybackTokens >= _value, "not enough tokens in refund program" );
        require( balanceOf(msg.sender) >= _value, "not enough tokens" );  
        hodlPremium[msg.sender].buybackTokens = hodlPremium[msg.sender].buybackTokens.sub(_value);
        _burn( msg.sender, _value );
        require( stablecoin.transferFrom( stablecoinPayer, msg.sender, _value.div(20) ), "transfer failed" );  
    }

    function setHodlPremiumCap(uint256 newhodlPremiumCap) public onlyOwner {
        require(newhodlPremiumCap > 0);
        hodlPremiumCap = newhodlPremiumCap;
        emit HodlPremiumCapSet(hodlPremiumCap);
    }

     
    function burn(uint256 _value) public onlyOwner {
        super.burn(_value);
    }

    function sethodlPremium(
        address beneficiary,
        uint256 value,
        uint256 contributionTime
    )
        public
        onlyOwner
        returns (bool)
    {
        require(beneficiary != address(0) && value > 0 && contributionTime > 0, "Not eligible for HODL Premium");

        if (hodlPremium[beneficiary].hodlTokens != 0) {
            hodlPremium[beneficiary].hodlTokens = hodlPremium[beneficiary].hodlTokens.add(value);
            emit HodlPremiumSet(beneficiary, hodlPremium[beneficiary].hodlTokens, hodlPremium[beneficiary].contributionTime);
        } else {
            hodlPremium[beneficiary] = Bonus(value, contributionTime, 0);
            emit HodlPremiumSet(beneficiary, value, contributionTime);
        }

        return true;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_to != address(0));
        require(_value <= balanceOf(msg.sender));

        if (hodlPremiumMinted < hodlPremiumCap && hodlPremium[msg.sender].hodlTokens > 0) {
            uint256 amountForBonusCalculation = calculateAmountForBonus(msg.sender, _value);
            uint256 bonus = calculateBonus(msg.sender, amountForBonusCalculation);

             
            hodlPremium[msg.sender].hodlTokens = hodlPremium[msg.sender].hodlTokens.sub(amountForBonusCalculation);
            if ( bonus > 0) {
                 
                _mint( msg.sender, bonus );
                 
            }
        }

        ERC20Pausable.transfer( _to, _value );
 
 
 

         
        if( balanceOf(msg.sender) < hodlPremium[msg.sender].buybackTokens )
            hodlPremium[msg.sender].buybackTokens = balanceOf(msg.sender);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        whenNotPaused
        returns (bool)
    {
        require(_to != address(0));

        if (hodlPremiumMinted < hodlPremiumCap && hodlPremium[_from].hodlTokens > 0) {
            uint256 amountForBonusCalculation = calculateAmountForBonus(_from, _value);
            uint256 bonus = calculateBonus(_from, amountForBonusCalculation);

             
            hodlPremium[_from].hodlTokens = hodlPremium[_from].hodlTokens.sub(amountForBonusCalculation);
            if ( bonus > 0) {
                 
                _mint( _from, bonus );
                 
            }
        }

        ERC20Pausable.transferFrom( _from, _to, _value);
        if( balanceOf(_from) < hodlPremium[_from].buybackTokens )
            hodlPremium[_from].buybackTokens = balanceOf(_from);
        return true;
    }

    function calculateBonus(address beneficiary, uint256 amount) internal returns (uint256) {
        uint256 bonusAmount;

        uint256 contributionTime = hodlPremium[beneficiary].contributionTime;
        uint256 bonusPeriod;
        if (now <= contributionTime) {
            bonusPeriod = 0;
        } else if (now.sub(contributionTime) >= maxBonusDuration) {
            bonusPeriod = maxBonusDuration;
        } else {
            bonusPeriod = now.sub(contributionTime);
        }

        if (bonusPeriod != 0) {
            bonusAmount = (((bonusPeriod.mul(amount)).div(maxBonusDuration)).mul(25)).div(100);
            if (hodlPremiumMinted.add(bonusAmount) > hodlPremiumCap) {
                bonusAmount = hodlPremiumCap.sub(hodlPremiumMinted);
                hodlPremiumMinted = hodlPremiumCap;
            } else {
                hodlPremiumMinted = hodlPremiumMinted.add(bonusAmount);
            }

            if( totalSupply().add(bonusAmount) > maxTokenSupply )
                bonusAmount = maxTokenSupply.sub(totalSupply());
        }

        return bonusAmount;
    }

    function calculateAmountForBonus(address beneficiary, uint256 _value) internal view returns (uint256) {
        uint256 amountForBonusCalculation;

        if(_value >= hodlPremium[beneficiary].hodlTokens) {
            amountForBonusCalculation = hodlPremium[beneficiary].hodlTokens;
        } else {
            amountForBonusCalculation = _value;
        }

        return amountForBonusCalculation;
    }

}


contract TestToken is ERC20{
    constructor ( uint256 _balance)public {
        _mint(msg.sender, _balance);
    }
}