 

pragma solidity ^ 0.5.5;

library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b > 0);  
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

 
contract Ownable {

    address public owner;

     
    constructor()public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract SlotsCoin is Ownable {
    
    using SafeMath
    for uint;
    
    mapping(address => uint) public deposit;
    mapping(address => uint) public withdrawal;
    bool status = true;
    uint min_payment = 0.05 ether;
    address payable public marketing_address = 0x777777018285801412ec226229C6F6AE16445F89;
    uint public rp = 0;
    
    event Deposit(
        address indexed from,
        uint indexed block,
        uint value,
        uint time
    );
    
    event Withdrawal(
        address indexed from,
        uint indexed block,
        uint value, 
        uint ident,
        uint time
    );
    
    modifier isNotContract() {
        uint size;
        address addr = msg.sender;
        assembly { size := extcodesize(addr) }
        require(size == 0 && tx.origin == msg.sender);
        _;
    }
    
    modifier contractIsOn() {
        require(status);
        _;
    }
    modifier minPayment() {
        require(msg.value >= min_payment);
        _;
    }
    
     
    function multisend(address payable[] memory dests, uint256[] memory values, uint256[] memory ident) onlyOwner contractIsOn public returns(uint) {
        uint256 i = 0;
        
        while (i < dests.length) {
            uint transfer_value = values[i].sub(values[i].mul(3).div(100));
            dests[i].transfer(transfer_value);
            withdrawal[dests[i]]+=values[i];
            emit Withdrawal(dests[i], block.number, values[i], ident[i], now);
            rp += values[i].mul(3).div(100);
            i += 1;
        }
        
        return(i);
    }
    
    function startProphylaxy()onlyOwner public {
        status = false;
    }
    
    function stopProphylaxy()onlyOwner public {
        status = true;
    }
    
    function() external isNotContract contractIsOn minPayment payable {
        deposit[msg.sender]+= msg.value;
        emit Deposit(msg.sender, block.number, msg.value, now);
    }
    
}