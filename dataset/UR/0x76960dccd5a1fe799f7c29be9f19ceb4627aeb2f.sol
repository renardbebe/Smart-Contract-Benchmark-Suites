 

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


contract REDToken is ERC20, Ownable {

    using SafeMath for uint;

 

    string public constant name = "Red Community Token";
    string public constant symbol = "RED";

    uint8 public decimals = 18;                             

    mapping (address => uint256) angels;                    
    mapping (address => uint256) accounts;                  
    mapping (address => mapping (address => uint256)) allowed;  

 

    uint256 public angelSupply;                             
    uint256 public earlyBirdsSupply;                        
    uint256 public publicSupply;                            
    uint256 public foundationSupply;                        
    uint256 public redTeamSupply;                           
    uint256 public marketingSupply;                         

    uint256 public angelAmountRemaining;                    
    uint256 public icoStartsAt;                             
    uint256 public icoEndsAt;                               
    uint256 public redTeamLockingPeriod;                    
    uint256 public angelLockingPeriod;                      

    address public crowdfundAddress;                        
    address public redTeamAddress;                          
    address public foundationAddress;                       
    address public marketingAddress;                        

    bool public unlock20Done = false;                       

    enum icoStages {
        Ready,                                              
        EarlyBirds,                                         
        PublicSale,                                         
        Done                                                
    }
    icoStages stage;                                        

 

    event EarlyBirdsFinalized(uint tokensRemaining);        
    event CrowdfundFinalized(uint tokensRemaining);         

 

    modifier nonZeroAddress(address _to) {                  
        require(_to != 0x0);
        _;
    }

    modifier nonZeroAmount(uint _amount) {                  
        require(_amount > 0);
        _;
    }

    modifier nonZeroValue() {                               
        require(msg.value > 0);
        _;
    }

    modifier onlyDuringCrowdfund(){                    
        require((now >= icoStartsAt) && (now < icoEndsAt));
        _;
    }

    modifier notBeforeCrowdfundEnds(){                      
        require(now >= icoEndsAt);
        _;
    }

    modifier checkRedTeamLockingPeriod() {                  
        require(now >= redTeamLockingPeriod);
        _;
    }

    modifier checkAngelsLockingPeriod() {                   
        require(now >= angelLockingPeriod);
        _;
    }

    modifier onlyCrowdfund() {                              
        require(msg.sender == crowdfundAddress);
        _;
    }

 

     
     
     
    function transfer(address _to, uint256 _amount) public notBeforeCrowdfundEnds returns (bool success) {
        require(accounts[msg.sender] >= _amount);          
        addToBalance(_to, _amount);
        decrementBalance(msg.sender, _amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }

     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) public notBeforeCrowdfundEnds returns (bool success) {
        require(allowance(_from, msg.sender) >= _amount);
        decrementBalance(_from, _amount);
        addToBalance(_to, _amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }

     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowance(msg.sender, _spender) == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return accounts[_owner] + angels[_owner];
    }


 

     
     
     
    function REDToken() public {
        totalSupply         = 200000000 * 1e18;              

        angelSupply         =  20000000 * 1e18;              
        earlyBirdsSupply    =  48000000 * 1e18;              
        publicSupply        =  12000000 * 1e18;              
        redTeamSupply       =  30000000 * 1e18;              
        foundationSupply    =  70000000 * 1e18;              
        marketingSupply     =  20000000 * 1e18;              

        angelAmountRemaining = angelSupply;                  
        redTeamAddress       = 0x31aa507c140E012d0DcAf041d482e04F36323B03;        
        foundationAddress    = 0x93e3AF42939C163Ee4146F63646Fb4C286CDbFeC;        
        marketingAddress     = 0x0;                          

        icoStartsAt          = 1515398400;                   
        icoEndsAt            = 1517385600;                   
        angelLockingPeriod   = icoEndsAt.add(90 days);       
        redTeamLockingPeriod = icoEndsAt.add(365 days);      

        addToBalance(foundationAddress, foundationSupply);

        stage = icoStages.Ready;                             
    }

     
     
     
    function startCrowdfund() external onlyCrowdfund onlyDuringCrowdfund returns(bool) {
        require(stage == icoStages.Ready);
        stage = icoStages.EarlyBirds;
        addToBalance(crowdfundAddress, earlyBirdsSupply);
        return true;
    }

     
     
     
    function isEarlyBirdsStage() external view returns(bool) {
        return (stage == icoStages.EarlyBirds);
    }

     
     
     
    function setCrowdfundAddress(address _crowdfundAddress) external onlyOwner nonZeroAddress(_crowdfundAddress) {
        require(crowdfundAddress == 0x0);
        crowdfundAddress = _crowdfundAddress;
    }

     
     
     
    function transferFromCrowdfund(address _to, uint256 _amount) external onlyCrowdfund nonZeroAmount(_amount) nonZeroAddress(_to) returns (bool success) {
        require(balanceOf(crowdfundAddress) >= _amount);
        decrementBalance(crowdfundAddress, _amount);
        addToBalance(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }

     
     
     
    function releaseRedTeamTokens() external checkRedTeamLockingPeriod onlyOwner returns(bool success) {
        require(redTeamSupply > 0);
        addToBalance(redTeamAddress, redTeamSupply);
        Transfer(0x0, redTeamAddress, redTeamSupply);
        redTeamSupply = 0;
        return true;
    }

     
     
     
    function releaseMarketingTokens() external onlyOwner returns(bool success) {
        require(marketingSupply > 0);
        addToBalance(marketingAddress, marketingSupply);
        Transfer(0x0, marketingAddress, marketingSupply);
        marketingSupply = 0;
        return true;
    }

     
     
     
    function finalizeEarlyBirds() external onlyOwner returns (bool success) {
        require(stage == icoStages.EarlyBirds);
        uint256 amount = balanceOf(crowdfundAddress);
        addToBalance(crowdfundAddress, publicSupply);
        stage = icoStages.PublicSale;
        EarlyBirdsFinalized(amount);                        
        return true;
    }

     
     
     
    function finalizeCrowdfund() external onlyCrowdfund {
        require(stage == icoStages.PublicSale);
        uint256 amount = balanceOf(crowdfundAddress);
        if (amount > 0) {
            accounts[crowdfundAddress] = 0;
            addToBalance(foundationAddress, amount);
            Transfer(crowdfundAddress, foundationAddress, amount);
        }
        stage = icoStages.Done;
        CrowdfundFinalized(amount);                         
    }

     
     
     
    function changeRedTeamAddress(address _wallet) external onlyOwner {
        redTeamAddress = _wallet;
    }

     
     
     
    function changeMarketingAddress(address _wallet) external onlyOwner {
        marketingAddress = _wallet;
    }

     
     
     
    function partialUnlockAngelsAccounts(address[] _batchOfAddresses) external onlyOwner notBeforeCrowdfundEnds returns (bool success) {
        require(unlock20Done == false);
        uint256 amount;
        address holder;
        for (uint256 i = 0; i < _batchOfAddresses.length; i++) {
            holder = _batchOfAddresses[i];
            amount = angels[holder].mul(20).div(100);
            angels[holder] = angels[holder].sub(amount);
            addToBalance(holder, amount);
        }
        unlock20Done = true;
        return true;
    }

     
     
     
    function fullUnlockAngelsAccounts(address[] _batchOfAddresses) external onlyOwner checkAngelsLockingPeriod returns (bool success) {
        uint256 amount;
        address holder;
        for (uint256 i = 0; i < _batchOfAddresses.length; i++) {
            holder = _batchOfAddresses[i];
            amount = angels[holder];
            angels[holder] = 0;
            addToBalance(holder, amount);
        }
        return true;
    }

     
     
     
     
    function deliverAngelsREDAccounts(address[] _batchOfAddresses, uint[] _amountOfRED) external onlyOwner onlyDuringCrowdfund returns (bool success) {
        for (uint256 i = 0; i < _batchOfAddresses.length; i++) {
            deliverAngelsREDBalance(_batchOfAddresses[i], _amountOfRED[i]);
        }
        return true;
    }
 
     
     
     
     
    function deliverAngelsREDBalance(address _accountHolder, uint _amountOfBoughtRED) internal onlyOwner {
        require(angelAmountRemaining > 0);
        angels[_accountHolder] = angels[_accountHolder].add(_amountOfBoughtRED);
        Transfer(0x0, _accountHolder, _amountOfBoughtRED);
        angelAmountRemaining = angelAmountRemaining.sub(_amountOfBoughtRED);
    }

     
     
     
    function addToBalance(address _address, uint _amount) internal {
        accounts[_address] = accounts[_address].add(_amount);
    }

     
     
     
    function decrementBalance(address _address, uint _amount) internal {
        accounts[_address] = accounts[_address].sub(_amount);
    }
}