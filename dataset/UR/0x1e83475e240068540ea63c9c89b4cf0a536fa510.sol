 

pragma solidity 0.4.18;


 
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


contract PreSaleToken {
    using SafeMath for uint256;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AllowExchanger(address indexed exchanger);
    event RevokeExchanger(address indexed exchanger);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event Exchange(address indexed from, uint256 exchangedValue, string symbol, uint256 grantedValue);
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    address public owner;

     
    uint256 public totalSupply;

     
    mapping(address => uint256) balances;

     
     
    address[] public holders;

     
    bool public mintingFinished = false;

     
     
    mapping(address => bool) public exchangers;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyExchanger() {
        require(exchangers[msg.sender]);
        _;
    }

    function PreSaleToken() public {
        owner = msg.sender;
    }

    function allowExchanger(address _exchanger) onlyOwner public {
        require(mintingFinished);
        require(_exchanger != 0x0);
        require(!exchangers[_exchanger]);

        exchangers[_exchanger] = true;
        AllowExchanger(_exchanger);
    }

    function exchange(
        address _from,
        uint256 _amount,
        string _symbol,
        uint256 _grantedValue
    )
        onlyExchanger
        public
        returns (bool)
    {
        require(mintingFinished);  
        require(_from != 0x0);
        require(!exchangers[_from]);
        require(_amount > 0);
        require(_amount <= balances[_from]);

        balances[_from] = balances[_from].sub(_amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);
        Exchange(
            _from,
            _amount,
            _symbol,
            _grantedValue
        );
        Transfer(_from, msg.sender, _amount);

        return true;
    }

    function finishMinting() onlyOwner public returns (bool) {
        require(!mintingFinished);

        mintingFinished = true;
        MintFinished();

        return true;
    }

    function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
        require(_to != 0x0);
        require(!mintingFinished);
        require(_amount > 0);

        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        holders.push(_to);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);

        return true;
    }

    function revokeExchanger(address _exchanger) onlyOwner public {
        require(mintingFinished);
        require(_exchanger != 0x0);
        require(exchangers[_exchanger]);

        delete exchangers[_exchanger];
        RevokeExchanger(_exchanger);
    }

    function transferOwnership(address _to) onlyOwner public {
        require(_to != address(0));
        OwnershipTransferred(owner, _to);
        owner = _to;
    }

    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }
}


contract PreSale {
    using SafeMath for uint256;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event WalletChanged(address indexed previousWallet, address indexed newWallet);
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event Pause();
    event Unpause();
    event Withdrawal(address indexed wallet, uint256 weiAmount);
    event Extended(uint256 until);
    event Finalized();
    event Refunding();
    event Refunded(address indexed beneficiary, uint256 weiAmount);
    event Whitelisted(address indexed participant, uint256 weiAmount);

     
    address public owner;

     
    PreSaleToken public token;

     
     
    uint256 public goal;

     
    uint256 public startTime;
    uint256 public endTime;
    uint256 public timeExtension;

     
    uint256 public rate;

     
     
     
    uint256 public weiRaised;

     
     
    address public wallet;

     
     
    mapping(address => uint256) public whitelisted;

     
    mapping(address => uint256) public deposited;

     
    address[] public investors;

     
    bool public paused = false;

     
    bool public finished = false;
    uint256 public finishedAt;

     
    bool public refunding = false;

     
    uint256 public weiRefunded;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier saleOpen() {
        require(!finished);
        require(!paused);
        require(now >= startTime);
        require(now <= endTime + timeExtension);
        _;
    }

    function PreSale(
        uint256 _goal,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        address _wallet
    )
        public
        payable
    {
        require(msg.value > 0);
        require(_goal > 0);
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != 0x0);

        owner = msg.sender;
        goal = _goal;
        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
        token = new PreSaleToken();

        wallet.transfer(msg.value);
    }

    function () public payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _beneficiary) saleOpen public payable {
        require(_beneficiary != address(0));
        require(msg.value > 0);

        uint256 weiAmount = msg.value;
        uint256 newDeposited = deposited[_beneficiary].add(weiAmount);

        require(newDeposited <= whitelisted[_beneficiary]);

        uint256 tokens = weiAmount.mul(rate);

        deposited[_beneficiary] = newDeposited;
        investors.push(_beneficiary);

        weiRaised = weiRaised.add(weiAmount);

        token.mint(_beneficiary, tokens);
        TokenPurchase(
            msg.sender,
            _beneficiary,
            weiAmount,
            tokens
        );
    }

    function changeWallet(address _wallet) onlyOwner public payable {
        require(_wallet != 0x0);
        require(msg.value > 0);

        wallet = _wallet;
        WalletChanged(_wallet, wallet);

        wallet.transfer(msg.value);
    }

    function extendTime(uint256 _timeExtension) onlyOwner public {
        require(!finished);
        require(now < endTime + timeExtension);
        require(_timeExtension > 0);

        timeExtension = timeExtension.add(_timeExtension);
        require(timeExtension <= 7 days);

        Extended(endTime.add(timeExtension));
    }

    function finish() onlyOwner public {
        require(!finished);
        require(now > endTime + timeExtension);

        finished = true;
        finishedAt = now;
        token.finishMinting();

        if (goalReached()) {
            token.transferOwnership(owner);
            withdraw();
        } else {
            refunding = true;
            Refunding();
        }

        Finalized();
    }

    function pause() onlyOwner public {
        require(!paused);
        paused = true;
        Pause();
    }

    function refund(address _investor) public {
        require(finished);
        require(refunding);
        require(deposited[_investor] > 0);

        uint256 weiAmount = deposited[_investor];
        deposited[_investor] = 0;
        weiRefunded = weiRefunded.add(weiAmount);
        Refunded(_investor, weiAmount);

        _investor.transfer(weiAmount);
    }

    function transferOwnership(address _to) onlyOwner public {
        require(_to != address(0));
        OwnershipTransferred(owner, _to);
        owner = _to;
    }

    function unpause() onlyOwner public {
        require(paused);
        paused = false;
        Unpause();
    }

    function whitelist(address _participant, uint256 _weiAmount) onlyOwner public {
        require(_participant != 0x0);

        whitelisted[_participant] = _weiAmount;
        Whitelisted(_participant, _weiAmount);
    }

    function withdraw() onlyOwner public {
        require(goalReached() || (finished && now > finishedAt + 14 days));

        uint256 weiAmount = this.balance;

        if (weiAmount > 0) {
            wallet.transfer(weiAmount);
            Withdrawal(wallet, weiAmount);
        }
    }

    function goalReached() public constant returns (bool) {
        return weiRaised >= goal;
    }
}