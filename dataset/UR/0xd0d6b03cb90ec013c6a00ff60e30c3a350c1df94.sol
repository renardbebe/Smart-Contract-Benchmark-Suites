 

pragma solidity ^0.4.24;

 
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

 
 
contract NamiMultiSigWallet {

    uint constant public MAX_OWNER_COUNT = 50;

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);

    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
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
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != 0);
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(!(ownerCount > MAX_OWNER_COUNT
            || _required > ownerCount
            || _required == 0
            || ownerCount == 0));
        _;
    }

     
    function() public payable {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

     
     
     
     
    constructor(address[] _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i = 0; i < _owners.length; i++) {
            require(!(isOwner[_owners[i]] || _owners[i] == 0));
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

     
     
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

     
     
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        emit OwnerRemoval(owner);
    }

     
     
     
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

     
     
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

     
     
     
     
     
    function submitTransaction(address destination, uint value, bytes data)
        public
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

     
     
    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

     
     
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

     
     
    function executeTransaction(uint transactionId)
        public
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
             
            transactions[transactionId].executed = true;
             
            if (transactions[transactionId].destination.call.value(transactions[transactionId].value)(transactions[transactionId].data)) {
                emit Execution(transactionId);
            } else {
                emit ExecutionFailure(transactionId);
                transactions[transactionId].executed = false;
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
        transactions[transactionId] = Transaction({
            destination: destination, 
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

     
     
     
     
    function getConfirmationCount(uint transactionId)
        public
        constant
        returns (uint count)
    {
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
        }
    }

     
     
     
     
    function getTransactionCount(bool pending, bool executed)
        public
        constant
        returns (uint count)
    {
        for (uint i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed)
                count += 1;
        }
    }

     
     
    function getOwners()
        public
        constant
        returns (address[])
    {
        return owners;
    }

     
     
     
    function getConfirmations(uint transactionId)
        public
        constant
        returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
    }

     
     
     
     
     
     
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        constant
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        }
        _transactionIds = new uint[](to - from);
        for (i = from; i < to; i++) {
            _transactionIds[i - from] = transactionIdsTemp[i];
        }
    }
}
contract PresaleToken {
    mapping (address => uint256) public balanceOf;
    function burnTokens(address _owner) public;
}
  
 
  
 
contract ERC223ReceivingContract {
 
    function tokenFallback(address _from, uint _value, bytes _data) public returns (bool success);
    function tokenFallbackBuyer(address _from, uint _value, address _buyer) public returns (bool success);
    function tokenFallbackExchange(address _from, uint _value, uint _price) public returns (bool success);
}
 
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract NamiCrowdSale {
    using SafeMath for uint256;

     
     
    constructor(address _escrow, address _namiMultiSigWallet, address _namiPresale) public {
        require(_namiMultiSigWallet != 0x0);
        escrow = _escrow;
        namiMultiSigWallet = _namiMultiSigWallet;
        namiPresale = _namiPresale;
    }


     

    string public name = "Nami ICO";
    string public  symbol = "NAC";
    uint   public decimals = 18;

    bool public TRANSFERABLE = false;  

    uint public constant TOKEN_SUPPLY_LIMIT = 1000000000 * (1 ether / 1 wei);
    
    uint public binary = 0;

     

    enum Phase {
        Created,
        Running,
        Paused,
        Migrating,
        Migrated
    }

    Phase public currentPhase = Phase.Created;
    uint public totalSupply = 0;  

     
     
    address public escrow;

     
    address public namiMultiSigWallet;

     
    address public namiPresale;

     
    address public crowdsaleManager;
    
     
    address public binaryAddress;
    
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    modifier onlyCrowdsaleManager() {
        require(msg.sender == crowdsaleManager); 
        _; 
    }

    modifier onlyEscrow() {
        require(msg.sender == escrow);
        _;
    }
    
    modifier onlyTranferable() {
        require(TRANSFERABLE);
        _;
    }
    
    modifier onlyNamiMultisig() {
        require(msg.sender == namiMultiSigWallet);
        _;
    }
    
     

    event LogBuy(address indexed owner, uint value);
    event LogBurn(address indexed owner, uint value);
    event LogPhaseSwitch(Phase newPhase);
     
    event LogMigrate(address _from, address _to, uint256 amount);
     
    event Transfer(address indexed from, address indexed to, uint256 value);

     

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
     
    function transferForTeam(address _to, uint256 _value) public
        onlyEscrow
    {
        _transfer(msg.sender, _to, _value);
    }
    
     
    function transfer(address _to, uint256 _value) public
        onlyTranferable
    {
        _transfer(msg.sender, _to, _value);
    }
    
        
    function transferFrom(address _from, address _to, uint256 _value) 
        public
        onlyTranferable
        returns (bool success)
    {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        onlyTranferable
        returns (bool success) 
    {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        onlyTranferable
        returns (bool success) 
    {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function changeTransferable () public
        onlyEscrow
    {
        TRANSFERABLE = !TRANSFERABLE;
    }
    
     
    function changeEscrow(address _escrow) public
        onlyNamiMultisig
    {
        require(_escrow != 0x0);
        escrow = _escrow;
    }
    
     
    function changeBinary(uint _binary)
        public
        onlyEscrow
    {
        binary = _binary;
    }
    
     
    function changeBinaryAddress(address _binaryAddress)
        public
        onlyEscrow
    {
        require(_binaryAddress != 0x0);
        binaryAddress = _binaryAddress;
    }
    
     
    function getPrice() public view returns (uint price) {
        if (now < 1517443200) {
             
            return 3450;
        } else if (1517443200 < now && now <= 1518048000) {
             
            return 2400;
        } else if (1518048000 < now && now <= 1518652800) {
             
            return 2300;
        } else if (1518652800 < now && now <= 1519257600) {
             
            return 2200;
        } else if (1519257600 < now && now <= 1519862400) {
             
            return 2100;
        } else if (1519862400 < now && now <= 1520467200) {
             
            return 2000;
        } else if (1520467200 < now && now <= 1521072000) {
             
            return 1900;
        } else if (1521072000 < now && now <= 1521676800) {
             
            return 1800;
        } else if (1521676800 < now && now <= 1522281600) {
             
            return 1700;
        } else {
            return binary;
        }
    }


    function() payable public {
        buy(msg.sender);
    }
    
    
    function buy(address _buyer) payable public {
         
        require(currentPhase == Phase.Running);
         
        require(now <= 1522281600 || msg.sender == binaryAddress);
        require(msg.value != 0);
        uint newTokens = msg.value * getPrice();
        require (totalSupply + newTokens < TOKEN_SUPPLY_LIMIT);
         
        balanceOf[_buyer] = balanceOf[_buyer].add(newTokens);
         
        totalSupply = totalSupply.add(newTokens);
        emit LogBuy(_buyer,newTokens);
        emit Transfer(this,_buyer,newTokens);
    }
    

     
     
    function burnTokens(address _owner) public
        onlyCrowdsaleManager
    {
         
        require(currentPhase == Phase.Migrating);

        uint tokens = balanceOf[_owner];
        require(tokens != 0);
        balanceOf[_owner] = 0;
        totalSupply -= tokens;
        emit LogBurn(_owner, tokens);
        emit Transfer(_owner, crowdsaleManager, tokens);

         
        if (totalSupply == 0) {
            currentPhase = Phase.Migrated;
            emit LogPhaseSwitch(Phase.Migrated);
        }
    }


     
    function setPresalePhase(Phase _nextPhase) public
        onlyEscrow
    {
        bool canSwitchPhase
            =  (currentPhase == Phase.Created && _nextPhase == Phase.Running)
            || (currentPhase == Phase.Running && _nextPhase == Phase.Paused)
                 
            || ((currentPhase == Phase.Running || currentPhase == Phase.Paused)
                && _nextPhase == Phase.Migrating
                && crowdsaleManager != 0x0)
            || (currentPhase == Phase.Paused && _nextPhase == Phase.Running)
                 
            || (currentPhase == Phase.Migrating && _nextPhase == Phase.Migrated
                && totalSupply == 0);

        require(canSwitchPhase);
        currentPhase = _nextPhase;
        emit LogPhaseSwitch(_nextPhase);
    }


    function withdrawEther(uint _amount) public
        onlyEscrow
    {
        require(namiMultiSigWallet != 0x0);
         
        if (address(this).balance > 0) {
            namiMultiSigWallet.transfer(_amount);
        }
    }
    
    function safeWithdraw(address _withdraw, uint _amount) public
        onlyEscrow
    {
        NamiMultiSigWallet namiWallet = NamiMultiSigWallet(namiMultiSigWallet);
        if (namiWallet.isOwner(_withdraw)) {
            _withdraw.transfer(_amount);
        }
    }


    function setCrowdsaleManager(address _mgr) public
        onlyEscrow
    {
         
        require(currentPhase != Phase.Migrating);
        crowdsaleManager = _mgr;
    }

     
    function _migrateToken(address _from, address _to)
        internal
    {
        PresaleToken presale = PresaleToken(namiPresale);
        uint256 newToken = presale.balanceOf(_from);
        require(newToken > 0);
         
        presale.burnTokens(_from);
         
        balanceOf[_to] = balanceOf[_to].add(newToken);
         
        totalSupply = totalSupply.add(newToken);
        emit LogMigrate(_from, _to, newToken);
        emit Transfer(this,_to,newToken);
    }

     
    function migrateToken(address _from, address _to) public
        onlyEscrow
    {
        _migrateToken(_from, _to);
    }

     
    function migrateForInvestor() public {
        _migrateToken(msg.sender, msg.sender);
    }

     
    
     
    event TransferToBuyer(address indexed _from, address indexed _to, uint _value, address indexed _seller);
    event TransferToExchange(address indexed _from, address indexed _to, uint _value, uint _price);
    
    
     
     
    function transferToExchange(address _to, uint _value, uint _price) public {
        uint codeLength;
        
        assembly {
            codeLength := extcodesize(_to)
        }
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender,_to,_value);
        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallbackExchange(msg.sender, _value, _price);
            emit TransferToExchange(msg.sender, _to, _value, _price);
        }
    }
    
     
     
    function transferToBuyer(address _to, uint _value, address _buyer) public {
        uint codeLength;
        
        assembly {
            codeLength := extcodesize(_to)
        }
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender,_to,_value);
        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallbackBuyer(msg.sender, _value, _buyer);
            emit TransferToBuyer(msg.sender, _to, _value, _buyer);
        }
    }
 
}
contract NamiTrade{
    using SafeMath for uint256;

    uint public minNac = 0;  
    uint public minWithdraw =  2000 * 10**18;
    uint public maxWithdraw = 50000 * 10**18;  

    constructor(address _escrow, address _namiMultiSigWallet, address _namiAddress) public {
        require(_namiMultiSigWallet != 0x0);
        escrow = _escrow;
        namiMultiSigWallet = _namiMultiSigWallet;
        NamiAddr = _namiAddress;
         
        balanceOf[_escrow] = 7850047931491270769372792;
        totalSupply = 7850047931491270769372792;
    }


     
    uint public NetfBalance;
     


     
     
    address public escrow;

     
    address public namiMultiSigWallet;

     
    address public NamiAddr;

    modifier onlyEscrow() {
        require(msg.sender == escrow);
        _;
    }

    modifier onlyNami {
        require(msg.sender == NamiAddr);
        _;
    }

    modifier onlyNamiMultisig {
        require(msg.sender == namiMultiSigWallet);
        _;
    }

    modifier onlyController {
        require(isController[msg.sender] == true);
        _;
    }


     
    mapping(address => bool) public isController;



     
     
    function setController(address _controller)
    public
    onlyEscrow
    {
        require(!isController[_controller]);
        isController[_controller] = true;
    }

     
    function removeController(address _controller)
    public
    onlyEscrow
    {
        require(isController[_controller]);
        isController[_controller] = false;
    }


     
    function changeMinNac(uint _minNAC) public
    onlyEscrow
    {
        require(_minNAC != 0);
        minNac = _minNAC;
    }

     
    function changeEscrow(address _escrow) public
    onlyNamiMultisig
    {
        require(_escrow != 0x0);
        escrow = _escrow;
    }


     
    function changeMinWithdraw(uint _minWithdraw) public
    onlyEscrow
    {
        require(_minWithdraw != 0);
        minWithdraw = _minWithdraw;
    }

    function changeMaxWithdraw(uint _maxNac) public
    onlyEscrow
    {
        require(_maxNac != 0);
        maxWithdraw = _maxNac;
    }

     
     
    function withdrawEther(uint _amount) public
    onlyEscrow
    {
        require(namiMultiSigWallet != 0x0);
         
        if (address(this).balance > 0) {
            namiMultiSigWallet.transfer(_amount);
        }
    }


     
     
    function withdrawNac(uint _amount) public
    onlyEscrow
    {
        require(namiMultiSigWallet != 0x0);
         
        NamiCrowdSale namiToken = NamiCrowdSale(NamiAddr);
        if (namiToken.balanceOf(address(this)) > 0) {
            namiToken.transfer(namiMultiSigWallet, _amount);
        }
    }

     
    event Deposit(address indexed user, uint amount, uint timeDeposit);
    event Withdraw(address indexed user, uint amount, uint timeWithdraw);

    event PlaceBuyFciOrder(address indexed investor, uint amount, uint timePlaceOrder);
    event PlaceSellFciOrder(address indexed investor, uint amount, uint timePlaceOrder);
    event InvestToNLF(address indexed investor, uint amount, uint timeInvest);

     
     
     
    string public name = "Nami Trade";
    string public symbol = "FCI";
    uint8 public decimals = 18;

    uint256 public totalSupply;

     
    bool public isPause;

     
    uint256 public timeExpires;

     
    uint public fciDecimals = 1000000;
    uint256 public priceFci;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event BuyFci(address investor, uint256 valueNac, uint256 valueFci, uint timeBuyFci);
    event SellFci(address investor, uint256 valueNac, uint256 valueFci, uint timeSellFci);
    event WithdrawRound(address investor, uint256 valueNac, uint timeWithdraw);
    
    modifier onlyRunning {
        require(isPause == false);
        _;
    }


     
    function addNacToNetf(uint _valueNac) public onlyController {
        NetfBalance = NetfBalance.add(_valueNac);
    }


     
    function removeNacFromNetf(uint _valueNac) public onlyController {
        NetfBalance = NetfBalance.sub(_valueNac);
    }

     
     
    function changePause() public onlyController {
        isPause = !isPause;
    }

     
    function updatePriceFci(uint _price, uint _timeExpires) onlyController public {
        require(now > timeExpires);
        priceFci = _price;
        timeExpires = _timeExpires;
    }

     
    function buyFci(address _buyer, uint _valueNac) onlyController public {
         
        require(isPause == false && now < timeExpires);
         
        require(_buyer != 0x0);
        require( _valueNac * fciDecimals > priceFci);
        uint fciReceive = (_valueNac.mul(fciDecimals))/priceFci;

         
        balanceOf[_buyer] = balanceOf[_buyer].add(fciReceive);
        totalSupply = totalSupply.add(fciReceive);
        NetfBalance = NetfBalance.add(_valueNac);

        emit Transfer(address(this), _buyer, fciReceive);
        emit BuyFci(_buyer, _valueNac, fciReceive, now);
    }


     
    function placeSellFciOrder(uint _valueFci) onlyRunning public {
        require(balanceOf[msg.sender] >= _valueFci && _valueFci > 0);
        _transfer(msg.sender, address(this), _valueFci);
        emit PlaceSellFciOrder(msg.sender, _valueFci, now);
    }

     
    function sellFci(address _seller, uint _valueFci) onlyController public {
         
        require(isPause == false && now < timeExpires);
         
        require(_seller != 0x0);
        require(_valueFci * priceFci > fciDecimals);
        uint nacReturn = (_valueFci.mul(priceFci))/fciDecimals;

         
        balanceOf[address(this)] = balanceOf[address(this)].sub(_valueFci);
        totalSupply = totalSupply.sub(_valueFci);

         
        NetfBalance = NetfBalance.sub(nacReturn);

         
        NamiCrowdSale namiToken = NamiCrowdSale(NamiAddr);
        namiToken.transfer(_seller, nacReturn);

        emit SellFci(_seller, nacReturn, _valueFci, now);
    }

     
    struct ShareHolderNETF {
        uint stake;
        bool isWithdrawn;
    }

    struct RoundNetfRevenue {
        bool isOpen;
        uint currentNAC;
        uint totalFci;
        bool withdrawable;
    }

    uint public currentNetfRound;

    mapping (uint => RoundNetfRevenue) public NetfRevenue;
    mapping (uint => mapping(address => ShareHolderNETF)) public usersNETF;

     
     
    function openNetfRevenueRound(uint _roundIndex) onlyController public {
        require(NetfRevenue[_roundIndex].isOpen == false);
        currentNetfRound = _roundIndex;
        NetfRevenue[_roundIndex].isOpen = true;
    }

     
    function depositNetfRevenue(uint _valueNac) onlyController public {
        require(NetfRevenue[currentNetfRound].isOpen == true && NetfRevenue[currentNetfRound].withdrawable == false);
        NetfRevenue[currentNetfRound].currentNAC = NetfRevenue[currentNetfRound].currentNAC.add(_valueNac);
    }

     
    function withdrawNetfRevenue(uint _valueNac) onlyController public {
        require(NetfRevenue[currentNetfRound].isOpen == true && NetfRevenue[currentNetfRound].withdrawable == false);
        NetfRevenue[currentNetfRound].currentNAC = NetfRevenue[currentNetfRound].currentNAC.sub(_valueNac);
    }

     

     
    function latchTotalFci(uint _roundIndex) onlyController public {
        require(isPause == true && NetfRevenue[_roundIndex].isOpen == true);
        require(NetfRevenue[_roundIndex].withdrawable == false);
        NetfRevenue[_roundIndex].totalFci = totalSupply;
    }

    function latchFciUserController(uint _roundIndex, address _investor) onlyController public {
        require(isPause == true && NetfRevenue[_roundIndex].isOpen == true);
        require(NetfRevenue[_roundIndex].withdrawable == false);
        require(balanceOf[_investor] > 0);
        usersNETF[_roundIndex][_investor].stake = balanceOf[_investor];
    }

     
    function latchFciUser(uint _roundIndex) public {
        require(isPause == true && NetfRevenue[_roundIndex].isOpen == true);
        require(NetfRevenue[_roundIndex].withdrawable == false);
        require(balanceOf[msg.sender] > 0);
        usersNETF[_roundIndex][msg.sender].stake = balanceOf[msg.sender];
    }

     
    function changeWithdrawableNetfRe(uint _roundIndex) onlyController public {
        require(isPause == true && NetfRevenue[_roundIndex].isOpen == true);
        NetfRevenue[_roundIndex].withdrawable = true;
        isPause = false;
    }

     
     
    function withdrawNacNetfReController(uint _roundIndex, address _investor) onlyController public {
        require(NetfRevenue[_roundIndex].withdrawable == true && isPause == false && _investor != 0x0);
        require(usersNETF[_roundIndex][_investor].stake > 0 && usersNETF[_roundIndex][_investor].isWithdrawn == false);
        require(NetfRevenue[_roundIndex].totalFci > 0);
         
        uint nacReturn = ( NetfRevenue[_roundIndex].currentNAC.mul(usersNETF[_roundIndex][_investor].stake) ) / NetfRevenue[_roundIndex].totalFci;
        NamiCrowdSale namiToken = NamiCrowdSale(NamiAddr);
        namiToken.transfer(_investor, nacReturn);

        usersNETF[_roundIndex][_investor].isWithdrawn = true;
    }

     
    function withdrawNacNetfRe(uint _roundIndex) public {
        require(NetfRevenue[_roundIndex].withdrawable == true && isPause == false);
        require(usersNETF[_roundIndex][msg.sender].stake > 0 && usersNETF[_roundIndex][msg.sender].isWithdrawn == false);
        require(NetfRevenue[_roundIndex].totalFci > 0);
         
        uint nacReturn = ( NetfRevenue[_roundIndex].currentNAC.mul(usersNETF[_roundIndex][msg.sender].stake) ) / NetfRevenue[_roundIndex].totalFci;
        NamiCrowdSale namiToken = NamiCrowdSale(NamiAddr);
        namiToken.transfer(msg.sender, nacReturn);

        usersNETF[_roundIndex][msg.sender].isWithdrawn = true;
    }

     
     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value >= balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public onlyRunning {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public onlyRunning returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public onlyRunning
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    public onlyRunning
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
     
     



     
     
     
    uint public currentRound = 1;
    uint public currentSubRound = 1;

    struct shareHolderNLF {
        uint fciNLF;
        bool isWithdrawnRound;
    }

    struct SubRound {
        uint totalNacInSubRound;
        bool isOpen;
        bool isCloseNacPool;
    }

    struct Round {
        bool isOpen;
        bool isActivePool;
        bool withdrawable;
        uint currentNAC;
        uint finalNAC;
    }

     
    mapping(uint => Round) public NLFunds;
    mapping(uint => mapping(address => mapping(uint => bool))) public isWithdrawnSubRoundNLF;
    mapping(uint => mapping(uint => SubRound)) public listSubRoundNLF;
    mapping(uint => mapping(address => shareHolderNLF)) public membersNLF;


    event ActivateRound(uint RoundIndex, uint TimeActive);
    event ActivateSubRound(uint RoundIndex, uint TimeActive);
     
     
    function activateRound(uint _roundIndex)
    onlyEscrow
    public
    {
         
        require(NLFunds[_roundIndex].isOpen == false);
        NLFunds[_roundIndex].isOpen = true;
        currentRound = _roundIndex;
        emit ActivateRound(_roundIndex, now);
    }

     
     
    function deactivateRound(uint _roundIndex)
    onlyEscrow
    public
    {
         
        require(NLFunds[_roundIndex].isOpen == true);
        NLFunds[_roundIndex].isActivePool = true;
        NLFunds[_roundIndex].isOpen = false;
        NLFunds[_roundIndex].finalNAC = NLFunds[_roundIndex].currentNAC;
    }

     
    function activateSubRound(uint _subRoundIndex)
    onlyController
    public
    {
         
        require(NLFunds[currentRound].isOpen == false && NLFunds[currentRound].isActivePool == true);
         
        require(listSubRoundNLF[currentRound][_subRoundIndex].isOpen == false);
         
        currentSubRound = _subRoundIndex;
        require(listSubRoundNLF[currentRound][_subRoundIndex].isCloseNacPool == false);

        listSubRoundNLF[currentRound][_subRoundIndex].isOpen = true;
        emit ActivateSubRound(_subRoundIndex, now);
    }


     
    function depositToSubRound(uint _value)
    onlyController
    public
    {
         
        require(currentSubRound != 0);
        require(listSubRoundNLF[currentRound][currentSubRound].isOpen == true);
        require(listSubRoundNLF[currentRound][currentSubRound].isCloseNacPool == false);

         
        listSubRoundNLF[currentRound][currentSubRound].totalNacInSubRound = listSubRoundNLF[currentRound][currentSubRound].totalNacInSubRound.add(_value);
    }


     
    function withdrawFromSubRound(uint _value)
    onlyController
    public
    {
         
        require(currentSubRound != 0);
        require(listSubRoundNLF[currentRound][currentSubRound].isOpen == true);
        require(listSubRoundNLF[currentRound][currentSubRound].isCloseNacPool == false);

         
        listSubRoundNLF[currentRound][currentSubRound].totalNacInSubRound = listSubRoundNLF[currentRound][currentSubRound].totalNacInSubRound.sub(_value);
    }


     
    function closeDepositSubRound()
    onlyController
    public
    {
        require(listSubRoundNLF[currentRound][currentSubRound].isOpen == true);
        require(listSubRoundNLF[currentRound][currentSubRound].isCloseNacPool == false);

        listSubRoundNLF[currentRound][currentSubRound].isCloseNacPool = true;
    }


     
    function withdrawSubRound(uint _roundIndex, uint _subRoundIndex) public {
         
        require(listSubRoundNLF[_roundIndex][_subRoundIndex].isCloseNacPool == true);

         
        require(isWithdrawnSubRoundNLF[_roundIndex][msg.sender][_subRoundIndex] == false);

         
        require(membersNLF[_roundIndex][msg.sender].fciNLF > 0);

         
        NamiCrowdSale namiToken = NamiCrowdSale(NamiAddr);

        uint nacReturn = (listSubRoundNLF[_roundIndex][_subRoundIndex].totalNacInSubRound.mul(membersNLF[_roundIndex][msg.sender].fciNLF)).div(NLFunds[_roundIndex].finalNAC);
        namiToken.transfer(msg.sender, nacReturn);

        isWithdrawnSubRoundNLF[_roundIndex][msg.sender][_subRoundIndex] = true;
    }


     
    function addNacToNLF(uint _value) public onlyController {
        require(NLFunds[currentRound].isActivePool == true);
        require(NLFunds[currentRound].withdrawable == false);

        NLFunds[currentRound].currentNAC = NLFunds[currentRound].currentNAC.add(_value);
    }

     

    function removeNacFromNLF(uint _value) public onlyController {
        require(NLFunds[currentRound].isActivePool == true);
        require(NLFunds[currentRound].withdrawable == false);

        NLFunds[currentRound].currentNAC = NLFunds[currentRound].currentNAC.sub(_value);
    }

     
    function changeWithdrawableRound(uint _roundIndex)
    public
    onlyEscrow
    {
        require(NLFunds[_roundIndex].isActivePool == true);
        require(NLFunds[_roundIndex].withdrawable == false && NLFunds[_roundIndex].isOpen == false);

        NLFunds[_roundIndex].withdrawable = true;
    }


     
    function _withdrawRound(uint _roundIndex, address _investor) internal {
        require(NLFunds[_roundIndex].withdrawable == true);
        require(membersNLF[_roundIndex][_investor].isWithdrawnRound == false);
        require(membersNLF[_roundIndex][_investor].fciNLF > 0);

        NamiCrowdSale namiToken = NamiCrowdSale(NamiAddr);
        uint nacReturn = NLFunds[_roundIndex].currentNAC.mul(membersNLF[_roundIndex][_investor].fciNLF).div(NLFunds[_roundIndex].finalNAC);
        namiToken.transfer(msg.sender, nacReturn);

         
        membersNLF[_roundIndex][_investor].isWithdrawnRound = true;
        membersNLF[_roundIndex][_investor].fciNLF = 0;
        emit WithdrawRound(_investor, nacReturn, now);
    }

     
    function withdrawRound(uint _roundIndex) public {
        _withdrawRound(_roundIndex, msg.sender);
    }

    function withdrawRoundController(uint _roundIndex, address _investor) public onlyController {
        _withdrawRound(_roundIndex, _investor);
    }



     
    function tokenFallbackExchange(address _from, uint _value, uint _choose) onlyNami public returns (bool success) {
        require(_choose <= 2);
        if (_choose == 0) {
             
            require(_value >= minNac);
            emit Deposit(_from, _value, now);
        } else if(_choose == 1) {
            require(_value >= minNac && NLFunds[currentRound].isOpen == true);
             
            membersNLF[currentRound][_from].fciNLF = membersNLF[currentRound][_from].fciNLF.add(_value);
            NLFunds[currentRound].currentNAC = NLFunds[currentRound].currentNAC.add(_value);

            emit InvestToNLF(_from, _value, now);
        } else if(_choose == 2) {
             
            require(_value >= minNac);  
            emit PlaceBuyFciOrder(_from, _value, now);
        }
        return true;
    }


     
     
     

     
    function withdrawToken(address _account, uint _amount)
    public
    onlyController
    {
        require(_amount >= minWithdraw && _amount <= maxWithdraw);
        NamiCrowdSale namiToken = NamiCrowdSale(NamiAddr);

        uint previousBalances = namiToken.balanceOf(address(this));
        require(previousBalances >= _amount);

         
        namiToken.transfer(_account, _amount);

         
        emit Withdraw(_account, _amount, now);
        assert(previousBalances >= namiToken.balanceOf(address(this)));
    }


}