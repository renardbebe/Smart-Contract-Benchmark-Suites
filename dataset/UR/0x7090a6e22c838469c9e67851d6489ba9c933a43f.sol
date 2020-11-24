 

pragma solidity ^0.5;

contract Token {

     
     
    function balanceOf(address _owner) view public returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value)  public returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}



contract StandardToken is Token {


    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public circulatingSupply;
}


 
contract ZuckBucks is StandardToken {
     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    address payable private owner;
    uint public totalSupply;

    uint256 public starting_giveaway;
    uint256 public next_giveaway;
    uint256 private giveaway_count;
    
    function () external payable {
         
        uint256 eth_val = msg.value;
        
        uint256 giveaway_value;

        giveaway_count++;

        giveaway_value = (((starting_giveaway / giveaway_count) + (starting_giveaway / (giveaway_count + 2))) * (10**18 + eth_val)) / 10**18;
        next_giveaway = (starting_giveaway / (giveaway_count + 1)) + (starting_giveaway / (giveaway_count + 3));


        balances[msg.sender] += giveaway_value;
        balances[owner] -= giveaway_value;
        circulatingSupply += giveaway_value;
        emit Transfer(owner, msg.sender, giveaway_value);
        
         
        owner.transfer(eth_val);
    }



    constructor() ZuckBucks (
        ) public {
        totalSupply = 1500000;                         
        balances[msg.sender] = totalSupply;                
        circulatingSupply = 0;
        name = "Zuck Bucks";                                    
        decimals = 0;                             
        symbol = "ZBUX";                                
        starting_giveaway = 50000;
        next_giveaway = 0;
        owner = msg.sender;
        giveaway_count = 0;
    }



}