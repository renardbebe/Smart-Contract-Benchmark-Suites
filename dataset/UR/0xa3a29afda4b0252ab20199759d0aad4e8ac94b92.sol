 

pragma solidity ^0.4.18;

 

 
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

   
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

 

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transferInternal(address to, uint256 value) internal returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

   
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

   
    function transferInternal(address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

   
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

 

 
contract ERC20 is ERC20Basic {
    function allowanceInternal(address owner, address spender) internal view returns (uint256);
    function transferFromInternal(address from, address to, uint256 value) internal returns (bool);
    function approveInternal(address spender, uint256 value) internal returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


   
    function transferFromInternal(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

   
    function approveInternal(address _spender, uint256 _value) internal returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

   
    function allowanceInternal(address _owner, address _spender) internal view returns (uint256) {
        return allowed[_owner][_spender];
    }

   
    function increaseApprovalInternal(address _spender, uint _addedValue) internal returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

   
    function decreaseApprovalInternal(address _spender, uint _subtractedValue) internal returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

 

 
 



 
contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;
    address public icoContractAddress;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    modifier onlyIcoContract() {
        require(msg.sender == icoContractAddress);
        _;
    }


     
    function mint(address _to, uint256 _amount) onlyIcoContract canMint external returns (bool) {
         
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint external returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

}

 

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


   
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

   
    modifier whenPaused() {
        require(paused);
        _;
    }

   
    function pause() onlyOwner whenNotPaused external {
        paused = true;
        emit Pause();
    }

   
    function unpause() onlyOwner whenPaused external {
        paused = false;
        emit Unpause();
    }
}

 

 
contract PausableToken is StandardToken, Pausable {

    function transferInternal(address _to, uint256 _value) internal whenNotPaused returns (bool) {
        return super.transferInternal(_to, _value);
    }

    function transferFromInternal(address _from, address _to, uint256 _value) internal whenNotPaused returns (bool) {
        return super.transferFromInternal(_from, _to, _value);
    }

    function approveInternal(address _spender, uint256 _value) internal whenNotPaused returns (bool) {
        return super.approveInternal(_spender, _value);
    }

    function increaseApprovalInternal(address _spender, uint _addedValue) internal whenNotPaused returns (bool success) {
        return super.increaseApprovalInternal(_spender, _addedValue);
    }

    function decreaseApprovalInternal(address _spender, uint _subtractedValue) internal whenNotPaused returns (bool success) {
        return super.decreaseApprovalInternal(_spender, _subtractedValue);
    }
}

 

 
contract ReentrancyGuard {

   
  bool private reentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!reentrancy_lock);
    reentrancy_lock = true;
    _;
    reentrancy_lock = false;
  }

}

 

contract IiinoCoin is MintableToken, PausableToken, ReentrancyGuard {
    event RewardMint(address indexed to, uint256 amount);
    event RewardMintingAmt(uint256 _amountOfTokensMintedPreCycle);
    event ResetReward();
    event RedeemReward(address indexed to, uint256 value);

    event CreatedEscrow(bytes32 _tradeHash);
    event ReleasedEscrow(bytes32 _tradeHash);
    event Dispute(bytes32 _tradeHash);
    event CancelledBySeller(bytes32 _tradeHash);
    event CancelledByBuyer(bytes32 _tradeHash);
    event BuyerArbitratorSet(bytes32 _tradeHash);
    event SellerArbitratorSet(bytes32 _tradeHash);
    event DisputeResolved (bytes32 _tradeHash);
    event IcoContractAddressSet (address _icoContractAddress);

    using SafeMath for uint256;

     
    mapping(address => uint256) public reward;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public amountMintPerDuration;  
    uint256 public durationBetweenRewardMints;  
    uint256 public previousDistribution;  
    uint256 public totalRewardsDistributed;  
    uint256 public totalRewardsRedeemed;  
    uint256 public minimumRewardWithdrawalLimit;  
    uint256 public rewardAvailableCurrentDistribution;  

    function IiinoCoin(
        string _name,
        string _symbol,
        uint8 _decimals,
        uint256 _amountMintPerDuration,
        uint256 _durationBetweenRewardMints
    ) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        amountMintPerDuration = _amountMintPerDuration;
        durationBetweenRewardMints = _durationBetweenRewardMints;
        previousDistribution = now;  
        totalRewardsDistributed = 0;
        totalRewardsRedeemed = 0;
        minimumRewardWithdrawalLimit = 10 ether;  
        rewardAvailableCurrentDistribution = amountMintPerDuration;
        icoContractAddress = msg.sender;
    }

     
    function setIcoContractAddress(
        address _icoContractAddress
    ) external nonReentrant onlyOwner whenNotPaused {
        require (_icoContractAddress != address(0));
        emit IcoContractAddressSet(_icoContractAddress);
        icoContractAddress = _icoContractAddress;
    }

     
    function batchDistributeReward(
        address[] _rewardAdresses,
        uint256[] _amountOfReward,
        uint256 _timestampOfDistribution
    ) external nonReentrant onlyOwner whenNotPaused {
        require(_timestampOfDistribution > previousDistribution.add(durationBetweenRewardMints));  
        require(_timestampOfDistribution < now);  
        require(_rewardAdresses.length == _amountOfReward.length);  

        uint256 rewardDistributed = 0;

        for (uint j = 0; j < _rewardAdresses.length; j++) {
            rewardMint(_rewardAdresses[j], _amountOfReward[j]);
            rewardDistributed = rewardDistributed.add(_amountOfReward[j]);
        }
        require(rewardAvailableCurrentDistribution >= rewardDistributed);
        totalRewardsDistributed = totalRewardsDistributed.add(rewardDistributed);
        rewardAvailableCurrentDistribution = rewardAvailableCurrentDistribution.sub(rewardDistributed);
    }

     
    function distributeReward(
        address _rewardAddress,
        uint256 _amountOfReward,
        uint256 _timestampOfDistribution
    ) external nonReentrant onlyOwner whenNotPaused {

        require(_timestampOfDistribution > previousDistribution);
        require(_timestampOfDistribution < previousDistribution.add(durationBetweenRewardMints));  
        require(_timestampOfDistribution < now);  
         
        rewardMint(_rewardAddress, _amountOfReward);

    }

     
    function resetReward() external nonReentrant onlyOwner whenNotPaused {
        require(now > previousDistribution.add(durationBetweenRewardMints));  
        previousDistribution = previousDistribution.add(durationBetweenRewardMints);  
        rewardAvailableCurrentDistribution = amountMintPerDuration;
        emit ResetReward();
    }

     
    function redeemReward(
        address _beneficiary,
        uint256 _value
    ) external nonReentrant whenNotPaused{
         
        require(msg.sender == _beneficiary);
        require(_value >= minimumRewardWithdrawalLimit);
        require(reward[_beneficiary] >= _value);
        reward[_beneficiary] = reward[_beneficiary].sub(_value);
        balances[_beneficiary] = balances[_beneficiary].add(_value);
        totalRewardsRedeemed = totalRewardsRedeemed.add(_value);
        emit RedeemReward(_beneficiary, _value);
    }

    function rewardMint(
        address _to,
        uint256 _amount
    ) onlyOwner canMint whenNotPaused internal returns (bool) {
        require(_amount > 0);
        require(_to != address(0));
        require(rewardAvailableCurrentDistribution >= _amount);
        totalSupply_ = totalSupply_.add(_amount);
        reward[_to] = reward[_to].add(_amount);
        totalRewardsDistributed = totalRewardsDistributed.add(_amount);
        rewardAvailableCurrentDistribution = rewardAvailableCurrentDistribution.sub(_amount);
        emit RewardMint(_to, _amount);
         
        return true;
    }
    function userRewardAccountBalance(
        address _address
    ) whenNotPaused external view returns (uint256) {
        require(_address != address(0));
        return reward[_address];
    }
    function changeRewardMintingAmount(
        uint256 _newRewardMintAmt
    ) whenNotPaused nonReentrant onlyOwner external {
        require(_newRewardMintAmt < amountMintPerDuration);
        amountMintPerDuration = _newRewardMintAmt;
        emit RewardMintingAmt(_newRewardMintAmt);
    }

    function transferFrom(address _from, address _to, uint256 _value) external nonReentrant returns (bool) {
        return transferFromInternal(_from, _to, _value);
    }
    function approve(address _spender, uint256 _value) external nonReentrant returns (bool) {
        return approveInternal(_spender, _value);
    }
    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowanceInternal(_owner, _spender);
    }
    function increaseApproval(address _spender, uint _addedValue) external nonReentrant returns (bool) {
        return increaseApprovalInternal(_spender, _addedValue);
    }
    function decreaseApproval(address _spender, uint _subtractedValue) external nonReentrant returns (bool) {
        return decreaseApprovalInternal(_spender, _subtractedValue);
    }
    function transfer(address _to, uint256 _value) external nonReentrant returns (bool) {
        return transferInternal(_to, _value);
    }
}