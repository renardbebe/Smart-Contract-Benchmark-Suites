 

pragma solidity ^0.4.17;



 
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


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
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


 

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract MetaToken is PausableToken {

    string public name = 'MetaMetaMeta! Token';
    uint8 public decimals = 8;
    string public symbol = 'M3T';
    string public version = '0.4.0';

    uint256 public blockReward = 1 * (10**uint256(decimals));
    uint32 public halvingInterval = 210000;
    uint256 public blockNumber = 0;  
    uint256 public totalSupply = 0;
    uint256 public target   = 0x0000ffff00000000000000000000000000000000000000000000000000000000;  
    uint256 public powLimit = 0x0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint40 public lastMinedOn;  
    uint256 public randomness;

    address public newContractAddress;

    function MetaToken() Ownable() {
        lastMinedOn = uint40(block.timestamp);
        updateRandomness();
    }

     
    function updateRandomness() internal {
        randomness = uint256(sha3(sha3(uint256(block.blockhash(block.number-1)) + uint256(block.coinbase) + uint256(block.timestamp))));
    }

     
    function getRamdomness() view returns (uint256 currentRandomness) {
        return randomness;
    }

     
    function hash(uint256 nonce, uint256 currentRandomness) pure returns (uint256){
        return uint256(sha3(nonce+currentRandomness));
    }

     
    function checkProofOfWork(uint256 nonce, uint256 currentRandomness, uint256 currentTarget) pure returns (bool workAccepted){
        return uint256(hash(nonce, currentRandomness)) < currentTarget;
    }

     
    function checkMine(uint256 nonce) view returns (bool success) {
        return checkProofOfWork(nonce, getRamdomness(), target);
    }

     
    function mine(uint256 nonce) whenNotPaused returns (bool success) {
        require(checkMine(nonce));

        Mine(msg.sender, blockReward, uint40(block.timestamp) - uint40(lastMinedOn));  

        balances[msg.sender] += blockReward;  
        blockNumber += 1;
        totalSupply += blockReward;  
        updateRandomness();

         
        var mul = (block.timestamp - lastMinedOn);
        if (mul > (60*2.5*2)) {
            mul = 60*2.5*2;
        }
        if (mul < (60*2.5/2)) {
            mul = 60*2.5/2;
        }
        target *= mul;
        target /= (60*2.5);

        if (target > powLimit) {  
            target = powLimit;
        }

        lastMinedOn = uint40(block.timestamp);  
        if (blockNumber % halvingInterval == 0) {  
            blockReward /= 2;
            RewardHalved();
        }

        return true;
    }

    function setNewContractAddress(address newAddress) onlyOwner {
        newContractAddress = newAddress;
    }

    event Mine(address indexed _miner, uint256 _reward, uint40 _seconds);
    event RewardHalved();
}