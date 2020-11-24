 

pragma solidity ^0.5.2;

 
library SafeMath {
     
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

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
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
        require(to != address(0), "ERC20: transfer to the zero address");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
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

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}


contract Coinerium is ERC20{
  using SafeMath for uint256;
  
  OracleInterface oracle;
  string public constant symbol = "CONM";
  string public constant name = "Coinerium";
  uint8 public constant decimals = 18;
  uint256 internal _reserveOwnerSupply;
  address owner;
  
  
  constructor(address oracleAddress) public {
    oracle = OracleInterface(oracleAddress);
    _reserveOwnerSupply = 300000000 * 10**uint(decimals);  
    owner = msg.sender;
    _mint(owner,_reserveOwnerSupply);
  }

  function donate() public payable {}

  function flush() public payable {
     
    uint256 amount = msg.value.mul(oracle.price());
    uint256 finalAmount= amount.div(1 ether);
    _mint(msg.sender,finalAmount);
  }

  function getPrice() public view returns (uint256) {
    return oracle.price();
  }

  function withdraw(uint256 amountCent) public returns (uint256 amountWei){
    require(amountCent <= balanceOf(msg.sender));
    amountWei = (amountCent.mul(1 ether)).div(oracle.price());

     
     
     
     

     
     
     
     
     
     
     
     
    if(balanceOf(msg.sender) <= amountWei) {
      amountWei = amountWei.mul(balanceOf(msg.sender));
      amountWei = amountWei.mul(oracle.price());
      amountWei = amountWei.div(1 ether);
      amountWei = amountWei.mul(totalSupply());
    }
    _burn(msg.sender,amountCent);
    msg.sender.transfer(amountWei);
  }
}

interface OracleInterface {

  function price() external view returns (uint256);

}
contract MockOracle is OracleInterface {

    uint256 public price_;
    address owner;
    
     
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
         _;
    }
    
    constructor() public {
        owner = msg.sender;
    }

    function setPrice(uint256 price) public onlyOwner {
    
      price_ = price;

    }

    function price() public view returns (uint256){

      return price_;

    }

}