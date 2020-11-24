 

pragma solidity 0.4.19;


 
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

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
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

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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


 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
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


contract MinerOneToken is MintableToken {
    using SafeMath for uint256;

    string public name = "MinerOne";
    string public symbol = "MIO";
    uint8 public decimals = 18;

     
    struct Account {
         
        uint256 lastDividends;
         
        uint256 fixedBalance;
         
        uint256 remainder;
    }

     
    mapping(address => Account) internal accounts;

     
    uint256 internal totalDividends;
     
    uint256 internal reserved;

     
    event Distributed(uint256 amount);
     
    event Paid(address indexed to, uint256 amount);
     
    event FundsReceived(address indexed from, uint256 amount);

    modifier fixBalance(address _owner) {
        Account storage account = accounts[_owner];
        uint256 diff = totalDividends.sub(account.lastDividends);
        if (diff > 0) {
            uint256 numerator = account.remainder.add(balances[_owner].mul(diff));

            account.fixedBalance = account.fixedBalance.add(numerator.div(totalSupply_));
            account.remainder = numerator % totalSupply_;
            account.lastDividends = totalDividends;
        }
        _;
    }

    modifier onlyWhenMintingFinished() {
        require(mintingFinished);
        _;
    }

    function () external payable {
        withdraw(msg.sender, msg.value);
    }

    function deposit() external payable {
        require(msg.value > 0);
        require(msg.value <= this.balance.sub(reserved));

        totalDividends = totalDividends.add(msg.value);
        reserved = reserved.add(msg.value);
        Distributed(msg.value);
    }

     
    function getDividends(address _owner) public view returns (uint256) {
        Account storage account = accounts[_owner];
        uint256 diff = totalDividends.sub(account.lastDividends);
        if (diff > 0) {
            uint256 numerator = account.remainder.add(balances[_owner].mul(diff));
            return account.fixedBalance.add(numerator.div(totalSupply_));
        } else {
            return 0;
        }
    }

    function transfer(address _to, uint256 _value) public
        onlyWhenMintingFinished
        fixBalance(msg.sender)
        fixBalance(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public
        onlyWhenMintingFinished
        fixBalance(_from)
        fixBalance(_to) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function payoutToAddress(address[] _holders) external {
        require(_holders.length > 0);
        require(_holders.length <= 100);
        for (uint256 i = 0; i < _holders.length; i++) {
            withdraw(_holders[i], 0);
        }
    }

     
    function withdraw(address _benefeciary, uint256 _toReturn) internal
        onlyWhenMintingFinished
        fixBalance(_benefeciary) returns (bool) {

        uint256 amount = accounts[_benefeciary].fixedBalance;
        reserved = reserved.sub(amount);
        accounts[_benefeciary].fixedBalance = 0;
        uint256 toTransfer = amount.add(_toReturn);
        if (toTransfer > 0) {
            _benefeciary.transfer(toTransfer);
        }
        if (amount > 0) {
            Paid(_benefeciary, amount);
        }
        return true;
    }
}


contract MinerOneCrowdsale is Ownable {
    using SafeMath for uint256;
     
    address public constant WALLET = 0x2C2b3885BC8B82Ad4D603D95ED8528Ef112fE8F2;
     
    address public constant TEAM_WALLET = 0x997faEf570B534E5fADc8D2D373e2F11aF4e115a;
     
    address public constant RESEARCH_AND_DEVELOPMENT_WALLET = 0x770998331D6775c345B1807c40413861fc4D6421;
     
    address public constant BOUNTY_WALLET = 0xd481Aab166B104B1aB12e372Ef7af6F986f4CF19;

    uint256 public constant UINT256_MAX = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 public constant ICO_TOKENS = 287000000e18;
    uint8 public constant ICO_TOKENS_PERCENT = 82;
    uint8 public constant TEAM_TOKENS_PERCENT = 10;
    uint8 public constant RESEARCH_AND_DEVELOPMENT_TOKENS_PERCENT = 6;
    uint8 public constant BOUNTY_TOKENS_PERCENT = 2;
    uint256 public constant SOFT_CAP = 3000000e18;
    uint256 public constant START_TIME = 1518692400;  
    uint256 public constant RATE = 1000;  
    uint256 public constant LARGE_PURCHASE = 10000e18;
    uint256 public constant LARGE_PURCHASE_BONUS = 4;
    uint256 public constant TOKEN_DESK_BONUS = 3;
    uint256 public constant MIN_TOKEN_AMOUNT = 100e18;

    Phase[] internal phases;

    struct Phase {
        uint256 till;
        uint8 discount;
    }

     
    MinerOneToken public token;
     
    uint256 public weiRaised;
     
    RefundVault public vault;
    uint256 public currentPhase = 0;
    bool public isFinalized = false;
    address private tokenMinter;
    address private tokenDeskProxy;
    uint256 public icoEndTime = 1526558400;  

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event Finalized();
     
    event ManualTokenMintRequiresRefund(address indexed purchaser, uint256 value);

    function MinerOneCrowdsale(address _token) public {
        phases.push(Phase({ till: 1519214400, discount: 35 }));  
        phases.push(Phase({ till: 1519905600, discount: 30 }));  
        phases.push(Phase({ till: 1521201600, discount: 25 }));  
        phases.push(Phase({ till: 1522584000, discount: 20 }));  
        phases.push(Phase({ till: 1524312000, discount: 15 }));  
        phases.push(Phase({ till: 1525608000, discount: 10 }));  
        phases.push(Phase({ till: 1526472000, discount: 5  }));  
        phases.push(Phase({ till: UINT256_MAX, discount:0 }));   

        token = MinerOneToken(_token);
        vault = new RefundVault(WALLET);
        tokenMinter = msg.sender;
    }

    modifier onlyTokenMinterOrOwner() {
        require(msg.sender == tokenMinter || msg.sender == owner);
        _;
    }

     
    function () external payable {
        if (!isFinalized) {
            buyTokens(msg.sender, msg.sender);
        } else {
            claimRefund();
        }
    }

    function mintTokens(address[] _receivers, uint256[] _amounts) external onlyTokenMinterOrOwner {
        require(_receivers.length > 0 && _receivers.length <= 100);
        require(_receivers.length == _amounts.length);
        require(!isFinalized);
        for (uint256 i = 0; i < _receivers.length; i++) {
            address receiver = _receivers[i];
            uint256 amount = _amounts[i];

            require(receiver != address(0));
            require(amount > 0);

            uint256 excess = appendContribution(receiver, amount);

            if (excess > 0) {
                ManualTokenMintRequiresRefund(receiver, excess);
            }
        }
    }

     
    function buyTokens(address sender, address beneficiary) public payable {
        require(beneficiary != address(0));
        require(sender != address(0));
        require(validPurchase());

        uint256 weiReceived = msg.value;
        uint256 nowTime = getNow();
         
        while (currentPhase < phases.length && phases[currentPhase].till < nowTime) {
            currentPhase = currentPhase.add(1);
        }

         
        uint256 tokens = calculateTokens(weiReceived);

        if (tokens < MIN_TOKEN_AMOUNT) revert();

        uint256 excess = appendContribution(beneficiary, tokens);
        uint256 refund = (excess > 0 ? excess.mul(weiReceived).div(tokens) : 0);

        weiReceived = weiReceived.sub(refund);
        weiRaised = weiRaised.add(weiReceived);

        if (refund > 0) {
            sender.transfer(refund);
        }

        TokenPurchase(sender, beneficiary, weiReceived, tokens.sub(excess));

        if (goalReached()) {
            WALLET.transfer(weiReceived);
        } else {
            vault.deposit.value(weiReceived)(sender);
        }
    }

     
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());

        vault.refund(msg.sender);
    }

     
    function finalize() public onlyOwner {
        require(!isFinalized);
        require(hasEnded());

        if (goalReached()) {
            vault.close();

            uint256 totalSupply = token.totalSupply();

            uint256 teamTokens = uint256(TEAM_TOKENS_PERCENT).mul(totalSupply).div(ICO_TOKENS_PERCENT);
            token.mint(TEAM_WALLET, teamTokens);
            uint256 rdTokens = uint256(RESEARCH_AND_DEVELOPMENT_TOKENS_PERCENT).mul(totalSupply).div(ICO_TOKENS_PERCENT);
            token.mint(RESEARCH_AND_DEVELOPMENT_WALLET, rdTokens);
            uint256 bountyTokens = uint256(BOUNTY_TOKENS_PERCENT).mul(totalSupply).div(ICO_TOKENS_PERCENT);
            token.mint(BOUNTY_WALLET, bountyTokens);

            token.finishMinting();
            token.transferOwnership(token);
        } else {
            vault.enableRefunds();
        }

        Finalized();

        isFinalized = true;
    }

     
    function hasEnded() public view returns (bool) {
        return getNow() > icoEndTime || token.totalSupply() == ICO_TOKENS;
    }

    function goalReached() public view returns (bool) {
        return token.totalSupply() >= SOFT_CAP;
    }

    function setTokenMinter(address _tokenMinter) public onlyOwner {
        require(_tokenMinter != address(0));
        tokenMinter = _tokenMinter;
    }

    function setTokenDeskProxy(address _tokekDeskProxy) public onlyOwner {
        require(_tokekDeskProxy != address(0));
        tokenDeskProxy = _tokekDeskProxy;
    }

    function setIcoEndTime(uint256 _endTime) public onlyOwner {
        require(_endTime > icoEndTime);
        icoEndTime = _endTime;
    }

    function getNow() internal view returns (uint256) {
        return now;
    }

    function calculateTokens(uint256 _weiAmount) internal view returns (uint256) {
        uint256 tokens = _weiAmount.mul(RATE).mul(100).div(uint256(100).sub(phases[currentPhase].discount));

        uint256 bonus = 0;
        if (currentPhase > 0) {
            bonus = bonus.add(tokens >= LARGE_PURCHASE ? LARGE_PURCHASE_BONUS : 0);
            bonus = bonus.add(msg.sender == tokenDeskProxy ? TOKEN_DESK_BONUS : 0);
        }
        return tokens.add(tokens.mul(bonus).div(100));
    }

    function appendContribution(address _beneficiary, uint256 _tokens) internal returns (uint256) {
        uint256 excess = 0;
        uint256 tokensToMint = 0;
        uint256 totalSupply = token.totalSupply();

        if (totalSupply.add(_tokens) < ICO_TOKENS) {
            tokensToMint = _tokens;
        } else {
            tokensToMint = ICO_TOKENS.sub(totalSupply);
            excess = _tokens.sub(tokensToMint);
        }
        if (tokensToMint > 0) {
            token.mint(_beneficiary, tokensToMint);
        }
        return excess;
    }

     
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = getNow() >= START_TIME && getNow() <= icoEndTime;
        bool nonZeroPurchase = msg.value != 0;
        bool canMint = token.totalSupply() < ICO_TOKENS;
        bool validPhase = (currentPhase < phases.length);
        return withinPeriod && nonZeroPurchase && canMint && validPhase;
    }
}