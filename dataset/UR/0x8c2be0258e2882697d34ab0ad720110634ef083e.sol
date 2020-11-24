 

pragma solidity >= 0.5.0 < 0.6.0;


 


 
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract J888 is IERC20 {
    string public name = "J888";
    string public symbol = "888";
    uint8 public decimals = 18;
    
    uint256 marketingAmount;
    uint256 companyAmount;
    uint256 saleAmount;

    uint256 _totalSupply;
    mapping(address => uint256) balances;

    address public owner;
    address public marketing;
    address public company;
    address public sale;
    
    modifier isOwner {
        require(owner == msg.sender);
        _;
    }
    
    constructor() public {
        owner   = msg.sender;
        marketing = 0xeC5D08b63FA4E683F2f959D650b1ca456bcD75A9;
        company = 0xF82e46D8B7cBB26312C0e391926A7ae687CA1c45;
        sale = 0x6561A1096b3B772a2fE9fd9088e2F4C2f225E05e;
        
        marketingAmount = toWei(1500000000);
        companyAmount   = toWei(1500000000);
        saleAmount      = toWei(7000000000);
        _totalSupply    = toWei(10000000000);   

        require(_totalSupply == marketingAmount + companyAmount + saleAmount );
        
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, balances[owner]);
        
        transfer(marketing, marketingAmount);
        transfer(company, companyAmount);
        transfer(sale, saleAmount);


        require(balances[owner] == 0);
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address who) public view returns (uint256) {
        return balances[who];
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
        require(msg.sender != to);
        require(value > 0);
        
        require( balances[msg.sender] >= value );
        require( balances[to] + value >= balances[to] );

        if (to == address(0) || to == address(0x1) || to == address(0xdead)) {
             _totalSupply -= value;
        }

        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function burnCoins(uint256 value) public {
        require(balances[msg.sender] >= value);
        require(_totalSupply >= value);
        
        balances[msg.sender] -= value;
        _totalSupply -= value;

        emit Transfer(msg.sender, address(0), value);
    }


     

    function toWei(uint256 value) private view returns (uint256) {
        return value * (10 ** uint256(decimals));
    }
}