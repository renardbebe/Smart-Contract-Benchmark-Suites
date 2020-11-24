 

 

pragma solidity ^0.5.0;

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.0;


 
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

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity ^0.5.0;



 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

      
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

 

pragma solidity ^0.5.0;

 
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
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;

contract XJY is ERC20Detailed, ERC20, Ownable {

    uint256 public constant CAP = 195000300000000;
    uint256 public constant INVEST_ADDRESS_1_CAP = 84000000000000;
    uint256 public constant INVEST_ADDRESS_2_CAP = 84000000000000;
    uint256 public constant INVEST_ADDRESS_3_CAP = 27000000000000;
    uint256 public constant SIGNAL_AMOUNT = 100000000;

    bool private _mintFinished = false;
    bool private _onlyWhitelisted = false;
    address private _minter;
    mapping(address => bool) private _whitelisteds;

    address private _investAddress1;
    address private _investAddress2;
    address private _investAddress3;

    uint256 private _investAddress1Minted;
    uint256 private _investAddress2Minted;
    uint256 private _investAddress3Minted;

    modifier canMint()  {
        require(!_mintFinished, 'Mint finished');
        _;
    }

    modifier canSendTransaction()  {
        if (_onlyWhitelisted) {
            require(_whitelisteds[msg.sender], 'msg.sender is not whitelisted');
        }
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == _minter);
        _;
    }

    function transfer(address _to, uint256 _value) public canSendTransaction() returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public canSendTransaction() returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public canSendTransaction() returns (bool) {
        return super.approve(_spender, _value);
    }

    constructor() public
    ERC20Detailed("XJY", "XJY", 8)
    {
        _investAddress1 = 0x64085A3d0A7FCC7B2904E47ED662f62B8Afa3fBb;
        _investAddress2 = 0xFA8ccdA8107DF3719b3A1292F9b8a5D3cA1805dA;
        _investAddress3 = 0xD9e9E9EcF394B3137C6034Ecf722e8dA47C0D3B2;

        _mint(_investAddress1, SIGNAL_AMOUNT);
        _mint(_investAddress2, SIGNAL_AMOUNT);
        _mint(_investAddress3, SIGNAL_AMOUNT);
    }

    function setMinter(address minterAddress) public onlyOwner {
        _minter = minterAddress;
    }

    function setInvestAddress1(address investAddress) public onlyOwner {
        _investAddress1 = investAddress;
    }

    function setInvestAddress2(address investAddress) public onlyOwner {
        _investAddress2 = investAddress;
    }

    function setInvestAddress3(address investAddress) public onlyOwner {
        _investAddress3 = investAddress;
    }

    function finishMint()
    public
    onlyOwner
    canMint
    returns (bool)
    {
        _mintFinished = true;
        return true;
    }

    function onlyWhitelistedOff()
    public
    onlyOwner
    returns (bool)
    {
        _onlyWhitelisted = false;
        return true;
    }

    function onlyWhitelistedOn()
    public
    onlyOwner
    returns (bool)
    {
        _onlyWhitelisted = true;
        return true;
    }

    function mint(address to, uint256 value)
    public
    onlyMinter
    canMint
    returns (bool)
    {
        require(totalSupply().add(value) <= CAP, "Cap exceeded");
        require(to == _investAddress1 || to == _investAddress2 || to == _investAddress3, 'Can mint only to invest addresses');
        if (to == _investAddress1) {
            require(_investAddress1Minted.add(value) <= INVEST_ADDRESS_1_CAP, 'Cap invest address1 exceeded');
            _investAddress1Minted = _investAddress1Minted.add(value);
        } else if (to == _investAddress2) {
            require(_investAddress2Minted.add(value) <= INVEST_ADDRESS_2_CAP, 'Cap invest address2 exceeded');
            _investAddress2Minted = _investAddress2Minted.add(value);
        } else if (to == _investAddress3) {
            require(_investAddress3Minted.add(value) <= INVEST_ADDRESS_3_CAP, 'Cap invest address3 exceeded');
            _investAddress3Minted = _investAddress3Minted.add(value);
        }
        _mint(to, value);
        return true;
    }

    function addWhitelisted(address[] memory addresses) public onlyOwner returns (bool) {
        uint256 i = 0;
        while (i < addresses.length) {
            _whitelisteds[addresses[i]] = true;
            i += 1;
        }
        return true;
    }

    function removeWhitelisted(address[] memory addresses) public onlyOwner returns (bool) {
        uint256 i = 0;
        while (i < addresses.length) {
            _whitelisteds[addresses[i]] = false;
            i += 1;
        }
        return true;
    }

    function minter() public view returns (address) {
        return _minter;
    }

    function mintFinished() public view returns (bool) {
        return _mintFinished;
    }

    function onlyWhitelisted() public view returns (bool) {
        return _onlyWhitelisted;
    }

    function isWhitelisted(address wallet) public view returns (bool) {
        return _whitelisteds[wallet];
    }

    function investAddress1() public view returns (address) {
        return _investAddress1;
    }

    function investAddress2() public view returns (address) {
        return _investAddress2;
    }

    function investAddress3() public view returns (address) {
        return _investAddress3;
    }

    function investAddress1Minted() public view returns (uint256) {
        return _investAddress1Minted;
    }

    function investAddress2Minted() public view returns (uint256) {
        return _investAddress2Minted;
    }

    function investAddress3Minted() public view returns (uint256) {
        return _investAddress3Minted;
    }
}