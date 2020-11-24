 

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

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
    
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

 
contract Ownable {
    address[2] private _owners = [address(0), address(0)];

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owners[0] = msg.sender;
        emit OwnershipTransferred(address(0), _owners[0]);
    }

     
    function owners() public view returns (address[2] memory) {
        return _owners;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        for (uint8 i = 0; i < _owners.length; i++) {
            if (_owners[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

     
    function renounceOwnership(uint8 i) public onlyOwner {
        require(i < _owners.length);
        emit OwnershipTransferred(_owners[i], address(0));
        _owners[i] = address(0);
    }

     
    function transferOwnership(address newOwner, uint8 i) public onlyOwner {
        _transferOwnership(newOwner, i);
    }

     
    function _transferOwnership(address newOwner, uint8 i) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owners[i], newOwner);
        _owners[i] = newOwner;
    }
}

 
contract BasicToken is ERC20, Ownable {
    mapping(address => bool) public frozens;
    
    event Frozen(address indexed _address, bool _value);
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(frozens[to] == false);
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(frozens[from] == false);
        return super.transferFrom(from, to, value);
    }
    
    function freeze(address[] memory _targets, bool _value) public onlyOwner {
        require(_targets.length > 0);
        require(_targets.length <= 255);
        
        for (uint8 i = 0; i < _targets.length; i++) {
            address addressElement = _targets[i];
            
            assert(addressElement != address(0));
            frozens[addressElement] = _value;
            emit Frozen(addressElement, _value);
        }
    }
}

contract UCToken is BasicToken {
    uint8 public constant DECIMALS = 18;
    string public name = "Unity Chain Token";
    string public symbol = "UCT";
    uint8 public decimals = DECIMALS;
    
    uint256 public constant INITIAL_FACTOR = (10 ** 6) * (10 ** uint256(DECIMALS));
    
    constructor() public {
        _mint(0x490657f65380fe9e47ab46671B9CE7d02a06dF40, 1500 * INITIAL_FACTOR);
        _mint(0xA0d5366E74E56Be39542BD6125897E30775C7bd8, 1500 * INITIAL_FACTOR);
        _mint(0xfdE4884AD60012b80c1E57cCf4526d38746899a0, 250 * INITIAL_FACTOR);
        _mint(0xf5Cfb87CAe4bC2D314D824De5B1B7a9F00Ef30Ee, 250 * INITIAL_FACTOR);
        _mint(0xDdb844341f70DC7FB45Ca27E26cB5a131823AE74, 1000 * INITIAL_FACTOR);
        
        _mint(0x93e307CaCC969A6506E53F5Cb279f23D325d563d, 470573904 * (10 ** uint256(DECIMALS)));
        _mint(0x2EAdc466b18bAb66369C52CF8F37DAf383F793a7, 29426096 * (10 ** uint256(DECIMALS)));
    }
}