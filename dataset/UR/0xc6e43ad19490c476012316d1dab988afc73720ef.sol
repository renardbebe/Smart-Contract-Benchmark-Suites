 

pragma solidity 0.5.7;

 
library SafeMath {

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
}

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

}

 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 amount, address token, bytes calldata extraData) external;
}

 
contract BurnableToken is ERC20, Ownable {

      
     function burn(uint256 value) public onlyOwner {
         _burn(msg.sender, value);
     }

}

 
contract LockableToken is BurnableToken {

     
    bool private _started;

     
    mapping(address => Lock) private _locked;
    struct Lock {
        bool locked;
        Batch[] batches;
    }
    struct Batch {
        uint256 amount;
        uint256 time;
    }

     
    function lock(address[] calldata addresses, uint256[] calldata values, uint256[] calldata times) external onlyOwner {
        require(!_started);
        require(addresses.length == values.length && values.length == times.length);

        for (uint256 i = 0; i < addresses.length; i++) {
            require(balanceOf(addresses[i]) >= values[i]);

            if (!_locked[addresses[i]].locked) {
                _locked[addresses[i]].locked = true;
            }

            _locked[addresses[i]].batches.push(Batch(values[i], block.timestamp + times[i]));

            if (_locked[addresses[i]].batches.length > 1) {
                assert(
                    _locked[addresses[i]].batches[_locked[addresses[i]].batches.length - 1].amount
                    < _locked[addresses[i]].batches[_locked[addresses[i]].batches.length - 2].amount
                    &&
                    _locked[addresses[i]].batches[_locked[addresses[i]].batches.length - 1].time
                    > _locked[addresses[i]].batches[_locked[addresses[i]].batches.length - 2].time
                );
            }
        }

        _started = true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        if (_locked[from].locked) {
            for (uint256 i = 0; i < _locked[from].batches.length; i++) {
                if (block.timestamp <= _locked[from].batches[i].time) {
                    require(value <= balanceOf(from).sub(_locked[from].batches[i].amount));
                    break;
                }
            }
        }
        super._transfer(from, to, value);
    }

     
    function started() external view returns(bool) {
        return _started;
    }

}



 
contract DOMToken is LockableToken {

     
    string private _name = "Diamond Open Market";
     
    string private _symbol = "DOM";
     
    uint8 private _decimals = 18;

     
    uint256 public constant INITIAL_SUPPLY = 6000000000  * (10 ** 18);

     
    constructor(address recipient) public {

        _mint(recipient, INITIAL_SUPPLY);

    }

     
    function approveAndCall(address spender, uint256 amount, bytes calldata extraData) external returns (bool) {
        require(approve(spender, amount));

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, amount, address(this), extraData);

        return true;
    }

     
    function withdrawERC20(address ERC20Token, address recipient) external onlyOwner {

        uint256 amount = IERC20(ERC20Token).balanceOf(address(this));
        IERC20(ERC20Token).transfer(recipient, amount);

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