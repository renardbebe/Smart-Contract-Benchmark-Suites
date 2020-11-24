 

pragma solidity ^0.4.11;

contract MiningRig {
     
    string public warning = "請各位要有耐心等候交易完成喔";
    
     
    address public owner = 0x0;
    
     
    uint public closeBlock = 0;
    
     
    uint public totalNTD = 0;
    
     
    uint public totalWithdrew = 0;
    
     
    mapping(address => uint) public usersNTD;
    
     
    mapping(address => uint) public usersWithdrew;
    
     
    modifier onlyOwner () {
        assert(owner == msg.sender);
        _;
    }
    
     
    modifier beforeCloseBlock () {
        assert(block.number <= closeBlock);
        _;
    }
    
     
    modifier afterCloseBlock () {
        assert(block.number > closeBlock);
        _;
    }
    
     
    modifier onlyMember () {
        assert(usersNTD[msg.sender] != 0);
        _;
    }
    
     
    function MiningRig () {
        owner = msg.sender;
        closeBlock = block.number + 5760;  
    }
    
     
    function Register (address theUser, uint NTD) onlyOwner beforeCloseBlock {
        usersNTD[theUser] += NTD;
        totalNTD += NTD;
    }
    
     
    function Unregister (address theUser, uint NTD) onlyOwner beforeCloseBlock {
        assert(usersNTD[theUser] >= NTD);
        
        usersNTD[theUser] -= NTD;
        totalNTD -= NTD;
    }
    
     
    function Withdraw () onlyMember afterCloseBlock {
         
        uint everMined = this.balance + totalWithdrew;
        
         
        uint totalUserCanWithdraw = everMined * usersNTD[msg.sender] / totalNTD;
        
         
        uint userCanWithdrawNow = totalUserCanWithdraw - usersWithdrew[msg.sender];
        
         
        totalWithdrew += userCanWithdrawNow;
        usersWithdrew[msg.sender] += userCanWithdrawNow;

        assert(userCanWithdrawNow > 0);
        
        msg.sender.transfer(userCanWithdrawNow);
    }
    
     
     
    function Cashing (address targetAddress, uint permilleToCashing) onlyMember afterCloseBlock {
         
        assert(permilleToCashing <= 1000);
        assert(permilleToCashing > 0);
        
         
        uint everMined = this.balance + totalWithdrew;
        
         
        uint totalUserCanWithdraw = everMined * usersNTD[msg.sender] / totalNTD;
        
         
        uint userCanWithdrawNow = totalUserCanWithdraw - usersWithdrew[msg.sender];
        
         
        uint totalTargetUserCanWithdraw = everMined * usersNTD[targetAddress] / totalNTD;
        
         
        uint targetUserCanWithdrawNow = totalTargetUserCanWithdraw - usersWithdrew[targetAddress];
        
         
        assert(userCanWithdrawNow == 0);
        assert(targetUserCanWithdrawNow == 0);
        
        uint NTDToTransfer = usersNTD[msg.sender] * permilleToCashing / 1000;
        uint WithdrewToTransfer = usersWithdrew[msg.sender] * permilleToCashing / 1000;
        
        usersNTD[msg.sender] -= NTDToTransfer;
        usersWithdrew[msg.sender] -= WithdrewToTransfer;
        
        usersNTD[targetAddress] += NTDToTransfer;
        usersWithdrew[targetAddress] += WithdrewToTransfer;
    }
    
    function ContractBalance () constant returns (uint) {
        return this.balance;
    }
    
    function ContractTotalMined() constant returns (uint) {
        return this.balance + totalWithdrew;
    }
    
    function MyTotalNTD () constant returns (uint) {
        return usersNTD[msg.sender];
    }
    
    function MyTotalWithdrew () constant returns (uint) {
        return usersWithdrew[msg.sender];
    }
 
    function () payable {}
}