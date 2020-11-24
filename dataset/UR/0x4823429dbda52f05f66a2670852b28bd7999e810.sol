 

pragma solidity ^0.4.18;


 

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }
    
     
    function toSlice(string self) internal pure returns (slice) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }
    
     
    function empty(slice self) internal pure returns (bool) {
        return self._len == 0;
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


 
contract ERC827 is ERC20 {

  function approve( address _spender, uint256 _value, bytes _data ) public returns (bool);
  function transfer( address _to, uint256 _value, bytes _data ) public returns (bool);
  function transferFrom( address _from, address _to, uint256 _value, bytes _data ) public returns (bool);

}


 
contract ERC827Token is ERC827, StandardToken {

   
  function approve(address _spender, uint256 _value, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.approve(_spender, _value);

    require(_spender.call(_data));

    return true;
  }

   
  function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transfer(_to, _value);

    require(_to.call(_data));
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transferFrom(_from, _to, _value);

    require(_to.call(_data));
    return true;
  }

   
  function increaseApproval(address _spender, uint _addedValue, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.increaseApproval(_spender, _addedValue);

    require(_spender.call(_data));

    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.decreaseApproval(_spender, _subtractedValue);

    require(_spender.call(_data));

    return true;
  }

}

 




 
contract MultiOwnable {
    address public root;
    mapping (address => address) public owners;  
    
     
    function MultiOwnable() public {
        root= msg.sender;
        owners[root]= root;
    }
    
     
    modifier onlyOwner() {
        require(owners[msg.sender] != 0);
        _;
    }
    
     
    function newOwner(address _owner) onlyOwner public returns (bool) {
        require(_owner != 0);
        owners[_owner]= msg.sender;
        return true;
    }
    
     
    function deleteOwner(address _owner) onlyOwner public returns (bool) {
        require(owners[_owner] == msg.sender || (owners[_owner] != 0 && msg.sender == root));
        owners[_owner]= 0;
        return true;
    }
}


 
contract KStarCoinBasic is ERC827Token, MultiOwnable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;
    using strings for *;

     
     
     
     
     
     
    uint256 public capOfTotalSupply;
    uint256 public constant INITIAL_SUPPLY= 30e6 * 1 ether;  

    uint256 public crowdsaleRaised;
    uint256 public constant CROWDSALE_HARDCAP= 45e6 * 1 ether;  

     
    function increaseCap(uint256 _addedValue) onlyOwner public returns (bool) {
        require(_addedValue >= 100e6 * 1 ether);
        capOfTotalSupply = capOfTotalSupply.add(_addedValue);
        return true;
    }
    
     
    function checkCap(uint256 _amount) public view returns (bool) {
        return (totalSupply_.add(_amount) <= capOfTotalSupply);
    }
    
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(super.transfer(_to, _value));
        KSC_Send(msg.sender, _to, _value, "");
        KSC_Receive(_to, msg.sender, _value, "");
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(super.transferFrom(_from, _to, _value));
        KSC_SendTo(_from, _to, _value, "");
        KSC_ReceiveFrom(_to, _from, _value, "");
        return true;
    }
    
    function approve(address _to, uint256 _value) public returns (bool) {
        require(super.approve(_to, _value));
        KSC_Approve(msg.sender, _to, _value, "");
        return true;
    }
    
     
    function increaseApproval(address _to, uint _addedValue) public returns (bool) {
        require(super.increaseApproval(_to, _addedValue));
        KSC_ApprovalInc(msg.sender, _to, _addedValue, "");
        return true;
    }
    
     
    function decreaseApproval(address _to, uint _subtractedValue) public returns (bool) {
        require(super.decreaseApproval(_to, _subtractedValue));
        KSC_ApprovalDec(msg.sender, _to, _subtractedValue, "");
        return true;
    }
	 
    
     
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
        return transfer(_to, _value, _data, "");
    }
    
    function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
        return transferFrom(_from, _to, _value, _data, "");
    }
    
    function approve(address _to, uint256 _value, bytes _data) public returns (bool) {
        return approve(_to, _value, _data, "");
    }
    
     
    function increaseApproval(address _to, uint _addedValue, bytes _data) public returns (bool) {
        return increaseApproval(_to, _addedValue, _data, "");
    }
    
     
    function decreaseApproval(address _to, uint _subtractedValue, bytes _data) public returns (bool) {
        return decreaseApproval(_to, _subtractedValue, _data, "");
    }
	 
    
     
    function transfer(address _to, uint256 _value, bytes _data, string _note) public returns (bool) {
        require(super.transfer(_to, _value, _data));
        KSC_Send(msg.sender, _to, _value, _note);
        KSC_Receive(_to, msg.sender, _value, _note);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value, bytes _data, string _note) public returns (bool) {
        require(super.transferFrom(_from, _to, _value, _data));
        KSC_SendTo(_from, _to, _value, _note);
        KSC_ReceiveFrom(_to, _from, _value, _note);
        return true;
    }
    
    function approve(address _to, uint256 _value, bytes _data, string _note) public returns (bool) {
        require(super.approve(_to, _value, _data));
        KSC_Approve(msg.sender, _to, _value, _note);
        return true;
    }
    
    function increaseApproval(address _to, uint _addedValue, bytes _data, string _note) public returns (bool) {
        require(super.increaseApproval(_to, _addedValue, _data));
        KSC_ApprovalInc(msg.sender, _to, _addedValue, _note);
        return true;
    }
    
    function decreaseApproval(address _to, uint _subtractedValue, bytes _data, string _note) public returns (bool) {
        require(super.decreaseApproval(_to, _subtractedValue, _data));
        KSC_ApprovalDec(msg.sender, _to, _subtractedValue, _note);
        return true;
    }
	 
      
     
    function mint(address _to, uint256 _amount) onlyOwner internal returns (bool) {
        require(_to != address(0));
        require(checkCap(_amount));

        totalSupply_= totalSupply_.add(_amount);
        balances[_to]= balances[_to].add(_amount);

        Transfer(address(0), _to, _amount);
        return true;
    }
    
     
    function mint(address _to, uint256 _amount, string _note) onlyOwner public returns (bool) {
        require(mint(_to, _amount));
        KSC_Mint(_to, msg.sender, _amount, _note);
        return true;
    }

     
    function burn(address _to, uint256 _amount) onlyOwner internal returns (bool) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);

        balances[_to]= balances[_to].sub(_amount);
        totalSupply_= totalSupply_.sub(_amount);
        
        return true;
    }
    
     
    function burn(address _to, uint256 _amount, string _note) onlyOwner public returns (bool) {
        require(burn(_to, _amount));
        KSC_Burn(_to, msg.sender, _amount, _note);
        return true;
    }
    
     
     
    function sell(address _to, uint256 _value, string _note) onlyOwner public returns (bool) {
        require(crowdsaleRaised.add(_value) <= CROWDSALE_HARDCAP);
        require(mint(_to, _value));
        
        crowdsaleRaised= crowdsaleRaised.add(_value);
        KSC_Buy(_to, msg.sender, _value, _note);
        return true;
    }
    
     
     
    function mintToOtherCoinBuyer(address _to, uint256 _value, string _note) onlyOwner public returns (bool) {
        require(mint(_to, _value));
        KSC_BuyOtherCoin(_to, msg.sender, _value, _note);
        return true;
    }
  
     
     
    function mintToInfluencer(address _to, uint256 _value, string _note) onlyOwner public returns (bool) {
        require(mint(_to, _value));
        KSC_GetAsInfluencer(_to, msg.sender, _value, _note);
        return true;
    }
    
     
     
    function exchangePointToCoin(address _to, uint256 _value, string _note) onlyOwner public returns (bool) {
        require(mint(_to, _value));
        KSC_ExchangePointToCoin(_to, msg.sender, _value, _note);
        return true;
    }
    
     
     
    event KSC_Initialize(address indexed _src, address indexed _desc, uint256 _value, string _note);
    
     
    event KSC_Send(address indexed _src, address indexed _desc, uint256 _value, string _note);
    event KSC_Receive(address indexed _src, address indexed _desc, uint256 _value, string _note);
    
     
    event KSC_Approve(address indexed _src, address indexed _desc, uint256 _value, string _note);
    event KSC_ApprovalInc(address indexed _src, address indexed _desc, uint256 _value, string _note);
    event KSC_ApprovalDec(address indexed _src, address indexed _desc, uint256 _value, string _note);
    
     
    event KSC_SendTo(address indexed _src, address indexed _desc, uint256 _value, string _note);
    event KSC_ReceiveFrom(address indexed _src, address indexed _desc, uint256 _value, string _note);
    
     
    event KSC_Mint(address indexed _src, address indexed _desc, uint256 _value, string _note);
    event KSC_Burn(address indexed _src, address indexed _desc, uint256 _value, string _note);
    
     
    event KSC_Buy(address indexed _src, address indexed _desc, uint256 _value, string _note);
    
     
    event KSC_BuyOtherCoin(address indexed _src, address indexed _desc, uint256 _value, string _note);
    
     
    event KSC_GetAsInfluencer(address indexed _src, address indexed _desc, uint256 _value, string _note);

     
    event KSC_ExchangePointToCoin(address indexed _src, address indexed _desc, uint256 _value, string _note);
}


 
contract KStarCoin is KStarCoinBasic {
    string public constant name= "KStarCoin";
    string public constant symbol= "KSC";
    uint8 public constant decimals= 18;
    
     
    function KStarCoin() public {
        totalSupply_= INITIAL_SUPPLY;
        balances[msg.sender]= INITIAL_SUPPLY;
	    capOfTotalSupply = 100e6 * 1 ether;
        crowdsaleRaised= 0;
        
        Transfer(0x0, msg.sender, INITIAL_SUPPLY);
        KSC_Initialize(msg.sender, 0x0, INITIAL_SUPPLY, "");
    }
}