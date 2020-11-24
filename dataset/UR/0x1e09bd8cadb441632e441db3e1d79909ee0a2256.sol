 

pragma solidity ^0.4.18;
 

 
library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}
 
contract ERC20TokenInterface {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    }


 
contract admined {  
    address public admin;  
    bool public lockSupply;  
    bool public lockTransfer;  
    address public allowedAddress;  

     
    function admined() internal {
        admin = msg.sender;  
        Admined(admin);
    }

    
    function setAllowedAddress(address _to) public {
        allowedAddress = _to;
        AllowedSet(_to);
    }

    modifier onlyAdmin() {  
        require(msg.sender == admin);
        _;
    }

    modifier supplyLock() {  
        require(lockSupply == false);
        _;
    }

    modifier transferLock() {  
        require(lockTransfer == false || allowedAddress == msg.sender);
        _;
    }

    
    function transferAdminship(address _newAdmin) onlyAdmin public {  
        admin = _newAdmin;
        TransferAdminship(admin);
    }

    
    function setSupplyLock(bool _set) onlyAdmin public {  
        lockSupply = _set;
        SetSupplyLock(_set);
    }

    
    function setTransferLock(bool _set) onlyAdmin public {  
        lockTransfer = _set;
        SetTransferLock(_set);
    }

     
    event AllowedSet(address _to);
    event SetSupplyLock(bool _set);
    event SetTransferLock(bool _set);
    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}

 
contract ERC20Token is ERC20TokenInterface, admined {  
    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping (address => uint256) balances;  
    mapping (address => mapping (address => uint256)) allowed;  
    mapping (address => bool) frozen;  

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
      return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) transferLock public returns (bool success) {
        require(_to != address(0));  
        require(balances[msg.sender] >= _value);
        require(frozen[msg.sender]==false);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) transferLock public returns (bool success) {
        require(_to != address(0));  
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        require(frozen[_from]==false);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
      allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
    }

     
    function mintToken(address _target, uint256 _mintedAmount) onlyAdmin supplyLock public {
        balances[_target] = SafeMath.add(balances[_target], _mintedAmount);
        totalSupply = SafeMath.add(totalSupply, _mintedAmount);
        Transfer(0, this, _mintedAmount);
        Transfer(this, _target, _mintedAmount);
    }

     
    function burnToken(address _target, uint256 _burnedAmount) onlyAdmin supplyLock public {
        balances[_target] = SafeMath.sub(balances[_target], _burnedAmount);
        totalSupply = SafeMath.sub(totalSupply, _burnedAmount);
        Burned(_target, _burnedAmount);
    }

     
    function setFrozen(address _target,bool _flag) onlyAdmin public {
        frozen[_target]=_flag;
        FrozenStatus(_target,_flag);
    }


     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burned(address indexed _target, uint256 _value);
    event FrozenStatus(address _target,bool _flag);
}

 
contract Asset is ERC20Token {
    string public name = 'Digital Safe Coin';
    uint8 public decimals = 1;
    string public symbol = 'DSC';
    string public version = '1';

    function Asset() public {

        totalSupply = 500000000 * (10**uint256(decimals));           
         
         
        balances[msg.sender] = 300000000 * (10**uint256(decimals));  
         
        balances[0x9caC17210aAc675E39b7fd6B9182eF5eBe724EC8] = 100000000 * (10**uint256(decimals)); 
         
        balances[0x3B41bFA39241CDF7afeF807087774e27fd01a1b2] = 50000000 * (10**uint256(decimals)); 
         
        balances[0xBa52E579C7296A6B45D724CD8163966eEdC5997a] = 49500000 * (10**uint256(decimals)); 
        balances[0xFAB6368b0F7be60c573a6562d82469B5ED9e7eE6] = 500000 * (10**uint256(decimals));   
        
        Transfer(0, this, totalSupply);
        Transfer(this, msg.sender, balances[msg.sender]);
        Transfer(this, 0x9caC17210aAc675E39b7fd6B9182eF5eBe724EC8, balances[0x9caC17210aAc675E39b7fd6B9182eF5eBe724EC8]);
        Transfer(this, 0x3B41bFA39241CDF7afeF807087774e27fd01a1b2, balances[0x3B41bFA39241CDF7afeF807087774e27fd01a1b2]);
        Transfer(this, 0xBa52E579C7296A6B45D724CD8163966eEdC5997a, balances[0xBa52E579C7296A6B45D724CD8163966eEdC5997a]);
        Transfer(this, 0xFAB6368b0F7be60c573a6562d82469B5ED9e7eE6, balances[0xFAB6368b0F7be60c573a6562d82469B5ED9e7eE6]);
    }
    
     
    function() public {
        revert();
    }

}