 

pragma solidity ^0.4.11;
 

 contract token {

    function balanceOf(address _owner) public returns (uint256 bal);
    function transfer(address _to, uint256 _value) public returns (bool); 
 
 }


 

contract admined {
    address public admin;  
     
    function admined() internal {
        admin = msg.sender;  
        Admined(admin);
    }

    modifier onlyAdmin() {  
        require(msg.sender == admin);
        _;
    }

     
    function transferAdminship(address _newAdmin) onlyAdmin public {  
        require(_newAdmin != address(0));
        admin = _newAdmin;
        TransferAdminship(admin);
    }

     
    event TransferAdminship(address newAdmin);
    event Admined(address administrador);
}

contract Sender is admined {
    
    token public ERC20Token;
    mapping (address => bool) public flag;  
    uint256 public price;  
    
    function Sender (token _addressOfToken, uint256 _initialPrice) public {
        price = _initialPrice;
        ERC20Token = _addressOfToken; 
    }

    function updatePrice(uint256 _newPrice) onlyAdmin public {
        price = _newPrice;
    }

    function contribute() public payable {  
        require(flag[msg.sender] == false);
        flag[msg.sender] = true;
        ERC20Token.transfer(msg.sender,price);
    }

    function withdraw() onlyAdmin public{
        require(admin.send(this.balance));
        ERC20Token.transfer(admin, ERC20Token.balanceOf(this));
    }

    function() public payable {
        contribute();
    }
}