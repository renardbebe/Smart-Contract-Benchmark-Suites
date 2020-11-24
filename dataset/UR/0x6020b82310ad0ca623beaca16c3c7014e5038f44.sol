 

pragma solidity ^0.4.21;


 
contract SafeMath {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
     

    function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x > MAX_UINT256 - y) revert();
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x < y) revert();
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (y == 0) return 0;
        if (x > MAX_UINT256 / y) revert();
        return x * y;
    }

}


 
contract Ownable {
    address public owner;  
    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0)); 
        owner = newOwner;
    }
}
  
 

contract ERC223Interface {
    uint256 public totalSupply;

    function balanceOf(address who) public view returns (uint256);
  

    function transfer(address to, uint256 value, bytes data) public returns (bool ok);
    function transfer(address to, uint256 value, bytes data, string custom_fallback) public returns (bool ok);
  
    event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);
}


contract ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);
    
    function transfer(address to, uint256 value) public returns (bool ok);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success);
    function approve(address _spender, uint256 _value) public returns(bool success);
    function allowance(address _owner, address _spender) public constant returns(uint256 remaining);

}


contract ContractReceiver {
     
    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }
        
    function tokenFallback(address _from, uint256 _value, bytes _data) public pure {
        TKN memory tkn;
        tkn.sender = _from;
        tkn.value = _value;
        tkn.data = _data;
        uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
        tkn.sig = bytes4(u);
      
       
    }
}


contract StandardToken is ERC223Interface, ERC20Interface, SafeMath, ContractReceiver {
    mapping(address => uint) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        uint256 _allowance = allowed[_from][msg.sender];
     
     
    
        balances[_from] = safeSub(balanceOf(_from), _value); 
    
        balances[_to] = safeAdd(balanceOf(_to), _value);
        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

   
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
   

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
  }

     
  function increaseApproval (address _spender, uint256 _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = safeAdd(allowed[msg.sender][_spender],_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
   
  function decreaseApproval (address _spender, uint256 _subtractedValue) public returns (bool success) {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = safeSub(oldValue,_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  
  
   
    function transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) public returns (bool success) {
        if (isContract(_to)) {
            if (balanceOf(msg.sender) < _value) {  
                revert();
            }
            balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
            balances[_to] = safeAdd(balanceOf(_to), _value);
            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
            emit Transfer(msg.sender, _to, _value, _data);
            return true;
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }
  
   
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success) {
    
        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }
  
   
   
    function transfer(address _to, uint256 _value) public returns (bool success) {
      
     
     
        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        }
        else {
            return transferToAddress(_to, _value, empty);
        }
    }

   
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
             
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

   
    function transferToAddress(address _to, uint256 _value, bytes _data) private returns (bool) {
        
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
  
   
    function transferToContract(address _to, uint256 _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }
}


 
contract BurnableToken is StandardToken,Ownable {
    event Burn(address indexed burner, uint256 value);
     

    function burn(uint256 _value)  onlyOwner public  returns (bool) {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         
        address burner = msg.sender;
        balances[burner] = safeSub(balances[burner], _value);
        totalSupply = safeSub(totalSupply, _value);
        emit Burn(burner, _value);
        return true;
    }
}

 

contract MintableToken is BurnableToken {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

   
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        bytes memory empty;

        require ( _amount > 0);

         
         
        
        totalSupply = safeAdd(totalSupply, _amount);
        balances[_to] = safeAdd(balances[_to], _amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount, empty);
        return true;
    }

   
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}


contract EMIToken is StandardToken, MintableToken {
    string public name = "EMITOKEN";
    string public symbol = "EMI";
    uint8 public decimals = 8;
    uint256 public initialSupply = 600000000 * (10 ** uint256(decimals));
    function EMIToken() public{

        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;  

        emit Transfer(0x0, msg.sender, initialSupply);
    }
}