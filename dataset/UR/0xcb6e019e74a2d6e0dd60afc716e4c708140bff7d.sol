 

pragma solidity ^0.4.24;

contract AutoChainTokenCandyInface{

    function name() public constant returns (string );
    function  symbol() public constant returns (string );
    function  decimals()  public constant returns (uint8 );
     
    function  totalSupply()  public constant returns (uint256 );

     
    function  balanceOf(address _owner)  public constant returns (uint256 );

     
    function  transfer(address _to, uint256 _value) public returns (bool );

     
    function  transferFrom(address _from, address _to, uint256 _value) public returns   
    (bool );

     
    function  approve(address _spender, uint256 _value) public returns (bool );

     
    function  allowance(address _owner, address _spender) public constant returns 
    (uint256 );

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
}

contract AutoChainTokenCandy is AutoChainTokenCandyInface {

     
    uint256 private _localtotalSupply;		 
    string private _localname;                    
    uint8 private _localdecimals;                
    string private _localsymbol;                
    string private _localversion = '0.01';     

    address private _localowner;  

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;

    function  AutoChainTokenCandy() public {
        _localowner=msg.sender;		 
        balances[msg.sender] = 50000000000;  
        _localtotalSupply = 50000000000;          
        _localname = 'AutoChainTokenCandy';                    
        _localdecimals = 4;            
        _localsymbol = 'ATCx';              
        
    }

    function getOwner() constant public returns (address ){
        return _localowner;
    }

    function  name() constant public returns (string ){
    	return _localname;
    }
    function  decimals() public constant returns (uint8 ){
    	return _localdecimals;
    }
    function  symbol() public constant returns (string ){
    	return _localsymbol;
    }
    function  version() public constant returns (string ){
    	return _localversion;
    }
    function  totalSupply() public constant returns (uint256 ){
    	return _localtotalSupply;
    }
    function  transfer(address _to, uint256 _value) public returns (bool ) {
         
         
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        balances[msg.sender] -= _value; 
        balances[_to] += _value; 
        emit Transfer(msg.sender, _to, _value); 
        return true;
    }
    function  transferFrom(address _from, address _to, uint256 _value) public returns 
    (bool ) {
        require(balances[_from] >= _value &&  balances[_to] + _value > balances[_to] && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value; 
        balances[_from] -= _value;  
        allowed[_from][msg.sender] -= _value; 
        emit Transfer(_from, _to, _value); 
        return true;
    }
    function  balanceOf(address _owner) public constant returns (uint256 ) {
        return balances[_owner];
    }
    function  approve(address _spender, uint256 _value) public returns (bool )   
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function  allowance(address _owner, address _spender) public constant returns (uint256 ) {
        return allowed[_owner][_spender]; 
    }
}