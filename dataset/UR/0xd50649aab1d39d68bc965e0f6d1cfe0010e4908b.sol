 

pragma solidity ^0.4.24;
 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != owner);
        owner = newOwner;
    }
}





contract TokenERC20 is owned {
    using SafeMath for uint;
     
    string public name;
    string public symbol;
    uint8 public decimals = 8;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

     
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }

     
    function _transfer(address _from, address _to, uint _value)  internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    
     
    function burn(address addr, uint256 _value) onlyOwner public returns (bool success) {
        balanceOf[addr] = balanceOf[addr].sub(_value);             
        totalSupply = totalSupply.sub(_value);                       
        emit Burn(addr, _value);
        return true;
    }
}

    



contract TOSC is owned, TokenERC20 {
    using SafeMath for uint;
    mapping (address => bool) public frozenAddress;
    mapping (address => bool) percentLockedAddress;
    mapping (address => uint256) percentLockAvailable;

     
    event FrozenFunds(address target, bool frozen);
    event PercentLocked(address target, uint percentage, uint256 availableValue);
    event PercentLockRemoved(address target);
    

     
    constructor (
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}
    

    
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to].add(_value) >= balanceOf[_to]);  
        require(!frozenAddress[_from]);                      
        require(!frozenAddress[_to]);                        
        if(percentLockedAddress[_from] == true){
            require(_value <= percentLockAvailable[_from]);
            percentLockAvailable[_from] = percentLockAvailable[_from].sub(_value);
        }
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);                          
        balanceOf[_to] = balanceOf[_to].add(_value);                            
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
        emit Transfer(_from, _to, _value);
    }

     
     
     
    function freezeAddress(address target, bool freeze) onlyOwner public {
        frozenAddress[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
    
    function PercentLock(address target,uint percentage, uint256 available) onlyOwner public{
    
        percentLockedAddress[target] = true;
        percentLockAvailable[target] = available;
  
        emit PercentLocked(target, percentage, available);
    }
    
    function removePercentLock(address target)onlyOwner public{
        percentLockedAddress[target] = false;
        percentLockAvailable[target] = 0;
        emit PercentLockRemoved(target);
    }
    
    
    
    function sendTransfer(address _from, address _to, uint256 _value)onlyOwner external{
        _transfer(_from, _to, _value);
    }
  
    
    

    function getBalance(address addr) external view onlyOwner returns(uint256){
        return balanceOf[addr];
    }
    
    function getfrozenAddress(address addr) onlyOwner external view returns(bool){
        return frozenAddress[addr];
    }
    
    function getpercentLockedAccount(address addr) onlyOwner external view returns(bool){
        return percentLockedAddress[addr];
    }
    
    
    function getpercentLockAvailable(address addr) onlyOwner external view returns(uint256){
        return percentLockAvailable[addr];
    }

}