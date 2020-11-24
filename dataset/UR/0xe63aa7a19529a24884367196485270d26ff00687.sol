 

pragma solidity ^0.4.24;
 
contract SafeMath {

    function safeMul(uint256 a, uint256 b) pure internal returns (uint256) {
        uint256 c = a * b;
        judgement(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) pure internal returns (uint256) {
        judgement(b > 0);
        uint256 c = a / b;
        judgement(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) pure internal returns (uint256) {
        judgement(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) pure internal returns (uint256) {
        uint256 c = a + b;
        judgement(c>=a && c>=b);
        return c;
    }
    function safeMulWithPresent(uint256 a , uint256 b) pure internal returns (uint256){
        uint256 c = safeDiv(safeMul(a,b),100);
        judgement(b == (c*100)/a);
        return c;
    }
    function judgement(bool assertion) pure internal {
        if (!assertion) {
            revert();
        }
    }
}
contract BBZZXUCAuth{
    address public owner;
    constructor () public{
        owner = msg.sender;
    }
    event LogOwnerChanged (address msgSender );

     
    modifier onlyOwner{
        assert(msg.sender == owner);
        _;
    } 

    function setOwner (address newOwner) public onlyOwner returns (bool){
        if (owner == msg.sender){
            owner = newOwner;
            emit LogOwnerChanged(msg.sender);
            return true;
        }else{
            return false;
        }
    }

}
contract BBZZXUCStop is BBZZXUCAuth{
    bool internal stopped = false;

    modifier stoppable {
        assert (!stopped);
        _;
    }

    function _status() view public returns (bool){
        return stopped;
    }
    function stop() public onlyOwner{
        stopped = true;
    }
    function start() public onlyOwner{
        stopped = false;
    }

}
contract Token is SafeMath { 
     
    uint256 public totalSupply;                                  
     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) view public returns (uint256 remaining);

    function push(address _to,uint256 amount) public returns (bool);
     
    function burn(uint256 amount) public returns (bool);

    function mint(uint256 amount) public;

    function frozenCheck(address _from , address _to) view private returns (bool);

    function freezeAccount(address target , bool freeze) public;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn    (address indexed _owner , uint256 _value);
    event Minted  (uint256 amount);
}
contract StandardToken is Token ,BBZZXUCStop{

    function transfer(address _to, uint256 _value) stoppable public returns (bool ind) {
         
         
         
         
        require(frozenCheck(msg.sender,_to));
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender] , _value);
            balances[_to]  = safeAdd(balances[_to],_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) stoppable public returns (bool success) {
         
        require(frozenCheck(_from,_to));
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to]  = safeAdd(balances[_to],_value);
            balances[_from] = safeSub(balances[_from] , _value);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) stoppable public returns (bool success) {
        require(frozenCheck(_spender,msg.sender));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    function burn(uint256 amount) stoppable onlyOwner public returns (bool){
        if(balances[msg.sender] > amount ){
            balances[msg.sender] = safeSub(balances[msg.sender],amount);
            totalSupply = safeSub(totalSupply,amount);
            emit Burn(msg.sender,amount);
            return true;
        }else{
            return false;
        }
    }
    function push(address _to , uint256 amount) onlyOwner public returns (bool){          
        balances[_to] = safeAdd(balances[_to] ,amount);
        return true;
    }
    function mint(uint256 amount) onlyOwner public{
        totalSupply = safeAdd(totalSupply, amount);
        emit Minted(amount);
    }
    function frozenCheck(address _from , address _to) view private returns (bool){
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        return true;
    }
    function freezeAccount(address target , bool freeze) onlyOwner public{
        frozenAccount[target] = freeze;
    }

    mapping (address => uint256)                      private  balances;
    mapping (address => mapping (address => uint256)) private  allowed;
    mapping (address => bool)                         private  frozenAccount;     

}
contract BBZZXUCToken is StandardToken{

    string public name = "BBZZXUC";                                    
    uint256 public decimals = 18;                                  
    string public symbol = "BBZZXUC";                                  

    constructor() public {                     
        owner = msg.sender;
    }

    function () stoppable public {
        revert();
    }

}