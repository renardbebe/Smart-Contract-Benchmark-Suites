 

pragma solidity 0.4.19;

 

 
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

 

 
contract BurnableToken is StandardToken, Ownable {

    event Burn(address indexed burner, uint256 amount);

     
    function burn(uint256 _amount) public {
        burnInternal(msg.sender, _amount);
    }

     
    function burnFrom(address _from, uint256 _amount) public onlyOwner {
        burnInternal(_from, _amount);
    }

     
    function burnInternal(address _from, uint256 _amount) internal {
        require(_from != address(0));
        require(_amount > 0);
        require(_amount <= balances[_from]);
         
         

        balances[_from] = balances[_from].sub(_amount);
        totalSupply_ = totalSupply_.sub(_amount);
        Transfer(_from, address(0), _amount);
        Burn(_from, _amount);
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

 

contract GiftToken is BurnableToken, Pausable {

    string public name = "Giftcoin";
    string public symbol = "GIFT";
    uint8 public decimals = 18;
  
    uint256 public initialTotalSupply = uint256(1e8) * (uint256(10) ** decimals);

    address private addressIco;

    modifier onlyIco() {
        require(msg.sender == addressIco);
        _;
    }

     
    function GiftToken(address _ico) public {
        pause();
        setIcoAddress(_ico);

        totalSupply_ = initialTotalSupply;
        balances[_ico] = balances[_ico].add(initialTotalSupply);
        Transfer(address(0), _ico, initialTotalSupply);
    }

    function setIcoAddress(address _ico) public onlyOwner {
        require(_ico != address(0));
         
        require(balanceOf(addressIco) == 0);

        addressIco = _ico;
  
         
         
         
        transferOwnership(_ico);
    }

     
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
    function transferFromIco(address _to, uint256 _value) public onlyIco returns (bool) {
        return super.transfer(_to, _value);
    }
}

 

 
contract Whitelist is Ownable {
    struct WalletInfo {
        string data;
        bool whitelisted;
        uint256 createdTimestamp;
    }

    address public backendAddress;

    mapping(address => WalletInfo) public whitelist;

    uint256 public whitelistLength = 0;

     
    function setBackendAddress(address _backendAddress) public onlyOwner {
        require(_backendAddress != address(0));
        backendAddress = _backendAddress;
    }

     
    modifier onlyPrivilegedAddresses() {
        require(msg.sender == owner || msg.sender == backendAddress);
        _;
    }

       
    function addWallet(address _wallet, string _data) public onlyPrivilegedAddresses {
        require(_wallet != address(0));
        require(!isWhitelisted(_wallet));
        whitelist[_wallet].data = _data;
        whitelist[_wallet].whitelisted = true;
        whitelist[_wallet].createdTimestamp = now;
        whitelistLength++;
    }

           
    function updateWallet(address _wallet, string _data) public onlyPrivilegedAddresses {
        require(_wallet != address(0));
        require(isWhitelisted(_wallet));
        whitelist[_wallet].data = _data;
    }

       
    function removeWallet(address _wallet) public onlyPrivilegedAddresses {
        require(_wallet != address(0));
        require(isWhitelisted(_wallet));
        delete whitelist[_wallet];
        whitelistLength--;
    }

      
    function isWhitelisted(address _wallet) public view returns (bool) {
        return whitelist[_wallet].whitelisted;
    }

      
    function walletData(address _wallet) public view returns (string) {
        return whitelist[_wallet].data;
    }

     
    function walletCreatedTimestamp(address _wallet) public view returns (uint256) {
        return whitelist[_wallet].createdTimestamp;
    }
}

 

contract GiftCrowdsale is Pausable {
    using SafeMath for uint256;

    uint256 public startTimestamp = 0;

    uint256 public endTimestamp = 0;

    uint256 public exchangeRate = 0;

    uint256 public tokensSold = 0;

    uint256 constant public minimumInvestment = 25e16;  

    uint256 public minCap = 0;

    uint256 public endFirstPeriodTimestamp = 0;
    uint256 public endSecondPeriodTimestamp = 0;
    uint256 public endThirdPeriodTimestamp = 0;

    GiftToken public token;
    Whitelist public whitelist;

    mapping(address => uint256) public investments;

    modifier beforeSaleOpens() {
        require(now < startTimestamp);
        _;
    }

    modifier whenSaleIsOpen() {
        require(now >= startTimestamp && now < endTimestamp);
        _;
    }

    modifier whenSaleHasEnded() {
        require(now >= endTimestamp);
        _;
    }

     
    function GiftCrowdsale (
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _exchangeRate,
        uint256 _minCap
    )
        public
    {
        require(_startTimestamp >= now && _endTimestamp > _startTimestamp);
        require(_exchangeRate > 0);

        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;

        exchangeRate = _exchangeRate;

        endFirstPeriodTimestamp = _startTimestamp.add(1 days);
        endSecondPeriodTimestamp = _startTimestamp.add(1 weeks);
        endThirdPeriodTimestamp = _startTimestamp.add(2 weeks);

        minCap = _minCap;

        pause();
    }

    function discount() public view returns (uint256) {
        if (now > endThirdPeriodTimestamp)
            return 0;
        if (now > endSecondPeriodTimestamp)
            return 5;
        if (now > endFirstPeriodTimestamp)
            return 15;
        return 25;
    }

    function bonus(address _wallet) public view returns (uint256) {
        uint256 _created = whitelist.walletCreatedTimestamp(_wallet);
        if (_created > 0 && _created < startTimestamp) {
            return 10;
        }
        return 0;
    }

     
    function sellTokens() public payable whenSaleIsOpen whenWhitelisted(msg.sender) whenNotPaused {
        require(msg.value > minimumInvestment);
        uint256 _bonus = bonus(msg.sender);
        uint256 _discount = discount();
        uint256 tokensAmount = (msg.value).mul(exchangeRate).mul(_bonus.add(100)).div((100 - _discount));

        token.transferFromIco(msg.sender, tokensAmount);

        tokensSold = tokensSold.add(tokensAmount);

        addInvestment(msg.sender, msg.value);
    }

     
    function() public payable {
        sellTokens();
    }

     
    function withdrawal(address _wallet) external onlyOwner whenSaleHasEnded {
        require(_wallet != address(0));
        _wallet.transfer(this.balance);

        token.transferOwnership(msg.sender);
    }

     
    function assignTokens(address _to, uint256 _value) external onlyOwner {
        token.transferFromIco(_to, _value);

        tokensSold = tokensSold.add(_value);
    }

     
    function addInvestment(address _from, uint256 _value) internal {
        investments[_from] = investments[_from].add(_value);
    }

     
    function refundPayment() external whenWhitelisted(msg.sender) whenSaleHasEnded {
        require(tokensSold < minCap);
        require(investments[msg.sender] > 0);

        token.burnFrom(msg.sender, token.balanceOf(msg.sender));

        uint256 investment = investments[msg.sender];
        investments[msg.sender] = 0;
        (msg.sender).transfer(investment);
    }

     
    function transferTokenOwnership(address _newOwner) public onlyOwner {
        token.transferOwnership(_newOwner);
    }

    function updateIcoEnding(uint256 _endTimestamp) public onlyOwner {
        endTimestamp = _endTimestamp;
    }

    modifier whenWhitelisted(address _wallet) {
        require(whitelist.isWhitelisted(_wallet));
        _;
    }

    function init(address _token, address _whitelist) public onlyOwner {
        require(_token != address(0) && _whitelist != address(0));
         
        require(token == address(0) && whitelist == address(0));
         
        require(Ownable(_token).owner() == address(this));

        token = GiftToken(_token);
        whitelist = Whitelist(_whitelist);

        unpause();
    }

     
    function unpause() public onlyOwner whenPaused {
        require(token != address(0) && whitelist != address(0));
        super.unpause();
    }

     
    function setExchangeRate(uint256 _exchangeRate) public onlyOwner beforeSaleOpens {
        require(_exchangeRate > 0);

        exchangeRate = _exchangeRate;
    }
}