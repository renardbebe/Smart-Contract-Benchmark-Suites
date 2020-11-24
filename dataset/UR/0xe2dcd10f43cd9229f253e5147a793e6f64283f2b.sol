 

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


   
  function Ownable() public {
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
  struct Lockup
  {
      uint256 lockupTime;
      uint256 lockupAmount;
  }
  Lockup lockup;
  mapping(address=>Lockup) lockupParticipants;  
  
  
  uint256 startTime;
   
  function transfer(address _to, uint256 _amount) public returns (bool success) {
    require(_to != address(0));
    require(balances[msg.sender] >= _amount && _amount > 0
        && balances[_to].add(_amount) > balances[_to]);

    if (lockupParticipants[msg.sender].lockupAmount>0)
    {
        uint timePassed = now - startTime;
        if (timePassed < lockupParticipants[msg.sender].lockupTime)
        {
            require(balances[msg.sender].sub(_amount) >= lockupParticipants[msg.sender].lockupAmount);
        }
    }
     
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(msg.sender, _to, _amount);
    return true;
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
 
 contract DayDayToken is BurnableToken {
     string public name ;
     string public symbol ;
     uint8 public decimals =  2;
     
   
      
     function ()public payable {
         revert();
     }
     
      
     function DayDayToken(address wallet) public 
     {
         owner = msg.sender;
         ownerWallet = wallet;
         totalSupply = 300000000000;
         totalSupply = totalSupply.mul(10 ** uint256(decimals));  
         name = "DayDayToken";
         symbol = "DD";
         balances[wallet] = totalSupply;
         startTime = now;
         
          
         emit Transfer(address(0), msg.sender, totalSupply);
     }
     
      
    function getTokenDetail() public view returns (string, string, uint256) {
	    return (name, symbol, totalSupply);
    }
    
     
    function lockTokensForFs (address F1, address F2) public onlyOwner
    {
        lockup = Lockup({lockupTime:720 days,lockupAmount:90000000 * 10 ** uint256(decimals)});
        lockupParticipants[F1] = lockup;
        
        lockup = Lockup({lockupTime:720 days,lockupAmount:60000000 * 10 ** uint256(decimals)});
        lockupParticipants[F2] = lockup;
    }
    function lockTokensForAs( address A1, address A2, 
                         address A3, address A4,
                         address A5, address A6,
                         address A7, address A8,
                         address A9) public onlyOwner
    {
        lockup = Lockup({lockupTime:180 days,lockupAmount:90000000 * 10 ** uint256(decimals)});
        lockupParticipants[A1] = lockup;
        
        lockup = Lockup({lockupTime:180 days,lockupAmount:60000000 * 10 ** uint256(decimals)});
        lockupParticipants[A2] = lockup;
        
        lockup = Lockup({lockupTime:180 days,lockupAmount:30000000 * 10 ** uint256(decimals)});
        lockupParticipants[A3] = lockup;
        
        lockup = Lockup({lockupTime:180 days,lockupAmount:60000000 * 10 ** uint256(decimals)});
        lockupParticipants[A4] = lockup;
        
        lockup = Lockup({lockupTime:180 days,lockupAmount:60000000 * 10 ** uint256(decimals)});
        lockupParticipants[A5] = lockup;
        
        lockup = Lockup({lockupTime:180 days,lockupAmount:15000000 * 10 ** uint256(decimals)});
        lockupParticipants[A6] = lockup;
        
        lockup = Lockup({lockupTime:180 days,lockupAmount:15000000 * 10 ** uint256(decimals)});
        lockupParticipants[A7] = lockup;
        
        lockup = Lockup({lockupTime:180 days,lockupAmount:15000000 * 10 ** uint256(decimals)});
        lockupParticipants[A8] = lockup;
        
        lockup = Lockup({lockupTime:180 days,lockupAmount:15000000 * 10 ** uint256(decimals)});
        lockupParticipants[A9] = lockup;
    }
    
    function lockTokensForCs(address C1,address C2, address C3) public onlyOwner
    {
        lockup = Lockup({lockupTime:90 days,lockupAmount:2500000 * 10 ** uint256(decimals)});
        lockupParticipants[C1] = lockup;
        
        lockup = Lockup({lockupTime:90 days,lockupAmount:1000000 * 10 ** uint256(decimals)});
        lockupParticipants[C2] = lockup;
        
        lockup = Lockup({lockupTime:90 days,lockupAmount:1500000 * 10 ** uint256(decimals)});
        lockupParticipants[C3] = lockup;   
    }
    
    function lockTokensForTeamAndReserve(address team) public onlyOwner
    {
        lockup = Lockup({lockupTime:360 days,lockupAmount:63000000 * 10 ** uint256(decimals)});
        lockupParticipants[team] = lockup;
        
        lockup = Lockup({lockupTime:720 days,lockupAmount:415000000 * 10 ** uint256(decimals)});
        lockupParticipants[ownerWallet] = lockup;
    }
 }