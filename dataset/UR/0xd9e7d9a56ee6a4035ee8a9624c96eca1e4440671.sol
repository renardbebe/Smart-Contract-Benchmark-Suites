 

pragma solidity ^0.4.18;

 

 
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

 

 
contract CrowdsaleAuthorizer {
    mapping(address => uint256)    public participated;
    mapping(address => bool)       public whitelistAddresses;

    address                        public admin;
    uint256                        public saleStartTime;
    uint256                        public saleEndTime;
    uint256                        public increaseMaxContribTime;
    uint256                        public minContribution;
    uint256                        public maxContribution;

    using SafeMath for uint256;

     
    modifier onlyAdmin() {
      require(msg.sender == admin);
      _;
    }

     
    modifier validAddress(address _addr) {
      require(_addr != address(0x0));
      require(_addr != address(this));
      _;
    }

     
    function CrowdsaleAuthorizer(
        address _admin,
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        uint256 _increaseMaxContribTime,
        uint256 _minContribution,
        uint256 _maxContribution
    )
        validAddress(_admin)
        public
    {
        require(_saleStartTime > now);
        require(_saleEndTime > now);
        require(_increaseMaxContribTime > now);
        require(_saleStartTime < _saleEndTime);
        require(_increaseMaxContribTime > _saleStartTime);
        require(_maxContribution > 0);
        require(_minContribution < _maxContribution);

        admin = _admin;
        saleStartTime = _saleStartTime;
        saleEndTime = _saleEndTime;
        increaseMaxContribTime = _increaseMaxContribTime;

        minContribution = _minContribution;
        maxContribution = _maxContribution;
    }

    event UpdateWhitelist(address _user, bool _allow, uint _time);

     
    function updateWhitelist(address _user, bool _allow)
        public
        onlyAdmin
    {
        whitelistAddresses[_user] = _allow;
        UpdateWhitelist(_user, _allow, now);
    }

     
    function updateWhitelists(address[] _users, bool[] _allows)
        external
        onlyAdmin
    {
        require(_users.length == _allows.length);
        for (uint i = 0 ; i < _users.length ; i++) {
            address _user = _users[i];
            bool _allow = _allows[i];
            whitelistAddresses[_user] = _allow;
            UpdateWhitelist(_user, _allow, now);
        }
    }

     
    function eligibleAmount(address _contributor, uint256 _amount)
        public
        view
        returns(uint256)
    {
         
        if (!saleStarted() || saleEnded()) {
            return 0;
        }

         
        if (_amount < minContribution) {
            return 0;
        }

        uint256 userMaxContribution = maxContribution;
         
        if (now >= increaseMaxContribTime) {
            userMaxContribution = maxContribution.mul(10);
        }

         
        uint256 remainingCap = userMaxContribution.sub(participated[_contributor]);

         
        return (remainingCap > _amount) ? _amount : remainingCap;
    }

     
    function saleStarted() public view returns(bool) {
        return now >= saleStartTime;
    }

     
    function saleEnded() public view returns(bool) {
        return now > saleEndTime;
    }

     
    function eligibleAmountCheck(address _contributor, uint256 _amount)
        internal
        returns(uint256)
    {
         
        if (!whitelistAddresses[_contributor]) {
            return 0;
        }

        uint256 result = eligibleAmount(_contributor, _amount);
        participated[_contributor] = participated[_contributor].add(result);

        return result;
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

 

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
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

 

 
contract PolicyPalNetworkToken is StandardToken, BurnableToken, Ownable {
     
    string    public constant name     = "PolicyPal Network Token";
    string    public constant symbol   = "PAL";
    uint8     public constant decimals = 18;

     
    address public  tokenSaleContract;
    bool    public  isTokenTransferable = false;


     
    modifier onlyWhenTransferAllowed() {
        require(isTokenTransferable || msg.sender == owner || msg.sender == tokenSaleContract);
        _;
    }

     
    modifier isValidDestination(address _to) {
        require(_to != address(0x0));
        require(_to != address(this));
        _;
    }

     
    function toggleTransferable(bool _toggle) external
        onlyOwner
    {
        isTokenTransferable = _toggle;
    }
    

     
    function PolicyPalNetworkToken(
        uint _tokenTotalAmount,
        address _adminAddr
    ) 
        public
        isValidDestination(_adminAddr)
    {
        require(_tokenTotalAmount > 0);

        totalSupply_ = _tokenTotalAmount;

         
        balances[msg.sender] = _tokenTotalAmount;
        Transfer(address(0x0), msg.sender, _tokenTotalAmount);

         
        tokenSaleContract = msg.sender;

         
        transferOwnership(_adminAddr);
    }

     
    function transfer(address _to, uint256 _value) public
        onlyWhenTransferAllowed
        isValidDestination(_to)
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public
        onlyWhenTransferAllowed
        isValidDestination(_to)
        returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }

     
    function burn(uint256 _value)
        public
    {
        super.burn(_value);
        Transfer(msg.sender, address(0x0), _value);
    }

     
    function emergencyERC20Drain(ERC20 _token, uint256 _amount) public
        onlyOwner
    {
        _token.transfer(owner, _amount);
    }
}

 

 
contract PolicyPalNetworkCrowdsale is CrowdsaleAuthorizer {
     
    address                 public multiSigWallet;
    PolicyPalNetworkToken   public token;
    uint256                 public raisedWei;
    bool                    public haltSale;
    uint                    public rate;

     
    modifier validSale() {
      require(!haltSale);
      require(saleStarted());
      require(!saleEnded());
      _;
    }

     
    event Buy(address _buyer, uint256 _tokens, uint256 _payedWei);

     
    function PolicyPalNetworkCrowdsale(
        address _admin,
        address _multiSigWallet,
        uint256 _totalTokenSupply,
        uint256 _premintedTokenSupply,
        uint256 _presaleTokenSupply,
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        uint256 _increaseMaxContribTime,
        uint    _rate,
        uint256 _minContribution,
        uint256 _maxContribution
    )
    CrowdsaleAuthorizer(
        _admin,
        _saleStartTime,
        _saleEndTime,
        _increaseMaxContribTime,
        _minContribution,
        _maxContribution
    )
        validAddress(_multiSigWallet)
        public
    {
        require(_totalTokenSupply > 0);
        require(_premintedTokenSupply > 0);
        require(_presaleTokenSupply > 0);
        require(_rate > 0);
        
        require(_premintedTokenSupply < _totalTokenSupply);
        require(_presaleTokenSupply < _totalTokenSupply);

        multiSigWallet = _multiSigWallet;
        rate = _rate;

        token = new PolicyPalNetworkToken(
            _totalTokenSupply,
            _admin
        );

         
        token.transfer(multiSigWallet, _premintedTokenSupply);
         
        token.transfer(_admin, _presaleTokenSupply);
    }

     
    function setHaltSale(bool _halt)
        onlyAdmin
        public
    {
        haltSale = _halt;
    }

     
    function() public payable {
        buy(msg.sender);
    }

     
    function buy(address _recipient) public payable
        validSale
        validAddress(_recipient)
        returns(uint256)
    {
         
        uint256 weiContributionAllowed = eligibleAmountCheck(_recipient, msg.value);
        require(weiContributionAllowed > 0);

         
        uint256 tokensRemaining = token.balanceOf(address(this));
        require(tokensRemaining > 0);

         
        uint256 receivedTokens = weiContributionAllowed.mul(rate);

         
         
        if (receivedTokens > tokensRemaining) {
            receivedTokens = tokensRemaining;
            weiContributionAllowed = tokensRemaining.div(rate);
        }

         
        assert(token.transfer(_recipient, receivedTokens));

         
        sendETHToMultiSig(weiContributionAllowed);
        raisedWei = raisedWei.add(weiContributionAllowed);

         
         
        if (msg.value > weiContributionAllowed) {
            msg.sender.transfer(msg.value.sub(weiContributionAllowed));
        }

         
        Buy(_recipient, receivedTokens, weiContributionAllowed);

        return weiContributionAllowed;
    }

     
    function emergencyDrain(ERC20 _anyToken) public
        onlyAdmin
        returns(bool)
    {
        if (this.balance > 0) {
            sendETHToMultiSig(this.balance);
        }
        if (_anyToken != address(0x0)) {
            assert(_anyToken.transfer(multiSigWallet, _anyToken.balanceOf(this)));
        }
        return true;
    }

     
    function sendETHToMultiSig(uint256 _value) internal {
        multiSigWallet.transfer(_value);
    }
}