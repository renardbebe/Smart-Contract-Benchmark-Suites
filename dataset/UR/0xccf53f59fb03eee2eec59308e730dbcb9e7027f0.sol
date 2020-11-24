 

 
 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }
  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}
contract ERC223Interface {
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public ;
    function transfer(address to, uint value, bytes data) public ;
     
    event Transfer(address indexed from, address indexed to, uint value);  
}
contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}
contract EducationToken is ERC223Interface {
    
    using SafeMath for uint;
    
    string public constant name = "Education Token";
    string public constant symbol = "KEDU";
    uint8  public constant decimals = 18;
    
    uint256 public constant totalSupply =  2000 * (10 ** 6) * (10 ** 18);  
    uint256 public constant Million     =         (10 ** 6);
     
    
    address public constant contractOwner = 0x21bA616f20a14bc104615Cc955F818310E725aBA;
    
    mapping (address => uint256) balances;
    
    function EducationToken() {
        preAllocation();
    }
	function preAllocation() internal {
        balances[0x21bA616f20a14bc104615Cc955F818310E725aBA] =1400*(10**6)*(10**18);  
        balances[0x6F34740F96C76B4C228D8EFA5EC9C71205733102] =  60*(10**6)*(10**18);  
        balances[0x33fa06cD9A1451961890532bB3F2F2b6fB817976] =  60*(10**6)*(10**18);  
        balances[0x5d49508ab79A149663F036C9e1f820F2B78EC230] =  60*(10**6)*(10**18);  
        balances[0x45bC7Ac57f10b42133abf5a92861D4AA3C5EA3e8] =  60*(10**6)*(10**18);  
        balances[0xc157F7DcA6c101Cc2c63462d4E81bF5C335EFB49] =  60*(10**6)*(10**18);  
        balances[0x1306E082444370f11039b1eC19D85Bf3dF35Bb62] =  60*(10**6)*(10**18);  
        balances[0xC45E047cD81356d655D5c061311f62BBe2d2908C] =  60*(10**6)*(10**18);  
        balances[0x42b4B6BBb2619Afd619A56aeBa1533699c3A8e8d] =  60*(10**6)*(10**18);  
        balances[0xA8e5986C88556180Db85b3288CD10f383c1C04a6] =  60*(10**6)*(10**18);  
        balances[0xA6B60801869c732B75Ee980fC53458dAc75ebe7E] =  60*(10**6)*(10**18);  
	}
    function() payable {
        require(msg.value >= 0.00001 ether);
    }
    function getETH(uint256 _amount) public {
         
        require(msg.sender==contractOwner);
        msg.sender.transfer(_amount);
    }
    function nowSupply() constant public returns(uint){
        uint supply=totalSupply;
        supply=supply-balances[0x21bA616f20a14bc104615Cc955F818310E725aBA];
        supply=supply-balances[0x6F34740F96C76B4C228D8EFA5EC9C71205733102];
        supply=supply-balances[0x33fa06cD9A1451961890532bB3F2F2b6fB817976];
        supply=supply-balances[0x5d49508ab79A149663F036C9e1f820F2B78EC230];
        supply=supply-balances[0x45bC7Ac57f10b42133abf5a92861D4AA3C5EA3e8];
        supply=supply-balances[0xc157F7DcA6c101Cc2c63462d4E81bF5C335EFB49];
        supply=supply-balances[0x1306E082444370f11039b1eC19D85Bf3dF35Bb62];
        supply=supply-balances[0xC45E047cD81356d655D5c061311f62BBe2d2908C];
        supply=supply-balances[0x42b4B6BBb2619Afd619A56aeBa1533699c3A8e8d];
        supply=supply-balances[0xA8e5986C88556180Db85b3288CD10f383c1C04a6];
        supply=supply-balances[0xA6B60801869c732B75Ee980fC53458dAc75ebe7E];
        return supply;
    }
    
     
     
     
    function transfer(address _to, uint _value, bytes _data) public {
         
         
        uint codeLength;
        assembly {
             
            codeLength := extcodesize(_to)
        }

        require(_value > 0);
        require(balances[msg.sender] >= _value);
        require(balances[_to]+_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value);
    }
    function transfer(address _to, uint _value) public {
        uint codeLength;
        bytes memory empty;
        assembly {
             
            codeLength := extcodesize(_to)
        }

        require(_value > 0);
        require(balances[msg.sender] >= _value);
        require(balances[_to]+_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value);
    }
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
}