 

pragma solidity ^0.4.20;

 

 
contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
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

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}

contract Lottery is Ownable {

     
    modifier secCheck(address aContract) {
        require(aContract != address(contractCall));
        _;
    }

     
    modifier restriction() {
        require(!_restriction);
        _;
    }

     

    event BoughtTicket(uint256 amount, address customer, uint yourEntry);
    event WinnerPaid(uint256 amount, address winner);


     

    _Contract contractCall;   
    address[] public entries;  
    uint256 entryCounter;  
    uint256 public automaticThreshold;  
    uint256 public ticketPrice = 10 finney;  
    bool public _restriction;  
    




    constructor() public {
        contractCall = _Contract(0x05215FCE25902366480696F38C3093e31DBCE69A);
        _restriction = true;
        automaticThreshold = 100;  
        ticketPrice = 10 finney;  
        entryCounter = 0;
    }

     
    function() payable public {
    }


    function buyTickets() restriction() payable public {
         
        require(msg.value >= ticketPrice);

        address customerAddress = msg.sender;
         
        contractCall.buy.value(msg.value)(customerAddress);
         
        if (entryCounter == (entries.length)) {
            entries.push(customerAddress);
            }
        else {
            entries[entryCounter] = customerAddress;
        }
         
        entryCounter++;
         
        emit BoughtTicket(msg.value, msg.sender, entryCounter);

          
        if(entryCounter >= automaticThreshold) {
             
            contractCall.exit();

             
            payWinner();
        }
    }

     
    function PRNG() internal view returns (uint256) {
        uint256 initialize1 = block.timestamp;
        uint256 initialize2 = uint256(block.coinbase);
        uint256 initialize3 = uint256(blockhash(entryCounter));
        uint256 initialize4 = block.number;
        uint256 initialize5 = block.gaslimit;
        uint256 initialize6 = block.difficulty;

        uint256 calc1 = uint256(keccak256(abi.encodePacked((initialize1 * 5),initialize5,initialize6)));
        uint256 calc2 = 1-calc1;
        int256 ov = int8(calc2);
        uint256 calc3 = uint256(sha256(abi.encodePacked(initialize1,ov,initialize3,initialize4)));
        uint256 PRN = uint256(keccak256(abi.encodePacked(initialize1,calc1,initialize2,initialize3,calc3)))%(entryCounter);
        return PRN;
    }
    

     
    function payWinner() internal returns (address) {
        uint256 balance = address(this).balance;
        uint256 number = PRNG();  
        address winner = entries[number];  
        winner.transfer(balance);  
        entryCounter = 0;  

        emit WinnerPaid(balance, winner);
        return winner;
    }

     
    function donateToDev() payable public {
        address developer = 0x13373FEdb7f8dF156E5718303897Fae2d363Cc96;
        developer.transfer(msg.value);
    }

     
    function myTokens() public view returns(uint256) {
        return contractCall.myTokens();
    }

     
    function myDividends() public view returns(uint256) {
        return contractCall.myDividends(true);
    }


     

     
    function disableRestriction() onlyOwner() public {
        _restriction = false;
    }

     
    function changeThreshold(uint newThreshold) onlyOwner() public {
         
        require(entryCounter == 0);
        automaticThreshold = newThreshold;
    }

    function changeTicketPrice(uint newticketPrice) onlyOwner() public {
         
        require(entryCounter == 0);
        ticketPrice = newticketPrice;
    }

     
    function payWinnerManually() public onlyOwner() returns (address) {
        address winner = payWinner();
        return winner;
    }

     
    function imAlive() public onlyOwner() {
        inactivity = 1;
    }
     

     
    uint inactivity = 1;
    function adminIsDead() public {
        if (inactivity == 1) {
            inactivity == block.timestamp;
        }
        else {
            uint256 inactivityThreshold = (block.timestamp - (30 days));
            assert(inactivityThreshold < block.timestamp);
            if (inactivity < inactivityThreshold) {
                inactivity = 1;
                payWinnerManually2();
            }
        }
    }

    function payWinnerManually2() internal {
        payWinner();
    }


      
    function returnAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens) public onlyOwner() secCheck(tokenAddress) returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }


}


 
contract ERC20Interface
{
    function transfer(address to, uint256 tokens) public returns (bool success);
}

 
contract _Contract
{
    function buy(address) public payable returns(uint256);
    function exit() public;
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
}