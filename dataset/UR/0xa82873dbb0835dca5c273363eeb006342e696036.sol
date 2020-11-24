 

pragma solidity ^0.5.1;

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
 
  constructor() public payable{
      
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
  
function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
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

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  uint256 public basePercent = 100;

  mapping(address => uint256) balances;

 function findTwoAnfHalfPercent(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(basePercent);
    uint256 onePercent = roundValue.mul(basePercent).div(4000);
    return onePercent;
  }
  
  function transfer(address to, uint256 value) public returns (bool) {
    require(to != address(0));
    require(value <= balances[msg.sender]);

    uint256 tokensToBurn = findTwoAnfHalfPercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

     balances[msg.sender] = balances[msg.sender].sub(value);
     balances[to] = balances[to].add(tokensToTransfer);

    totalSupply = totalSupply.sub(tokensToBurn);

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurn);
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
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
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
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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


 

contract EqvcTokens is StandardToken, Ownable {
    string public constant symbol = "EQVC";
    string public constant name = "EqvcToken";
    uint8 public constant decimals = 0;
    uint256 public constant INITIAL_SUPPLY = 2000000;
    uint256 public constant TOKEN_OFFERING_ALLOWANCE = 2000000;
    uint256 public constant ADMIN_ALLOWANCE = INITIAL_SUPPLY - TOKEN_OFFERING_ALLOWANCE;
    
     
    address public adminAddr;

     
	  address public tokenOfferingAddr;

     
    bool public transferEnabled = false;
    
     
    modifier onlyWhenTransferAllowed() {
        require(transferEnabled || msg.sender == adminAddr || msg.sender == tokenOfferingAddr);
        _;
    }

     
    modifier onlyTokenOfferingAddrNotSet() {
        require(tokenOfferingAddr == address(0x0));
        _;
    }

     
    modifier validDestination(address to) {
        require(to != address(0x0));
        require(to != address(this));
        require(to != owner);
        require(to != address(adminAddr));
        require(to != address(tokenOfferingAddr));
        _;
    }
    
     
    function EqvcToken(address admin) public {
        totalSupply = INITIAL_SUPPLY;
        
         
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);

         
        adminAddr = admin;
        approve(adminAddr, ADMIN_ALLOWANCE);
    }
    
    
 

     
    function setTokenOffering(address offeringAddr, uint256 amountForSale) external onlyOwner onlyTokenOfferingAddrNotSet {
        require(!transferEnabled);

        uint256 amount = (amountForSale == 0) ? TOKEN_OFFERING_ALLOWANCE : amountForSale;
        require(amount <= TOKEN_OFFERING_ALLOWANCE);

        approve(offeringAddr, amount);
        tokenOfferingAddr = offeringAddr;
    }
    
     
    function enableTransfer() external onlyOwner {
        transferEnabled = true;

         
        approve(tokenOfferingAddr, 0);
    }

     
    function transfer(address to, uint256 value) public onlyWhenTransferAllowed validDestination(to) returns (bool) {
        return super.transfer(to, value);
    }
    
     
    function transferFrom(address from, address to, uint256 value) public onlyWhenTransferAllowed validDestination(to) returns (bool) {
        return super.transferFrom(from, to, value);
    }
    
}

contract EqvcsCrowdsale is Pausable {
    using SafeMath for uint256;

      
    EqvcTokens public token;

     
    uint256 public startTime;
    uint256 public endTime;

     
    address payable  beneficiary;

     
    uint256 public rate;

     
    uint256 public EthRaised;

     
    uint256 public capReleaseTimestamp;

    uint256 public extraTime;

     
     

     
    mapping(address => uint256) public contributions;

     
     uint256 public constant FUNDING_ETH_HARD_CAP = 1300;

     
    uint256 public minContribution = 1 ;

     
    uint256 public maxContribution = 15;

     
     uint256 public remainCap;

     
    Stages public stage;

    enum Stages { 
        Setup,
        OfferingStarted,
        OfferingEnded
    }

    event OfferingOpens(uint256 startTime, uint256 endTime);
    event OfferingCloses(uint256 endTime, uint256 totalEthRaised);
     
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

     
    modifier atStage(Stages expectedStage) {
        require(stage == expectedStage);
        _;
    }

    
     
    function EqvcCrowdsale(
        uint256 eqvcToEtherRate, 
        address payable beneficiaryAddr, 
        address tokenAddress
    ) public {
        require(eqvcToEtherRate > 0);
        require(beneficiaryAddr != address(0));
        require(tokenAddress != address(0));

        token = EqvcTokens(tokenAddress);
        rate = eqvcToEtherRate;
        beneficiary = beneficiaryAddr;
        stage = Stages.Setup;
    }

     
    function ()  payable external {
        buy();
    }

     
     
     
    function ownerSafeWithdrawal() external onlyOwner {
        beneficiary.transfer(address(this).balance);
    }

    function updateRate(uint256 eqvcToEtherRate) public onlyOwner atStage(Stages.Setup) {
        rate = eqvcToEtherRate;
    }

     
     
     
     
     
     
     
     
     
     
     
    function startOffering(uint256 durationInSeconds) public onlyOwner atStage(Stages.Setup) {
        stage = Stages.OfferingStarted;
        startTime = now;
        capReleaseTimestamp = startTime + 1 days;
        extraTime = capReleaseTimestamp + 365 days;
        endTime = extraTime.add(durationInSeconds);
        emit OfferingOpens(startTime, endTime);
    }

     
    function endOffering() public onlyOwner atStage(Stages.OfferingStarted) {
        endOfferingImpl();
    }
    
  
     
    function buy() public payable whenNotPaused atStage(Stages.OfferingStarted) returns (bool) {
         
              buyTokens();
              return true;
         
        revert();
    }

     
    function hasEnded() public view returns (bool) {
        return now > endTime || stage == Stages.OfferingEnded;
    }

     
    modifier validPurchase() {
        require(now >= startTime && now <= endTime && stage == Stages.OfferingStarted);
        if(now > capReleaseTimestamp) {
          maxContribution = 2000;
        }
        uint256 contributionInETH = uint256(msg.value).div(10**18);
        address participant = msg.sender; 


        require(contributionInETH <= maxContribution.sub(contributions[participant]));
        require(participant != address(0) && contributionInETH >= minContribution && contributionInETH <= maxContribution);
        require(EthRaised.add(contributionInETH) <= FUNDING_ETH_HARD_CAP);
        
        _;
    }


    function buyTokens() internal validPurchase {
      
         
        uint256 contributionInETH = uint256(msg.value).div(10**18);
        address participant = msg.sender;

         
        uint256 tokens = contributionInETH.mul(rate);
        
        if (!token.transferFrom(token.owner(), participant, tokens)) {
            revert();
        }

        EthRaised = EthRaised.add(contributionInETH);
        contributions[participant] = contributions[participant].add(contributionInETH);

        remainCap = FUNDING_ETH_HARD_CAP.sub(EthRaised);

        
        
        if (EthRaised >= FUNDING_ETH_HARD_CAP) {
            endOfferingImpl();
        }
        
         
         
        beneficiary.transfer(contributionInETH.mul(10**18));
        emit TokenPurchase(msg.sender, contributionInETH, tokens);          
    }


     
    function endOfferingImpl() internal{
        endTime = now;
        stage = Stages.OfferingEnded;
        emit OfferingCloses(endTime, EthRaised);
    }

     
    function allocateTokens(address to, uint256 tokens) public onlyOwner returns (bool) {
        if (!token.transferFrom(token.owner(), to, tokens)) {
            revert();
        }
        return true;
    }
    
     
    function batchallocateTokens(address[] memory toList, uint256[] memory tokensList)  public onlyOwner  returns (bool)  {
        require(toList.length == tokensList.length);

        for (uint32 i = 0; i < toList.length; i++) {
            allocateTokens(toList[i], tokensList[i]);
        }
        return true;
    }

}