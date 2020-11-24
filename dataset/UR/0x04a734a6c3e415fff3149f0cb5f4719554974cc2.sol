 

pragma solidity ^0.5.0;

pragma experimental ABIEncoderV2;

 
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

 
library SignedSafeMath {
    int256 constant private INT256_MIN = -2**255;

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN));  

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);  
        require(!(b == -1 && a == INT256_MIN));  

        int256 c = a / b;

        return c;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
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

 
interface AdminInterface {
     
    function emergencyShutdown() external;

     
     
    function remargin() external;
}

contract ExpandedIERC20 is IERC20 {
     
    function burn(uint value) external;

     
     
    function mint(address to, uint value) external;
}

 
interface StoreInterface {

     
    function payOracleFees() external payable;

     
     
    function payOracleFeesErc20(address erc20Address) external; 

     
     
     
    function computeOracleFees(uint startTime, uint endTime, uint pfc) external view returns (uint feeAmount);
}

interface ReturnCalculatorInterface {
     
    function computeReturn(int oldPrice, int newPrice) external view returns (int assetReturn);

     
     
    function leverage() external view returns (int _leverage);
}

 
interface PriceFeedInterface {
     
    function isIdentifierSupported(bytes32 identifier) external view returns (bool isSupported);

     
     
    function latestPrice(bytes32 identifier) external view returns (uint publishTime, int price);

     
    event PriceUpdated(bytes32 indexed identifier, uint indexed time, int price);
}

contract AddressWhitelist is Ownable {
    enum Status { None, In, Out }
    mapping(address => Status) private whitelist;

    address[] private whitelistIndices;

     
    function addToWhitelist(address newElement) external onlyOwner {
         
        if (whitelist[newElement] == Status.In) {
            return;
        }

         
        if (whitelist[newElement] == Status.None) {
            whitelistIndices.push(newElement);
        }

        whitelist[newElement] = Status.In;

        emit AddToWhitelist(newElement);
    }

     
    function removeFromWhitelist(address elementToRemove) external onlyOwner {
        if (whitelist[elementToRemove] != Status.Out) {
            whitelist[elementToRemove] = Status.Out;
            emit RemoveFromWhitelist(elementToRemove);
        }
    }

     
    function isOnWhitelist(address elementToCheck) external view returns (bool) {
        return whitelist[elementToCheck] == Status.In;
    }

     
     
     
     
     
     
    function getWhitelist() external view returns (address[] memory activeWhitelist) {
         
        uint activeCount = 0;
        for (uint i = 0; i < whitelistIndices.length; i++) {
            if (whitelist[whitelistIndices[i]] == Status.In) {
                activeCount++;
            }
        }

         
        activeWhitelist = new address[](activeCount);
        activeCount = 0;
        for (uint i = 0; i < whitelistIndices.length; i++) {
            address addr = whitelistIndices[i];
            if (whitelist[addr] == Status.In) {
                activeWhitelist[activeCount] = addr;
                activeCount++;
            }
        }
    }

    event AddToWhitelist(address indexed addedAddress);
    event RemoveFromWhitelist(address indexed removedAddress);
}

contract Withdrawable is Ownable {
     
    function withdraw(uint amount) external onlyOwner {
        msg.sender.transfer(amount);
    }

     
    function withdrawErc20(address erc20Address, uint amount) external onlyOwner {
        IERC20 erc20 = IERC20(erc20Address);
        require(erc20.transfer(msg.sender, amount));
    }
}

 
interface OracleInterface {
     
     
     
     
    function requestPrice(bytes32 identifier, uint time) external returns (uint expectedTime);

     
    function hasPrice(bytes32 identifier, uint time) external view returns (bool hasPriceAvailable);

     
     
     
    function getPrice(bytes32 identifier, uint time) external view returns (int price);

     
    function isIdentifierSupported(bytes32 identifier) external view returns (bool isSupported);

     
    event VerifiedPriceRequested(bytes32 indexed identifier, uint indexed time);

     
    event VerifiedPriceAvailable(bytes32 indexed identifier, uint indexed time, int price);
}

interface RegistryInterface {
    struct RegisteredDerivative {
        address derivativeAddress;
        address derivativeCreator;
    }

     
    function registerDerivative(address[] calldata counterparties, address derivativeAddress) external;

     
     
    function addDerivativeCreator(address derivativeCreator) external;

     
     
    function removeDerivativeCreator(address derivativeCreator) external;

     
     
    function isDerivativeRegistered(address derivative) external view returns (bool isRegistered);

     
    function getRegisteredDerivatives(address party) external view returns (RegisteredDerivative[] memory derivatives);

     
    function getAllRegisteredDerivatives() external view returns (RegisteredDerivative[] memory derivatives);

     
    function isDerivativeCreatorAuthorized(address derivativeCreator) external view returns (bool isAuthorized);
}

contract Registry is RegistryInterface, Withdrawable {

    using SafeMath for uint;

     
    RegisteredDerivative[] private registeredDerivatives;

     
    enum PointerValidity {
        Invalid,
        Valid,
        WasValid
    }

    struct Pointer {
        PointerValidity valid;
        uint128 index;
    }

     
    mapping(address => Pointer) private derivativePointers;

     
     
     
    struct PartiesMap {
        mapping(address => bool) parties;
    }

     
    mapping(address => PartiesMap) private derivativesToParties;

     
    mapping(address => bool) private derivativeCreators;

    modifier onlyApprovedDerivativeCreator {
        require(derivativeCreators[msg.sender]);
        _;
    }

    function registerDerivative(address[] calldata parties, address derivativeAddress)
        external
        onlyApprovedDerivativeCreator
    {
         
        Pointer storage pointer = derivativePointers[derivativeAddress];

         
         
        require(pointer.valid == PointerValidity.Invalid);
        pointer.valid = PointerValidity.Valid;

        registeredDerivatives.push(RegisteredDerivative(derivativeAddress, msg.sender));

         
        pointer.index = uint128(registeredDerivatives.length.sub(1));

         
        PartiesMap storage partiesMap = derivativesToParties[derivativeAddress];
        for (uint i = 0; i < parties.length; i = i.add(1)) {
            partiesMap.parties[parties[i]] = true;
        }

        address[] memory partiesForEvent = parties;
        emit RegisterDerivative(derivativeAddress, partiesForEvent);
    }

    function addDerivativeCreator(address derivativeCreator) external onlyOwner {
        if (!derivativeCreators[derivativeCreator]) {
            derivativeCreators[derivativeCreator] = true;
            emit AddDerivativeCreator(derivativeCreator);
        }
    }

    function removeDerivativeCreator(address derivativeCreator) external onlyOwner {
        if (derivativeCreators[derivativeCreator]) {
            derivativeCreators[derivativeCreator] = false;
            emit RemoveDerivativeCreator(derivativeCreator);
        }
    }

    function isDerivativeRegistered(address derivative) external view returns (bool isRegistered) {
        return derivativePointers[derivative].valid == PointerValidity.Valid;
    }

    function getRegisteredDerivatives(address party) external view returns (RegisteredDerivative[] memory derivatives) {
         
         
         
         
         
        RegisteredDerivative[] memory tmpDerivativeArray = new RegisteredDerivative[](registeredDerivatives.length);
        uint outputIndex = 0;
        for (uint i = 0; i < registeredDerivatives.length; i = i.add(1)) {
            RegisteredDerivative storage derivative = registeredDerivatives[i];
            if (derivativesToParties[derivative.derivativeAddress].parties[party]) {
                 
                tmpDerivativeArray[outputIndex] = derivative;
                outputIndex = outputIndex.add(1);
            }
        }

         
        derivatives = new RegisteredDerivative[](outputIndex);
        for (uint j = 0; j < outputIndex; j = j.add(1)) {
            derivatives[j] = tmpDerivativeArray[j];
        }
    }

    function getAllRegisteredDerivatives() external view returns (RegisteredDerivative[] memory derivatives) {
        return registeredDerivatives;
    }

    function isDerivativeCreatorAuthorized(address derivativeCreator) external view returns (bool isAuthorized) {
        return derivativeCreators[derivativeCreator];
    }

    event RegisterDerivative(address indexed derivativeAddress, address[] parties);
    event AddDerivativeCreator(address indexed addedDerivativeCreator);
    event RemoveDerivativeCreator(address indexed removedDerivativeCreator);

}

contract Testable is Ownable {

     
     
    bool public isTest;

    uint private currentTime;

    constructor(bool _isTest) internal {
        isTest = _isTest;
        if (_isTest) {
            currentTime = now;  
        }
    }

    modifier onlyIfTest {
        require(isTest);
        _;
    }

    function setCurrentTime(uint _time) external onlyOwner onlyIfTest {
        currentTime = _time;
    }

    function getCurrentTime() public view returns (uint) {
        if (isTest) {
            return currentTime;
        } else {
            return now;  
        }
    }
}

contract ContractCreator is Withdrawable {
    Registry internal registry;
    address internal oracleAddress;
    address internal storeAddress;
    address internal priceFeedAddress;

    constructor(address registryAddress, address _oracleAddress, address _storeAddress, address _priceFeedAddress)
        public
    {
        registry = Registry(registryAddress);
        oracleAddress = _oracleAddress;
        storeAddress = _storeAddress;
        priceFeedAddress = _priceFeedAddress;
    }

    function _registerContract(address[] memory parties, address contractToRegister) internal {
        registry.registerDerivative(parties, contractToRegister);
    }
}

library TokenizedDerivativeParams {
    enum ReturnType {
        Linear,
        Compound
    }

    struct ConstructorParams {
        address sponsor;
        address admin;
        address oracle;
        address store;
        address priceFeed;
        uint defaultPenalty;  
        uint supportedMove;  
        bytes32 product;
        uint fixedYearlyFee;  
        uint disputeDeposit;  
        address returnCalculator;
        uint startingTokenPrice;
        uint expiry;
        address marginCurrency;
        uint withdrawLimit;  
        ReturnType returnType;
        uint startingUnderlyingPrice;
        uint creationTime;
    }
}

 
library TDS {
        enum State {
         
         
         
        Live,

         
         
         

         
         
         
         
        Disputed,

         
         
        Expired,

         
         
         
         
        Defaulted,

         
         
        Emergency,

         
         
         
        Settled
    }

     
    struct TokenState {
        int underlyingPrice;
        int tokenPrice;
        uint time;
    }

     
    struct Dispute {
        int disputedNav;
        uint deposit;
    }

    struct WithdrawThrottle {
        uint startTime;
        uint remainingWithdrawal;
    }

    struct FixedParameters {
         
        uint defaultPenalty;  
        uint supportedMove;  
        uint disputeDeposit;  
        uint fixedFeePerSecond;  
        uint withdrawLimit;  
        bytes32 product;
        TokenizedDerivativeParams.ReturnType returnType;
        uint initialTokenUnderlyingRatio;
        uint creationTime;
        string symbol;
    }

    struct ExternalAddresses {
         
        address sponsor;
        address admin;
        address apDelegate;
        OracleInterface oracle;
        StoreInterface store;
        PriceFeedInterface priceFeed;
        ReturnCalculatorInterface returnCalculator;
        IERC20 marginCurrency;
    }

    struct Storage {
        FixedParameters fixedParameters;
        ExternalAddresses externalAddresses;

         
        int shortBalance;
        int longBalance;

        State state;
        uint endTime;

         
         
         
         
        TokenState referenceTokenState;
        TokenState currentTokenState;

        int nav;   

        Dispute disputeInfo;

         
        int defaultPenaltyAmount;

        WithdrawThrottle withdrawThrottle;
    }
}

library TokenizedDerivativeUtils {
    using TokenizedDerivativeUtils for TDS.Storage;
    using SafeMath for uint;
    using SignedSafeMath for int;

    uint private constant SECONDS_PER_DAY = 86400;
    uint private constant SECONDS_PER_YEAR = 31536000;
    uint private constant INT_MAX = 2**255 - 1;
    uint private constant UINT_FP_SCALING_FACTOR = 10**18;
    int private constant INT_FP_SCALING_FACTOR = 10**18;

    modifier onlySponsor(TDS.Storage storage s) {
        require(msg.sender == s.externalAddresses.sponsor);
        _;
    }

    modifier onlyAdmin(TDS.Storage storage s) {
        require(msg.sender == s.externalAddresses.admin);
        _;
    }

    modifier onlySponsorOrAdmin(TDS.Storage storage s) {
        require(msg.sender == s.externalAddresses.sponsor || msg.sender == s.externalAddresses.admin);
        _;
    }

    modifier onlySponsorOrApDelegate(TDS.Storage storage s) {
        require(msg.sender == s.externalAddresses.sponsor || msg.sender == s.externalAddresses.apDelegate);
        _;
    }

     
     
     
    function _initialize(
        TDS.Storage storage s, TokenizedDerivativeParams.ConstructorParams memory params, string memory symbol) public {

        s._setFixedParameters(params, symbol);
        s._setExternalAddresses(params);
        
         
         
        require(params.startingTokenPrice >= UINT_FP_SCALING_FACTOR.div(10**9));
        require(params.startingTokenPrice <= UINT_FP_SCALING_FACTOR.mul(10**9));

         
        (uint latestTime, int latestUnderlyingPrice) = s.externalAddresses.priceFeed.latestPrice(s.fixedParameters.product);

         
        if (params.startingUnderlyingPrice != 0) {
            latestUnderlyingPrice = _safeIntCast(params.startingUnderlyingPrice);
        }

        require(latestUnderlyingPrice > 0);
        require(latestTime != 0);

         
        s.fixedParameters.initialTokenUnderlyingRatio = params.startingTokenPrice.mul(UINT_FP_SCALING_FACTOR).div(_safeUintCast(latestUnderlyingPrice));
        require(s.fixedParameters.initialTokenUnderlyingRatio != 0);

         
        if (params.expiry == 0) {
            s.endTime = ~uint(0);
        } else {
            require(params.expiry >= latestTime);
            s.endTime = params.expiry;
        }

        s.nav = s._computeInitialNav(latestUnderlyingPrice, latestTime, params.startingTokenPrice);

        s.state = TDS.State.Live;
    }

    function _depositAndCreateTokens(TDS.Storage storage s, uint marginForPurchase, uint tokensToPurchase) external onlySponsorOrApDelegate(s) {
        s._remarginInternal();

        int newTokenNav = _computeNavForTokens(s.currentTokenState.tokenPrice, tokensToPurchase);

        if (newTokenNav < 0) {
            newTokenNav = 0;
        }

        uint positiveTokenNav = _safeUintCast(newTokenNav);

         
         
        uint refund = s._pullSentMargin(marginForPurchase);

         
        uint depositAmount = marginForPurchase.sub(positiveTokenNav);

         
        s._depositInternal(depositAmount);

         
         
         
         
        refund = refund.add(s._createTokensInternal(tokensToPurchase, positiveTokenNav));

         
        s._sendMargin(refund);
    }

    function _redeemTokens(TDS.Storage storage s, uint tokensToRedeem) external {
        require(s.state == TDS.State.Live || s.state == TDS.State.Settled);
        require(tokensToRedeem > 0);

        if (s.state == TDS.State.Live) {
            require(msg.sender == s.externalAddresses.sponsor || msg.sender == s.externalAddresses.apDelegate);
            s._remarginInternal();
            require(s.state == TDS.State.Live);
        }

        ExpandedIERC20 thisErc20Token = ExpandedIERC20(address(this));

        uint initialSupply = _totalSupply();
        require(initialSupply > 0);

        _pullAuthorizedTokens(thisErc20Token, tokensToRedeem);
        thisErc20Token.burn(tokensToRedeem);
        emit TokensRedeemed(s.fixedParameters.symbol, tokensToRedeem);

         
         
        uint tokenPercentage = tokensToRedeem.mul(UINT_FP_SCALING_FACTOR).div(initialSupply);
        uint tokenMargin = _takePercentage(_safeUintCast(s.longBalance), tokenPercentage);

        s.longBalance = s.longBalance.sub(_safeIntCast(tokenMargin));
        assert(s.longBalance >= 0);
        s.nav = _computeNavForTokens(s.currentTokenState.tokenPrice, _totalSupply());

        s._sendMargin(tokenMargin);
    }

    function _dispute(TDS.Storage storage s, uint depositMargin) external onlySponsor(s) {
        require(
            s.state == TDS.State.Live,
            "Contract must be Live to dispute"
        );

        uint requiredDeposit = _safeUintCast(_takePercentage(s._getRequiredMargin(s.currentTokenState), s.fixedParameters.disputeDeposit));

        uint sendInconsistencyRefund = s._pullSentMargin(depositMargin);

        require(depositMargin >= requiredDeposit);
        uint overpaymentRefund = depositMargin.sub(requiredDeposit);

        s.state = TDS.State.Disputed;
        s.endTime = s.currentTokenState.time;
        s.disputeInfo.disputedNav = s.nav;
        s.disputeInfo.deposit = requiredDeposit;

         
        s.defaultPenaltyAmount = s._computeDefaultPenalty();
        emit Disputed(s.fixedParameters.symbol, s.endTime, s.nav);

        s._requestOraclePrice(s.endTime);

         
         
         
        s._sendMargin(sendInconsistencyRefund.add(overpaymentRefund));
    }

    function _withdraw(TDS.Storage storage s, uint amount) external onlySponsor(s) {
         
        if (s.state == TDS.State.Live) {
            s._remarginInternal();
        }

         
        require(s.state == TDS.State.Live || s.state == TDS.State.Settled);

         
         
         
         
        int withdrawableAmount;
        if (s.state == TDS.State.Settled) {
            withdrawableAmount = s.shortBalance;
        } else {
             
            uint currentTime = s.currentTokenState.time;
            if (s.withdrawThrottle.startTime <= currentTime.sub(SECONDS_PER_DAY)) {
                 
                s.withdrawThrottle.startTime = currentTime;
                s.withdrawThrottle.remainingWithdrawal = _takePercentage(_safeUintCast(s.shortBalance), s.fixedParameters.withdrawLimit);
            }

            int marginMaxWithdraw = s.shortBalance.sub(s._getRequiredMargin(s.currentTokenState));
            int throttleMaxWithdraw = _safeIntCast(s.withdrawThrottle.remainingWithdrawal);

             
            withdrawableAmount = throttleMaxWithdraw < marginMaxWithdraw ? throttleMaxWithdraw : marginMaxWithdraw;

             
             
            s.withdrawThrottle.remainingWithdrawal = s.withdrawThrottle.remainingWithdrawal.sub(amount);
        }

         
        require(
            withdrawableAmount >= _safeIntCast(amount),
            "Attempting to withdraw more than allowed"
        );

         
         
         
        s.shortBalance = s.shortBalance.sub(_safeIntCast(amount));
        emit Withdrawal(s.fixedParameters.symbol, amount);
        s._sendMargin(amount);
    }

    function _acceptPriceAndSettle(TDS.Storage storage s) external onlySponsor(s) {
         
        require(s.state == TDS.State.Defaulted);

         
        s._settleAgreedPrice();
    }

    function _setApDelegate(TDS.Storage storage s, address _apDelegate) external onlySponsor(s) {
        s.externalAddresses.apDelegate = _apDelegate;
    }

     
    function _emergencyShutdown(TDS.Storage storage s) external onlyAdmin(s) {
        require(s.state == TDS.State.Live);
        s.state = TDS.State.Emergency;
        s.endTime = s.currentTokenState.time;
        s.defaultPenaltyAmount = s._computeDefaultPenalty();
        emit EmergencyShutdownTransition(s.fixedParameters.symbol, s.endTime);
        s._requestOraclePrice(s.endTime);
    }

    function _settle(TDS.Storage storage s) external {
        s._settleInternal();
    }

    function _createTokens(TDS.Storage storage s, uint marginForPurchase, uint tokensToPurchase) external onlySponsorOrApDelegate(s) {
         
         
        uint refund = s._pullSentMargin(marginForPurchase);

         
         
        refund = refund.add(s._createTokensInternal(tokensToPurchase, marginForPurchase));

         
        s._sendMargin(refund);
    }

    function _deposit(TDS.Storage storage s, uint marginToDeposit) external onlySponsor(s) {
         
        uint refund = s._pullSentMargin(marginToDeposit);
        s._depositInternal(marginToDeposit);

         
         
        s._sendMargin(refund);
    }

     
    function _calcNAV(TDS.Storage storage s) external view returns (int navNew) {
        (TDS.TokenState memory newTokenState, ) = s._calcNewTokenStateAndBalance();
        navNew = _computeNavForTokens(newTokenState.tokenPrice, _totalSupply());
    }

     
     
    function _calcTokenValue(TDS.Storage storage s) external view returns (int newTokenValue) {
        (TDS.TokenState memory newTokenState,) = s._calcNewTokenStateAndBalance();
        newTokenValue = newTokenState.tokenPrice;
    }

     
    function _calcShortMarginBalance(TDS.Storage storage s) external view returns (int newShortMarginBalance) {
        (, newShortMarginBalance) = s._calcNewTokenStateAndBalance();
    }

    function _calcExcessMargin(TDS.Storage storage s) external view returns (int newExcessMargin) {
        (TDS.TokenState memory newTokenState, int newShortMarginBalance) = s._calcNewTokenStateAndBalance();
         
        int requiredMargin = newTokenState.time >= s.endTime ? 0 : s._getRequiredMargin(newTokenState);
        return newShortMarginBalance.sub(requiredMargin);
    }

    function _getCurrentRequiredMargin(TDS.Storage storage s) external view returns (int requiredMargin) {
        if (s.state == TDS.State.Settled) {
             
            return 0;
        }

         return s._getRequiredMargin(s.currentTokenState);
    }

    function _canBeSettled(TDS.Storage storage s) external view returns (bool canBeSettled) {
        TDS.State currentState = s.state;

        if (currentState == TDS.State.Settled) {
            return false;
        }

         
         
        (uint priceFeedTime, ) = s._getLatestPrice();
        if (currentState == TDS.State.Live && (priceFeedTime < s.endTime)) {
            return false;
        }

        return s.externalAddresses.oracle.hasPrice(s.fixedParameters.product, s.endTime);
    }

    function _getUpdatedUnderlyingPrice(TDS.Storage storage s) external view returns (int underlyingPrice, uint time) {
        (TDS.TokenState memory newTokenState, ) = s._calcNewTokenStateAndBalance();
        return (newTokenState.underlyingPrice, newTokenState.time);
    }

    function _calcNewTokenStateAndBalance(TDS.Storage storage s) internal view returns (TDS.TokenState memory newTokenState, int newShortMarginBalance)
    {
         
         
         
         

        if (s.state == TDS.State.Settled) {
             
            return (s.currentTokenState, s.shortBalance);
        }

         
        (uint priceFeedTime, int priceFeedPrice) = s._getLatestPrice();

        bool isContractLive = s.state == TDS.State.Live;
        bool isContractPostExpiry = priceFeedTime >= s.endTime;

         
        if (isContractLive && priceFeedTime <= s.currentTokenState.time) {
            return (s.currentTokenState, s.shortBalance);
        }

         
         
         
        bool shouldUseReferenceTokenState = isContractLive &&
            (s.fixedParameters.returnType == TokenizedDerivativeParams.ReturnType.Linear || isContractPostExpiry);
        TDS.TokenState memory lastTokenState = shouldUseReferenceTokenState ? s.referenceTokenState : s.currentTokenState;

         
        (uint recomputeTime, int recomputePrice) = !isContractLive || isContractPostExpiry ?
            (s.endTime, s.externalAddresses.oracle.getPrice(s.fixedParameters.product, s.endTime)) :
            (priceFeedTime, priceFeedPrice);

         
        newShortMarginBalance = s.shortBalance;

         
        newShortMarginBalance = isContractLive ?
            newShortMarginBalance.sub(
                _safeIntCast(s._computeExpectedOracleFees(s.currentTokenState.time, recomputeTime))) :
            newShortMarginBalance;

         
        newTokenState = s._computeNewTokenState(lastTokenState, recomputePrice, recomputeTime);
        int navNew = _computeNavForTokens(newTokenState.tokenPrice, _totalSupply());
        newShortMarginBalance = newShortMarginBalance.sub(_getLongDiff(navNew, s.longBalance, newShortMarginBalance));

         
         
        if (!isContractLive || isContractPostExpiry) {
             
            bool inDefault = !s._satisfiesMarginRequirement(newShortMarginBalance, newTokenState);
            if (inDefault) {
                int expectedDefaultPenalty = isContractLive ? s._computeDefaultPenalty() : s._getDefaultPenalty();
                int defaultPenalty = (newShortMarginBalance < expectedDefaultPenalty) ?
                    newShortMarginBalance :
                    expectedDefaultPenalty;
                newShortMarginBalance = newShortMarginBalance.sub(defaultPenalty);
            }

             
            if (s.state == TDS.State.Disputed && navNew != s.disputeInfo.disputedNav) {
                int depositValue = _safeIntCast(s.disputeInfo.deposit);
                newShortMarginBalance = newShortMarginBalance.add(depositValue);
            }
        }
    }

    function _computeInitialNav(TDS.Storage storage s, int latestUnderlyingPrice, uint latestTime, uint startingTokenPrice)
        internal
        returns (int navNew)
    {
        int unitNav = _safeIntCast(startingTokenPrice);
        s.referenceTokenState = TDS.TokenState(latestUnderlyingPrice, unitNav, latestTime);
        s.currentTokenState = TDS.TokenState(latestUnderlyingPrice, unitNav, latestTime);
         
        navNew = 0;
    }

    function _remargin(TDS.Storage storage s) external onlySponsorOrAdmin(s) {
        s._remarginInternal();
    }

    function _withdrawUnexpectedErc20(TDS.Storage storage s, address erc20Address, uint amount) external onlySponsor(s) {
        if(address(s.externalAddresses.marginCurrency) == erc20Address) {
            uint currentBalance = s.externalAddresses.marginCurrency.balanceOf(address(this));
            int totalBalances = s.shortBalance.add(s.longBalance);
            assert(totalBalances >= 0);
            uint withdrawableAmount = currentBalance.sub(_safeUintCast(totalBalances)).sub(s.disputeInfo.deposit);
            require(withdrawableAmount >= amount);
        }

        IERC20 erc20 = IERC20(erc20Address);
        require(erc20.transfer(msg.sender, amount));
    }

    function _setExternalAddresses(TDS.Storage storage s, TokenizedDerivativeParams.ConstructorParams memory params) internal {

         
         
         
         
        s.externalAddresses.marginCurrency = IERC20(params.marginCurrency);

        s.externalAddresses.oracle = OracleInterface(params.oracle);
        s.externalAddresses.store = StoreInterface(params.store);
        s.externalAddresses.priceFeed = PriceFeedInterface(params.priceFeed);
        s.externalAddresses.returnCalculator = ReturnCalculatorInterface(params.returnCalculator);

         
        require(s.externalAddresses.oracle.isIdentifierSupported(params.product));
        require(s.externalAddresses.priceFeed.isIdentifierSupported(params.product));

        s.externalAddresses.sponsor = params.sponsor;
        s.externalAddresses.admin = params.admin;
    }

    function _setFixedParameters(TDS.Storage storage s, TokenizedDerivativeParams.ConstructorParams memory params, string memory symbol) internal {
         
        require(params.returnType == TokenizedDerivativeParams.ReturnType.Compound
            || params.returnType == TokenizedDerivativeParams.ReturnType.Linear);

         
        require(params.returnType == TokenizedDerivativeParams.ReturnType.Compound || params.fixedYearlyFee == 0);

         
        require(params.defaultPenalty <= UINT_FP_SCALING_FACTOR);

        s.fixedParameters.returnType = params.returnType;
        s.fixedParameters.defaultPenalty = params.defaultPenalty;
        s.fixedParameters.product = params.product;
        s.fixedParameters.fixedFeePerSecond = params.fixedYearlyFee.div(SECONDS_PER_YEAR);
        s.fixedParameters.disputeDeposit = params.disputeDeposit;
        s.fixedParameters.supportedMove = params.supportedMove;
        s.fixedParameters.withdrawLimit = params.withdrawLimit;
        s.fixedParameters.creationTime = params.creationTime;
        s.fixedParameters.symbol = symbol;
    }

     
     
    function _remarginInternal(TDS.Storage storage s) internal {
         
        require(s.state == TDS.State.Live);

        (uint latestTime, int latestPrice) = s._getLatestPrice();
         
        if (latestTime <= s.currentTokenState.time) {
             
            return;
        }

         
        int potentialPenaltyAmount = s._computeDefaultPenalty();

        if (latestTime >= s.endTime) {
            s.state = TDS.State.Expired;
            emit Expired(s.fixedParameters.symbol, s.endTime);

             
            int recomputedNav = s._computeNav(s.currentTokenState.underlyingPrice, s.currentTokenState.time);
            assert(recomputedNav == s.nav);

            uint feeAmount = s._deductOracleFees(s.currentTokenState.time, s.endTime);

             
            s.defaultPenaltyAmount = potentialPenaltyAmount;

             
             
            s._requestOraclePrice(s.endTime);
            s._payOracleFees(feeAmount);
            return;
        }
        uint feeAmount = s._deductOracleFees(s.currentTokenState.time, latestTime);

         
        int navNew = s._computeNav(latestPrice, latestTime);

         
        s._updateBalances(navNew);

         
        bool inDefault = !s._satisfiesMarginRequirement(s.shortBalance, s.currentTokenState);
        if (inDefault) {
            s.state = TDS.State.Defaulted;
            s.defaultPenaltyAmount = potentialPenaltyAmount;
            s.endTime = latestTime;  
            emit Default(s.fixedParameters.symbol, latestTime, s.nav);
            s._requestOraclePrice(latestTime);
        }

        s._payOracleFees(feeAmount);
    }

    function _createTokensInternal(TDS.Storage storage s, uint tokensToPurchase, uint navSent) internal returns (uint refund) {
        s._remarginInternal();

         
        require(s.state == TDS.State.Live);

        int purchasedNav = _computeNavForTokens(s.currentTokenState.tokenPrice, tokensToPurchase);

        if (purchasedNav < 0) {
            purchasedNav = 0;
        }

         
        refund = navSent.sub(_safeUintCast(purchasedNav));

        s.longBalance = s.longBalance.add(purchasedNav);

        ExpandedIERC20 thisErc20Token = ExpandedIERC20(address(this));

        thisErc20Token.mint(msg.sender, tokensToPurchase);
        emit TokensCreated(s.fixedParameters.symbol, tokensToPurchase);

        s.nav = _computeNavForTokens(s.currentTokenState.tokenPrice, _totalSupply());

         
        require(s._satisfiesMarginRequirement(s.shortBalance, s.currentTokenState));
    }

    function _depositInternal(TDS.Storage storage s, uint value) internal {
         
        require(s.state == TDS.State.Live);
        s.shortBalance = s.shortBalance.add(_safeIntCast(value));
        emit Deposited(s.fixedParameters.symbol, value);
    }

    function _settleInternal(TDS.Storage storage s) internal {
        TDS.State startingState = s.state;
        require(startingState == TDS.State.Disputed || startingState == TDS.State.Expired
                || startingState == TDS.State.Defaulted || startingState == TDS.State.Emergency);
        s._settleVerifiedPrice();
        if (startingState == TDS.State.Disputed) {
            int depositValue = _safeIntCast(s.disputeInfo.deposit);
            if (s.nav != s.disputeInfo.disputedNav) {
                s.shortBalance = s.shortBalance.add(depositValue);
            } else {
                s.longBalance = s.longBalance.add(depositValue);
            }
        }
    }

     
    function _deductOracleFees(TDS.Storage storage s, uint lastTimeOracleFeesPaid, uint currentTime) internal returns (uint feeAmount) {
        feeAmount = s._computeExpectedOracleFees(lastTimeOracleFeesPaid, currentTime);
        s.shortBalance = s.shortBalance.sub(_safeIntCast(feeAmount));
         
         
    }

     
    function _payOracleFees(TDS.Storage storage s, uint feeAmount) internal {
        if (feeAmount == 0) {
            return;
        }

        if (address(s.externalAddresses.marginCurrency) == address(0x0)) {
            s.externalAddresses.store.payOracleFees.value(feeAmount)();
        } else {
            require(s.externalAddresses.marginCurrency.approve(address(s.externalAddresses.store), feeAmount));
            s.externalAddresses.store.payOracleFeesErc20(address(s.externalAddresses.marginCurrency));
        }
    }

    function _computeExpectedOracleFees(TDS.Storage storage s, uint lastTimeOracleFeesPaid, uint currentTime)
        internal
        view
        returns (uint feeAmount)
    {
         
        int pfc = s.shortBalance < s.longBalance ? s.longBalance : s.shortBalance;
        uint expectedFeeAmount = s.externalAddresses.store.computeOracleFees(lastTimeOracleFeesPaid, currentTime, _safeUintCast(pfc));

         
        uint shortBalance = _safeUintCast(s.shortBalance);
        return (shortBalance < expectedFeeAmount) ? shortBalance : expectedFeeAmount;
    }

    function _computeNewTokenState(TDS.Storage storage s,
        TDS.TokenState memory beginningTokenState, int latestUnderlyingPrice, uint recomputeTime)
        internal
        view
        returns (TDS.TokenState memory newTokenState)
    {
        int underlyingReturn = s.externalAddresses.returnCalculator.computeReturn(
            beginningTokenState.underlyingPrice, latestUnderlyingPrice);
        int tokenReturn = underlyingReturn.sub(
            _safeIntCast(s.fixedParameters.fixedFeePerSecond.mul(recomputeTime.sub(beginningTokenState.time))));
        int tokenMultiplier = tokenReturn.add(INT_FP_SCALING_FACTOR);
        
         
        if (s.fixedParameters.returnType == TokenizedDerivativeParams.ReturnType.Compound && tokenMultiplier < 0) {
            tokenMultiplier = 0;
        }

        int newTokenPrice = _takePercentage(beginningTokenState.tokenPrice, tokenMultiplier);
        newTokenState = TDS.TokenState(latestUnderlyingPrice, newTokenPrice, recomputeTime);
    }

    function _satisfiesMarginRequirement(TDS.Storage storage s, int balance, TDS.TokenState memory tokenState)
        internal
        view
        returns (bool doesSatisfyRequirement) 
    {
        return s._getRequiredMargin(tokenState) <= balance;
    }

    function _requestOraclePrice(TDS.Storage storage s, uint requestedTime) internal {
        uint expectedTime = s.externalAddresses.oracle.requestPrice(s.fixedParameters.product, requestedTime);
        if (expectedTime == 0) {
             
            s._settleInternal();
        }
    }

    function _getLatestPrice(TDS.Storage storage s) internal view returns (uint latestTime, int latestUnderlyingPrice) {
        (latestTime, latestUnderlyingPrice) = s.externalAddresses.priceFeed.latestPrice(s.fixedParameters.product);
        require(latestTime != 0);
    }

    function _computeNav(TDS.Storage storage s, int latestUnderlyingPrice, uint latestTime) internal returns (int navNew) {
        if (s.fixedParameters.returnType == TokenizedDerivativeParams.ReturnType.Compound) {
            navNew = s._computeCompoundNav(latestUnderlyingPrice, latestTime);
        } else {
            assert(s.fixedParameters.returnType == TokenizedDerivativeParams.ReturnType.Linear);
            navNew = s._computeLinearNav(latestUnderlyingPrice, latestTime);
        }
    }

    function _computeCompoundNav(TDS.Storage storage s, int latestUnderlyingPrice, uint latestTime) internal returns (int navNew) {
        s.referenceTokenState = s.currentTokenState;
        s.currentTokenState = s._computeNewTokenState(s.currentTokenState, latestUnderlyingPrice, latestTime);
        navNew = _computeNavForTokens(s.currentTokenState.tokenPrice, _totalSupply());
        emit NavUpdated(s.fixedParameters.symbol, navNew, s.currentTokenState.tokenPrice);
    }

    function _computeLinearNav(TDS.Storage storage s, int latestUnderlyingPrice, uint latestTime) internal returns (int navNew) {
         
        s.referenceTokenState.time = s.currentTokenState.time;
        s.currentTokenState = s._computeNewTokenState(s.referenceTokenState, latestUnderlyingPrice, latestTime);
        navNew = _computeNavForTokens(s.currentTokenState.tokenPrice, _totalSupply());
        emit NavUpdated(s.fixedParameters.symbol, navNew, s.currentTokenState.tokenPrice);
    }

    function _recomputeNav(TDS.Storage storage s, int oraclePrice, uint recomputeTime) internal returns (int navNew) {
         
        assert(s.endTime == recomputeTime);
        s.currentTokenState = s._computeNewTokenState(s.referenceTokenState, oraclePrice, recomputeTime);
        navNew = _computeNavForTokens(s.currentTokenState.tokenPrice, _totalSupply());
        emit NavUpdated(s.fixedParameters.symbol, navNew, s.currentTokenState.tokenPrice);
    }

     
     
    function _settleWithPrice(TDS.Storage storage s, int price) internal {

         
        s._updateBalances(s._recomputeNav(price, s.endTime));

        bool inDefault = !s._satisfiesMarginRequirement(s.shortBalance, s.currentTokenState);

        if (inDefault) {
            int expectedDefaultPenalty = s._getDefaultPenalty();
            int penalty = (s.shortBalance < expectedDefaultPenalty) ?
                s.shortBalance :
                expectedDefaultPenalty;

            s.shortBalance = s.shortBalance.sub(penalty);
            s.longBalance = s.longBalance.add(penalty);
        }

        s.state = TDS.State.Settled;
        emit Settled(s.fixedParameters.symbol, s.endTime, s.nav);
    }

    function _updateBalances(TDS.Storage storage s, int navNew) internal {
         
         
        int longDiff = _getLongDiff(navNew, s.longBalance, s.shortBalance);
        s.nav = navNew;

        s.longBalance = s.longBalance.add(longDiff);
        s.shortBalance = s.shortBalance.sub(longDiff);
    }

    function _getDefaultPenalty(TDS.Storage storage s) internal view returns (int penalty) {
        return s.defaultPenaltyAmount;
    }

    function _computeDefaultPenalty(TDS.Storage storage s) internal view returns (int penalty) {
        return _takePercentage(s._getRequiredMargin(s.currentTokenState), s.fixedParameters.defaultPenalty);
    }

    function _getRequiredMargin(TDS.Storage storage s, TDS.TokenState memory tokenState)
        internal
        view
        returns (int requiredMargin)
    {
        int leverageMagnitude = _absoluteValue(s.externalAddresses.returnCalculator.leverage());

        int effectiveNotional;
        if (s.fixedParameters.returnType == TokenizedDerivativeParams.ReturnType.Linear) {
            int effectiveUnitsOfUnderlying = _safeIntCast(_totalSupply().mul(s.fixedParameters.initialTokenUnderlyingRatio).div(UINT_FP_SCALING_FACTOR)).mul(leverageMagnitude);
            effectiveNotional = effectiveUnitsOfUnderlying.mul(tokenState.underlyingPrice).div(INT_FP_SCALING_FACTOR);
        } else {
            int currentNav = _computeNavForTokens(tokenState.tokenPrice, _totalSupply());
            effectiveNotional = currentNav.mul(leverageMagnitude);
        }

         
         
        requiredMargin = _takePercentage(_absoluteValue(effectiveNotional), s.fixedParameters.supportedMove);
    }

    function _pullSentMargin(TDS.Storage storage s, uint expectedMargin) internal returns (uint refund) {
        if (address(s.externalAddresses.marginCurrency) == address(0x0)) {
             
             
            return msg.value.sub(expectedMargin);
        } else {
             
            require(msg.value == 0);
            _pullAuthorizedTokens(s.externalAddresses.marginCurrency, expectedMargin);

             
            return 0;
        }
    }

    function _sendMargin(TDS.Storage storage s, uint amount) internal {
         
        if (amount == 0) {
            return;
        }

        if (address(s.externalAddresses.marginCurrency) == address(0x0)) {
            msg.sender.transfer(amount);
        } else {
            require(s.externalAddresses.marginCurrency.transfer(msg.sender, amount));
        }
    }

    function _settleAgreedPrice(TDS.Storage storage s) internal {
        int agreedPrice = s.currentTokenState.underlyingPrice;

        s._settleWithPrice(agreedPrice);
    }

    function _settleVerifiedPrice(TDS.Storage storage s) internal {
        int oraclePrice = s.externalAddresses.oracle.getPrice(s.fixedParameters.product, s.endTime);
        s._settleWithPrice(oraclePrice);
    }

    function _pullAuthorizedTokens(IERC20 erc20, uint amountToPull) private {
         
        if (amountToPull > 0) {
            require(erc20.transferFrom(msg.sender, address(this), amountToPull));
        }
    }

     
     
    function _getLongDiff(int navNew, int longBalance, int shortBalance) private pure returns (int longDiff) {
        int newLongBalance = navNew;

         
        if (newLongBalance < 0) {
            newLongBalance = 0;
        }

        longDiff = newLongBalance.sub(longBalance);

         
        if (longDiff > shortBalance) {
            longDiff = shortBalance;
        }
    }

    function _computeNavForTokens(int tokenPrice, uint numTokens) private pure returns (int navNew) {
        int navPreDivision = _safeIntCast(numTokens).mul(tokenPrice);
        navNew = navPreDivision.div(INT_FP_SCALING_FACTOR);

         
         
        if ((navPreDivision % INT_FP_SCALING_FACTOR) != 0) {
            navNew = navNew.add(1);
        }
    }

    function _totalSupply() private view returns (uint totalSupply) {
        ExpandedIERC20 thisErc20Token = ExpandedIERC20(address(this));
        return thisErc20Token.totalSupply();
    }

    function _takePercentage(uint value, uint percentage) private pure returns (uint result) {
        return value.mul(percentage).div(UINT_FP_SCALING_FACTOR);
    }

    function _takePercentage(int value, uint percentage) private pure returns (int result) {
        return value.mul(_safeIntCast(percentage)).div(INT_FP_SCALING_FACTOR);
    }

    function _takePercentage(int value, int percentage) private pure returns (int result) {
        return value.mul(percentage).div(INT_FP_SCALING_FACTOR);
    }

    function _absoluteValue(int value) private pure returns (int result) {
        return value < 0 ? value.mul(-1) : value;
    }

    function _safeIntCast(uint value) private pure returns (int result) {
        require(value <= INT_MAX);
        return int(value);
    }

    function _safeUintCast(int value) private pure returns (uint result) {
        require(value >= 0);
        return uint(value);
    }

     
     
     
    event NavUpdated(string symbol, int newNav, int newTokenPrice);
     
    event Default(string symbol, uint defaultTime, int defaultNav);
     
    event Settled(string symbol, uint settleTime, int finalNav);
     
    event Expired(string symbol, uint expiryTime);
     
    event Disputed(string symbol, uint timeDisputed, int navDisputed);
     
    event EmergencyShutdownTransition(string symbol, uint shutdownTime);
     
    event TokensCreated(string symbol, uint numTokensCreated);
     
    event TokensRedeemed(string symbol, uint numTokensRedeemed);
     
    event Deposited(string symbol, uint amount);
     
    event Withdrawal(string symbol, uint amount);
}

 
contract TokenizedDerivative is ERC20, AdminInterface, ExpandedIERC20 {
    using TokenizedDerivativeUtils for TDS.Storage;

     
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;  

    TDS.Storage public derivativeStorage;

    constructor(
        TokenizedDerivativeParams.ConstructorParams memory params,
        string memory _name,
        string memory _symbol
    ) public {
         
        name = _name;
        symbol = _symbol;

         
        derivativeStorage._initialize(params, _symbol);
    }

     
    function createTokens(uint marginForPurchase, uint tokensToPurchase) external payable {
        derivativeStorage._createTokens(marginForPurchase, tokensToPurchase);
    }

     
    function depositAndCreateTokens(uint marginForPurchase, uint tokensToPurchase) external payable {
        derivativeStorage._depositAndCreateTokens(marginForPurchase, tokensToPurchase);
    }

     
    function redeemTokens(uint tokensToRedeem) external {
        derivativeStorage._redeemTokens(tokensToRedeem);
    }

     
    function dispute(uint depositMargin) external payable {
        derivativeStorage._dispute(depositMargin);
    }

     
    function withdraw(uint amount) external {
        derivativeStorage._withdraw(amount);
    }

     
     
    function remargin() external {
        derivativeStorage._remargin();
    }

     
     
     
    function acceptPriceAndSettle() external {
        derivativeStorage._acceptPriceAndSettle();
    }

     
     
    function setApDelegate(address apDelegate) external {
        derivativeStorage._setApDelegate(apDelegate);
    }

     
    function emergencyShutdown() external {
        derivativeStorage._emergencyShutdown();
    }

     
    function calcNAV() external view returns (int navNew) {
        return derivativeStorage._calcNAV();
    }

     
     
    function calcTokenValue() external view returns (int newTokenValue) {
        return derivativeStorage._calcTokenValue();
    }

     
    function calcShortMarginBalance() external view returns (int newShortMarginBalance) {
        return derivativeStorage._calcShortMarginBalance();
    }

     
     
    function calcExcessMargin() external view returns (int excessMargin) {
        return derivativeStorage._calcExcessMargin();
    }

     
     
    function getCurrentRequiredMargin() external view returns (int requiredMargin) {
        return derivativeStorage._getCurrentRequiredMargin();
    }

     
    function canBeSettled() external view returns (bool canContractBeSettled) {
        return derivativeStorage._canBeSettled();
    }

     
     
     
    function getUpdatedUnderlyingPrice() external view returns (int underlyingPrice, uint time) {
        return derivativeStorage._getUpdatedUnderlyingPrice();
    }

     
     
    function settle() external {
        derivativeStorage._settle();
    }

     
     
    function deposit(uint amountToDeposit) external payable {
        derivativeStorage._deposit(amountToDeposit);
    }

     
    function withdrawUnexpectedErc20(address erc20Address, uint amount) external {
        derivativeStorage._withdrawUnexpectedErc20(erc20Address, amount);
    }

     
    modifier onlyThis {
        require(msg.sender == address(this));
        _;
    }

     
    function burn(uint value) external onlyThis {
         
        _burn(msg.sender, value);
    }

     
    function mint(address to, uint256 value) external onlyThis {
        _mint(to, value);
    }

     
     
    event NavUpdated(string symbol, int newNav, int newTokenPrice);
    event Default(string symbol, uint defaultTime, int defaultNav);
    event Settled(string symbol, uint settleTime, int finalNav);
    event Expired(string symbol, uint expiryTime);
    event Disputed(string symbol, uint timeDisputed, int navDisputed);
    event EmergencyShutdownTransition(string symbol, uint shutdownTime);
    event TokensCreated(string symbol, uint numTokensCreated);
    event TokensRedeemed(string symbol, uint numTokensRedeemed);
    event Deposited(string symbol, uint amount);
    event Withdrawal(string symbol, uint amount);
}

contract TokenizedDerivativeCreator is ContractCreator, Testable {
    struct Params {
        uint defaultPenalty;  
        uint supportedMove;  
        bytes32 product;
        uint fixedYearlyFee;  
        uint disputeDeposit;  
        address returnCalculator;
        uint startingTokenPrice;
        uint expiry;
        address marginCurrency;
        uint withdrawLimit;  
        TokenizedDerivativeParams.ReturnType returnType;
        uint startingUnderlyingPrice;
        string name;
        string symbol;
    }

    AddressWhitelist public sponsorWhitelist;
    AddressWhitelist public returnCalculatorWhitelist;
    AddressWhitelist public marginCurrencyWhitelist;

    constructor(
        address registryAddress,
        address _oracleAddress,
        address _storeAddress,
        address _priceFeedAddress,
        address _sponsorWhitelist,
        address _returnCalculatorWhitelist,
        address _marginCurrencyWhitelist,
        bool _isTest
    )
        public
        ContractCreator(registryAddress, _oracleAddress, _storeAddress, _priceFeedAddress)
        Testable(_isTest)
    {
        sponsorWhitelist = AddressWhitelist(_sponsorWhitelist);
        returnCalculatorWhitelist = AddressWhitelist(_returnCalculatorWhitelist);
        marginCurrencyWhitelist = AddressWhitelist(_marginCurrencyWhitelist);
    }

    function createTokenizedDerivative(Params memory params)
        public
        returns (address derivativeAddress)
    {
        TokenizedDerivative derivative = new TokenizedDerivative(_convertParams(params), params.name, params.symbol);

        address[] memory parties = new address[](1);
        parties[0] = msg.sender;

        _registerContract(parties, address(derivative));

        return address(derivative);
    }

     
    function _convertParams(Params memory params)
        private
        view
        returns (TokenizedDerivativeParams.ConstructorParams memory constructorParams)
    {
         
        require(sponsorWhitelist.isOnWhitelist(msg.sender));
        constructorParams.sponsor = msg.sender;

        require(returnCalculatorWhitelist.isOnWhitelist(params.returnCalculator));
        constructorParams.returnCalculator = params.returnCalculator;

        require(marginCurrencyWhitelist.isOnWhitelist(params.marginCurrency));
        constructorParams.marginCurrency = params.marginCurrency;

        constructorParams.defaultPenalty = params.defaultPenalty;
        constructorParams.supportedMove = params.supportedMove;
        constructorParams.product = params.product;
        constructorParams.fixedYearlyFee = params.fixedYearlyFee;
        constructorParams.disputeDeposit = params.disputeDeposit;
        constructorParams.startingTokenPrice = params.startingTokenPrice;
        constructorParams.expiry = params.expiry;
        constructorParams.withdrawLimit = params.withdrawLimit;
        constructorParams.returnType = params.returnType;
        constructorParams.startingUnderlyingPrice = params.startingUnderlyingPrice;

         
        constructorParams.priceFeed = priceFeedAddress;
        constructorParams.oracle = oracleAddress;
        constructorParams.store = storeAddress;
        constructorParams.admin = oracleAddress;
        constructorParams.creationTime = getCurrentTime();
    }
}