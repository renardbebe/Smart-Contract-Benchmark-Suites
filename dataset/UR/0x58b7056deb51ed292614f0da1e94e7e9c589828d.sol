 

pragma solidity ^0.4.17;

 
 
 
 
 
 
 
 

 
 
 
 
 
 
 
 
 
 
 
 
 


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;

        assert(a == 0 || c / a == b);

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

 
 
 
contract Owned {

    address public owner;
    address public proposedOwner;

    event OwnershipTransferInitiated(address indexed _proposedOwner);
    event OwnershipTransferCompleted(address indexed _newOwner);


    function Owned() public {
        owner = msg.sender;
    }


    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }


    function isOwner(address _address) internal view returns (bool) {
        return (_address == owner);
    }


    function initiateOwnershipTransfer(address _proposedOwner) public onlyOwner returns (bool) {
        proposedOwner = _proposedOwner;

        OwnershipTransferInitiated(_proposedOwner);

        return true;
    }


    function completeOwnershipTransfer() public returns (bool) {
        require(msg.sender == proposedOwner);

        owner = proposedOwner;
        proposedOwner = address(0);

        OwnershipTransferCompleted(owner);

        return true;
    }
}

 
 
 
 
contract OpsManaged is Owned {

    address public opsAddress;
    address public adminAddress;

    event AdminAddressChanged(address indexed _newAddress);
    event OpsAddressChanged(address indexed _newAddress);


    function OpsManaged() public
        Owned()
    {
    }


    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }


    modifier onlyAdminOrOps() {
        require(isAdmin(msg.sender) || isOps(msg.sender));
        _;
    }


    modifier onlyOwnerOrAdmin() {
        require(isOwner(msg.sender) || isAdmin(msg.sender));
        _;
    }


    modifier onlyOps() {
        require(isOps(msg.sender));
        _;
    }


    function isAdmin(address _address) internal view returns (bool) {
        return (adminAddress != address(0) && _address == adminAddress);
    }


    function isOps(address _address) internal view returns (bool) {
        return (opsAddress != address(0) && _address == opsAddress);
    }


    function isOwnerOrOps(address _address) internal view returns (bool) {
        return (isOwner(_address) || isOps(_address));
    }


     
    function setAdminAddress(address _adminAddress) external onlyOwnerOrAdmin returns (bool) {
        require(_adminAddress != owner);
        require(_adminAddress != address(this));
        require(!isOps(_adminAddress));

        adminAddress = _adminAddress;

        AdminAddressChanged(_adminAddress);

        return true;
    }


     
    function setOpsAddress(address _opsAddress) external onlyOwnerOrAdmin returns (bool) {
        require(_opsAddress != owner);
        require(_opsAddress != address(this));
        require(!isAdmin(_opsAddress));

        opsAddress = _opsAddress;

        OpsAddressChanged(_opsAddress);

        return true;
    }
}

contract SimpleTokenConfig {

    string  public constant TOKEN_SYMBOL   = "ST";
    string  public constant TOKEN_NAME     = "Simple Token";
    uint8   public constant TOKEN_DECIMALS = 18;

    uint256 public constant DECIMALSFACTOR = 10**uint256(TOKEN_DECIMALS);
    uint256 public constant TOKENS_MAX     = 800000000 * DECIMALSFACTOR;
}

contract ERC20Interface {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);
    function totalSupply() public view returns (uint256);

    function balanceOf(address _owner) public view returns (uint256 balance);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

 
 
 
contract ERC20Token is ERC20Interface, Owned {

    using SafeMath for uint256;

    string  private tokenName;
    string  private tokenSymbol;
    uint8   private tokenDecimals;
    uint256 internal tokenTotalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;


    function ERC20Token(string _symbol, string _name, uint8 _decimals, uint256 _totalSupply) public
        Owned()
    {
        tokenSymbol      = _symbol;
        tokenName        = _name;
        tokenDecimals    = _decimals;
        tokenTotalSupply = _totalSupply;
        balances[owner]  = _totalSupply;

         
         
        Transfer(0x0, owner, _totalSupply);
    }


    function name() public view returns (string) {
        return tokenName;
    }


    function symbol() public view returns (string) {
        return tokenSymbol;
    }


    function decimals() public view returns (uint8) {
        return tokenDecimals;
    }


    function totalSupply() public view returns (uint256) {
        return tokenTotalSupply;
    }


    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }


    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);

        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(_from, _to, _value);

        return true;
    }


    function approve(address _spender, uint256 _value) public returns (bool success) {

        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }
}

 
 
 
 
 
 
 
 

 
 
 
 
 
 
 
 

contract SimpleToken is ERC20Token, OpsManaged, SimpleTokenConfig {

    bool public finalized;


     
    event Burnt(address indexed _from, uint256 _amount);
    event Finalized();


    function SimpleToken() public
        ERC20Token(TOKEN_SYMBOL, TOKEN_NAME, TOKEN_DECIMALS, TOKENS_MAX)
        OpsManaged()
    {
        finalized = false;
    }


     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        checkTransferAllowed(msg.sender, _to);

        return super.transfer(_to, _value);
    }


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        checkTransferAllowed(msg.sender, _to);

        return super.transferFrom(_from, _to, _value);
    }


    function checkTransferAllowed(address _sender, address _to) private view {
        if (finalized) {
             
            return;
        }

         
         
         
         
        require(isOwnerOrOps(_sender) || _to == owner);
    }

     
     
    function burn(uint256 _value) public returns (bool success) {
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        tokenTotalSupply = tokenTotalSupply.sub(_value);

        Burnt(msg.sender, _value);

        return true;
    }


     
    function finalize() external onlyAdmin returns (bool success) {
        require(!finalized);

        finalized = true;

        Finalized();

        return true;
    }
}

 
 
 
 

 
 
 
 
 
 
 
 
 
 

contract Trustee is OpsManaged {

    using SafeMath for uint256;


    SimpleToken public tokenContract;

    struct Allocation {
        uint256 amountGranted;
        uint256 amountTransferred;
        bool    revokable;
    }

     
    address public revokeAddress;

     
     
     
    uint256 public totalLocked;

    mapping (address => Allocation) public allocations;


     
     
     
    event AllocationGranted(address indexed _from, address indexed _account, uint256 _amount, bool _revokable);
    event AllocationRevoked(address indexed _from, address indexed _account, uint256 _amountRevoked);
    event AllocationProcessed(address indexed _from, address indexed _account, uint256 _amount);
    event RevokeAddressChanged(address indexed _newAddress);
    event TokensReclaimed(uint256 _amount);


    function Trustee(SimpleToken _tokenContract) public
        OpsManaged()
    {
        require(address(_tokenContract) != address(0));

        tokenContract = _tokenContract;
    }


    modifier onlyOwnerOrRevoke() {
        require(isOwner(msg.sender) || isRevoke(msg.sender));
        _;
    }


    modifier onlyRevoke() {
        require(isRevoke(msg.sender));
        _;
    }


    function isRevoke(address _address) private view returns (bool) {
        return (revokeAddress != address(0) && _address == revokeAddress);
    }


     
    function setRevokeAddress(address _revokeAddress) external onlyOwnerOrRevoke returns (bool) {
        require(_revokeAddress != owner);
        require(!isAdmin(_revokeAddress));
        require(!isOps(_revokeAddress));

        revokeAddress = _revokeAddress;

        RevokeAddressChanged(_revokeAddress);

        return true;
    }


     
    function grantAllocation(address _account, uint256 _amount, bool _revokable) public onlyAdminOrOps returns (bool) {
        require(_account != address(0));
        require(_account != address(this));
        require(_amount > 0);

         
        require(allocations[_account].amountGranted == 0);

        if (isOps(msg.sender)) {
             
             
            require(!tokenContract.finalized());
        }

        totalLocked = totalLocked.add(_amount);
        require(totalLocked <= tokenContract.balanceOf(address(this)));

        allocations[_account] = Allocation({
            amountGranted     : _amount,
            amountTransferred : 0,
            revokable         : _revokable
        });

        AllocationGranted(msg.sender, _account, _amount, _revokable);

        return true;
    }


     
    function revokeAllocation(address _account) external onlyRevoke returns (bool) {
        require(_account != address(0));

        Allocation memory allocation = allocations[_account];

        require(allocation.revokable);

        uint256 ownerRefund = allocation.amountGranted.sub(allocation.amountTransferred);

        delete allocations[_account];

        totalLocked = totalLocked.sub(ownerRefund);

        AllocationRevoked(msg.sender, _account, ownerRefund);

        return true;
    }


     
     
     
     
    function processAllocation(address _account, uint256 _amount) external onlyOps returns (bool) {
        require(_account != address(0));
        require(_amount > 0);

        Allocation storage allocation = allocations[_account];

        require(allocation.amountGranted > 0);

        uint256 transferable = allocation.amountGranted.sub(allocation.amountTransferred);

        if (transferable < _amount) {
           return false;
        }

        allocation.amountTransferred = allocation.amountTransferred.add(_amount);

         
        require(tokenContract.transfer(_account, _amount));

        totalLocked = totalLocked.sub(_amount);

        AllocationProcessed(msg.sender, _account, _amount);

        return true;
    }


     
     
     
    function reclaimTokens() external onlyAdmin returns (bool) {
        uint256 ownBalance = tokenContract.balanceOf(address(this));

         
        require(ownBalance > totalLocked);

        uint256 amountReclaimed = ownBalance.sub(totalLocked);

        address tokenOwner = tokenContract.owner();
        require(tokenOwner != address(0));

        require(tokenContract.transfer(tokenOwner, amountReclaimed));

        TokensReclaimed(amountReclaimed);

        return true;
    }
}

 
 
 
 
 
 
 
 
 
 
 
 
 

contract Pausable is OpsManaged {

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


  function pause() public onlyAdmin whenNotPaused {
    paused = true;

    Pause();
  }


  function unpause() public onlyAdmin whenPaused {
    paused = false;

    Unpause();
  }
}

contract TokenSaleConfig is SimpleTokenConfig {

    uint256 public constant PHASE1_START_TIME         = 1510664400;  
    uint256 public constant PHASE2_START_TIME         = 1510750800;  
    uint256 public constant END_TIME                  = 1512133199;  
    uint256 public constant CONTRIBUTION_MIN          = 0.1 ether;
    uint256 public constant CONTRIBUTION_MAX          = 10000.0 ether;

     
     
     
    uint256 public constant PHASE1_ACCOUNT_TOKENS_MAX = 36000     * DECIMALSFACTOR;

    uint256 public constant TOKENS_SALE               = 240000000 * DECIMALSFACTOR;
    uint256 public constant TOKENS_FOUNDERS           = 80000000  * DECIMALSFACTOR;
    uint256 public constant TOKENS_ADVISORS           = 80000000  * DECIMALSFACTOR;
    uint256 public constant TOKENS_EARLY_BACKERS      = 44884831  * DECIMALSFACTOR;
    uint256 public constant TOKENS_ACCELERATOR        = 217600000 * DECIMALSFACTOR;
    uint256 public constant TOKENS_FUTURE             = 137515169 * DECIMALSFACTOR;

     
     
     
     
    uint256 public constant TOKENS_PER_KETHER         = 3600000;

     
     
    uint256 public constant PURCHASE_DIVIDER          = 10**(uint256(18) - TOKEN_DECIMALS + 3);

}

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract TokenSale is OpsManaged, Pausable, TokenSaleConfig {  

    using SafeMath for uint256;


     
     
    bool public finalized;

     
     
    uint256 public endTime;
    uint256 public pausedTime;

     
    uint256 public tokensPerKEther;

     
    uint256 public phase1AccountTokensMax;

     
    address public wallet;

     
    SimpleToken public tokenContract;

     
     
     
     
     
    Trustee public trusteeContract;

     
    uint256 public totalTokensSold;

     
    uint256 public totalPresaleBase;
    uint256 public totalPresaleBonus;

     
     
     
    mapping(address => uint8) public whitelist;


     
     
     
    event Initialized();
    event PresaleAdded(address indexed _account, uint256 _baseTokens, uint256 _bonusTokens);
    event WhitelistUpdated(address indexed _account, uint8 _phase);
    event TokensPurchased(address indexed _beneficiary, uint256 _cost, uint256 _tokens, uint256 _totalSold);
    event TokensPerKEtherUpdated(uint256 _amount);
    event Phase1AccountTokensMaxUpdated(uint256 _tokens);
    event WalletChanged(address _newWallet);
    event TokensReclaimed(uint256 _amount);
    event UnsoldTokensBurnt(uint256 _amount);
    event Finalized();


    function TokenSale(SimpleToken _tokenContract, Trustee _trusteeContract, address _wallet) public
        OpsManaged()
    {
        require(address(_tokenContract) != address(0));
        require(address(_trusteeContract) != address(0));
        require(_wallet != address(0));

        require(PHASE1_START_TIME >= currentTime());
        require(PHASE2_START_TIME > PHASE1_START_TIME);
        require(END_TIME > PHASE2_START_TIME);
        require(TOKENS_PER_KETHER > 0);
        require(PHASE1_ACCOUNT_TOKENS_MAX > 0);

         
        uint256 partialAllocations = TOKENS_FOUNDERS.add(TOKENS_ADVISORS).add(TOKENS_EARLY_BACKERS);
        require(partialAllocations.add(TOKENS_SALE).add(TOKENS_ACCELERATOR).add(TOKENS_FUTURE) == TOKENS_MAX);

        wallet                 = _wallet;
        pausedTime             = 0;
        endTime                = END_TIME;
        finalized              = false;
        tokensPerKEther        = TOKENS_PER_KETHER;
        phase1AccountTokensMax = PHASE1_ACCOUNT_TOKENS_MAX;

        tokenContract   = _tokenContract;
        trusteeContract = _trusteeContract;
    }


     
     
    function initialize() external onlyOwner returns (bool) {
        require(totalTokensSold == 0);
        require(totalPresaleBase == 0);
        require(totalPresaleBonus == 0);

        uint256 ownBalance = tokenContract.balanceOf(address(this));
        require(ownBalance == TOKENS_SALE);

         
        uint256 trusteeBalance = tokenContract.balanceOf(address(trusteeContract));
        require(trusteeBalance >= TOKENS_FUTURE);

        Initialized();

        return true;
    }


     
    function changeWallet(address _wallet) external onlyAdmin returns (bool) {
        require(_wallet != address(0));
        require(_wallet != address(this));
        require(_wallet != address(trusteeContract));
        require(_wallet != address(tokenContract));

        wallet = _wallet;

        WalletChanged(wallet);

        return true;
    }



     
     
     

    function currentTime() public view returns (uint256 _currentTime) {
        return now;
    }


    modifier onlyBeforeSale() {
        require(hasSaleEnded() == false);
        require(currentTime() < PHASE1_START_TIME);
       _;
    }


    modifier onlyDuringSale() {
        require(hasSaleEnded() == false && currentTime() >= PHASE1_START_TIME);
        _;
    }

    modifier onlyAfterSale() {
         
        require(finalized);
        _;
    }


    function hasSaleEnded() private view returns (bool) {
         
        if (totalTokensSold >= TOKENS_SALE || finalized) {
            return true;
         
         
        } else if (pausedTime == 0 && currentTime() >= endTime) {
            return true;
         
         
        } else {
            return false;
        }
    }



     
     
     

     
     
     
     
     
    function updateWhitelist(address _account, uint8 _phase) external onlyOps returns (bool) {
        require(_account != address(0));
        require(_phase <= 2);
        require(!hasSaleEnded());

        whitelist[_account] = _phase;

        WhitelistUpdated(_account, _phase);

        return true;
    }



     
     
     

     
    function setTokensPerKEther(uint256 _tokensPerKEther) external onlyAdmin onlyBeforeSale returns (bool) {
        require(_tokensPerKEther > 0);

        tokensPerKEther = _tokensPerKEther;

        TokensPerKEtherUpdated(_tokensPerKEther);

        return true;
    }


     
    function setPhase1AccountTokensMax(uint256 _tokens) external onlyAdmin onlyBeforeSale returns (bool) {
        require(_tokens > 0);

        phase1AccountTokensMax = _tokens;

        Phase1AccountTokensMaxUpdated(_tokens);

        return true;
    }


    function () external payable whenNotPaused onlyDuringSale {
        buyTokens();
    }


     
    function buyTokens() public payable whenNotPaused onlyDuringSale returns (bool) {
        require(msg.value >= CONTRIBUTION_MIN);
        require(msg.value <= CONTRIBUTION_MAX);
        require(totalTokensSold < TOKENS_SALE);

         
        uint8 whitelistedPhase = whitelist[msg.sender];
        require(whitelistedPhase > 0);

        uint256 tokensMax = TOKENS_SALE.sub(totalTokensSold);

        if (currentTime() < PHASE2_START_TIME) {
             
            require(whitelistedPhase == 1);

            uint256 accountBalance = tokenContract.balanceOf(msg.sender);

             
             
            uint256 phase1Balance = phase1AccountTokensMax.sub(accountBalance);

            if (phase1Balance < tokensMax) {
                tokensMax = phase1Balance;
            }
        }

        require(tokensMax > 0);

        uint256 tokensBought = msg.value.mul(tokensPerKEther).div(PURCHASE_DIVIDER);
        require(tokensBought > 0);

        uint256 cost = msg.value;
        uint256 refund = 0;

        if (tokensBought > tokensMax) {
             
            tokensBought = tokensMax;

             
            cost = tokensBought.mul(PURCHASE_DIVIDER).div(tokensPerKEther);

             
            refund = msg.value.sub(cost);
        }

        totalTokensSold = totalTokensSold.add(tokensBought);

         
        require(tokenContract.transfer(msg.sender, tokensBought));

         
        if (refund > 0) {
            msg.sender.transfer(refund);
        }

         
        wallet.transfer(msg.value.sub(refund));

        TokensPurchased(msg.sender, cost, tokensBought, totalTokensSold);

         
        if (totalTokensSold == TOKENS_SALE) {
            finalizeInternal();
        }

        return true;
    }


     
     
     

     
     
    function addPresale(address _account, uint256 _baseTokens, uint256 _bonusTokens) external onlyAdmin onlyBeforeSale returns (bool) {
        require(_account != address(0));

         
        require(_baseTokens > 0);
        require(_bonusTokens < _baseTokens);

         
        totalTokensSold = totalTokensSold.add(_baseTokens);
        require(totalTokensSold <= TOKENS_SALE);

        uint256 ownBalance = tokenContract.balanceOf(address(this));
        require(_baseTokens <= ownBalance);

        totalPresaleBase  = totalPresaleBase.add(_baseTokens);
        totalPresaleBonus = totalPresaleBonus.add(_bonusTokens);

         
        require(tokenContract.transfer(address(trusteeContract), _baseTokens));

         
        uint256 tokens = _baseTokens.add(_bonusTokens);
        require(trusteeContract.grantAllocation(_account, tokens, false  ));

        PresaleAdded(_account, _baseTokens, _bonusTokens);

        return true;
    }


     
     
     

     
    function pause() public onlyAdmin whenNotPaused {
        require(hasSaleEnded() == false);

        pausedTime = currentTime();

        return super.pause();
    }


     
     
     
    function unpause() public onlyAdmin whenPaused {

         
        uint256 current = currentTime();

         
        if (current > PHASE1_START_TIME) {
            uint256 timeDelta;

            if (pausedTime < PHASE1_START_TIME) {
                 
                 
                timeDelta = current.sub(PHASE1_START_TIME);
            } else {
                 
                 
                timeDelta = current.sub(pausedTime);
            }

            endTime = endTime.add(timeDelta);
        }

        pausedTime = 0;

        return super.unpause();
    }


     
     
     
     
    function reclaimTokens(uint256 _amount) external onlyAfterSale onlyAdmin returns (bool) {
        uint256 ownBalance = tokenContract.balanceOf(address(this));
        require(_amount <= ownBalance);
        
        address tokenOwner = tokenContract.owner();
        require(tokenOwner != address(0));

        require(tokenContract.transfer(tokenOwner, _amount));

        TokensReclaimed(_amount);

        return true;
    }


     
    function burnUnsoldTokens() external onlyAfterSale onlyAdmin returns (bool) {
        uint256 ownBalance = tokenContract.balanceOf(address(this));

        require(tokenContract.burn(ownBalance));

        UnsoldTokensBurnt(ownBalance);

        return true;
    }


     
     
     
    function finalize() external onlyAdmin returns (bool) {
        return finalizeInternal();
    }


     
     
     
    function finalizeInternal() private returns (bool) {
        require(!finalized);

        finalized = true;

        Finalized();

        return true;
    }
}