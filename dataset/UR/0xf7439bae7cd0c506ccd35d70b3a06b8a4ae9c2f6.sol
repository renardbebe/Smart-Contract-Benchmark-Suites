 

pragma solidity 0.4.24;

contract Ownable {
    address public owner=0x28970854Bfa61C0d6fE56Cc9daAAe5271CEaEC09;


     
    constructor()public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        owner = newOwner;
    }

}
contract PricingStrategy {

   
  function isPricingStrategy() public pure  returns (bool) {
    return true;
  }

   
  function isSane() public pure returns (bool) {
    return true;
  }

   
  function isPresalePurchase(address purchaser) public pure returns (bool) {
    return false;
  }

   
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public pure returns (uint tokenAmount){
      
  }
  
}
contract FinalizeAgent {

  function isFinalizeAgent() public pure returns(bool) {
    return true;
  }

   
  function isSane() public pure returns (bool){
      return true;
}
   
  function finalizeCrowdsale() pure public{
     
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
     
     
     
    return a / b;
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
contract UbricoinPresale {

     

    enum Phase {
        Created,
        Running,
        Paused,
        Migrating,
        Migrated
    }

    Phase public currentPhase = Phase.Created;
    uint public totalSupply = 0;  
    

     
     
    address public tokenManager;

     
    address public escrow;

     
    address public crowdsaleManager;

    mapping (address => uint256) private balance;


    modifier onlyTokenManager()     { if(msg.sender != tokenManager) revert(); _; }
    modifier onlyCrowdsaleManager() { if(msg.sender != crowdsaleManager) revert(); _; }


     

    event LogBuy(address indexed owner, uint256 value);
    event LogBurn(address indexed owner, uint256 value);
    event LogPhaseSwitch(Phase newPhase);


     

 
     
     
    function burnTokens(address _owner) public
        onlyCrowdsaleManager
    {
         
        if(currentPhase != Phase.Migrating) revert();

        uint256 tokens = balance[_owner];
        if(tokens == 0) revert();
        balance[_owner] = 0;
        
        emit LogBurn(_owner, tokens);

         
       
    }

     

    function setPresalePhase(Phase _nextPhase) public
        onlyTokenManager
    {
        bool canSwitchPhase
            =  (currentPhase == Phase.Created && _nextPhase == Phase.Running)
            || (currentPhase == Phase.Running && _nextPhase == Phase.Paused)
                 
            || ((currentPhase == Phase.Running || currentPhase == Phase.Paused)
                && _nextPhase == Phase.Migrating
                && crowdsaleManager != 0x0)
            || (currentPhase == Phase.Paused && _nextPhase == Phase.Running)
                 
            || (currentPhase == Phase.Migrating && _nextPhase == Phase.Migrated
                && totalSupply == 0);

        if(!canSwitchPhase) revert();
        currentPhase = _nextPhase;
        emit LogPhaseSwitch(_nextPhase); 
           
    }


    function withdrawEther() public
        onlyTokenManager
    {
         
        if(address(this).balance > 0) {
            if(!escrow.send(address(this).balance)) revert();
        }
    }


    function setCrowdsaleManager(address _mgr) public
        onlyTokenManager
    {
         
        if(currentPhase == Phase.Migrating) revert();
        crowdsaleManager = _mgr;
    }
}
contract Haltable is Ownable  {
    
  bool public halted;
  
   modifier stopInEmergency {
    if (halted) revert();
    _;
  }

  modifier stopNonOwnersInEmergency {
    if (halted && msg.sender != owner) revert();
    _;
  }

  modifier onlyInEmergency {
    if (!halted) revert();
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}
contract WhitelistedCrowdsale is Ownable {

  mapping(address => bool) public whitelist;

   
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }
  
   
  function addToWhitelist(address _beneficiary) onlyOwner public  {
    whitelist[_beneficiary] = true;
  }

   
  function addManyToWhitelist(address[] _beneficiaries) onlyOwner public {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

   
  function removeFromWhitelist(address _beneficiary)onlyOwner public {
    whitelist[_beneficiary] = false;
  }

   
  
}

   contract UbricoinCrowdsale is FinalizeAgent,WhitelistedCrowdsale {
    using SafeMath for uint256;
    address public beneficiary;
    uint256 public fundingGoal;
    uint256 public amountRaised;
    uint256 public deadline;
       
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
    uint256 public investorCount = 0;
    
    bool public requiredSignedAddress;
    bool public requireCustomerId;
    

    bool public paused = false;

    
    event GoalReached(address recipient, uint256 totalAmountRaised);
    event FundTransfer(address backer, uint256 amount, bool isContribution);
    
     
    event Invested(address investor, uint256 weiAmount, uint256 tokenAmount, uint256 customerId);

   
    event InvestmentPolicyChanged(bool requireCustomerId, bool requiredSignedAddress, address signerAddress);
    event Pause();
    event Unpause();
 
     
 
    modifier afterDeadline() { if (now >= deadline) _; }
    

     
     
    function invest(address ) public payable {
    if(requireCustomerId) revert();  
    if(requiredSignedAddress) revert();  
   
  }
     
    function investWithCustomerId(address , uint256 customerId) public payable {
    if(requiredSignedAddress) revert();  
    if(customerId == 0)revert();   

  }
  
    function buyWithCustomerId(uint256 customerId) public payable {
    investWithCustomerId(msg.sender, customerId);
  }
     
     
    function checkGoalReached() afterDeadline public {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }

   

     
    function safeWithdrawal() afterDeadline public {
        if (!fundingGoalReached) {
            uint256 amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                emit FundTransfer(beneficiary,amountRaised,false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if  (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
               emit FundTransfer(beneficiary,amountRaised,false);
            } else {
                 
                fundingGoalReached = false;
            }
        }
    }
    
      
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused public returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }

}
contract Upgradeable {
    mapping(bytes4=>uint32) _sizes;
    address _dest;

     
    function initialize() public{
        
    }
    
     
    function replace(address target) internal {
        _dest = target;
        require(target.delegatecall(bytes4(keccak256("initialize()"))));
    }
}
 
contract Dispatcher is Upgradeable {
    
    constructor (address target) public {
        replace(target);
    }
    
    function initialize() public {
         
        revert();
    }

    function() public {
        uint len;
        address target;
        bytes4 sig;
        assembly { sig := calldataload(0) }
        len = _sizes[sig];
        target = _dest;
        
        bool ret;
        assembly {
             
            calldatacopy(0x0, 0x0, calldatasize)
            ret:=delegatecall(sub(gas, 10000), target, 0x0, calldatasize, 0, len)
            return(0, len)
        }
        if (!ret) revert();
    }
}
contract Example is Upgradeable {
    uint _value;
    
    function initialize() public {
        _sizes[bytes4(keccak256("getUint()"))] = 32;
    }
    
    function getUint() public view returns (uint) {
        return _value;
    }
    
    function setUint(uint value) public {
        _value = value;
    }
}
interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData)external;
    
}

  

contract Ubricoin is UbricoinPresale,Ownable,Haltable, UbricoinCrowdsale,Upgradeable {
    
    using SafeMath for uint256;
    
     
    string public name ='Ubricoin';
    string public symbol ='UBN';
    string public version= "1.0";
    uint public decimals=18;
     
    uint public totalSupply = 10000000000;
    uint256 public constant RATE = 1000;
    uint256 initialSupply;

    
    
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    
    uint256 public AVAILABLE_AIRDROP_SUPPLY = 100000000* decimals;  
    uint256 public grandTotalClaimed = 1;
    uint256 public startTime;
    
    struct Allocation {
    uint8 AllocationSupply;  
    uint256 totalAllocated;  
    uint256 amountClaimed;   
}
    
    
    mapping (address => Allocation) public allocations;

     
    mapping (address => bool) public airdropAdmins;

     
    mapping (address => bool) public airdrops;

  modifier onlyOwnerOrAdmin() {
    require(msg.sender == owner || airdropAdmins[msg.sender]);
    _;
}
    
    
    
     
    event Burn(address indexed from, uint256 value);

        bytes32 public currentChallenge;                          
        uint256 public timeOfLastProof;                              
        uint256 public difficulty = 10**32;                          

     
    function proofOfWork(uint256 nonce) public{
        bytes8 n = bytes8(keccak256(abi.encodePacked(nonce, currentChallenge)));     
        require(n >= bytes8(difficulty));                    

        uint256 timeSinceLastProof = (now - timeOfLastProof);   
        require(timeSinceLastProof >=  5 seconds);          
        balanceOf[msg.sender] += timeSinceLastProof / 60 seconds;   

        difficulty = difficulty * 10 minutes / timeSinceLastProof + 1;   

        timeOfLastProof = now;                               
        currentChallenge = keccak256(abi.encodePacked(nonce, currentChallenge, blockhash(block.number - 1)));   
    }


   function () payable public whenNotPaused {
        require(msg.value > 0);
        uint256 tokens = msg.value.mul(RATE);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(tokens);
        totalSupply = totalSupply.add(tokens);
        owner.transfer(msg.value);
}
    
     
    function _transfer(address _from, address _to, uint256 _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value >= balanceOf[_to]);
         
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
     function transfer(address _to, uint256 _value) public {
		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
	}
     
   function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balanceOf[tokenOwner];
        
}

   function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
        return allowance[tokenOwner][spender];
}
   
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }
  
    function mintToken(address target, uint256 mintedAmount)private onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, owner, mintedAmount);
        emit Transfer(owner, target, mintedAmount);
    }

    function validPurchase() internal returns (bool) {
    bool lessThanMaxInvestment = msg.value <= 1000 ether;  
    return validPurchase() && lessThanMaxInvestment;
}

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
    
    
  function setAirdropAdmin(address _admin, bool _isAdmin) public onlyOwner {
    airdropAdmins[_admin] = _isAdmin;
  }

   
  function airdropTokens(address[] _recipient) public onlyOwnerOrAdmin {
    
    uint airdropped;
    for(uint256 i = 0; i< _recipient.length; i++)
    {
        if (!airdrops[_recipient[i]]) {
          airdrops[_recipient[i]] = true;
          Ubricoin.transfer(_recipient[i], 1 * decimals);
          airdropped = airdropped.add(1 * decimals);
        }
    }
    AVAILABLE_AIRDROP_SUPPLY = AVAILABLE_AIRDROP_SUPPLY.sub(airdropped);
    totalSupply = totalSupply.sub(airdropped);
    grandTotalClaimed = grandTotalClaimed.add(airdropped);
}
    
}