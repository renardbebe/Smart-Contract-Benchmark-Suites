 

pragma solidity ^0.4.15;

 

contract SafeMath {
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

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

     
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = true;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused {
    paused = false;
    Unpause();
  }
}
 
contract LockFunds is Ownable {
  event Lock();
  event UnLock();

  bool public locked = true;


   
  modifier whenNotLocked() {
    require(!locked);
    _;
  }

   
  modifier whenLocked() {
    require(locked);
    _;
  }

   
  function lock() onlyOwner whenNotLocked {
    locked = true;
    Lock();
  }

   
  function unlock() onlyOwner whenLocked {
    locked = false;
    UnLock();
  }
}
 
contract StandardToken is Token, SafeMath, LockFunds {

    function transfer(address _to, uint256 _value) whenNotLocked returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] = sub(balances[msg.sender], _value);
        balances[_to] = add(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) whenNotLocked returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] = add(balances[_to], _value);
        balances[_from] -= sub(balances[_from], _value);
        allowed[_from][msg.sender] = sub(allowed[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

 

contract BurnableToken is SafeMath, StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = sub(balances[burner],_value);
        totalSupply = sub(totalSupply,_value);
        Burn(burner, _value);
    }
}

 

contract SEEDSToken is SafeMath, StandardToken, BurnableToken, Pausable {

    string public constant name = "Seeds";                                       
    string public constant symbol = "SEEDS";                                     
    uint256 public constant decimals = 18;                                       
    uint256 public constant maxFixedSupply = 500000000*10**decimals;             
	uint256 public constant tokenCreationCap = 375000000*10**decimals;           
	uint256 public constant initialSupply = add(add(freeTotal, teamTotal), add(advisorTotal,lockedTeam));    
    uint256 public freeTotal = 5000000*10**decimals;                             
    uint256 public teamTotal = 50000000*10**decimals;                            
    uint256 public advisorTotal = 50000000*10**decimals;                         
    uint256 public lockedTeam = 20000000*10**decimals;                           
    uint256 public stillAvailable = tokenCreationCap;                            
    
	
	uint256 public toBeDistributedFree = freeTotal; 
    uint256 public totalEthReceivedinWei;
    uint256 public totalDistributedinWei;
    uint256 public totalBountyinWei;

    Phase public currentPhase = Phase.END;

    enum Phase {
        PreICO,
        ICO1,
        ICO2,
        ICO3,
        ICO4,
        END
    }

    event CreateSEEDS(address indexed _to, uint256 _value);
    event PriceChanged(string _text, uint _newPrice);
    event StageChanged(string _text);
    event Withdraw(address to, uint amount);

    function SEEDSToken() {                                                      
        owner=msg.sender;                                                        
        balances[owner] = sub(maxFixedSupply, tokenCreationCap);                 
        totalSupply = initialSupply;
    
    }

    function () payable {
        createTokens();
    }


    function createTokens() whenNotPaused internal  {                            
        uint multiplier = 10 ** 10;                                              
        uint256 oneTokenInWei;
        uint256 tokens; 
        uint256 checkedSupply;

        if (currentPhase == Phase.PreICO){
            {
                oneTokenInWei = 25000000000000;
                tokens = div(msg.value*100000000, oneTokenInWei) * multiplier;
                checkedSupply = add(totalSupply, tokens);
                if (checkedSupply <= tokenCreationCap)
                    {
                        addTokens(tokens);
                        stillAvailable = sub(stillAvailable, tokens);            
                    }
                else
                    revert ();
            }
        } 
        else if (currentPhase == Phase.ICO1){
            {
                oneTokenInWei = 35000000000000;
                tokens = div(msg.value*100000000, oneTokenInWei) * multiplier;
                checkedSupply = add(totalSupply, tokens);
                if (checkedSupply <= tokenCreationCap)
                    {
                        addTokens(tokens);
                        stillAvailable = sub(stillAvailable, tokens);
                    }
                else
                    revert ();
            }
        }
        else if (currentPhase == Phase.ICO2){
            {
                oneTokenInWei = 42000000000000;
                tokens = div(msg.value*100000000, oneTokenInWei) * multiplier;
                checkedSupply = add(totalSupply, tokens);
                if (checkedSupply <= tokenCreationCap)
                    {
                        addTokens(tokens);
                        stillAvailable = sub(stillAvailable, tokens);            
                    }
                else
                    revert ();
            }
        }
        else if (currentPhase == Phase.ICO3){
            {
                oneTokenInWei = 47500000000000;
                tokens = div(msg.value*100000000, oneTokenInWei) * multiplier;
                checkedSupply = add(totalSupply, tokens);
                if (checkedSupply <= tokenCreationCap)
                    {
                        addTokens(tokens);
                        stillAvailable = sub(stillAvailable, tokens);            
                    }
                else
                    revert ();
            }
        }
        else if (currentPhase == Phase.ICO4){
            {
                oneTokenInWei = 50000000000000;
                tokens = div(msg.value*100000000, oneTokenInWei) * multiplier;
                checkedSupply = add(totalSupply, tokens);
                if (checkedSupply <= tokenCreationCap)
                    {
                        addTokens(tokens);
                        stillAvailable = sub(stillAvailable, tokens);            
                    }
                else
                    revert ();
            }
        }
        else if (currentPhase == Phase.END){
            revert();
        }
    }

    function addTokens(uint256 tokens) internal {                                
        require (msg.value >= 0 && msg.sender != address(0));
        balances[msg.sender] = add(balances[msg.sender], tokens);
        totalSupply = add(totalSupply, tokens);
        totalEthReceivedinWei = add(totalEthReceivedinWei, msg.value);
        CreateSEEDS(msg.sender, tokens);
    }

    function withdrawInWei(address _toAddress, uint256 amount) external onlyOwner {      
        require(_toAddress != address(0));
        _toAddress.transfer(amount);
        Withdraw(_toAddress, amount);
    }

    function setPreICOPhase() external onlyOwner {                               
        currentPhase = Phase.PreICO;
        StageChanged("Current stage: PreICO");
    }
    
    function setICO1Phase() external onlyOwner {
        currentPhase = Phase.ICO1;
        StageChanged("Current stage: ICO1");
    }
    
    function setICO2Phase() external onlyOwner {
        currentPhase = Phase.ICO2;
        StageChanged("Current stage: ICO2");
    }
    
    function setICO3Phase() external onlyOwner {
        currentPhase = Phase.ICO3;
        StageChanged("Current stage: ICO3");
    }
    
    function setICO4Phase() external onlyOwner {
        currentPhase = Phase.ICO4;
        StageChanged("Current stage: ICO4");
    }

    function setENDPhase () external onlyOwner {
        currentPhase = Phase.END;
        StageChanged ("Current stage: END");
    }

    function generateTokens(address _receiver, uint256 _amount) external onlyOwner {     
        require(_receiver != address(0));
        balances[_receiver] = add(balances[_receiver], _amount);
        totalSupply = add(totalSupply, _amount);
        CreateSEEDS(_receiver, _amount);
    }

	function airdropSEEDSinWei(address[] addresses, uint256 _value) onlyOwner {  
         uint256 airdrop = _value;
         uint256 airdropMax = 100000*10**decimals;
         uint256 total = mul(airdrop, addresses.length);
         if (toBeDistributedFree >= 0 && total<=airdropMax){
             for (uint i = 0; i < addresses.length; i++) {
	            balances[owner] = sub(balances[owner], airdrop);
                balances[addresses[i]] = add(balances[addresses[i]],airdrop);
                Transfer(owner, addresses[i], airdrop);
            }
			totalDistributedinWei = add(totalDistributedinWei,total);
			toBeDistributedFree = sub(toBeDistributedFree, totalDistributedinWei);
         }
         else
            revert();
       }
    function bountySEEDSinWei(address[] addresses, uint256 _value) onlyOwner {   
         uint256 bounty = _value;
         uint256 total = mul(bounty, addresses.length);
         if (toBeDistributedFree >= 0){
             for (uint i = 0; i < addresses.length; i++) {
	            balances[owner] = sub(balances[owner], bounty);
                balances[addresses[i]] = add(balances[addresses[i]],bounty);
                Transfer(owner, addresses[i], bounty);
            }
			totalBountyinWei = add(totalBountyinWei,total);
			toBeDistributedFree = sub(toBeDistributedFree, totalBountyinWei);
         }
         else
            revert();
       }
       
}