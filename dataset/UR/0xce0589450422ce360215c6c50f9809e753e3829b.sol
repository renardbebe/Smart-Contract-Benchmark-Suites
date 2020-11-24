 

pragma solidity ^0.4.15;

 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

 
contract HasNoEther is Ownable {

     
    function HasNoEther() payable {
        require(msg.value == 0);
    }

     
    function() external {
    }

     
    function reclaimEther() external onlyOwner {
        assert(owner.send(this.balance));
    }
}

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract PricingStrategy is HasNoEther {
    using SafeMath for uint;

     
    uint256 public oneTokenInWei;

    address public crowdsaleAddress;

    function PricingStrategy(address _crowdsale) {
        crowdsaleAddress = _crowdsale;
    }

    modifier onlyCrowdsale() {
        require(msg.sender == crowdsaleAddress);
        _;
    }

     
    function calculatePrice(uint256 _value, uint256 _decimals) public constant returns (uint) {
        uint256 multiplier = 10 ** _decimals;
        uint256 weiAmount = _value.mul(multiplier);
        uint256 tokens = weiAmount.div(oneTokenInWei);
        return tokens;
    }

    function setTokenPriceInWei(uint _oneTokenInWei) onlyCrowdsale public returns (bool) {
        oneTokenInWei = _oneTokenInWei;
        return true;
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

contract RNTMultiSigWallet {
     
    event Confirmation(address indexed sender, uint indexed transactionId);

    event Revocation(address indexed sender, uint indexed transactionId);

    event Submission(uint indexed transactionId);

    event Execution(uint indexed transactionId);

    event ExecutionFailure(uint indexed transactionId);

    event Deposit(address indexed sender, uint value);

    event OwnerAddition(address indexed owner);

    event OwnerRemoval(address indexed owner);

    event RequirementChange(uint required);

    event Pause();

    event Unpause();

     
    uint constant public MAX_OWNER_COUNT = 10;

    uint constant public ADMINS_COUNT = 2;

     
    mapping(uint => WalletTransaction) public transactions;

    mapping(uint => mapping(address => bool)) public confirmations;

    mapping(address => bool) public isOwner;

    mapping(address => bool) public isAdmin;

    address[] public owners;

    address[] public admins;

    uint public required;

    uint public transactionCount;

    bool public paused = false;

    struct WalletTransaction {
        address sender;
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

     

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier adminExists(address admin) {
        require(isAdmin[admin]);
        _;
    }

    modifier adminDoesNotExist(address admin) {
        require(!isAdmin[admin]);
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != 0);
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        if (transactions[transactionId].executed)
            require(false);
        _;
    }

    modifier notNull(address _address) {
        require(_address != 0);
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        if (ownerCount > MAX_OWNER_COUNT
        || _required > ownerCount
        || _required == 0
        || ownerCount == 0) {
            require(false);
        }
        _;
    }

    modifier validAdminsCount(uint adminsCount) {
        require(adminsCount == ADMINS_COUNT);
        _;
    }

     
    function()
    whenNotPaused
    payable
    {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }

     
     
     
     
    function RNTMultiSigWallet(address[] _admins, uint _required)
    public
         
         
    {
        for (uint i = 0; i < _admins.length; i++) {
            require(_admins[i] != 0 && !isOwner[_admins[i]] && !isAdmin[_admins[i]]);
            isAdmin[_admins[i]] = true;
            isOwner[_admins[i]] = true;
        }

        admins = _admins;
        owners = _admins;
        required = _required;
    }

     
    function pause() adminExists(msg.sender) whenNotPaused public {
        paused = true;
        Pause();
    }

     
    function unpause() adminExists(msg.sender) whenPaused public {
        paused = false;
        Unpause();
    }

     
     
    function addOwner(address owner)
    public
    whenNotPaused
    adminExists(msg.sender)
    ownerDoesNotExist(owner)
    notNull(owner)
    validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        OwnerAddition(owner);
    }

     
     
    function removeOwner(address owner)
    public
    whenNotPaused
    adminExists(msg.sender)
    adminDoesNotExist(owner)
    ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i = 0; i < owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        OwnerRemoval(owner);
    }

     
     
     
    function replaceOwner(address owner, address newOwner)
    public
    whenNotPaused
    adminExists(msg.sender)
    adminDoesNotExist(owner)
    ownerExists(owner)
    ownerDoesNotExist(newOwner)
    {
        for (uint i = 0; i < owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        OwnerRemoval(owner);
        OwnerAddition(newOwner);
    }

     
     
    function changeRequirement(uint _required)
    public
    whenNotPaused
    adminExists(msg.sender)
    validRequirement(owners.length, _required)
    {
        required = _required;
        RequirementChange(_required);
    }

     
     
     
     
     
    function submitTransaction(address destination, uint value, bytes data)
    public
    whenNotPaused
    ownerExists(msg.sender)
    returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

     
     
    function confirmTransaction(uint transactionId)
    public
    whenNotPaused
    ownerExists(msg.sender)
    transactionExists(transactionId)
    notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

     
     
    function revokeConfirmation(uint transactionId)
    public
    whenNotPaused
    ownerExists(msg.sender)
    confirmed(transactionId, msg.sender)
    notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        Revocation(msg.sender, transactionId);
    }

     
     
    function executeTransaction(uint transactionId)
    public
    whenNotPaused
    ownerExists(msg.sender)
    confirmed(transactionId, msg.sender)
    notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            WalletTransaction storage walletTransaction = transactions[transactionId];
            walletTransaction.executed = true;
            if (walletTransaction.destination.call.value(walletTransaction.value)(walletTransaction.data))
                Execution(transactionId);
            else {
                ExecutionFailure(transactionId);
                walletTransaction.executed = false;
            }
        }
    }

     
     
     
    function isConfirmed(uint transactionId)
    public
    constant
    returns (bool)
    {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

     
     
     
     
     
     
    function addTransaction(address destination, uint value, bytes data)
    internal
    notNull(destination)
    returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = WalletTransaction({
            sender : msg.sender,
            destination : destination,
            value : value,
            data : data,
            executed : false
            });
        transactionCount += 1;
        Submission(transactionId);
    }

     
     
     
     
    function getConfirmationCount(uint transactionId)
    public
    constant
    returns (uint count)
    {
        for (uint i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

     
     
     
     
    function getTransactionCount(bool pending, bool executed)
    public
    constant
    returns (uint count)
    {
        for (uint i = 0; i < transactionCount; i++)
            if (pending && !transactions[i].executed
            || executed && transactions[i].executed)
                count += 1;
    }

     
     
    function getOwners()
    public
    constant
    returns (address[])
    {
        return owners;
    }

     
     
    function getAdmins()
    public
    constant
    returns (address[])
    {
        return admins;
    }

     
     
     
    function getConfirmations(uint transactionId)
    public
    constant
    returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

     
     
     
     
     
     
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
    public
    constant
    returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i = 0; i < transactionCount; i++)
            if (pending && !transactions[i].executed
            || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i = from; i < to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
}

contract RntPresaleEthereumDeposit is Pausable {
    using SafeMath for uint256;

    uint256 public overallTakenEther = 0;

    mapping(address => uint256) public receivedEther;

    struct Donator {
        address addr;
        uint256 donated;
    }

    Donator[] donators;

    RNTMultiSigWallet public wallet;

    function RntPresaleEthereumDeposit(address _walletAddress) {
        wallet = RNTMultiSigWallet(_walletAddress);
    }

    function updateDonator(address _address) internal {
        bool isFound = false;
        for (uint i = 0; i < donators.length; i++) {
            if (donators[i].addr == _address) {
                donators[i].donated = receivedEther[_address];
                isFound = true;
                break;
            }
        }
        if (!isFound) {
            donators.push(Donator(_address, receivedEther[_address]));
        }
    }

    function getDonatorsNumber() external constant returns (uint256) {
        return donators.length;
    }

    function getDonator(uint pos) external constant returns (address, uint256) {
        return (donators[pos].addr, donators[pos].donated);
    }

     
    function() whenNotPaused payable {
        wallet.transfer(msg.value);

        overallTakenEther = overallTakenEther.add(msg.value);
        receivedEther[msg.sender] = receivedEther[msg.sender].add(msg.value);

        updateDonator(msg.sender);
    }

    function receivedEtherFrom(address _from) whenNotPaused constant public returns (uint256) {
        return receivedEther[_from];
    }

    function myEther() whenNotPaused constant public returns (uint256) {
        return receivedEther[msg.sender];
    }
}

contract PresaleFinalizeAgent is HasNoEther {
    using SafeMath for uint256;

    RntPresaleEthereumDeposit public deposit;

    address public crowdsaleAddress;

    mapping(address => uint256) public tokensForAddress;

    uint256 public weiPerToken = 0;

    bool public sane = true;

    function PresaleFinalizeAgent(address _deposit, address _crowdsale){
        deposit = RntPresaleEthereumDeposit(_deposit);
        crowdsaleAddress = _crowdsale;
    }

    modifier onlyCrowdsale() {
        require(msg.sender == crowdsaleAddress);
        _;
    }

    function isSane() public constant returns (bool) {
        return sane;
    }

    function setCrowdsaleAddress(address _address) onlyOwner public {
        crowdsaleAddress = _address;
    }

    function finalizePresale(uint256 presaleTokens) onlyCrowdsale public {
        require(sane);
        uint256 overallEther = deposit.overallTakenEther();
        uint256 multiplier = 10 ** 18;
        overallEther = overallEther.mul(multiplier);
        weiPerToken = overallEther.div(presaleTokens);
        require(weiPerToken > 0);
        sane = false;
    }
}

contract IRntToken {
    uint256 public decimals = 18;

    uint256 public totalSupply = 1000000000 * (10 ** 18);

    string public name = "RNT Token";

    string public code = "RNT";


    function balanceOf() public constant returns (uint256 balance);

    function transfer(address _to, uint _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
}

contract RntCrowdsale is Pausable {
    using SafeMath for uint256;

    enum Status {Unknown, Presale, ICO, Finalized}  

    Status public currentStatus = Status.Unknown;

    bool public isPresaleStarted = false;

    bool public isPresaleFinalized = false;

    bool public isIcoStarted = false;

    bool public isIcoFinalized = false;

    uint256 public icoReceivedWei;

    uint256 public icoTokensSold;

    uint256 public icoInvestmentsCount = 0;

    mapping(address => uint256) public icoInvestments;

    mapping(address => uint256) public icoTokenTransfers;

    IRntToken public token;

    PricingStrategy public pricingStrategy;

    PresaleFinalizeAgent public presaleFinalizeAgent;

    RntPresaleEthereumDeposit public deposit;

    address public wallet;

    address public proxy;

    mapping(address => bool) public tokensAllocationAllowed;

    uint public presaleStartTime;

    uint public presaleEndTime;

    uint public icoStartTime;

    uint public icoEndTime;

     
    event Invested(address indexed investor, uint weiAmount, uint tokenAmount, bytes16 indexed customerId);

    event PresaleStarted(uint timestamp);

    event PresaleFinalized(uint timestamp);

    event IcoStarted(uint timestamp);

    event IcoFinalized(uint timestamp);

     
    event TokensPerWeiReceived(uint tokenPrice);

     
    event PresaleTokensClaimed(uint count);

    function RntCrowdsale(address _tokenAddress) {
        token = IRntToken(_tokenAddress);
    }

     
    modifier inStatus(Status status) {
        require(getCrowdsaleStatus() == status);
        _;
    }

     
    modifier canAllocateTokens {
        require(tokensAllocationAllowed[msg.sender] == true);
        _;
    }

     
    function allowAllocation(address _addr, bool _allow) onlyOwner external {
        tokensAllocationAllowed[_addr] = _allow;
    }

     
    function setPresaleFinalizeAgent(address _agentAddress) whenNotPaused onlyOwner external {
        presaleFinalizeAgent = PresaleFinalizeAgent(_agentAddress);
    }

     
    function setPricingStartegy(address _pricingStrategyAddress) whenNotPaused onlyOwner external {
        pricingStrategy = PricingStrategy(_pricingStrategyAddress);
    }

     
    function setMultiSigWallet(address _walletAddress) whenNotPaused onlyOwner external {
        wallet = _walletAddress;
    }


     
    function setBackendProxyBuyer(address _proxyAddress) whenNotPaused onlyOwner external {
        proxy = _proxyAddress;
    }

     
    function setPresaleEthereumDeposit(address _depositAddress) whenNotPaused onlyOwner external {
        deposit = RntPresaleEthereumDeposit(_depositAddress);
    }

     
    function getCrowdsaleStatus() constant public returns (Status) {
        return currentStatus;
    }

     
    function startPresale() whenNotPaused onlyOwner external {
        require(!isPresaleStarted);

        currentStatus = Status.Presale;
        isPresaleStarted = true;

        presaleStartTime = now;
        PresaleStarted(presaleStartTime);
    }

     
    function finalizePresale() whenNotPaused onlyOwner external {
        require(isPresaleStarted && !isPresaleFinalized);
        require(presaleFinalizeAgent.isSane());

        uint256 presaleSupply = token.totalSupply();

         
        presaleSupply = presaleSupply.div(5);

        presaleFinalizeAgent.finalizePresale(presaleSupply);
        uint tokenWei = presaleFinalizeAgent.weiPerToken();
        pricingStrategy.setTokenPriceInWei(tokenWei);
        TokensPerWeiReceived(tokenWei);

        require(tokenWei > 0);

        currentStatus = Status.Unknown;
        isPresaleFinalized = true;

        presaleEndTime = now;
        PresaleFinalized(presaleEndTime);
    }

     
    function startIco() whenNotPaused onlyOwner external {
        require(!isIcoStarted && isPresaleFinalized);

        currentStatus = Status.ICO;
        isIcoStarted = true;

        icoStartTime = now;
        IcoStarted(icoStartTime);
    }

     
    function finalizeIco() whenNotPaused onlyOwner external {
        require(!isIcoFinalized && isIcoStarted);

        currentStatus = Status.Finalized;
        isIcoFinalized = true;

        icoEndTime = now;
        IcoFinalized(icoEndTime);
    }


     
    function investInternal(address _receiver, bytes16 _customerUuid) private {
        uint weiAmount = msg.value;

        uint256 tokenAmount = pricingStrategy.calculatePrice(weiAmount, 18);

        require(tokenAmount != 0);

        if (icoInvestments[_receiver] == 0) {
             
            icoInvestmentsCount++;
        }
        icoInvestments[_receiver] = icoInvestments[_receiver].add(weiAmount);
        icoTokenTransfers[_receiver] = icoTokenTransfers[_receiver].add(tokenAmount);
        icoReceivedWei = icoReceivedWei.add(weiAmount);
        icoTokensSold = icoTokensSold.add(tokenAmount);

        assignTokens(owner, _receiver, tokenAmount);

         
        wallet.transfer(weiAmount);

         
        Invested(_receiver, weiAmount, tokenAmount, _customerUuid);
    }

     
    function allocateInternal(address _receiver, bytes16 _customerUuid, uint256 _weiAmount) private {
        uint256 tokenAmount = pricingStrategy.calculatePrice(_weiAmount, 18);

        require(tokenAmount != 0);

        if (icoInvestments[_receiver] == 0) {
             
            icoInvestmentsCount++;
        }
        icoInvestments[_receiver] = icoInvestments[_receiver].add(_weiAmount);
        icoTokenTransfers[_receiver] = icoTokenTransfers[_receiver].add(tokenAmount);
        icoReceivedWei = icoReceivedWei.add(_weiAmount);
        icoTokensSold = icoTokensSold.add(tokenAmount);

        assignTokens(owner, _receiver, tokenAmount);

         
        Invested(_receiver, _weiAmount, tokenAmount, _customerUuid);
    }

     
    function allocateTokens(address _receiver, bytes16 _customerUuid, uint256 _weiAmount) whenNotPaused canAllocateTokens public {
        allocateInternal(_receiver, _customerUuid, _weiAmount);
    }

     
    function invest(bytes16 _customerUuid) whenNotPaused inStatus(Status.ICO) public payable {
        investInternal(msg.sender, _customerUuid);
    }

     
    function claimPresaleTokens() whenNotPaused external {
        require(isPresaleFinalized == true);

        uint256 senderEther = deposit.receivedEtherFrom(msg.sender);
        uint256 multiplier = 10 ** 18;
        senderEther = senderEther.mul(multiplier);
        uint256 tokenWei = pricingStrategy.oneTokenInWei();
        uint256 tokensAmount = senderEther.div(tokenWei);

        require(tokensAmount > 0);
        token.transferFrom(owner, msg.sender, tokensAmount);
        PresaleTokensClaimed(tokensAmount);
    }

     
    function assignTokens(address _from, address _receiver, uint _tokenAmount) private {
        token.transferFrom(_from, _receiver, _tokenAmount);
    }
}