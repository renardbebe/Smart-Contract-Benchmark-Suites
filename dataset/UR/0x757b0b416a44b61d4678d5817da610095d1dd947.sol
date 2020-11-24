 

pragma solidity ^0.4.18;

 
contract SafeMath {

    function safeMul(uint a, uint b)pure internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b)pure internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b)pure internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b)pure internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}

 
contract ERC20 {
    function balanceOf(address who) public view returns (uint);
    function allowance(address owner, address spender) public view returns (uint);
    function transfer(address to, uint value) public returns (bool ok);
    function transferFrom(address from, address to, uint value) public returns (bool ok);
    function approve(address spender, uint value) public returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract Ownable {
     
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public{
        require(newOwner != owner);
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract AddressHolder {
    address[] internal addresses;

    function inArray(address _addr) public view returns(bool){
        for(uint i = 0; i < addresses.length; i++){
            if(_addr == addresses[i]){
                return true;
            }
        }
        return false;
    }

    function addAddress(address _addr) public {
        addresses.push(_addr);
    }

    function showAddresses() public view returns(address[] ){
        return addresses;
    }

    function totalUsers() public view returns(uint count){
        return addresses.length;
    }
}

contract Freezable is Ownable{

     
    bool internal accountsFrozen;

     
    mapping (address => bool) internal admins;

     
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);

    constructor() public {
        admins[msg.sender] = true;
    }

    function freezeAccount(address target, bool freeze) onlyOwner public{
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function unFreezeAccount(address target) onlyOwner public{
        frozenAccount[target] = false;
        emit FrozenFunds(target, false);
    }
    
    function makeAdmin(address target, bool isAdmin) onlyOwner public{
        admins[target] = isAdmin;
    }

    function revokeAdmin(address target) onlyOwner public {
        admins[target] = false;
    }

    function freezeAll() onlyOwner public{
        accountsFrozen = true;
    }

    function unfreezeAll() onlyOwner public {
        accountsFrozen = false;
    }

    modifier isAdmin() {
        require(admins[msg.sender] == true);
        _;
    }
}

 
contract StandardToken is ERC20, SafeMath, Freezable, AddressHolder{

    event Burn(address indexed from, uint value);

     
    mapping(address => uint) balances;
    uint public totalSupply;

     
    mapping (address => mapping (address => uint)) internal allowed;
    
     
    function transfer(address _to, uint _value) 
    public
    returns (bool success)
    {
        require(_to != address(0));

         
        if(!inArray(_to)){
            addAddress(_to);
        }
        require(balances[msg.sender] >= _value);
        require(_value > 0);
        require(!frozenAccount[msg.sender]);
        require(!accountsFrozen || admins[msg.sender] == true);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value)
    public
    returns (bool success) 
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(!frozenAccount[msg.sender]);
        require(!accountsFrozen || admins[msg.sender] == true);

         
        if(!inArray(_to)){
            addAddress(_to);
        }

        uint _allowance = allowed[_from][msg.sender];
        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) 
    public
    returns (bool success)
    {
        require(_spender != address(0));

         
        if(!inArray(_spender)){
            addAddress(_spender);
        }
         
         
         
         
         
        require(_value == 0 || allowed[msg.sender][_spender] == 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
         
        if(!inArray(_spender)){
            addAddress(_spender);
        }
        allowed[msg.sender][_spender] = safeAdd(allowed[msg.sender][_spender], _addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = safeSub(oldValue, _subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function burn(address from, uint amount) onlyOwner public{
        require(balances[from] >= amount && amount > 0);
        balances[from] = safeSub(balances[from],amount);
        totalSupply = safeAdd(totalSupply, amount);
        emit Transfer(from, address(0), amount);
        emit Burn(from, amount);
    }

    function burn(uint amount) onlyOwner public {
        burn(msg.sender, amount);
    }
}

contract Geco is StandardToken {
    string public name;
    uint8 public decimals; 
    string public symbol;
    string public version = "1.0";
    uint totalEthInWei;

    constructor() public{
        decimals = 18;      
        totalSupply = 100000000 * 10 ** uint256(decimals);     
        balances[msg.sender] = totalSupply;      
        name = "GreenEminer";     
        symbol = "GECO";     

         
        addAddress(msg.sender);
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) 
    public
    returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }

     
    function() payable public{
        revert();
    }
}