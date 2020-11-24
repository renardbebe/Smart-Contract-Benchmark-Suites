 

pragma solidity ^0.5.1;

contract Token {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Transfer_data( address indexed _to, uint256 _value,string data);
    event data_Marketplace(string data);

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

   function transfer_data( address _to,uint256 _value,string memory data) public returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[fundsWallet] += _value;
            emit Transfer_data(_to, _value, data);
            return true;
        } else { return false; }
    }
    
     function marketplace( string memory data) public returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= 1 && 1 > 0) {
            balances[msg.sender] -= 1;
            balances[fundsWallet] += 1;
            emit data_Marketplace(data);
            return true;
        } else { return false; }
    }
    
     


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function mybalance() public view returns (uint256 balance) {
        return balances[fundsWallet];
    }


    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;



     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'H1.0'; 
    uint256 public totalEthInWei;          
    address payable fundsWallet;            

     
     
    constructor () public {
        balances[msg.sender] = 1000000000000000000000;                
        totalSupply = 1000000000000000000000;                         
        name = "Kaus-0.0.1";                                    
        decimals = 0;                                                
        symbol = "KAUS";                                              
        fundsWallet = msg.sender;                                     
    }

   
    
}