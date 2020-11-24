 

pragma solidity ^0.4.21;

 

interface ISimpleCrowdsale {
    function getSoftCap() external view returns(uint256);
    function isContributorInLists(address contributorAddress) external view returns(bool);
    function processReservationFundContribution(
        address contributor,
        uint256 tokenAmount,
        uint256 tokenBonusAmount
    ) external payable;
}

 

 
contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address previousOwner, address newOwner);

     
    function Ownable(address _owner) public {
        owner = _owner == address(0) ? msg.sender : _owner;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function confirmOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

 

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

 

 
interface ICrowdsaleFund {
     
    function processContribution(address contributor) external payable;
     
    function onCrowdsaleEnd() external;
     
    function enableCrowdsaleRefund() external;
}

 

 
interface ICrowdsaleReservationFund {
     
    function canCompleteContribution(address contributor) external returns(bool);
     
    function completeContribution(address contributor) external;
     
    function processContribution(address contributor, uint256 _tokensToIssue, uint256 _bonusTokensToIssue) external payable;

     
    function contributionsOf(address contributor) external returns(uint256);

     
    function onCrowdsaleEnd() external;
}

 

 
contract IERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value)  public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool success);
    function approve(address _spender, uint256 _value)  public returns (bool success);
    function allowance(address _owner, address _spender)  public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

 
contract SafeMath {
     
    function SafeMath() public {
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 

 
contract LockedTokensTest is SafeMath {
    struct Tokens {
        uint256 amount;
        uint256 lockEndTime;
        bool released;
    }

    event TokensUnlocked(address _to, uint256 _value);

    IERC20Token public token;
    address public crowdsaleAddress;
    mapping(address => Tokens[]) public walletTokens;

     
    function LockedTokensTest(IERC20Token _token, address _crowdsaleAddress) public {
        token = _token;
        crowdsaleAddress = _crowdsaleAddress;
    }

     
    function addTokens(address _to, uint256 _amount, uint256 _lockEndTime) external {
        require(msg.sender == crowdsaleAddress);
        walletTokens[_to].push(Tokens({amount: _amount, lockEndTime: _lockEndTime, released: false}));
    }

     
    function releaseTokens() public {
        require(walletTokens[msg.sender].length > 0);

        for(uint256 i = 0; i < walletTokens[msg.sender].length; i++) {
            if(!walletTokens[msg.sender][i].released && now >= walletTokens[msg.sender][i].lockEndTime) {
                walletTokens[msg.sender][i].released = true;
                token.transfer(msg.sender, walletTokens[msg.sender][i].amount);
                TokensUnlocked(msg.sender, walletTokens[msg.sender][i].amount);
            }
        }
    }
}

 

 
contract MultiOwnable {
    address public manager;  
    address[] public owners;
    mapping(address => bool) public ownerByAddress;

    event SetOwners(address[] owners);

    modifier onlyOwner() {
        require(ownerByAddress[msg.sender] == true);
        _;
    }

     
    function MultiOwnable() public {
        manager = msg.sender;
    }

     
    function setOwners(address[] _owners) public {
        require(msg.sender == manager);
        _setOwners(_owners);

    }

    function _setOwners(address[] _owners) internal {
        for(uint256 i = 0; i < owners.length; i++) {
            ownerByAddress[owners[i]] = false;
        }


        for(uint256 j = 0; j < _owners.length; j++) {
            ownerByAddress[_owners[j]] = true;
        }
        owners = _owners;
        SetOwners(_owners);
    }

    function getOwners() public constant returns (address[]) {
        return owners;
    }
}

 

 
contract ERC20Token is IERC20Token, SafeMath {
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);

        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);

        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256) {
      return allowed[_owner][_spender];
    }
}

 

 
interface ITokenEventListener {
     
    function onTokenTransfer(address _from, address _to, uint256 _value) external;
}

 

 
contract ManagedToken is ERC20Token, MultiOwnable {
    bool public allowTransfers = false;
    bool public issuanceFinished = false;

    ITokenEventListener public eventListener;

    event AllowTransfersChanged(bool _newState);
    event Issue(address indexed _to, uint256 _value);
    event Destroy(address indexed _from, uint256 _value);
    event IssuanceFinished();

    modifier transfersAllowed() {
        require(allowTransfers);
        _;
    }

    modifier canIssue() {
        require(!issuanceFinished);
        _;
    }

     
    function ManagedToken(address _listener, address[] _owners) public {
        if(_listener != address(0)) {
            eventListener = ITokenEventListener(_listener);
        }
        _setOwners(_owners);
    }

     
    function setAllowTransfers(bool _allowTransfers) external onlyOwner {
        allowTransfers = _allowTransfers;
        AllowTransfersChanged(_allowTransfers);
    }

     
    function setListener(address _listener) public onlyOwner {
        if(_listener != address(0)) {
            eventListener = ITokenEventListener(_listener);
        } else {
            delete eventListener;
        }
    }

    function transfer(address _to, uint256 _value) public transfersAllowed returns (bool) {
        bool success = super.transfer(_to, _value);
        if(hasListener() && success) {
            eventListener.onTokenTransfer(msg.sender, _to, _value);
        }
        return success;
    }

    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed returns (bool) {
        bool success = super.transferFrom(_from, _to, _value);
        if(hasListener() && success) {
            eventListener.onTokenTransfer(_from, _to, _value);
        }
        return success;
    }

    function hasListener() internal view returns(bool) {
        if(eventListener == address(0)) {
            return false;
        }
        return true;
    }

     
    function issue(address _to, uint256 _value) external onlyOwner canIssue {
        totalSupply = safeAdd(totalSupply, _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Issue(_to, _value);
        Transfer(address(0), _to, _value);
    }

     
    function destroy(address _from, uint256 _value) external {
        require(ownerByAddress[msg.sender] || msg.sender == _from);
        require(balances[_from] >= _value);
        totalSupply = safeSub(totalSupply, _value);
        balances[_from] = safeSub(balances[_from], _value);
        Transfer(_from, address(0), _value);
        Destroy(_from, _value);
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = safeAdd(allowed[msg.sender][_spender], _addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = safeSub(oldValue, _subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function finishIssuance() public onlyOwner returns (bool) {
        issuanceFinished = true;
        IssuanceFinished();
        return true;
    }
}

 

 
contract TransferLimitedToken is ManagedToken {
    uint256 public constant LIMIT_TRANSFERS_PERIOD = 365 days;

    mapping(address => bool) public limitedWallets;
    uint256 public limitEndDate;
    address public limitedWalletsManager;
    bool public isLimitEnabled;

    modifier onlyManager() {
        require(msg.sender == limitedWalletsManager);
        _;
    }

     
    modifier canTransfer(address _from, address _to)  {
        require(now >= limitEndDate || !isLimitEnabled || (!limitedWallets[_from] && !limitedWallets[_to]));
        _;
    }

     
    function TransferLimitedToken(
        uint256 _limitStartDate,
        address _listener,
        address[] _owners,
        address _limitedWalletsManager
    ) public ManagedToken(_listener, _owners)
    {
        limitEndDate = _limitStartDate + LIMIT_TRANSFERS_PERIOD;
        isLimitEnabled = true;
        limitedWalletsManager = _limitedWalletsManager;
    }

     
    function addLimitedWalletAddress(address _wallet) public {
        require(msg.sender == limitedWalletsManager || ownerByAddress[msg.sender]);
        limitedWallets[_wallet] = true;
    }

     
    function delLimitedWalletAddress(address _wallet) public onlyManager {
        limitedWallets[_wallet] = false;
    }

     
    function disableLimit() public onlyManager {
        isLimitEnabled = false;
    }

    function transfer(address _to, uint256 _value) public canTransfer(msg.sender, _to) returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public canTransfer(_from, _to) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public canTransfer(msg.sender, _spender) returns (bool) {
        return super.approve(_spender,_value);
    }
}

 

contract TheAbyssDAICO is Ownable, SafeMath, Pausable, ISimpleCrowdsale {
    enum AdditionalBonusState {
        Unavailable,
        Active,
        Applied
    }

    uint256 public constant ADDITIONAL_BONUS_NUM = 3;
    uint256 public constant ADDITIONAL_BONUS_DENOM = 100;

    uint256 public constant ETHER_MIN_CONTRIB = 0.0002 ether;
    uint256 public constant ETHER_MAX_CONTRIB = 20 ether;

    uint256 public constant ETHER_MIN_CONTRIB_PRIVATE = 100 ether;
    uint256 public constant ETHER_MAX_CONTRIB_PRIVATE = 3000 ether;

    uint256 public constant ETHER_MIN_CONTRIB_USA = 0.0002 ether;
    uint256 public constant ETHER_MAX_CONTRIB_USA = 20 ether;

    uint256 public constant SALE_START_TIME = 1523904300;  
    uint256 public constant SALE_END_TIME = 1523906100;  

    uint256 public constant BONUS_WINDOW_1_END_TIME = SALE_START_TIME + 2 days;
    uint256 public constant BONUS_WINDOW_2_END_TIME = SALE_START_TIME + 7 days;
    uint256 public constant BONUS_WINDOW_3_END_TIME = SALE_START_TIME + 14 days;
    uint256 public constant BONUS_WINDOW_4_END_TIME = SALE_START_TIME + 21 days;

    uint256 public constant MAX_CONTRIB_CHECK_END_TIME = SALE_START_TIME + 1 days;

    uint256 public constant BNB_TOKEN_PRICE_NUM = 169;
    uint256 public constant BNB_TOKEN_PRICE_DENOM = 1;

    uint256 public tokenPriceNum = 0;
    uint256 public tokenPriceDenom = 0;
    
    TransferLimitedToken public token;
    ICrowdsaleFund public fund;
    ICrowdsaleReservationFund public reservationFund;
    LockedTokensTest public lockedTokens;

    mapping(address => bool) public whiteList;
    mapping(address => bool) public privilegedList;
    mapping(address => AdditionalBonusState) public additionalBonusOwnerState;
    mapping(address => uint256) public userTotalContributed;

    address public bnbTokenWallet;
    address public referralTokenWallet;
    address public foundationTokenWallet;
    address public advisorsTokenWallet;
    address public companyTokenWallet;
    address public reserveTokenWallet;
    address public bountyTokenWallet;

    uint256 public totalEtherContributed = 0;
    uint256 public rawTokenSupply = 0;

     
    IERC20Token public bnbToken;
    uint256 public BNB_HARD_CAP = 300000 ether;  
    uint256 public BNB_MIN_CONTRIB = 1000 ether;  
    mapping(address => uint256) public bnbContributions;
    uint256 public totalBNBContributed = 0;

    uint256 public hardCap = 0;  
    uint256 public softCap = 0;  

    bool public bnbRefundEnabled = false;

    event LogContribution(address contributor, uint256 amountWei, uint256 tokenAmount, uint256 tokenBonus, bool additionalBonusApplied, uint256 timestamp);
    event ReservationFundContribution(address contributor, uint256 amountWei, uint256 tokensToIssue, uint256 bonusTokensToIssue, uint256 timestamp);
    event LogBNBContribution(address contributor, uint256 amountBNB, uint256 tokenAmount, uint256 tokenBonus, bool additionalBonusApplied, uint256 timestamp);

    modifier checkContribution() {
        require(isValidContribution());
        _;
    }

    modifier checkBNBContribution() {
        require(isValidBNBContribution());
        _;
    }

    modifier checkCap() {
        require(validateCap());
        _;
    }

    modifier checkTime() {
        require(now >= SALE_START_TIME && now <= SALE_END_TIME);
        _;
    }

    function TheAbyssDAICO(
        address bnbTokenAddress,
        address tokenAddress,
        address fundAddress,
        address reservationFundAddress,
        address _bnbTokenWallet,
        address _referralTokenWallet,
        address _foundationTokenWallet,
        address _advisorsTokenWallet,
        address _companyTokenWallet,
        address _reserveTokenWallet,
        address _bountyTokenWallet,
        address _owner
    ) public
        Ownable(_owner)
    {
        require(tokenAddress != address(0));

        bnbToken = IERC20Token(bnbTokenAddress);
        token = TransferLimitedToken(tokenAddress);
        fund = ICrowdsaleFund(fundAddress);
        reservationFund = ICrowdsaleReservationFund(reservationFundAddress);

        bnbTokenWallet = _bnbTokenWallet;
        referralTokenWallet = _referralTokenWallet;
        foundationTokenWallet = _foundationTokenWallet;
        advisorsTokenWallet = _advisorsTokenWallet;
        companyTokenWallet = _companyTokenWallet;
        reserveTokenWallet = _reserveTokenWallet;
        bountyTokenWallet = _bountyTokenWallet;
    }

     
    function isContributorInLists(address contributor) external view returns(bool) {
        return whiteList[contributor] || privilegedList[contributor] || token.limitedWallets(contributor);
    }

     
    function isValidContribution() internal view returns(bool) {
        uint256 currentUserContribution = safeAdd(msg.value, userTotalContributed[msg.sender]);
        if(whiteList[msg.sender] && msg.value >= ETHER_MIN_CONTRIB) {
            if(now <= MAX_CONTRIB_CHECK_END_TIME && currentUserContribution > ETHER_MAX_CONTRIB ) {
                    return false;
            }
            return true;

        }
        if(privilegedList[msg.sender] && msg.value >= ETHER_MIN_CONTRIB_PRIVATE) {
            if(now <= MAX_CONTRIB_CHECK_END_TIME && currentUserContribution > ETHER_MAX_CONTRIB_PRIVATE ) {
                    return false;
            }
            return true;
        }

        if(token.limitedWallets(msg.sender) && msg.value >= ETHER_MIN_CONTRIB_USA) {
            if(now <= MAX_CONTRIB_CHECK_END_TIME && currentUserContribution > ETHER_MAX_CONTRIB_USA) {
                    return false;
            }
            return true;
        }

        return false;
    }

     
    function validateCap() internal view returns(bool){
        if(msg.value <= safeSub(hardCap, totalEtherContributed)) {
            return true;
        }
        return false;
    }

     
    function setTokenPrice(uint256 _tokenPriceNum, uint256 _tokenPriceDenom) public onlyOwner {
        require(tokenPriceNum == 0 && tokenPriceDenom == 0);
        require(_tokenPriceNum > 0 && _tokenPriceDenom > 0);
        tokenPriceNum = _tokenPriceNum;
        tokenPriceDenom = _tokenPriceDenom;
    }

     
    function setHardCap(uint256 _hardCap) public onlyOwner {
        require(hardCap == 0);
        hardCap = _hardCap;
    }

     
    function setSoftCap(uint256 _softCap) public onlyOwner {
        require(softCap == 0);
        softCap = _softCap;
    }

     
    function getSoftCap() external view returns(uint256) {
        return softCap;
    }

     
    function isValidBNBContribution() internal view returns(bool) {
        if(token.limitedWallets(msg.sender)) {
            return false;
        }
        if(!whiteList[msg.sender] && !privilegedList[msg.sender]) {
            return false;
        }
        uint256 amount = bnbToken.allowance(msg.sender, address(this));
        if(amount < BNB_MIN_CONTRIB || safeAdd(totalBNBContributed, amount) > BNB_HARD_CAP) {
            return false;
        }
        return true;

    }

     
    function getBonus() internal constant returns (uint256, uint256) {
        uint256 numerator = 0;
        uint256 denominator = 100;

        if(now < BONUS_WINDOW_1_END_TIME) {
            numerator = 25;
        } else if(now < BONUS_WINDOW_2_END_TIME) {
            numerator = 15;
        } else if(now < BONUS_WINDOW_3_END_TIME) {
            numerator = 10;
        } else if(now < BONUS_WINDOW_4_END_TIME) {
            numerator = 5;
        } else {
            numerator = 0;
        }

        return (numerator, denominator);
    }

    function addToLists(
        address _wallet,
        bool isInWhiteList,
        bool isInPrivilegedList,
        bool isInLimitedList,
        bool hasAdditionalBonus
    ) public onlyOwner {
        if(isInWhiteList) {
            whiteList[_wallet] = true;
        }
        if(isInPrivilegedList) {
            privilegedList[_wallet] = true;
        }
        if(isInLimitedList) {
            token.addLimitedWalletAddress(_wallet);
        }
        if(hasAdditionalBonus) {
            additionalBonusOwnerState[_wallet] = AdditionalBonusState.Active;
        }
        if(reservationFund.canCompleteContribution(_wallet)) {
            reservationFund.completeContribution(_wallet);
        }
    }

     
    function addToWhiteList(address _wallet) public onlyOwner {
        whiteList[_wallet] = true;
    }

     
    function addAdditionalBonusMember(address _wallet) public onlyOwner {
        additionalBonusOwnerState[_wallet] = AdditionalBonusState.Active;
    }

     
    function addToPrivilegedList(address _wallet) public onlyOwner {
        privilegedList[_wallet] = true;
    }

     
    function setLockedTokens(address lockedTokensAddress) public onlyOwner {
        lockedTokens = LockedTokensTest(lockedTokensAddress);
    }

     
    function () payable public whenNotPaused {
        if(whiteList[msg.sender] || privilegedList[msg.sender] || token.limitedWallets(msg.sender)) {
            processContribution(msg.sender, msg.value);
        } else {
            processReservationContribution(msg.sender, msg.value);
        }
    }

    function processReservationContribution(address contributor, uint256 amount) private checkTime checkCap {
        require(amount >= ETHER_MIN_CONTRIB);

        if(now <= MAX_CONTRIB_CHECK_END_TIME) {
            uint256 currentUserContribution = safeAdd(amount, reservationFund.contributionsOf(contributor));
            require(currentUserContribution <= ETHER_MAX_CONTRIB);
        }
        uint256 bonusNum = 0;
        uint256 bonusDenom = 100;
        (bonusNum, bonusDenom) = getBonus();
        uint256 tokenBonusAmount = 0;
        uint256 tokenAmount = safeDiv(safeMul(amount, tokenPriceNum), tokenPriceDenom);

        if(bonusNum > 0) {
            tokenBonusAmount = safeDiv(safeMul(tokenAmount, bonusNum), bonusDenom);
        }

        reservationFund.processContribution.value(amount)(
            contributor,
            tokenAmount,
            tokenBonusAmount
        );
        ReservationFundContribution(contributor, amount, tokenAmount, tokenBonusAmount, now);
    }

     
    function processBNBContribution() public whenNotPaused checkTime checkBNBContribution {
        bool additionalBonusApplied = false;
        uint256 bonusNum = 0;
        uint256 bonusDenom = 100;
        (bonusNum, bonusDenom) = getBonus();
        uint256 amountBNB = bnbToken.allowance(msg.sender, address(this));
        bnbToken.transferFrom(msg.sender, address(this), amountBNB);
        bnbContributions[msg.sender] = safeAdd(bnbContributions[msg.sender], amountBNB);

        uint256 tokenBonusAmount = 0;
        uint256 tokenAmount = safeDiv(safeMul(amountBNB, BNB_TOKEN_PRICE_NUM), BNB_TOKEN_PRICE_DENOM);
        rawTokenSupply = safeAdd(rawTokenSupply, tokenAmount);
        if(bonusNum > 0) {
            tokenBonusAmount = safeDiv(safeMul(tokenAmount, bonusNum), bonusDenom);
        }

        if(additionalBonusOwnerState[msg.sender] ==  AdditionalBonusState.Active) {
            additionalBonusOwnerState[msg.sender] = AdditionalBonusState.Applied;
            uint256 additionalBonus = safeDiv(safeMul(tokenAmount, ADDITIONAL_BONUS_NUM), ADDITIONAL_BONUS_DENOM);
            tokenBonusAmount = safeAdd(tokenBonusAmount, additionalBonus);
            additionalBonusApplied = true;
        }

        uint256 tokenTotalAmount = safeAdd(tokenAmount, tokenBonusAmount);
        token.issue(msg.sender, tokenTotalAmount);
        totalBNBContributed = safeAdd(totalBNBContributed, amountBNB);

        LogBNBContribution(msg.sender, amountBNB, tokenAmount, tokenBonusAmount, additionalBonusApplied, now);
    }

     
    function processContribution(address contributor, uint256 amount) private checkTime checkContribution checkCap {
        bool additionalBonusApplied = false;
        uint256 bonusNum = 0;
        uint256 bonusDenom = 100;
        (bonusNum, bonusDenom) = getBonus();
        uint256 tokenBonusAmount = 0;

        uint256 tokenAmount = safeDiv(safeMul(amount, tokenPriceNum), tokenPriceDenom);
        rawTokenSupply = safeAdd(rawTokenSupply, tokenAmount);

        if(bonusNum > 0) {
            tokenBonusAmount = safeDiv(safeMul(tokenAmount, bonusNum), bonusDenom);
        }

        if(additionalBonusOwnerState[contributor] ==  AdditionalBonusState.Active) {
            additionalBonusOwnerState[contributor] = AdditionalBonusState.Applied;
            uint256 additionalBonus = safeDiv(safeMul(tokenAmount, ADDITIONAL_BONUS_NUM), ADDITIONAL_BONUS_DENOM);
            tokenBonusAmount = safeAdd(tokenBonusAmount, additionalBonus);
            additionalBonusApplied = true;
        }

        processPayment(contributor, amount, tokenAmount, tokenBonusAmount, additionalBonusApplied);
    }

     
    function processReservationFundContribution(
        address contributor,
        uint256 tokenAmount,
        uint256 tokenBonusAmount
    ) external payable checkCap {
        require(msg.sender == address(reservationFund));
        require(msg.value > 0);

        processPayment(contributor, msg.value, tokenAmount, tokenBonusAmount, false);
    }

    function processPayment(address contributor, uint256 etherAmount, uint256 tokenAmount, uint256 tokenBonusAmount, bool additionalBonusApplied) internal {
        uint256 tokenTotalAmount = safeAdd(tokenAmount, tokenBonusAmount);

        token.issue(contributor, tokenTotalAmount);
        fund.processContribution.value(etherAmount)(contributor);
        totalEtherContributed = safeAdd(totalEtherContributed, etherAmount);
        userTotalContributed[contributor] = safeAdd(userTotalContributed[contributor], etherAmount);
        LogContribution(contributor, etherAmount, tokenAmount, tokenBonusAmount, additionalBonusApplied, now);
    }

     
    function finalizeCrowdsale() public onlyOwner {
        if(
            (totalEtherContributed >= safeSub(hardCap, 20 ether) && totalBNBContributed >= safeSub(BNB_HARD_CAP, 10000 ether)) ||
            (now >= SALE_END_TIME && totalEtherContributed >= softCap)
        ) {
            fund.onCrowdsaleEnd();
            reservationFund.onCrowdsaleEnd();
             
            bnbToken.transfer(bnbTokenWallet, bnbToken.balanceOf(address(this)));

             
            uint256 referralTokenAmount = safeDiv(rawTokenSupply, 10);
            token.issue(referralTokenWallet, referralTokenAmount);

             
            uint256 foundationTokenAmount = safeDiv(token.totalSupply(), 2);  
            lockedTokens.addTokens(foundationTokenWallet, foundationTokenAmount, now + 365 days);

            uint256 suppliedTokenAmount = token.totalSupply();

             
            uint256 reservedTokenAmount = safeDiv(safeMul(suppliedTokenAmount, 3), 10);  
            token.issue(address(lockedTokens), reservedTokenAmount);
            lockedTokens.addTokens(reserveTokenWallet, reservedTokenAmount, now + 183 days);

             
            uint256 advisorsTokenAmount = safeDiv(suppliedTokenAmount, 10);  
            token.issue(advisorsTokenWallet, advisorsTokenAmount);

             
            uint256 companyTokenAmount = safeDiv(suppliedTokenAmount, 4);  
            token.issue(address(lockedTokens), companyTokenAmount);
            lockedTokens.addTokens(companyTokenWallet, companyTokenAmount, now + 730 days);

             
            uint256 bountyTokenAmount = safeDiv(suppliedTokenAmount, 60);  
            token.issue(bountyTokenWallet, bountyTokenAmount);

            token.setAllowTransfers(true);

        } else if(now >= SALE_END_TIME) {
             
            fund.enableCrowdsaleRefund();
            reservationFund.onCrowdsaleEnd();
            bnbRefundEnabled = true;
        }
        token.finishIssuance();
    }

     
    function refundBNBContributor() public {
        require(bnbRefundEnabled);
        require(bnbContributions[msg.sender] > 0);
        uint256 amount = bnbContributions[msg.sender];
        bnbContributions[msg.sender] = 0;
        bnbToken.transfer(msg.sender, amount);
        token.destroy(msg.sender, token.balanceOf(msg.sender));
    }
}