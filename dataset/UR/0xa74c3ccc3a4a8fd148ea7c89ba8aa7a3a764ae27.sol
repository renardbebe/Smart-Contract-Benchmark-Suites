 

pragma solidity >=0.4.22 <0.6.0;

contract owned {
    address  public owner;
    address  public manager;
    address  public checker;
    address  public admin;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyManager {
        require(msg.sender == manager);
        _;
    }

    modifier onlyChecker {
        require(msg.sender == checker);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    function transferOwnership(address  newOwner) onlyOwner public {
        owner = newOwner;
    }

    function setManager(address  newManager) onlyManager public {
        manager = newManager;
    }

    function setChecker(address  newChecker) onlyChecker public {
        checker = newChecker;
    }

    function setAdmin(address  newAdmin) onlyAdmin public {
        admin = newAdmin;
    }

}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenSTP {

    string public name = "ABC GROUP";
    string public detail = "ABC Company Limited";
    string public website = "https://abc.co.th";
    string public symbol ="CMG";
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;
    uint256 public supplyLimit = 0;
    uint256 public newSupplyLimitReq = 0;
    uint256 public newSupplyLimitApprove = 0;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);

    constructor() public {
        supplyLimit = 300000000 * 10 ** uint256(decimals);
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value); 
        balanceOf[msg.sender] -= _value;   
        totalSupply -= _value;       
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value); 
        require(_value <= allowance[_from][msg.sender]); 
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value; 
        emit Burn(_from, _value);
        return true;
    }
}

contract ABCToken is owned, TokenSTP {
    address public appAddress;
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);

    constructor() public {}


    function setAppAddress(address _appAddress) onlyOwner public {
        appAddress = _appAddress;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != address(0x0)); 
        require (balanceOf[_from] >= _value); 
        require (balanceOf[_to] + _value >= balanceOf[_to]); 
        require(!frozenAccount[_from]); 
        require(!frozenAccount[_to]); 
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        require (supplyLimit >= totalSupply+mintedAmount); 
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function reqIncSupply(uint _incSupply) onlyManager public {
        require( newSupplyLimitReq==0);
        newSupplyLimitReq = supplyLimit+(_incSupply * 10 ** uint256(decimals));
    }

    function checkIncSupply() onlyChecker public {
        require( newSupplyLimitReq!=0 && newSupplyLimitApprove == 0);
        newSupplyLimitApprove = newSupplyLimitReq;
        newSupplyLimitReq = 0;
    }

    function confirmIncSupply() onlyAdmin public {
        require( newSupplyLimitReq!=0 && newSupplyLimitApprove == 0);
        supplyLimit = newSupplyLimitApprove;
        newSupplyLimitApprove = 0;
    }
}