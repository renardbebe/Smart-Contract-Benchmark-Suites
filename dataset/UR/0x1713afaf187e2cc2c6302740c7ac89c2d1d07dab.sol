 

pragma solidity ^0.5.0;

contract Pack {

    enum Type {
        Rare, Epic, Legendary, Shiny
    }

}

contract Ownable {

    address payable public owner;

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address payable _owner) public onlyOwner {
        owner = _owner;
    }

    function getOwner() public view returns (address payable) {
        return owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "must be owner to call this function");
        _;
    }

}


 
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

contract IERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function allowance(address owner, address spender) public view returns (uint256);
    
    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);
    
    function transfer(address to, uint256 value) public returns (bool);
    
  
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
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
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

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

contract ERC20Burnable is ERC20 {
     
    function burn(uint256 value) internal {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) internal {
        _burnFrom(from, value);
    }
}



interface IProcessor {

    function processPayment(address user, uint cost, uint items, address referrer) external payable returns (uint id);
    
}

interface IPack {

    function openChest(Pack.Type packType, address user, uint count) external returns (uint);

}


contract Chest is Ownable, ERC20Detailed, ERC20Burnable {

    using SafeMath for uint;

    uint256 public cap;
    IProcessor public processor;
    IPack public pack;
    Pack.Type public packType;
    uint price;
    bool public tradeable;

    event ChestsPurchased(address user, uint count, address referrer, uint paymentID);

    constructor(
        IPack _pack, Pack.Type _pt,
        uint _price, IProcessor _processor, uint _cap,
        string memory name, string memory sym
    ) public ERC20Detailed(name, sym, 0) {
        price = _price;
        cap = _cap;
        pack = _pack;
        packType = _pt;
        processor = _processor;
    }

    function purchase(uint count, address referrer) public payable {
        return purchaseFor(msg.sender, count, referrer);
    }

    function purchaseFor(address user, uint count, address referrer) public payable {

        _mint(user, count);

        uint paymentID = processor.processPayment.value(msg.value)(msg.sender, price, count, referrer);
        emit ChestsPurchased(user, count, referrer, paymentID);
    }

    function open(uint value) public payable returns (uint) {
        return openFor(msg.sender, value);
    }

     
    function openFor(address user, uint value) public payable returns (uint) {

        require(value > 0, "must open at least one chest");
         
         
        if (user == msg.sender) {
            burn(value);
        } else {
            burnFrom(user, value);
        }

        require(address(pack) != address(0), "pack must be set");
   
        return pack.openChest(packType, user, value);
    }

    function makeTradeable() public onlyOwner {
        tradeable = true;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(tradeable, "not currently tradeable");
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(tradeable, "not currently tradeable");
        return super.transferFrom(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        if (cap > 0) {
            require(totalSupply().add(value) <= cap, "not enough space in cap");
        }
        super._mint(account, value);
    }

}