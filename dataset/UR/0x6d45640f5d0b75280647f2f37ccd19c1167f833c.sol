 

pragma solidity ^0.5.11;
    
    
    
    
    
    
   
  contract ERC20Interface {
       
      function totalSupply() external view returns (uint256);
   
       
      function balanceOf(address _owner) external view returns (uint256);
   
       
      function transfer(address _to, uint256 _value) external returns (bool);
   
       
      function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
   
       
       
       
      function approve(address _spender, uint256 _value) external returns (bool);
   
       
      function allowance(address _owner, address _spender) external view returns (uint256);
   
       
      event Transfer(address indexed _from, address indexed _to, uint256 _value);
   
       
      event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  }
     
  contract FLExToken is ERC20Interface {

      string public constant symbol = "FLEx";
      string public constant name = "FLEx token";
      uint8 public constant decimals = 4;            
      
      uint256 private _totalSupply = 10*10**9*10**4;               

      using SafeMath for uint;
      
       
      address public owner;
   
       
      mapping(address => uint256) balances;
   
       
      mapping(address => mapping (address => uint256)) allowed;
   
       
      modifier onlyOwner() {
          if (msg.sender != owner) {
              revert();
          }
          _;
      } 
      
      constructor() public {        
         
        owner = 0x14387E6A7E79d28340fd78Ea3ac2243F4f511CAD;
        balances[owner] = _totalSupply;
      } 
   
      function totalSupply() public view returns (uint256) {
        return _totalSupply;
      }
   
       
      function balanceOf(address _owner) view public returns (uint256 balance) {
          return balances[_owner];
      }
   
       
      function transfer(address _to, uint256 _amount) public returns (bool success) {          
        
          if (balances[msg.sender] >= _amount 
              && _amount > 0
              && balances[_to] + _amount > balances[_to]) {
              balances[msg.sender] -= _amount;
              balances[_to] += _amount;
              emit Transfer(msg.sender, _to, _amount);
              return true;
          } else {
              return false;
          }
      }
   
       
       
       
       
       
       
      function transferFrom(
          address _from,
          address _to,
          uint256 _amount
      ) public returns (bool success) {         

         if (balances[_from] >= _amount
             && allowed[_from][msg.sender] >= _amount
             && _amount > 0
             && balances[_to] + _amount > balances[_to]) {
             balances[_from] -= _amount;
             allowed[_from][msg.sender] -= _amount;
             balances[_to] += _amount;
             emit Transfer(_from, _to, _amount);
             return true;
         } else {
             return false;
         }
     }
  
      
      
     function approve(address _spender, uint256 _amount) public returns (bool success) {
         allowed[msg.sender][_spender] = _amount;
         emit Approval(msg.sender, _spender, _amount);
         return true;
     }
  
     function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
         return allowed[_owner][_spender];
     }

     function TransferOwnership(address newOwner) onlyOwner public
    {
      owner = newOwner;
    }

 }

   
  library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
      uint c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
      
      uint c = a / b;      
      return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
      assert(b <= a);
      return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
      uint c = a + b;
      require(c >= a);
      return c;
    }
    
  }