 

pragma solidity >= 0.4.24 < 0.6.0;


 


 
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract INNT is IERC20 {
    string public name = "Inning Token";
    string public symbol = "INNT";
    uint8 public decimals = 18;
    
    uint256 exAmount;
    uint256 reserveAmount;
    
    uint256 _totalSupply;
    mapping(address => uint256) balances;

    address public owner;
    address public reserve;

    modifier isOwner {
        require(owner == msg.sender);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        reserve   = 0x80EB19c0dD70Db1b5aA836879Ea683c5818CF52f;

        exAmount        = toWei(4700000000);    
        reserveAmount   = toWei(300000000);     
        _totalSupply    = toWei(5000000000);    

        require(_totalSupply == exAmount + reserveAmount );
        
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, balances[owner]);
        
        transfer(reserve, reserveAmount);
        require(balances[owner] == exAmount);
    }
    
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address who) public view returns (uint256) {
        return balances[who];
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
        require(msg.sender != to);

        require(to != owner);
        require(value > 0);
        
        require( balances[msg.sender] >= value );
        require( balances[to] + value >= balances[to] );     

        if(msg.sender == reserve) {
            require(now >= 1587600000);      
        }

        if (to == address(0) || to == address(0x1) || to == address(0xdead)) {
             _totalSupply -= value;
        }


        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function burnCoins(uint256 value) public {
        require(msg.sender != owner);    
        require(balances[msg.sender] >= value);
        require(_totalSupply >= value);
        
        balances[msg.sender] -= value;
        _totalSupply -= value;

        emit Transfer(msg.sender, address(0), value);
    }

    function balanceOfOwner() public view returns (uint256) {
        return balances[owner];
    }
    
    function toWei(uint256 value) private constant returns (uint256) {
        return value * (10 ** uint256(decimals));
    }
}