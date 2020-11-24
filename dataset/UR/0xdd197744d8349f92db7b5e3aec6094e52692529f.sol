 

 

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

  contract ERC20 {
  function totalSupply()public view returns (uint total_Supply);
  function balanceOf(address _owner)public view returns (uint256 balance);
  function allowance(address _owner, address _spender)public view returns (uint remaining);
  function transferFrom(address _from, address _to, uint _amount)public returns (bool ok);
  function approve(address _spender, uint _amount)public returns (bool ok);
  function transfer(address _to, uint _amount)public returns (bool ok);
  event Transfer(address indexed _from, address indexed _to, uint _amount);
  event Approval(address indexed _owner, address indexed _spender, uint _amount);
}

contract ERBIUM is ERC20
{
    using SafeMath for uint256;
    string public constant symbol = "ERB";
    string public constant name = "Erbium";
    uint8 public constant decimals = 10;
     
    uint256 public _totalSupply = 10000000 * 10 **10;      
     
    mapping(address => uint256) balances;   
     
    address public owner;
    
    mapping (address => mapping (address => uint)) allowed;
    
    uint256 public supply_increased;
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    event LOG(string e,uint256 value);
    
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
    
    function ERBIUM() public
    {
        owner = msg.sender;
        balances[owner] = 2000000 * 10 **10;  
    
        supply_increased += balances[owner];
    }
    
     
    
    function () public payable {
  
    }

     
    function mineToken(uint256 supply_to_increase) public onlyOwner
    {
        require((supply_increased + supply_to_increase) <= _totalSupply);
        supply_increased += supply_to_increase;
        
        balances[owner] += supply_to_increase;
        Transfer(0, owner, supply_to_increase);
    }
    
    
     
    function totalSupply() public view returns (uint256 total_Supply) {
        total_Supply = _totalSupply;
    }
  
     
    function balanceOf(address _owner)public view returns (uint256 balance) {
        return balances[_owner];
    }
  
     
    function transfer(address _to, uint256 _amount)public returns (bool success) {
        require( _to != 0x0);
        require(balances[msg.sender] >= _amount 
            && _amount >= 0
            && balances[_to] + _amount >= balances[_to]);
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(msg.sender, _to, _amount);
            return true;
    }
  
     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )public returns (bool success) {
        require(_to != 0x0); 
        require(balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount >= 0
            && balances[_to] + _amount >= balances[_to]);
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(_from, _to, _amount);
            return true;
            }

     
     
    function approve(address _spender, uint256 _amount)public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
  
    function allowance(address _owner, address _spender)public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
  }
  
     
  function transferOwnership(address newOwner)public onlyOwner
  {
      require( newOwner != 0x0);
      balances[newOwner] = balances[newOwner].add(balances[owner]);
      balances[owner] = 0;
      owner = newOwner;
  }
  
   
  function drain() external onlyOwner {
        owner.transfer(this.balance);
    }
    
     
    function kill() external onlyOwner {
        selfdestruct(address(uint160(owner)));
    }    
    
     
  function stringToUint(string s) private pure returns (uint) 
    {
        bytes memory b = bytes(s);
        uint i;
        uint result1 = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if(c == 46)
            {
                 
            }
          else if (c >= 48 && c <= 57) {
                result1 = result1 * 10 + (c - 48);
               
                
            }
        }
            return result1;
      }
    
}