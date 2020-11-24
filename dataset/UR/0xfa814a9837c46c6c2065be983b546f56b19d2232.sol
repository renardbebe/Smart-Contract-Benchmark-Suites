 

pragma solidity ^0.4.18;


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract Ownable {
  address public owner;                                                      
  address public masterOwner = 0xe4925C73851490401b858B657F26E62e9aD20F66;   

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public {
    require(newOwner != address(0));
    require(masterOwner == msg.sender);  
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
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

  function cei(uint256 a, uint256 b) internal pure returns (uint256) {
    return ((a + b - 1) / b) * b;
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


 
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract VZToken is StandardToken, Ownable {


     

    string public constant name = "VectorZilla Token";  
    string public constant symbol = "VZT";  
    string public constant version = "1.0";  
    uint8 public constant decimals = 18;  

     

    uint256 public constant INITIAL_SUPPLY = 100000000 * 10 ** 18;  
    uint256 public constant BURNABLE_UP_TO =  90000000 * 10 ** 18;  
    uint256 public constant VECTORZILLA_RESERVE_VZT = 25000000 * 10 ** 18;  

     
    address public constant VECTORZILLA_RESERVE = 0xF63e65c57024886cCa65985ca6E2FB38df95dA11;

     
    address public tokenSaleContract;

     
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);


     

    modifier onlyOwnerAndContract() {
        require(msg.sender == owner || msg.sender == tokenSaleContract);
        _;
    }


    modifier onlyWhenValidAddress( address _addr ) {
        require(_addr != address(0x0));
        _;
    }

    modifier onlyWhenValidContractAddress(address _addr) {
        require(_addr != address(0x0));
        require(_addr != address(this));
        require(isContract(_addr));
        _;
    }

    modifier onlyWhenBurnable(uint256 _value) {
        require(totalSupply - _value >= INITIAL_SUPPLY - BURNABLE_UP_TO);
        _;
    }

    modifier onlyWhenNotFrozen(address _addr) {
        require(!frozenAccount[_addr]);
        _;
    }

     

     

    event Burn(address indexed burner, uint256 value);
    event Finalized();
     
    event Withdraw(address indexed from, address indexed to, uint256 value);

     
    function VZToken(address _owner) public {
        require(_owner != address(0));
        totalSupply = INITIAL_SUPPLY;
        balances[_owner] = INITIAL_SUPPLY - VECTORZILLA_RESERVE_VZT;  
        balances[VECTORZILLA_RESERVE] = VECTORZILLA_RESERVE_VZT;  
        owner = _owner;
    }

     
    function () payable public onlyOwner {}

     
    function transfer(address _to, uint256 _value) 
        public
        onlyWhenValidAddress(_to)
        onlyWhenNotFrozen(msg.sender)
        onlyWhenNotFrozen(_to)
        returns(bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) 
        public
        onlyWhenValidAddress(_to)
        onlyWhenValidAddress(_from)
        onlyWhenNotFrozen(_from)
        onlyWhenNotFrozen(_to)
        returns(bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
    function burn(uint256 _value)
        public
        onlyWhenBurnable(_value)
        onlyWhenNotFrozen(msg.sender)
        returns (bool) {
        require(_value <= balances[msg.sender]);
       
       
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
        Transfer(burner, address(0x0), _value);
        return true;
      }

     
    function burnFrom(address _from, uint256 _value) 
        public
        onlyWhenBurnable(_value)
        onlyWhenNotFrozen(_from)
        onlyWhenNotFrozen(msg.sender)
        returns (bool success) {
        assert(transferFrom( _from, msg.sender, _value ));
        return burn(_value);
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        onlyWhenValidAddress(_spender)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function freezeAccount(address target, bool freeze) external onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

     
    function withdrawToOwner(uint256 weiAmt) public onlyOwner {
         
        require(weiAmt > 0);
        owner.transfer(weiAmt);
         
        Withdraw(this, msg.sender, weiAmt);
    }


     
     
     
     
    function claimTokens(address _token) external onlyOwner {
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }
        StandardToken token = StandardToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(owner, balance);
         
        Withdraw(this, owner, balance);
    }

    function setTokenSaleContract(address _tokenSaleContract)
        external
        onlyWhenValidContractAddress(_tokenSaleContract)
        onlyOwner {
           require(_tokenSaleContract != tokenSaleContract);
           tokenSaleContract = _tokenSaleContract;
    }

     
     
     
    function isContract(address _addr) constant internal returns(bool) {
        if (_addr == 0) {
            return false;
        }
        uint256 size;
        assembly {
            size: = extcodesize(_addr)
        }
        return (size > 0);
    }

     
    function sendToken(address _to, uint256 _value)
        public
        onlyWhenValidAddress(_to)
        onlyOwnerAndContract
        returns(bool) {
        address _from = owner;
         
        require(balances[_from] >= _value);
         
        require(balances[_to] + _value > balances[_to]);
         
        uint256 previousBalances = balances[_from] + balances[_to];
         
        balances[_from] -= _value;
         
        balances[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balances[_from] + balances[_to] == previousBalances);
        return true;
    }
     
    function batchSendTokens(address[] addresses, uint256[] _values) 
        public onlyOwnerAndContract
        returns (bool) {
        require(addresses.length == _values.length);
        require(addresses.length <= 20);  
        uint i = 0;
        uint len = addresses.length;
        for (;i < len; i++) {
            sendToken(addresses[i], _values[i]);
        }
        return true;
    }
}