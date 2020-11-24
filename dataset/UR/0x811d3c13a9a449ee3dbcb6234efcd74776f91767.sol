 

pragma solidity ^0.4.3;

 
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

contract ERC677 is ERC20 {
  function transferAndCall(address to, uint value, bytes data) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint value, bytes data);
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

contract PoolOwners is Ownable {

    mapping(uint64 => address)  private ownerAddresses;
    mapping(address => bool)    private whitelist;

    mapping(address => uint256) public ownerPercentages;
    mapping(address => uint256) public ownerShareTokens;
    mapping(address => uint256) public tokenBalance;

    mapping(address => mapping(address => uint256)) private balances;

    uint64  public totalOwners = 0;
    uint16  public distributionMinimum = 20;

    bool   private contributionStarted = false;
    bool   private distributionActive = false;

     
    uint256 private ethWei = 1000000000000000000;  
    uint256 private valuation = ethWei * 4000;  
    uint256 private hardCap = ethWei * 1000;  
    address private wallet;
    bool    private locked = false;

    uint256 public totalContributed = 0;

     
     
    uint256 private minimumContribution = 200000000000000000;  

     

    event Contribution(address indexed sender, uint256 share, uint256 amount);
    event TokenDistribution(address indexed token, uint256 amount);
    event TokenWithdrawal(address indexed token, address indexed owner, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner, uint256 amount);

     

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender]);
        _;
    }

     

    constructor(address _wallet) public {
        wallet = _wallet;
    }

     

     
    function() public payable { contribute(msg.sender); }

    function contribute(address sender) internal {
         
        require(!locked);

         
        require(contributionStarted);

         
        require(whitelist[sender]);

         
        require(msg.value >= minimumContribution);

         
        require(hardCap >= msg.value);

         
        require((msg.value % minimumContribution) == 0);

         
        require(hardCap >= SafeMath.add(totalContributed, msg.value));

         
        totalContributed = SafeMath.add(totalContributed, msg.value);

         
        uint256 share = percent(msg.value, valuation, 5);

         
        if (ownerPercentages[sender] != 0) {  
            ownerShareTokens[sender] = SafeMath.add(ownerShareTokens[sender], msg.value);
            ownerPercentages[sender] = SafeMath.add(share, ownerPercentages[sender]);
        } else {  
            ownerAddresses[totalOwners] = sender;
            totalOwners += 1;
            ownerPercentages[sender] = share;
            ownerShareTokens[sender] = msg.value;
        }

         
        wallet.transfer(msg.value);

         
        emit Contribution(sender, share, msg.value);
    }

     
    function whitelistWallet(address contributor) external onlyOwner() {
         
        require(contributor != address(0));

         
        whitelist[contributor] = true;
    }

     
    function startContribution() external onlyOwner() {
        require(!contributionStarted);
        contributionStarted = true;
    }

     

     
    function setOwnerShare(address owner, uint256 value) public onlyOwner() {
         
        require(!locked);

        if (ownerShareTokens[owner] == 0) {
            whitelist[owner] = true;
            ownerAddresses[totalOwners] = owner;
            totalOwners += 1;
        }
        ownerShareTokens[owner] = value;
        ownerPercentages[owner] = percent(value, valuation, 5);
    }

     
    function sendOwnership(address receiver, uint256 amount) public onlyWhitelisted() {
         
        require(ownerShareTokens[msg.sender] > 0);

         
        require(ownerShareTokens[msg.sender] >= amount);

         
        ownerShareTokens[msg.sender] = SafeMath.sub(ownerShareTokens[msg.sender], amount);

         
        if (ownerShareTokens[msg.sender] == 0) {
            ownerPercentages[msg.sender] = 0;
            whitelist[receiver] = false; 
            
        } else {  
            ownerPercentages[msg.sender] = percent(ownerShareTokens[msg.sender], valuation, 5);
        }

         
        if (ownerShareTokens[receiver] == 0) {
            whitelist[receiver] = true;
            ownerAddresses[totalOwners] = receiver;
            totalOwners += 1;
        }
        ownerShareTokens[receiver] = SafeMath.add(ownerShareTokens[receiver], amount);
        ownerPercentages[receiver] = SafeMath.add(ownerPercentages[receiver], percent(amount, valuation, 5));

        emit OwnershipTransferred(msg.sender, receiver, amount);
    }

     
    function lockShares() public onlyOwner() {
        require(!locked);
        locked = true;
    }

     
    function distributeTokens(address token) public onlyWhitelisted() {
         
        require(!distributionActive);
        distributionActive = true;

         
        ERC677 erc677 = ERC677(token);

         
        uint256 currentBalance = erc677.balanceOf(this) - tokenBalance[token];
        require(currentBalance > ethWei * distributionMinimum);

         
        tokenBalance[token] = SafeMath.add(tokenBalance[token], currentBalance);

         
         
         
        for (uint64 i = 0; i < totalOwners; i++) {
            address owner = ownerAddresses[i];

             
            if (ownerShareTokens[owner] > 0) {
                 
                balances[owner][token] = SafeMath.add(SafeMath.div(SafeMath.mul(currentBalance, ownerPercentages[owner]), 100000), balances[owner][token]);
            }
        }
        distributionActive = false;

         
        emit TokenDistribution(token, currentBalance);
    }

     
    function withdrawTokens(address token, uint256 amount) public {
         
        require(amount > 0);

         
        require(balances[msg.sender][token] >= amount);

         
        balances[msg.sender][token] = SafeMath.sub(balances[msg.sender][token], amount);
        tokenBalance[token] = SafeMath.sub(tokenBalance[token], amount);

         
        ERC677 erc677 = ERC677(token);
        require(erc677.transfer(msg.sender, amount) == true);

         
        emit TokenWithdrawal(token, msg.sender, amount);
    }

     
    function setDistributionMinimum(uint16 minimum) public onlyOwner() {
        distributionMinimum = minimum;
    }

     
    function isWhitelisted(address contributor) public view returns (bool) {
        return whitelist[contributor];
    }

     
    function getOwnerBalance(address token) public view returns (uint256) {
        return balances[msg.sender][token];
    }

     

     
    function percent(uint numerator, uint denominator, uint precision) private pure returns (uint quotient) {
        uint _numerator = numerator * 10 ** (precision+1);
        uint _quotient = ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }
}