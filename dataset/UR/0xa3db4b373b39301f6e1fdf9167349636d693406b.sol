 

pragma solidity ^0.4.18;

contract FullERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  
  uint256 public totalSupply;
  uint8 public decimals;

  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
}

contract RewardDistributable {
    event TokensRewarded(address indexed player, address rewardToken, uint rewards, address requester, uint gameId, uint block);
    event ReferralRewarded(address indexed referrer, address indexed player, address rewardToken, uint rewards, uint gameId, uint block);
    event ReferralRegistered(address indexed player, address indexed referrer);

     
    function transferRewards(address player, uint entryAmount, uint gameId) public;

     
    function getTotalTokens(address tokenAddress) public constant returns(uint);

     
    function getRewardTokenCount() public constant returns(uint);

     
    function getTotalApprovers() public constant returns(uint);

     
    function getRewardRate(address player, address tokenAddress) public constant returns(uint);

     
     
    function addRequester(address requester) public;

     
     
    function removeRequester(address requester) public;

     
     
    function addApprover(address approver) public;

     
     
    function removeApprover(address approver) public;

     
    function updateRewardRate(address tokenAddress, uint newRewardRate) public;

     
    function addRewardToken(address tokenAddress, uint newRewardRate) public;

     
    function removeRewardToken(address tokenAddress) public;

     
    function updateReferralBonusRate(uint newReferralBonusRate) public;

     
     
     
    function registerReferral(address player, address referrer) public;

     
    function destroyRewards() public;
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

contract RewardDistributor is RewardDistributable, Ownable {
    using SafeMath for uint256;

    struct RewardSource {
        address rewardTokenAddress;
        uint96 rewardRate;  
    }

    RewardSource[] public rewardSources;
    mapping(address => bool) public approvedRewardSources;
    
    mapping(address => bool) public requesters;  
    address[] public approvers;  

    mapping(address => address) public referrers;  
    
    uint public referralBonusRate;

    modifier onlyRequesters() {
        require(requesters[msg.sender] || (msg.sender == owner));
        _;
    }

    modifier validRewardSource(address tokenAddress) {
        require(approvedRewardSources[tokenAddress]);
        _;        
    }

    function RewardDistributor(uint256 rewardRate, address tokenAddress) public {
        referralBonusRate = 10;
        addRewardToken(tokenAddress, rewardRate);
    }

     
    function transferRewards(address player, uint entryAmount, uint gameId) public onlyRequesters {
         
        for (uint i = 0; i < rewardSources.length; i++) {
            transferRewardsInternal(player, entryAmount, gameId, rewardSources[i]);
        }
    }

     
    function getTotalTokens(address tokenAddress) public constant validRewardSource(tokenAddress) returns(uint) {
        for (uint j = 0; j < rewardSources.length; j++) {
            if (rewardSources[j].rewardTokenAddress == tokenAddress) {
                FullERC20 rewardToken = FullERC20(rewardSources[j].rewardTokenAddress);
                uint total = rewardToken.balanceOf(this);
            
                for (uint i = 0; i < approvers.length; i++) {
                    address approver = approvers[i];
                    uint allowance = rewardToken.allowance(approver, this);
                    total = total.add(allowance);
                }

                return total;
            }
        }

        return 0;
    }

     
    function getRewardTokenCount() public constant returns(uint) {
        return rewardSources.length;
    }


     
    function getTotalApprovers() public constant returns(uint) {
        return approvers.length;
    }

     
     
    function getRewardRate(address player, address tokenAddress) public constant validRewardSource(tokenAddress) returns(uint) {
        for (uint j = 0; j < rewardSources.length; j++) {
            if (rewardSources[j].rewardTokenAddress == tokenAddress) {
                RewardSource storage rewardSource = rewardSources[j];
                uint256 rewardRate = rewardSource.rewardRate;
                uint bonusRate = referrers[player] == address(0) ? 0 : referralBonusRate;
                return rewardRate.mul(100).div(100 + bonusRate);
            }
        }

        return 0;
    }

     
     
    function addRequester(address requester) public onlyOwner {
        require(!requesters[requester]);    
        requesters[requester] = true;
    }

     
     
    function removeRequester(address requester) public onlyOwner {
        require(requesters[requester]);
        requesters[requester] = false;
    }

     
     
    function addApprover(address approver) public onlyOwner {
        approvers.push(approver);
    }

     
     
    function removeApprover(address approver) public onlyOwner {
        uint good = 0;
        for (uint i = 0; i < approvers.length; i = i.add(1)) {
            bool isValid = approvers[i] != approver;
            if (isValid) {
                if (good != i) {
                    approvers[good] = approvers[i];            
                }
              
                good = good.add(1);
            } 
        }

         
        approvers.length = good;
    }

     
    function updateRewardRate(address tokenAddress, uint newRewardRate) public onlyOwner {
        require(newRewardRate > 0);
        require(tokenAddress != address(0));

        for (uint i = 0; i < rewardSources.length; i++) {
            if (rewardSources[i].rewardTokenAddress == tokenAddress) {
                rewardSources[i].rewardRate = uint96(newRewardRate);
                return;
            }
        }
    }

     
    function addRewardToken(address tokenAddress, uint newRewardRate) public onlyOwner {
        require(tokenAddress != address(0));
        require(!approvedRewardSources[tokenAddress]);
        
        rewardSources.push(RewardSource(tokenAddress, uint96(newRewardRate)));
        approvedRewardSources[tokenAddress] = true;
    }

     
     
    function removeRewardToken(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(0));
        require(approvedRewardSources[tokenAddress]);

        approvedRewardSources[tokenAddress] = false;

         
         
        for (uint i = 0; i < rewardSources.length; i++) {
            if (rewardSources[i].rewardTokenAddress == tokenAddress) {
                rewardSources[i] = rewardSources[rewardSources.length - 1];
                delete rewardSources[rewardSources.length - 1];
                rewardSources.length--;
                return;
            }
        }
    }

     
    function destroyRewards() public onlyOwner {
        for (uint i = 0; i < rewardSources.length; i++) {
            FullERC20 rewardToken = FullERC20(rewardSources[i].rewardTokenAddress);
            uint tokenBalance = rewardToken.balanceOf(this);
            assert(rewardToken.transfer(owner, tokenBalance));
            approvedRewardSources[rewardSources[i].rewardTokenAddress] = false;
        }

        rewardSources.length = 0;
    }

     
    function updateReferralBonusRate(uint newReferralBonusRate) public onlyOwner {
        require(newReferralBonusRate < 100);
        referralBonusRate = newReferralBonusRate;
    }

     
     
     
    function registerReferral(address player, address referrer) public onlyRequesters {
        if (referrer != address(0) && player != referrer) {
            referrers[player] = referrer;
            ReferralRegistered(player, referrer);
        }
    }

     
    function transferRewardsInternal(address player, uint entryAmount, uint gameId, RewardSource storage rewardSource) internal {
        if (rewardSource.rewardTokenAddress == address(0)) {
            return;
        }
        
        FullERC20 rewardToken = FullERC20(rewardSource.rewardTokenAddress);
        uint rewards = entryAmount.div(rewardSource.rewardRate).mul(10**uint256(rewardToken.decimals()));
        if (rewards == 0) {
            return;
        }

        address referrer = referrers[player];
        uint referralBonus = referrer == address(0) ? 0 : rewards.mul(referralBonusRate).div(100);
        uint totalRewards = referralBonus.mul(2).add(rewards);
        uint playerRewards = rewards.add(referralBonus);

         
        if (rewardToken.balanceOf(this) >= totalRewards) {
            assert(rewardToken.transfer(player, playerRewards));
            TokensRewarded(player, rewardToken, playerRewards, msg.sender, gameId, block.number);

            if (referralBonus > 0) {
                assert(rewardToken.transfer(referrer, referralBonus));
                ReferralRewarded(referrer, rewardToken, player, referralBonus, gameId, block.number);
            }
            
            return;
        }

         
        for (uint i = 0; i < approvers.length; i++) {
            address approver = approvers[i];
            uint allowance = rewardToken.allowance(approver, this);
            if (allowance >= totalRewards) {
                assert(rewardToken.transferFrom(approver, player, playerRewards));
                TokensRewarded(player, rewardToken, playerRewards, msg.sender, gameId, block.number);
                if (referralBonus > 0) {
                    assert(rewardToken.transfer(referrer, referralBonus));
                    ReferralRewarded(referrer, rewardToken, player, referralBonus, gameId, block.number);
                }
                return;
            }
        }
    }
}