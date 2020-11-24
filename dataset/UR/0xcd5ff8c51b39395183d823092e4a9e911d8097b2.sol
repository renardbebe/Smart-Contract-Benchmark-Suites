 

pragma solidity 0.5.11;

 
library SafeMath {

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

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

}

 
interface IBTALToken {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function mint(address account, uint256 amount) external returns (bool);
    function lock(address account, uint256 amount, uint256 time) external;
    function release() external;
    function hardcap() external view returns(uint256);
    function isAdmin(address account) external view returns (bool);
    function isOwner(address account) external view returns (bool);
}

 
 interface IExchange {
     function acceptETH() external payable;
     function finish() external;
     function reserveAddress() external view returns(address payable);
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

 
contract WhitelistedRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    IBTALToken private _token;

    modifier onlyAdmin() {
        require(_token.isAdmin(msg.sender), "Caller has no permission");
        _;
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "Sender is not whitelisted");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyAdmin {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function addListToWhitelisted(address[] memory accounts) public {
        for (uint256 i = 0; i < accounts.length; i++) {
            addWhitelisted(accounts[i]);
        }
    }

    function removeWhitelisted(address account) public onlyAdmin {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }

    function removeListWhitelisted(address[] memory accounts) public {
        for (uint256 i = 0; i < accounts.length; i++) {
            removeWhitelisted(accounts[i]);
        }
    }

}

 
contract EnlistedRole {
    using Roles for Roles.Role;

    event EnlistedAdded(address indexed account);
    event EnlistedRemoved(address indexed account);

    Roles.Role private _enlisted;

    IBTALToken private _token;

    modifier onlyAdmin() {
        require(_token.isAdmin(msg.sender));
        _;
    }

    modifier onlyEnlisted() {
        require(isEnlisted(msg.sender), "Sender is not Enlisted");
        _;
    }

    function isEnlisted(address account) public view returns (bool) {
        return _enlisted.has(account);
    }

    function addEnlisted(address account) public onlyAdmin {
        _enlisted.add(account);
        emit EnlistedAdded(account);
    }

    function addListToEnlisted(address[] memory accounts) public {
        for (uint256 i = 0; i < accounts.length; i++) {
            addEnlisted(accounts[i]);
        }
    }

    function removeEnlisted(address account) public onlyAdmin {
        _enlisted.remove(account);
        emit EnlistedRemoved(account);
    }
    
    function removeListEnlisted(address[] memory accounts) public {
        for (uint256 i = 0; i < accounts.length; i++) {
            removeEnlisted(accounts[i]);
        }
    }
}

 
contract Crowdsale is ReentrancyGuard, WhitelistedRole, EnlistedRole {
    using SafeMath for uint256;

     
    address internal _initAddress;

     
    IBTALToken private _token;

     
    address payable private _wallet;
    address payable private _exchangeAddr;
    address private _bonusAddr;
    address private _teamAddr;
    address private _priceProvider;

     
    uint256 private _weiRaised;  
    uint256 private _tokensPurchased;  
    uint256 private _reserved;  

     
    uint256 private _reserveTrigger = 210000000 * (10**18);  
    uint256 private _reserveLimit = 150000;  

     
    uint256 private _currentETHPrice;
    uint256 private _decimals;

     
    uint256 private _rate;

     
    uint256 private _bonusPercent = 500;

     
    uint256 private _minimum = 26 ether;  

     
    uint256 private _hardcap;  

     
    uint256 private _endTime;  

     
    enum Reserving {OFF, ON}
    Reserving private _reserve = Reserving.OFF;

    enum State {Usual, Whitelist, PrivateSale, Closed}
    State public state = State.Usual;

     
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event TokensSent(address indexed sender, address indexed beneficiary, uint256 amount);
    event NewETHPrice(uint256 oldValue, uint256 newValue, uint256 decimals);
    event Payout(address indexed recipient, uint256 weiAmount, uint256 usdAmount);
    event BonusPayed(address indexed beneficiary, uint256 amount);
    event ReserveState(bool isActive);
    event StateChanged(string currentState);

     
    modifier active() {
        require(
            block.timestamp <= _endTime
            && _tokensPurchased < _hardcap
            && state != State.Closed
            );
        _;
    }

     
    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }

     
    constructor() public {
        _initAddress = msg.sender;
    }

     
    function init(
        uint256 rate,
        uint256 initialETHPrice,
        uint256 decimals,
        address payable wallet,
        address bonusAddr,
        address teamAddr,
        address payable exchange,
        IBTALToken token,
        uint256 endTime,
        uint256 hardcap
        ) public {

        require(msg.sender == _initAddress);
        require(address(_token) == address(0));

        require(rate != 0, "Rate is 0");
        require(initialETHPrice != 0, "Initial ETH price is 0");
        require(wallet != address(0), "Wallet is the zero address");
        require(bonusAddr != address(0), "BonusAddr is the zero address");
        require(teamAddr != address(0), "TeamAddr is the zero address");
        require(isContract(address(token)), "Token is not a contract");
        require(isContract(exchange), "Exchange is not a contract");
        require(endTime != 0, "EndTime is 0");
        require(hardcap != 0, "HardCap is 0");


        _rate = rate;
        _currentETHPrice = initialETHPrice;
        _decimals = decimals;
        _wallet = wallet;
        _bonusAddr = bonusAddr;
        _teamAddr = teamAddr;
        _exchangeAddr = exchange;
        _token = token;
        _endTime = endTime;
        _hardcap = hardcap;
    }

     
    function() external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public payable nonReentrant active {
        require(beneficiary != address(0), "New parameter value is the zero address");
        require(msg.value >= _minimum, "Wei amount is less than minimum");

        if (state == State.Whitelist) {
            require(isWhitelisted(beneficiary), "Beneficiary is not whitelisted");
        }

        if (state == State.PrivateSale) {
            require(isEnlisted(beneficiary), "Beneficiary is not enlisted");
        }

        uint256 weiAmount = msg.value;

        uint256 tokens = weiToTokens(weiAmount);

        uint256 bonusAmount = tokens.mul(_bonusPercent).div(10000);

        if (_tokensPurchased.add(tokens).add(bonusAmount) > _hardcap) {
            tokens = (_hardcap.sub(_tokensPurchased)).mul(10000).div(_bonusPercent.add(10000));
            bonusAmount = _hardcap.sub(_tokensPurchased).sub(tokens);
            weiAmount = tokensToWei(tokens);
            _sendETH(msg.sender, msg.value.sub(weiAmount));
        }

        if (bonusAmount > 0) {
            _token.mint(_bonusAddr, bonusAmount);
            emit BonusPayed(beneficiary, bonusAmount);
        }

        if (
            _tokensPurchased <= _reserveTrigger
            && _tokensPurchased.add(tokens) > _reserveTrigger
            && reserved() < _reserveLimit
            ) {
            _reserve = Reserving.ON;
            emit ReserveState(true);
            uint256 unreservedWei = tokensToWei(_reserveTrigger.sub(_tokensPurchased));
            _sendETH(_wallet, unreservedWei);
            refund(weiAmount.sub(unreservedWei));
        } else {
            refund(weiAmount);
        }

        _token.mint(beneficiary, tokens);

        _tokensPurchased = _tokensPurchased.add(tokens);
        _weiRaised = _weiRaised.add(weiAmount);

        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

    }

     
    function _sendTokens(address recipient, uint256 amount) internal {
        require(recipient != address(0), "Recipient is the zero address");
        _token.mint(recipient, amount);
        emit TokensSent(msg.sender, recipient, amount);
    }

     
    function sendTokens(address recipient, uint256 amount) public onlyAdmin {
        _sendTokens(recipient, amount);
        _tokensPurchased = _tokensPurchased.add(amount);
    }

     
    function sendTokensToList(address[] memory recipients, uint256 amount) public onlyAdmin {
        require(recipients.length > 0);
        for (uint256 i = 0; i < recipients.length; i++) {
            _sendTokens(recipients[i], amount);
        }
        _tokensPurchased = _tokensPurchased.add(amount.mul(recipients.length));
    }

     
     function sendTokensPerWei(address recipient, uint256 weiAmount) public onlyAdmin {
         _sendTokens(recipient, weiToTokens(weiAmount));
         _tokensPurchased = _tokensPurchased.add(weiToTokens(weiAmount));
     }

      
     function sendTokensPerWeiToList(address[] memory recipients, uint256 weiAmount) public onlyAdmin {
         require(recipients.length > 0);
         for (uint256 i = 0; i < recipients.length; i++) {
             _sendTokens(recipients[i], weiToTokens(weiAmount));
         }
         _tokensPurchased = _tokensPurchased.add(weiToTokens(weiAmount).mul(recipients.length));
     }

     
     function refund(uint256 weiAmount) internal {
         if (_reserve == Reserving.OFF) {
             _sendETH(_wallet, weiAmount);
         } else {
             if (USDToWei(_reserveLimit) >= _reserved) {
                 if (weiToUSD(_reserved.add(weiAmount)) >= _reserveLimit) {

                     uint256 reservedWei = USDToWei(_reserveLimit).sub(_reserved);
                     _sendETH(_exchangeAddr, reservedWei);
                     uint256 unreservedWei = weiAmount.sub(reservedWei);
                     _sendETH(_wallet, unreservedWei);

                     _reserved = USDToWei(_reserveLimit);
                     _reserve = Reserving.OFF;
                     emit ReserveState(false);
                } else {
                     _reserved = _reserved.add(weiAmount);
                     _sendETH(_exchangeAddr, weiAmount);
                }
             } else {
                 _sendETH(_wallet, weiAmount);
                 _reserve = Reserving.OFF;
                 emit ReserveState(false);
             }
         }
     }

     function _sendETH(address payable recipient, uint256 weiAmount) internal {
         require(recipient != address(0));

         if (recipient == _exchangeAddr) {
             IExchange(_exchangeAddr).acceptETH.value(weiAmount)();
         } else {
             recipient.transfer(weiAmount);
         }

         emit Payout(recipient, weiAmount, weiToUSD(weiAmount));
     }

     
    function finishSale() public onlyAdmin {
        require(isEnded());

        _token.mint(IExchange(_exchangeAddr).reserveAddress(), _token.hardcap().sub(_token.totalSupply()));
        _token.lock(_teamAddr, _token.balanceOf(_teamAddr), 31536000);
        _token.release();
        IExchange(_exchangeAddr).finish();

        emit StateChanged("Usual");
        state = State.Usual;
    }

     
    function weiToTokens(uint256 weiAmount) internal view returns(uint256) {
        return weiAmount.mul(_currentETHPrice).mul(_rate).div(10**_decimals).div(1 ether);
    }

     
    function tokensToWei(uint256 tokenAmount) internal view returns(uint256) {
        return tokenAmount.mul(1 ether).mul(10**_decimals).div(_rate).div(_currentETHPrice);
    }

     
    function weiToUSD(uint256 weiAmount) internal view returns(uint256) {
        return weiAmount.mul(_currentETHPrice).div(10**_decimals).div(1 ether);
    }

     
    function USDToWei(uint256 USDAmount) internal view returns(uint256) {
        return USDAmount.mul(1 ether).mul(10**_decimals).div(_currentETHPrice);
    }

     
    function tokensToUSD(uint256 tokenAmount) internal view returns(uint256) {
        return weiToUSD(tokensToWei(tokenAmount));
    }

     
    function setRate(uint256 newRate) external onlyAdmin {
        require(newRate != 0, "New parameter value is 0");

        _rate = newRate;
    }

     
    function setEthPriceProvider(address provider) external onlyAdmin {
        require(provider != address(0), "New parameter value is the zero address");
        require(isContract(provider));

        _priceProvider = provider;
    }

     
    function setWallet(address payable newWallet) external onlyAdmin {
        require(newWallet != address(0), "New parameter value is the zero address");

        _wallet = newWallet;
    }

     
    function setBonusAddr(address newBonusAddr) external onlyAdmin {
        require(newBonusAddr != address(0), "New parameter value is the zero address");

        _bonusAddr = newBonusAddr;
    }


     
    function setTeamAddr(address payable newTeamAddr) external onlyAdmin {
        require(newTeamAddr != address(0), "New parameter value is the zero address");

        _teamAddr = newTeamAddr;
    }

     
    function setExchangeAddr(address payable newExchange) external onlyAdmin {
        require(newExchange != address(0), "New parameter value is the zero address");
        require(isContract(newExchange), "Exchange is not a contract");

        _exchangeAddr = newExchange;
    }

     
    function setETHPrice(uint256 newPrice) external {
        require(newPrice != 0, "New parameter value is 0");
        require(msg.sender == _priceProvider || isAdmin(msg.sender), "Sender has no permission");

        emit NewETHPrice(_currentETHPrice, newPrice, _decimals);
        _currentETHPrice = newPrice;
    }

     
    function setDecimals(uint256 newDecimals) external {
        require(msg.sender == _priceProvider || isAdmin(msg.sender), "Sender has no permission");

        _decimals = newDecimals;
    }

     
    function setEndTime(uint256 newTime) external onlyAdmin {
        require(newTime != 0, "New parameter value is 0");

        _endTime = newTime;
    }

     
    function setBonusPercent(uint256 newPercent) external onlyAdmin {

        _bonusPercent = newPercent;
    }

     
    function setHardCap(uint256 newCap) external onlyAdmin {
        require(newCap != 0, "New parameter value is 0");

        _hardcap = newCap;
    }

     
    function setMinimum(uint256 newMinimum) external onlyAdmin {
        require(newMinimum != 0, "New parameter value is 0");

        _minimum = newMinimum;
    }

     
    function setReserveLimit(uint256 newResLimitUSD) external onlyAdmin {
        require(newResLimitUSD != 0, "New parameter value is 0");

        _reserveLimit = newResLimitUSD;
    }

     
    function setReserveTrigger(uint256 newReserveTrigger) external onlyAdmin {
        require(newReserveTrigger != 0, "New parameter value is 0");

        _reserveTrigger = newReserveTrigger;
    }

     
    function switchWhitelist() external onlyAdmin {
        require(state != State.Whitelist);
        emit StateChanged("Whitelist");
        state = State.Whitelist;
    }

     
    function switchPrivateSale() external onlyAdmin {
        require(state != State.PrivateSale);
        emit StateChanged("PrivateSale");
        state = State.PrivateSale;
    }

     
    function switchClosed() external onlyAdmin {
        require(state != State.Closed);
        emit StateChanged("Closed");
        state = State.Closed;
    }

     
    function switchUsual() external onlyAdmin {
        require(state != State.Usual);
        emit StateChanged("Usual");
        state = State.Usual;
    }

     
    function withdrawERC20(address ERC20Token, address recipient) external onlyAdmin {

        uint256 amount = IBTALToken(ERC20Token).balanceOf(address(this));
        require(amount > 0);
        IBTALToken(ERC20Token).transfer(recipient, amount);

    }

     
    function token() public view returns (IBTALToken) {
        return _token;
    }

     
    function wallet() public view returns (address payable) {
        return _wallet;
    }

     
    function bonusAddr() public view returns (address) {
        return _bonusAddr;
    }

     
    function teamAddr() public view returns (address) {
        return _teamAddr;
    }

     
    function exchange() public view returns (address payable) {
        return _exchangeAddr;
    }

     
    function priceProvider() public view returns (address) {
        return _priceProvider;
    }

     
    function rate() public view returns (uint256) {
        return _rate;
    }

     
    function currentETHPrice() public view returns (uint256 price) {
        return(_currentETHPrice);
    }

     
    function currentETHPriceDecimals() public view returns (uint256 decimals) {
        return(_decimals);
    }

     
    function bonusPercent() public view returns (uint256) {
        return _bonusPercent;
    }

     
    function minimum() public view returns (uint256) {
        return _minimum;
    }

     
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

     
    function reserved() public view returns (uint256) {
        return weiToUSD(_reserved);
    }

     
    function reserveLimit() public view returns (uint256) {
        return _reserveLimit;
    }

     
    function reserveTrigger() public view returns (uint256) {
        return _reserveTrigger;
    }

     
    function hardcap() public view returns (uint256) {
        return _hardcap;
    }

     
    function endTime() public view returns (uint256) {
        return _endTime;
    }

     
    function tokensPurchased() public view returns (uint256) {
        return _tokensPurchased;
    }

     
    function isOwner(address account) internal view returns (bool) {
        return _token.isOwner(account);
    }

     
    function isAdmin(address account) internal view returns (bool) {
        return _token.isAdmin(account);
    }

     
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

     
    function isEnded() public view returns (bool) {
        return (_tokensPurchased >= _hardcap || block.timestamp >= _endTime);
    }

}