 

pragma solidity ^ 0.4 .13;

contract SafeMath {
    function safeMul(uint a, uint b) internal returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns(uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    function assert(bool assertion) internal {
        if (!assertion) {
            revert();
        }
    }
}




contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) owner = newOwner;
    }

    function kill() {
        if (msg.sender == owner) selfdestruct(owner);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert();
            _;
    }
}

contract Pausable is Ownable {
    bool public stopped;

    modifier stopInEmergency {
        if (stopped) {
            revert();
        }
        _;
    }

    modifier onlyInEmergency {
        if (!stopped) {
            revert();
        }
        _;
    }

     
    function emergencyStop() external onlyOwner {
        stopped = true;
    }

     
    function release() external onlyOwner onlyInEmergency {
        stopped = false;
    }
}




 
 
 
contract Presale is SafeMath, Pausable {

    struct Backer {
        uint weiReceived;    
        uint SOCXSent;       
        bool processed;      
    }
    
    address public multisigETH;  
    uint public ETHReceived;     
    uint public SOCXSentToETH;   
    uint public startBlock;      
    uint public endBlock;        

    uint public minContributeETH; 
    bool public presaleClosed;   
    uint public maxCap;          

    uint totalTokensSold;        
    uint tokenPriceWei;          


    uint multiplier = 10000000000;               
    mapping(address => Backer) public backers;   
    address[] public backersIndex;               


     
     
    modifier onlyBy(address a) {
        if (msg.sender != a) revert();
        _;
    }

     
    modifier respectTimeFrame() {
        if ((block.number < startBlock) || (block.number > endBlock)) revert();
        _;
    }



     
    event ReceivedETH(address backer, uint amount, uint tokenAmount);



     
     
    function Presale() {     
           
        multisigETH = 0x7bf08cb1732e1246c65b51b83ac092f9b4ebb8c6;  
        maxCap = 2000000 * multiplier;   
        SOCXSentToETH = 0;               
        minContributeETH = 1 ether;      
        startBlock = 0;                  
        endBlock = 0;                    
        tokenPriceWei = 720000000000000; 
    }

     
     
     
    function numberOfBackers() constant returns(uint) {
        return backersIndex.length;
    }

    function updateMultiSig(address _multisigETH) onlyBy(owner) {
        multisigETH = _multisigETH;
    }


     
     
    function () payable {
        if (block.number > endBlock) revert();
        handleETH(msg.sender);
    }

     
     
    function start() onlyBy(owner) {
        startBlock = block.number;        
        endBlock = startBlock + 57600;
         
         
    }

     
     
    function process(address _backer) onlyBy(owner) returns (bool){

        Backer storage backer = backers[_backer]; 
        backer.processed = true;

        return true;
    }

     
     
     
    function handleETH(address _backer) internal stopInEmergency respectTimeFrame returns(bool res) {

        if (msg.value < minContributeETH) revert();                      
        uint SOCXToSend = (msg.value / tokenPriceWei) * multiplier;  

        
        if (safeAdd(SOCXSentToETH, SOCXToSend) > maxCap) revert();   

        Backer storage backer = backers[_backer];                    
        backer.SOCXSent = safeAdd(backer.SOCXSent, SOCXToSend);      
        backer.weiReceived = safeAdd(backer.weiReceived, msg.value); 
        ETHReceived = safeAdd(ETHReceived, msg.value);               
        SOCXSentToETH = safeAdd(SOCXSentToETH, SOCXToSend);          
        backersIndex.push(_backer);                                  

        ReceivedETH(_backer, msg.value, SOCXToSend);                 
        return true;
    }



     
     
     
    function finalize() onlyBy(owner) {

        if (block.number < endBlock && SOCXSentToETH < maxCap) revert();

        if (!multisigETH.send(this.balance)) revert();
        presaleClosed = true;

    }

    
     
     
    function drain() onlyBy(owner) {
        if (!owner.send(this.balance)) revert();
    }

}