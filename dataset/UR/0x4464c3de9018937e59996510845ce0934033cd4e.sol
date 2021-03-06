 

pragma solidity ^0.4.16;

 
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}
contract EthPredict is SafeMath{
    string public name;
    string public symbol;
    address public owner;
    uint8 public decimals;
    uint256 public totalSupply;
    address public icoContractAddress;
    uint256 public  tokensTotalSupply =  1000 * (10**6) * 10**18;
    mapping (address => bool) restrictedAddresses;
    uint256 constant initialSupply = 100 * (10**6) * 10**18;
    string constant  tokenName = 'EthPredictToken';
    uint8 constant decimalUnits = 18;
    string constant tokenSymbol = 'EPT';


     
    mapping (address => uint256) public balanceOf;
	  mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

	 
    event Freeze(address indexed from, uint256 value);

	 
    event Unfreeze(address indexed from, uint256 value);
   
    event Mint(address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    modifier onlyOwner {
      assert(owner == msg.sender);
      _;
    }

     
    function EthPredict() {
        balanceOf[msg.sender] = initialSupply;               
        totalSupply = initialSupply;                         
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimalUnits;                             
		    owner = msg.sender;
    }

     
    function transfer(address _to, uint256 _value) {                             
		    require (_value > 0) ;
        require (balanceOf[msg.sender] >= _value);            
        require (balanceOf[_to] + _value >= balanceOf[_to]) ;      
        require (!restrictedAddresses[_to]);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             
        Transfer(msg.sender, _to, _value);                    
    }

     
    function approve(address _spender, uint256 _value)
        returns (bool success) {
          allowance[msg.sender][_spender] = _value;           
      		Approval(msg.sender, _spender, _value);              
      		return true;
    }

    function mintTokens(address _to, uint256 _amount) {
      require (msg.sender == icoContractAddress);			 
      require (_amount != 0 ) ;    
      require (balanceOf[_to] + _amount > balanceOf[_to]) ; 
      require (totalSupply <=tokensTotalSupply);
       
      totalSupply += _amount;                                       
      balanceOf[_to] += _amount;                    		     
      Mint(_to, _amount);                          		     
      Transfer(0x0, _to, _amount);                             
    }

    function prodTokens(address _to, uint256 _amount)
    onlyOwner {
      require (_amount != 0 ) ;    
      require (balanceOf[_to] + _amount > balanceOf[_to]) ;      
      require (totalSupply <=tokensTotalSupply);
       
      totalSupply += _amount;                                       
      balanceOf[_to] += _amount;                    		     
      Mint(_to, _amount);                          		     
      Transfer(0x0, _to, _amount);                             
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require (balanceOf[_from] >= _value);                  
        require (balanceOf[_to] + _value >= balanceOf[_to]) ;   
        require (_value <= allowance[_from][msg.sender]) ;      
        require (!restrictedAddresses[_to]);
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                            
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                              
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) returns (bool success) {
        require (balanceOf[msg.sender] >= _value) ;             
		    require (_value <= 0) ;
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                       
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                 
        Burn(msg.sender, _value);
        return true;
    }

	function freeze(uint256 _value) returns (bool success) {
        require (balanceOf[msg.sender] >= _value) ;             
		    require (_value > 0) ;
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                       
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                 
        Freeze(msg.sender, _value);
        return true;
    }

	function unfreeze(uint256 _value) returns (bool success) {
        require (balanceOf[msg.sender] >= _value) ;             
        require (_value > 0) ;
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                       
		    balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        Unfreeze(msg.sender, _value);
        return true;
    }

	 
	function withdrawEther(uint256 amount)
  onlyOwner {
		owner.transfer(amount);
	}

  function totalSupply() constant returns (uint256 Supply) {
		return totalSupply;
	}

	 
	function balanceOf(address _owner) constant returns (uint256 balance) {
		return balanceOf[_owner];
	}

	 
	function() payable {
    }

  function changeICOAddress(address _newAddress) onlyOwner{
  		icoContractAddress = _newAddress;
  	}
     
	function editRestrictedAddress(address _newRestrictedAddress) onlyOwner {
		restrictedAddresses[_newRestrictedAddress] = !restrictedAddresses[_newRestrictedAddress];
	}

	function isRestrictedAddress(address _querryAddress) constant returns (bool answer){
		return restrictedAddresses[_querryAddress];
	}
}