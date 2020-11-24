 

pragma solidity 0.4.18;



 
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

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

contract NamCoin is StandardToken, Ownable {
    string public name = "Nam Coin";  
    string public symbol = "NAM";  
    uint8 public constant decimals = 18;  
    uint256 public unitsOneEthCanBuy = 120048;      
    uint256 public totalEthInWei;          
    address public fundsWallet;  
    uint public constant crowdsaleSupply = 60 * (uint(10)**9) * (uint(10)**decimals);  
    uint public constant tokenContractSupply = 60 * (uint(10)**9) * (uint(10)**decimals);  

     
    function setUnitsOneEthCanBuy(uint256 new_unitsOneEthCanBuy) public onlyOwner
    {
        unitsOneEthCanBuy = new_unitsOneEthCanBuy;
    }
    
     
    function issueTokens(address _to, uint256 _amount) public onlyOwner
    {
        require(_to != 0x0);
        this.transfer(_to, _amount);
    }
    
     
     
    function transferCollectedEther(address _to) public onlyOwner
    {
        require(_to != 0x0);
        require(!crowdsaleRunning);
        _to.transfer(this.balance);
    }
    
    bool public crowdsaleRunning = false;
    uint256 public crowdsaleStartTimestamp;
    uint256 public crowdsaleDuration = 60 * 24*60*60;  
    
    function startCrowdsale() public onlyOwner
    {
        crowdsaleRunning = true;
        crowdsaleStartTimestamp = now;
    }
    
    function stopCrowdsale() public onlyOwner
    {
        crowdsaleRunning = false;
    }
    
     
    uint256 public purchaseGold = 10 * (uint(10)**6) * (uint(10)**decimals);
    uint256 public purchaseSilver = 5 * (uint(10)**6) * (uint(10)**decimals);
    uint256 public purchaseBronze = 3 * (uint(10)**6) * (uint(10)**decimals);
    uint256 public purchaseCoffee = 1 * (uint(10)**6) * (uint(10)**decimals);

    function NamCoin(address _fundsWallet) public {
        fundsWallet = _fundsWallet;
        
        totalSupply_ = crowdsaleSupply + tokenContractSupply;
        
        balances[fundsWallet] = crowdsaleSupply;
        Transfer(0x0, fundsWallet, crowdsaleSupply);
        
        balances[this] = tokenContractSupply;
        Transfer(0x0, this, tokenContractSupply);
    }

    function() payable public {
         
        require(crowdsaleRunning);
        
         
        require(now <= crowdsaleStartTimestamp + crowdsaleDuration);
        
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy * (uint(10)**decimals) / (1 ether);
        
         
        if (amount >= purchaseGold) {
            amount = amount.mul(120).div(100);  

        }else if (amount >= purchaseSilver) {
            amount = amount.mul(115).div(100);

        }else if (amount >= purchaseBronze) {
            amount = amount.mul(110).div(100);

        }else if (amount >= purchaseCoffee) {
            amount = amount.mul(103).div(100);

        }else {
            amount = amount.mul(100).div(100);
        }
        
         
       require (balances[fundsWallet] >= amount);

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        Transfer(fundsWallet, msg.sender, amount);  
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)  public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}