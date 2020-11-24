 

pragma solidity ^0.4.24;

contract OCCC {
    
    string public name;
    string public symbol;
     
    uint256 public totalSupply;
     
    uint8 public decimals = 18;
    
     
    address private admin_add;
     
    uint private present_money=0;
    
     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowances;
    
     
    constructor(uint256 limit,string token_name,string token_symbol,uint8 token_decimals) public {
        admin_add=msg.sender;
        name=token_name;
        symbol=token_symbol;
        totalSupply=limit * 10 ** uint256(decimals);
        decimals=token_decimals;
        
        balanceOf[admin_add]=totalSupply;
    }
    
     
    function setPresentMoney (uint money) public{
        address opt_user=msg.sender;
        if(opt_user == admin_add){
            present_money = money;
        }
    }
    
     
    function approve(address _spender, uint256 value) public returns (bool success){
        allowances[msg.sender][_spender] = value;
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining){
        return allowances[_owner][_spender];
    }
    
     
    function adminSendMoneyToUser(address to,uint256 value) public{
        address opt_add=msg.sender;
        if(opt_add == admin_add){
            transferFrom(admin_add,to,value);
        }
    }
    
     
    function burnAccountMoeny(address add,uint256 value) public{
        address opt_add=msg.sender;
        require(opt_add == admin_add);
        require(balanceOf[add]>value);
        
        balanceOf[add]-=value;
        totalSupply -=value;
    }

    function transfer(address _to, uint256 _value) public returns (bool success){

        return _transferAct(msg.sender,_to,_value);
    }

     
    function transferFrom(address from,address to,uint256 value) public returns (bool success){
        
        require(value <= allowances[from][msg.sender]);      
        allowances[from][msg.sender] -= value;
        
        return _transferAct(from,to,value);
    }
    
    function _transferAct(address from,address to,uint256 value) public returns (bool success){
         
        require(to != 0x0);
         
        require(balanceOf[from] >= value);
         
        require(balanceOf[to] + value >= balanceOf[to]);
        
        uint previousBalances = balanceOf[from] + balanceOf[to];
        balanceOf[from] -= value;
        balanceOf[to] += value;
        
        emit Transfer(from,to,value);
        
        assert(balanceOf[from] + balanceOf[to] == previousBalances);
        return true;
    }
    
     
    function balanceOf(address _owner) public view returns(uint256 balance){
        return balanceOf[_owner];
    }

}