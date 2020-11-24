 

pragma solidity ^0.4.18;

 

contract OBS_V1{
 
	address public owner;  
    mapping(address => address)    public tokens2owners;         
    mapping(address => address []) public owners2tokens;         
    mapping(address => address)    public tmpAddr2contractAddr;  
    
     
    event evntCreateContract(address _addrTmp,
                             address _addrToken,
                             address _owner,
                             address _addrBroker,
                             uint256 _supply,
                             string   _name
                            ); 
     
	function OBS_V1() public{
		owner = msg.sender;
	}
    
     
    function createContract (address _owner,
                            address _addrTmp, 
                            uint256 _supply,
                            string   _name) public{
         
        if (owner != msg.sender) revert();

         
        address addrToken = new MyObs( _owner, _supply, _name, "", 0, msg.sender);

         
        tokens2owners[addrToken]       = _owner;	
		owners2tokens[_owner].push(addrToken);
        tmpAddr2contractAddr[_addrTmp] = addrToken;
        
         
        evntCreateContract(_addrTmp, addrToken, _owner, msg.sender, _supply, _name); 
    }    
}

contract MyObs{ 

     
    address public addrOwner;            
    address public addrFabricContract;   
    address public addrBroker;           

     
    string public  name;                 
    string public  symbol;               
    uint8  public  decimals;             
    uint256 public supply;               

     
    mapping (address => uint256) public balances; 

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    
     
    function MyObs( address _owner, uint256 _supply, string _name, string _symbol, uint8 _decimals, address _addrBroker) public{
        if (_supply == 0) revert();
        
         
        addrOwner          = _owner;       
        addrFabricContract = msg.sender;   
        addrBroker         = _addrBroker;  

         
        balances[_owner]   = _supply;

         
        name     = _name;     
        symbol   = _symbol;
        decimals = _decimals;
        supply   = _supply;
    }

    function totalSupply() public constant returns (uint256) {
        return supply;
    }

    function balanceOf(address _owner)public constant returns (uint256) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value)public returns (bool) {
         
        if (balances[msg.sender] < _value) return false;
        if (balances[_to] + _value < balances[_to]) return false;
        
         
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        
         
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom( address _from, address _to, uint256 _value )public returns (bool) {
         
        if (addrBroker != msg.sender) return false;
        
         
        if (balances[_from] < _value) return false;
        if (balances[_to] + _value < balances[_to]) return false;
        
         
        balances[_from] -= _value;
        balances[_to] += _value;
        
         
        Transfer(_from, _to, _value);
        return true;
    }
}