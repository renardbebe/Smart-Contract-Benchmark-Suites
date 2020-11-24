 

pragma solidity ^0.4.19;
 
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


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
 
contract ERC20Basic {
     
  uint256 public totalSupply;
  
  function balanceOf(address _owner) public view returns (uint256 balance);
  
  function transfer(address _to, uint256 _amount) public returns (bool success);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender) public view returns (uint256 remaining);
  
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);
  
  function approve(address _spender, uint256 _amount) public returns (bool success);
  
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

   
  mapping(address => uint256) balances;
  address ownerWallet;
  bool released = false;

  enum LockupType {NOLOCK, FOUNDATION, TEAM, CONSORTIUM, PARTNER, BLACK}

  struct Lockup
  {
      uint256 lockupTime;
      uint256 lockupAmount;
      LockupType lockType;
  }
  Lockup lockup;
  mapping(address=>Lockup) lockupParticipants;  
  
  
  uint256 startTime;
  function release() public {
      require(ownerWallet == msg.sender);
      require(!released);
      released = true;
  }

  function lock() public {
      require(ownerWallet == msg.sender);
      require(released);
      released = false;
  }

  function get_Release() view public returns (bool) {
      return released;
  }

   
  function transfer(address _to, uint256 _amount) public returns (bool success) {
    require(_to != address(0));
    require(balances[msg.sender] >= _amount && _amount > 0
        && balances[_to].add(_amount) > balances[_to]);


    if (!released) {  
      if ( (lockupParticipants[msg.sender].lockType == LockupType.PARTNER) || (msg.sender == ownerWallet) ) {
         
         
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
       
      } else {
         
        return false;
      } 
    } else {  
      if (lockupParticipants[msg.sender].lockType == LockupType.BLACK ) {
         
        return false;
      } else if (lockupParticipants[msg.sender].lockupAmount>0) {
            uint timePassed = now - startTime;
            if (timePassed < lockupParticipants[msg.sender].lockupTime)
            {
                require(balances[msg.sender].sub(_amount) >= lockupParticipants[msg.sender].lockupAmount);
            }
             
             
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            emit Transfer(msg.sender, _to, _amount);
            return true;
      }
    }
    return false;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {
  
  
  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
    require(_to != address(0));
    require(balances[_from] >= _amount);
    require(allowed[_from][msg.sender] >= _amount);
    require(_amount > 0 && balances[_to].add(_amount) > balances[_to]);
    
    if (lockupParticipants[_from].lockupAmount>0)
    {
        uint timePassed = now - startTime;
        if (timePassed < lockupParticipants[_from].lockupTime)
        {
            require(balances[msg.sender].sub(_amount) >= lockupParticipants[_from].lockupAmount);
        }
    }
    balances[_from] = balances[_from].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    emit Transfer(_from, _to, _amount);
    return true;
  }

   
  function approve(address _spender, uint256 _amount) public returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract BurnableToken is StandardToken, Ownable {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public onlyOwner{
        require(_value <= balances[ownerWallet]);
         
         

        balances[ownerWallet] = balances[ownerWallet].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
    }
}
 
 contract GenieKRW is BurnableToken {
     string public name ;
     string public symbol ;
     uint8 public decimals =  18;
     
   
      
     function ()public payable {
         revert();
     }
     
      
      
     constructor() public 
     {
         owner = msg.sender;
         ownerWallet = owner;
         totalSupply = 10000000000;
         totalSupply = totalSupply.mul(10 ** uint256(decimals));  
         name = "GenieKRW";
         symbol = "GKRW";
         balances[owner] = totalSupply;
         startTime = now;
         
          
         emit Transfer(address(0), msg.sender, totalSupply);
     }
     
      
    function getTokenDetail() public view returns (string, string, uint256) {
	    return (name, symbol, totalSupply);
    }
    
    

    function lockTokensForTeam(address team, uint256 daysafter, uint256 amount) public onlyOwner
    {
        lockup = Lockup({
                          lockupTime:daysafter * 1 days,
                          lockupAmount:amount * 10 ** uint256(decimals), 
                          lockType:LockupType.TEAM
                          });
        lockupParticipants[team] = lockup;
    }

  

    function registerPartner(address partner) public onlyOwner
    {
        lockup = Lockup({
                          lockupTime:0 days,
                          lockupAmount:0 * 10 ** uint256(decimals), 
                          lockType:LockupType.PARTNER
                          });
        lockupParticipants[partner] = lockup;
    }

    function lockTokensUpdate(address addr, uint daysafter, uint256 amount, uint256 l_type) public onlyOwner
    {
        
        lockup = Lockup({
                          lockupTime:daysafter *  1 days,
                          lockupAmount:amount * 10 ** uint256(decimals), 
                          lockType: BasicToken.LockupType(l_type)
                          });
        lockupParticipants[addr] = lockup;
    }
 }