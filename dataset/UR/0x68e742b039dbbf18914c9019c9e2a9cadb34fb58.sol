 

pragma solidity ^0.4.24;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert((c >= a) && (c >= b));
        return c;
    }
}

 
contract StandardToken {
    using SafeMath for uint256;

    string public name;  
    string public symbol;  
    uint8 public decimals;  
    uint256 public totalSupply;  
    string public version;  

     

     
    function transfer(address _to, uint256 _value)  returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) ;

     
    function approve(address _spender, uint256 _value) returns (bool success);

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) ;

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Owned {
     modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

   address public owner;

    constructor() public {
        owner = msg.sender;
    }

    address newOwner=0x0;

    event OwnerUpdate(address _prevOwner, address _newOwner);

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public{
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

contract Controlled is Owned {
    constructor() public {
        setExclude(msg.sender,true);
    }

    bool public transferEnabled = true;

    bool lockFlag=true;

    mapping(address => bool) locked;

    mapping(address => bool) exclude;

    function enableTransfer(bool _enable) public onlyOwner returns (bool success){
        transferEnabled=_enable;
		return true;
    }

    function disableLock(bool _enable) public onlyOwner returns (bool success){
        lockFlag=_enable;
        return true;
    }

    function addLock(address _addr) public onlyOwner returns (bool success){
        require(lockFlag == true);
        require(_addr != msg.sender);
        locked[_addr]=true;
        return true;
    }

    function setExclude(address _addr,bool _enable) public onlyOwner returns (bool success){
        exclude[_addr]=_enable;
        return true;
    }

    function removeLock(address _addr) public onlyOwner returns (bool success){
        locked[_addr]=false;
        return true;
    }

    modifier transferAllowed(address _addr) {
        if (!exclude[_addr]) {
            require(transferEnabled,"transfer is not enabeled now!");
            if(lockFlag){
                require(!locked[_addr],"you are locked!");
            }
        }
        _;
    }
}

contract DmToken is StandardToken,Controlled {
	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) internal allowed;

    constructor() public {
        totalSupply = 3000000 * 100000000;
        name = "Test Coin";
        symbol = "TEST";
        decimals = 8;
        version = "1.0";
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public transferAllowed(msg.sender) returns (bool success) {
		require(_to != address(0));
		require(_value <= balanceOf[msg.sender]);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public transferAllowed(_from) returns (bool success) {
        require(_to != address(0));
        require(_value <= balanceOf[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}