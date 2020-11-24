 

pragma solidity 0.5.9;
 

 
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

    function balanceOf(address _owner) public view returns (uint256 value);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    }

contract ApproveAndCallFallBack {
 
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
 
}

 
contract admined {  
    address public admin;  
    bool public lockSupply;  
    bool public lockTransfer;  
    address public allowedAddress;  

     
    constructor() internal {
        admin = 0x129e3B92f033d553E38599AD3aa9C45A2FACaF73;  
        emit Admined(admin);
    }

    
    function setAllowedAddress(address _to) onlyAdmin public {
        allowedAddress = _to;
        emit AllowedSet(_to);
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
        require(_newAdmin != address(0));
        admin = _newAdmin;
        emit TransferAdminship(admin);
    }

    
    function setSupplyLock(bool _set) onlyAdmin public {  
        lockSupply = _set;
        emit SetSupplyLock(_set);
    }

    
    function setTransferLock(bool _set) onlyAdmin public {  
        lockTransfer = _set;
        emit SetTransferLock(_set);
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

     
    function balanceOf(address _owner) public view returns (uint256 value) {
      return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) transferLock public returns (bool success) {
        require(_to != address(0));  
        require(frozen[msg.sender]==false);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) transferLock public returns (bool success) {
        require(_to != address(0));  
        require(frozen[_from]==false);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function approveAndCall(address spender, uint256 _value, bytes memory data) public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][spender] == 0));
        allowed[msg.sender][spender] = _value;
        emit Approval(msg.sender, spender, _value);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, _value, address(this), data);
        return true;
    }

     
    function mintToken(address _target, uint256 _mintedAmount) onlyAdmin supplyLock public {
        require(totalSupply.add(_mintedAmount) <= 1000000000 * (10 ** 2) );  
        balances[_target] = SafeMath.add(balances[_target], _mintedAmount);
        totalSupply = SafeMath.add(totalSupply, _mintedAmount);
        emit Transfer(address(0), _target, _mintedAmount);
    }

     
    function burnToken(uint256 _burnedAmount) onlyAdmin supplyLock public {
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _burnedAmount);
        totalSupply = SafeMath.sub(totalSupply, _burnedAmount);
        emit Burned(msg.sender, _burnedAmount);
    }

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burned(address indexed _target, uint256 _value);
}

 
contract Asset is ERC20Token {
    string public name = 'PGcoin';
    uint8 public decimals = 2;
    string public symbol = 'PGC';
    string public version = '2';

   constructor() public {
        totalSupply = 200000000 * (10 ** uint256(decimals));  
        balances[0x129e3B92f033d553E38599AD3aa9C45A2FACaF73] = totalSupply;

        emit Transfer(address(0), 0x129e3B92f033d553E38599AD3aa9C45A2FACaF73, balances[0x129e3B92f033d553E38599AD3aa9C45A2FACaF73]);
    }
    
     
    function() external {
        revert();
    }

}