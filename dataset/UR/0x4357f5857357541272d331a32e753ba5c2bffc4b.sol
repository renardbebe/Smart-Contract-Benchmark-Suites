 

pragma solidity ^0.5.8;


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

    contract ERC20Mintable is ERC20, MinterRole {
        
        function mint(address account, uint256 amount) public onlyMinter returns (bool) {
            _mint(account, amount);
            return true;
        }
    }

    contract ERC20Capped is ERC20Mintable {
        uint256 private _cap;

        
        constructor (uint256 cap) public {
            require(cap > 0, "ERC20Capped: cap is 0");
            _cap = cap;
        }

        
        function cap() public view returns (uint256) {
            return _cap;
        }

        
        function _mint(address account, uint256 value) internal {
            require(totalSupply().add(value) <= _cap, "ERC20Capped: cap exceeded");
            super._mint(account, value);
        }
    }

    contract ERC20Burnable is ERC20 {
        
        function burn(uint256 amount) public {
            _burn(msg.sender, amount);
        }

        
        function burnFrom(address account, uint256 amount) public {
            _burnFrom(account, amount);
        }
    }

    library Address {
        
        function isContract(address account) internal view returns (bool) {
            
            
            

            uint256 size;
            
            assembly { size := extcodesize(account) }
            return size > 0;
        }
    }

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

    contract Crowdsale is ReentrancyGuard {
        using SafeMath for uint256;
        using SafeERC20 for IERC20;

        
        IERC20 private _token;

        
        address payable private _wallet;

        
        
        
        
        uint256 private _rate;

        
        uint256 private _weiRaised;

        
        event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

        event RateAdjusted(uint256 adjustedRate);

        
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

        
        function adjustRate(uint256 newRate) public {
            require(newRate > 0, "Crowdsale-adjustRate: Rate has to be non-zero");
            _rate = newRate;
            emit RateAdjusted(newRate);
        }

        
        function _forwardFunds() internal {
            _wallet.transfer(msg.value);
        }
    }

    contract TimedCrowdsale is Crowdsale {
        using SafeMath for uint256;

        uint256 private _openingTime;
        uint256 private _closingTime;

        
        event TimedCrowdsaleExtended(uint256 prevClosingTime, uint256 newClosingTime);

        
        modifier onlyWhileOpen {
            require(isOpen(), "TimedCrowdsale: not open");
            _;
        }

        
        constructor (uint256 openingTime, uint256 closingTime) public {
            
            require(openingTime >= block.timestamp, "TimedCrowdsale: opening time is before current time");
            
            require(closingTime > openingTime, "TimedCrowdsale: opening time is not before closing time");

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

        
        function _extendTime(uint256 newClosingTime) internal {
            require(!hasClosed(), "TimedCrowdsale: already closed");
            
            require(newClosingTime > _closingTime, "TimedCrowdsale: new closing time is before current closing time");

            emit TimedCrowdsaleExtended(_closingTime, newClosingTime);
            _closingTime = newClosingTime;
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
            require(msg.sender == _primary, "Secondary: caller is not the primary account");
            _;
        }

        
        function primary() public view returns (address) {
            return _primary;
        }

        
        function transferPrimary(address recipient) public onlyPrimary {
            require(recipient != address(0), "Secondary: new primary is the zero address");
            _primary = recipient;
            emit PrimaryTransferred(_primary);
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
            require(isManager(msg.sender), "ManagerRole-onlyManager: The account is not a manager");
            _;
        }

        
        
        function addManagers(address[] calldata accounts) external onlyOwner {
            uint256 length = accounts.length;
            require(length <= 256, "ManagerRole-addManagers:too many accounts");
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
            require(account != address(0), "ManagerRole-addManager: account is zero");
            _addManager(account);
        }

        
        function renounceManager() public {
            require(_numManager >= 2, "ManagerRole-renounceManager: Managers are fewer than 2");
            _removeManager(msg.sender);
        }

        
        function renounceOwnership() public onlyOwner {
            revert("ManagerRole-renounceOwnership: Cannot renounce ownership");
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

    contract PausableManager is ManagerRole {

        event BePaused(address manager);
        event BeUnpaused(address manager);

        bool private _paused;   

        constructor() internal {
            _paused = false;
        }

    
        modifier whenNotPaused() {
            require(!_paused, "PausableManager-whenNotPaused: paused");
            _;
        }

        
        modifier whenPaused() {
            require(_paused, "PausableManager-whenPaused: not paused");
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

    contract ValidAddress {
        
        modifier onlyValidAddress(address _address) {
            require(_address != address(0), "ValidAddress-onlyValidAddress:Not a valid address");
            _;
        }

        
        modifier isSenderNot(address _address) {
            require(_address != msg.sender, "ValidAddress-isSenderNot:Address is the same as the sender");
            _;
        }

        
        modifier isSender(address _address) {
            require(_address == msg.sender, "ValidAddress-isSender: Address is different from the sender");
            _;
        }
    }

    contract Whitelist is ValidAddress, PausableManager {

        mapping (address => bool) private _isWhitelisted;       
        mapping(address => uint) public _contributionAmounts;   
        uint public totalWhiteListed;                           
        address[] public holdersIndex;                          

        event AdddWhitelisted(address indexed user);
        event RemovedWhitelisted(address indexed user);


        
        function addWhitelisted(address user, uint256 maxAllowed) external onlyManager {
            _addWhitelisted(user, maxAllowed);
        }

        
        
        function addWhitelistedMultiple(address[] calldata users, uint256[] calldata maxAllowed) external onlyManager {
            uint256 length = users.length;
            require(length <= 256, "Whitelist-addWhitelistedMultiple: List too long");
            for (uint256 i = 0; i < length; i++) {
                _addWhitelisted(users[i], maxAllowed[i]);
            }
        }

        
        function removeWhitelisted(address user)
            external
            onlyManager
        {
            _removeWhitelisted(user);
        }

        
        
        function removeWhitelistedMultiple(address[] calldata users)
            external
            onlyManager
        {
            uint256 length = users.length;
            require(length <= 256, "Whitelist-removeWhitelistedMultiple: List too long");
            for (uint256 i = 0; i < length; i++) {
                _removeWhitelisted(users[i]);
            }
        }

        
        function isWhitelisted(address user) public view returns (bool) {
            return _isWhitelisted[user];
        }

        
        function returnMaxAmountForUser(address user) public view returns (uint256) {
            return  _contributionAmounts[user];
        }

        
        function _addWhitelisted(address user, uint maxToContribute)
            internal
            onlyValidAddress(user)
        {
            require(_isWhitelisted[user] == false, "Whitelist-_addWhitelisted: account already whitelisted");
            _isWhitelisted[user] = true;
            _contributionAmounts[user] = maxToContribute;
            totalWhiteListed++;
            holdersIndex.push(user);
            emit AdddWhitelisted(user);
        }

        
        function _removeWhitelisted(address user)
            internal
            onlyValidAddress(user)
        {
            require(_isWhitelisted[user] == true, "Whitelist-_removeWhitelisted: account was not whitelisted");
            _isWhitelisted[user] = false;
            _contributionAmounts[user] = 0;
            totalWhiteListed--;
            emit RemovedWhitelisted(user);
        }
    }

    contract WhitelistCrowdsale is Whitelist, Crowdsale {
        
        function _preValidatePurchase(address beneficiary, uint256 weiAmount)
            internal
            view
        {
            require(isWhitelisted(beneficiary), "WhitelistCrowdsale-_preValidatePurchase: beneficiary is not whitelisted");
            super._preValidatePurchase(beneficiary, weiAmount);
        }
    }

    contract PostDeliveryCrowdsale is TimedCrowdsale, WhitelistCrowdsale {
        using SafeMath for uint256;

        mapping(address => uint256) private _balances;
        __unstable__TokenVault private _vault;

        constructor() public {
            _vault = new __unstable__TokenVault();
            
            _addWhitelisted(address(_vault), 0);
        }

        
        function withdrawTokens(address beneficiary) public {
            require(hasClosed(), "PostDeliveryCrowdsale: not closed");
            uint256 amount = _balances[beneficiary];
            require(amount > 0, "PostDeliveryCrowdsale: beneficiary is not due any tokens");

            _balances[beneficiary] = 0;
            _vault.transfer(token(), beneficiary, amount);
        }

        
        function balanceOf(address account) public view returns (uint256) {
            return _balances[account];
        }

        
        function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
            _balances[beneficiary] = _balances[beneficiary].add(tokenAmount);
            _deliverTokens(address(_vault), tokenAmount);
        }
    }

    contract __unstable__TokenVault is Secondary {
        function transfer(IERC20 token, address to, uint256 amount) public onlyPrimary {
            token.transfer(to, amount);
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
            require(!_finalized, "FinalizableCrowdsale: already finalized");
            require(hasClosed(), "FinalizableCrowdsale: not closed");

            _finalized = true;

            _finalization();
            emit CrowdsaleFinalized();
        }

        
        function _finalization() internal {
            
        }
    }

    contract CounterGuard {
        
        modifier onlyOnce(bool criterion) {
            require(criterion == false, "CounterGuard-onlyOnce: Already been set");
            _;
        }
    }

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

    contract ECrowdsale is CounterGuard, WhitelistCrowdsale,
                            PostDeliveryCrowdsale, FinalizableCrowdsale,
                            PausableCrowdsale {
    
        bool private _setRole;              
        uint256 private _maxCryptoSale;     
        uint256 private _cryptoSaleAmount;  
        bool private _noCryptoLimits;       
        address payable private _wallet;    
        uint256 private _weiRaised;

        event WithdrawTokens(address beneficiary, uint256 value);
        event RefundExtra(address beneficiary, uint256 value);
        event NonEthTokenPurchased(address indexed beneficiary, uint256 tokenAmount);

        

        constructor(
            uint256 startingTime,
            uint256 endingTime,
            uint256 rate,
            address payable wallet,
            IERC20 token,
            uint maxCryptoSale
        )
            public
            Crowdsale(rate, wallet, token)
            TimedCrowdsale(startingTime, endingTime)
            {
                _wallet = wallet;
                _maxCryptoSale = maxCryptoSale;
                _noCryptoLimits = false;
            }

        
        function nonEthPurchase(address beneficiary, uint256 tokenAmount)
            public onlyManager
        {
            require(beneficiary != address(0), "ECrowdsale-nonEthPurchase: beneficiary is the zero address");
            _processPurchase(beneficiary, tokenAmount);
            emit NonEthTokenPurchased(beneficiary, tokenAmount);
        }

        
        function _preValidatePurchaseCrypto(address beneficiary, uint256 weiAmount) private view {
            require(returnMaxAmountForUser(beneficiary).sub(balanceOf(beneficiary)) >= weiAmount,
                    "ECrowdsale-_preValidatePurchaseCrypto: contribution exceeds allowed amount");
            super._preValidatePurchase(beneficiary, weiAmount);
        }


        
        function nonEthPurchaseMulti(
            address[] calldata beneficiaries,
            uint256[] calldata amounts
        )
            external
        {
            uint256 length = amounts.length;
            require(beneficiaries.length == length, "length !=");
            require(length <= 256, "ECrowdsale-nonEthPurchaseMulti: List too long, please shorten the array");
            for (uint256 i = 0; i < length; i++) {
                nonEthPurchase(beneficiaries[i], amounts[i]);
            }
        }

        
        function roleSetup(
            address newOwner
        )
            public
            onlyOwner
            onlyOnce(_setRole)
        {
            if (address(newOwner) != address(msg.sender) ) {
                addManager(newOwner);
                _removeManager(msg.sender);
                transferOwnership(newOwner);
            }
            _setRole = true;
        }

        
        function withdrawTokens(address beneficiary) public {

            require(finalized(), "ECrowdsale:withdrawTokens - Crowdsale is not finalized");

            uint256 balanceOf = balanceOf(beneficiary);
            super.withdrawTokens(beneficiary);
            emit WithdrawTokens(beneficiary, balanceOf);
        }

        
        function claimTokens() public {

            address payable beneficiary = msg.sender;
            withdrawTokens(beneficiary);
        }

        
        function cryptoSaleAmount() public view returns(uint256) {

            return _cryptoSaleAmount;
        }

        
        function allowRemainingTokensForCrypto() public onlyManager {

            _noCryptoLimits = true;

        }

        
        function extendTime(uint256 newClosingTime) public onlyManager {
        super._extendTime(newClosingTime);
        }

        
        function weiRaised() public view returns (uint256) {
            return _weiRaised;
        }

        
        function finalize() public  onlyManager {
            super.finalize();
        }

        
        function buyTokens(address beneficiary) public payable   {

            uint256 extra = msg.value % rate();
            uint256 amountPaid;

            amountPaid = msg.value - extra;

            _preValidatePurchaseCrypto(beneficiary, amountPaid);
            uint256 tokens = amountPaid / rate();
            _cryptoSaleAmount += tokens;  

            require(_cryptoSaleAmount <= _maxCryptoSale || _noCryptoLimits,
            "ECrowdsale-buyTokens: Max available for crypto sale has been reached");

            _weiRaised += amountPaid;
            _processPurchase(beneficiary, tokens);
            _wallet.transfer(amountPaid);
            emit TokensPurchased(msg.sender, beneficiary, amountPaid, tokens);

            if (extra > 0) {
                msg.sender.transfer(extra);
                emit RefundExtra(msg.sender, extra);
            }
        }

        
        function adjustRate(uint256 newRate) public onlyManager {
            super.adjustRate(newRate);
        }
    }

    contract Token is CounterGuard, ERC20Detailed,
        ERC20Capped, ERC20Burnable, PausableManager {

        uint256 private constant ALLOCATION = 10000; 
        bool private _setRole;
        address  payable public crowdsaleContractAddress;

        event logPayment(address indexed paymentAddress, uint amount, uint date);

        
        struct Payment {

            uint date;
            uint amount;
            address paymentContractAddress;
        }

        Payment[] public payments;  


        
        constructor(
            string memory name,
            string memory symbol,
            uint8 decimals,
            uint256 cap
        )
            public
            ERC20Detailed(name, symbol, decimals)
            ERC20Capped(cap) {
                pause();
            }


        
        modifier onlyWhitelisted(address user) {

            require(ECrowdsale(crowdsaleContractAddress).isWhitelisted(user), "Token-onlyWhitelisted: user is not whitelisted");
            _;
        }


        
        function registerPayment(address paymentAddress, uint amount) public  {

            require(msg.sender == owner() || msg.sender == paymentAddress, "Token-registerPayment: You are not authorized to make this call");

            require(paymentAddress != address(0), "Token-registerPayment: Payment address can't be 0x0");
            require(amount > 0, "Token-registerPayment: Payment amount can't be 0");

            uint index = payments.length;
            payments.length ++;

            payments[index].date = now;
            payments[index].amount = amount;
            payments[index].paymentContractAddress = paymentAddress;
            emit logPayment(paymentAddress, amount, now);
        }


        
        function returnPaymentNum() public view returns ( uint) {

            return payments.length;
        }


        
        function isWhitelisted(address user) public view returns (bool) {

            return ECrowdsale(crowdsaleContractAddress).isWhitelisted(user);
        }


        
        function transfer(address to, uint256 value)
            public
            whenNotPaused
            onlyWhitelisted(to)
            returns (bool)
        {
            
            return super.transfer(to, value);
        }

        
        function transferFrom(address from, address to, uint256 value)
            public
            whenNotPaused
            onlyWhitelisted(to)
            returns (bool)
        {
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

        
        function roleSetup(
            address _newOwner,
            address payable _crowdsaleContractAddress
        )
            public
            onlyOwner
            onlyOnce(_setRole)
        {
            _setRole = true;
            crowdsaleContractAddress = _crowdsaleContractAddress;
            mint(crowdsaleContractAddress, ALLOCATION);

            if (address(_newOwner) != address(msg.sender) ) {
                addManager(_newOwner);
                addMinter(_newOwner);
                _removeManager(msg.sender);
                _removeMinter(msg.sender);
                transferOwnership(_newOwner);
            }
        }
    }