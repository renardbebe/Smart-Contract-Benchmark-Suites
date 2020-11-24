 

pragma solidity ^0.4.24;

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

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
     
   emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

library Locklist {
  
  struct List {
    mapping(address => bool) registry;
  }
  
  function add(List storage list, address _addr)
    internal
  {
    list.registry[_addr] = true;
  }

  function remove(List storage list, address _addr)
    internal
  {
    list.registry[_addr] = false;
  }

  function check(List storage list, address _addr)
    view
    internal
    returns (bool)
  {
    return list.registry[_addr];
  }
}

contract Locklisted is Ownable  {

  Locklist.List private _list;
  
  modifier onlyLocklisted() {
    require(Locklist.check(_list, msg.sender) == true);
    _;
  }

  event AddressAdded(address _addr);
  event AddressRemoved(address _addr);
  
  function LocklistedAddress()
  public
  {
    Locklist.add(_list, msg.sender);
  }

  function LocklistAddressenable(address _addr) onlyOwner
    public
  {
    Locklist.add(_list, _addr);
    emit AddressAdded(_addr);
  }

  function LocklistAddressdisable(address _addr) onlyOwner
    public
  {
    Locklist.remove(_list, _addr);
   emit AddressRemoved(_addr);
  }
  
  function LocklistAddressisListed(address _addr)
  public
  view
  returns (bool)
  {
      return Locklist.check(_list, _addr);
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract BasicToken is ERC20Basic,Locklisted {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(!LocklistAddressisListed(_to));
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    
     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
   emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(!LocklistAddressisListed(_to));
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
   emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

contract TokenFreeze is Ownable, StandardToken {
  uint256 public unfreeze_date;
  
  event FreezeDateChanged(string message, uint256 date);

  function TokenFreeze() public {
    unfreeze_date = now;
  }

  modifier freezed() {
    require(unfreeze_date < now);
    _;
  }

  function changeFreezeDate(uint256 datetime) onlyOwner public {
    require(datetime != 0);
    unfreeze_date = datetime;
  emit  FreezeDateChanged("Unfreeze Date: ", datetime);
  }
  
  function transferFrom(address _from, address _to, uint256 _value) freezed public returns (bool) {
    super.transferFrom(_from, _to, _value);
  }

  function transfer(address _to, uint256 _value) freezed public returns (bool) {
    super.transfer(_to, _value);
  }

}



 

contract MintableToken is TokenFreeze {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  
  string public constant name = "Vertex";
  string public constant symbol = "VTEX";
  uint8 public constant decimals = 5;   
  bool public mintingFinished = false;
 
  mapping (address => bool) public whitelist; 
  
  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(!LocklistAddressisListed(_to));
    totalSupply = totalSupply.add(_amount);
    require(totalSupply <= 30000000000000);
    balances[_to] = balances[_to].add(_amount);
    emit  Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}




contract WhitelistToken is Locklisted {

  function onlyLocklistedCanDo()
    onlyLocklisted
    view
    external
  {    
  }

}

 
 
contract Vertex_Token is Ownable,  Locklisted, MintableToken {
    using SafeMath for uint256;

     
    MintableToken public token;

     
     
     
    uint256 public ICOStartTime = 1538380800;
    uint256 public ICOEndTime = 1548403200;

    uint256 public hardCap = 30000000000000;

     
    address public wallet;

     
    uint256 public rate;
    uint256 public weiRaised;

     

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event newOraclizeQuery(string description);

    function Vertex_Token(uint256 _rate, address _wallet, uint256 _unfreeze_date)  public {
        require(_rate > 0);
        require(_wallet != address(0));

        token = createTokenContract();

        rate = _rate;
        wallet = _wallet;
        
        token.changeFreezeDate(_unfreeze_date);
    }
   
     
     
     
     
     
     
     
     
     
    
    function changeTokenFreezeDate(uint256 _new_date) onlyOwner public {
        token.changeFreezeDate(_new_date);
    }
    
    function unfreezeTokens() onlyOwner public {
        token.changeFreezeDate(now);
    }

     
     
    function createTokenContract() internal returns (MintableToken) {
        return new MintableToken();
    }

     
    function () payable public {
        buyTokens(msg.sender);
    }

     
    function getUSDPrice() public constant returns (uint256 cents_by_token) {
        uint256 total_tokens = SafeMath.div(totalTokenSupply(), token.decimals());

        if (total_tokens > 165000000)
            return 31;
        else if (total_tokens > 150000000)
            return 30;
        else if (total_tokens > 135000000)
            return 29;
        else if (total_tokens > 120000000)
            return 28;
        else if (total_tokens > 105000000)
            return 27;
        else if (total_tokens > 90000000)
            return 26;
        else if (total_tokens > 75000000)
            return 25;
        else if (total_tokens > 60000000)
            return 24;
        else if (total_tokens > 45000000)
            return 23;
        else if (total_tokens > 30000000)
            return 22;
        else if (total_tokens > 15000000)
            return 18;
        else
            return 15;
    }
     
     
     
     
    function stringFloatToUnsigned(string _s) payable public returns (string) {
        bytes memory _new_s = new bytes(bytes(_s).length - 1);
        uint k = 0;

        for (uint i = 0; i < bytes(_s).length; i++) {
            if (bytes(_s)[i] == '.') { break; }  

            _new_s[k] = bytes(_s)[i];
            k++;
        }

        return string(_new_s);
    }
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    
    
     
     function withdraw(uint amount) onlyOwner returns(bool) {
         require(amount < this.balance);
        wallet.transfer(amount);
        return true;

    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    
     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 _convert_rate = SafeMath.div(SafeMath.mul(rate, getUSDPrice()), 100);

         
        uint256 weiAmount = SafeMath.mul(msg.value, 10**uint256(token.decimals()));
        uint256 tokens = SafeMath.div(weiAmount, _convert_rate);
        require(tokens > 0);
        
         
         

         
        weiRaised = SafeMath.add(weiRaised, msg.value);

         
        emit TokenPurchase(msg.sender, beneficiary, msg.value, tokens);
         
         
    }


     
    function sendTokens(address _to, uint256 _amount) onlyOwner public {
        token.mint(_to, _amount);
    }
     
    function transferTokenOwnership(address _newOwner) onlyOwner public {
        token.transferOwnership(_newOwner);
    }

     
     
    function forwardFunds() internal {
        wallet.transfer(address(this).balance);
    }

     
    function validPurchase() internal constant returns (bool) {
        bool hardCapOk = token.totalSupply() < SafeMath.mul(hardCap, 10**uint256(token.decimals()));
        
        bool withinICOPeriod = now >= ICOStartTime && now <= ICOEndTime;
        bool nonZeroPurchase = msg.value != 0;
        
         
        uint256 total_tokens = SafeMath.div(totalTokenSupply(), token.decimals());
         
         
         
         
         
        
         
         return hardCapOk && withinICOPeriod && nonZeroPurchase;
    }
    
     
    function totalTokenSupply() public view returns (uint256) {
        return token.totalSupply();
    }
}