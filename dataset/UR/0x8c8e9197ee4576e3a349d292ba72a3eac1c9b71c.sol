 

pragma solidity ^0.4.23;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
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


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;
  
  bool public stopped = false;
  
  event Stop(address indexed from);
  
  event Start(address indexed from);
  
  modifier isRunning {
    assert (!stopped);
    _;
  }

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) isRunning public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 ownerBalance) {
    return balances[_owner];
  }
  
  function stop() onlyOwner public {
    stopped = true;
    emit Stop(msg.sender);
  }

  function start() onlyOwner public {
    stopped = false;
    emit Start(msg.sender);
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) isRunning public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) isRunning public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) isRunning public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) isRunning public returns (bool) {
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

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}


 
contract CappedMintableToken is StandardToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event MintingAgentChanged(address addr, bool state);

  uint256 public cap;

  bool public mintingFinished = false;
  mapping (address => bool) public mintAgents;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  
  modifier onlyMintAgent() {
     
    if(!mintAgents[msg.sender] && (msg.sender != owner)) {
        revert();
    }
    _;
  }


  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }


   
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    emit MintingAgentChanged(addr, state);
  }
  
   
  function mint(address _to, uint256 _amount) onlyMintAgent canMint isRunning public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 
contract StandardBurnableToken is BurnableToken, StandardToken {

   
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}


 
contract ODXToken is CappedMintableToken, StandardBurnableToken {

  string public name; 
  string public symbol; 
  uint8 public decimals; 

   
  constructor(
      string _name, 
      string _symbol, 
      uint8 _decimals, 
      uint256 _maxTokens
  ) 
    public 
    CappedMintableToken(_maxTokens) 
  {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply_ = 0;
  }
  
  function () payable public {
      revert();
  }

}


 
contract PrivateSaleRules is Ownable {
  using SafeMath for uint256;

   
  uint256 public weiRaisedDuringPrivateSale;

  mapping(address => uint256[]) public lockedTokens;
  
  uint256[] public lockupTimes;
  mapping(address => uint256) public privateSale;
  
  mapping (address => bool) public privateSaleAgents;

   
  ERC20 public token;

  event AddLockedTokens(address indexed beneficiary, uint256 totalContributionAmount, uint256[] tokenAmount);
  event UpdateLockedTokens(address indexed beneficiary, uint256 totalContributionAmount, uint256 lockedTimeIndex, uint256 tokenAmount);
  event PrivateSaleAgentChanged(address addr, bool state);


  modifier onlyPrivateSaleAgent() {
     
    require(privateSaleAgents[msg.sender] || msg.sender == owner);
    _;
  }
  

   
  constructor(uint256[] _lockupTimes, ODXToken _token) public {
    require(_lockupTimes.length > 0);
    
    lockupTimes = _lockupTimes;
    token = _token;
  }

   
  function setPrivateSaleAgent(address addr, bool state) onlyOwner public {
    privateSaleAgents[addr] = state;
    emit PrivateSaleAgentChanged(addr, state);
  }
  
   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    require(ODXToken(token).mint(_beneficiary, _tokenAmount));
  }
  
   
   
  function claimLockedTokens() public {
    for (uint i=0; i<lockupTimes.length; i++) {
        uint256 lockupTime = lockupTimes[i];
        if (lockupTime < now){
            uint256 tokens = lockedTokens[msg.sender][i];
            if (tokens>0){
                lockedTokens[msg.sender][i] = 0;
                _deliverTokens(msg.sender, tokens);    
            }
        }
    }
  }


   
  function releaseLockedTokensByIndex(address _beneficiary, uint256 _lockedTimeIndex) onlyOwner public {
    require(lockupTimes[_lockedTimeIndex] < now);
    uint256 tokens = lockedTokens[_beneficiary][_lockedTimeIndex];
    if (tokens>0){
        lockedTokens[_beneficiary][_lockedTimeIndex] = 0;
        _deliverTokens(_beneficiary, tokens);    
    }
  }
  
  function releaseLockedTokens(address _beneficiary) public {
    for (uint i=0; i<lockupTimes.length; i++) {
        uint256 lockupTime = lockupTimes[i];
        if (lockupTime < now){
            uint256 tokens = lockedTokens[_beneficiary][i];
            if (tokens>0){
                lockedTokens[_beneficiary][i] = 0;
                _deliverTokens(_beneficiary, tokens);    
            }
        }
    }
    
  }
  
  function tokensReadyForRelease(uint256 releaseBatch) public view returns (bool) {
      bool forRelease = false;
      uint256 lockupTime = lockupTimes[releaseBatch];
      if (lockupTime < now){
        forRelease = true;
      }
      return forRelease;
  }

   
  function getTotalLockedTokensPerUser(address _beneficiary) public view returns (uint256) {
    uint256 totalTokens = 0;
    uint256[] memory lTokens = lockedTokens[_beneficiary];
    for (uint i=0; i<lockupTimes.length; i++) {
        totalTokens += lTokens[i];
    }
    return totalTokens;
  }
  
  function getLockedTokensPerUser(address _beneficiary) public view returns (uint256[]) {
    return lockedTokens[_beneficiary];
  }

  function addPrivateSaleWithMonthlyLockup(address _beneficiary, uint256[] _atokenAmount, uint256 _totalContributionAmount) onlyPrivateSaleAgent public {
      require(_beneficiary != address(0));
      require(_totalContributionAmount > 0);
      require(_atokenAmount.length == lockupTimes.length);
      
      uint256 existingContribution = privateSale[_beneficiary];
      if (existingContribution > 0){
        revert();
      }else{
        lockedTokens[_beneficiary] = _atokenAmount;
        privateSale[_beneficiary] = _totalContributionAmount;
          
        weiRaisedDuringPrivateSale = weiRaisedDuringPrivateSale.add(_totalContributionAmount);
          
        emit AddLockedTokens(
          _beneficiary,
          _totalContributionAmount,
          _atokenAmount
        );
          
      }
      
  }
  
   


   
  function updatePrivateSaleWithMonthlyLockupByIndex(address _beneficiary, uint _lockedTimeIndex, uint256 _atokenAmount, uint256 _totalContributionAmount) onlyPrivateSaleAgent public {
      require(_beneficiary != address(0));
      require(_totalContributionAmount > 0);
       
      require(_lockedTimeIndex < lockupTimes.length);

      
      uint256 oldContributions = privateSale[_beneficiary];
       
      require(oldContributions > 0);

       
      require(!tokensReadyForRelease(_lockedTimeIndex));
      
      lockedTokens[_beneficiary][_lockedTimeIndex] = _atokenAmount;
      
       
      weiRaisedDuringPrivateSale = weiRaisedDuringPrivateSale.sub(oldContributions);
      
       
      privateSale[_beneficiary] = _totalContributionAmount;
      weiRaisedDuringPrivateSale = weiRaisedDuringPrivateSale.add(_totalContributionAmount);
            
      emit UpdateLockedTokens(
      _beneficiary,
      _totalContributionAmount,
      _lockedTimeIndex,
      _atokenAmount
    );
  }


}

 
contract ODXPrivateSale is PrivateSaleRules {

uint256[] alockupTimes = [1556582400,1559174400,1561852800,1564444800,1567123200,1569801600,1572393600,1575072000,1577664000,1580342400];
    
  constructor(
    ODXToken _token
  )
    public
    PrivateSaleRules(alockupTimes, _token)
  {  }
  
}