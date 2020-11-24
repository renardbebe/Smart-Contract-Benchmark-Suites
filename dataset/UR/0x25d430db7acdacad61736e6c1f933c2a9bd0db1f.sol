 

pragma solidity 0.4.17;
 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract Ownable {
  address internal owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
  function Ownable() public {
    owner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
 
 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) allowed;
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    uint256 _allowance = allowed[_from][msg.sender];
     
     
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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
     
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(msg.sender, _to, _amount);
    return true;
  }
   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  function burnTokens(uint256 _unsoldTokens) onlyOwner public returns (bool) {
    totalSupply = SafeMath.sub(totalSupply, _unsoldTokens);
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
 
contract TokenFunctions is Ownable, Pausable {
  using SafeMath for uint256;
   
  MintableToken internal token;
  struct PrivatePurchaserStruct {
    uint privatePurchaserTimeLock;
    uint256 privatePurchaserTokens;
    uint256 privatePurchaserBonus;
  }
  struct AdvisorStruct {
    uint advisorTimeLock;
    uint256 advisorTokens;
  }
  struct BackerStruct {
    uint backerTimeLock;
    uint256 backerTokens;
  }
  struct FounderStruct {
    uint founderTimeLock;
    uint256 founderTokens;
  }
  struct FoundationStruct {
    uint foundationTimeLock;
    uint256 foundationBonus;
    uint256 foundationTokens;
  }
  mapping (address => AdvisorStruct) advisor;
  mapping (address => BackerStruct) backer;
  mapping (address => FounderStruct) founder;
  mapping (address => FoundationStruct) foundation;
  mapping (address => PrivatePurchaserStruct) privatePurchaser;
   
      
  uint256 public totalTokens = 105926908800000000000000000; 
  uint256 internal publicSupply = 775353800000000000000000; 
  uint256 internal bountySupply = 657896000000000000000000;
  uint256 internal privateSupply = 52589473690000000000000000;  
  uint256 internal advisorSupply = 2834024170000000000000000;
  uint256 internal backerSupply = 317780730000000000000000;
  uint256 internal founderSupply = 10592690880000000000000000;
  uint256 internal foundationSupply = 38159689530000000000000000; 
  event AdvisorTokenTransfer (address indexed beneficiary, uint256 amount);
  event BackerTokenTransfer (address indexed beneficiary, uint256 amount);
  event FoundationTokenTransfer (address indexed beneficiary, uint256 amount);
  event FounderTokenTransfer (address indexed beneficiary, uint256 amount);
  event PrivatePurchaserTokenTransfer (address indexed beneficiary, uint256 amount);
  event AddAdvisor (address indexed advisorAddress, uint timeLock, uint256 advisorToken);
  event AddBacker (address indexed backerAddress, uint timeLock, uint256 backerToken);
  event AddFoundation (address indexed foundationAddress, uint timeLock, uint256 foundationToken, uint256 foundationBonus);
  event AddFounder (address indexed founderAddress, uint timeLock, uint256 founderToken);
  event BountyTokenTransfer (address indexed beneficiary, uint256 amount);
  event PublicTokenTransfer (address indexed beneficiary, uint256 amount);
  event AddPrivatePurchaser (address indexed privatePurchaserAddress, uint timeLock, uint256 privatePurchaserTokens, uint256 privatePurchaserBonus);
  function addAdvisors (address advisorAddress, uint timeLock, uint256 advisorToken) onlyOwner public returns(bool acknowledgement) {
      
      require(now < timeLock || timeLock == 0);
      require(advisorToken > 0);
      require(advisorAddress != 0x0);
      require(advisorSupply >= advisorToken);
      advisorSupply = SafeMath.sub(advisorSupply,advisorToken);
      
      advisor[advisorAddress].advisorTimeLock = timeLock;
      advisor[advisorAddress].advisorTokens = advisorToken;
      
      AddAdvisor(advisorAddress, timeLock, advisorToken);
      return true;
        
  }
  function getAdvisorStatus (address addr) public view returns(address, uint, uint256) {
        return (addr, advisor[addr].advisorTimeLock, advisor[addr].advisorTokens);
  } 
  function addBackers (address backerAddress, uint timeLock, uint256 backerToken) onlyOwner public returns(bool acknowledgement) {
      
      require(now < timeLock || timeLock == 0);
      require(backerToken > 0);
      require(backerAddress != 0x0);
      require(backerSupply >= backerToken);
      backerSupply = SafeMath.sub(backerSupply,backerToken);
           
      backer[backerAddress].backerTimeLock = timeLock;
      backer[backerAddress].backerTokens = backerToken;
      
      AddBacker(backerAddress, timeLock, backerToken);
      return true;
        
  }
  function getBackerStatus(address addr) public view returns(address, uint, uint256) {
        return (addr, backer[addr].backerTimeLock, backer[addr].backerTokens);
  } 
  function addFounder(address founderAddress, uint timeLock, uint256 founderToken) onlyOwner public returns(bool acknowledgement) {
      
      require(now < timeLock || timeLock == 0);
      require(founderToken > 0);
      require(founderAddress != 0x0);
      require(founderSupply >= founderToken);
      founderSupply = SafeMath.sub(founderSupply,founderToken);  
      founder[founderAddress].founderTimeLock = timeLock;
      founder[founderAddress].founderTokens = founderToken;
      
      AddFounder(founderAddress, timeLock, founderToken);
      return true;
        
  }
  function getFounderStatus(address addr) public view returns(address, uint, uint256) {
        return (addr, founder[addr].founderTimeLock, founder[addr].founderTokens);
  }
  function addFoundation(address foundationAddress, uint timeLock, uint256 foundationToken, uint256 foundationBonus) onlyOwner public returns(bool acknowledgement) {
      
      require(now < timeLock || timeLock == 0);
      require(foundationToken > 0);
      require(foundationBonus > 0);
      require(foundationAddress != 0x0);
      uint256 totalTokens = SafeMath.add(foundationToken, foundationBonus);
      require(foundationSupply >= totalTokens);
      foundationSupply = SafeMath.sub(foundationSupply, totalTokens);  
      foundation[foundationAddress].foundationBonus = foundationBonus;
      foundation[foundationAddress].foundationTimeLock = timeLock;
      foundation[foundationAddress].foundationTokens = foundationToken;
      
      AddFoundation(foundationAddress, timeLock, foundationToken, foundationBonus);
      return true;
        
  }
  function getFoundationStatus(address addr) public view returns(address, uint, uint256, uint256) {
        return (addr, foundation[addr].foundationTimeLock, foundation[addr].foundationBonus, foundation[addr].foundationTokens);
  }
  function addPrivatePurchaser(address privatePurchaserAddress, uint timeLock, uint256 privatePurchaserToken, uint256 privatePurchaserBonus) onlyOwner public returns(bool acknowledgement) {
      
      require(now < timeLock || timeLock == 0);
      require(privatePurchaserToken > 0);
      require(privatePurchaserBonus > 0);
      require(privatePurchaserAddress != 0x0);
      uint256 totalTokens = SafeMath.add(privatePurchaserToken, privatePurchaserBonus);
      require(privateSupply >= totalTokens);
      privateSupply = SafeMath.sub(privateSupply, totalTokens);        
      privatePurchaser[privatePurchaserAddress].privatePurchaserTimeLock = timeLock;
      privatePurchaser[privatePurchaserAddress].privatePurchaserTokens = privatePurchaserToken;
      privatePurchaser[privatePurchaserAddress].privatePurchaserBonus = privatePurchaserBonus;
      
      AddPrivatePurchaser(privatePurchaserAddress, timeLock, privatePurchaserToken, privatePurchaserBonus);
      return true;
        
  }
  function getPrivatePurchaserStatus(address addr) public view returns(address, uint256, uint, uint) {
        return (addr, privatePurchaser[addr].privatePurchaserTimeLock, privatePurchaser[addr].privatePurchaserTokens, privatePurchaser[addr].privatePurchaserBonus);
  }
  function TokenFunctions() internal {
    token = createTokenContract();
  }
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }
  
   
  function getTokenAddress() onlyOwner public returns (address) {
    return token;
  }
}
 
 
contract HazzaToken is MintableToken {
     
    string public constant name = "HAZZA";
    string public constant symbol = "HAZ";
    uint8 public constant decimals = 18;
    uint256 public constant _totalSupply = 105926908800000000000000000;
  
     
    function HazzaToken() {
        totalSupply = _totalSupply;
    }
}
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }
  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract TokenDistribution is TokenFunctions {
   
    function grantAdvisorToken() public returns(bool response) {
        require(advisor[msg.sender].advisorTokens > 0);
        require(now > advisor[msg.sender].advisorTimeLock);
        uint256 transferToken = advisor[msg.sender].advisorTokens;
        advisor[msg.sender].advisorTokens = 0;
        token.mint(msg.sender, transferToken);
        AdvisorTokenTransfer(msg.sender, transferToken);
        
        return true;
      
    }
   
    function grantBackerToken() public returns(bool response) {
        require(backer[msg.sender].backerTokens > 0);
        require(now > backer[msg.sender].backerTimeLock);
        uint256 transferToken = backer[msg.sender].backerTokens;
        backer[msg.sender].backerTokens = 0;
        token.mint(msg.sender, transferToken);
        BackerTokenTransfer(msg.sender, transferToken);
        
        return true;
      
    }
   
    function grantFoundationToken() public returns(bool response) {
  
        if (now > foundation[msg.sender].foundationTimeLock) {
                require(foundation[msg.sender].foundationTokens > 0);
                uint256 transferToken = foundation[msg.sender].foundationTokens;
                foundation[msg.sender].foundationTokens = 0;
                token.mint(msg.sender, transferToken);
                FoundationTokenTransfer(msg.sender, transferToken);
        }
        
        if (foundation[msg.sender].foundationBonus > 0) {
                uint256 transferTokenBonus = foundation[msg.sender].foundationBonus;
                foundation[msg.sender].foundationBonus = 0;
                token.mint(msg.sender, transferTokenBonus);
                FoundationTokenTransfer(msg.sender, transferTokenBonus);
        }
        return true;
      
    }
   
    function grantFounderToken() public returns(bool response) {
        require(founder[msg.sender].founderTokens > 0);
        require(now > founder[msg.sender].founderTimeLock);
        uint256 transferToken = founder[msg.sender].founderTokens;
        founder[msg.sender].founderTokens = 0;
        token.mint(msg.sender, transferToken);
        FounderTokenTransfer(msg.sender, transferToken);
        
        return true;
      
    }
   
    function grantPrivatePurchaserToken() public returns(bool response) {
        if (now > privatePurchaser[msg.sender].privatePurchaserTimeLock) {
                require(privatePurchaser[msg.sender].privatePurchaserTokens > 0);
                uint256 transferToken = privatePurchaser[msg.sender].privatePurchaserTokens;
                privatePurchaser[msg.sender].privatePurchaserTokens = 0;
                token.mint(msg.sender, transferToken);
                PrivatePurchaserTokenTransfer(msg.sender, transferToken);
        }
        
        if (privatePurchaser[msg.sender].privatePurchaserBonus > 0) {
                uint256 transferBonusToken = privatePurchaser[msg.sender].privatePurchaserBonus;
                privatePurchaser[msg.sender].privatePurchaserBonus = 0;
                token.mint(msg.sender, transferBonusToken);
                PrivatePurchaserTokenTransfer(msg.sender, transferBonusToken);
        }
        return true;
      
    }
     
    function bountyTransferToken(address[] beneficiary, uint256[] tokens) onlyOwner public {
        for (uint i = 0; i < beneficiary.length; i++) {
        require(bountySupply >= tokens[i]);
        bountySupply = SafeMath.sub(bountySupply, tokens[i]);
        token.mint(beneficiary[i], tokens[i]);
        BountyTokenTransfer(beneficiary[i], tokens[i]);
        
        }
    }
         
    function publicTransferToken(address[] beneficiary, uint256[] tokens) onlyOwner public {
        for (uint i = 0; i < beneficiary.length; i++) {
        
        require(publicSupply >= tokens[i]);
        publicSupply = SafeMath.sub(publicSupply,tokens[i]);
        token.mint(beneficiary[i], tokens[i]);
        PublicTokenTransfer(beneficiary[i], tokens[i]);
        }
    }
}
contract HazzaTokenInterface is TokenFunctions, TokenDistribution {
  
     
    function HazzaTokenInterface() public TokenFunctions() {
    }
    
     
    function createTokenContract() internal returns (MintableToken) {
        return new HazzaToken();
    }
}