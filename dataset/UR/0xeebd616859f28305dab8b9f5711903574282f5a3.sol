 

pragma solidity ^0.4.23;

 
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

 
contract ERC20StandardToken {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);

  mapping (address => mapping (address => uint256)) internal allowed;
  mapping (address => uint256) public balanceOf;
  
  using SafeMath for uint256;
  uint256 totalSupply_;

   
   
  function transferFrom(address _from,address _to,uint256 _value) public returns (bool)
  {
    require(_to != address(0));
    require(_value <= balanceOf[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balanceOf[_from] = balanceOf[_from].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balanceOf[msg.sender]);

    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }


   
  
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   

  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
 
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}



  

contract addtionalERC223Interface {
    function transfer(address to, uint256 value, bytes data) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

contract ERC223ReceivingContract { 
     
    
    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }
    
    function tokenFallback(address _from, uint256 _value, bytes _data) public pure
    {
        TKN memory tkn;
        tkn.sender = _from;
        tkn.value = _value;
        tkn.data = _data;
        uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
        tkn.sig = bytes4(u);        
    }
}


 
contract ERC223Token is addtionalERC223Interface , ERC20StandardToken {
 
    function _transfer(address _to, uint256 _value ) private returns (bool) {
        require(balanceOf[msg.sender] >= _value);
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        
        return true;
    }

    function _transferFallback(address _to, uint256 _value, bytes _data) private returns (bool) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        
        emit Transfer(msg.sender, _to, _value, _data);
        
        return true;
    }

     
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool OK) {
         
         
        if(isContract(_to))
        {
            return _transferFallback(_to,_value,_data);
        }else{
            _transfer(_to,_value);
            emit Transfer(msg.sender, _to, _value, _data);
        }
        
        return true;
    }
    
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        bytes memory empty;

        if(isContract(_to))
        {
            return _transferFallback(_to,_value,empty);
        }else{
            _transfer(_to,_value);
            emit Transfer(msg.sender, _to, _value);
        }
        
    }
    
     
    function isContract(address _addr) private view returns (bool) {
        uint length;
        assembly {
             
            length := extcodesize(_addr)
        }
        return (length > 0);
    }    
}


contract TowaCoin is ERC223Token
{
    string public name = "TOWACOIN";
    string public symbol = "TOWA";
    uint8 public decimals = 18;
    
    constructor() public{
	    address founder = 0x9F7d681707AA64fFdfBA162084932058bD34aBF4;
	    address developer = 0xE66EBB7Bd6E44413Ac1dE57ECe202c8F0CA1Efd9;
    
        uint256  dec = decimals;
        totalSupply_ = 200 * 1e8 * (10**dec);
        balanceOf[founder] = totalSupply_.mul(97).div(100);
        balanceOf[developer] = totalSupply_.mul(3).div(100);
    }
    
}