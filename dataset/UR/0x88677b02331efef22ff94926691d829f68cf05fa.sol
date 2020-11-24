 

pragma solidity ^0.4.13;

 
 
 

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



contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract Pausable is Ownable {
    using SafeMath for uint256;

    event Pause();
    event Unpause();

    bool public paused = false;
 

    modifier whenNotPaused() {
        require(!paused || msg.sender == address(this));
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public {
        require(msg.sender != address(0));
        paused = true;
        Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        require(msg.sender != address(0));
        paused = false;
        Unpause();
    }
}



contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;
  event Burn(address indexed burner, uint256 value);

   
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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         
    
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

}

contract PausableToken is StandardToken, Pausable {
  using SafeMath for uint256;
   

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint256 _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint256 _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
}


}
contract PotToken is PausableToken {

    using SafeMath for uint256;
    address owner = msg.sender;
    bool public stop = false;
    uint256 public totalContribution = 0;
    uint256 public constant fundingStartTime = 1522587600;                            
    uint256 public constant fundingEndTime = 5404107600;                             
    uint256 public constant tokensPerEthPrice = 200;                                  
    
    function name() public pure returns (string) { return "Decentralized Coffee Pot Control Protocol"; }
    function symbol() public pure returns (string) { return "DCPCP"; }
    function decimals() public  pure  returns (uint8) { return 18; }
    
    function balanceOf(address _owner) public constant returns (uint256) { return balances[_owner]; }

    
    function getStats() public constant returns (uint256, uint256) { 
        return (totalContribution, totalSupply);
    }
    
    
    function stopIt() public onlyOwner returns (bool) {
        require(!stop);
        stop = true;
        return true;
    }
        
    
    function() external payable {
        require(!(msg.value == 0)
        && (!stop)
        && (now >= fundingStartTime)
        && (now <= fundingEndTime));
        uint256 rewardTransferAmount = 0;
      
        totalContribution =  (totalContribution.add(msg.value));
        rewardTransferAmount = (msg.value.mul(tokensPerEthPrice));
        totalSupply = (totalSupply.add(rewardTransferAmount));
        balances[msg.sender] = (balances[msg.sender].add(rewardTransferAmount));
        owner.transfer(msg.value);
        
        Transfer(address(this), msg.sender, rewardTransferAmount);
    }
}