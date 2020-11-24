 

pragma solidity ^0.4;


contract ERC20 {
   uint public totalSupply;
   function balanceOf(address _account) public constant returns (uint balance);
   function transfer(address _to, uint _value) public returns (bool success);
   function transferFrom(address _from, address _to, uint _value) public returns (bool success);
   function approve(address _spender, uint _value) public returns (bool success);
   function allowance(address _owner, address _spender) public constant returns (uint remaining);
   event Transfer(address indexed _from, address indexed _to, uint _value);
   event Approval(address indexed _owner, address indexed _spender, uint _value);
}


contract Token is ERC20 {

    mapping(address => uint256) public balances;

    
    mapping(address => uint256) public investBalances;

    mapping(address => mapping (address => uint)) allowed;

     
    uint256 public totalSupply;

     
    string public constant name = "MMS";
    string public constant symbol = "MMS";
    address public owner;
    address public owner2;
    address public owner3;
    uint public decimals = 18;

     
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == owner2 || msg.sender == owner3);
        _;
    }




    function Token() public {
        totalSupply = 10000000000000000000000000;
        owner = 0x1FC11ac635e89c228765f3e6aEe0970D9aFf2BF5;
        owner2 = 0x4AB9AA258369438bC146b26af02F6E3568009D92;
        balances[owner] = totalSupply;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != owner);
        balances[newOwner] = balances[owner];
        balances[owner] = 0;
        owner = newOwner;
    }

     
    function balanceOf(address _account) public constant returns (uint256 balance) {
    return balances[_account];
    }

  
    function transfer(address _to, uint _value) public  returns (bool success) {
        require(_to != 0x0);                                
        require(balances[msg.sender] >= _value);            
        balances[msg.sender] -= _value;                     
        balances[_to] += _value;                            
        Transfer(msg.sender, _to, _value);
    return true;
    }

    
    function transferFrom(address _from, address _to, uint256 _amount) public  returns(bool) {
        require(_amount <= allowed[_from][msg.sender]);
        if (balances[_from] >= _amount && _amount > 0) {
            balances[_from] -= _amount;
            balances[_to] += _amount;
            allowed[_from][msg.sender] -= _amount;
            Transfer(_from, _to, _amount);
            return true;
        }
        else {
            return false;
            }
    }

    function approve(address _spender, uint _value) public  returns (bool success){
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
    }

    function add_tokens(address _to, uint256 _amount) public onlyOwner {
        balances[owner] -= _amount;
        investBalances[_to] += _amount;
    }

     
    function transferToken_toBalance(address _user, uint256 _amount) public onlyOwner {
        investBalances[_user] -= _amount;
        balances[_user] += _amount;
    } 

     
    function transferToken_toInvestBalance(address _user, uint256 _amount) public onlyOwner {
        balances[_user] -= _amount;
        investBalances[_user] += _amount;
    }  


    function changeOwner3(address _owner3) public onlyOwner {
        owner3 = _owner3;
    }
}