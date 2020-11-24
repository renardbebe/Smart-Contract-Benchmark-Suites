 

pragma solidity 0.4.24;
 
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

 
contract  SwapToken{
    using SafeMath for uint256;
    ERC20 public oldToken;
    ERC20 public newToken;
    address public tokenOwner;

    address public owner;
    bool public swap_able;
    bool public setup_token;

    event Swap(address sender, uint256 amount);
    event SwapAble(bool swapable);

    modifier isOwner() {
        require (msg.sender == owner);
        _;
    }

    modifier isSwap() {
        require (swap_able);
        _;
    }

    modifier isNotSetup() {
        require (!setup_token);
        _;
    }

    constructor()
    public
    {
        owner = msg.sender;
        swap_able = false;
    }

    function setupToken(address _oldToken, address _newToken, address _tokenOwner)
    public
    isNotSetup
    isOwner
    {
        require(_oldToken != 0 && _newToken != 0 && _tokenOwner != 0);
        oldToken = ERC20(_oldToken);
        newToken = ERC20(_newToken);
        tokenOwner = _tokenOwner;
        setup_token = true;
    }

    function swapAble(bool _swap_able)
    public
    isOwner
    {
        swap_able = _swap_able;
        emit SwapAble(_swap_able);
    }

    function withdrawOldToken(address to, uint256 amount)
    public
    isOwner
    returns (bool success)
    {
        require(oldToken.transfer(to, amount));
        return true;
    }

    function swapAbleToken()
    public
    view
    returns (uint256)
    {
        return newToken.allowance(tokenOwner, this);
    }

    function swapToken(uint256 amount)
    public
    isSwap
    returns (bool success)
    {
        require(newToken.allowance(tokenOwner, this) >= amount);
        require(oldToken.transferFrom(msg.sender, this, amount));
        require(newToken.transferFrom(tokenOwner, msg.sender, amount));
        emit Swap(msg.sender, amount);
        return true;
    }
}