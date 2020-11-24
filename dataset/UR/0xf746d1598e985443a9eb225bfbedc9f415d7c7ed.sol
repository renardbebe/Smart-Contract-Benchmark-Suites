 

pragma solidity 0.5.4;


contract Ownable {
    address public owner;
    address public pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        pendingOwner = newOwner;
    }

     
    function claimOwnership() onlyPendingOwner public {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}


 
interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract TokenReceiver is Ownable {
    IERC20 public token;

    event Receive(address from, uint invoiceID, uint amount);

    constructor (address _token) public {
        require(_token != address(0));

        token = IERC20(_token);
    }

    function receiveTokenWithInvoiceID(uint _invoiceID, uint _amount) public {
        require(token.transferFrom(msg.sender, address(this), _amount), "");
        
        emit Receive(msg.sender, _invoiceID, _amount);
    }

    function changeToken(address _token) public onlyOwner {
        token = IERC20(_token);
    }
    
    function reclaimToken(IERC20 _token, uint _amount) external onlyOwner {
        _token.transfer(owner, _amount);
    }
}