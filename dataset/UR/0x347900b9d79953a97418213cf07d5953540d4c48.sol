 

pragma solidity ^0.5.2;
 
 
 
 
 
interface IVersioned {
    event AppendedData( string data, uint256 versionIndex );

     
    function() external;

     
    function appendData(string calldata _data) external returns (bool);

     
    function getVersionIndex() external view returns (uint count);
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

contract Ownable {

     
    address payable private _owner;
    
     
    address[] private _owners;

     
    address payable private _pendingOwner;

     
    mapping (address => mapping (address => bool)) internal allowed;

    event PendingTransfer( address indexed owner, address indexed pendingOwner );
    event OwnershipTransferred( address indexed previousOwner, address indexed newOwner );
    event Approval( address indexed owner, address indexed trustee );
    event RemovedApproval( address indexed owner, address indexed trustee );

     
    modifier onlyPendingOwner {
        require(isPendingOwner());
        _;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    constructor() public {
        _owner = msg.sender;
        _owners.push(_owner);
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function() external {}

     
    function owner() public view returns (address payable) {
        return _owner;
    }
    
     
    function owners() public view returns (address[] memory) {
        return _owners;
    }
    
     
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    
     
    function isPendingOwner() public view returns (bool) {
        return msg.sender == _pendingOwner;
    }

     
    function transferOwnership(address payable pendingOwner_) onlyOwner public {
        _pendingOwner = pendingOwner_;
        emit PendingTransfer(_owner, _pendingOwner);
    }


     
    function transferOwnershipFrom(address payable pendingOwner_) public {
        require(allowance(msg.sender));
        _pendingOwner = pendingOwner_;
        emit PendingTransfer(_owner, _pendingOwner);
    }

     
    function claimOwnership() onlyPendingOwner public {
        _owner = _pendingOwner;
        _owners.push(_owner);
        _pendingOwner = address(0);
        emit OwnershipTransferred(_owner, _pendingOwner);
    }

     
    function approve(address trustee) onlyOwner public returns (bool) {
        allowed[msg.sender][trustee] = true;
        emit Approval(msg.sender, trustee);
        return true;
    }

     
    function removeApproval(address trustee) onlyOwner public returns (bool) {
        allowed[msg.sender][trustee] = false;
        emit RemovedApproval(msg.sender, trustee);
        return true;
    }

     
    function allowance(address trustee) public view returns (bool) {
        return allowed[_owner][trustee];
    }
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

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract Versioned is IVersioned {

    string[] public data;
    
    event AppendedData( 
        string data, 
        uint256 versionIndex
    );

     
    function() external {}

     
    function appendData(string memory _data) public returns (bool) {
        return _appendData(_data);
    }
    
     
    function _appendData(string memory _data) internal returns (bool) {
        data.push(_data);
        emit AppendedData(_data, getVersionIndex());
        return true;
    }

     
    function getVersionIndex() public view returns (uint count) {
        return data.length - 1;
    }
}

contract vRC20 is ERC20, ERC20Detailed, Versioned, Ownable {

    constructor (
        uint256 supply,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public ERC20Detailed (name, symbol, decimals) {
        _mint(msg.sender, supply);
    }

     
    function appendData(string memory _data) public onlyOwner returns (bool) {
        return _appendData(_data);
    }
}