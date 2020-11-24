 

pragma solidity ^0.4.13;

 
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


   
  function Ownable() {
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

contract AbstractStarbaseToken {
    function isFundraiser(address fundraiserAddress) public returns (bool);
    function company() public returns (address);
    function allocateToCrowdsalePurchaser(address to, uint256 value) public returns (bool);
    function allocateToMarketingSupporter(address to, uint256 value) public returns (bool);
}

 
contract StarbaseMarketingCampaign is Ownable {
     
    event NewContributor (address indexed contributorAddress, uint256 tokenCount);
    event WithdrawContributorsToken(address indexed contributorAddress, uint256 tokenWithdrawn);

     
    AbstractStarbaseToken public starbaseToken;

     
    struct Contributor {
        uint256 rewardedTokens;
        mapping (bytes32 => bool) contributions;   
        bool isContributor;
    }

     
    address[] public contributors;
    mapping (address => Contributor) public contributor;

     

     
    function StarbaseMarketingCampaign() {
        owner = msg.sender;
    }

     

     
    function setup(address starbaseTokenAddress)
        external
        onlyOwner
        returns (bool)
    {
        assert(address(starbaseToken) == 0);
        starbaseToken = AbstractStarbaseToken(starbaseTokenAddress);
        return true;
    }

     
    function deliverRewardedTokens(
        address contributorAddress,
        uint256 tokenCount,
        string contributionId
    )
        external
        onlyOwner
        returns(bool)
    {

        bytes32 id = keccak256(contributionId);

        assert(!contributor[contributorAddress].contributions[id]);
        contributor[contributorAddress].contributions[id] = true;

        contributor[contributorAddress].rewardedTokens = SafeMath.add(contributor[contributorAddress].rewardedTokens, tokenCount);

        if (!contributor[contributorAddress].isContributor) {
            contributor[contributorAddress].isContributor = true;
            contributors.push(contributorAddress);
            NewContributor(contributorAddress, tokenCount);
        }

        starbaseToken.allocateToMarketingSupporter(contributorAddress, tokenCount);
        WithdrawContributorsToken(contributorAddress, tokenCount);

        return true;
    }


     

     
    function getContributorInfo(address contributorAddress, string contributionId)
        constant
        public
        returns (uint256, bool, bool)
    {
        bytes32 id = keccak256(contributionId);

        return(
          contributor[contributorAddress].rewardedTokens,
          contributor[contributorAddress].contributions[id],
          contributor[contributorAddress].isContributor
        );
    }

     
    function numberOfContributors()
        constant
        public
        returns (uint256)
    {
        return contributors.length;
    }
}