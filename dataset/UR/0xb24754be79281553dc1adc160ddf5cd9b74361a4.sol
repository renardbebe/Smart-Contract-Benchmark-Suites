 

pragma solidity ^0.4.11;
contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract ERC20 {
     
    string public standard = 'RIALTO 1.0';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public supply;

     
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

     
    function ERC20(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balances[msg.sender] = initialSupply;               
        supply = initialSupply;                         
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimalUnits;                             
    }


    function totalSupply() constant returns (uint totalSupply);
    function balanceOf(address _owner) constant returns (uint256 balance);


     
    function transfer(address _to, uint256 _value) returns (bool success);

  
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);


     
        function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
                return allowance[_owner][_spender];
        }

     
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }   
    }   
    
        
    function () {
        throw;      
    }   
}   
contract Rialto is owned, ERC20 {

    uint256 public lockPercentage = 15;

    uint256 public expiration = block.timestamp + 180 days;


     
    function Rialto(
        uint256 initialSupply,  
        string tokenName,  
        uint8 decimalUnits,  
        string tokenSymbol  
    ) ERC20 (initialSupply, tokenName, decimalUnits, tokenSymbol) {}

         
        function balanceOf(address _owner) constant returns (uint256 balance) {
                return balances[_owner];
        }

         
        function totalSupply() constant returns (uint256 totalSupply) {
                return supply;
        }

    function transferOwnership(address newOwner) onlyOwner {
        if(!transfer(newOwner, balances[msg.sender])) throw;
        owner = newOwner;
    }

     
    function transfer(address _to, uint256 _value) returns (bool success){


        if (balances[msg.sender] < _value) throw;            

        if (balances[_to] + _value < balances[_to]) throw;  

        if (msg.sender == owner && block.timestamp < expiration && (balances[msg.sender]-_value) < lockPercentage * supply / 100 ) throw;   

        balances[msg.sender] -= _value;                      
        balances[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
        return true;
    }


     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {


        if (balances[_from] < _value) throw;                  
        if (balances[_to] + _value < balances[_to]) throw;   
        if (_value > allowance[_from][msg.sender]) throw;    
        if (_from == owner && block.timestamp < expiration && (balances[_from]-_value) < lockPercentage * supply / 100) throw;  

        balances[_from] -= _value;                           
        balances[_to] += _value;                             
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }



  }