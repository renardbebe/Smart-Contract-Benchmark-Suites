 

pragma solidity ^0.4.19;

contract Ownable {
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));      
    owner = newOwner;
  }
}

library AddressUtils {
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}

interface ERC165ReceiverInterface {
  function tokensReceived(address _from, address _to, uint _amount, bytes _data) external returns (bool);
}

contract supportERC165Basic {
  bytes4 constant InvalidID = 0xffffffff;
  bytes4 constant ERC165ID = 0x01ffc9a7;
	
  function transfer_erc165(address to, uint256 value, bytes _data) public returns (bool);

  function doesContractImplementInterface(address _contract, bytes4 _interfaceId) internal view returns (bool) {
      uint256 success;
      uint256 result;

      (success, result) = noThrowCall(_contract, ERC165ID);
      if ((success==0)||(result==0)) {
          return false;
      }
  
      (success, result) = noThrowCall(_contract, InvalidID);
      if ((success==0)||(result!=0)) {
          return false;
      }

      (success, result) = noThrowCall(_contract, _interfaceId);
      if ((success==1)&&(result==1)) {
          return true;
      }
      return false;
  }

  function noThrowCall(address _contract, bytes4 _interfaceId) constant internal returns (uint256 success, uint256 result) {
      bytes4 erc165ID = ERC165ID;

      assembly {
              let x := mload(0x40)                
              mstore(x, erc165ID)                 
              mstore(add(x, 0x04), _interfaceId)  

              success := staticcall(
                                  30000,          
                                  _contract,      
                                  x,              
                                  0x20,           
                                  x,              
                                  0x20)           

              result := mload(x)                  
      }
  }	
}
 

contract ERC20Basic is supportERC165Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  using AddressUtils for address;

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
  }
    
   
  function transfer_erc165(address _to, uint256 _value, bytes _data) public returns (bool) {
    transfer(_to, _value);
      
    if (!_to.isContract()) revert();
    
    ERC165ReceiverInterface i;
    if(!doesContractImplementInterface(_to, i.tokensReceived.selector)) revert(); 

    ERC165ReceiverInterface app= ERC165ReceiverInterface(_to);
    app.tokensReceived(msg.sender, _to, _value, _data);
    
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract RoboAiCoin is StandardToken, Ownable {

  string public name = "RoboAi Coin";
  string public symbol = "R2R";
  uint public decimals = 8;
    
  function RoboAiCoin() public {
    owner = msg.sender;
    totalSupply_ = 0;
    
    totalSupply_= 1 * 10 ** (9+8);   

    balances[owner] = totalSupply_;
	Transfer(address(0), owner, balances[owner]);
  }
}