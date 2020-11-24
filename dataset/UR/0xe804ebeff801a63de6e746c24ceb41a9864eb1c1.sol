 

 
pragma solidity ^0.4.25;


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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
 


 
 
contract FixedMath {
    
    using SafeMath for uint;
    uint constant internal METDECIMALS = 18;
    uint constant internal METDECMULT = 10 ** METDECIMALS;
    uint constant internal DECIMALS = 18;
    uint constant internal DECMULT = 10 ** DECIMALS;

     
    function fMul(uint x, uint y) internal pure returns (uint) {
        return (x.mul(y)).div(DECMULT);
    }

     
    function fDiv(uint numerator, uint divisor) internal pure returns (uint) {
        return (numerator.mul(DECMULT)).div(divisor);
    }

     
     
    function fSqrt(uint n) internal pure returns (uint) {
        if (n == 0) {
            return 0;
        }
        uint z = n * n;
        require(z / n == n);

        uint high = fAdd(n, DECMULT);
        uint low = 0;
        while (fSub(high, low) > 1) {
            uint mid = fAdd(low, high) / 2;
            if (fSqr(mid) <= n) {
                low = mid;
            } else {
                high = mid;
            }
        }
        return low;
    }

     
    function fSqr(uint n) internal pure returns (uint) {
        return fMul(n, n);
    }

     
    function fAdd(uint x, uint y) internal pure returns (uint) {
        return x.add(y);
    }

     
    function fSub(uint x, uint y) internal pure returns (uint) {
        return x.sub(y);
    }
}


 
contract Formula is FixedMath {

     
     
     
     
     
    function returnForMint(uint smartTokenSupply, uint reserveTokensSent, uint reserveTokenBalance) 
        internal pure returns (uint)
    {
        uint s = smartTokenSupply;
        uint e = reserveTokensSent;
        uint r = reserveTokenBalance;
         
         
        return ((fMul(s, (fSub(fSqrt(fAdd(DECMULT, fDiv(e, r))), DECMULT)))).mul(METDECMULT)).div(DECMULT);
    }

     
     
     
     
     
    function returnForRedemption(uint smartTokenSupply, uint smartTokensSent, uint reserveTokenBalance)
        internal pure returns (uint)
    {
        uint s = smartTokenSupply;
        uint t = smartTokensSent;
        uint r = reserveTokenBalance;
         
         
        return ((fMul(r, (fSub(DECMULT, fSqr(fSub(DECMULT, fDiv(t, s))))))).mul(METDECMULT)).div(DECMULT);
    }
}


 
contract Pricer {

    using SafeMath for uint;
    uint constant internal METDECIMALS = 18;
    uint constant internal METDECMULT = 10 ** METDECIMALS;
    uint public minimumPrice = 33*10**11;
    uint public minimumPriceInDailyAuction = 1;

    uint public tentimes;
    uint public hundredtimes;
    uint public thousandtimes;

    uint constant public MULTIPLIER = 1984320568*10**5;

     
    function initPricer() public {
        uint x = METDECMULT;
        uint i;
        
         
        for (i = 0; i < 10; i++) {
            x = x.mul(99).div(100);
        }
        tentimes = x;
        x = METDECMULT;

         
         
         
        for (i = 0; i < 10; i++) {
            x = x.mul(tentimes).div(METDECMULT);
        }
        hundredtimes = x;
        x = METDECMULT;

         
         
         
        for (i = 0; i < 10; i++) {
            x = x.mul(hundredtimes).div(METDECMULT);
        }
        thousandtimes = x;
    }

     
     
     
     
    function priceAt(uint initialPrice, uint _n) public view returns (uint price) {
        uint mult = METDECMULT;
        uint i;
        uint n = _n;

         
         
         
        if (n / 1000 > 0) {
            for (i = 0; i < n / 1000; i++) {
                mult = mult.mul(thousandtimes).div(METDECMULT);
            }
            n = n % 1000;
        }

         
         
         
        if (n / 100 > 0) {
            for (i = 0; i < n / 100; i++) {
                mult = mult.mul(hundredtimes).div(METDECMULT);
            }
            n = n % 100;
        }

         
         
         
        if (n / 10 > 0) {
            for (i = 0; i < n / 10; i++) {
                mult = mult.mul(tentimes).div(METDECMULT);
            }
            n = n % 10;
        }

         
        for (i = 0; i < n; i++) {
            mult = mult.mul(99).div(100);
        }

         
         
        price = initialPrice.mul(mult).div(METDECMULT);
        
        if (price < minimumPriceInDailyAuction) {
            price = minimumPriceInDailyAuction;
        }
    }

     
     
     
     
    function priceAtInitialAuction(uint lastPurchasePrice, uint numTicks) public view returns (uint price) {
         
         
         
         
        if (lastPurchasePrice > MULTIPLIER.mul(numTicks)) {
            price = lastPurchasePrice.sub(MULTIPLIER.mul(numTicks));
        }

        if (price < minimumPrice) {
            price = minimumPrice;
        }
    }
}


 
 
interface ERC20 {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint256);
    function allowance(address _owner, address _spender) public constant returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function approve(address _spender, uint256 _value) public returns (bool);
}


 
contract Ownable {

    address public owner;
    event OwnershipChanged(address indexed prevOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
     
     
    function changeOwnership(address _newOwner) public onlyOwner returns (bool) {
        require(_newOwner != address(0));
        require(_newOwner != owner);
        emit OwnershipChanged(owner, _newOwner);
        owner = _newOwner;
        return true;
    }
}


 
contract Owned is Ownable {

    address public newOwner;

     
     
     
    function changeOwnership(address _newOwner) public onlyOwner returns (bool) {
        require(_newOwner != owner);
        newOwner = _newOwner;
        return true;
    }

     
     
    function acceptOwnership() public returns (bool) {
        require(msg.sender == newOwner);

        emit OwnershipChanged(owner, newOwner);
        owner = newOwner;
        return true;
    }
}


 
contract Mintable is Owned {

    using SafeMath for uint256;

    event Mint(address indexed _to, uint _value);
    event Destroy(address indexed _from, uint _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balanceOf;

    address public autonomousConverter;
    address public minter;
    ITokenPorter public tokenPorter;

     
     
     
     
     
    function initMintable(address _autonomousConverter, address _minter, uint _initialSupply, 
        uint _decmult) public onlyOwner {
        require(autonomousConverter == 0x0 && _autonomousConverter != 0x0);
        require(minter == 0x0 && _minter != 0x0);
      
        autonomousConverter = _autonomousConverter;
        minter = _minter;
        _totalSupply = _initialSupply.mul(_decmult);
        _balanceOf[_autonomousConverter] = _totalSupply;
    }

    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public constant returns (uint256) {
        return _balanceOf[_owner];
    }

     
     
    function setTokenPorter(address _tokenPorter) public onlyOwner returns (bool) {
        require(_tokenPorter != 0x0);

        tokenPorter = ITokenPorter(_tokenPorter);
        return true;
    }

     
     
     
    function mint(address _to, uint _value) public returns (bool) {
        require(msg.sender == minter || msg.sender == address(tokenPorter));
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        _totalSupply = _totalSupply.add(_value);
        emit Mint(_to, _value);
        emit Transfer(0x0, _to, _value);
        return true;
    }

     
     
     
    function destroy(address _from, uint _value) public returns (bool) {
        require(msg.sender == autonomousConverter || msg.sender == address(tokenPorter));
        _balanceOf[_from] = _balanceOf[_from].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Destroy(_from, _value);
        emit Transfer(_from, 0x0, _value);
        return true;
    }
}


 
contract Token is ERC20, Mintable {
    mapping(address => mapping(address => uint256)) internal _allowance;

    function initToken(address _autonomousConverter, address _minter,
    uint _initialSupply, uint _decmult) public onlyOwner {
        initMintable(_autonomousConverter, _minter, _initialSupply, _decmult);
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return _allowance[_owner][_spender];
    }

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_to != minter);
        require(_to != address(this));
        require(_to != autonomousConverter);
        Proceeds proceeds = Auctions(minter).proceeds();
        require((_to != address(proceeds)));

        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) { 
        require(_to != address(0));       
        require(_to != minter && _from != minter);
        require(_to != address(this) && _from != address(this));
        Proceeds proceeds = Auctions(minter).proceeds();
        require(_to != address(proceeds) && _from != address(proceeds));
         
        require(_from != autonomousConverter);
        require(_allowance[_from][msg.sender] >= _value);
        
        _balanceOf[_from] = _balanceOf[_from].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(this));
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
    function multiTransfer(uint[] bits) public returns (bool) {
        for (uint i = 0; i < bits.length; i++) {
            address a = address(bits[i] >> 96);
            uint amount = bits[i] & ((1 << 96) - 1);
            if (!transfer(a, amount)) revert();
        }

        return true;
    }

     
     
     
     
    function approveMore(address _spender, uint256 _value) public returns (bool) {
        uint previous = _allowance[msg.sender][_spender];
        uint newAllowance = previous.add(_value);
        _allowance[msg.sender][_spender] = newAllowance;
        emit Approval(msg.sender, _spender, newAllowance);
        return true;
    }

     
     
     
     
    function approveLess(address _spender, uint256 _value) public returns (bool) {
        uint previous = _allowance[msg.sender][_spender];
        uint newAllowance = previous.sub(_value);
        _allowance[msg.sender][_spender] = newAllowance;
        emit Approval(msg.sender, _spender, newAllowance);
        return true;
    }
}


 
contract SmartToken is Mintable {
    uint constant internal METDECIMALS = 18;
    uint constant internal METDECMULT = 10 ** METDECIMALS;

    function initSmartToken(address _autonomousConverter, address _minter, uint _initialSupply) public  onlyOwner {
        initMintable(_autonomousConverter, _minter, _initialSupply, METDECMULT); 
    }
}


 
contract METToken is Token {

    string public constant name = "Metronome";
    string public constant symbol = "MET";
    uint8 public constant decimals = 18;

    bool public transferAllowed;

    function initMETToken(address _autonomousConverter, address _minter, 
        uint _initialSupply, uint _decmult) public onlyOwner {
        initToken(_autonomousConverter, _minter, _initialSupply, _decmult);
    }
    
     
    modifier transferable() {
        require(transferAllowed);
        _;
    }

    function enableMETTransfers() public returns (bool) {
        require(!transferAllowed && Auctions(minter).isInitialAuctionEnded());
        transferAllowed = true; 
        return true;
    }

     
     
     
    function transfer(address _to, uint256 _value) public transferable returns (bool) {
        return super.transfer(_to, _value);
        
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public transferable returns (bool) {        
        return super.transferFrom(_from, _to, _value);
    }

     
     
     
     
    function multiTransfer(uint[] bits) public transferable returns (bool) {
        return super.multiTransfer(bits);
    }
    
    mapping (address => bytes32) public roots;

    function setRoot(bytes32 data) public {
        roots[msg.sender] = data;
    }

    function getRoot(address addr) public view returns (bytes32) {
        return roots[addr];
    }

    function rootsMatch(address a, address b) public view returns (bool) {
        return roots[a] == roots[b];
    }

     
     
     
     
     
     
     
     
     
     
     
    function importMET(bytes8 _originChain, bytes8 _destinationChain, address[] _addresses, bytes _extraData, 
        bytes32[] _burnHashes, uint[] _supplyOnAllChains, uint[] _importData, bytes _proof) public returns (bool)
    {
        require(address(tokenPorter) != 0x0);
        return tokenPorter.importMET(_originChain, _destinationChain, _addresses, _extraData, 
        _burnHashes, _supplyOnAllChains, _importData, _proof);
    }

     
     
     
     
     
     
     
     
    function export(bytes8 _destChain, address _destMetronomeAddr, address _destRecipAddr, uint _amount, uint _fee, 
    bytes _extraData) public returns (bool)
    {
        require(address(tokenPorter) != 0x0);
        return tokenPorter.export(msg.sender, _destChain, _destMetronomeAddr,
        _destRecipAddr, _amount, _fee, _extraData);
    }

    struct Sub {
        uint startTime;      
        uint payPerWeek; 
        uint lastWithdrawTime;
    }

    event LogSubscription(address indexed subscriber, address indexed subscribesTo);
    event LogCancelSubscription(address indexed subscriber, address indexed subscribesTo);

    mapping (address => mapping (address => Sub)) public subs;

     
     
     
     
     
    function subscribe(uint _startTime, uint _payPerWeek, address _recipient) public returns (bool) {
        require(_startTime >= block.timestamp);
        require(_payPerWeek != 0);
        require(_recipient != 0);

        subs[msg.sender][_recipient] = Sub(_startTime, _payPerWeek, _startTime);  
        
        emit LogSubscription(msg.sender, _recipient);
        return true;
    }

     
     
     
    function cancelSubscription(address _recipient) public returns (bool) {
        require(subs[msg.sender][_recipient].startTime != 0);
        require(subs[msg.sender][_recipient].payPerWeek != 0);

        subs[msg.sender][_recipient].startTime = 0;
        subs[msg.sender][_recipient].payPerWeek = 0;
        subs[msg.sender][_recipient].lastWithdrawTime = 0;

        emit LogCancelSubscription(msg.sender, _recipient);
        return true;
    }

     
     
     
     
    function getSubscription(address _owner, address _recipient) public constant
        returns (uint startTime, uint payPerWeek, uint lastWithdrawTime) 
    {
        Sub storage sub = subs[_owner][_recipient];
        return (
            sub.startTime,
            sub.payPerWeek,
            sub.lastWithdrawTime
        );
    }

     
     
     
    function subWithdraw(address _owner) public transferable returns (bool) {
        require(subWithdrawFor(_owner, msg.sender));
        return true;
    }

     
     
     
    function multiSubWithdraw(address[] _owners) public returns (uint) {
        uint n = 0;
        for (uint i=0; i < _owners.length; i++) {
            if (subWithdrawFor(_owners[i], msg.sender)) {
                n++;
            } 
        }
        return n;
    }

     
     
     
     
     
    function multiSubWithdrawFor(address[] _owners, address[] _recipients) public returns (uint) {
         
        require(_owners.length == _recipients.length);

        uint n = 0;
        for (uint i = 0; i < _owners.length; i++) {
            if (subWithdrawFor(_owners[i], _recipients[i])) {
                n++;
            }
        }

        return n;
    }

    function subWithdrawFor(address _from, address _to) internal returns (bool) {
        Sub storage sub = subs[_from][_to];
        
        if (sub.startTime > 0 && sub.startTime < block.timestamp && sub.payPerWeek > 0) {
            uint weekElapsed = (now.sub(sub.lastWithdrawTime)).div(7 days);
            uint amount = weekElapsed.mul(sub.payPerWeek);
            if (weekElapsed > 0 && _balanceOf[_from] >= amount) {
                subs[_from][_to].lastWithdrawTime = block.timestamp;
                _balanceOf[_from] = _balanceOf[_from].sub(amount);
                _balanceOf[_to] = _balanceOf[_to].add(amount);
                emit Transfer(_from, _to, amount);
                return true;
            }
        }       
        return false;
    }
}


 
contract AutonomousConverter is Formula, Owned {

    SmartToken public smartToken;
    METToken public reserveToken;
    Auctions public auctions;

    enum WhichToken { Eth, Met }
    bool internal initialized = false;

    event LogFundsIn(address indexed from, uint value);
    event ConvertEthToMet(address indexed from, uint eth, uint met);
    event ConvertMetToEth(address indexed from, uint eth, uint met);

    function init(address _reserveToken, address _smartToken, address _auctions) 
        public onlyOwner payable 
    {
        require(!initialized);
        auctions = Auctions(_auctions);
        reserveToken = METToken(_reserveToken);
        smartToken = SmartToken(_smartToken);
        initialized = true;
    }

    function handleFund() public payable {
        require(msg.sender == address(auctions.proceeds()));
        emit LogFundsIn(msg.sender, msg.value);
    }

    function getMetBalance() public view returns (uint) {
        return balanceOf(WhichToken.Met);
    }

    function getEthBalance() public view returns (uint) {
        return balanceOf(WhichToken.Eth);
    }

     
     
     
    function getMetForEthResult(uint _depositAmount) public view returns (uint256) {
        return convertingReturn(WhichToken.Eth, _depositAmount);
    }

     
     
     
    function getEthForMetResult(uint _depositAmount) public view returns (uint256) {
        return convertingReturn(WhichToken.Met, _depositAmount);
    }

     
     
     
    function convertEthToMet(uint _mintReturn) public payable returns (uint returnedMet) {
        returnedMet = convert(WhichToken.Eth, _mintReturn, msg.value);
        emit ConvertEthToMet(msg.sender, msg.value, returnedMet);
    }

     
     
     
     
     
    function convertMetToEth(uint _amount, uint _mintReturn) public returns (uint returnedEth) {
        returnedEth = convert(WhichToken.Met, _mintReturn, _amount);
        emit ConvertMetToEth(msg.sender, returnedEth, _amount);
    }

    function balanceOf(WhichToken which) internal view returns (uint) {
        if (which == WhichToken.Eth) return address(this).balance;
        if (which == WhichToken.Met) return reserveToken.balanceOf(this);
        revert();
    }

    function convertingReturn(WhichToken whichFrom, uint _depositAmount) internal view returns (uint256) {
        
        WhichToken to = WhichToken.Met;
        if (whichFrom == WhichToken.Met) {
            to = WhichToken.Eth;
        }

        uint reserveTokenBalanceFrom = balanceOf(whichFrom).add(_depositAmount);
        uint mintRet = returnForMint(smartToken.totalSupply(), _depositAmount, reserveTokenBalanceFrom);
        
        uint newSmartTokenSupply = smartToken.totalSupply().add(mintRet);
        uint reserveTokenBalanceTo = balanceOf(to);
        return returnForRedemption(
            newSmartTokenSupply,
            mintRet,
            reserveTokenBalanceTo);
    }

    function convert(WhichToken whichFrom, uint _minReturn, uint amnt) internal returns (uint) {
        WhichToken to = WhichToken.Met;
        if (whichFrom == WhichToken.Met) {
            to = WhichToken.Eth;
            require(reserveToken.transferFrom(msg.sender, this, amnt));
        }

        uint mintRet = mint(whichFrom, amnt, 1);
        
        return redeem(to, mintRet, _minReturn);
    }

    function mint(WhichToken which, uint _depositAmount, uint _minReturn) internal returns (uint256 amount) {
        require(_minReturn > 0);

        amount = mintingReturn(which, _depositAmount);
        require(amount >= _minReturn);
        require(smartToken.mint(msg.sender, amount));
    }

    function mintingReturn(WhichToken which, uint _depositAmount) internal view returns (uint256) {
        uint256 smartTokenSupply = smartToken.totalSupply();
        uint256 reserveBalance = balanceOf(which);
        return returnForMint(smartTokenSupply, _depositAmount, reserveBalance);
    }

    function redeem(WhichToken which, uint _amount, uint _minReturn) internal returns (uint redeemable) {
        require(_amount <= smartToken.balanceOf(msg.sender));
        require(_minReturn > 0);

        redeemable = redemptionReturn(which, _amount);
        require(redeemable >= _minReturn);

        uint256 reserveBalance = balanceOf(which);
        require(reserveBalance >= redeemable);

        uint256 tokenSupply = smartToken.totalSupply();
        require(_amount < tokenSupply);

        smartToken.destroy(msg.sender, _amount);
        if (which == WhichToken.Eth) {
            msg.sender.transfer(redeemable);
        } else {
            require(reserveToken.transfer(msg.sender, redeemable));
        }
    }

    function redemptionReturn(WhichToken which, uint smartTokensSent) internal view returns (uint256) {
        uint smartTokenSupply = smartToken.totalSupply();
        uint reserveTokenBalance = balanceOf(which);
        return returnForRedemption(
            smartTokenSupply,
            smartTokensSent,
            reserveTokenBalance);
    }
}


 
contract Proceeds is Owned {
    using SafeMath for uint256;

    AutonomousConverter public autonomousConverter;
    Auctions public auctions;
    event LogProceedsIn(address indexed from, uint value); 
    event LogClosedAuction(address indexed from, uint value);
    uint latestAuctionClosed;

    function initProceeds(address _autonomousConverter, address _auctions) public onlyOwner {
        require(address(auctions) == 0x0 && _auctions != 0x0);
        require(address(autonomousConverter) == 0x0 && _autonomousConverter != 0x0);

        autonomousConverter = AutonomousConverter(_autonomousConverter);
        auctions = Auctions(_auctions);
    }

    function handleFund() public payable {
        require(msg.sender == address(auctions));
        emit LogProceedsIn(msg.sender, msg.value);
    }

     
    function closeAuction() public {
        uint lastPurchaseTick = auctions.lastPurchaseTick();
        uint currentAuction = auctions.currentAuction();
        uint val = ((address(this).balance).mul(25)).div(10000); 
        if (val > 0 && (currentAuction > auctions.whichAuction(lastPurchaseTick)) 
            && (latestAuctionClosed < currentAuction)) {
            latestAuctionClosed = currentAuction;
            autonomousConverter.handleFund.value(val)();
            emit LogClosedAuction(msg.sender, val);
        }
    }
}


 
contract Auctions is Pricer, Owned {

    using SafeMath for uint256;
    METToken public token;
    Proceeds public proceeds;
    address[] public founders;
    mapping(address => TokenLocker) public tokenLockers;
    uint internal constant DAY_IN_SECONDS = 86400;
    uint internal constant DAY_IN_MINUTES = 1440;
    uint public genesisTime;
    uint public lastPurchaseTick;
    uint public lastPurchasePrice;
    uint public constant INITIAL_GLOBAL_DAILY_SUPPLY = 2880 * METDECMULT;
    uint public INITIAL_FOUNDER_SUPPLY = 1999999 * METDECMULT;
    uint public INITIAL_AC_SUPPLY = 1 * METDECMULT;
    uint public totalMigratedOut = 0;
    uint public totalMigratedIn = 0;
    uint public timeScale = 1;
    uint public constant INITIAL_SUPPLY = 10000000 * METDECMULT;
    uint public mintable = INITIAL_SUPPLY;
    uint public initialAuctionDuration = 7 days;
    uint public initialAuctionEndTime;
    uint public dailyAuctionStartTime;
    uint public constant DAILY_PURCHASE_LIMIT = 1000 ether;
    mapping (address => uint) internal purchaseInTheAuction;
    mapping (address => uint) internal lastPurchaseAuction;
    bool public minted;
    bool public initialized;
    uint public globalSupplyAfterPercentageLogic = 52598080 * METDECMULT;
    uint public constant AUCTION_WHEN_PERCENTAGE_LOGIC_STARTS = 14791;
    bytes8 public chain = "ETH";
    event LogAuctionFundsIn(address indexed sender, uint amount, uint tokens, uint purchasePrice, uint refund);

    constructor() public {
        mintable = INITIAL_SUPPLY - 2000000 * METDECMULT;
    }

     
    function () public payable running {
        require(msg.value > 0);
        
        uint amountForPurchase = msg.value;
        uint excessAmount;

        if (currentAuction() > whichAuction(lastPurchaseTick)) {
            proceeds.closeAuction();
            restartAuction();
        }

        if (isInitialAuctionEnded()) {
            require(now >= dailyAuctionStartTime);
            if (lastPurchaseAuction[msg.sender] < currentAuction()) {
                if (amountForPurchase > DAILY_PURCHASE_LIMIT) {
                    excessAmount = amountForPurchase.sub(DAILY_PURCHASE_LIMIT);
                    amountForPurchase = DAILY_PURCHASE_LIMIT;
                }           
                purchaseInTheAuction[msg.sender] = msg.value;
                lastPurchaseAuction[msg.sender] = currentAuction();
            } else {
                require(purchaseInTheAuction[msg.sender] < DAILY_PURCHASE_LIMIT);
                if (purchaseInTheAuction[msg.sender].add(amountForPurchase) > DAILY_PURCHASE_LIMIT) {
                    excessAmount = (purchaseInTheAuction[msg.sender].add(amountForPurchase)).sub(DAILY_PURCHASE_LIMIT);
                    amountForPurchase = amountForPurchase.sub(excessAmount);
                }
                purchaseInTheAuction[msg.sender] = purchaseInTheAuction[msg.sender].add(msg.value);
            }
        }

        uint _currentTick = currentTick();

        uint weiPerToken;
        uint tokens;
        uint refund;
        (weiPerToken, tokens, refund) = calcPurchase(amountForPurchase, _currentTick);
        require(tokens > 0);

        if (now < initialAuctionEndTime && (token.totalSupply()).add(tokens) >= INITIAL_SUPPLY) {
            initialAuctionEndTime = now;
            dailyAuctionStartTime = ((initialAuctionEndTime / 1 days) + 1) * 1 days;
        }

        lastPurchaseTick = _currentTick;
        lastPurchasePrice = weiPerToken;

        assert(tokens <= mintable);
        mintable = mintable.sub(tokens);

        assert(refund <= amountForPurchase);
        uint ethForProceeds = amountForPurchase.sub(refund);

        proceeds.handleFund.value(ethForProceeds)();

        require(token.mint(msg.sender, tokens));

        refund = refund.add(excessAmount);
        if (refund > 0) {
            if (purchaseInTheAuction[msg.sender] > 0) {
                purchaseInTheAuction[msg.sender] = purchaseInTheAuction[msg.sender].sub(refund);
            }
            msg.sender.transfer(refund);
        }
        emit LogAuctionFundsIn(msg.sender, ethForProceeds, tokens, lastPurchasePrice, refund);
    }

    modifier running() {
        require(isRunning());
        _;
    }

    function isRunning() public constant returns (bool) {
        return (block.timestamp >= genesisTime && genesisTime > 0);
    }

     
     
    function currentTick() public view returns(uint) {
        return whichTick(block.timestamp);
    }

     
     
    function currentAuction() public view returns(uint) {
        return whichAuction(currentTick());
    }

     
     
     
    function whichTick(uint t) public view returns(uint) {
        if (genesisTime > t) { 
            revert(); 
        }
        return (t - genesisTime) * timeScale / 1 minutes;
    }

     
     
     
    function whichAuction(uint t) public view returns(uint) {
        if (whichTick(dailyAuctionStartTime) > t) {
            return 0;
        } else {
            return ((t - whichTick(dailyAuctionStartTime)) / DAY_IN_MINUTES) + 1;
        }
    }

     
    function heartbeat() public view returns (
        bytes8 _chain,
        address auctionAddr,
        address convertAddr,
        address tokenAddr,
        uint minting,
        uint totalMET,
        uint proceedsBal,
        uint currTick,
        uint currAuction,
        uint nextAuctionGMT,
        uint genesisGMT,
        uint currentAuctionPrice,
        uint _dailyMintable,
        uint _lastPurchasePrice) {
        _chain = chain;
        convertAddr = proceeds.autonomousConverter();
        tokenAddr = token;
        auctionAddr = this;
        totalMET = token.totalSupply();
        proceedsBal = address(proceeds).balance;

        currTick = currentTick();
        currAuction = currentAuction();
        if (currAuction == 0) {
            nextAuctionGMT = dailyAuctionStartTime;
        } else {
            nextAuctionGMT = (currAuction * DAY_IN_SECONDS) / timeScale + dailyAuctionStartTime;
        }
        genesisGMT = genesisTime;

        currentAuctionPrice = currentPrice();
        _dailyMintable = dailyMintable();
        minting = currentMintable();
        _lastPurchasePrice = lastPurchasePrice;
    }

     
     
     
     
     
    function initAuctions(uint _startTime, uint _minimumPrice, uint _startingPrice, uint _timeScale) 
        public onlyOwner returns (bool) 
    {
        require(minted);
        require(!initialized);
        require(_timeScale != 0);
        initPricer();
        if (_startTime > 0) { 
            genesisTime = (_startTime / (1 minutes)) * (1 minutes) + 60;
        } else {
            genesisTime = block.timestamp + 60 - (block.timestamp % 60);
        }

        initialAuctionEndTime = genesisTime + initialAuctionDuration;

         
         
        if (initialAuctionEndTime == (initialAuctionEndTime / 1 days) * 1 days) {
            dailyAuctionStartTime = initialAuctionEndTime;
        } else {
            dailyAuctionStartTime = ((initialAuctionEndTime / 1 days) + 1) * 1 days;
        }

        lastPurchaseTick = 0;

        if (_minimumPrice > 0) {
            minimumPrice = _minimumPrice;
        }

        timeScale = _timeScale;

        if (_startingPrice > 0) {
            lastPurchasePrice = _startingPrice * 1 ether;
        } else {
            lastPurchasePrice = 2 ether;
        }

        for (uint i = 0; i < founders.length; i++) {
            TokenLocker tokenLocker = tokenLockers[founders[i]];
            tokenLocker.lockTokenLocker();
        }
        
        initialized = true;
        return true;
    }

    function createTokenLocker(address _founder, address _token) public onlyOwner {
        require(_token != 0x0);
        require(_founder != 0x0);
        founders.push(_founder);
        TokenLocker tokenLocker = new TokenLocker(address(this), _token);
        tokenLockers[_founder] = tokenLocker;
        tokenLocker.changeOwnership(_founder);
    }

     
     
     
     
    function mintInitialSupply(uint[] _founders, address _token, 
        address _proceeds, address _autonomousConverter) public onlyOwner returns (bool) 
    {
        require(!minted);
        require(_founders.length != 0);
        require(address(token) == 0x0 && _token != 0x0);
        require(address(proceeds) == 0x0 && _proceeds != 0x0);
        require(_autonomousConverter != 0x0);

        token = METToken(_token);
        proceeds = Proceeds(_proceeds);

         
        uint foundersTotal;
        for (uint i = 0; i < _founders.length; i++) {
            address addr = address(_founders[i] >> 96);
            require(addr != 0x0);
            uint amount = _founders[i] & ((1 << 96) - 1);
            require(amount > 0);
            TokenLocker tokenLocker = tokenLockers[addr];
            require(token.mint(address(tokenLocker), amount));
            tokenLocker.deposit(addr, amount);
            foundersTotal = foundersTotal.add(amount);
        }

         
        require(foundersTotal == INITIAL_FOUNDER_SUPPLY);

         
        require(token.mint(_autonomousConverter, INITIAL_AC_SUPPLY));

        minted = true;
        return true;
    }

     
    function stopEverything() public onlyOwner {
        if (genesisTime < block.timestamp) {
            revert(); 
        }
        genesisTime = genesisTime + (60 * 60 * 24 * 365 * 1000);  
        initialAuctionEndTime = genesisTime;
        dailyAuctionStartTime = genesisTime;
    }

     
    function isInitialAuctionEnded() public view returns (bool) {
        return (initialAuctionEndTime != 0 && 
            (now >= initialAuctionEndTime || token.totalSupply() >= INITIAL_SUPPLY));
    }

     
    function globalMetSupply() public view returns (uint) {

        uint currAuc = currentAuction();
        if (currAuc > AUCTION_WHEN_PERCENTAGE_LOGIC_STARTS) {
            return globalSupplyAfterPercentageLogic;
        } else {
            return INITIAL_SUPPLY.add(INITIAL_GLOBAL_DAILY_SUPPLY.mul(currAuc));
        }
    }

     
     
    function globalDailySupply() public view returns (uint) {
        uint dailySupply = INITIAL_GLOBAL_DAILY_SUPPLY;
        uint thisAuction = currentAuction();

        if (thisAuction > AUCTION_WHEN_PERCENTAGE_LOGIC_STARTS) {
            uint lastAuctionPurchase = whichAuction(lastPurchaseTick);
            uint recentAuction = AUCTION_WHEN_PERCENTAGE_LOGIC_STARTS + 1;
            if (lastAuctionPurchase > recentAuction) {
                recentAuction = lastAuctionPurchase;
            }

            uint totalAuctions = thisAuction - recentAuction;
            if (totalAuctions > 1) {
                 
                uint factor = 36525 + ((totalAuctions - 1) * 2);
                dailySupply = (globalSupplyAfterPercentageLogic.mul(2).mul(factor)).div(36525 ** 2);

            } else {
                dailySupply = globalSupplyAfterPercentageLogic.mul(2).div(36525);
            }

            if (dailySupply < INITIAL_GLOBAL_DAILY_SUPPLY) {
                dailySupply = INITIAL_GLOBAL_DAILY_SUPPLY; 
            }
        }

        return dailySupply;
    }

     
     
    function currentPrice() public constant returns (uint weiPerToken) {
        weiPerToken = calcPriceAt(currentTick());
    }

     
    function dailyMintable() public constant returns (uint) {
        return nextAuctionSupply(0);
    }

     
    function tokensOnThisChain() public view returns (uint) {
        uint totalSupply = token.totalSupply();
        uint currMintable = currentMintable();
        return totalSupply.add(currMintable);
    }

     
    function currentMintable() public view returns (uint) {
        uint currMintable = mintable;
        uint currAuction = currentAuction();
        uint totalAuctions = currAuction.sub(whichAuction(lastPurchaseTick));
        if (totalAuctions > 0) {
            currMintable = mintable.add(nextAuctionSupply(totalAuctions));
        }
        return currMintable;
    }

     
    function prepareAuctionForNonOGChain() public {
        require(msg.sender == address(token.tokenPorter()) || msg.sender == address(token));
        require(token.totalSupply() == 0);
        require(chain != "ETH");
        lastPurchaseTick = currentTick();
    }

     
     
     
     
     
     
    function whatWouldPurchaseDo(uint _wei, uint _timestamp) public constant
        returns (uint weiPerToken, uint tokens, uint refund)
    {
        weiPerToken = calcPriceAt(whichTick(_timestamp));
        uint calctokens = METDECMULT.mul(_wei).div(weiPerToken);
        tokens = calctokens;
        if (calctokens > mintable) {
            tokens = mintable;
            uint weiPaying = mintable.mul(weiPerToken).div(METDECMULT);
            refund = _wei.sub(weiPaying);
        }
    }

     
     
     
     
    function nextAuction() internal constant returns(uint _startTime, uint _startPrice, uint _auctionTokens) {
        if (block.timestamp < genesisTime) {
            _startTime = genesisTime;
            _startPrice = lastPurchasePrice;
            _auctionTokens = mintable;
            return;
        }

        uint recentAuction = whichAuction(lastPurchaseTick);
        uint currAuc = currentAuction();
        uint totalAuctions = currAuc - recentAuction;
        _startTime = dailyAuctionStartTime;
        if (currAuc > 1) {
            _startTime = auctionStartTime(currentTick());
        }

        _auctionTokens = nextAuctionSupply(totalAuctions);

        if (totalAuctions > 1) {
            _startPrice = lastPurchasePrice / 100 + 1;
        } else {
            if (mintable == 0 || totalAuctions == 0) {
                 
                _startPrice = (lastPurchasePrice * 2) + 1;   
            } else {
                 
                if (currAuc == 1) {
                     
                    _startPrice = minimumPrice * 2;
                } else {
                     
                    uint tickWhenAuctionEnded = whichTick(_startTime);
                    uint numTick = 0;
                    if (tickWhenAuctionEnded > lastPurchaseTick) {
                        numTick = tickWhenAuctionEnded - lastPurchaseTick;
                    }
                    _startPrice = priceAt(lastPurchasePrice, numTick) * 2;
                }
                
                
            }
        }
    }

     
     
     
     
     
     
    function calcPurchase(uint _wei, uint _t) internal view returns (uint weiPerToken, uint tokens, uint refund)
    {
        require(_t >= lastPurchaseTick);
        uint numTicks = _t - lastPurchaseTick;
        if (isInitialAuctionEnded()) {
            weiPerToken = priceAt(lastPurchasePrice, numTicks);
        } else {
            weiPerToken = priceAtInitialAuction(lastPurchasePrice, numTicks);
        }

        uint calctokens = METDECMULT.mul(_wei).div(weiPerToken);
        tokens = calctokens;
        if (calctokens > mintable) {
            tokens = mintable;
            uint ethPaying = mintable.mul(weiPerToken).div(METDECMULT);
            refund = _wei.sub(ethPaying);
        }
    }

     
     
    function nextAuctionSupply(uint totalAuctionMissed) internal view returns (uint supply) {
        uint thisAuction = currentAuction();
        uint tokensHere = token.totalSupply().add(mintable);
        supply = INITIAL_GLOBAL_DAILY_SUPPLY;
        uint dailySupplyAtLastPurchase;
        if (thisAuction > AUCTION_WHEN_PERCENTAGE_LOGIC_STARTS) {
            supply = globalDailySupply();
            if (totalAuctionMissed > 1) {
                dailySupplyAtLastPurchase = globalSupplyAfterPercentageLogic.mul(2).div(36525);
                supply = dailySupplyAtLastPurchase.add(supply).mul(totalAuctionMissed).div(2);
            } 
            supply = (supply.mul(tokensHere)).div(globalSupplyAfterPercentageLogic);
        } else {
            if (totalAuctionMissed > 1) {
                supply = supply.mul(totalAuctionMissed);
            }
            uint previousGlobalMetSupply = 
            INITIAL_SUPPLY.add(INITIAL_GLOBAL_DAILY_SUPPLY.mul(whichAuction(lastPurchaseTick)));
            supply = (supply.mul(tokensHere)).div(previousGlobalMetSupply);
        
        }
    }

     
     
     
    function calcPriceAt(uint _tick) internal constant returns (uint weiPerToken) {
        uint recentAuction = whichAuction(lastPurchaseTick);
        uint totalAuctions = whichAuction(_tick).sub(recentAuction);
        uint prevPrice;

        uint numTicks = 0;

         
        if (mintable == 0 && totalAuctions == 0) {
            return lastPurchasePrice;
        }

         
        if (totalAuctions > 1) {
            prevPrice = lastPurchasePrice / 100 + 1;
            numTicks = numTicksSinceAuctionStart(_tick);
        } else if (totalAuctions == 1) {
             
             
            if (mintable == 0) {
                prevPrice = lastPurchasePrice * 2;
            } else {
                 
                 
                if (whichAuction(_tick) == 1) {
                    prevPrice = minimumPrice * 2;
                } else {
                    prevPrice = priceAt(lastPurchasePrice, numTicksTillAuctionStart(_tick)) * 2;
                }
            }
            numTicks = numTicksSinceAuctionStart(_tick);
        } else {
             
            prevPrice = lastPurchasePrice;
            numTicks = _tick - lastPurchaseTick;
        }

        require(numTicks >= 0);

        if (isInitialAuctionEnded()) {
            weiPerToken = priceAt(prevPrice, numTicks);
        } else {
            weiPerToken = priceAtInitialAuction(prevPrice, numTicks);
        }
    }

     
     
    function numTicksSinceAuctionStart(uint _tick) private view returns (uint ) {
        uint currentAuctionStartTime = auctionStartTime(_tick);
        return _tick - whichTick(currentAuctionStartTime);
    }
    
     
     
    function numTicksTillAuctionStart(uint _tick) private view returns (uint) {
        uint currentAuctionStartTime = auctionStartTime(_tick);
        return whichTick(currentAuctionStartTime) - lastPurchaseTick;
    }

     
     
     
    function auctionStartTime(uint _tick) private view returns (uint) {
        return ((whichAuction(_tick)) * 1 days) / timeScale + dailyAuctionStartTime - 1 days;
    }

     
    function restartAuction() private {
        uint time;
        uint price;
        uint auctionTokens;
        (time, price, auctionTokens) = nextAuction();

        uint thisAuction = currentAuction();
        if (thisAuction > AUCTION_WHEN_PERCENTAGE_LOGIC_STARTS) {
            globalSupplyAfterPercentageLogic = globalSupplyAfterPercentageLogic.add(globalDailySupply());
        }

        mintable = mintable.add(auctionTokens);
        lastPurchasePrice = price;
        lastPurchaseTick = whichTick(time);
    }
}


 
contract TokenLocker is Ownable {
    using SafeMath for uint;
    uint internal constant QUARTER = 91 days + 450 minutes;
  
    Auctions public auctions;
    METToken public token;
    bool public locked = false;
  
    uint public deposited;
    uint public lastWithdrawTime;
    uint public quarterlyWithdrawable;
    
    event Withdrawn(address indexed who, uint amount);
    event Deposited(address indexed who, uint amount);

    modifier onlyAuction() {
        require(msg.sender == address(auctions));
        _;
    }

    modifier preLock() { 
        require(!locked);
        _; 
    }

    modifier postLock() { 
        require(locked); 
        _; 
    }

     
     
     
    constructor(address _auctions, address _token) public {
        require(_auctions != 0x0);
        require(_token != 0x0);
        auctions = Auctions(_auctions);
        token = METToken(_token);
    }

     
     
    function lockTokenLocker() public onlyAuction {
        require(auctions.initialAuctionEndTime() != 0);
        require(auctions.initialAuctionEndTime() >= auctions.genesisTime()); 
        locked = true;
    }

     
     
     
    function deposit (address beneficiary, uint amount ) public onlyAuction preLock {
        uint totalBalance = token.balanceOf(this);
        require(totalBalance.sub(deposited) >= amount);
        deposited = deposited.add(amount);
        emit Deposited(beneficiary, amount);
    }

     
     
     
    function withdraw() public onlyOwner postLock {
        require(deposited > 0);
        uint withdrawable = 0; 
        uint withdrawTime = auctions.initialAuctionEndTime();
        if (lastWithdrawTime == 0 && auctions.isInitialAuctionEnded()) {
            withdrawable = withdrawable.add((deposited.mul(25)).div(100));
            quarterlyWithdrawable = (deposited.sub(withdrawable)).div(12);
            lastWithdrawTime = withdrawTime;
        }

        require(lastWithdrawTime != 0);

        if (now >= lastWithdrawTime.add(QUARTER)) {
            uint daysSinceLastWithdraw = now.sub(lastWithdrawTime);
            uint totalQuarters = daysSinceLastWithdraw.div(QUARTER);

            require(totalQuarters > 0);
        
            withdrawable = withdrawable.add(quarterlyWithdrawable.mul(totalQuarters));

            if (now >= withdrawTime.add(QUARTER.mul(12))) {
                withdrawable = deposited;
            }

            lastWithdrawTime = lastWithdrawTime.add(totalQuarters.mul(QUARTER));
        }

        if (withdrawable > 0) {
            deposited = deposited.sub(withdrawable);
            token.transfer(msg.sender, withdrawable);
            emit Withdrawn(msg.sender, withdrawable);
        }
    }
}


 
 
interface ITokenPorter {
    event ExportOnChainClaimedReceiptLog(address indexed destinationMetronomeAddr, 
        address indexed destinationRecipientAddr, uint amount);

    event ExportReceiptLog(bytes8 destinationChain, address destinationMetronomeAddr,
        address indexed destinationRecipientAddr, uint amountToBurn, uint fee, bytes extraData, uint currentTick,
        uint indexed burnSequence, bytes32 indexed currentBurnHash, bytes32 prevBurnHash, uint dailyMintable,
        uint[] supplyOnAllChains, uint genesisTime, uint blockTimestamp, uint dailyAuctionStartTime);

    event ImportReceiptLog(address indexed destinationRecipientAddr, uint amountImported, 
        uint fee, bytes extraData, uint currentTick, uint indexed importSequence, 
        bytes32 indexed currentHash, bytes32 prevHash, uint dailyMintable, uint blockTimestamp, address caller);

    function export(address tokenOwner, bytes8 _destChain, address _destMetronomeAddr, 
        address _destRecipAddr, uint _amount, uint _fee, bytes _extraData) public returns (bool);
    
    function importMET(bytes8 _originChain, bytes8 _destinationChain, address[] _addresses, bytes _extraData, 
        bytes32[] _burnHashes, uint[] _supplyOnAllChains, uint[] _importData, bytes _proof) public returns (bool);

}


 
contract TokenPorter is ITokenPorter, Owned {
    using SafeMath for uint;
    Auctions public auctions;
    METToken public token;
    Validator public validator;

    uint public burnSequence = 1;
    uint public importSequence = 1;
    uint public chainHopStartTime = now + (2*60*60*24);
     
    uint public minimumExportFee = 1 * (10 ** 12);
     
    uint public exportFee = 50;
    bytes32[] public exportedBurns;
    uint[] public supplyOnAllChains = new uint[](6);
    mapping (bytes32 => bytes32) public merkleRoots;
    mapping (bytes32 => bytes32) public mintHashes;
     
     
    mapping (bytes32 => uint) public burnHashes;
     
    mapping(bytes8 => address) public destinationChains;

    event LogExportReceipt(bytes8 destinationChain, address destinationMetronomeAddr,
        address indexed destinationRecipientAddr, uint amountToBurn, uint fee, bytes extraData, uint currentTick,
        uint burnSequence, bytes32 indexed currentBurnHash, bytes32 prevBurnHash, uint dailyMintable,
        uint[] supplyOnAllChains, uint blockTimestamp, address indexed exporter);

    event LogImportRequest(bytes8 originChain, bytes32 indexed currentBurnHash, bytes32 prevHash,
        address indexed destinationRecipientAddr, uint amountToImport, uint fee, uint exportTimeStamp,
        uint burnSequence, bytes extraData);
    
    event LogImport(bytes8 originChain, address indexed destinationRecipientAddr, uint amountImported, uint fee,
    bytes extraData, uint indexed importSequence, bytes32 indexed currentHash);
    
     
     
     
    function initTokenPorter(address _tokenAddr, address _auctionsAddr) public onlyOwner {
        require(_tokenAddr != 0x0);
        require(_auctionsAddr != 0x0);
        auctions = Auctions(_auctionsAddr);
        token = METToken(_tokenAddr);
    }

     
     
    function setMinimumExportFee(uint _minimumExportFee) public onlyOwner returns (bool) {
        require(_minimumExportFee > 0);
        minimumExportFee = _minimumExportFee;
        return true;
    }

     
     
    function setExportFeePerTenThousand(uint _exportFee) public onlyOwner returns (bool) {
        exportFee = _exportFee;
        return true;
    }

     
     
     
    function setChainHopStartTime(uint _startTime) public onlyOwner returns (bool) {
        require(_startTime >= block.timestamp);
        chainHopStartTime = _startTime;
        return true;
    }

     
     
    function setValidator(address _validator) public onlyOwner returns (bool) {
        require(_validator != 0x0);
        validator = Validator(_validator);
        return true;
    }

     
     
     
    function addDestinationChain(bytes8 _chainName, address _contractAddress) public onlyOwner returns (bool) {
        require(_chainName != 0 && _contractAddress != address(0));
        destinationChains[_chainName] = _contractAddress;
        return true;
    }

     
     
    function removeDestinationChain(bytes8 _chainName) public onlyOwner returns (bool) {
        require(_chainName != 0);
        require(destinationChains[_chainName] != address(0));
        destinationChains[_chainName] = address(0);
        return true;   
    }

     
     
     
    mapping (address  => mapping(address => uint)) public claimables;

     
     
     
     
    function claimReceivables(address[] recipients) public returns (uint) {
        require(recipients.length > 0);

        uint total;
        for (uint i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint amountBurned = claimables[msg.sender][recipient];
            if (amountBurned > 0) {
                claimables[msg.sender][recipient] = 0;
                emit ExportOnChainClaimedReceiptLog(msg.sender, recipient, amountBurned);
                total = total.add(1);
            }
        }
        return total;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
    function importMET(bytes8 _originChain, bytes8 _destinationChain, address[] _addresses, bytes _extraData, 
        bytes32[] _burnHashes, uint[] _supplyOnAllChains, uint[] _importData, bytes _proof) public returns (bool)
    {
        
        require(msg.sender == address(token));
        require(now >= chainHopStartTime);
        require(_importData.length == 8);
        require(_addresses.length == 2);
        require(_burnHashes.length == 2);
        require(!validator.hashClaimed(_burnHashes[1]));
        require(isReceiptValid(_originChain, _destinationChain, _addresses, _extraData, _burnHashes, 
        _supplyOnAllChains, _importData));
        require(_destinationChain == auctions.chain());
        require(_addresses[0] == address(token));
        require(_importData[1] != 0);
        
         
         
        merkleRoots[_burnHashes[1]] = bytesToBytes32(_proof);

         
        mintHashes[_burnHashes[1]] = keccak256(abi.encodePacked(_originChain, 
        _addresses[1], _importData[1], _importData[2]));
        
        emit LogImportRequest(_originChain, _burnHashes[1], _burnHashes[0], _addresses[1], _importData[1],
            _importData[2], _importData[0], _importData[6], _extraData);
        return true;
    }

     
     
     
     
     
     
     
     
    function export(address tokenOwner, bytes8 _destChain, address _destMetronomeAddr,
        address _destRecipAddr, uint _amount, uint _fee, bytes _extraData) public returns (bool) {
        require(msg.sender == address(token));
        require(now >= chainHopStartTime);
        require(_destChain != 0x0 && _destMetronomeAddr != 0x0 && _destRecipAddr != 0x0 && _amount != 0);
        require(destinationChains[_destChain] == _destMetronomeAddr);
        
        require(token.balanceOf(tokenOwner) >= _amount.add(_fee));
        require(_fee >= minimumExportFee && _fee >= (_amount.mul(exportFee).div(10000)));
        token.destroy(tokenOwner, _amount.add(_fee));

        uint dailyMintable = auctions.dailyMintable();
        uint currentTick = auctions.currentTick();
       
       
        if (burnSequence == 1) {
            exportedBurns.push(keccak256(abi.encodePacked(uint8(0))));
        }

        if (_destChain == auctions.chain()) {
            claimables[_destMetronomeAddr][_destRecipAddr] = 
                claimables[_destMetronomeAddr][_destRecipAddr].add(_amount);
        }
        uint blockTime = block.timestamp;
        bytes32 currentBurn = keccak256(abi.encodePacked(
            blockTime, 
            auctions.chain(),
            _destChain, 
            _destMetronomeAddr, 
            _destRecipAddr, 
            _amount,
            _fee,
            currentTick,
            auctions.genesisTime(),
            dailyMintable,
            _extraData,
            exportedBurns[burnSequence - 1]));
       
        exportedBurns.push(currentBurn);
        burnHashes[currentBurn] = burnSequence;
        supplyOnAllChains[0] = token.totalSupply();
        
        emit LogExportReceipt(_destChain, _destMetronomeAddr, _destRecipAddr, _amount, _fee, _extraData, 
            currentTick, burnSequence, currentBurn, exportedBurns[burnSequence - 1], dailyMintable,
            supplyOnAllChains, blockTime, tokenOwner);

        burnSequence = burnSequence + 1;
        return true;
    }

     
     
     
     
     
     
     
     
     
    function mintToken(bytes8 originChain, address recipientAddress, uint amount, 
        uint fee, bytes extraData, bytes32 currentHash, uint globalSupplyInOtherChains, 
        address[] validators) public returns (bool) {
        require(msg.sender == address(validator));
        require(originChain != 0x0);
        require(recipientAddress != 0x0);
        require(amount > 0);
        require(currentHash != 0x0);

         
        require(mintHashes[currentHash] == keccak256(abi.encodePacked(originChain, recipientAddress, amount, fee)));

        require(isGlobalSupplyValid(amount, fee, globalSupplyInOtherChains));
        
        if (importSequence == 1 && token.totalSupply() == 0) {
            auctions.prepareAuctionForNonOGChain();
        }
        
        require(token.mint(recipientAddress, amount));
         
         
        uint feeToDistribute =  fee.div(validators.length);
        for (uint i = 0; i < validators.length; i++) {
            token.mint(validators[i], feeToDistribute);
        }
        emit LogImport(originChain, recipientAddress, amount, fee, extraData, importSequence, currentHash);
        importSequence++;
        return true;
    }

     
    function bytesToBytes32(bytes b) private pure returns (bytes32) {
        bytes32 out;

        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[i] & 0xFF) >> (i * 8);
        }
        return out;
    }

     
    function isGlobalSupplyValid(uint amount, uint fee, uint globalSupplyInOtherChains) private view returns (bool) {
        uint amountToImport = amount.add(fee);
        uint currentGlobalSupply = globalSupplyInOtherChains.add(token.totalSupply());
        return (amountToImport.add(currentGlobalSupply) <= auctions.globalMetSupply());
    }

     
    function isReceiptValid(bytes8 _originChain, bytes8 _destinationChain, address[] _addresses, bytes _extraData, 
        bytes32[] _burnHashes, uint[] _supplyOnAllChain, uint[] _importData) private pure returns(bool) {

         
         
         
         
         
         
         

        if (_burnHashes[1] == keccak256(abi.encodePacked(_importData[0], _originChain,
            _destinationChain, _addresses[0], _addresses[1], _importData[1], _importData[2], 
            _importData[3], _importData[4], _importData[5], _extraData, _burnHashes[0]))) {
            return true;
        }
        
        return false;
    }
}    


 
contract Proposals is Owned {
    uint public votingPeriod = 60 * 60 * 24 * 15;

    Validator public validator;
    mapping (address => uint) public valProposals;

    bytes32[] public actions;
    
    struct Proposal {
        uint proposalId;
        bytes32 action;
        uint expiry;
        address validator;
        uint newThreshold;
        uint supportCount;
        address[] voters;
        bool passed;
        mapping (address => bool) voted;

    }

    Proposal[] public proposals;

    event LogVoted(uint indexed proposalId, address indexed voter, bool support);

    event LogProposalCreated(uint indexed proposalId, address indexed newValidator, 
        uint newThreshold, address creator, uint expiry, bytes32 indexed action);

    event LogProposalClosed(uint indexed proposalId, address indexed newValidator, 
        uint newThreshold, bytes32 indexed action, uint expiry, uint supportCount, bool passed);

     
    modifier onlyValidator() {
        require(validator.isValidator(msg.sender));
        _;
    }

    constructor() public {
        actions.push("addval");
        actions.push("removeval");
        actions.push("updatethreshold");
    }

     
     
    function setValidator(address _validator) public onlyOwner returns (bool) {
        require(_validator != 0x0);
        validator = Validator(_validator);
        return true;
    }

     
     
    function updateVotingPeriod(uint _t) public onlyOwner returns (bool) {
        require(_t != 0);
        votingPeriod = _t;
        return true;
    }

     
     
     
    function proposeNewValidator(address _validator, uint _newThreshold) public onlyValidator returns (uint) {
        require(_validator != 0x0);
        require(!validator.isValidator(_validator));
        if (_newThreshold > 0) {
            uint valCount = validator.getValidatorsCount();
            require(validator.isNewThresholdValid(valCount + 1, _newThreshold));
        }
        return createNewProposal(_validator, msg.sender, actions[0], _newThreshold);
    }

     
     
     
     
     
    function proposeRemoveValidator(address _validator, uint _newThreshold) public onlyValidator returns (uint) {
        require(_validator != 0x0);
        require(validator.isValidator(_validator));
        if (_newThreshold > 0) {
            uint valCount = validator.getValidatorsCount();
            require(validator.isNewThresholdValid(valCount - 1, _newThreshold));
        }
        return createNewProposal(_validator, msg.sender, actions[1], _newThreshold);
    }

     
     
    function proposeNewThreshold(uint _newThreshold) public onlyValidator returns (uint) {
        uint valCount = validator.getValidatorsCount();
        require(validator.isNewThresholdValid(valCount, _newThreshold));
        return createNewProposal(0x0, msg.sender, actions[2], _newThreshold);
    }

     
     
     
    function voteForProposal(uint _proposalId, bool _support) public onlyValidator {
        require(proposals[_proposalId].expiry != 0);
        require(now < proposals[_proposalId].expiry);
        require(!proposals[_proposalId].passed);
        require(!(proposals[_proposalId]).voted[msg.sender]);
        proposals[_proposalId].voters.push(msg.sender);
        proposals[_proposalId].voted[msg.sender] = true;
        if (_support) {
            proposals[_proposalId].supportCount++;
        }
        emit LogVoted(_proposalId, msg.sender, _support);
    }
    
     
     
    function closeProposal(uint _proposalId) public {
        require(proposals[_proposalId].expiry != 0);
        if (proposals[_proposalId].supportCount >= validator.threshold()) {
            executeProposal(_proposalId, proposals[_proposalId].newThreshold);
        } else if (now > proposals[_proposalId].expiry) {
             
            if ((proposals[_proposalId].action == actions[1]) && 
                (proposals[_proposalId].voters.length == proposals[_proposalId].supportCount)) {
                executeProposal(_proposalId, proposals[_proposalId].newThreshold);
            }
        }   
    }

     
     
     
    function executeProposal(uint _proposalId, uint _newThreshold) private {
        if (proposals[_proposalId].action == actions[0]) {
            validator.addValidator(proposals[_proposalId].validator);
        } else if (proposals[_proposalId].action == actions[1]) {
            validator.removeValidator(proposals[_proposalId].validator);
        }
        if (_newThreshold != 0 && _newThreshold != validator.threshold()) {
            validator.updateThreshold(_newThreshold);
        }
        proposals[_proposalId].passed = true;
        emit LogProposalClosed(_proposalId, proposals[_proposalId].validator, 
            _newThreshold, proposals[_proposalId].action, proposals[_proposalId].expiry, 
            proposals[_proposalId].supportCount, true);
    }

     
     
     
     
     
    function createNewProposal(address _validator, address _creator, bytes32 _action, 
        uint _newThreshold) private returns (uint proposalId) {
        proposalId = proposals.length++;
        if (_validator != 0x0) {
            require((valProposals[_validator] == 0) || (now > proposals[valProposals[_validator]].expiry) 
            || (proposals[valProposals[_validator]].passed));
            valProposals[_validator] = proposalId;
        }
        uint expiry = now + votingPeriod;
        Proposal storage p = proposals[proposalId];
        p.proposalId = proposalId;
        p.action = _action;
        p.expiry = expiry;
        p.validator = _validator;
        p.newThreshold = _newThreshold;
        emit LogProposalCreated(proposalId, _validator, _newThreshold, _creator, expiry, _action);
    }
}


 
contract Validator is Owned {

    using SafeMath for uint;

     
    mapping (bytes32 => mapping (address => bool)) public hashAttestations;
    mapping (bytes32 => mapping (address => bool)) public hashRefutation;
    mapping (bytes32 => uint) public attestationCount;
    mapping (address => bool) public isValidator;
    address[] public validators;
    METToken public token;
    TokenPorter public tokenPorter;
    Auctions public auctions;
    Proposals public proposals;

    mapping (bytes32 => bool) public hashClaimed;

     
    uint public threshold = 2;

    event LogAttestation(bytes32 indexed hash, address indexed recipientAddr, bool isValid);
    event LogValidatorAdded(address indexed validator, address indexed caller, uint threshold);
    event LogValidatorRemoved(address indexed validator, address indexed caller, uint threshold);
  
     
    modifier onlyValidator() {
        require(isValidator[msg.sender]);
        _;
    }

     
    modifier onlyAuthorized() {
        require(msg.sender == owner || msg.sender == address(proposals));
        _;
    }

     
    function addValidator(address _validator) public onlyAuthorized {
        require(!isValidator[_validator]);
        validators.push(_validator);
        isValidator[_validator] = true;
        uint minThreshold = (validators.length / 2) + 1;
        if (threshold < minThreshold) {
            threshold = minThreshold;
        }
        emit LogValidatorAdded(_validator, msg.sender, threshold);
    }

     
    function removeValidator(address _validator) public onlyAuthorized {
         
        require(validators.length > 1);
        delete isValidator[_validator];
        for (uint i = 0; i < (validators.length); i++) {
            if (validators[i] == _validator) {
                if (i != (validators.length - 1)) {
                    validators[i] = validators[validators.length - 1];
                }
                validators.length--; 
                break;
            }
        }

        if (threshold >= validators.length) {
            if (validators.length == 1) {
                threshold = 1;
            } else {
                threshold = validators.length - 1;
            }
        }
        emit LogValidatorRemoved(_validator, msg.sender, threshold);
    }

     
    function getValidatorsCount() public view returns (uint) { 
        return  validators.length;
    }

     
     
     
    function updateThreshold(uint _threshold) public onlyAuthorized returns (bool) {
        require(isNewThresholdValid(validators.length, _threshold));
        threshold = _threshold;
        return true;
    }

     
     
     
     
    function isNewThresholdValid(uint _valCount, uint _threshold) public pure returns (bool) {
        if (_threshold == 1 && _valCount == 2) {
            return true;
        } else if (_threshold >= 1 && _threshold < _valCount && (_threshold > (_valCount / 2))) {
            return true;
        }
        return false;
    }

     
     
     
    function setProposalContract(address _proposals) public onlyOwner returns (bool) {
        require(_proposals != 0x0);
        proposals = Proposals(_proposals);
        return true;
    }

     
     
     
    function setTokenPorter(address _tokenPorter) public onlyOwner returns (bool) {
        require(_tokenPorter != 0x0);
        tokenPorter = TokenPorter(_tokenPorter);
        return true;
    }

     
     
     
     
    function initValidator(address _tokenAddr, address _auctionsAddr, address _tokenPorterAddr) public onlyOwner {
        require(_tokenAddr != 0x0);
        require(_auctionsAddr != 0x0);
        require(_tokenPorterAddr != 0x0);
        tokenPorter = TokenPorter(_tokenPorterAddr);
        auctions = Auctions(_auctionsAddr);
        token = METToken(_tokenAddr);
    }

     
     
     
     
     
     
     
     
     
    function attestHash(bytes32 _burnHash, bytes8 _originChain, address _recipientAddr, 
        uint _amount, uint _fee, bytes32[] _proof, bytes _extraData,
        uint _globalSupplyInOtherChains) public onlyValidator {
        require(_burnHash != 0x0);
        require(!hashAttestations[_burnHash][msg.sender]);
        require(!hashRefutation[_burnHash][msg.sender]);
        require(verifyProof(tokenPorter.merkleRoots(_burnHash), _burnHash, _proof));
        hashAttestations[_burnHash][msg.sender] = true;
        attestationCount[_burnHash]++;
        emit LogAttestation(_burnHash, _recipientAddr, true);
        
        if (attestationCount[_burnHash] >= threshold && !hashClaimed[_burnHash]) {
            hashClaimed[_burnHash] = true;
            require(tokenPorter.mintToken(_originChain, _recipientAddr, _amount, _fee, 
                _extraData, _burnHash, _globalSupplyInOtherChains, validators));
        }
    }

     
     
    function refuteHash(bytes32 _burnHash, address _recipientAddr) public onlyValidator {
        require(!hashAttestations[_burnHash][msg.sender]);
        require(!hashRefutation[_burnHash][msg.sender]);
        hashRefutation[_burnHash][msg.sender] = true;
        emit LogAttestation(_burnHash, _recipientAddr, false);
    }

     
     
     
     
     
    function verifyProof(bytes32 _root, bytes32 _leaf, bytes32[] _proof) private pure returns (bool) {
        require(_root != 0x0 && _leaf != 0x0 && _proof.length != 0);

        bytes32 _hash = _leaf;
        for (uint i = 0; i < _proof.length; i++) {
            _hash = sha256(_proof[i], _hash);
        } 
        return (_hash == _root);
    }

}