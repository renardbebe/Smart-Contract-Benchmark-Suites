 

pragma solidity ^0.5.2;

 

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

contract ERC223Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value, bytes calldata data) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ReentrancyGuard {
    using SafeMath for uint256;
    uint256 private _guardCounter;

    constructor () internal {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter = _guardCounter.add(1);
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

contract ERC223ReceivingContract { 
   
    function tokenFallback(address _from, uint256 _value, bytes memory _data) public;
}

contract wwwTROYgold is ERC223Interface {
    using SafeMath for uint256;

    address private _owner; 

    string  public  constant name = "www.TROY.gold";
    string  public  constant symbol = "GOLD";
    uint8   public  constant decimals = 18;
    uint256 private constant _totalSupply = 27000000 * (uint256(10) ** decimals);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    constructor() public {
        _owner = msg.sender;
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return _balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(to != address(0));
        require(value > 0 && balanceOf(msg.sender) >= value);
        require(balanceOf(to).add(value) > balanceOf(to));

        uint256 codeLength;
        bytes memory empty;

        assembly {
            codeLength := extcodesize(to)
        }

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);

        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
            receiver.tokenFallback(msg.sender, value, empty);
        }

        emit Transfer(msg.sender, to, value, empty);
        return true;
    }

    function transfer(address to, uint256 value, bytes memory data) public returns (bool success) {
        require(to != address(0));
        require(value > 0 && balanceOf(msg.sender) >= value);
        require(balanceOf(to).add(value) > balanceOf(to));

        uint256 codeLength;

        assembly {
            codeLength := extcodesize(to)
        }

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);

        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
            receiver.tokenFallback(msg.sender, value, data);
        }

        emit Transfer(msg.sender, to, value, data);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(to != address(0));
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool success) {
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool success) {
        uint256 oldValue = _allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            _allowed[msg.sender][spender] = 0;
        } else {
            _allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function unlockERC20Tokens(address tokenAddress, uint256 tokens) public returns (bool success) {
        require(msg.sender == _owner);
        return ERC223Interface(tokenAddress).transfer(_owner, tokens);
    }

    function () external payable {
        revert("This contract does not accept ETH");
    }

}

contract ERC223Contract is ReentrancyGuard {
    using SafeMath for uint256;

    ERC223Interface private token;

    function getBlockNumber() public view returns (uint256) {
        return block.number;
    }

    function getData() public pure returns (bytes memory) {
        return msg.data;
    }

    function getSignature() public pure returns (bytes4) {
        return msg.sig;
    }

    function () external {

      revert();
    }

    function tokenFallback(address player, uint tokens, bytes memory data) public nonReentrant {
        emit TROYgold(player, tokens, data);
    }

    event Created(string, uint);
    event TROYgold(address from, uint value, bytes data);
}