 

 
pragma solidity ^0.4.18;
contract metahashtoken {

     
    string public name;              
    string public symbol;            
    uint8  public decimals;          
    uint   public totalTokens;       
    uint   public finalyze;

     
    address public ownerContract;    
    address public owner;            
    
     
    mapping (address => uint256) public balance;                 
    mapping (address => mapping (address => uint256)) allowed;     
    
     
    event Burn(address indexed from, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
     
    function totalSupply() public constant returns (uint256 _totalSupply){
        return totalTokens;
    }
    
     
    function balanceOf(address _owner) public constant returns (uint256 _balance){
        return balance[_owner];
    }
    
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        address addrSender;
        if (msg.sender == ownerContract){
             
            addrSender = ownerContract;
        } else {
             
            addrSender = msg.sender;
        }
        
         
        if (balance[addrSender] < _value){
            revert();
        }
        
         
        if ((balance[_to] + _value) < balance[_to]){
            revert();
        }
        balance[addrSender] -= _value;
        balance[_to] += _value;
        
        Transfer(addrSender, _to, _value);  
        return true;
    }
    
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        var _allowance = allowed[_from][msg.sender];
        
         
        if (_allowance < _value){
            revert();
        }
        
         
        if (balance[_from] < _value){
            revert();
        }
        balance[_to] += _value;
        balance[_from] -= _value;
        allowed[_from][msg.sender] = _allowance - _value;
        Transfer(_from, _to, _value);
        return true;
    }
    
     
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
     
    function metahashtoken() public {
        name = 'BITCOMO';
        symbol = 'BM';
        decimals = 2;
        owner = msg.sender;
        totalTokens = 0;  
        finalyze = 0;
    }
    
     
    function setContract(address _ownerContract) public {
        if (msg.sender == owner){
            ownerContract = _ownerContract;
        }
    }
    
    function setOptions(uint256 tokenCreate) public {
         
        if ((msg.sender == ownerContract) && (finalyze == 0)){
            totalTokens += tokenCreate;
            balance[ownerContract] += tokenCreate;
        } else {
            revert();
        }
    }
    
    function burn(uint256 _value) public returns (bool success) {
        if (balance[msg.sender] <= _value){
            revert();
        }

        balance[msg.sender] -= _value;
        totalTokens -= _value;
        Burn(msg.sender, _value);
        return true;
    }
    
     
    function finalyzeContract() public {
        if (msg.sender != owner){
            revert();
        }
        finalyze = 1;
    }

}