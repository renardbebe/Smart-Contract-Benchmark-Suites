 

pragma solidity 0.4.24;


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}


 
contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    from_;
    value_;
    data_;
    revert();
  }

}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


 
contract HasNoContracts is Ownable {

   
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


 
contract PoolParty is HasNoTokens, HasNoContracts {
    using SafeMath for uint256;

    event PoolCreated(uint256 poolId, address creator);

    uint256 public nextPoolId;

     
    mapping(uint256 =>address) public pools;

     
     
     
     
    function reclaimEther() external onlyOwner {
        owner.transfer(address(this).balance);
    }

     
     
     
     
     
     
     
     
     
    function createPool(
        address[] _admins,
        uint256[] _configsUint,
        bool[] _configsBool
    )
        public
        returns (address _pool)
    {
        address poolOwner = msg.sender;

        _pool = new Pool(
            poolOwner,
            _admins,
            _configsUint,
            _configsBool,
            nextPoolId
        );

        pools[nextPoolId] = _pool;
        nextPoolId = nextPoolId.add(1);

        emit PoolCreated(nextPoolId, poolOwner);
    }
}


 
contract Admin {
    using SafeMath for uint256;
    using SafeMath for uint8;

    address public owner;
    address[] public admins;

     
    modifier isAdmin() {
        bool found = false;

        for (uint256 i = 0; i < admins.length; ++i) {
            if (admins[i] == msg.sender) {
                found = true;
                break;
            }
        }

         
        require(found);
        _;
    }

     
    modifier isValidAdminsList(address[] _listOfAdmins) {
        bool containsSender = false;

        for (uint256 i = 0; i < _listOfAdmins.length; ++i) {
             
            require(_listOfAdmins[i] != address(0));

            if (_listOfAdmins[i] == owner) {
                containsSender = true;
            }

            for (uint256 j = i + 1; j < _listOfAdmins.length; ++j) {
                 
                require(_listOfAdmins[i] != _listOfAdmins[j]);
            }
        }

         
        require(containsSender);
        _;
    }

     
     
     
    function createAdminsForPool(
        address[] _listOfAdmins
    )
        internal
        isValidAdminsList(_listOfAdmins)
    {
        admins = _listOfAdmins;
    }
}


 
contract State is Admin {
    enum PoolState{
         
        OPEN,

         
        CLOSED,

         
         
        AWAITING_TOKENS,

         
        COMPLETED,

         
        CANCELLED
    }

    event PoolIsOpen ();
    event PoolIsClosed ();
    event PoolIsAwaitingTokens ();
    event PoolIsCompleted ();
    event PoolIsCancelled ();

    PoolState public state;

     
    modifier isOpen() {
         
        require(state == PoolState.OPEN);
        _;
    }

     
    modifier isClosed() {
         
        require(state == PoolState.CLOSED);
        _;
    }

     
    modifier isOpenOrClosed() {
         
        require(state == PoolState.OPEN || state == PoolState.CLOSED);
        _;
    }

     
    modifier isCancelled() {
         
        require(state == PoolState.CANCELLED);
        _;
    }

     
    modifier isUserRefundable() {
         
        require(state == PoolState.OPEN || state == PoolState.CANCELLED);
        _;
    }

     
    modifier isAdminRefundable() {
         
        require(state == PoolState.OPEN || state == PoolState.CLOSED || state == PoolState.CANCELLED);   
        _;
    }

     
    modifier isAwaitingOrCompleted() {
         
        require(state == PoolState.COMPLETED || state == PoolState.AWAITING_TOKENS);
        _;
    }

     
    modifier isCompleted() {
         
        require(state == PoolState.COMPLETED);
        _;
    }

     
     
    function setPoolToOpen() public isAdmin isClosed {
        state = PoolState.OPEN;
        emit PoolIsOpen();
    }

     
     
    function setPoolToClosed() public isAdmin isOpen {
        state = PoolState.CLOSED;
        emit PoolIsClosed();
    }

     
     
    function setPoolToCancelled() public isAdmin isOpenOrClosed {
        state = PoolState.CANCELLED;
        emit PoolIsCancelled();
    }

     
    function setPoolToAwaitingTokens() internal {
        state = PoolState.AWAITING_TOKENS;
        emit PoolIsAwaitingTokens();
    }

     
    function setPoolToCompleted() internal {
        state = PoolState.COMPLETED;
        emit PoolIsCompleted();
    }
}


 
contract Config is State {
    enum OptionUint256{
        MAX_ALLOCATION,
        MIN_CONTRIBUTION,
        MAX_CONTRIBUTION,

         
        ADMIN_FEE_PERCENT_DECIMALS,

         
        ADMIN_FEE_PERCENTAGE
    }

    enum OptionBool{
         
        HAS_WHITELIST,

         
        ADMIN_FEE_PAYOUT_TOKENS
    }

    uint8 public constant  OPTION_UINT256_SIZE = 5;
    uint8 public constant  OPTION_BOOL_SIZE = 2;
    uint8 public constant  FEE_PERCENTAGE_DECIMAL_CAP = 5;

    uint256 public maxAllocation;
    uint256 public minContribution;
    uint256 public maxContribution;
    uint256 public adminFeePercentageDecimals;
    uint256 public adminFeePercentage;
    uint256 public feePercentageDivisor;

    bool public hasWhitelist;
    bool public adminFeePayoutIsToken;

     
     
     
     
     
     
     
     
     
     
    function setMinMaxContribution(
        uint256 _min,
        uint256 _max
    )
        public
        isAdmin
        isOpenOrClosed
    {
         
        require(_max <= maxAllocation);
         
        require(_min <= _max);

        minContribution = _min;
        maxContribution = _max;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function createConfigsForPool(
        uint256[] _configsUint,
        bool[] _configsBool
    )
        internal
    {
         
        require(_configsUint.length == OPTION_UINT256_SIZE);
         
        require(_configsBool.length == OPTION_BOOL_SIZE);

         
        maxAllocation = _configsUint[uint(OptionUint256.MAX_ALLOCATION)];
        minContribution = _configsUint[uint(OptionUint256.MIN_CONTRIBUTION)];
        maxContribution = _configsUint[uint(OptionUint256.MAX_CONTRIBUTION)];
        adminFeePercentageDecimals = _configsUint[uint(OptionUint256.ADMIN_FEE_PERCENT_DECIMALS)];
        adminFeePercentage = _configsUint[uint(OptionUint256.ADMIN_FEE_PERCENTAGE)];

         
        hasWhitelist = _configsBool[uint(OptionBool.HAS_WHITELIST)];
        adminFeePayoutIsToken = _configsBool[uint(OptionBool.ADMIN_FEE_PAYOUT_TOKENS)];

         
         
        require(adminFeePercentageDecimals <= FEE_PERCENTAGE_DECIMAL_CAP);
         
        require(maxContribution <= maxAllocation);
         
        require(minContribution <= maxContribution);

         
        feePercentageDivisor = (10 ** adminFeePercentageDecimals).mul(100);
         
        require(adminFeePercentage < feePercentageDivisor);
    }
}


 
contract Whitelist is Config {
    mapping(address => bool) public whitelist;

     
    modifier isWhitelistEnabled() {
         
        require(hasWhitelist);
        _;
    }

     
    modifier canDeposit(address _user) {
        if (hasWhitelist) {
             
            require(whitelist[_user] != false);
        }
        _;
    }

     
     
     
     
     
    function addAddressesToWhitelist(address[] _users) public isAdmin {
        addAddressesToWhitelistInternal(_users);
    }

     
     
     
     
     
    function addAddressesToWhitelistInternal(
        address[] _users
    )
        internal
        isWhitelistEnabled
    {
         
        require(_users.length > 0);

        for (uint256 i = 0; i < _users.length; ++i) {
            whitelist[_users[i]] = true;
        }
    }
}


 
contract Pool is Whitelist {
     
     
     
     
    mapping(address => bool) public invested;

     
     
     
    mapping(address => uint256) public swimmers;
    mapping(address => uint256) public swimmerReimbursements;
    mapping(address => mapping(address => uint256)) public swimmersTokensPaid;
    mapping(address => uint256) public totalTokensDistributed;
    mapping(address => bool) public adminFeePaid;

    address[] public swimmersList;
    address[] public tokenAddress;

    address public poolPartyAddress;
    uint256 public adminWeiFee;
    uint256 public poolId;
    uint256 public weiRaised;
    uint256 public reimbursementTotal;

    event AdminFeePayout(uint256 value);
    event Deposit(address recipient, uint256 value);
    event EtherTransferredOut(uint256 value);
    event ProjectReimbursed(uint256 value);
    event Refund(address recipient, uint256 value);
    event ReimbursementClaimed(address recipient, uint256 value);
    event TokenAdded(address tokenAddress);
    event TokenRemoved(address tokenAddress);
    event TokenClaimed(address recipient, uint256 value, address tokenAddress);

     
    modifier isOwner() {
         
        require(msg.sender == owner);
        _;
    }

     
     
    modifier depositIsConfigCompliant() {
         
        require(msg.value > 0);
        uint256 totalRaised = weiRaised.add(msg.value);
        uint256 amount = swimmers[msg.sender].add(msg.value);

         
        require(totalRaised <= maxAllocation);
         
        require(amount <= maxContribution);
         
        require(amount >= minContribution);
        _;
    }

     
    modifier userHasFundedPool(address _user) {
         
        require(swimmers[_user] > 0);
        _;
    }

     
    modifier isValidIndex(uint256 _startIndex, uint256 _numberOfAddresses) {
        uint256 endIndex = _startIndex.add(_numberOfAddresses.sub(1));

         
        require(_startIndex < swimmersList.length);
         
        require(endIndex < swimmersList.length);
        _;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    constructor(
        address _poolOwner,
        address[] _admins,
        uint256[] _configsUint,
        bool[] _configsBool,
        uint256  _poolId
    )
        public
    {
        owner = _poolOwner;
        state = PoolState.OPEN;
        poolPartyAddress = msg.sender;
        poolId = _poolId;

        createAdminsForPool(_admins);
        createConfigsForPool(_configsUint, _configsBool);

        if (hasWhitelist) {
            addAddressesToWhitelistInternal(admins);
        }

        emit PoolIsOpen();
    }

     
     
    function() public payable {
        deposit(msg.sender);
    }

     
     
     
     
    function getAdminAddressArray(
    )
        public
        view
        returns (address[] _arrayToReturn)
    {
        _arrayToReturn = admins;
    }

     
     
     
     
    function getTokenAddressArray(
    )
        public
        view
        returns (address[] _arrayToReturn)
    {
        _arrayToReturn = tokenAddress;
    }

     
     
     
    function getAmountOfTokens(
    )
        public
        view
        returns (uint256 _lengthOfTokens)
    {
        _lengthOfTokens = tokenAddress.length;
    }

     
     
     
     
    function getSwimmersListArray(
    )
        public
        view
        returns (address[] _arrayToReturn)
    {
        _arrayToReturn = swimmersList;
    }

     
     
     
    function getAmountOfSwimmers(
    )
        public
        view
        returns (uint256 _lengthOfSwimmers)
    {
        _lengthOfSwimmers = swimmersList.length;
    }

     
     
     
     
     
     
     
     
    function deposit(
        address _user
    )
        public
        payable
        isOpen
        depositIsConfigCompliant
        canDeposit(_user)
    {
        if (!invested[_user]) {
            swimmersList.push(_user);
            invested[_user] = true;
        }

        weiRaised = weiRaised.add(msg.value);
        swimmers[_user] = swimmers[_user].add(msg.value);

        emit Deposit(msg.sender, msg.value);
    }

     
     
     
     
     
    function refund() public isUserRefundable userHasFundedPool(msg.sender) {
        processRefundInternal(msg.sender);
    }

     
     
     
     
     
     
     
    function refundManyAddresses(
        uint256 _startIndex,
        uint256 _numberOfAddresses
    )
        public
        isCancelled
        isValidIndex(_startIndex, _numberOfAddresses)
    {
        uint256 endIndex = _startIndex.add(_numberOfAddresses.sub(1));

        for (uint256 i = _startIndex; i <= endIndex; ++i) {
            address user = swimmersList[i];

            if (swimmers[user] > 0) {
                processRefundInternal(user);
            }
        }
    }

     
     
     
     
    function claim() public {
        claimAddress(msg.sender);
    }

     
     
     
     
     
     
    function claimAddress(
        address _address
    )
        public
        isCompleted
        userHasFundedPool(_address)
    {
        for (uint256 i = 0; i < tokenAddress.length; ++i) {
            ERC20Basic token = ERC20Basic(tokenAddress[i]);
            uint256 poolTokenBalance = token.balanceOf(this);

            payoutTokensInternal(_address, poolTokenBalance, token);
        }
    }

     
     
     
     
     
     
    function claimManyAddresses(
        uint256 _startIndex,
        uint256 _numberOfAddresses
    )
        public
        isValidIndex(_startIndex, _numberOfAddresses)
    {
        uint256 endIndex = _startIndex.add(_numberOfAddresses.sub(1));

        claimAddressesInternal(_startIndex, endIndex);
    }

     
     
     
     
     
    function reimbursement() public {
        claimReimbursement(msg.sender);
    }

     
     
     
     
     
     
    function claimReimbursement(
        address _user
    )
        public
        isAwaitingOrCompleted
        userHasFundedPool(_user)
    {
        processReimbursementInternal(_user);
    }

     
     
     
     
     
     
     
    function claimManyReimbursements(
        uint256 _startIndex,
        uint256 _numberOfAddresses
    )
        public
        isAwaitingOrCompleted
        isValidIndex(_startIndex, _numberOfAddresses)
    {
        uint256 endIndex = _startIndex.add(_numberOfAddresses.sub(1));

        for (uint256 i = _startIndex; i <= endIndex; ++i) {
            address user = swimmersList[i];

            if (swimmers[user] > 0) {
                processReimbursementInternal(user);
            }
        }
    }

     
     
     
     
     
     
     
     
     
     
    function addToken(
        address _tokenAddress
    )
        public
        isAdmin
        isAwaitingOrCompleted
    {
        if (state != PoolState.COMPLETED) {
            setPoolToCompleted();
        }

        for (uint256 i = 0; i < tokenAddress.length; ++i) {
             
            require(tokenAddress[i] != _tokenAddress);
        }

         
         
         
        ERC20Basic token = ERC20Basic(_tokenAddress);

         
        require(token.balanceOf(this) >= 0);

        tokenAddress.push(_tokenAddress);

        emit TokenAdded(_tokenAddress);
    }

     
     
     
     
     
     
     
     
    function removeToken(address _tokenAddress) public isAdmin isCompleted {
        for (uint256 i = 0; i < tokenAddress.length; ++i) {
            if (tokenAddress[i] == _tokenAddress) {
                tokenAddress[i] = tokenAddress[tokenAddress.length - 1];
                delete tokenAddress[tokenAddress.length - 1];
                tokenAddress.length--;
                break;
            }
        }

        if (tokenAddress.length == 0) {
            setPoolToAwaitingTokens();
        }

        emit TokenRemoved(_tokenAddress);
    }

     
     
     
     
     
     
     
    function removeAddressFromWhitelistAndRefund(
        address _address
    )
        public
        isWhitelistEnabled
        canDeposit(_address)
    {
        whitelist[_address] = false;
        refundAddress(_address);
    }

     
     
     
     
     
     
    function refundAddress(
        address _address
    )
        public
        isAdmin
        isAdminRefundable
        userHasFundedPool(_address)
    {
        processRefundInternal(_address);
    }

     
     
     
     
     
     
    function projectReimbursement(
    )
        public
        payable
        isAdmin
        isAwaitingOrCompleted
    {
        reimbursementTotal = reimbursementTotal.add(msg.value);

        emit ProjectReimbursed(msg.value);
    }

     
     
     
     
     
     
     
     
     
     
    function setMaxAllocation(uint256 _newMax) public isAdmin isOpenOrClosed {
         
        require(_newMax >= maxContribution);

        maxAllocation = _newMax;
    }

     
     
     
     
     
     
     
    function transferWei(address _contractAddress) public isOwner isClosed {
        uint256 weiForTransfer = weiTransferCalculator();

        if (adminFeePercentage > 0) {
            weiForTransfer = payOutAdminFee(weiForTransfer);
        }

         
        require(weiForTransfer > 0);
        _contractAddress.transfer(weiForTransfer);

        setPoolToAwaitingTokens();

        emit EtherTransferredOut(weiForTransfer);
    }

     
     
     
    function weiTransferCalculator() internal returns (uint256 _amountOfWei) {
        if (weiRaised > maxAllocation) {
            _amountOfWei = maxAllocation;
            reimbursementTotal = reimbursementTotal.add(weiRaised.sub(maxAllocation));
        } else {
            _amountOfWei = weiRaised;
        }
    }

     
     
     
     
     
     
    function payOutAdminFee(
        uint256 _weiTotal
    )
        internal
        returns (uint256 _weiForTransfer)
    {
        adminWeiFee = _weiTotal.mul(adminFeePercentage).div(feePercentageDivisor);

        if (adminFeePayoutIsToken) {
             
             
            if (swimmers[owner] > 0) {
                collectAdminFee(owner);
            } else {
                 
                 
                if (!invested[owner]) {
                    swimmersList.push(owner);
                    invested[owner] = true;
                }

                adminFeePaid[owner] = true;
            }

             
             
             
            swimmers[owner] = swimmers[owner].add(adminWeiFee);
            _weiForTransfer = _weiTotal;
        } else {
            _weiForTransfer = _weiTotal.sub(adminWeiFee);

            if (adminWeiFee > 0) {
                owner.transfer(adminWeiFee);

                emit AdminFeePayout(adminWeiFee);
            }
        }
    }

     
     
     
     
     
     
     
     
     
     
     
    function claimAddressesInternal(
        uint256 _startIndex,
        uint256 _endIndex
    )
        internal
        isCompleted
    {
        for (uint256 i = 0; i < tokenAddress.length; ++i) {
            ERC20Basic token = ERC20Basic(tokenAddress[i]);
            uint256 tokenBalance = token.balanceOf(this);

            for (uint256 j = _startIndex; j <= _endIndex && tokenBalance > 0; ++j) {
                address user = swimmersList[j];

                if (swimmers[user] > 0) {
                    payoutTokensInternal(user, tokenBalance, token);
                }

                tokenBalance = token.balanceOf(this);
            }
        }
    }

     
     
     
     
     
    function payoutTokensInternal(
        address _user,
        uint256 _poolBalance,
        ERC20Basic _token
    )
        internal
    {
         
         
         
        if (!adminFeePaid[_user] && adminFeePayoutIsToken && adminFeePercentage > 0) {
            collectAdminFee(_user);
        }

         
        uint256 totalTokensReceived = _poolBalance.add(totalTokensDistributed[_token]);

        uint256 tokensOwedTotal = swimmers[_user].mul(totalTokensReceived).div(weiRaised);
        uint256 tokensPaid = swimmersTokensPaid[_user][_token];
        uint256 tokensToBePaid = tokensOwedTotal.sub(tokensPaid);

        if (tokensToBePaid > 0) {
            swimmersTokensPaid[_user][_token] = tokensOwedTotal;
            totalTokensDistributed[_token] = totalTokensDistributed[_token].add(tokensToBePaid);

             
            require(_token.transfer(_user, tokensToBePaid));

            emit TokenClaimed(_user, tokensToBePaid, _token);
        }
    }

     
     
     
    function processReimbursementInternal(address _user) internal {
         
         
         
        if (!adminFeePaid[_user] && adminFeePayoutIsToken && adminFeePercentage > 0) {
            collectAdminFee(_user);
        }

         
         
         
        uint256 amountContributed = swimmers[_user];
        uint256 totalReimbursement = reimbursementTotal.mul(amountContributed).div(weiRaised);
        uint256 alreadyReimbursed = swimmerReimbursements[_user];

        uint256 reimbursementAvailable = totalReimbursement.sub(alreadyReimbursed);

        if (reimbursementAvailable > 0) {
            swimmerReimbursements[_user] = swimmerReimbursements[_user].add(reimbursementAvailable);
            _user.transfer(reimbursementAvailable);

            emit ReimbursementClaimed(_user, reimbursementAvailable);
        }
    }

     
     
     
     
     
    function collectAdminFee(address _user) internal {
        uint256 individualFee = swimmers[_user].mul(adminFeePercentage).div(feePercentageDivisor);

         
         
        individualFee = individualFee.add(1);
        swimmers[_user] = swimmers[_user].sub(individualFee);

         
        adminFeePaid[_user] = true;
    }

     
     
     
    function processRefundInternal(address _user) internal {
        uint256 amount = swimmers[_user];

        swimmers[_user] = 0;
        weiRaised = weiRaised.sub(amount);
        _user.transfer(amount);

        emit Refund(_user, amount);
    }
}