 

pragma solidity >=0.5.0 <0.6.0;

 
library SafeMathUint256 {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath: Multiplier exception");
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;  
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: Subtraction exception");
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath: Addition exception");
        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: Modulo exception");
        return a % b;
    }

}

 
library SafeMathUint8 {
     
    function mul(uint8 a, uint8 b) internal pure returns (uint8 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath: Multiplier exception");
        return c;
    }

     
    function div(uint8 a, uint8 b) internal pure returns (uint8) {
        return a / b;  
    }

     
    function sub(uint8 a, uint8 b) internal pure returns (uint8) {
        require(b <= a, "SafeMath: Subtraction exception");
        return a - b;
    }

     
    function add(uint8 a, uint8 b) internal pure returns (uint8 c) {
        c = a + b;
        require(c >= a, "SafeMath: Addition exception");
        return c;
    }

     
    function mod(uint8 a, uint8 b) internal pure returns (uint8) {
        require(b != 0, "SafeMath: Modulo exception");
        return a % b;
    }

}


contract Ownership {
    address payable public owner;
    address payable public pendingOwner;

    event OwnershipTransferred (address indexed from, address indexed to);

    constructor () public
    {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require (msg.sender == owner, "Ownership: Access denied");
        _;
    }

    function transferOwnership (address payable _pendingOwner) public
        onlyOwner
    {
        pendingOwner = _pendingOwner;
    }

    function acceptOwnership () public
    {
        require (msg.sender == pendingOwner, "Ownership: Only new owner is allowed");

        emit OwnershipTransferred (owner, pendingOwner);

        owner = pendingOwner;
        pendingOwner = address(0);
    }

}


 
contract Controllable is Ownership {

    bool public stopped;
    mapping (address => bool) public freezeAddresses;

    event Paused();
    event Resumed();

    event FreezeAddress(address indexed addressOf);
    event UnfreezeAddress(address indexed addressOf);

    modifier onlyActive(address _sender) {
        require(!freezeAddresses[_sender], "Controllable: Not active");
        _;
    }

    modifier isUsable {
        require(!stopped, "Controllable: Paused");
        _;
    }

    function pause () public
        onlyOwner
    {
        stopped = true;
        emit Paused ();
    }
    
    function resume () public
        onlyOwner
    {
        stopped = false;
        emit Resumed ();
    }

    function freezeAddress(address _addressOf) public
        onlyOwner
        returns (bool)
    {
        if (!freezeAddresses[_addressOf]) {
            freezeAddresses[_addressOf] = true;
            emit FreezeAddress(_addressOf);
        }

        return true;
    }
	
    function unfreezeAddress(address _addressOf) public
        onlyOwner
        returns (bool)
    {
        if (freezeAddresses[_addressOf]) {
            delete freezeAddresses[_addressOf];
            emit UnfreezeAddress(_addressOf);
        }

        return true;
    }

}


 
contract ERC20Basic {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic, Controllable {
    using SafeMathUint256 for uint256;

    mapping(address => uint256) balances;

    uint256 public totalSupply;

    constructor(uint256 _initialSupply) public
    {
        totalSupply = _initialSupply;

        if (0 < _initialSupply) {
            balances[msg.sender] = _initialSupply;
            emit Transfer(address(0), msg.sender, _initialSupply);
        }
    }

     
    function transfer(address _to, uint256 _value) public
        isUsable
        onlyActive(msg.sender)
        onlyActive(_to)
        returns (bool)
    {
        require(0 < _value, "BasicToken.transfer: Zero value");
        require(_value <= balances[msg.sender], "BasicToken.transfer: Insufficient fund");

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view
        returns (uint256 balance)
    {
        return balances[_owner];
    }

}


 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

     
    function transferFrom(address _from, address _to, uint256 _value) public
        isUsable
        onlyActive(msg.sender)
        onlyActive(_from)
        onlyActive(_to)
        returns (bool)
    {
        require(0 < _value, "StandardToken.transferFrom: Zero value");
        require(_value <= balances[_from], "StandardToken.transferFrom: Insufficient fund");
        require(_value <= allowed[_from][msg.sender], "StandardToken.transferFrom: Insufficient allowance");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        isUsable
        onlyActive(msg.sender)
        onlyActive(_spender)
        returns (bool)
    {
        require(0 < _value, "StandardToken.approve: Zero value");

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint256 _addedValue) public
        isUsable
        onlyActive(msg.sender)
        onlyActive(_spender)
        returns (bool)
    {
        require(0 < _addedValue, "StandardToken.increaseApproval: Zero value");

        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue) public
        isUsable
        onlyActive(msg.sender)
        onlyActive(_spender)
        returns (bool)
    {
        require(0 < _subtractedValue, "StandardToken.decreaseApproval: Zero value");

        uint256 oldValue = allowed[msg.sender][_spender];

        if (_subtractedValue > oldValue)
            allowed[msg.sender][_spender] = 0;
        else
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}


contract ApprovalReceiver {
    function receiveApproval(address _from, uint256 _value, address _tokenContract, bytes calldata _extraData) external;
}

contract ETT is StandardToken {
    using SafeMathUint256 for uint256;

    bytes32 constant FREEZE_CODE_DEFAULT = 0x0000000000000000000000000000000000000000000000000000000000000000;

    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);

    event FreezeWithPurpose(address indexed from, uint256 value, bytes32 purpose);
    event UnfreezeWithPurpose(address indexed from, uint256 value, bytes32 purpose);

    string public name;
    string public symbol;
    uint8 public decimals;

     
    mapping (address => uint256) public freezeOf;
     
    mapping (address => mapping (bytes32 => uint256)) public freezes;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply) public
        BasicToken(_initialSupply)
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

     
    function freeze(address _from, uint256 _value) external
        onlyOwner
        returns (bool)
    {
        require(_value <= balances[_from], "StableCoin.freeze: Insufficient fund");

        balances[_from] = balances[_from].sub(_value);
        freezeOf[_from] = freezeOf[_from].add(_value);
        freezes[_from][FREEZE_CODE_DEFAULT] = freezes[_from][FREEZE_CODE_DEFAULT].add(_value);
        emit Freeze(_from, _value);
        emit FreezeWithPurpose(_from, _value, FREEZE_CODE_DEFAULT);
        return true;
    }
	
     
    function freezeWithPurpose(address _from, uint256 _value, string calldata _purpose) external
        returns (bool)
    {
        return freezeWithPurposeCode(_from, _value, encodePacked(_purpose));
    }
	
     
    function freezeWithPurposeCode(address _from, uint256 _value, bytes32 _purposeCode) public
        onlyOwner
        returns (bool)
    {
        require(_value <= balances[_from], "StableCoin.freezeWithPurposeCode: Insufficient fund");

        balances[_from] = balances[_from].sub(_value);
        freezeOf[_from] = freezeOf[_from].add(_value);
        freezes[_from][_purposeCode] = freezes[_from][_purposeCode].add(_value);
        emit Freeze(_from, _value);
        emit FreezeWithPurpose(_from, _value, _purposeCode);
        return true;
    }
	
     
    function unfreeze(address _from, uint256 _value) external
        onlyOwner
        returns (bool)
    {
        require(_value <= freezes[_from][FREEZE_CODE_DEFAULT], "StableCoin.unfreeze: Insufficient fund");

        freezeOf[_from] = freezeOf[_from].sub(_value);
        freezes[_from][FREEZE_CODE_DEFAULT] = freezes[_from][FREEZE_CODE_DEFAULT].sub(_value);
        balances[_from] = balances[_from].add(_value);
        emit Unfreeze(_from, _value);
        emit UnfreezeWithPurpose(_from, _value, FREEZE_CODE_DEFAULT);
        return true;
    }

     
    function unfreezeWithPurpose(address _from, uint256 _value, string calldata _purpose) external
        onlyOwner
        returns (bool)
    {
        return unfreezeWithPurposeCode(_from, _value, encodePacked(_purpose));
    }

     
    function unfreezeWithPurposeCode(address _from, uint256 _value, bytes32 _purposeCode) public
        onlyOwner
        returns (bool)
    {
        require(_value <= freezes[_from][_purposeCode], "StableCoin.unfreezeWithPurposeCode: Insufficient fund");

        freezeOf[_from] = freezeOf[_from].sub(_value);
        freezes[_from][_purposeCode] = freezes[_from][_purposeCode].sub(_value);
        balances[_from] = balances[_from].add(_value);
        emit Unfreeze(_from, _value);
        emit UnfreezeWithPurpose(_from, _value, _purposeCode);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes calldata _extraData) external
        isUsable
        returns (bool)
    {
         
        approve(_spender, _value);

        ApprovalReceiver(_spender).receiveApproval(msg.sender, _value, address(this), _extraData);
        return true;
    }

    function encodePacked(string memory s) internal pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(s));
    }

}