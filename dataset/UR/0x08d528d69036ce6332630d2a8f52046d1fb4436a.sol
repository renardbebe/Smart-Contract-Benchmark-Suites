 

 

pragma solidity ^0.5.0;

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

 
 
pragma solidity ^0.5.0;


contract IIvoCrowdsale {
     
    function startingTime() public view returns(uint256);
}

 

 
 
pragma solidity ^0.5.0;


contract IVault {
     
    function receiveFor(address beneficiary, uint256 value) public;

     
    function updateReleaseTime(uint256 roundEndTime) public;
}

 

 
 
pragma solidity ^0.5.0;


contract CounterGuard {
     
    modifier onlyOnce(bool criterion) {
        require(criterion == false, "Already been set");
        _;
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
        require(isOwner(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 

pragma solidity ^0.5.0;




 
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

     
    function callOptionalReturn(IERC20 token, bytes memory data) private {
         
         

         
         
         
         
         
        require(address(token).isContract(), "SafeERC20: call to non-contract");

         
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {  
             
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

 

 
 
pragma solidity ^0.5.0;





contract Reclaimable is Ownable {
    using SafeERC20 for IERC20;

     
    function reclaimToken(IERC20 tokenToBeRecovered) external onlyOwner {
        uint256 balance = tokenToBeRecovered.balanceOf(address(this));
        tokenToBeRecovered.safeTransfer(owner(), balance);
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
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

 

pragma solidity ^0.5.0;





 
contract Crowdsale is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

     
    IERC20 private _token;

     
    address payable private _wallet;

     
     
     
     
    uint256 private _rate;

     
    uint256 private _weiRaised;

     
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    constructor (uint256 rate, address payable wallet, IERC20 token) public {
        require(rate > 0, "Crowdsale: rate is 0");
        require(wallet != address(0), "Crowdsale: wallet is the zero address");
        require(address(token) != address(0), "Crowdsale: token is the zero address");

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
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
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

 

pragma solidity ^0.5.0;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

 

 
 
pragma solidity ^0.5.0;





contract ManagerRole is Ownable {
    using Roles for Roles.Role;
    using SafeMath for uint256;

    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);

    Roles.Role private managers;
    uint256 private _numManager;

    constructor() internal {
        _addManager(msg.sender);
        _numManager = 1;
    }

     
    modifier onlyManager() {
        require(isManager(msg.sender), "The account is not a manager");
        _;
    }

     
     
    function addManagers(address[] calldata accounts) external onlyOwner {
        uint256 length = accounts.length;
        require(length <= 256, "too many accounts");
        for (uint256 i = 0; i < length; i++) {
            _addManager(accounts[i]);
        }
    }
    
     
    function removeManager(address account) external onlyOwner {
        _removeManager(account);
    }

     
    function isManager(address account) public view returns (bool) {
        return managers.has(account);
    }

     
    function numManager() public view returns (uint256) {
        return _numManager;
    }

     
    function addManager(address account) public onlyOwner {
        require(account != address(0), "account is zero");
        _addManager(account);
    }

     
    function renounceManager() public {
        require(_numManager >= 2, "Managers are fewer than 2");
        _removeManager(msg.sender);
    }

     
    function renounceOwnership() public onlyOwner {
        revert("Cannot renounce ownership");
    }

     
    function _addManager(address account) internal {
        _numManager = _numManager.add(1);
        managers.add(account);
        emit ManagerAdded(account);
    }

     
    function _removeManager(address account) internal {
        _numManager = _numManager.sub(1);
        managers.remove(account);
        emit ManagerRemoved(account);
    }
}

 

 
 
pragma solidity ^0.5.0;



contract PausableManager is ManagerRole {

    event BePaused(address manager);
    event BeUnpaused(address manager);

    bool private _paused;    

    constructor() internal {
        _paused = false;
    }

    
    modifier whenNotPaused() {
        require(!_paused, "not paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "paused");
        _;
    }

     
    function paused() public view returns(bool) {
        return _paused;
    }

     
    function pause() public onlyManager whenNotPaused {
        _paused = true;
        emit BePaused(msg.sender);
    }

     
    function unpause() public onlyManager whenPaused {
        _paused = false;
        emit BeUnpaused(msg.sender);
    }
}

 

 
 
pragma solidity ^0.5.0;


contract ValidAddress {
     
    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "Not a valid address");
        _;
    }

     
    modifier isSenderNot(address _address) {
        require(_address != msg.sender, "Address is the same as the sender");
        _;
    }

     
    modifier isSender(address _address) {
        require(_address == msg.sender, "Address is different from the sender");
        _;
    }
}

 

 
 
pragma solidity ^0.5.0;




contract Whitelist is ValidAddress, PausableManager {
    
    bool private _isWhitelisting;
    mapping (address => bool) private _isWhitelisted;

    event AddedWhitelisted(address indexed account);
    event RemovedWhitelisted(address indexed account);

     
    constructor() internal {
        _isWhitelisting = true;
    }
    
     
    function addWhitelisted(address account) external onlyManager {
        _addWhitelisted(account);
    }
    
     
     
    function addWhitelisteds(address[] calldata accounts) external onlyManager {
        uint256 length = accounts.length;
        require(length <= 256, "too long");
        for (uint256 i = 0; i < length; i++) {
            _addWhitelisted(accounts[i]);
        }
    }

     
    function removeWhitelisted(address account) 
        external 
        onlyManager  
    {
        _removeWhitelisted(account);
    }

     
     
    function removeWhitelisteds(address[] calldata accounts) 
        external 
        onlyManager  
    {
        uint256 length = accounts.length;
        require(length <= 256, "too long");
        for (uint256 i = 0; i < length; i++) {
            _removeWhitelisted(accounts[i]);
        }
    }

     
    function isWhitelisted(address account) public view returns (bool) {
        return _isWhitelisted[account];
    }

     
    function _addWhitelisted(address account) 
        internal
        onlyValidAddress(account)
    {
        require(_isWhitelisted[account] == false, "account already whitelisted");
        _isWhitelisted[account] = true;
        emit AddedWhitelisted(account);
    }

     
    function _removeWhitelisted(address account) 
        internal 
        onlyValidAddress(account)
    {
        require(_isWhitelisted[account] == true, "account was not whitelisted");
        _isWhitelisted[account] = false;
        emit RemovedWhitelisted(account);
    }
}

 

 
 
pragma solidity ^0.5.0;




 
contract WhitelistCrowdsale is Whitelist, Crowdsale {
     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) 
        internal 
        view 
    {
        require(isWhitelisted(_beneficiary), "beneficiary is not whitelisted");
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }
}

 

 
 
pragma solidity ^0.5.0;




contract NonEthPurchasableCrowdsale is Crowdsale {
    event NonEthTokenPurchased(address indexed beneficiary, uint256 tokenAmount);

     
    function nonEthPurchase(address beneficiary, uint256 tokenAmount) 
        public 
    {
        _preValidatePurchase(beneficiary, tokenAmount);
        _processPurchase(beneficiary, tokenAmount);
        emit NonEthTokenPurchased(beneficiary, tokenAmount);
    }
}

 

 
 
pragma solidity ^0.5.0;





 
 
contract UpdatableRateCrowdsale is PausableManager, Crowdsale {
    using SafeMath for uint256;
    
     
     
    uint256 private constant TOKEN_PRICE_USD = 3213;
    uint256 private constant TOKEN_PRICE_BASE = 10000;
    uint256 private constant FIAT_RATE_BASE = 100;

     
     
    uint256 private _rate;
     
     
     
    uint256 private _fiatRate; 

     
    event UpdatedFiatRate (uint256 value, uint256 timestamp);

     
    constructor (uint256 initialFiatRate) internal {
        require(initialFiatRate > 0, "fiat rate is not positive");
        _updateRate(initialFiatRate);
    }

     
    function updateRate(uint256 newFiatRate) external onlyManager {
        _updateRate(newFiatRate);
    }

     
    function rate() public view returns (uint256) {
        return _rate;
    }

     
    function fiatRate() public view returns (uint256) {
        return _fiatRate;
    }

     
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }

     
    function _updateRate(uint256 newFiatRate) internal {
        _fiatRate = newFiatRate;
        _rate = _fiatRate.mul(TOKEN_PRICE_BASE).div(TOKEN_PRICE_USD * FIAT_RATE_BASE);
        emit UpdatedFiatRate(_fiatRate, block.timestamp);
    }
}

 

 
 
pragma solidity ^0.5.0;







contract CappedMultiRoundCrowdsale is UpdatableRateCrowdsale {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

     
    uint256 private constant ROUNDS = 3;
    uint256 private constant CAP_ROUND_ONE = 22500000 ether;
    uint256 private constant CAP_ROUND_TWO = 37500000 ether;
    uint256 private constant CAP_ROUND_THREE = 52500000 ether;
    uint256 private constant HARD_CAP = 52500000 ether;
    uint256 private constant PRICE_PERCENTAGE_ROUND_ONE = 80;
    uint256 private constant PRICE_PERCENTAGE_ROUND_TWO = 90;
    uint256 private constant PRICE_PERCENTAGE_ROUND_THREE = 100;
    uint256 private constant PRICE_PERCENTAGE_BASE = 100;

    uint256 private _currentRoundCap;
    uint256 private _mintedByCrowdsale;
    uint256 private _currentRound;
    uint256[ROUNDS] private _capOfRound;
    uint256[ROUNDS] private _pricePercentagePerRound;
    address private privateVaultAddress;
    address private presaleVaultAddress;
    address private reserveVaultAddress;

     
    event RoundStarted(uint256 indexed roundNumber, uint256 timestamp);

     
     
    constructor (uint256 startingTime) internal {
         
        _pricePercentagePerRound[0] = PRICE_PERCENTAGE_ROUND_ONE;
        _pricePercentagePerRound[1] = PRICE_PERCENTAGE_ROUND_TWO;
        _pricePercentagePerRound[2] = PRICE_PERCENTAGE_ROUND_THREE;
         
        _capOfRound[0] = CAP_ROUND_ONE;
        _capOfRound[1] = CAP_ROUND_TWO;
        _capOfRound[2] = CAP_ROUND_THREE;
         
        _currentRound;
        _currentRoundCap = _capOfRound[_currentRound];
        emit RoundStarted(_currentRound, startingTime);
    }
     
    
     
    modifier stillInRounds() {
        require(_currentRound < ROUNDS, "Not in rounds");
        _;
    }

     
      
    modifier vaultAddressesSet() {
        require(privateVaultAddress != address(0) && presaleVaultAddress != address(0) && reserveVaultAddress != address(0), "Vaults are not set");
        _;
    }
     

     
    function hardCap() public pure returns(uint256) {
        return HARD_CAP;
    }

     
    function currentRoundCap() public view returns(uint256) {
        return _currentRoundCap;
    }
    
     
    function mintedByCrowdsale() public view returns(uint256) {
        return _mintedByCrowdsale;
    }

     
    function rounds() public pure returns(uint256) {
        return ROUNDS;
    }

     
    function currentRound() public view returns(uint256) {
        return _currentRound;
    }

     
    function capOfRound(uint256 index) public view returns(uint256) {
        return _capOfRound[index];
    }

     
    function pricePercentagePerRound(uint256 index) public view returns(uint256) {
        return _pricePercentagePerRound[index];
    }
    
     
    function hardCapReached() public view returns (bool) {
        return _mintedByCrowdsale >= HARD_CAP;
    }

     
    function currentRoundCapReached() public view returns (bool) {
        return _mintedByCrowdsale >= _currentRoundCap;
    }

     
    function closeCurrentRound() public onlyManager stillInRounds {
        _capOfRound[_currentRound] = _mintedByCrowdsale;
        _updateRoundCaps(_currentRound);
    }

     
    function _preValidatePurchase(
        address beneficiary,
        uint256 weiAmount
    )
        internal
        view
        stillInRounds
    {
        super._preValidatePurchase(beneficiary, weiAmount);
    }

     
    function _processPurchase(
        address beneficiary,
        uint256 tokenAmount
    )
        internal
    {
         
         
         
         
         
         
        uint256 finalAmount = _mintedByCrowdsale.add(tokenAmount);
        uint256 totalMintedAmount = _mintedByCrowdsale;

        for (uint256 i = _currentRound; i < ROUNDS; i = i.add(1)) {
            if (finalAmount > _capOfRound[i]) {
                sendToCorrectAddress(beneficiary, _capOfRound[i].sub(totalMintedAmount), _currentRound);
                 
                totalMintedAmount = _capOfRound[i];
                _updateRoundCaps(_currentRound);
            } else {
                _mintedByCrowdsale = finalAmount;
                sendToCorrectAddress(beneficiary, finalAmount.sub(totalMintedAmount), _currentRound);
                if (finalAmount == _capOfRound[i]) {
                    _updateRoundCaps(_currentRound);
                }
                break;
            }
        }
    }

     
    function _getTokenAmount(uint256 weiAmount)
        internal view returns (uint256)
    {
         
        uint256 tokenAmountBeforeDiscount = super._getTokenAmount(weiAmount);
        uint256 tokenAmountForThisRound;
        uint256 tokenAmountForNextRound;
        uint256 tokenAmount;
        for (uint256 round = _currentRound; round < ROUNDS; round = round.add(1)) {
            (tokenAmountForThisRound, tokenAmountForNextRound) = 
            _dealWithBigTokenPurchase(tokenAmountBeforeDiscount, round);
            tokenAmount = tokenAmount.add(tokenAmountForThisRound);
            if (tokenAmountForNextRound == 0) {
                break;
            } else {
                tokenAmountBeforeDiscount = tokenAmountForNextRound;
            }
        }
         
         
        require(tokenAmountForNextRound == 0, "there is still tokens for the next round...");
        return tokenAmount;
    }

     
    function _setVaults(
        IVault privateVault,
        IVault presaleVault,
        IVault reserveVault
    )
        internal
    {
        require(address(privateVault) != address(0), "Not valid address: privateVault");
        require(address(presaleVault) != address(0), "Not valid address: presaleVault");
        require(address(reserveVault) != address(0), "Not valid address: reserveVault");
        privateVaultAddress = address(privateVault);
        presaleVaultAddress = address(presaleVault);
        reserveVaultAddress = address(reserveVault);
    }

     
    function _dealWithBigTokenPurchase(uint256 tokenAmount, uint256 round) 
        private
        view 
        stillInRounds 
        returns (uint256, uint256) 
    {
         
         
         
        uint256 maxTokenAmountOfCurrentRound = (_capOfRound[round]
                                                .sub(_mintedByCrowdsale))
                                                .mul(_pricePercentagePerRound[round])
                                                .div(PRICE_PERCENTAGE_BASE);
        if (tokenAmount < maxTokenAmountOfCurrentRound) {
             
            return (tokenAmount.mul(PRICE_PERCENTAGE_BASE).div(_pricePercentagePerRound[round]), 0);
        } else {
             
            uint256 tokenAmountOfNextRound = tokenAmount.sub(maxTokenAmountOfCurrentRound);
            return (maxTokenAmountOfCurrentRound, tokenAmountOfNextRound);
        }
    }

     
    function sendToCorrectAddress(
        address beneficiary, 
        uint256 tokenAmountToBeSent,
        uint256 roundNumber
    )
        private 
        vaultAddressesSet
    {
        if (roundNumber == 2) {
             
             
            super._processPurchase(beneficiary, tokenAmountToBeSent);
        } else if (roundNumber == 0) {
             
            super._processPurchase(privateVaultAddress, tokenAmountToBeSent);
             
            IVault(privateVaultAddress).receiveFor(beneficiary, tokenAmountToBeSent);
        } else {
             
            super._processPurchase(presaleVaultAddress, tokenAmountToBeSent);
             
            IVault(presaleVaultAddress).receiveFor(beneficiary, tokenAmountToBeSent);
        }
    }

     
    function _updateRoundCaps(uint256 round) private {
        if (round == 0) {
             
            IVault(privateVaultAddress).updateReleaseTime(block.timestamp);
            _currentRound = 1;
            _currentRoundCap = _capOfRound[1];
        } else if (round == 1) {
             
            IVault(presaleVaultAddress).updateReleaseTime(block.timestamp);
            _currentRound = 2;
            _currentRoundCap = _capOfRound[2];
        } else {
             
            IVault(reserveVaultAddress).updateReleaseTime(block.timestamp);
             
            _currentRound = 3;
            _currentRoundCap = _capOfRound[2];
        }
        emit RoundStarted(_currentRound, block.timestamp);
    }
}

 

 
 
pragma solidity ^0.5.0;




contract PausableCrowdsale is PausableManager, Crowdsale {

     
    function _preValidatePurchase(
        address _beneficiary, 
        uint256 _weiAmount
    )
        internal 
        view 
        whenNotPaused 
    {
        return super._preValidatePurchase(_beneficiary, _weiAmount);
    }

}

 

 
 
pragma solidity ^0.5.0;




contract StartingTimedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 private _startingTime;

     
    modifier onlyWhileOpen {
        require(isStarted(), "Not yet started");
        _;
    }

     
    constructor(uint256 startingTime) internal {
         
        require(startingTime >= block.timestamp, "Starting time is in the past");

        _startingTime = startingTime;
    }

     
    function startingTime() public view returns(uint256) {
        return _startingTime;
    }

     
    function isStarted() public view returns (bool) {
         
        return block.timestamp >= _startingTime;
    }

     
    function _preValidatePurchase(
        address beneficiary,
        uint256 weiAmount
    )
        internal
        onlyWhileOpen
        view
    {
        super._preValidatePurchase(beneficiary, weiAmount);
    }
}

 

 
 
pragma solidity ^0.5.0;




 
contract FinalizableCrowdsale is StartingTimedCrowdsale {
    using SafeMath for uint256;

    bool private _finalized;

    event CrowdsaleFinalized(address indexed account);

    constructor () internal {
        _finalized = false;
    }

     
    function finalized() public view returns (bool) {
        return _finalized;
    }

     
    function finalize() public {
        require(!_finalized, "already finalized");

        _finalized = true;

        emit CrowdsaleFinalized(msg.sender);
    }
}

 

pragma solidity ^0.5.0;



 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

      
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
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
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
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
     
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

 

pragma solidity ^0.5.0;



 
contract MintedCrowdsale is Crowdsale {
     
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
         
        require(
            ERC20Mintable(address(token())).mint(beneficiary, tokenAmount),
                "MintedCrowdsale: minting failed"
        );
    }
}

 

 
 
pragma solidity ^0.5.0;














contract IvoCrowdsale is IIvoCrowdsale, CounterGuard, Reclaimable, MintedCrowdsale, 
    NonEthPurchasableCrowdsale, CappedMultiRoundCrowdsale, WhitelistCrowdsale, 
    PausableCrowdsale, FinalizableCrowdsale {
     
    uint256 private constant ROUNDS = 3;
    uint256 private constant KYC_AML_RATE_DEDUCTED = 965;
    uint256 private constant KYC_AML_FEE_BASE = 1000;
    bool private _setRole;

     
     
    constructor(
        uint256 startingTime,
        uint256 rate,
        uint256 initialFiatRate,
        address payable wallet, 
        IERC20 token
    ) 
        public
        Crowdsale(rate, wallet, token)
        UpdatableRateCrowdsale(initialFiatRate)
        CappedMultiRoundCrowdsale(startingTime)
        StartingTimedCrowdsale(startingTime) {}
     
    
     
    function nonEthPurchases(
        address[] calldata beneficiaries, 
        uint256[] calldata amounts
    ) 
        external
        onlyManager 
    {
        uint256 length = amounts.length;
        require(beneficiaries.length == length, "length !=");
        require(length <= 256, "To long, please consider shorten the array");
        for (uint256 i = 0; i < length; i++) {
            super.nonEthPurchase(beneficiaries[i], amounts[i]);
        }
    }
    
     
    function nonEthPurchase(address beneficiary, uint256 tokenAmount) 
        public 
        onlyManager 
    {
        super.nonEthPurchase(beneficiary, tokenAmount);
    }

     
    function closeCurrentRound() public onlyWhileOpen {
        super.closeCurrentRound();
    }

     
    function roleSetup(
        address newOwner,
        IVault privateVault,
        IVault presaleVault,
        IVault reserveVault
    )
        public
        onlyOwner
        onlyOnce(_setRole)
    {
        _setVaults(privateVault, presaleVault, reserveVault);
        addManager(newOwner);
        _removeManager(msg.sender);
        transferOwnership(newOwner);
        _setRole = true;
    }

      
    function finalize() public onlyManager {
        require(this.currentRound() == ROUNDS, "Multi-rounds has not yet completed");
        super.finalize();
        PausableManager(address(token())).unpause();
        ERC20Mintable(address(token())).addMinter(msg.sender);
        ERC20Mintable(address(token())).renounceMinter();
    }

         
     
    function _getTokenAmount(uint256 weiAmount)
        internal
        view 
        returns (uint256)
    {
        uint256 availableWei = weiAmount.mul(KYC_AML_RATE_DEDUCTED).div(KYC_AML_FEE_BASE);
        return super._getTokenAmount(availableWei);
    }
}