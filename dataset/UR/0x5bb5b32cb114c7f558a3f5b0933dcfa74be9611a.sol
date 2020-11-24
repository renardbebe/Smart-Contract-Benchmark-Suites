 

pragma solidity ^0.4.13;

contract Utils {
     
    function Utils() {
    }

     
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

     
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

     
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

     

     
    function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

contract IERC20Token {
     
    function name() public constant returns (string name) { name; }
    function symbol() public constant returns (string symbol) { symbol; }
    function decimals() public constant returns (uint8 decimals) { decimals; }
    function totalSupply() public constant returns (uint256 totalSupply) { totalSupply; }
    function balanceOf(address _owner) public constant returns (uint256 balance) { _owner; balance; }
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) { _owner; _spender; remaining; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

contract ERC20Token is IERC20Token, Utils {
    string public standard = 'Token 0.1';
    string public name = '';
    string public symbol = '';
    uint8 public decimals = 0;
    uint256 public totalSupply = 0;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function ERC20Token(string _name, string _symbol, uint8 _decimals) {
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0);  

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

     
    function transfer(address _to, uint256 _value)
        public
        validAddress(_to)
        returns (bool success)
    {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool success)
    {
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value)
        public
        validAddress(_spender)
        returns (bool success)
    {
         
        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract IOwned {
     
    function owner() public constant returns (address owner) { owner; }

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

     
    function Owned() {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

contract ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
}

contract TokenHolder is ITokenHolder, Owned, Utils {
     
    function TokenHolder() {
    }

     
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        assert(_token.transfer(_to, _amount));
    }
}

contract SmartTokenController is TokenHolder {
    ISmartToken public token;    

     
    function SmartTokenController(ISmartToken _token)
        validAddress(_token)
    {
        token = _token;
    }

     
    modifier active() {
        assert(token.owner() == address(this));
        _;
    }

     
    modifier inactive() {
        assert(token.owner() != address(this));
        _;
    }

     
    function transferTokenOwnership(address _newOwner) public ownerOnly {
        token.transferOwnership(_newOwner);
    }

     
    function acceptTokenOwnership() public ownerOnly {
        token.acceptOwnership();
    }

     
    function disableTokenTransfers(bool _disable) public ownerOnly {
        token.disableTransfers(_disable);
    }

     
    function withdrawFromToken(IERC20Token _token, address _to, uint256 _amount) public ownerOnly {
        token.withdrawTokens(_token, _to, _amount);
    }
}

contract ISmartToken is ITokenHolder, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

contract SmartToken is ISmartToken, Owned, ERC20Token, TokenHolder {
    string public version = '0.3';

    bool public transfersEnabled = true;     

     
    event NewSmartToken(address _token);
     
    event Issuance(uint256 _amount);
     
    event Destruction(uint256 _amount);

     
    function SmartToken(string _name, string _symbol, uint8 _decimals)
        ERC20Token(_name, _symbol, _decimals)
    {
        NewSmartToken(address(this));
    }

     
    modifier transfersAllowed {
        assert(transfersEnabled);
        _;
    }

     
    function disableTransfers(bool _disable) public ownerOnly {
        transfersEnabled = !_disable;
    }

     
    function issue(address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_to)
        notThis(_to)
    {
        totalSupply = safeAdd(totalSupply, _amount);
        balanceOf[_to] = safeAdd(balanceOf[_to], _amount);

        Issuance(_amount);
        Transfer(this, _to, _amount);
    }

     
    function destroy(address _from, uint256 _amount) public {
        require(msg.sender == _from || msg.sender == owner);  

        balanceOf[_from] = safeSub(balanceOf[_from], _amount);
        totalSupply = safeSub(totalSupply, _amount);

        Transfer(_from, this, _amount);
        Destruction(_amount);
    }

     

     
    function transfer(address _to, uint256 _value) public transfersAllowed returns (bool success) {
        assert(super.transfer(_to, _value));
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed returns (bool success) {
        assert(super.transferFrom(_from, _to, _value));
        return true;
    }
}

contract KickcityAbstractCrowdsale is Owned, SmartTokenController {
  uint256 public etherHardCap = 14706 ether;  
  uint256 public etherCollected = 0;

  uint256 public USD_IN_ETH = 850;  

  function setUsdEthRate(uint256 newrate) ownerOnly {
    USD_IN_ETH = newrate;
    oneEtherInKicks = newrate * 10;
  }

  function usdCollected() constant public returns(uint256) {
    return safeMul(etherCollected, USD_IN_ETH) / 1 ether;
  }

  function setHardCap(uint256 newCap) ownerOnly {
     etherHardCap = newCap;
  }

  uint256 public saleStartTime;
  uint256 public saleEndTime;

  modifier duringSale() {
    assert(now >= saleStartTime && now < saleEndTime);
    _;
  }

  uint256 private maxGasPrice = 0.06 szabo;  

  modifier validGasPrice() {
    assert(tx.gasprice <= maxGasPrice);
    _;
  }

  address public kickcityWallet;

  function KickcityAbstractCrowdsale(uint256 start, uint256 end, KickcityToken _token, address beneficiary) SmartTokenController(_token) {
    assert(start < end);
    assert(beneficiary != 0x0);
    saleStartTime = start;
    saleEndTime = end;
    kickcityWallet = beneficiary;
  }

   
  uint256 public oneEtherInKicks = 8500;
  uint256 public minEtherContrib = 59 finney;  

  function calcKicks(uint256 etherVal) constant public returns (uint256 kicksVal);

   
  event Contribution(address indexed contributor, uint256 contributed, uint256 tokensReceived);

  function processContribution() private validGasPrice duringSale {
    uint256 leftToCollect = safeSub(etherHardCap, etherCollected);
    uint256 contribution = msg.value > leftToCollect ? leftToCollect : msg.value;
    uint256 change = safeSub(msg.value, contribution);

    if (contribution > 0) {
      uint256 kicks = calcKicks(contribution);

       
      kickcityWallet.transfer(contribution);

       
      token.issue(msg.sender, kicks);
      etherCollected = safeAdd(etherCollected, contribution);
      Contribution(msg.sender, contribution, kicks);
    }

     
    if (change > 0) {
      msg.sender.transfer(change);
    }
  }

  function () payable {
    if (msg.value > 0) {
      processContribution();
    }
  }
}

contract KickcityCrowdsale is KickcityAbstractCrowdsale {
  function KickcityCrowdsale(uint256 start, uint256 end, KickcityToken _token, address beneficiary) KickcityAbstractCrowdsale(start, end, _token, beneficiary) { }

  function calcKicks(uint256 etherVal) constant public returns (uint256 kicksVal) {
    assert(etherVal >= minEtherContrib);
    uint256 value = safeMul(etherVal, oneEtherInKicks);
    if (now <= saleStartTime + 1 days) {
       
      kicksVal = safeAdd(value, safeMul(value / 100, 15)); 
    } else if (now <= saleStartTime + 10 days) {
       
      kicksVal = safeAdd(value, value / 10); 
    } else if (now <= saleStartTime + 20 days) {
       
      kicksVal = safeAdd(value, value / 20);
    } else {
      kicksVal = value;
    }
  }
}

contract KickcityToken is SmartToken {
    function KickcityToken() SmartToken("KickCity Token", "KCY", 18) { 
        disableTransfers(true);
     }
}