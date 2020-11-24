 

 

 
 

 
 
 

 
 

pragma solidity ^0.5.0;

contract Logging {
    function log(string memory message, uint256 amount, address addr) public;
}

contract SharedWalletWithLogging {

    Logging logger = Logging(0xe21ADf5002f257df1b743F1B03F5F5352DE300e7);

    uint256 min_initial_deposit = 1 ether;
    uint256 min_deposit = 0.1 ether;
    mapping(address => uint256) public balances;
    address payable public _owner;
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }    
    
    constructor() public payable {
        _init();
    }
    
    function _init() public payable {
        require(msg.value >= min_initial_deposit);
        _owner = msg.sender; 
    }

    function deposit() public payable {
        require(msg.value >= min_deposit);
        balances[msg.sender] += msg.value;
    
        logger.log('Deposit', msg.value, msg.sender);
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount);

        balances[msg.sender] -= amount;
        msg.sender.transfer(amount);

        logger.log('Withdrawal', amount, msg.sender);
    }
    
    function ownerWithdraw() public onlyOwner {
        _owner.transfer(address(this).balance);
        
        logger.log('OwnerWithdrawal', address(this).balance, msg.sender);
    }
}