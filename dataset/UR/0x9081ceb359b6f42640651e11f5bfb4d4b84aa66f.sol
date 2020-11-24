 

pragma solidity ^0.4.21;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

}

 
contract PartialBasic is StandardToken {
  using SafeMath for uint256;

  string public constant name = "Partial Basic";  
  string public constant symbol = "PB";  
  uint8 public constant decimals = 18;  

  uint256 public constant BASE_REWARD = 20000 ether;
  uint256 private constant PRECISION = 10**18;

  uint256 public totalNodes;
  uint256 public rewardStartTime;
  uint256 public rewardCheckpoint;
  uint256 private rewardTimestamp;

  mapping(address => uint256) public nodes;
  mapping(address => uint256) private claimed;

  event Mint(address indexed to, uint256 amount);
  event AddNode(address indexed owner);

   
  function addNode(address _owner) external {
    uint256 checkpointCandidate;

    if (rewardStartTime == 0) {
       
      rewardStartTime = block.timestamp;
    } else {
       
       
      checkpointCandidate = rewardPerNode();
      require(checkpointCandidate > rewardCheckpoint || block.timestamp == rewardTimestamp);
    }

     
    sync(_owner);

    if (rewardCheckpoint != checkpointCandidate) {
       
      rewardCheckpoint = checkpointCandidate;
    }

    if (rewardTimestamp != block.timestamp) {
       
      rewardTimestamp = block.timestamp;
    }

     
    nodes[_owner] = nodes[_owner].add(1);

     
    claimed[_owner] = rewardCheckpoint.mul(nodes[_owner]);

     
    totalNodes = totalNodes.add(1);

     
    emit AddNode(_owner);
  }

   
  function rewardPerNode() public view returns (uint256) {
     
    if (totalNodes == 0) {
      return;
    }

     
    uint256 totalDays = block.timestamp.sub(rewardTimestamp).mul(PRECISION).div(1 days);

     
    uint256 newReward = BASE_REWARD.mul(totalDays).div(PRECISION).div(totalNodes);

     
    return rewardCheckpoint.add(newReward);
  }

   
  function calculateReward(address _owner) public view returns (uint256) {
     
    if (isMining(_owner)) {
       
      uint256 reward = rewardPerNode().mul(nodes[_owner]);
      return reward.sub(claimed[_owner]);
    }
  }

   
  function sync(address _owner) public {
    uint256 reward = calculateReward(_owner);
    if (reward > 0) {
      claimed[_owner] = claimed[_owner].add(reward);
      balances[_owner] = balances[_owner].add(reward);
      emit Mint(_owner, reward);
      emit Transfer(address(0), _owner, reward);
    }
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    sync(msg.sender);
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    sync(_from);
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner].add(calculateReward(_owner));
  }

   
  function totalSupply() public view returns (uint256) {
    if (rewardStartTime == 0) {
      return;
    }

     
    uint256 totalDays = block.timestamp.sub(rewardStartTime).mul(PRECISION).div(1 days);

     
    return BASE_REWARD.mul(totalDays).div(PRECISION);
  }

   
  function isMining(address _owner) public view returns (bool) {
    return nodes[_owner] != 0;
  }

   
  function getInfo(address _owner) public view returns (bool, uint256, uint256, uint256, uint256, uint256, uint256) {
    return (isMining(_owner), nodes[_owner], balanceOf(_owner), calculateReward(_owner), rewardPerNode(), totalNodes, totalSupply());
  }

}