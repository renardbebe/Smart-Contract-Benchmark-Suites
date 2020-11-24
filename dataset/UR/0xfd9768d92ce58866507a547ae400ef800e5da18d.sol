 

pragma solidity ^0.4.24;

 
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
contract Dcoin is SafeMath{
    string public name;
    string public symbol;
    address public owner;
    uint8 public decimals;
    uint256 public totalSupply;
    address public icoContractAddress;
    uint256 public  tokensTotalSupply =  2000 * (10**6) * 10**18;
    mapping (address => bool) restrictedAddresses;
    uint256 constant initialSupply = 2000 * (10**6) * 10**18;
    string constant  tokenName = 'Dcoin';
    uint8 constant decimalUnits = 18;
    string constant tokenSymbol = 'DGAS';


     
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

     
    constructor() public {
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimalUnits;                             
	    owner = msg.sender;
    }

     
    function transfer(address _to, uint256 _value) public {
		require (_value > 0) ;
        require (balanceOf[msg.sender] >= _value);            
        require (balanceOf[_to] + _value >= balanceOf[_to]) ;      
        require (!restrictedAddresses[_to]);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             
        emit Transfer(msg.sender, _to, _value);                    
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;           
      	emit Approval(msg.sender, _spender, _value);      
      	return true;
    }

    function prodTokens(address _to, uint256 _amount) public onlyOwner {
      require (_amount != 0 ) ;    
      require (balanceOf[_to] + _amount > balanceOf[_to]) ;      
      require (totalSupply <=tokensTotalSupply);
       
      totalSupply += _amount;                                       
      balanceOf[_to] += _amount;                    		     
      emit Mint(_to, _amount);                          		     
      emit Transfer(0x0, _to, _amount);                             
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require (balanceOf[_from] >= _value);                  
        require (balanceOf[_to] + _value >= balanceOf[_to]) ;   
        require (_value <= allowance[_from][msg.sender]) ;      
        require (!restrictedAddresses[_to]);
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                            
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                              
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] >= _value) ;             
		    require (_value <= 0) ;
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                       
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                 
        emit Burn(msg.sender, _value);
        return true;
    }

	function freeze(uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] >= _value) ;             
		    require (_value > 0) ;
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                       
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                 
        emit Freeze(msg.sender, _value);
        return true;
    }

	function unfreeze(uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] >= _value) ;             
        require (_value > 0) ;
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                       
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }

	 
	function withdrawEther(uint256 amount) public onlyOwner {
		owner.transfer(amount);
	}

  function totalSupply() public constant returns (uint256 Supply) {
		return totalSupply;
	}

	 
	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return balanceOf[_owner];
	}


	function() public payable {
    revert();
    }

     
	function editRestrictedAddress(address _newRestrictedAddress) public onlyOwner {
		restrictedAddresses[_newRestrictedAddress] = !restrictedAddresses[_newRestrictedAddress];
	}

	function isRestrictedAddress(address _querryAddress) public constant returns (bool answer){
		return restrictedAddresses[_querryAddress];
	}
}