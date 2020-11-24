 

pragma solidity 0.4.25;

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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

contract ClaimReward is Ownable {
     
    event LogClaimReward(address indexed sender, uint256 indexed rewards);
    
    address communityFundAddress = 0x325a7A78e5da2333b475570398F27D8F4e8E9Eb3;
    address livePeerContractAddress = 0x58b6A8A3302369DAEc383334672404Ee733aB239;

     
    address[] private delegatorAddressList;

    mapping (address => Delegator) rewardDelegators;
     
    uint256 public claimCounter = 0;
     
    bool public contractStopped = false;
    
    struct Delegator {
        address delegator;
        uint rewards;
        bool hasClaimed;
    }
    
     
    modifier haltInEmergency {
        require(!contractStopped);
        _;
    }
    
     
     
    function toggleContractStopped() public onlyOwner {
        contractStopped = !contractStopped;
    }
    
     
    function updateDelegatorRewards(address[] delegatorAddress, uint[] rewards) onlyOwner public returns (bool) {
        for (uint i=0; i<delegatorAddress.length; i++) {
            Delegator memory delegator = Delegator(delegatorAddress[i], rewards[i] * 10 ** 14 , false);
            rewardDelegators[delegatorAddress[i]] = delegator;
            delegatorAddressList.push(delegatorAddress[i]);
        }
        return true;
    }
    
     
    function checkRewards() external view returns (uint256) {
        return rewardDelegators[msg.sender].rewards;
    }
    
     
    function claimRewards() external haltInEmergency returns (bool) {
        require(!rewardDelegators[msg.sender].hasClaimed);
        require(rewardDelegators[msg.sender].delegator == msg.sender);
        require((ERC20(livePeerContractAddress).balanceOf(this) - this.checkRewards()) > 0);
        require(claimCounter < this.getAllDelegatorAddress().length);
        
        rewardDelegators[msg.sender].hasClaimed = true;
        claimCounter += 1;
        ERC20(livePeerContractAddress).transfer(msg.sender, rewardDelegators[msg.sender].rewards);
        
        emit LogClaimReward(msg.sender, rewardDelegators[msg.sender].rewards);
        
        return true;
    }

     
    function activateCommunityFund() external onlyOwner returns (bool) {
        require(ERC20(livePeerContractAddress).balanceOf(this) > 0);
        ERC20(livePeerContractAddress).transfer(communityFundAddress, ERC20(livePeerContractAddress).balanceOf(this));
        return true;
    }
    
     
    function getAllDelegatorAddress() external view returns (address[]) {
        return delegatorAddressList;  
    } 
}