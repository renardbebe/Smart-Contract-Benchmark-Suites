 

pragma solidity ^0.4.24;

contract Token {

     
    function totalSupply() constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
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

contract AI42TOKEN is StandardToken {  

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'V1.2'; 
    uint256 public unitsOneEthCanBuy;      
    uint256 public totalEthInWei;          
    address public fundsWallet;            
    uint256 public AI42IndexValue;         
    uint256 public ETHUSDrate;             

     
     
    constructor () public AI42TOKEN() {
        balances[msg.sender] = 100000 * 1e18;                    
        totalSupply = 100000 * 1e18;                             
        name = "AI-42 INDEX Token";                              
        decimals = 18;                                           
        symbol = "AI42";                                         
        unitsOneEthCanBuy = 0.07326 * 1e18;                      
        fundsWallet = msg.sender;                                
        AI42IndexValue = 150032;                                 
        ETHUSDrate = 10992;                                      
    }

    function() public payable{
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy / 1e18;
        require(balances[fundsWallet] >= amount);

        balances[fundsWallet] = balances[fundsWallet] - amount ;
        balances[msg.sender] = balances[msg.sender] + amount ;

        emit Transfer(fundsWallet, msg.sender, amount);  

         
        fundsWallet.transfer(msg.value);                               
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success)  {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
    
     
    function setAI42IndexValue(uint256 x) public returns (bool) {
        require(msg.sender == fundsWallet);                      
        AI42IndexValue = x;
        return true;
    }
     
    function setETHUSDrate(uint256 x) public returns (bool) {
        require(msg.sender == fundsWallet);                      
        ETHUSDrate = x;
        return true;
    }
     
    function setunitsOneEthCanBuy(uint256 x) public returns (bool) {
        require(msg.sender == fundsWallet);                      
        unitsOneEthCanBuy = x;
        return true;
    }
     
    function getAI42IndexValue() public view returns (uint256) {
        return AI42IndexValue;
    }
     
    function getETHUSDrate() public view returns (uint256) {
        return ETHUSDrate;
    }
     
    function getunitsOneEthCanBuy() public view returns (uint256) {
        return unitsOneEthCanBuy;
    }
}