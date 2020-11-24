 

pragma solidity ^0.4.24;

 

contract Reternal {
    
     
    mapping (address => Investor) public investors;
    address[] public addresses;
    
    struct Investor
    {
        uint id;
        uint deposit;
        uint depositCount;
        uint block;
        address referrer;
    }
    
    uint constant public MINIMUM_INVEST = 10000000000000000 wei;
    address defaultReferrer = 0x25EDFd665C2898c2898E499Abd8428BaC616a0ED;
    
    uint public round;
    uint public totalDepositAmount;
    bool public pause;
    uint public restartBlock;
    bool ref_flag;
    
     
    uint bank1 = 200e18;  
    uint bank2 = 500e18;  
    uint bank3 = 900e18;  
    uint bank4 = 1500e18;  
    uint bank5 = 2000e18;  
     
    uint dep1 = 1e18;  
    uint dep2 = 4e18;  
    uint dep3 = 12e18;  
    uint dep4 = 5e19;  
    
    event NewInvestor(address indexed investor, uint deposit, address referrer);
    event PayOffDividends(address indexed investor, uint value);
    event refPayout(address indexed investor, uint value, address referrer);
    event NewDeposit(address indexed investor, uint value);
    event NextRoundStarted(uint round, uint block, address addr, uint value);
    
    constructor() public {
        addresses.length = 1;
        round = 1;
        pause = false;
    }

    function restart() private {
        address addr;

        for (uint i = addresses.length - 1; i > 0; i--) {
            addr = addresses[i];
            addresses.length -= 1;
            delete investors[addr];
        }
        
        emit NextRoundStarted(round, block.number, msg.sender, msg.value);
        pause = false;
        round += 1;
        totalDepositAmount = 0;
        
        createDeposit();
    }

    function getRaisedPercents(address addr) internal view  returns(uint){
         
        uint percent = getIndividualPercent() + getBankPercent();
        uint256 amount = investors[addr].deposit * percent / 100*(block.number-investors[addr].block)/6000;
        return(amount / 100);
    }
    
    function payDividends() private{
        require(investors[msg.sender].id > 0, "Investor not found.");
         
        uint amount = getRaisedPercents(msg.sender);
            
        if (address(this).balance < amount) {
            pause = true;
            restartBlock = block.number + 6000;
            return;
        }
        
         
        uint FeeToWithdraw = amount * 5 / 100;
        uint payment = amount - FeeToWithdraw;
        
        address(0xD9bE11E7412584368546b1CaE64b6C384AE85ebB).transfer(FeeToWithdraw);
        msg.sender.transfer(payment);
        emit PayOffDividends(msg.sender, amount);
        
    }
    
    function createDeposit() private{
        Investor storage user = investors[msg.sender];
        
        if (user.id == 0) {
            
             
            msg.sender.transfer(0 wei);
            user.id = addresses.push(msg.sender);

            if (msg.data.length != 0) {
                address referrer = bytesToAddress(msg.data);
                
                 
                if (investors[referrer].id > 0 && referrer != msg.sender) {
                    user.referrer = referrer;
                    
                     
                    if (user.depositCount == 0) {
                        uint cashback = msg.value / 100;
                        if (msg.sender.send(cashback)) {
                            emit refPayout(msg.sender, cashback, referrer);
                        }
                    }
                }
            } else {
                 
                user.referrer = defaultReferrer;
            }
            
            emit NewInvestor(msg.sender, msg.value, referrer);
            
        } else {
             
            payDividends();
        }
        
         
        uint payReferrer = msg.value * 2 / 100; 
        
        if (user.referrer == defaultReferrer) {
            user.referrer.transfer(payReferrer);
        } else {
            investors[referrer].deposit += payReferrer;
        }
        
        
        user.depositCount++;
        user.deposit += msg.value;
        user.block = block.number;
        totalDepositAmount += msg.value;
        emit NewDeposit(msg.sender, msg.value);
    }

    function() external payable {
        if(pause) {
            if (restartBlock <= block.number) { restart(); }
            require(!pause, "Eternal is restarting, wait for the block in restartBlock");
        } else {
            if (msg.value == 0) {
                payDividends();
                return;
            }
            require(msg.value >= MINIMUM_INVEST, "Too small amount, minimum 0.01 ether");
            createDeposit();
        }
    }
    
    function getBankPercent() public view returns(uint){
        
        uint contractBalance = address(this).balance;
        
        uint totalBank1 = bank1;
        uint totalBank2 = bank2;
        uint totalBank3 = bank3;
        uint totalBank4 = bank4;
        uint totalBank5 = bank5;
        
        if(contractBalance < totalBank1){
            return(0);
        }
        if(contractBalance >= totalBank1 && contractBalance < totalBank2){
            return(30);
        }
        if(contractBalance >= totalBank2 && contractBalance < totalBank3){
            return(40);
        }
        if(contractBalance >= totalBank3 && contractBalance < totalBank4){
            return(50);
        }
        if(contractBalance >= totalBank4 && contractBalance < totalBank5){
            return(65);
        }
        if(contractBalance >= totalBank5){
            return(80);
        }
    }

    function getIndividualPercent() public view returns(uint){
        
        uint userBalance = investors[msg.sender].deposit;
        
        uint totalDeposit1 = dep1;
        uint totalDeposit2 = dep2;
        uint totalDeposit3 = dep3;
        uint totalDeposit4 = dep4;
        
        if(userBalance < totalDeposit1){
            return(355);
        }
        if(userBalance >= totalDeposit1 && userBalance < totalDeposit2){
            return(365);
        }
        if(userBalance >= totalDeposit2 && userBalance < totalDeposit3){
            return(375);
        }
        if(userBalance >= totalDeposit3 && userBalance < totalDeposit4){
            return(385); 
        }
        if(userBalance >= totalDeposit4){
            return(400);
        }
    }
    
    function getInvestorCount() public view returns (uint) {
        return addresses.length - 1;
    }
    
    function bytesToAddress(bytes bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

}