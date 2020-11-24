 

pragma solidity ^0.4.18;

 
 
 
 
 
 
 

contract Authority {
    
     
    address public owner;
    
     
    address public beneficiary;
    
     
    bool public closed = false;
    
     
    bool public allowDraw = true;
    
     modifier onlyOwner() { 
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyBeneficiary(){
        require(msg.sender == beneficiary);
        _;
    }
    
    modifier alloweDrawEth(){
       if(allowDraw){
           _;
       }
    }
    
    function Authority() public {
        owner = msg.sender;
        beneficiary = msg.sender;
    }
    
    function open() public onlyOwner {
        closed = false;
    }
    
    function close() public onlyOwner {
        closed = true;
    }
    
    function setAllowDrawETH(bool _allow) public onlyOwner{
        allowDraw = _allow;
    }
}

contract PublickOffering is Authority {
    
     
    struct investorInfo{
        address investor;
        uint256 amount;
        uint    utime;
        bool    hadback;
    }
    
     
    mapping(uint => investorInfo) public bills;
    
     
    uint256 public totalETHSold;
    
     
    uint public lastAccountNum;
    
     
    uint256 public constant minETH = 0.2 * 10 ** 18;
    
     
    uint256 public constant maxETH = 20 * 10 ** 18;
    
    event Bill(address indexed sender, uint256 value, uint time);
    event Draw(address indexed _addr, uint256 value, uint time);
    event Back(address indexed _addr, uint256 value, uint time);
    
    function PublickOffering() public {
        totalETHSold = 0;
        lastAccountNum = 0;
    }
    
    function () public payable {
        if(!closed){
            require(msg.value >= minETH);
            require(msg.value <= maxETH);
            bills[lastAccountNum].investor = msg.sender;
            bills[lastAccountNum].amount = msg.value;
            bills[lastAccountNum].utime = now;
            totalETHSold += msg.value;
            lastAccountNum++;
            Bill(msg.sender, msg.value, now);
        } else {
            revert();
        }
    }
    
    function drawETH(uint256 amount) public onlyBeneficiary alloweDrawEth{
        beneficiary.transfer(amount);
        Draw(msg.sender, amount, now);
    }
    
    function backETH(uint pos) public onlyBeneficiary{
        if(!bills[pos].hadback){
            require(pos < lastAccountNum);
            bills[pos].investor.transfer(bills[pos].amount);
            bills[pos].hadback = true;
            Back(bills[pos].investor, bills[pos].amount, now);
        }
    }
    
}