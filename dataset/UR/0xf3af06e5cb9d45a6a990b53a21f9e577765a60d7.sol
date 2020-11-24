 

pragma solidity >=0.4.22 <0.6.0;

 
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


 
contract ERC20Token is IERC20 {

    using SafeMath for uint256;

    uint256 private _totalSupply;
    mapping (address => uint256) private _balances;
   
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals, uint256 totalSupply,  address tokenOwnerAddress) public payable {
         require(tokenOwnerAddress != address(0));
         _totalSupply = totalSupply;
          _name = name;
          _symbol = symbol;
          _decimals = decimals;
          _balances[tokenOwnerAddress] = totalSupply;
    }

  
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }


     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }





     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
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
    
    function approve(address spender, uint256 value) external returns (bool){
        require(address(0) != address(0));
        return false;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool){
        require(address(0) != address(0));
        return false;
    }


    function allowance(address owner, address spender) external view returns (uint256){
        require(address(0) != address(0));
        return 0;
    }

    

}