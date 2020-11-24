 

pragma solidity 0.4.18;

 
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

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
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

contract YUPToken is Ownable, StandardToken, CanReclaimToken, Pausable {
    using SafeMath for uint256;
    
     

    
     
    string public constant name = "YUP";
    string public constant symbol = "YUP";
    uint256 public constant decimals = 18;
    address public timelockVault;
    address public bountyFund;
    address public seedFund;
    address public reserveFund;
    address public vestingVault;
    uint256 constant D160 = 0x0010000000000000000000000000000000000000000;
    bool public finalized;
    
    event IsFinalized(uint256 _time);    
    
     
    modifier isFinalized() {
        require(finalized == true);
        _;
    }
    
    modifier notFinalized() {
        require(finalized == false);
        _;
    }
    
     
    function YUPToken(
        address _timelockVault,
        address _bountyFund,
        address _seedFund,
        address _reserveFund,
        address _vestingVault
    ) public {
        totalSupply_ = 445 * (10**6) * (10**decimals);   
        timelockVault = _timelockVault;
        bountyFund = _bountyFund;
        seedFund = _seedFund;
        reserveFund = _reserveFund;
        vestingVault = _vestingVault;
        finalized = false;
        
         
        
        balances[timelockVault] = 193991920000000000000000000;       
        Transfer(0x0, address(timelockVault), 193991920000000000000000000);
        
        balances[bountyFund] = totalSupply_.div(100);                
        Transfer(0x0, address(bountyFund), totalSupply_.div(100));
        
        balances[seedFund] = totalSupply_.div(100).mul(5);           
        Transfer(0x0, address(seedFund), totalSupply_.div(100).mul(5));
        
        balances[reserveFund] = totalSupply_.div(100).mul(10);       
        Transfer(0x0, address(reserveFund), totalSupply_.div(100).mul(10));
        
        balances[vestingVault] = totalSupply_.div(100).mul(20);      
        Transfer(0x0, address(vestingVault), totalSupply_.div(100).mul(20));
    }
    
     
    function transfer(address _to, uint256 _value) public whenNotPaused isFinalized returns (bool) {
        return super.transfer(_to, _value);
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused isFinalized returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
    
     
    function finalize() public notFinalized onlyOwner {
        finalized = true;
        IsFinalized(now);
    }
    
     
    function loadBalances(uint256[] data) public notFinalized onlyOwner {
        for (uint256 i = 0; i < data.length; i++) {
            address addr = address(data[i] & (D160 - 1));
            uint256 amount = data[i] / D160;
            
            balances[addr] = amount;
            Transfer(0x0, addr, amount);
        }
    }
}