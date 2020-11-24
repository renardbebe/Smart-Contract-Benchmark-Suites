 

pragma solidity  0.4 .21;

 
 
 
 

 
 
contract Token {
     
      
    function totalSupply() constant returns(uint256 initialSupply);

     
    function balanceOf(address _owner) constant returns(uint256 balance);

     
    function transfer(address _to, uint256 _value) returns(bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) returns(bool success);

     
     
     
    function approve(address _spender, uint256 _value) returns(bool success);

     
    function allowance(address _owner, address _spender) constant returns(uint256 remaining);

   

     
        event Burn(address indexed from, uint256 value);


     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract AssetToken is Token {
    string public  symbol;
    string public  name;
    uint8 public  decimals;
    uint256 _totalSupply;
    address public centralAdmin;
        uint256 public soldToken;



     
    address public owner;

     
    mapping(address => uint256) balances;

     
    mapping(address => mapping(address => uint256)) allowed;

     
   modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }


     
    function AssetToken(uint256 totalSupply,string tokenName,uint8 decimalUnits,string tokenSymbol,address centralAdmin) {
           soldToken = 0;

        if(centralAdmin != 0)
            owner = centralAdmin;
        else
        owner = msg.sender;
        balances[owner] = totalSupply;
        symbol = tokenSymbol;
        name = tokenName;
        decimals = decimalUnits;
        _totalSupply = totalSupply ;
    }
  function transferAdminship(address newAdmin) onlyOwner {
        owner = newAdmin;
    }
    function totalSupply() constant returns(uint256 initialSupply) {
        initialSupply = _totalSupply;
    }

     
    function balanceOf(address _owner) constant returns(uint256 balance) {
        return balances[_owner];
    }

      
    function mintToken(address target, uint256 mintedAmount) onlyOwner{
        balances[target] += mintedAmount;
        _totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

     
    function transfer(address _to, uint256 _amount) returns(bool success) {
        if (balances[msg.sender] >= _amount &&
            _amount > 0 &&
            balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns(bool success) {
        if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 &&
            balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
     
function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   
        balances[msg.sender] -= _value;            
        _totalSupply -= _value;                      
        Burn(msg.sender, _value);
        return true;
    }
 
   function transferCrowdsale(address _to, uint256 _value){
        require(balances[msg.sender] > 0);
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);
         
        balances[msg.sender] -= _value;
        balances[_to] += _value;
         soldToken +=  _value;
        Transfer(msg.sender, _to, _value);
    }


     
     
    function approve(address _spender, uint256 _amount) returns(bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }
 

}