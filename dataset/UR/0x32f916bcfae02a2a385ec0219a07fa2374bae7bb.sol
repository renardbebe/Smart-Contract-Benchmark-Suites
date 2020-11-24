 

pragma solidity ^0.4.18;
 
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

 
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract NamiCrowdSale {
    using SafeMath for uint256;

     
     
    function NamiCrowdSale(address _escrow, address _namiMultiSigWallet, address _namiPresale) public {
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
        Transfer(_from, _to, _value);
         
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
        LogBuy(_buyer,newTokens);
        Transfer(this,_buyer,newTokens);
    }
    

     
     
    function burnTokens(address _owner) public
        onlyCrowdsaleManager
    {
         
        require(currentPhase == Phase.Migrating);

        uint tokens = balanceOf[_owner];
        require(tokens != 0);
        balanceOf[_owner] = 0;
        totalSupply -= tokens;
        LogBurn(_owner, tokens);
        Transfer(_owner, crowdsaleManager, tokens);

         
        if (totalSupply == 0) {
            currentPhase = Phase.Migrated;
            LogPhaseSwitch(Phase.Migrated);
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
        LogPhaseSwitch(_nextPhase);
    }


    function withdrawEther(uint _amount) public
        onlyEscrow
    {
        require(namiMultiSigWallet != 0x0);
         
        if (this.balance > 0) {
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
        LogMigrate(_from, _to, newToken);
        Transfer(this,_to,newToken);
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
        Transfer(msg.sender,_to,_value);
        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallbackExchange(msg.sender, _value, _price);
            TransferToExchange(msg.sender, _to, _value, _price);
        }
    }
    
     
     
    function transferToBuyer(address _to, uint _value, address _buyer) public {
        uint codeLength;
        
        assembly {
            codeLength := extcodesize(_to)
        }
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(msg.sender,_to,_value);
        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallbackBuyer(msg.sender, _value, _buyer);
            TransferToBuyer(msg.sender, _to, _value, _buyer);
        }
    }
 
}


 
contract BinaryOption {
     
     
    address public namiCrowdSaleAddr;
    address public escrow;
    
     
    address public namiMultiSigWallet;
    
    Session public session;
    uint public timeInvestInMinute = 30;
    uint public timeOneSession = 180;
    uint public sessionId = 1;
    uint public rate = 190;
    uint public constant MAX_INVESTOR = 20;
     
    event SessionOpen(uint timeOpen, uint indexed sessionId);
    event InvestClose(uint timeInvestClose, uint priceOpen, uint indexed sessionId);
    event Invest(address indexed investor, bool choose, uint amount, uint timeInvest, uint indexed sessionId);
    event SessionClose(uint timeClose, uint indexed sessionId, uint priceClose, uint nacPrice, uint rate);

    event Deposit(address indexed sender, uint value);
     
    function() public payable {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }
     
     
     
     
     
     
     
     
     
    struct Session {
        uint priceOpen;
        uint priceClose;
        uint timeOpen;
        bool isReset;
        bool isOpen;
        bool investOpen;
        uint investorCount;
        mapping(uint => address) investor;
        mapping(uint => bool) win;
        mapping(uint => uint) amountInvest;
        mapping(address=> uint) investedSession;
    }
    
    function BinaryOption(address _namiCrowdSale, address _escrow, address _namiMultiSigWallet) public {
        require(_namiCrowdSale != 0x0 && _escrow != 0x0);
        namiCrowdSaleAddr = _namiCrowdSale;
        escrow = _escrow;
        namiMultiSigWallet = _namiMultiSigWallet;
    }
    
    
    modifier onlyEscrow() {
        require(msg.sender==escrow);
        _;
    }
    
        
    modifier onlyNamiMultisig() {
        require(msg.sender == namiMultiSigWallet);
        _;
    }
    
     
    function changeEscrow(address _escrow) public
        onlyNamiMultisig
    {
        require(_escrow != 0x0);
        escrow = _escrow;
    }
    
     
     
    function changeTimeInvest(uint _timeInvest)
        public
        onlyEscrow
    {
        require(!session.isOpen && _timeInvest < timeOneSession);
        timeInvestInMinute = _timeInvest;
    }
    
     
     
     
    function changeRate(uint _rate)
        public
        onlyEscrow
    {
        require(100 < _rate && _rate < 200 && !session.isOpen);
        rate = _rate;
    }
    
    function changeTimeOneSession(uint _timeOneSession) 
        public
        onlyEscrow
    {
        require(!session.isOpen && _timeOneSession > timeInvestInMinute);
        timeOneSession = _timeOneSession;
    }
    
     
     
    function withdrawEther(uint _amount) public
        onlyEscrow
    {
        require(namiMultiSigWallet != 0x0);
         
        if (this.balance > 0) {
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
    
     
     
     
    function getInvestors()
        public
        view
        returns (address[20])
    {
        address[20] memory listInvestor;
        for (uint i = 0; i < MAX_INVESTOR; i++) {
            listInvestor[i] = session.investor[i];
        }
        return listInvestor;
    }
    
    function getChooses()
        public
        view
        returns (bool[20])
    {
        bool[20] memory listChooses;
        for (uint i = 0; i < MAX_INVESTOR; i++) {
            listChooses[i] = session.win[i];
        }
        return listChooses;
    }
    
    function getAmount()
        public
        view
        returns (uint[20])
    {
        uint[20] memory listAmount;
        for (uint i = 0; i < MAX_INVESTOR; i++) {
            listAmount[i] = session.amountInvest[i];
        }
        return listAmount;
    }
    
     
     
    function resetSession()
        public
        onlyEscrow
    {
        require(!session.isReset && !session.isOpen);
        session.priceOpen = 0;
        session.priceClose = 0;
        session.isReset = true;
        session.isOpen = false;
        session.investOpen = false;
        session.investorCount = 0;
        for (uint i = 0; i < MAX_INVESTOR; i++) {
            session.investor[i] = 0x0;
            session.win[i] = false;
            session.amountInvest[i] = 0;
        }
    }
    
     
    function openSession ()
        public
        onlyEscrow
    {
        require(session.isReset && !session.isOpen);
        session.isReset = false;
         
        session.investOpen = true;
        session.timeOpen = now;
        session.isOpen = true;
        SessionOpen(now, sessionId);
    }
    
     
     
    function invest (bool _choose)
        public
        payable
    {
        require(msg.value >= 100000000000000000 && session.investOpen);  
        require(now < (session.timeOpen + timeInvestInMinute * 1 minutes));
        require(session.investorCount < MAX_INVESTOR && session.investedSession[msg.sender] != sessionId);
        session.investor[session.investorCount] = msg.sender;
        session.win[session.investorCount] = _choose;
        session.amountInvest[session.investorCount] = msg.value;
        session.investorCount += 1;
        session.investedSession[msg.sender] = sessionId;
        Invest(msg.sender, _choose, msg.value, now, sessionId);
    }
    
     
     
    function closeInvest (uint _priceOpen) 
        public
        onlyEscrow
    {
        require(_priceOpen != 0 && session.investOpen);
        require(now > (session.timeOpen + timeInvestInMinute * 1 minutes));
        session.investOpen = false;
        session.priceOpen = _priceOpen;
        InvestClose(now, _priceOpen, sessionId);
    }
    
     
     
     
     
    function getEtherToBuy (uint _ether, uint _rate, bool _status)
        public
        pure
        returns (uint)
    {
        if (_status) {
            return _ether * _rate / 100;
        } else {
            return _ether * (200 - _rate) / 100;
        }
    }

     
     
    function closeSession (uint _priceClose)
        public
        onlyEscrow
    {
        require(_priceClose != 0 && now > (session.timeOpen + timeOneSession * 1 minutes));
        require(!session.investOpen && session.isOpen);
        session.priceClose = _priceClose;
        bool result = (_priceClose>session.priceOpen)?true:false;
        uint etherToBuy;
        NamiCrowdSale namiContract = NamiCrowdSale(namiCrowdSaleAddr);
        uint price = namiContract.getPrice();
        for (uint i = 0; i < session.investorCount; i++) {
            if (session.win[i]==result) {
                etherToBuy = getEtherToBuy(session.amountInvest[i], rate, true);
            } else {
                etherToBuy = getEtherToBuy(session.amountInvest[i], rate, false);
            }
            namiContract.buy.value(etherToBuy)(session.investor[i]);
             
            session.investor[i] = 0x0;
            session.win[i] = false;
            session.amountInvest[i] = 0;
        }
        session.isOpen = false;
        SessionClose(now, sessionId, _priceClose, price, rate);
        sessionId += 1;
        
         
         
        session.priceOpen = 0;
        session.priceClose = 0;
        session.isReset = true;
        session.investOpen = false;
        session.investorCount = 0;
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


  

contract NamiExchange {
    using SafeMath for uint;
    
    function NamiExchange(address _namiAddress) public {
        NamiAddr = _namiAddress;
    }

    event UpdateBid(address owner, uint price, uint balance);
    event UpdateAsk(address owner, uint price, uint volume);

    
    mapping(address => OrderBid) public bid;
    mapping(address => OrderAsk) public ask;
    string public name = "NacExchange";
    
     
    address NamiAddr;
    
     
    uint public price = 1;
    uint public etherBalance=0;
    uint public nacBalance=0;
     
    struct OrderBid {
        uint price;
        uint eth;
    }
    
    struct OrderAsk {
        uint price;
        uint volume;
    }
    
        
     
    function() payable public {
        require(msg.value > 0);
        if (bid[msg.sender].price > 0) {
            bid[msg.sender].eth = (bid[msg.sender].eth).add(msg.value);
            etherBalance = etherBalance.add(msg.value);
            UpdateBid(msg.sender, bid[msg.sender].price, bid[msg.sender].eth);
        } else {
             
            msg.sender.transfer(msg.value);
        }
         
         
         
    }

     
    function tokenFallback(address _from, uint _value, bytes _data) public returns (bool success) {
        require(_value > 0 && _data.length == 0);
        if (ask[_from].price > 0) {
            ask[_from].volume = (ask[_from].volume).add(_value);
            nacBalance = nacBalance.add(_value);
            UpdateAsk(_from, ask[_from].price, ask[_from].volume);
            return true;
        } else {
             
            ERC23 asset = ERC23(NamiAddr);
            asset.transfer(_from, _value);
            return false;
        }
    }
    
    modifier onlyNami {
        require(msg.sender == NamiAddr);
        _;
    }
    
    
     
     
    
    function placeBuyOrder(uint _price) payable public {
        require(_price > 0);
        if (msg.value > 0) {
            etherBalance += msg.value;
            bid[msg.sender].eth = (bid[msg.sender].eth).add(msg.value);
            UpdateBid(msg.sender, _price, bid[msg.sender].eth);
        }
        bid[msg.sender].price = _price;
    }
    
    function tokenFallbackBuyer(address _from, uint _value, address _buyer) onlyNami public returns (bool success) {
        ERC23 asset = ERC23(NamiAddr);
        uint currentEth = bid[_buyer].eth;
        if ((_value.div(bid[_buyer].price)) > currentEth) {
            if (_from.send(currentEth) && asset.transfer(_buyer, currentEth.mul(bid[_buyer].price)) && asset.transfer(_from, _value - (currentEth.mul(bid[_buyer].price) ) ) ) {
                bid[_buyer].eth = 0;
                etherBalance = etherBalance.sub(currentEth);
                UpdateBid(_buyer, bid[_buyer].price, bid[_buyer].eth);
                return true;
            } else {
                 
                asset.transfer(_from, _value);
                return false;
            }
        } else {
            uint eth = _value.div(bid[_buyer].price);
            if (_from.send(eth) && asset.transfer(_buyer, _value)) {
                bid[_buyer].eth = (bid[_buyer].eth).sub(eth);
                etherBalance = etherBalance.sub(eth);
                UpdateBid(_buyer, bid[_buyer].price, bid[_buyer].eth);
                return true;
            } else {
                 
                asset.transfer(_from, _value);
                return false;
            }
        }
    }
    
    function closeBidOrder() public {
        require(bid[msg.sender].eth > 0 && bid[msg.sender].price > 0);
        msg.sender.transfer(bid[msg.sender].eth);
        etherBalance = etherBalance.sub(bid[msg.sender].eth);
        bid[msg.sender].eth = 0;
        UpdateBid(msg.sender, bid[msg.sender].price, bid[msg.sender].eth);
    }
    

     
     
     
    
    function tokenFallbackExchange(address _from, uint _value, uint _price) onlyNami public returns (bool success) {
        require(_price > 0);
        if (_value > 0) {
            nacBalance = nacBalance.add(_value);
            ask[_from].volume = (ask[_from].volume).add(_value);
            ask[_from].price = _price;
            UpdateAsk(_from, _price, ask[_from].volume);
            return true;
        } else {
            ask[_from].price = _price;
            return false;
        }
    }
    
    function closeAskOrder() public {
        require(ask[msg.sender].volume > 0 && ask[msg.sender].price > 0);
        ERC23 asset = ERC23(NamiAddr);
        if (asset.transfer(msg.sender, ask[msg.sender].volume)) {
            nacBalance = nacBalance.sub(ask[msg.sender].volume);
            ask[msg.sender].volume = 0;
            UpdateAsk(msg.sender, ask[msg.sender].price, 0);
        }
    }
    
    function buyNac(address _seller) payable public returns (bool success) {
        require(msg.value > 0 && ask[_seller].volume > 0 && ask[_seller].price > 0);
        ERC23 asset = ERC23(NamiAddr);
        uint maxEth = (ask[_seller].volume).div(ask[_seller].price);
        if (msg.value > maxEth) {
            if (_seller.send(maxEth) && msg.sender.send(msg.value.sub(maxEth)) && asset.transfer(msg.sender, ask[_seller].volume)) {
                nacBalance = nacBalance.sub(ask[_seller].volume);
                ask[_seller].volume = 0;
                UpdateAsk(_seller, ask[_seller].price, 0);
                return true;
            } else {
                 
                return false;
            }
        } else {
            if (_seller.send(msg.value) && asset.transfer(msg.sender, (msg.value).mul(ask[_seller].price))) {
                uint nac = (msg.value).mul(ask[_seller].price);
                nacBalance = nacBalance.sub(nac);
                ask[_seller].volume = (ask[_seller].volume).sub(nac);
                UpdateAsk(_seller, ask[_seller].price, ask[_seller].volume);
                return true;
            } else {
                 
                return false;
            }
        }
    }
}

contract ERC23 {
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public returns (bool success);
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
            Deposit(msg.sender, msg.value);
    }

     
     
     
     
    function NamiMultiSigWallet(address[] _owners, uint _required)
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
        OwnerAddition(owner);
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
        OwnerRemoval(owner);
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
        OwnerRemoval(owner);
        OwnerAddition(newOwner);
    }

     
     
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        RequirementChange(_required);
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
        Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

     
     
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        Revocation(msg.sender, transactionId);
    }

     
     
    function executeTransaction(uint transactionId)
        public
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
             
            transactions[transactionId].executed = true;
             
            if (transactions[transactionId].destination.call.value(transactions[transactionId].value)(transactions[transactionId].data)) {
                Execution(transactionId);
            } else {
                ExecutionFailure(transactionId);
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
        Submission(transactionId);
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