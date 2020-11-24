 

pragma solidity ^0.4.20;

 
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

 
contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ShortAddressProtection {

    modifier onlyPayloadSize(uint256 numwords) {
        assert(msg.data.length >= numwords * 32 + 4);
        _;
    }
}

 
contract BasicToken is ERC20Basic, ShortAddressProtection {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;

     
    function transfer(address _to, uint256 _value) onlyPayloadSize(2) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) onlyPayloadSize(2) public returns (bool) {
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) onlyPayloadSize(2) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) onlyPayloadSize(2) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
contract MintableToken is Ownable, StandardToken {

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    address public saleAgent;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier onlySaleAgent() {
        require(msg.sender == saleAgent);
        _;
    }

    function setSaleAgent(address _saleAgent) onlyOwner public {
        require(_saleAgent != address(0));
        saleAgent = _saleAgent;
    }

     
    function mint(address _to, uint256 _amount) onlySaleAgent canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() onlySaleAgent canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

contract Token is MintableToken {
    string public constant name = "TOKPIE";
    string public constant symbol = "TKP";
    uint8 public constant decimals = 18;
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

 
contract WhitelistedCrowdsale is Ownable {

    mapping(address => bool) public whitelist;

     
    modifier isWhitelisted(address _beneficiary) {
        require(whitelist[_beneficiary]);
        _;
    }

     
    function addToWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = true;
    }

     
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }
}

 
contract FinalizableCrowdsale is Pausable {
    using SafeMath for uint256;

    bool public isFinalized = false;

    event Finalized();

     
    function finalize() onlyOwner public {
        require(!isFinalized);

        finalization();
        Finalized();

        isFinalized = true;
    }

     
    function finalization() internal;
}

 
contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State {Active, Refunding, Closed}

    mapping(address => uint256) public deposited;
    address public wallet;
    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

     
    function RefundVault(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
        state = State.Active;
    }

     
    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close() onlyOwner public {
        require(state == State.Active);
        state = State.Closed;
        Closed();
        wallet.transfer(this.balance);
    }

    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        RefundsEnabled();
    }

     
    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        Refunded(investor, depositedValue);
    }
}

contract preICO is FinalizableCrowdsale, WhitelistedCrowdsale {
    Token public token;

     
    uint256 public startDate;

     
    uint256 public endDate;

     
    uint256 public weiRaised;

     
    uint256 public constant rate = 1920;

    uint256 public constant softCap = 500 * (1 ether);

    uint256 public constant hardCap = 1000 * (1 ether);

     
    RefundVault public vault;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    function preICO(address _token, address _wallet, uint256 _startDate, uint256 _endDate) public {
        require(_token != address(0) && _wallet != address(0));
        require(_endDate > _startDate);
        startDate = _startDate;
        endDate = _endDate;
        token = Token(_token);
        vault = new RefundVault(_wallet);
    }

     
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());

        vault.refund(msg.sender);
    }

     
    function goalReached() public view returns (bool) {
        return weiRaised >= softCap;
    }

     
    function finalization() internal {
        require(hasEnded());
        if (goalReached()) {
            vault.close();
        } else {
            vault.enableRefunds();
        }
    }

     
    function() external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) whenNotPaused isWhitelisted(beneficiary) isWhitelisted(msg.sender) public payable {
        require(beneficiary != address(0));
        require(validPurchase());
        require(!hasEnded());

        uint256 weiAmount = msg.value;

         
        uint256 tokens = weiAmount.mul(rate);

         
        require(tokens >= 100 * (10 ** 18));

         
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
        forwardFunds();
    }

     
    function forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }

     
    function validPurchase() internal view returns (bool) {
        return !isFinalized && now >= startDate && msg.value != 0;
    }

     
    function hasEnded() public view returns (bool) {
        return (now > endDate || weiRaised >= hardCap);
    }
}

contract ICO is Pausable, WhitelistedCrowdsale {
    using SafeMath for uint256;

    Token public token;

     
    uint256 public startDate;

     
    uint256 public endDate;

    uint256 public hardCap;

     
    uint256 public weiRaised;

    address public wallet;

    mapping(address => uint256) public deposited;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    function ICO(address _token, address _wallet, uint256 _startDate, uint256 _endDate, uint256 _hardCap) public {
        require(_token != address(0) && _wallet != address(0));
        require(_endDate > _startDate);
        require(_hardCap > 0);
        startDate = _startDate;
        endDate = _endDate;
        hardCap = _hardCap;
        token = Token(_token);
        wallet = _wallet;
    }

    function claimFunds() onlyOwner public {
        require(hasEnded());
        wallet.transfer(this.balance);
    }

    function getRate() public view returns (uint256) {
        if (now < startDate || hasEnded()) return 0;

         
        if (now >= startDate && now < startDate + 604680) return 1840;
         
        if (now >= startDate + 604680 && now < startDate + 1209480) return 1760;
         
        if (now >= startDate + 1209480 && now < startDate + 1814280) return 1680;
         
        if (now >= startDate + 1814280 && now < startDate + 2419080) return 1648;
         
        if (now >= startDate + 2419080) return 1600;
    }

     
    function() external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) whenNotPaused isWhitelisted(beneficiary) isWhitelisted(msg.sender) public payable {
        require(beneficiary != address(0));
        require(validPurchase());
        require(!hasEnded());

        uint256 weiAmount = msg.value;

         
        uint256 tokens = weiAmount.mul(getRate());

         
        require(tokens >= 100 * (10 ** 18));

         
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    }

     
    function validPurchase() internal view returns (bool) {
        return now >= startDate && msg.value != 0;
    }

     
    function hasEnded() public view returns (bool) {
        return (now > endDate || weiRaised >= hardCap);
    }
}

contract postICO is Ownable {
    using SafeMath for uint256;

    Token public token;

    address public walletE;
    address public walletB;
    address public walletC;
    address public walletF;
    address public walletG;

     
    uint256 public endICODate;

    bool public finished = false;

    uint256 public FTST;

     
    mapping(uint8 => bool) completedE;
    mapping(uint8 => bool) completedBC;

    uint256 public paymentSizeE;
    uint256 public paymentSizeB;
    uint256 public paymentSizeC;

     
    function postICO(
        address _token,
        address _walletE,
        address _walletB,
        address _walletC,
        address _walletF,
        address _walletG,
        uint256 _endICODate
    ) public {
        require(_token != address(0));
        require(_walletE != address(0));
        require(_walletB != address(0));
        require(_walletC != address(0));
        require(_walletF != address(0));
        require(_walletG != address(0));
        require(_endICODate >= now);

        token = Token(_token);
        endICODate = _endICODate;

        walletE = _walletE;
        walletB = _walletB;
        walletC = _walletC;
        walletF = _walletF;
        walletG = _walletG;
    }

    function finish() onlyOwner public {
        require(now > endICODate);
        require(!finished);
        require(token.saleAgent() == address(this));

        FTST = token.totalSupply().mul(100).div(65);

         
         
         
        paymentSizeE = FTST.mul(2625).div(100000);
        uint256 tokensE = paymentSizeE.mul(8);
        token.mint(this, tokensE);

         
         
         
        paymentSizeB = FTST.mul(25).div(10000);
        uint256 tokensB = paymentSizeB.mul(4);
        token.mint(this, tokensB);

         
         
        paymentSizeC = FTST.mul(215).div(10000);
        uint256 tokensC = paymentSizeC.mul(4);
        token.mint(this, tokensC);

         
        uint256 tokensF = FTST.mul(2).div(100);
        token.mint(walletF, tokensF);

         
        uint256 tokensG = FTST.mul(24).div(1000);
        token.mint(walletG, tokensG);

        token.finishMinting();
        finished = true;
    }

    function claimTokensE(uint8 order) onlyOwner public {
        require(finished);
        require(order >= 1 && order <= 8);
        require(!completedE[order]);

         
        if (order == 1) {
             
            require(now >= endICODate + 15724800);
            token.transfer(walletE, paymentSizeE);
            completedE[order] = true;
        }
         
        if (order == 2) {
             
            require(now >= endICODate + 31536000);
            token.transfer(walletE, paymentSizeE);
            completedE[order] = true;
        }
         
        if (order == 3) {
             
            require(now >= endICODate + 47260800);
            token.transfer(walletE, paymentSizeE);
            completedE[order] = true;
        }
         
        if (order == 4) {
             
            require(now >= endICODate + 63072000);
            token.transfer(walletE, paymentSizeE);
            completedE[order] = true;
        }
         
        if (order == 5) {
             
            require(now >= endICODate + 78796800);
            token.transfer(walletE, paymentSizeE);
            completedE[order] = true;
        }
         
        if (order == 6) {
             
            require(now >= endICODate + 94608000);
            token.transfer(walletE, paymentSizeE);
            completedE[order] = true;
        }
         
        if (order == 7) {
             
            require(now >= endICODate + 110332800);
            token.transfer(walletE, paymentSizeE);
            completedE[order] = true;
        }
         
        if (order == 8) {
             
            require(now >= endICODate + 126144000);
            token.transfer(walletE, paymentSizeE);
            completedE[order] = true;
        }
    }

    function claimTokensBC(uint8 order) onlyOwner public {
        require(finished);
        require(order >= 1 && order <= 4);
        require(!completedBC[order]);

         
        if (order == 1) {
             
            require(now >= endICODate + 15724800);
            token.transfer(walletB, paymentSizeB);
            token.transfer(walletC, paymentSizeC);
            completedBC[order] = true;
        }
         
        if (order == 2) {
             
            require(now >= endICODate + 31536000);
            token.transfer(walletB, paymentSizeB);
            token.transfer(walletC, paymentSizeC);
            completedBC[order] = true;
        }
         
        if (order == 3) {
             
            require(now >= endICODate + 47260800);
            token.transfer(walletB, paymentSizeB);
            token.transfer(walletC, paymentSizeC);
            completedBC[order] = true;
        }
         
        if (order == 4) {
             
            require(now >= endICODate + 63072000);
            token.transfer(walletB, paymentSizeB);
            token.transfer(walletC, paymentSizeC);
            completedBC[order] = true;
        }
    }
}

contract Controller is Ownable {
    Token public token;
    preICO public pre;
    ICO public ico;
    postICO public post;

    enum State {NONE, PRE_ICO, ICO, POST}

    State public state;

    function Controller(address _token, address _preICO, address _ico, address _postICO) public {
        require(_token != address(0x0));
        token = Token(_token);
        pre = preICO(_preICO);
        ico = ICO(_ico);
        post = postICO(_postICO);

        require(post.endICODate() == ico.endDate());

        require(pre.weiRaised() == 0);
        require(ico.weiRaised() == 0);

        require(token.totalSupply() == 0);
        state = State.NONE;
    }

    function startPreICO() onlyOwner public {
        require(state == State.NONE);
        require(token.owner() == address(this));
        token.setSaleAgent(pre);
        state = State.PRE_ICO;
    }

    function startICO() onlyOwner public {
        require(now > pre.endDate());
        require(state == State.PRE_ICO);
        require(token.owner() == address(this));
        token.setSaleAgent(ico);
        state = State.ICO;
    }

    function startPostICO() onlyOwner public {
        require(now > ico.endDate());
        require(state == State.ICO);
        require(token.owner() == address(this));
        token.setSaleAgent(post);
        state = State.POST;
    }
}