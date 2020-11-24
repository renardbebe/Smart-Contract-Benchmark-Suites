 

pragma solidity ^0.5.12;

contract RunDice {
    address public owner;
    address private nextOwner;
    address private RunDiceToken; 
    
    modifier onlyBy(address user) {
        require(msg.sender == user, "Caller have no access to this method.");
        _;
    }
    
    event Payment(
        address indexed user,
        uint amount
        );
    event PaymentFailed(
        address indexed user,
        uint amount
        );
    event Rolled(
        int16 number,
        uint amount,
        address indexed user
        );
    
    event Deposited(
        address indexed user,
        uint amount
        );
    event Withdrew(
        address indexed user,
        uint amount
        );
    event WithdrewFailed(
        address indexed user,
        uint amount
        );
    event TokensSent(
        uint amount
        );
    event TokensSendFailed(
        uint amount
        );
    event NotEnough(uint amount);
    
    constructor() public {
        owner = msg.sender;
    }
    
    function Random(uint min, uint max) view private returns (uint) {
        bytes32 hash = keccak256(abi.encodePacked(min, max, blockhash(block.number)));
        return min + ((uint(hash) + block.difficulty) % (max - min + 1));
    }
    
    function ChangeOwner(address newOwner) onlyBy(owner) public {
        nextOwner = newOwner;
    }
    
    function AcceptOwner() onlyBy(nextOwner) public {
        owner = nextOwner;
    }
    
    function Roll(int16 min, int16 max) payable public {
        require (min >= 0 && max <= 9999 && min <= max, "Min and Max parameters set wrong.");
        require (msg.value >= 100000000000000, "Bet amount set wrong.");
        
        uint amount = msg.value;
        int16 number = int16(Random(0, 9999));
        
        if(number >= min && number <= max) {
            address payable to = msg.sender;
            uint multiply = uint(100000000 / uint((max - min + 1)));
            uint value = amount * multiply / 10000000 * 975;
            
            emit Rolled(number, value, to);
            
            if(to.send(value)) {
                emit Payment(to, value);
            }
            else {
                emit PaymentFailed(to, value);
                if(!to.send(amount)) {
                    emit NotEnough(value - amount);
                }
            }
        }
        
        else {
            emit Rolled(number, 0, msg.sender);
        }
    }
    
    function Deposit() onlyBy(owner) payable public {
        emit Deposited(msg.sender, msg.value);
    }
    
    function Withdraw(uint value) onlyBy(owner) public {
        address payable to = msg.sender;
        if(value <= address(this).balance) {
            if(to.send(value)) {
                emit Withdrew(to, value);
            }
            else {
                emit WithdrewFailed(to, value);
            }
        }
        
        else {
            emit WithdrewFailed(to, value);
        }
    }
}