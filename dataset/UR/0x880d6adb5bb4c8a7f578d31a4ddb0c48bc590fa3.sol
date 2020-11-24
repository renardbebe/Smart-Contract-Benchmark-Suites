 

pragma solidity ^0.4.15;


 


 
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

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}




contract SteakToken is Ownable {

  using SafeMath for uint256;

  string public name = "Steak Token";
  string public symbol = "BOV";
  uint public decimals = 18;
  uint public totalSupply;       

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed ownerAddress, address indexed spenderAddress, uint256 value);
  event Mint(address indexed to, uint256 amount);
  event MineFinished();

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) returns (bool) {
    if(msg.data.length < (2 * 32) + 4) { revert(); }  
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }


  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
   function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
   function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

     
   function mint(address _to, uint256 _amount) internal returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }


}








 
 contract AuctionCrowdsale is SteakToken {
  using SafeMath for uint;

  uint public initialSale;                   

  bool public saleStarted;
  bool public saleEnded;

  uint public absoluteEndBlock;              

  uint256 public weiRaised;                  

  address[] public investors;                
  uint public numberOfInvestors;
  mapping(address => uint256) public investments;  

  mapping(address => bool) public claimed;       


  bool public bovBatchDistributed;               

  uint public initialPrizeWeiValue;              
  uint public initialPrizeBov;                   

  uint public dailyHashExpires;         





    
   event TokenInvestment(address indexed purchaser, address indexed beneficiary, uint256 value);



    
   function () payable {
    invest(msg.sender);
  }


   
   
  function invest(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validInvestment());

    uint256 weiAmount = msg.value;

    uint investedAmount = investments[beneficiary];

    forwardFunds();

    if (investedAmount > 0) {  
      investments[beneficiary] = investedAmount + weiAmount;  
    } else {  
      investors.push(beneficiary);
      numberOfInvestors += 1;
      investments[beneficiary] = weiAmount;
    }
    weiRaised = weiRaised.add(weiAmount);
    TokenInvestment(msg.sender, beneficiary, weiAmount);
  }



   
  function validInvestment() internal constant returns (bool) {
    bool withinPeriod = saleStarted && !saleEnded;
    bool nonZeroPurchase = (msg.value > 0);
    return withinPeriod && nonZeroPurchase;
  }




   
   
  function distributeAllTokens() public {

    require(!bovBatchDistributed);
    require(crowdsaleHasEnded());

     

    for (uint i=0; i < numberOfInvestors; i++) {
      address investorAddr = investors[i];
      if (!claimed[investorAddr]) {  
        claimed[investorAddr] = true;
        uint amountInvested = investments[investorAddr];
        uint bovEarned = amountInvested.mul(initialSale).div(weiRaised);
        mint(investorAddr, bovEarned);
      }
    }

    bovBatchDistributed = true;
  }


   
   
   
  function claimTokens(address origAddress) public {
    require(crowdsaleHasEnded());
    require(claimed[origAddress] == false);
    uint amountInvested = investments[origAddress];
    uint bovEarned = amountInvested.mul(initialSale).div(weiRaised);
    claimed[origAddress] = true;
    mint(origAddress, bovEarned);
  }


   
  function getCurrentShare(address addr) public constant returns (uint) {
    require(!bovBatchDistributed && !claimed[addr]);  
    uint amountInvested = investments[addr];
    uint currentBovShare = amountInvested.mul(initialSale).div(weiRaised);
    return currentBovShare;
  }



   
  function forwardFunds() internal {
    owner.transfer(msg.value);
  }


   
  function startCrowdsale() onlyOwner {
    require(!saleStarted && !saleEnded);
    saleStarted = true;
  }

   
     
  function endCrowdsale() onlyOwner {
    require(saleStarted && !saleEnded);
    dailyHashExpires = now;  
    saleEnded = true;
    setInitialPrize();
  }

   
  function endCrowdsalePublic() public {
    require(block.number > absoluteEndBlock);
    require(saleStarted && !saleEnded);
    dailyHashExpires = now;
    saleEnded = true;
    setInitialPrize();
  }


   
  function setInitialPrize() internal returns (uint) {
    require(crowdsaleHasEnded());
    require(initialPrizeBov == 0);  
    uint tokenUnitsPerWei = initialSale.div(weiRaised);
    initialPrizeBov = tokenUnitsPerWei.mul(initialPrizeWeiValue);
    return initialPrizeBov;
  }


   
  function crowdsaleHasEnded() public constant returns (bool) {
    return saleStarted && saleEnded;
  }

  function getInvestors() public returns (address[]) {
    return investors;
  }


}







contract Steak is AuctionCrowdsale {
   

  bytes32 public dailyHash;             


  Submission[] public submissions;           
  uint public numSubmissions;

  Submission[] public approvedSubmissions;
  mapping (address => uint) public memberId;     
  Member[] public members;                       

  uint public halvingInterval;                   
  uint public numberOfHalvings;                  



  uint public lastMiningBlock;                   

  bool public ownerCredited;     

  event PicAdded(address msgSender, uint submissionID, address recipient, bytes32 propUrl);  
  event Judged(uint submissionID, bool position, address voter, bytes32 justification);
  event MembershipChanged(address member, bool isMember);

  struct Submission {
    address recipient;     
    bytes32 url;            
    bool judged;           
    bool submissionApproved; 
    address judgedBy;      
    bytes32 adminComments;  
    bytes32 todaysHash;    
    uint awarded;          
  }

   
  struct Member {
    address member;
    bytes32 name;
    uint memberSince;
  }


  modifier onlyMembers {
    require(memberId[msg.sender] != 0);  
    _;
  }


  function Steak() {

    owner = msg.sender;
    initialSale = 10000000 * 1000000000000000000;  

     
     
     
    uint blocksPerHour = 212;
    uint maxCrowdsaleLifeFromLaunchDays = 40;  
    absoluteEndBlock = block.number + (blocksPerHour * 24 * maxCrowdsaleLifeFromLaunchDays);

    uint miningDays = 365;  
    lastMiningBlock = block.number + (blocksPerHour * 24 * miningDays);

    dailyHashExpires = now;

    halvingInterval = 500;     
    numberOfHalvings = 8;       

     
    initialPrizeWeiValue = (357 finney / 10);  

     
  }


   
  function initMembers() onlyOwner {
    addMember(0, '');                         
    addMember(msg.sender, 'Madame BOV');
  }



   
  function creditOwner() onlyOwner {
    require(!ownerCredited);
    uint ownerAward = initialSale / 10;   
    ownerCredited = true;    
    mint(owner, ownerAward);
  }






   
  function addMember(address targetMember, bytes32 memberName) onlyOwner {
    uint id;
    if (memberId[targetMember] == 0) {
      memberId[targetMember] = members.length;
      id = members.length++;
      members[id] = Member({member: targetMember, memberSince: now, name: memberName});
    } else {
      id = memberId[targetMember];
       
    }
    MembershipChanged(targetMember, true);
  }

  function removeMember(address targetMember) onlyOwner {
    if (memberId[targetMember] == 0) revert();

    memberId[targetMember] = 0;

    for (uint i = memberId[targetMember]; i<members.length-1; i++){
      members[i] = members[i+1];
    }
    delete members[members.length-1];
    members.length--;
  }



   
  function submitSteak(address addressToAward, bytes32 steakPicUrl)  returns (uint submissionID) {
    require(crowdsaleHasEnded());
    require(block.number <= lastMiningBlock);  
    submissionID = submissions.length++;  
    Submission storage s = submissions[submissionID];
    s.recipient = addressToAward;
    s.url = steakPicUrl;
    s.judged = false;
    s.submissionApproved = false;
    s.todaysHash = getDailyHash();  

    PicAdded(msg.sender, submissionID, addressToAward, steakPicUrl);
    numSubmissions = submissionID+1;

    return submissionID;
  }

   
  function getSubmission(uint submissionID) public constant returns (address recipient, bytes32 url, bool judged, bool submissionApproved, address judgedBy, bytes32 adminComments, bytes32 todaysHash, uint awarded) {
    Submission storage s = submissions[submissionID];
    recipient = s.recipient;
    url = s.url;                  
    judged = s.judged;            
    submissionApproved = s.submissionApproved;   
    judgedBy = s.judgedBy;            
    adminComments = s.adminComments;  
    todaysHash = s.todaysHash;        
    awarded = s.awarded;          
     
  }



   
  function judge(uint submissionNumber, bool supportsSubmission, bytes32 justificationText) onlyMembers {
    Submission storage s = submissions[submissionNumber];          
    require(!s.judged);                                      

    s.judged = true;
    s.judgedBy = msg.sender;
    s.submissionApproved = supportsSubmission;
    s.adminComments = justificationText;     

    if (supportsSubmission) {  
      uint prizeAmount = getSteakPrize();  
      s.awarded = prizeAmount;             
      mint(s.recipient, prizeAmount);      

       
      uint adminAward = prizeAmount.div(3);
      mint(msg.sender, adminAward);

      approvedSubmissions.push(s);
    }

    Judged(submissionNumber, supportsSubmission, msg.sender, justificationText);
  }


   
  function getSteakPrize() public constant returns (uint) {
    require(initialPrizeBov > 0);  
    uint halvings = numberOfApprovedSteaks().div(halvingInterval);
    if (halvings > numberOfHalvings) {   
      return 0;
    }

    uint prize = initialPrizeBov;

    prize = prize >> halvings;  
    return prize;
  }


  function numberOfApprovedSteaks() public constant returns (uint) {
    return approvedSubmissions.length;
  }


   
   
  function getDailyHash() public returns (bytes32) {
    if (dailyHashExpires > now) {  
      return dailyHash;
    } else {  

       
      bytes32 newHash = block.blockhash(block.number-1);
      dailyHash = newHash;

       
      uint nextExpiration = dailyHashExpires + 24 hours;  
      while (nextExpiration < now) {  
        nextExpiration += 24 hours;
      }
      dailyHashExpires = nextExpiration;
      return newHash;
    }
  }

   
  function minutesToPost() public constant returns (uint) {
    if (dailyHashExpires > now) {
      return (dailyHashExpires - now) / 60;  
    } else {
      return 0;
    }
  }

  function currentBlock() public constant returns (uint) {
    return block.number;
  }
}