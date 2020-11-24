 

pragma solidity ^0.4.19;

contract Token {

    function totalSupply() public constant returns (uint256 supply) {}

    function balanceOf(address _owner) public constant returns (uint256 balance) {}

    function transfer(address _to, uint256 _value) public returns (bool success) {}


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}


    function approve(address _spender, uint256 _value) public returns (bool success) {}


    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    
}

contract Owned{
    address public owner;
    function Owned(){
        owner = msg.sender;
    }
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;}

contract StandardToken is Token {

     
    function _transfer(address _from, address _to,uint256 _value) internal {
         
        require(_to != 0x0);
         
        require(balances[_from] >= _value);
         
        require(balances[_to] + _value > balances[_to]);

        uint256 previousBalances = balances[_from]+balances[_to];
         
        balances[_from] -= _value;
         
        balances[_to] += _value;
        Transfer(_from,_to,_value);
         
        assert(balances[_from] + balances[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
        
        _transfer(msg.sender,_to,_value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] -= _value;
        _transfer(_from,_to,_value);
        return true;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

 
 
 

contract XRTStandards is Owned,StandardToken
{

     

    function _transfer(address _from, address _to,uint256 _value) internal {
         
        require(_to != 0x0);
         
        require(balances[_from] >= _value);
         
        require(balances[_to] + _value > balances[_to]);
         
        balances[_from] -= _value;
         
        balances[_to] += _value;
        Transfer(_from,_to,_value);
    }

}

contract XRTToken is XRTStandards {

    uint256 public initialSupply;
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version; 
    uint256 public unitsOneEthCanBuy;      
    uint256 public totalEthInWei;          
    address public fundsWallet;            

     
     
    function XRTToken(uint256 _initialSupply, string t_name, string t_symbol,string t_version, uint8 decimalsUnits,uint256 OneEthValue) public {
        initialSupply = _initialSupply;
        decimals = decimalsUnits;                                                
        totalSupply = initialSupply*10**uint256(decimals);                         
        balances[msg.sender] = totalSupply;                
        name = t_name;                                    
        symbol = t_symbol;                                              
        unitsOneEthCanBuy = OneEthValue*10**uint256(decimals);                                    
        fundsWallet = msg.sender;
        version = t_version;                                  
    }

    function() payable{
        if (msg.value == 0) { return; }

        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        if (balances[fundsWallet] < amount) {
            return;
        }

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        Transfer(fundsWallet, msg.sender, amount);  

         
        fundsWallet.transfer(msg.value);                               
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
         
         
         
        if(approve(_spender,_value)){
            require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
            return true;
        }    
    }
}