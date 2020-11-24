 

pragma solidity >=0.4.10;

 
contract Owned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

 
library SafeMath {
  function safeMul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);  
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a && c>=b);
    return c;
  }
}

 
contract ESGAssetHolder {
    
    function burn(address _holder, uint _amount) returns (bool result) {

        _holder = 0x0;                               
        _amount = 0;                                 
        return false;
    }
}


 
contract ESGToken is Owned {
        
    string public name = "ESG Token";                
    string public symbol = "ESG";                    
    uint256 public decimals = 3;                     
    uint256 public currentSupply;                    
    uint256 public supplyCap;                        
    address public ICOcontroller;                    
    address public timelockTokens;                   
    bool public tokenParametersSet;                         
    bool public controllerSet;                              

    mapping (address => uint256) public balanceOf;                       
    mapping (address => mapping (address => uint)) public allowance;     
    mapping (address => bool) public frozenAccount;                      


    modifier onlyControllerOrOwner() {             
        require(msg.sender == ICOcontroller || msg.sender == owner);
        _;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address owner, uint amount);
    event FrozenFunds(address target, bool frozen);
    event Burn(address coinholder, uint amount);
    
     
    function ESGToken() {
        currentSupply = 0;                       
        supplyCap = 0;                           
        tokenParametersSet = false;              
        controllerSet = false;                   
    }

     
    function setICOController(address _ico) onlyOwner {      
        require(_ico != 0x0);
        ICOcontroller = _ico;
        controllerSet = true;
    }


     
    function setParameters(address _timelockAddr) onlyOwner {
        require(_timelockAddr != 0x0);

        timelockTokens = _timelockAddr;

        tokenParametersSet = true;
    }

    function parametersAreSet() constant returns (bool) {
        return tokenParametersSet && controllerSet;
    }

     
    function setTokenCapInUnits(uint256 _supplyCap) onlyControllerOrOwner {    
        assert(_supplyCap > 0);
        
        supplyCap = SafeMath.safeMul(_supplyCap, (10**decimals));
    }

     
    function mintLockedTokens(uint256 _mMentTkns) onlyControllerOrOwner {
        assert(_mMentTkns > 0);
        assert(tokenParametersSet);

        mint(timelockTokens, _mMentTkns);  
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balanceOf[_owner];
    }

     
    function mint(address _address, uint _amount) onlyControllerOrOwner {
        require(_address != 0x0);
        uint256 amount = SafeMath.safeMul(_amount, (10**decimals));              

         
        assert(supplyCap > 0 && amount > 0 && SafeMath.safeAdd(currentSupply, amount) <= supplyCap);
        
        balanceOf[_address] = SafeMath.safeAdd(balanceOf[_address], amount);     
        currentSupply = SafeMath.safeAdd(currentSupply, amount);                 
        
        Mint(_address, amount);
    }
    
     
    function transfer(address _to, uint _value) returns (bool success) {
        require(!frozenAccount[msg.sender]);         

         
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);    
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                  
        Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {   
        require(!frozenAccount[_from]);                          
        
         
        if (allowance[_from][msg.sender] < _value)
            return false;

         
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value); 

         
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);

        Transfer(_from, _to, _value);
        return true;
    }
    
     
    function approve(address _spender, uint256 _value)       
        returns (bool success)
    {
        require(!frozenAccount[msg.sender]);                 

         
        if ((_value != 0) && (allowance[msg.sender][_spender] != 0)) {
           return false;
        }

        allowance[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);
        return true;
    }

     

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }
    
     
    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

     
    function burn(uint _amount) returns (bool result) {

        if (_amount > balanceOf[msg.sender])
            return false;        

         
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _amount);
        currentSupply = SafeMath.safeSub(currentSupply, _amount);

         
        result = esgAssetHolder.burn(msg.sender, _amount);
        require(result);

        Burn(msg.sender, _amount);
    }

     

    ESGAssetHolder esgAssetHolder;               
    bool lockedAssetHolder;                      

    function lockAssetHolder() onlyOwner {       
        lockedAssetHolder = true;
    }

    function setAssetHolder(address _assetAdress) onlyOwner {    
        assert(!lockedAssetHolder);              
        esgAssetHolder = ESGAssetHolder(_assetAdress);
    }    
}