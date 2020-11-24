 

pragma solidity ^0.4.24;

 

contract LibUserInfo {
  struct Following {
    address leader;
    uint percentage;  
    uint index;
  }
}

 

 
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

 

contract ISocialTrading is Ownable {

   
  function follow(address _leader, uint256 _percentage) external;

   
  function unfollow(address _leader) external;

   
  function getFriends(address _user) public view returns (address[]);

   
  function getFollowers(address _user) public view returns (address[]);
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

contract SocialTrading is ISocialTrading {
  ERC20 public feeToken;
  address public feeWallet;

  mapping(address => mapping(address => LibUserInfo.Following)) public followerToLeaders;  
  mapping(address => address[]) public followerToLeadersIndex;  
  mapping(address => mapping(address => uint8)) public leaderToFollowers;
  mapping(address => address[]) public leaderToFollowersIndex;  

  mapping(address => bool) public relays;

  event Follow(address indexed leader, address indexed follower, uint percentage);
  event UnFollow(address indexed leader, address indexed follower);
  event AddRelay(address indexed relay);
  event RemoveRelay(address indexed relay);
  event PaidReward(
    address indexed leader,
    address indexed follower,
    address indexed relay,
    uint rewardAndFee,
    bytes32 leaderOpenOrderHash,
    bytes32 leaderCloseOrderHash,
    bytes32 followerOpenOrderHash,
    bytes32 followercloseOrderHash
  );

  constructor (
    address _feeWallet,
    ERC20 _feeToken
  ) public
  {
    feeWallet = _feeWallet;
    feeToken = _feeToken;
  }

  function() public {
    revert();
  }

   
  function follow(address _leader, uint256 _percentage) external {
    require(getCurrentPercentage(msg.sender) + _percentage <= 100 ether, "Following percentage more than 100%.");
    uint8 index = uint8(followerToLeadersIndex[msg.sender].push(_leader) - 1);
    followerToLeaders[msg.sender][_leader] = LibUserInfo.Following(
      _leader,
      _percentage,
      index
    );

    uint8 index2 = uint8(leaderToFollowersIndex[_leader].push(msg.sender) - 1);
    leaderToFollowers[_leader][msg.sender] = index2;
    emit Follow(_leader, msg.sender, _percentage);
  }

   
  function unfollow(address _leader) external {
    _unfollow(msg.sender, _leader);
  }

  function _unfollow(address _follower, address _leader) private {
    uint8 rowToDelete = uint8(followerToLeaders[_follower][_leader].index);
    address keyToMove = followerToLeadersIndex[_follower][followerToLeadersIndex[_follower].length - 1];
    followerToLeadersIndex[_follower][rowToDelete] = keyToMove;
    followerToLeaders[_follower][keyToMove].index = rowToDelete;
    followerToLeadersIndex[_follower].length -= 1;

    uint8 rowToDelete2 = uint8(leaderToFollowers[_leader][_follower]);
    address keyToMove2 = leaderToFollowersIndex[_leader][leaderToFollowersIndex[_leader].length - 1];
    leaderToFollowersIndex[_leader][rowToDelete2] = keyToMove2;
    leaderToFollowers[_leader][keyToMove2] = rowToDelete2;
    leaderToFollowersIndex[_leader].length -= 1;
    emit UnFollow(_leader, _follower);
  }

  function getFriends(address _user) public view returns (address[]) {
    address[] memory result = new address[](followerToLeadersIndex[_user].length);
    uint counter = 0;
    for (uint i = 0; i < followerToLeadersIndex[_user].length; i++) {
      result[counter] = followerToLeadersIndex[_user][i];
      counter++;
    }
    return result;
  }

  function getFollowers(address _user) public view returns (address[]) {
    address[] memory result = new address[](leaderToFollowersIndex[_user].length);
    uint counter = 0;
    for (uint i = 0; i < leaderToFollowersIndex[_user].length; i++) {
      result[counter] = leaderToFollowersIndex[_user][i];
      counter++;
    }
    return result;
  }

  function getCurrentPercentage(address _user) internal view returns (uint) {
    uint sum = 0;
    for (uint i = 0; i < followerToLeadersIndex[_user].length; i++) {
      address leader = followerToLeadersIndex[_user][i];
      sum += followerToLeaders[_user][leader].percentage;
    }
    return sum;
  }

   
  function registerRelay(address _relay) onlyOwner external {
    relays[_relay] = true;
    emit AddRelay(_relay);
  }

   
  function removeRelay(address _relay) onlyOwner external {
    relays[_relay] = false;
    emit RemoveRelay(_relay);
  }

  function distributeReward(
    address _leader,
    address _follower,
    uint _reward,
    uint _relayFee,
    bytes32[4] _orderHashes
  ) external
  {
     
     
     
     
    address relay = msg.sender;
    require(relays[relay]);
     
    uint256 allowance = feeToken.allowance(_follower, address(this));
    uint256 balance = feeToken.balanceOf(_follower);
    uint rewardAndFee = _reward + _relayFee;
    if ((balance >= rewardAndFee) && (allowance >= rewardAndFee)) {
      feeToken.transferFrom(_follower, _leader, _reward);
      feeToken.transferFrom(_follower, relay, _relayFee);
      emit PaidReward(
        _leader,
        _follower,
        relay,
        rewardAndFee,
        _orderHashes[0],
        _orderHashes[1],
        _orderHashes[2],
        _orderHashes[3]
      );
    } else {
      _unfollow(_follower, _leader);
    }
  }
}