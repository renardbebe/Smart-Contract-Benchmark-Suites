 

pragma solidity ^0.4.13;
contract IERC20Token {
  function totalSupply() constant returns (uint256 totalSupply);
  function balanceOf(address _owner) constant returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) returns (bool success) {}
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
  function approve(address _spender, uint256 _value) returns (bool success) {}
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract IToken {
  function totalSupply() constant returns (uint256 totalSupply);
  function mintTokens(address _to, uint256 _amount) {}
}
contract Owned {
    address public owner;
    address public newOwner;
    function Owned() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
    event OwnerUpdate(address _prevOwner, address _newOwner);
}
contract ReentrancyHandling {
    bool locked;
    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
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
contract Crowdsale is ReentrancyHandling, Owned {
  using SafeMath for uint256;
  
  struct ContributorData {
    bool isWhiteListed;
    bool isCommunityRoundApproved;
    uint256 contributionAmount;
    uint256 tokensIssued;
  }
  mapping(address => ContributorData) public contributorList;
  enum state { pendingStart, communityRound, crowdsaleStarted, crowdsaleEnded }
  state crowdsaleState;
  uint public communityRoundStartDate;
  uint public crowdsaleStartDate;
  uint public crowdsaleEndDate;
  event CommunityRoundStarted(uint timestamp);
  event CrowdsaleStarted(uint timestamp);
  event CrowdsaleEnded(uint timestamp);
  IToken token = IToken(0x0);
  uint ethToTokenConversion;
  uint256 maxCrowdsaleCap;
  uint256 maxCommunityCap;
  uint256 maxCommunityWithoutBonusCap;
  uint256 maxContribution;
  uint256 tokenSold = 0;
  uint256 communityTokenSold = 0;
  uint256 communityTokenWithoutBonusSold = 0;
  uint256 crowdsaleTokenSold = 0;
  uint256 public ethRaisedWithoutCompany = 0;
  address companyAddress;    
  uint maxTokenSupply;
  uint companyTokens;
  bool treasuryLocked = false;
  bool ownerHasClaimedTokens = false;
  bool ownerHasClaimedCompanyTokens = false;
   
  modifier onlyWhiteListUser {
    require(contributorList[msg.sender].isWhiteListed == true);
    _;
  }
   
  modifier onlyLowGasPrice {
	  require(tx.gasprice <= 50*10**9 wei);
	  _;
  }
   
   
   
  function() public noReentrancy onlyWhiteListUser onlyLowGasPrice payable {
    require(msg.value != 0);                                          
    require(companyAddress != 0x0);
    require(token != IToken(0x0));
    checkCrowdsaleState();                                            
    assert((crowdsaleState == state.communityRound && contributorList[msg.sender].isCommunityRoundApproved) ||
            crowdsaleState == state.crowdsaleStarted);
    
    processTransaction(msg.sender, msg.value);                        
    checkCrowdsaleState();                                            
  }
   
   
   
  function getState() public constant returns (uint256, uint256, uint) {
    uint currentState = 0;
    if (crowdsaleState == state.pendingStart) {
      currentState = 1;
    }
    else if (crowdsaleState == state.communityRound) {
      currentState = 2;
    }
    else if (crowdsaleState == state.crowdsaleStarted) {
      currentState = 3;
    }
    else if (crowdsaleState == state.crowdsaleEnded) {
      currentState = 4;
    }
    return (tokenSold, communityTokenSold, currentState);
  }
   
   
   
  function checkCrowdsaleState() internal {
    if (now > crowdsaleEndDate || tokenSold >= maxTokenSupply) {   
      if (crowdsaleState != state.crowdsaleEnded) {
        crowdsaleState = state.crowdsaleEnded;
        CrowdsaleEnded(now);
      }
    }
    else if (now > crowdsaleStartDate) {  
      if (crowdsaleState != state.crowdsaleStarted) {
        uint256 communityTokenRemaining = maxCommunityCap.sub(communityTokenSold);   
        maxCrowdsaleCap = maxCrowdsaleCap.add(communityTokenRemaining);
        crowdsaleState = state.crowdsaleStarted;   
        CrowdsaleStarted(now);
      }
    }
    else if (now > communityRoundStartDate) {
      if (communityTokenSold < maxCommunityCap) {
        if (crowdsaleState != state.communityRound) {
          crowdsaleState = state.communityRound;
          CommunityRoundStarted(now);
        }
      }
      else {   
        if (crowdsaleState != state.crowdsaleStarted) {
          crowdsaleState = state.crowdsaleStarted;
          CrowdsaleStarted(now);
        }
      }
    }
  }
   
   
   
  function calculateCommunity(address _contributor, uint256 _newContribution) internal returns (uint256, uint256) {
    uint256 communityEthAmount = 0;
    uint256 communityTokenAmount = 0;
    uint previousContribution = contributorList[_contributor].contributionAmount;   
     
    if (crowdsaleState == state.communityRound && 
        contributorList[_contributor].isCommunityRoundApproved && 
        previousContribution < maxContribution) {
        communityEthAmount = _newContribution;
        uint256 availableEthAmount = maxContribution.sub(previousContribution);                 
         
        if (communityEthAmount > availableEthAmount) {
          communityEthAmount = availableEthAmount;
        }
         
        communityTokenAmount = communityEthAmount.mul(ethToTokenConversion);
        uint256 availableTokenAmount = maxCommunityWithoutBonusCap.sub(communityTokenWithoutBonusSold);
         
        if (communityTokenAmount > availableTokenAmount) {
           
          communityTokenAmount = availableTokenAmount;
           
          communityEthAmount = communityTokenAmount.div(ethToTokenConversion);
        }
         
        communityTokenWithoutBonusSold = communityTokenWithoutBonusSold.add(communityTokenAmount);
         
        uint256 bonusTokenAmount = communityTokenAmount.mul(15);
        bonusTokenAmount = bonusTokenAmount.div(100);
         
        communityTokenAmount = communityTokenAmount.add(bonusTokenAmount);
         
        communityTokenSold = communityTokenSold.add(communityTokenAmount);
    }
    return (communityTokenAmount, communityEthAmount);
  }
   
   
   
  function calculateCrowdsale(uint256 _remainingContribution) internal returns (uint256, uint256) {
    uint256 crowdsaleEthAmount = _remainingContribution;
     
    uint256 crowdsaleTokenAmount = crowdsaleEthAmount.mul(ethToTokenConversion);
     
    uint256 availableTokenAmount = maxCrowdsaleCap.sub(crowdsaleTokenSold);
     
    if (crowdsaleTokenAmount > availableTokenAmount) {
       
      crowdsaleTokenAmount = availableTokenAmount;
       
      crowdsaleEthAmount = crowdsaleTokenAmount.div(ethToTokenConversion);
    }
     
    crowdsaleTokenSold = crowdsaleTokenSold.add(crowdsaleTokenAmount);
    return (crowdsaleTokenAmount, crowdsaleEthAmount);
  }
   
   
   
  function processTransaction(address _contributor, uint256 _amount) internal {
    uint256 newContribution = _amount;
    var (communityTokenAmount, communityEthAmount) = calculateCommunity(_contributor, newContribution);
     
    var (crowdsaleTokenAmount, crowdsaleEthAmount) = calculateCrowdsale(newContribution.sub(communityEthAmount));
     
    uint256 tokenAmount = crowdsaleTokenAmount.add(communityTokenAmount);
    assert(tokenAmount > 0);
     
    token.mintTokens(_contributor, tokenAmount);                              
     
    contributorList[_contributor].tokensIssued = contributorList[_contributor].tokensIssued.add(tokenAmount);                
     
    newContribution = crowdsaleEthAmount.add(communityEthAmount);
    contributorList[_contributor].contributionAmount = contributorList[_contributor].contributionAmount.add(newContribution);
    ethRaisedWithoutCompany = ethRaisedWithoutCompany.add(newContribution);                               
    tokenSold = tokenSold.add(tokenAmount);                                   
     
    uint256 refundAmount = _amount.sub(newContribution);
    if (refundAmount > 0) {
      _contributor.transfer(refundAmount);                                    
    }
    companyAddress.transfer(newContribution);                                 
  }
   
   
   
  function WhiteListContributors(address[] _contributorAddresses, bool[] _contributorCommunityRoundApproved) public onlyOwner {
    require(_contributorAddresses.length == _contributorCommunityRoundApproved.length);  
    for (uint cnt = 0; cnt < _contributorAddresses.length; cnt++) {
      contributorList[_contributorAddresses[cnt]].isWhiteListed = true;
      contributorList[_contributorAddresses[cnt]].isCommunityRoundApproved = _contributorCommunityRoundApproved[cnt];
    }
  }
   
   
   
  function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) public onlyOwner {
    IERC20Token(_tokenAddress).transfer(_to, _amount);
  }
   
   
   
  function setCompanyAddress(address _newAddress) public onlyOwner {
    require(!treasuryLocked);                               
    companyAddress = _newAddress;
    treasuryLocked = true;
  }
   
   
   
  function setToken(address _newAddress) public onlyOwner {
    token = IToken(_newAddress);
  }
  function getToken() public constant returns (address) {
    return address(token);
  }
   
   
   
  function claimCompanyTokens() public onlyOwner {
    require(!ownerHasClaimedCompanyTokens);                      
    require(companyAddress != 0x0);
    
    tokenSold = tokenSold.add(companyTokens); 
    token.mintTokens(companyAddress, companyTokens);             
    ownerHasClaimedCompanyTokens = true;                         
  }
   
   
   
  function claimRemainingTokens() public onlyOwner {
    checkCrowdsaleState();                                         
    require(crowdsaleState == state.crowdsaleEnded);               
    require(!ownerHasClaimedTokens);                               
    require(companyAddress != 0x0);
    uint256 remainingTokens = maxTokenSupply.sub(token.totalSupply());
    token.mintTokens(companyAddress, remainingTokens);             
    ownerHasClaimedTokens = true;                                  
  }
}
contract StormCrowdsale is Crowdsale {
    string public officialWebsite;
    string public officialFacebook;
    string public officialTelegram;
    string public officialEmail;
  function StormCrowdsale() public {
    officialWebsite = "https://www.stormtoken.com";
    officialFacebook = "https://www.facebook.com/stormtoken/";
    officialTelegram = "https://t.me/joinchat/GHTZGQwsy9mZk0KFEEjGtg";
    officialEmail = "<a class="__cf_email__" data-cfemail="85ecebe3eac5f6f1eaf7e8f1eaeee0ebabe6eae8" href="/cdn-cgi/l/email-protection">[email protected]</a>";
    communityRoundStartDate = 1510063200;                        
    crowdsaleStartDate = communityRoundStartDate + 24 hours;     
    crowdsaleEndDate = communityRoundStartDate + 30 days + 12 hours;  
    crowdsaleState = state.pendingStart;
    ethToTokenConversion = 26950;                  
    maxTokenSupply = 10000000000 ether;            
    companyTokens = 8124766171 ether;              
                                                   
    maxCommunityWithoutBonusCap = 945000000 ether;
    maxCommunityCap = 1086750000 ether;            
    maxCrowdsaleCap = 788483829 ether;             
    maxContribution = 100 ether;                   
  }
}