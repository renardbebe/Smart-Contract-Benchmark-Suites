 

pragma solidity ^0.4.24;

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() public {
        owner = msg.sender;
    }

    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
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

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function allowance(address owner, address spender)
    external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value)
    external returns (bool);
  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract ERC20Token is IERC20 {
    using SafeMath for uint256;

    
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 internal _totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;

    
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
        require(value <= _balances[msg.sender]);
        require(to != address(0));

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    
    function _forceTransfer(address from, address to, uint256 value) internal returns (bool) {
        require(value <= _balances[from]);
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
        return true;
    }

    
    function _mint(address account, uint256 amount) internal returns (bool) {
        require(account != 0);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        return true;
    }

    
    function _burn(address account, uint256 amount) internal returns (bool) {
        require(account != 0);
        require(amount <= _balances[account]);

        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
        return true;
    }
}



contract RegulatorService {

    function verify(address _token, address _spender, address _from, address _to, uint256 _amount) 
        public 
        view 
        returns (byte) 
    {
        return hex"A3";
    }

    function restrictionMessage(byte restrictionCode)
        public
        view
        returns (string)
    {
    	if(restrictionCode == hex"01") {
    		return "No restrictions detected";
        }
        if(restrictionCode == hex"10") {
            return "One of the accounts is not on the whitelist";
        }
        if(restrictionCode == hex"A3") {
            return "The lockup period is in progress";
        }
    }
}


contract AtomicDSS is ERC20Token, Ownable {
    byte public constant SUCCESS_CODE = hex"01";
    string public constant SUCCESS_MESSAGE = "SUCCESS";
    RegulatorService public regulator;
  
    event ReplaceRegulator(address oldRegulator, address newRegulator);

    modifier notRestricted (address from, address to, uint256 value) {
        byte restrictionCode = regulator.verify(this, msg.sender, from, to, value);
        require(restrictionCode == SUCCESS_CODE, regulator.restrictionMessage(restrictionCode));
        _;
    }

    constructor(RegulatorService _regulator, address[] wallets, uint256[] amounts, address owner) public {
            regulator = _regulator;
            symbol = "ATOM";
            name = "Atomic Capital, Inc.C-Corp.Delaware.Equity.1.Common.";
            decimals = 18;
            for (uint256 i = 0; i < wallets.length; i++){
                mint(wallets[i], amounts[i]);
                if(i == 10){
                    break;
                }
            }
            transferOwnership(owner);
    }

   
    modifier isContract (address _addr) {
        uint length;
        assembly { length := extcodesize(_addr) }
        require(length > 0);
        _;
    }

    function replaceRegulator(RegulatorService _regulator) 
        public 
        onlyOwner 
        isContract(_regulator) 
    {
        address oldRegulator = regulator;
        regulator = _regulator;
        emit ReplaceRegulator(oldRegulator, regulator);
    }

    function transfer(address to, uint256 value)
        public
        notRestricted(msg.sender, to, value)
        returns (bool)
    {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value)
        public
        notRestricted(from, to, value)
        returns (bool)
    {
        return super.transferFrom(from, to, value);
    }

    function forceTransfer(address from, address to, uint256 value)
        public
        onlyOwner
        returns (bool)
    {
        return super._forceTransfer(from, to, value);
    }

    function mint(address account, uint256 amount) 
        public
        onlyOwner
        returns (bool)
    {
        return super._mint(account, amount);
    }

    function burn(address account, uint256 amount) 
        public
        onlyOwner
        returns (bool)
    {
        return super._burn(account, amount);
    }
}