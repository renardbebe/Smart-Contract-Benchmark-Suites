 

pragma solidity 0.4.24;
 
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


 contract ContractReceiver{
    function tokenFallback(address _from, uint256 _value, bytes  _data) external;
}


 
 
contract ERC23BasicToken  {
    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

    function tokenFallback(address _from, uint256 _value, bytes  _data) external {
        throw;
    }

    function transfer(address _to, uint256 _value, bytes _data) returns  (bool success) {
        require(_to != address(0));
         

        if(isContract(_to)) {
            transferToContract(_to, _value, _data);
        }
        else {
            transferToAddress(_to, _value, _data);
        }
        return true;
    }

    function transfer(address _to, uint256 _value) {
        require(_to != address(0));
         
         

        bytes memory empty;
        if(isContract(_to)) {
            transferToContract(_to, _value, empty);
        }
        else {
            transferToAddress(_to, _value, empty);
        }
    }

    function transferToAddress(address _to, uint256 _value, bytes _data) internal {
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
    }

    function transferToContract(address _to, uint256 _value, bytes _data) internal {
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub( _value);
        balances[_to] = balances[_to].add( _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function isContract(address _addr) returns (bool is_contract) {
          uint256 length;
          assembly {
               
              length := extcodesize(_addr)
          }
          if(length>0) {
              return true;
          }
          else {
              return false;
          }
    }
}


  
  
contract ERC23StandardToken is ERC23BasicToken {
    mapping (address => mapping (address => uint256)) allowed;
    event Approval (address indexed owner, address indexed spender, uint256 value);

    function transferFrom(address _from, address _to, uint256 _value) {
    require (_value > 0);
    require(_to != address(0));
    require(_from != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) {

         
         
         
         
        require (_value > 0);
        require(_spender != address(0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}
 
contract Ownable {
  address public owner;
  address public admin;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
  function Ownable() public {
    owner = msg.sender;
    admin=owner;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner || msg.sender==admin);
    _;
  }
   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  
   
  function transferAdmin(address newAdmin) onlyOwner public {
    require(newAdmin != address(0));
    emit OwnershipTransferred(admin, newAdmin);
    admin = newAdmin;
  }
  
}

 
contract MintableToken is ERC23StandardToken,Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  bool public mintingFinished = false;
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(_amount>0);
    require(_to != address(0));

    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(0x0, _to, _amount);
    return true;
  }
   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


contract ANSAToken is MintableToken { 
  string public name="ANSA TOKEN";
  string public symbol="ANSA";
  uint8 public decimals=18;
  uint256 public tradeStartTime;

  function tradeStarttime(uint256 _startTime)public onlyOwner{
       tradeStartTime=_startTime.add(1 years);
   }
   
   function hasTrade() public view returns (bool) {
     
    return block.timestamp>tradeStartTime;
  }
   function transfer(address _to,uint256 _value) public{
       require(hasTrade());
       require(_to != address(0));

         
         

        bytes memory empty;
        if(isContract(_to)) {
             transferToContract(_to, _value, empty);
        }
        else {
            transferToAddress(_to, _value, empty);
        }
    }
    
     function transfer(address _to, uint256 _value, bytes _data)public  returns (bool success)  {
        require(hasTrade());
         
        require(_to != address(0));

        if(isContract(_to)) {
            transferToContract(_to, _value, _data);
        }
        else {
            transferToAddress(_to, _value, _data);
        }
        return true;
    }
 
 function transferFrom(address _from, address _to, uint256 _value) {
    require(hasTrade());
    require (_value > 0);
    require(_to != address(0));
    require(_from != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    }
}