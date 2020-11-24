 

pragma solidity ^0.5.7;

 

 
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

     
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

     
    function rescueTokens(address tokenAddr, address receiver, uint256 amount) external onlyOwner {
        IERC20 _token = IERC20(tokenAddr);
        require(receiver != address(0));
        uint256 balance = _token.balanceOf(address(this));

        require(balance >= amount);
        assert(_token.transfer(receiver, amount));
    }

     
    function withdrawEther(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0));

        uint256 balance = address(this).balance;

        require(balance >= amount);
        to.transfer(amount);
    }
}


 
interface IERC20{
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}


 
contract TGServiceNodesFund is Ownable{
    IERC20 public TG;
    address TG_Addr = address(0);

    event Donate(address indexed account, uint256 amount);

     
    constructor() public {
        TG = IERC20(TG_Addr);
    }

     
    function () external payable {
        emit Donate(msg.sender, msg.value);
    }

     
    function transferTG(address to, uint256 amount) external onlyOwner {
        assert(TG.transfer(to, amount));
    }

     
    function batchTransfer(address[] memory accounts, uint256[] memory values) public onlyOwner {
        require(accounts.length == values.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            assert(TG.transfer(accounts[i], values[i]));
        }
    }

     
    function setTGAddress(address _TGAddr) public onlyOwner {
        TG_Addr = _TGAddr;
        TG = IERC20(_TGAddr);
    }
}