 

pragma solidity ^0.4.19;

 

 
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
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

 

 
contract GMRToken is MintableToken {
     
    string public constant name = "GimmerToken";
    string public constant symbol = "GMR";
    uint8 public constant decimals = 18;

     
    modifier onlyWhenTransferEnabled() {
        require(mintingFinished);
        _;
    }

     
    modifier validDestination(address _to) {
        require(_to != address(0x0));
        require(_to != address(this));
        _;
    }

    function GMRToken() public {
    }

    function transferFrom(address _from, address _to, uint256 _value) public
        onlyWhenTransferEnabled
        validDestination(_to)
        returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public
        onlyWhenTransferEnabled
        returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval (address _spender, uint _addedValue) public
        onlyWhenTransferEnabled
        returns (bool) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public
        onlyWhenTransferEnabled
        returns (bool) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function transfer(address _to, uint256 _value) public
        onlyWhenTransferEnabled
        validDestination(_to)
        returns (bool) {
        return super.transfer(_to, _value);
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

 

 
contract GimmerToken is MintableToken {
     
    string public constant name = "GimmerToken";
    string public constant symbol = "GMR";
    uint8 public constant decimals = 18;

     
    modifier onlyWhenTransferEnabled() {
        require(mintingFinished);
        _;
    }

    modifier validDestination(address _to) {
        require(_to != address(0x0));
        require(_to != address(this));
        _;
    }

    function GimmerToken() public {
    }

    function transferFrom(address _from, address _to, uint256 _value) public
        onlyWhenTransferEnabled
        validDestination(_to)
        returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public
        onlyWhenTransferEnabled
        returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval (address _spender, uint _addedValue) public
        onlyWhenTransferEnabled
        returns (bool) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public
        onlyWhenTransferEnabled
        returns (bool) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function transfer(address _to, uint256 _value) public
        onlyWhenTransferEnabled
        validDestination(_to)
        returns (bool) {
        return super.transfer(_to, _value);
    }
}

 

 
contract GimmerTokenSale is Pausable {
    using SafeMath for uint256;

     
    struct Supporter {
        uint256 weiSpent;  
        bool hasKYC;  
    }

     
    mapping(address => Supporter) public supportersMap;  
    GimmerToken public token;  
    address public fundWallet;  
    address public kycManagerWallet;  
    address public currentAddress;  
    uint256 public tokensSold;  
    uint256 public weiRaised;  
    uint256 public maxTxGas;  
    uint256 public saleWeiLimitWithoutKYC;  
    bool public finished;  

    uint256 public constant ONE_MILLION = 1000000;  
    uint256 public constant PRE_SALE_GMR_TOKEN_CAP = 15 * ONE_MILLION * 1 ether;  
    uint256 public constant GMR_TOKEN_SALE_CAP = 100 * ONE_MILLION * 1 ether;  
    uint256 public constant MIN_ETHER = 0.1 ether;  

     
    uint256 public constant PRE_SALE_30_ETH = 30 ether;  
    uint256 public constant PRE_SALE_300_ETH = 300 ether;  
    uint256 public constant PRE_SALE_1000_ETH = 1000 ether;  

     
    uint256 public constant TOKEN_RATE_BASE_RATE = 2500;  
    uint256 public constant TOKEN_RATE_05_PERCENT_BONUS = 2625;  
    uint256 public constant TOKEN_RATE_10_PERCENT_BONUS = 2750;  
    uint256 public constant TOKEN_RATE_15_PERCENT_BONUS = 2875;  
    uint256 public constant TOKEN_RATE_20_PERCENT_BONUS = 3000;  
    uint256 public constant TOKEN_RATE_25_PERCENT_BONUS = 3125;  
    uint256 public constant TOKEN_RATE_30_PERCENT_BONUS = 3250;  
    uint256 public constant TOKEN_RATE_40_PERCENT_BONUS = 3500;  

     
    uint256 public constant PRE_SALE_START_TIME = 1525176000;  
    uint256 public constant PRE_SALE_END_TIME = 1525521600;  
    uint256 public constant START_WEEK_1 = 1525608000;  
    uint256 public constant START_WEEK_2 = 1526040000;  
    uint256 public constant START_WEEK_3 = 1526472000;  
    uint256 public constant START_WEEK_4 = 1526904000;  
    uint256 public constant SALE_END_TIME = 1527336000;  

     
    modifier onlyKycManager() {
        require(msg.sender == kycManagerWallet);
        _;
    }

     
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

     
    event KYC(address indexed user, bool isApproved);

     
    function GimmerTokenSale(
        address _fundWallet,
        address _kycManagerWallet,
        uint256 _saleWeiLimitWithoutKYC,
        uint256 _maxTxGas
    )
    public
    {
        require(_fundWallet != address(0));
        require(_kycManagerWallet != address(0));
        require(_saleWeiLimitWithoutKYC > 0);
        require(_maxTxGas > 0);

        currentAddress = this;

        fundWallet = _fundWallet;
        kycManagerWallet = _kycManagerWallet;
        saleWeiLimitWithoutKYC = _saleWeiLimitWithoutKYC;
        maxTxGas = _maxTxGas;

        token = new GimmerToken();
    }

     
    function () public payable {
        buyTokens();
    }

     
    function buyTokens() public payable whenNotPaused {
         
         
         
        require(tx.gasprice <= maxTxGas);
         
         
         
        require(validPurchase());

        address sender = msg.sender;
        uint256 weiAmountSent = msg.value;

         
        uint256 rate = getRate(weiAmountSent);
        uint256 newTokens = weiAmountSent.mul(rate);

         
        uint256 totalTokensSold = tokensSold.add(newTokens);
        if (isCrowdSaleRunning()) {
            require(totalTokensSold <= GMR_TOKEN_SALE_CAP);
        } else if (isPreSaleRunning()) {
            require(totalTokensSold <= PRE_SALE_GMR_TOKEN_CAP);
        }

         
        Supporter storage sup = supportersMap[sender];
        uint256 totalWei = sup.weiSpent.add(weiAmountSent);
        sup.weiSpent = totalWei;

         
        weiRaised = weiRaised.add(weiAmountSent);
        tokensSold = totalTokensSold;

         
        token.mint(sender, newTokens);
        TokenPurchase(sender, weiAmountSent, newTokens);

         
        fundWallet.transfer(msg.value);
    }

     
    function finishContract() public onlyOwner {
         
        require(now > SALE_END_TIME);
        require(!finished);

        finished = true;

         
        uint256 tenPC = tokensSold.div(10);
        token.mint(fundWallet, tenPC);

         
        token.finishMinting();

         
         
        token.transferOwnership(fundWallet);
    }

    function setSaleWeiLimitWithoutKYC(uint256 _newSaleWeiLimitWithoutKYC) public onlyKycManager {
        require(_newSaleWeiLimitWithoutKYC > 0);
        saleWeiLimitWithoutKYC = _newSaleWeiLimitWithoutKYC;
    }

     
    function updateMaxTxGas(uint256 _newMaxTxGas) public onlyKycManager {
        require(_newMaxTxGas > 0);
        maxTxGas = _newMaxTxGas;
    }

     
    function approveUserKYC(address _user) onlyKycManager public {
        require(_user != address(0));

        Supporter storage sup = supportersMap[_user];
        sup.hasKYC = true;
        KYC(_user, true);
    }

     
    function disapproveUserKYC(address _user) onlyKycManager public {
        require(_user != address(0));

        Supporter storage sup = supportersMap[_user];
        sup.hasKYC = false;
        KYC(_user, false);
    }

     
    function setKYCManager(address _newKYCManagerWallet) onlyOwner public {
        require(_newKYCManagerWallet != address(0));
        kycManagerWallet = _newKYCManagerWallet;
    }

     
    function isTokenSaleRunning() public constant returns (bool) {
        return (isPreSaleRunning() || isCrowdSaleRunning());
    }

     
    function isPreSaleRunning() public constant returns (bool) {
        return (now >= PRE_SALE_START_TIME && now < PRE_SALE_END_TIME);
    }

     
    function isCrowdSaleRunning() public constant returns (bool) {
        return (now >= START_WEEK_1 && now <= SALE_END_TIME);
    }

     
    function hasEnded() public constant returns (bool) {
        return now > SALE_END_TIME;
    }

     
    function hasPreSaleEnded() public constant returns (bool) {
        return now > PRE_SALE_END_TIME;
    }

     
    function userHasKYC(address _user) public constant returns (bool) {
        return supportersMap[_user].hasKYC;
    }

     
    function userWeiSpent(address _user) public constant returns (uint256) {
        return supportersMap[_user].weiSpent;
    }

     
    function getRate(uint256 _weiAmount) internal constant returns (uint256) {
        if (isCrowdSaleRunning()) {
            if (now >= START_WEEK_4) { return TOKEN_RATE_05_PERCENT_BONUS; }
            else if (now >= START_WEEK_3) { return TOKEN_RATE_10_PERCENT_BONUS; }
            else if (now >= START_WEEK_2) { return TOKEN_RATE_15_PERCENT_BONUS; }
            else if (now >= START_WEEK_1) { return TOKEN_RATE_20_PERCENT_BONUS; }
        }
        else if (isPreSaleRunning()) {
            if (_weiAmount >= PRE_SALE_1000_ETH) { return TOKEN_RATE_40_PERCENT_BONUS; }
            else if (_weiAmount >= PRE_SALE_300_ETH) { return TOKEN_RATE_30_PERCENT_BONUS; }
            else if (_weiAmount >= PRE_SALE_30_ETH) { return TOKEN_RATE_25_PERCENT_BONUS; }
        }
    }

     
    function validPurchase() internal constant returns (bool) {
        bool userHasKyc = userHasKYC(msg.sender);

        if (isCrowdSaleRunning()) {
             
            if(!userHasKyc) {
                Supporter storage sup = supportersMap[msg.sender];
                uint256 ethContribution = sup.weiSpent.add(msg.value);
                if (ethContribution > saleWeiLimitWithoutKYC) {
                    return false;
                }
            }
            return msg.value >= MIN_ETHER;
        }
        else if (isPreSaleRunning()) {
             
            return userHasKyc && msg.value >= PRE_SALE_30_ETH;
        } else {
            return false;
        }
    }
}

 

 
contract GMRTokenManager is Ownable {
    using SafeMath for uint256;

     
    GMRToken public token;
    GimmerTokenSale public oldTokenSale;

     
    bool public finishedMigration;

     
    uint256 public constant TOKEN_BONUS_RATE = 8785;  

     
    function GMRTokenManager(address _oldTokenSaleAddress) public {
         
        oldTokenSale = GimmerTokenSale(_oldTokenSaleAddress);

         
        token = new GMRToken();
    }

     
    function prepopulate(address _wallet) public onlyOwner {
        require(!finishedMigration);
        require(_wallet != address(0));

         
        uint256 spent = oldTokenSale.userWeiSpent(_wallet);
        require(spent != 0);

         
        uint256 balance = token.balanceOf(_wallet);
        require(balance == 0);

         
        uint256 tokens = spent.mul(TOKEN_BONUS_RATE);

         
        token.mint(_wallet, tokens);
    }

     
    function endMigration() public onlyOwner {
        require(!finishedMigration);
        finishedMigration = true;

        token.transferOwnership(owner);
    }
}