 

 
 
 pragma solidity ^0.4.18;

 


 
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
 
 
 
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() public { owner = msg.sender; }

   
  modifier onlyOwner() { require(msg.sender == owner); _; }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

} 
 

 


 


 


 


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 



 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
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
     
    assert(allowed[msg.sender][_spender] == 0 || _value == 0);
    
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}
 

contract TraceToken is MintableToken {

    string public constant name = 'Trace Token';
    string public constant symbol = 'TRACE';
    uint8 public constant decimals = 18;
    bool public transferAllowed = false;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event TransferAllowed(bool transferIsAllowed);

    modifier canTransfer() {
        require(mintingFinished && transferAllowed);
        _;        
    }

    function transferFrom(address from, address to, uint256 value) canTransfer public returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function transfer(address to, uint256 value) canTransfer public returns (bool) {
        return super.transfer(to, value);
    }

    function mint(address contributor, uint256 amount) public returns (bool) {
        return super.mint(contributor, amount);
    }

    function endMinting(bool _transferAllowed) public returns (bool) {
        transferAllowed = _transferAllowed;
        TransferAllowed(_transferAllowed);
        return super.finishMinting();
    }
}
 

contract TraceTokenSale is Ownable{
	using SafeMath for uint256;

	 
	TraceToken public token;

   
  uint256 public constant TOTAL_NUM_TOKENS = 5e26;  
  uint256 public constant tokensForSale = 25e25;  

   
  uint256 public totalEthers = 0;

   
  uint256 public constant softCap = 3984.064 ether; 
   
  uint256 public constant hardCap = 17928.287 ether; 
  
  uint256 public constant presaleLimit = 7968.127 ether; 
  bool public presaleLimitReached = false;

   
  uint256 public constant min_investment_eth = 0.5 ether;  
  uint256 public constant max_investment_eth = 398.4064 ether; 

  uint256 public constant min_investment_presale_eth = 5 ether;  

   
  bool public refundAllowed = false;

   
  bool public paused = false;

  uint256 public constant bountyReward = 1e25;
  uint256 public constant preicoAndAdvisors = 4e25;
  uint256 public constant liquidityPool = 25e24;
  uint256 public constant futureDevelopment = 1e26; 
  uint256 public constant teamAndFounders = 75e24;  

  uint256 public leftOverTokens = 0;

  uint256[8] public founderAmounts = [uint256(teamAndFounders.div(8)),teamAndFounders.div(8),teamAndFounders.div(8),teamAndFounders.div(8),teamAndFounders.div(8),teamAndFounders.div(8),teamAndFounders.div(8),teamAndFounders.div(8)];
  uint256[2]  public preicoAndAdvisorsAmounts = [ uint256(preicoAndAdvisors.mul(2).div(5)),preicoAndAdvisors.mul(2).div(5)];


   
  address public wallet;

   
  address public teamAndFoundersWallet;

   
  address public advisorsAndPreICO;

   
  uint256 public constant token_per_wei = 12550;

   
  uint256 public startTime;
  uint256 public endTime;

  uint256 private constant weekInSeconds = 86400 * 7;

   
  mapping(address => uint256) public whitelist;

   
  mapping(address => uint256) public etherBalances;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event Whitelist(address indexed beneficiary, uint256 value);
  event SoftCapReached();
  event Finalized();

  function TraceTokenSale(uint256 _startTime, address traceTokenAddress, address _wallet, address _teamAndFoundersWallet, address _advisorsAndPreICO) public {
    require(_startTime >=  now);
    require(_wallet != 0x0);
    require(_teamAndFoundersWallet != 0x0);
    require(_advisorsAndPreICO != 0x0);

    token = TraceToken(traceTokenAddress);
    wallet = _wallet;
    teamAndFoundersWallet = _teamAndFoundersWallet;
    advisorsAndPreICO = _advisorsAndPreICO;
    startTime = _startTime;
    endTime = _startTime + 4 * weekInSeconds;  
    
  }
     
     function() public payable {
       return buyTokens(msg.sender);
     }

     function calcAmount() internal view returns (uint256) {

      if (totalEthers >= presaleLimit || startTime + 2 * weekInSeconds  < now ){
         
        return msg.value.mul(token_per_wei);
        }else{
           
          require(msg.value >= min_investment_presale_eth);

           
          if (now <= startTime + weekInSeconds) {
            return msg.value.mul(token_per_wei.mul(100)).div(80);

          }

           
          if ( startTime +  weekInSeconds  < now ) {
           return msg.value.mul(token_per_wei.mul(100)).div(85);
         }
       }

     }

     
     function buyTokens(address contributor) public payable {
       require(!hasEnded());
       require(!isPaused());
       require(validPurchase());
       require(checkWhitelist(contributor,msg.value));
       uint256 amount = calcAmount();
       require((token.totalSupply() + amount) <= TOTAL_NUM_TOKENS);
       
       whitelist[contributor] = whitelist[contributor].sub(msg.value);
       etherBalances[contributor] = etherBalances[contributor].add(msg.value);

       totalEthers = totalEthers.add(msg.value);

       token.mint(contributor, amount);
       require(totalEthers <= hardCap); 
       TokenPurchase(0x0, contributor, msg.value, amount);
     }


      
     function balanceOf(address _owner) public view returns (uint256 balance) {
      return token.balanceOf(_owner);
    }

    function checkWhitelist(address contributor, uint256 eth_amount) public view returns (bool) {
     require(contributor!=0x0);
     require(eth_amount>0);
     return (whitelist[contributor] >= eth_amount);
   }

   function addWhitelist(address contributor, uint256 eth_amount) onlyOwner public returns (bool) {
     require(!hasEnded());
     require(contributor!=0x0);
     require(eth_amount>0);
     Whitelist(contributor, eth_amount);
     whitelist[contributor] = eth_amount;
     return true;
   }

   function addWhitelists(address[] contributors, uint256[] amounts) onlyOwner public returns (bool) {
     require(!hasEnded());
     address contributor;
     uint256 amount;
     require(contributors.length == amounts.length);

     for (uint i = 0; i < contributors.length; i++) {
      contributor = contributors[i];
      amount = amounts[i];
      require(addWhitelist(contributor, amount));
    }
    return true;
  }


  function validPurchase() internal view returns (bool) {

   bool withinPeriod = now >= startTime && now <= endTime;
   bool withinPurchaseLimits = msg.value >= min_investment_eth && msg.value <= max_investment_eth;
   return withinPeriod && withinPurchaseLimits;
 }

 function hasStarted() public view returns (bool) {
  return now >= startTime;
}

function hasEnded() public view returns (bool) {
  return now > endTime || token.totalSupply() == TOTAL_NUM_TOKENS;
}


function hardCapReached() public view returns (bool) {
  return hardCap.mul(999).div(1000) <= totalEthers; 
}

function softCapReached() public view returns(bool) {
  return totalEthers >= softCap;
}


function withdraw() onlyOwner public {
  require(softCapReached());
  require(this.balance > 0);

  wallet.transfer(this.balance);
}

function withdrawTokenToFounders() onlyOwner public {
  require(softCapReached());
  require(hasEnded());

  if (now > startTime + 720 days && founderAmounts[7]!=0){
    token.transfer(teamAndFoundersWallet, founderAmounts[7]);
    founderAmounts[7] = 0;
  }

  if (now > startTime + 630 days && founderAmounts[6]!=0){
    token.transfer(teamAndFoundersWallet, founderAmounts[6]);
    founderAmounts[6] = 0;
  }
  if (now > startTime + 540 days && founderAmounts[5]!=0){
    token.transfer(teamAndFoundersWallet, founderAmounts[5]);
    founderAmounts[5] = 0;
  }
  if (now > startTime + 450 days && founderAmounts[4]!=0){
    token.transfer(teamAndFoundersWallet, founderAmounts[4]);
    founderAmounts[4] = 0;
  }
  if (now > startTime + 360 days&& founderAmounts[3]!=0){
    token.transfer(teamAndFoundersWallet, founderAmounts[3]);
    founderAmounts[3] = 0;
  }
  if (now > startTime + 270 days && founderAmounts[2]!=0){
    token.transfer(teamAndFoundersWallet, founderAmounts[2]);
    founderAmounts[2] = 0;
  }
  if (now > startTime + 180 days && founderAmounts[1]!=0){
    token.transfer(teamAndFoundersWallet, founderAmounts[1]);
    founderAmounts[1] = 0;
  }
  if (now > startTime + 90 days && founderAmounts[0]!=0){
    token.transfer(teamAndFoundersWallet, founderAmounts[0]);
    founderAmounts[0] = 0;
  }
}

function withdrawTokensToAdvisors() onlyOwner public {
  require(softCapReached());
  require(hasEnded());

  if (now > startTime + 180 days && preicoAndAdvisorsAmounts[1]!=0){
    token.transfer(advisorsAndPreICO, preicoAndAdvisorsAmounts[1]);
    preicoAndAdvisorsAmounts[1] = 0;
  }

  if (now > startTime + 90 days && preicoAndAdvisorsAmounts[0]!=0){
    token.transfer(advisorsAndPreICO, preicoAndAdvisorsAmounts[0]);
    preicoAndAdvisorsAmounts[0] = 0;
  }
}

function refund() public {
  require(refundAllowed);
  require(hasEnded());
  require(!softCapReached());
  require(etherBalances[msg.sender] > 0);
  require(token.balanceOf(msg.sender) > 0);

  uint256 current_balance = etherBalances[msg.sender];
  etherBalances[msg.sender] = 0;
  token.transfer(this,token.balanceOf(msg.sender));  
  msg.sender.transfer(current_balance);
}


function finishCrowdsale() onlyOwner public returns (bool){
  require(!token.mintingFinished());
  require(hasEnded() || hardCapReached());

  if(softCapReached()) {
    token.mint(wallet, bountyReward);
    token.mint(advisorsAndPreICO,  preicoAndAdvisors.div(5));  
    token.mint(wallet, liquidityPool);
    token.mint(wallet, futureDevelopment);
    token.mint(this, teamAndFounders);
    token.mint(this, preicoAndAdvisors.mul(4).div(5)); 
    leftOverTokens = TOTAL_NUM_TOKENS.sub(token.totalSupply());
    token.mint(wallet,leftOverTokens);  

    token.endMinting(true);
    return true;
    } else {
      refundAllowed = true;
      token.endMinting(false);
      return false;
    }

    Finalized();
  }


   
  function pauseSale() onlyOwner public returns (bool){
    paused = true;
    return true;
  }

  function unpauseSale() onlyOwner public returns (bool){
    paused = false;
    return true;
  }

  function isPaused() public view returns (bool){
    return paused;
  }
}