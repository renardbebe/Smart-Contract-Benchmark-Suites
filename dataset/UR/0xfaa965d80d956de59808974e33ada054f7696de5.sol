 

pragma solidity ^0.5.6;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b != 0);
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    address public authorizedCaller;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
        authorizedCaller = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyAuthorized() {
        require(msg.sender == owner || msg.sender == authorizedCaller);
        _;
    }
    function transferAuthorizedCaller(address _newAuthorizedCaller) public onlyOwner {
        require(_newAuthorizedCaller != address(0));
        authorizedCaller = _newAuthorizedCaller;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _tokenOwner) public view returns (uint);

    function transfer(address _to, uint _amount) public returns (bool);

    function transferFrom(address _from, address _to, uint _amount) public returns (bool);

    function allowance(address _tokenOwner, address _spender) public view returns (uint);

    function approve(address _spender, uint _amount) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract BTourToken is ERC20, Ownable {
    using SafeMath for uint256;

    uint8 public constant decimals = 18;
    uint256 public constant _totalSupply = 2 * (10 ** 9) * (10 ** uint256(decimals));
    string public constant name = "BTour Chain";
    string public constant symbol = "BTOUR";

    bool public isPayable = true;
    bool public isHalted = false;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => bool) public locked;

    constructor() public {
        balances[msg.sender] = _totalSupply;
    }

    modifier checkHalted() {
        require(isHalted == false);
        _;
    }

    function() external payable {
        if (isPayable == false || isHalted == true) {
            revert();
        }
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function sendFeeCurrency(address payable _receiver, uint256 _amount) external payable onlyAuthorized returns (bool) {
        if (isPayable == false) {
            revert();
        }

        _receiver.transfer(_amount);
        return true;
    }

    function setIsPayable(bool p) external onlyAuthorized {
        isPayable = p;
    }

    function setHalted(bool _isHalted) external onlyOwner {
        isHalted = _isHalted;
    }

    function setLock(address _addr, bool _lock) external onlyAuthorized {
        locked[_addr] = _lock;
    }

    function balanceOf(address _tokenOwner) public view returns (uint) {
        return balances[_tokenOwner];
    }

    function transfer(address _to, uint _amount) public checkHalted returns (bool) {
        if (msg.sender != owner) {
            require(locked[msg.sender] == false && locked[_to] == false);
        }
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint _amount) public checkHalted returns (bool) {
        if (msg.sender != owner) {
            require(locked[msg.sender] == false && locked[_from] == false && locked[_to] == false);
        }
        require(_amount <= balances[_from]);
        if (_from != msg.sender) {
            require(_amount <= allowed[_from][msg.sender]);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        }
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function allowance(address _tokenOwner, address _spender) public view returns (uint) {
        return allowed[_tokenOwner][_spender];
    }

    function approve(address _spender, uint _amount) public checkHalted returns (bool) {
        require(locked[_spender] == false && locked[msg.sender] == false);

        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
}