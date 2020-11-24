 

pragma solidity ^0.4.15;

 
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


 
 
contract DNNToken {
    enum DNNSupplyAllocations {
        EarlyBackerSupplyAllocation,
        PRETDESupplyAllocation,
        TDESupplyAllocation,
        BountySupplyAllocation,
        WriterAccountSupplyAllocation,
        AdvisorySupplyAllocation,
        PlatformSupplyAllocation
    }
    function balanceOf(address who) constant public returns (uint256);
    function issueTokens(address, uint256, DNNSupplyAllocations) public pure returns (bool) {}
}

 
contract DNNAdvisoryLockBox {

  using SafeMath for uint256;

   
  DNNToken public dnnToken;

   
  address public cofounderA;
  address public cofounderB;

   
  mapping(address => uint256) advisorsWithEntitledSupply;

   
	mapping(address => uint256) advisorsTokensIssued;

   
	mapping(address => uint256) advisorsTokensIssuedOn;

   
	event AdvisorTokensSent(address to, uint256 issued, uint256 remaining);
	event AdvisorAdded(address advisor);
	event AdvisorAddressChanged(address oldaddress, address newaddress);
  event NotWhitelisted(address to);
  event NoTokensRemaining(address advisor);
  event NextRedemption(uint256 nextTime);

   
  modifier onlyCofounders() {
      require (msg.sender == cofounderA || msg.sender == cofounderB);
      _;
  }

   
  function replaceAdvisorAddress(address oldaddress, address newaddress) public onlyCofounders {
       
      if (advisorsWithEntitledSupply[oldaddress] > 0) {
          advisorsWithEntitledSupply[newaddress] = advisorsWithEntitledSupply[oldaddress];
          advisorsWithEntitledSupply[oldaddress] = 0;
          emit AdvisorAddressChanged(oldaddress, newaddress);
      }
      else {
          emit NotWhitelisted(oldaddress);
      }
  }

   
  function nextRedemptionTime(address advisorAddress) public view returns (uint256) {
      return advisorsTokensIssuedOn[advisorAddress] == 0 ? now : (advisorsTokensIssuedOn[advisorAddress] + 30 days);
  }

   
  function checkRemainingTokens(address advisorAddress) public view returns (uint256) {
      return advisorsWithEntitledSupply[advisorAddress] - advisorsTokensIssued[advisorAddress];
  }

   
  function isWhitelisted(address advisorAddress) public view returns (bool) {
     return advisorsWithEntitledSupply[advisorAddress] != 0;
  }

   
  function addAdvisor(address advisorAddress, uint256 entitledTokenAmount) public onlyCofounders {
      advisorsWithEntitledSupply[advisorAddress] = entitledTokenAmount;
      emit AdvisorAdded(advisorAddress);
  }

   
  function advisorEntitlement(address advisorAddress) public view returns (uint256) {
      return advisorsWithEntitledSupply[advisorAddress];
  }

  constructor() public
  {
       
      dnnToken = DNNToken(0x9D9832d1beb29CC949d75D61415FD00279f84Dc2);

       
      cofounderA = 0x3Cf26a9FE33C219dB87c2e50572e50803eFb2981;
      cofounderB = 0x9FFE2aD5D76954C7C25be0cEE30795279c4Cab9f;
  }

	 
	function () public payable {

       
       
      if (advisorsWithEntitledSupply[msg.sender] > 0) {

           
          if (advisorsTokensIssued[msg.sender] < advisorsWithEntitledSupply[msg.sender]) {

               
              if (advisorsTokensIssuedOn[msg.sender] == 0 || ((now - advisorsTokensIssuedOn[msg.sender]) >= 30 days)) {

                   
                  uint256 tokensToIssue = advisorsWithEntitledSupply[msg.sender].div(10);

                   
                  advisorsTokensIssued[msg.sender] = advisorsTokensIssued[msg.sender].add(tokensToIssue);

                   
                  advisorsTokensIssuedOn[msg.sender] = now;

                   
                  DNNToken.DNNSupplyAllocations allocationType = DNNToken.DNNSupplyAllocations.AdvisorySupplyAllocation;

                   
                  if (!dnnToken.issueTokens(msg.sender, tokensToIssue, allocationType)) {
                      revert();
                  }
                  else {
                     emit AdvisorTokensSent(msg.sender, tokensToIssue, checkRemainingTokens(msg.sender));
                  }
              }
              else {
                   emit NextRedemption(advisorsTokensIssuedOn[msg.sender] + 30 days);
              }
          }
          else {
            emit NoTokensRemaining(msg.sender);
          }
      }
      else {
        emit NotWhitelisted(msg.sender);
      }
	}

}