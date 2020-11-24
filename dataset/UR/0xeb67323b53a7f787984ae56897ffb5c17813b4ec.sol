 

 

pragma solidity 0.5.7;


 
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


 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}


 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}


contract OwnablePayable {
    address payable public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }


     
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

     
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

contract FrenchIco_Token is ERC20Mintable {

    using SafeMath for uint256;
    event newTokenFico(address owner, string copyright, string name, string symbol);

    uint8 public constant decimals = 18;
	string public name;
	string public symbol;

    constructor(string memory _symbol, string memory _name) public {
	    symbol = _symbol;
	    name = _name;
	    emit newTokenFico(msg.sender, "Copyright FRENCHICO", name, symbol);
	}

   function sendToGateway(address gatewayAddr, uint amount, uint orderId, uint[] calldata instruction, string calldata message, address addr) external {
    approve(address(gatewayAddr) ,amount);
    FrenchIco_Gateway gateway = FrenchIco_Gateway(address(gatewayAddr));
    gateway.orderFromToken(msg.sender, amount, address(this), orderId, instruction, message, addr);
    }



}

interface FrenchIco_Gateway {
function orderFromToken(address , uint , address, uint, uint[] calldata, string calldata, address) external returns (bool);
}

interface FrenchIco_Corporate {

    function isGeneralPaused() external view returns (bool);
    function GetRole(address addr) external view returns (uint _role);
    function GetWallet_FRENCHICO() external view returns (address payable);
    function GetMaxAmount() external view returns (uint);
}

contract FrenchIco {

    FrenchIco_Corporate Fico = FrenchIco_Corporate(address(0x8024A6e9f0842E86079e707bF874AFC061c38D60));

	modifier isNotStoppedByFrenchIco() {
	    require(!Fico.isGeneralPaused());
	    _;
	}
}

contract FrenchIco_Crowdsale is OwnablePayable, FrenchIco {

 using SafeMath for uint256;
 FrenchIco_Token public token;

   

    event TokensBuy(address beneficary, uint amount);
    event Copyright(string copyright);

    

    struct Investor {
	uint tokensBought;
    }
    mapping(address => Investor) public Investors;

    

    uint public endTime;
    uint public fundsCollected;

   
    constructor(string memory _name, string memory _symbol, uint _endTime) public {
        token = new FrenchIco_Token(_symbol, _name);
        endTime = _endTime;
        emit Copyright("Copyright FRENCHICO");

    }

   

    function() external payable {
        buyTokens();
    }


   
    function buyTokens() public payable isNotStoppedByFrenchIco  {
         require (msg.value>0,"empty");
         require (validAccess(msg.value), "Control Access Denied");
         require (now <= endTime,"ICO not running");
         token.mint(msg.sender,msg.value);
         Investors[msg.sender].tokensBought = Investors[msg.sender].tokensBought.add(msg.value);
         fundsCollected = fundsCollected.add(msg.value);
         _owner.transfer(address(this).balance);

         emit TokensBuy(msg.sender, msg.value);
    }


   
    function validAccess(uint value) public view returns(bool) {
        bool access;
        if (Fico.GetRole(msg.sender) <= 1 && Investors[msg.sender].tokensBought.add(value) <= Fico.GetMaxAmount()){access = true;}
        else if (Fico.GetRole(msg.sender) > 1){access = true;}
        else {access = false;}
        return access;
    }


}