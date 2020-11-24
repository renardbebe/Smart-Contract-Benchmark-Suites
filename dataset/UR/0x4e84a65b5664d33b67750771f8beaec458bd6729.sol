 

pragma solidity 0.5.8;
 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
}

 
contract Owned {  
    address public owner;  
    bool public lockSupply;  

     
    constructor() internal {
        owner = 0xA0c6f96035d0FA5F44D781060F84A0Bc6B8D87Ee;  
        emit TransferOwnership(owner);
    }

    modifier onlyOwner() {  
        require(msg.sender == owner, "Not Allowed");
        _;
    }

    modifier supplyLock() {  
        require(lockSupply == false, "Supply is locked");
        _;
    }

     
    function transferAdminship(address _newOwner) public onlyOwner {  
        require(_newOwner != address(0), "Not allowed");
        owner = _newOwner;
        emit TransferOwnership(owner);
    }

     
    function setSupplyLock(bool _set) public onlyOwner {  
        lockSupply = _set;
        emit SetSupplyLock(lockSupply);
    }

     
    event SetSupplyLock(bool _set);
    event TransferOwnership(address indexed newAdminister);
}

 
contract ERC20TokenInterface {
    function balanceOf(address _owner) public view returns(uint256 value);
    function transfer(address _to, uint256 _value) public returns(bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success);
    function approve(address _spender, uint256 _value) public returns(bool success);
    function allowance(address _owner, address _spender) public view returns(uint256 remaining);
}

 
contract ERC20Token is Owned, ERC20TokenInterface {
    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping(address => uint256) balances;  
    mapping(address => mapping(address => uint256)) allowed;  

     
    function balanceOf(address _owner) public view returns(uint256 value) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public returns(bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns(bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function burnTokens(uint256 _value) public onlyOwner {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);

        emit Transfer(msg.sender, address(0), _value);
        emit Burned(msg.sender, _value);
    }

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burned(address indexed _target, uint256 _value);
}

 
contract Asset is ERC20Token {
    string public name = 'Orionix';
    uint8 public decimals = 18;
    string public symbol = 'ORX';
    string public version = '2';

    constructor() public {
        totalSupply = 600000000 * (10 ** uint256(decimals));  
        balances[0xA0c6f96035d0FA5F44D781060F84A0Bc6B8D87Ee] = totalSupply;
        emit Transfer(
            address(0),
            0xA0c6f96035d0FA5F44D781060F84A0Bc6B8D87Ee,
            balances[0xA0c6f96035d0FA5F44D781060F84A0Bc6B8D87Ee]);
    }

     
    function () external {
        revert("This contract cannot receive direct payments or fallback calls");
    }

}