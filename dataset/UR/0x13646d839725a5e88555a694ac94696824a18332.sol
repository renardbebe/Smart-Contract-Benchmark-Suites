 

 

pragma solidity ^0.4.19;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
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
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }


contract TokenERC20 is owned {
    using SafeMath for uint256;
 
    bool public mintingFinished = false;

     modifier canMint {
        require(!mintingFinished);
        _;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowed;
      
    mapping (address => uint256) public frozenAccount;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);
    event Frozen(address indexed from, uint256 till);

     
    event Burn(address indexed from, uint256 value);
     
    event Mint(address indexed to, uint256 amount);
    event MintStarted();
    event MintFinished();

     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);       
        balanceOf[msg.sender] = totalSupply;                         
        name = tokenName;                                            
        symbol = tokenSymbol;                                        
    }

     
    function totalSupply() constant public returns (uint256 supply) {
        return totalSupply;
    }
     
    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balanceOf[_owner];
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
        
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balanceOf[msg.sender]);
        require(frozenAccount[msg.sender] < now);                    
        if (frozenAccount[msg.sender] < now) frozenAccount[msg.sender] = 0;
         
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
   
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balanceOf[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(frozenAccount[_from] < now);                    
        if (frozenAccount[_from] < now) frozenAccount[_from] = 0;
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
              allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }   
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowed[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowed[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
     
    function _mint(uint256 _value) canMint internal  {
        totalSupply = totalSupply.add(_value);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_value);
    }
    
     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
     
    function startMinting() onlyOwner  public returns (bool) {
        mintingFinished = false;
        MintStarted();
        return true;
    }  

     
   function freezeAccount(address _from, uint256 _till) onlyOwner public {
        require(frozenAccount[_from] == 0);
        frozenAccount[_from] = _till;                  
    }

}


contract LeRT is TokenERC20 {

 

     
    struct periodTerms { 
        uint256 periodTime;
        uint periodBonus;    
    }
    
    uint256 public priceLeRT = 100000000000000;  

    uint public currentPeriod = 0;
    
    mapping (uint => periodTerms) public periodTable;

     
    mapping (address => uint256) public frozenAccount;

    
     
    function() payable canMint public {
        if (now > periodTable[currentPeriod].periodTime) currentPeriod++;
        require(currentPeriod != 7);
        
        uint256 newTokens;
        require(priceLeRT > 0);
         
        newTokens = msg.value / priceLeRT * 10 ** uint256(decimals);
         
        newTokens += newTokens/100 * periodTable[currentPeriod].periodBonus; 
        _mint(newTokens);
        owner.transfer(msg.value); 
    }

     
    function LeRT(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {
         
        periodTable[0].periodTime = 1519084800;
        periodTable[0].periodBonus = 50;
        periodTable[1].periodTime = 1519343999;
        periodTable[1].periodBonus = 45;
        periodTable[2].periodTime = 1519689599;
        periodTable[2].periodBonus = 40;
        periodTable[3].periodTime = 1520294399;
        periodTable[3].periodBonus = 35;
        periodTable[4].periodTime = 1520899199;
        periodTable[4].periodBonus = 30;
        periodTable[5].periodTime = 1522108799;
        periodTable[5].periodBonus = 20;
        periodTable[6].periodTime = 1525132799;
        periodTable[6].periodBonus = 15;
        periodTable[7].periodTime = 1527811199;
        periodTable[7].periodBonus = 0;}

    function setPrice(uint256 _value) public onlyOwner {
        priceLeRT = _value;
    }
    function setPeriod(uint _period, uint256 _periodTime, uint256 _periodBouns) public onlyOwner {
        periodTable[_period].periodTime = _periodTime;
        periodTable[_period].periodBonus = _periodBouns;
    }
    
    function setCurrentPeriod(uint _period) public onlyOwner {
        currentPeriod = _period;
    }
    
    function mintOther(address _to, uint256 _value) public onlyOwner {
        uint256 newTokens;
        newTokens = _value + _value/100 * periodTable[currentPeriod].periodBonus; 
        balanceOf[_to] += newTokens;
        totalSupply += newTokens;
    }
}