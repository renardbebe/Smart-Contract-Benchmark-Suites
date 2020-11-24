 

pragma solidity ^0.4.25;

 

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {  
    require(msg.sender == owner);               
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

 
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

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    
     
    require(_to != address(0));

     
     
    require(balances[msg.sender] >= _value);

     
     
    require(balances[_to] + _value >= balances[_to]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);

     
    balances[_to] = balances[_to].add(_value);

     
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

}


 

contract StandardToken is ERC20, BasicToken {

   
  mapping (address => mapping (address => uint256)) allowed;

   
   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     
    require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  
   
  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

 
contract TokenSaleKYC is Ownable {
    
     
    mapping(address=>bool) public verified;

     
    event VerificationStatusUpdated(address participant, bool verificationStatus);

     
    function updateVerificationStatus(address participant, bool verificationStatus) public onlyOwner {
        verified[participant] = verificationStatus;
        emit VerificationStatusUpdated(participant, verificationStatus);
    }

     
    function updateVerificationStatuses(address[] participants, bool verificationStatus) public onlyOwner {
        for (uint i = 0; i < participants.length; i++) {
            updateVerificationStatus(participants[i], verificationStatus);
        }
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 
contract DigiPayToken is StandardToken, Ownable, TokenSaleKYC, Pausable {
  using SafeMath for uint256; 
  string  public name;
  string  public symbol;
  uint8   public decimals;

  uint256 public weiRaised;
  uint256 public hardCap;

  address public wallet;
  address public TEAM_WALLET;
  address public AIRDROP_WALLET;
  address public RESERVE_WALLET;

  uint    internal _totalSupply;
  uint    internal _teamAmount;
  uint    internal _airdropAmount;
  uint    internal _reserveAmount;

  uint256 internal presaleStartTime;
  uint256 internal presaleEndTime;
  uint256 internal mainsaleStartTime;
  uint256 internal mainsaleEndTime;

  bool    internal presaleOpen;
  bool    internal mainsaleOpen;
  bool    internal Open;
  bool    public   locked;
  
     
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);
    event Burn(address indexed burner, uint tokens);

     
    modifier onlyWhileOpen {
        require(now >= presaleStartTime && now <= mainsaleEndTime && Open && weiRaised <= hardCap);
        _;
    }
    
     
     
    modifier onlyUnlocked() {
        require(msg.sender == AIRDROP_WALLET || msg.sender == RESERVE_WALLET || msg.sender == owner || !locked);
        _;
    }

     
    constructor (address _owner, address _wallet, address _team, address _airdrop, address _reserve) public {

        _setTimes();
        
        name = "DigiPay";
        symbol = "DIP";
        decimals = 18;
        hardCap = 20000 ether;

        owner = _owner;
        wallet = _wallet;
        TEAM_WALLET = _team;
        AIRDROP_WALLET = _airdrop;
        RESERVE_WALLET = _reserve;

         
        _totalSupply = 180000000e18;
         
        _teamAmount = 36000000e18;
         
        _airdropAmount = 14400000e18;
         
        _reserveAmount = 3600000e18;

        balances[this] = totalSupply();
        emit Transfer(address(0x0),this, totalSupply());
        _transfer(TEAM_WALLET, _teamAmount);
        _transfer(AIRDROP_WALLET, _airdropAmount);
        _transfer(RESERVE_WALLET, _reserveAmount);

        Open = true;
        locked = true;
        
    }

    function updateWallet(address _wallet) public onlyOwner {
        wallet = _wallet;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function _setTimes() internal {   
        presaleStartTime          = 1541062800;  
        presaleEndTime            = 1543481999;  
        mainsaleStartTime         = 1545296400;  
        mainsaleEndTime           = 1548320399;  
    }

    function unlock() public onlyOwner {
        locked = false;
    }

    function lock() public onlyOwner {
        locked = true;
    }

     
    function transfer(address _to, uint _value) public onlyUnlocked returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value) public onlyUnlocked returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
    function _checkOpenings() internal {
        
        if(now >= presaleStartTime && now <= presaleEndTime) {
            presaleOpen = true;
            mainsaleOpen = false;
        }
        else if(now >= mainsaleStartTime && now <= mainsaleEndTime) {
            presaleOpen = false;
            mainsaleOpen = true;
        }
        else {
            presaleOpen = false;
            mainsaleOpen = false;
        }
    }
    
     
    function () external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _beneficiary) internal onlyWhileOpen whenNotPaused {
    
         
        uint256 weiAmount = msg.value;
    
         
        require(_beneficiary != address(0));
        require(weiAmount != 0);
    
        _checkOpenings();

         
        require(verified[_beneficiary]);

        require(presaleOpen || mainsaleOpen);
        
        if(presaleOpen) {
             
            require(weiAmount >= 2e18  && weiAmount <= 5e20);
        }
        else {
             
            require(weiAmount >= 2e17  && weiAmount <= 5e20);
        }
        
         
        uint256 tokens = _getTokenAmount(weiAmount);
        
         
        if(weiAmount >= 10e18) {
            tokens = tokens.add(weiAmount.mul(500));
        }
        
         
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);

         
        emit TokenPurchase(_beneficiary, weiAmount, tokens);

        _forwardFunds(msg.value);
    }
    
     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {

        uint256 RATE;
        if(presaleOpen) {
            RATE = 7500;  
        }
        
        if(now >= mainsaleStartTime && now < (mainsaleStartTime + 1 weeks)) {
            RATE = 6000;  
        }
        
        if(now >= (mainsaleStartTime + 1 weeks) && now < (mainsaleStartTime + 2 weeks)) {
            RATE = 5750;  
        }
        
        if(now >= (mainsaleStartTime + 2 weeks) && now < (mainsaleStartTime + 3 weeks)) {
            RATE = 5500;  
        }
        
        if(now >= (mainsaleStartTime + 3 weeks) && now < (mainsaleStartTime + 4 weeks)) {
            RATE = 5250;  
        }
        
        if(now >= (mainsaleStartTime + 4 weeks) && now <= mainsaleEndTime) {
            RATE = 5000;  
        }

        return _weiAmount.mul(RATE);
    }
    
     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        _transfer(_beneficiary, _tokenAmount);
    }

     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }
    
     
    function _forwardFunds(uint256 _amount) internal {
        wallet.transfer(_amount);
    }
    
    
     
    function _transfer(address to, uint256 tokens) internal returns (bool success) {
        require(to != 0x0);
        require(balances[this] >= tokens );
        require(balances[to] + tokens >= balances[to]);
        balances[this] = balances[this].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(this,to,tokens);
        return true;
    }
    
     
    function stopTokenSale() public onlyOwner {
        Open = false;
    }
    
     
    function sendtoMultiWallets(address[] _addresses, uint256[] _values) public onlyOwner {
        require(_addresses.length == _values.length);
        for (uint256 i = 0; i < _addresses.length; i++) {
             
            balances[AIRDROP_WALLET] = balances[AIRDROP_WALLET].sub(_values[i]*10**uint(decimals));
            balances[_addresses[i]] = balances[_addresses[i]].add(_values[i]*10**uint(decimals));
            emit Transfer(AIRDROP_WALLET, _addresses[i], _values[i]*10**uint(decimals));
        }
    }
    
     
    function drainRemainingToken(address _to, uint256 _value) public onlyOwner {
       require(now > mainsaleEndTime);
       _transfer(_to, _value);
    }
    
     
    function burnRemainingToken(uint256 _value) public onlyOwner returns (bool) {
        balances[this] = balances[this].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(this, _value);
        emit Transfer(this, address(0x0), _value);
        return true;
    }

}