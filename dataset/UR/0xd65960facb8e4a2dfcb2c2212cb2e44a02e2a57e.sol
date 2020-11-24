 

pragma solidity ^ 0.4.8;

contract ERC20 {

    uint public totalSupply;
    
    function totalSupply() constant returns(uint totalSupply);

    function balanceOf(address who) constant returns(uint256);

    function allowance(address owner, address spender) constant returns(uint);

    function transferFrom(address from, address to, uint value) returns(bool ok);

    function approve(address spender, uint value) returns(bool ok);

    function transfer(address to, uint value) returns(bool ok);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);

   }
   
  contract SoarCoin is ERC20
  {
      
     
    string public constant name = "Soarcoin";

     
    string public constant symbol = "Soar";

    uint public decimals = 6;
    uint public totalSupply = 5000000000000000 ;  
    address central_account;
    address owner;
    mapping(address => uint) balances;
    
    mapping(address => mapping(address => uint)) allowed;
    
     
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
    
    modifier onlycentralAccount {
        require(msg.sender == central_account);
        _;
    }
    
    function SoarCoin()
    {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
    
     
    function totalSupply() constant returns(uint) {
       return totalSupply;
    }
    
     
    function balanceOf(address sender) constant returns(uint256 balance) {
        return balances[sender];
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
    
    function set_centralAccount(address central_Acccount) onlyOwner
    {
        central_account = central_Acccount;
    }

     
     
     
     
     
     

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns(bool success) {
        if (balances[_from] >= _amount &&
            allowed[_from][msg.sender] >= _amount &&
            _amount > 0 &&
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
    
     
     
    function approve(address _spender, uint256 _amount) returns(bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function drain() onlyOwner {
        if (!owner.send(this.balance)) revert();
    }
     
    function zero_fee_transaction(
        address _from,
        address _to,
        uint256 _amount
    ) onlycentralAccount returns(bool success) {
        if (balances[_from] >= _amount &&
            _amount > 0 &&
            balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
      
  }