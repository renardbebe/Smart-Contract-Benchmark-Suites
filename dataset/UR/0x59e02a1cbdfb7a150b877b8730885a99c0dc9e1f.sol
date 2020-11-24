 

pragma solidity ^0.4.8;

 
contract SafeMath {
  function safeMul(uint256 a, uint256 b)  internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure  returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >=a);
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

  function kill() public {
      if (msg.sender == owner)
          selfdestruct(owner);
  }
   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
 
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  bool public paused = false;
   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }
   
  modifier whenPaused() {
    require(paused);
    _;
  }
   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }
   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract richtestff is SafeMath,Pausable{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
	  address public owner;
    uint256 public startTime;
    uint256[9] public founderAmounts;
     
    mapping (address => uint256) public balanceOf;
	  mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

	 
    event Freeze(address indexed from, uint256 value);

	 
    event Unfreeze(address indexed from, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    function richtestff(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) public {
        balanceOf[msg.sender] = initialSupply;               
        totalSupply = initialSupply;                         
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimalUnits;                             
		    owner = msg.sender;
        startTime=now;
        founderAmounts = [427*10** uint256(25), 304*10** uint256(25), 217*10** uint256(25), 154*10** uint256(25), 11*10** uint256(25), 78*10** uint256(25), 56*10** uint256(25), 34*10** uint256(25), 2*10** uint256(26)];
    }

     
    function transfer(address _to, uint256 _value) public whenNotPaused {
        if (_to == 0x0) revert();                                
        if (balanceOf[msg.sender] < _value) revert();            
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             
        emit Transfer(msg.sender, _to, _value);                    
    }

    function minutestotal() public onlyOwner 
    {
       if (now > startTime + 3 days&& founderAmounts[0]>0)
       {
        totalSupply=  SafeMath.safeAdd(totalSupply, founderAmounts[0]);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], founderAmounts[0]);
        founderAmounts[0]=0;
        emit  Transfer(0, msg.sender, founderAmounts[0]);

       }
       if (now > startTime + 6 days&& founderAmounts[1]>0)
       {
        totalSupply=  SafeMath.safeAdd(totalSupply, founderAmounts[1]);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], founderAmounts[1]);
        founderAmounts[1]=0;
        emit Transfer(0, msg.sender, founderAmounts[1]);

       }
        if (now > startTime + 9 days&& founderAmounts[2]>0)
       {
        totalSupply=  SafeMath.safeAdd(totalSupply, founderAmounts[2]);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], founderAmounts[2]);
        founderAmounts[2]=0;
        emit Transfer(0, msg.sender, founderAmounts[2]);
       }

        if (now > startTime + 12 days&& founderAmounts[3]>0)
       {
        totalSupply=  SafeMath.safeAdd(totalSupply, founderAmounts[3]);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], founderAmounts[3]);
        founderAmounts[3]=0;
        emit  Transfer(0, msg.sender, founderAmounts[3]);
       }
        if (now > startTime + 15 days&& founderAmounts[4]>0)
       {
        totalSupply=  SafeMath.safeAdd(totalSupply, founderAmounts[4]);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], founderAmounts[4]);
        founderAmounts[4]=0;
        emit Transfer(0, msg.sender, founderAmounts[4]);
       }
        if (now > startTime + 18 days&& founderAmounts[5]>0)
       {
        totalSupply=  SafeMath.safeAdd(totalSupply, founderAmounts[5]);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], founderAmounts[5]);
        founderAmounts[5]=0;
        emit  Transfer(0, msg.sender, founderAmounts[5]);
       }
        if (now > startTime + 21 days&& founderAmounts[6]>0)
       {
        totalSupply=  SafeMath.safeAdd(totalSupply, founderAmounts[6]);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], founderAmounts[6]);
        founderAmounts[6]=0;
        emit  Transfer(0, msg.sender, founderAmounts[6]);
       }
         if (now > startTime + 24 days&& founderAmounts[7]>0)
       {
        totalSupply=  SafeMath.safeAdd(totalSupply, founderAmounts[7]);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], founderAmounts[7]);
        founderAmounts[7]=0;
        emit  Transfer(0, msg.sender, founderAmounts[7]);
       }
        if (now > startTime + 27 days&& founderAmounts[8]>0)
       {
        totalSupply=  SafeMath.safeAdd(totalSupply, founderAmounts[8]);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], founderAmounts[8]);
        founderAmounts[8]=0;
        emit  Transfer(0, msg.sender, founderAmounts[8]);
       }
    }
     
    function approve(address _spender, uint256 _value) public whenNotPaused  returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit  Approval(msg.sender, _spender, _value);
        return true;
    }


     
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success) {
        if (_to == 0x0) revert();                                 
        if (balanceOf[_from] < _value) revert();                  
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();   
        if (_value > allowance[_from][msg.sender]) revert();      
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                            
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                              
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }


	function freeze(uint256 _value) public whenNotPaused returns (bool success) {
        if (balanceOf[msg.sender] < _value) revert();             
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                       
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                 
        emit  Freeze(msg.sender, _value);
        return true;
    }

	function unfreeze(uint256 _value) public whenNotPaused returns (bool success) {
        if (freezeOf[msg.sender] < _value) revert();             
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                       
		    balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }


}