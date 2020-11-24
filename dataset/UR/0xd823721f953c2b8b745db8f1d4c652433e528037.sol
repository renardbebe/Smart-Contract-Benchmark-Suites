 

 

pragma solidity ^0.5.10;

 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


 
contract ERC20BasicInterface {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint8 public decimals;
}

contract Bussiness is Ownable {
    address payable public ceoAddress = address(0x2BebE5B81844151212DE3c7ea2e2C07616f7801B);
    address public technical = address(0x2076A228E6eB670fd1C604DE574d555476520DB7);
    ERC20BasicInterface public nagemonToken = ERC20BasicInterface(0xF63C5639786E7ce7C35B3D2b97E74bf7af63eEEA);
    uint256 public NagemonExchange = 297;
    constructor() public {}
    
     
    modifier onlyCeoAddress() {
        require(msg.sender == ceoAddress);
        _;
    }
    modifier onlyTechnicalAddress() {
        require(msg.sender == technical);
        _;
    }
    event received(address _from, uint256 _amount);
    event receivedErc20(address _from, uint256 _amount);
    struct ticket {
        address owner;
        uint256 amount;
    }
    mapping(address => ticket) public tickets;
     
    function buyMonsterFossilByEth() public payable {
        ceoAddress.transfer(msg.value);
         
        uint256 amount = getTokenAmount(msg.value);
        tickets[msg.sender] = ticket(msg.sender, amount);
        emit received(msg.sender, msg.value);
    }
    function buyMonsterFossilByNagemon(uint256 _amount) public {
        require(nagemonToken.transferFrom(msg.sender, ceoAddress, _amount));
        tickets[msg.sender] = ticket(msg.sender, _amount);
        emit receivedErc20(msg.sender, _amount);
    }
    function resetTiket(address _ticketOwner) public onlyTechnicalAddress returns (bool) {
        tickets[_ticketOwner] = ticket(address(0), 0);
        return true;
    }
     
    function getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 tokenDecimal = 18 - nagemonToken.decimals();
        return _weiAmount * NagemonExchange / (10 ** tokenDecimal);
    }
    
    function config(uint256 _NagemonExchange, address _technical) public onlyOwner returns (uint256, address){
        NagemonExchange = _NagemonExchange;
        technical = _technical;
        return (NagemonExchange, technical);
    }
    function changeCeo(address payable _address) public onlyCeoAddress {
        require(_address != address(0));
        ceoAddress = _address;

    }
}