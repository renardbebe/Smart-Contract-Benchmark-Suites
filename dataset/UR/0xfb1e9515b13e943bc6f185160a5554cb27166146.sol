 

pragma solidity ^ 0.4.18;


library SafeMath {
    function mul(uint a, uint b) internal pure  returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint a, uint b) internal pure  returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure  returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}





 
contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}

 
contract WhiteList is Ownable {

    function isWhiteListed(address _user) external view returns (bool);        
}

 
 
contract Crowdsale is Pausable {

    using SafeMath for uint;

    struct Backer {
        uint weiReceived;  
        uint tokensToSend;  
        bool refunded;
    }

    Token public token;  
    address public multisig;  
    address public team;  
    uint public ethReceivedPresale;  
    uint public ethReceivedMain;  
    uint public tokensSentPresale;  
    uint public tokensSentMain;  
    uint public totalTokensSent;  
    uint public startBlock;  
    uint public endBlock;  
    uint public maxCap;  
    uint public minInvestETH;  
    bool public crowdsaleClosed;  
    Step public currentStep;   
    uint public refundCount;   
    uint public totalRefunded;  
    uint public dollarToEtherRatio;  
    uint public numOfBlocksInMinute;  
    WhiteList public whiteList;      

    mapping(address => Backer) public backers;  
    address[] public backersIndex;  
    uint public priorTokensSent; 
    uint public presaleCap;
   

     
    modifier respectTimeFrame() {
        require(block.number >= startBlock && block.number <= endBlock);
        _;
    }

     
    enum Step {      
        FundingPreSale,      
        FundingPublicSale,   
        Refunding   
    }

     
    event ReceivedETH(address indexed backer, uint amount, uint tokenAmount);
    event RefundETH(address indexed backer, uint amount);

     
     
     
    function Crowdsale(WhiteList _whiteList) public {               
        multisig = 0x10f78f2a70B52e6c3b490113c72Ba9A90ff1b5CA; 
        team = 0x10f78f2a70B52e6c3b490113c72Ba9A90ff1b5CA; 
        maxCap = 1510000000e8;             
        minInvestETH = 1 ether/2;    
        currentStep = Step.FundingPreSale;
        dollarToEtherRatio = 56413;       
        numOfBlocksInMinute = 408;           
        priorTokensSent = 4365098999e7;      
        whiteList = _whiteList;              
        presaleCap = 107000000e8;            

    }

     
    function returnWebsiteData() external view returns(uint, uint, uint, uint, uint, uint, Step, bool, bool) {            
    
        return (startBlock, endBlock, backersIndex.length, ethReceivedPresale + ethReceivedMain, maxCap, totalTokensSent, currentStep, paused, crowdsaleClosed);
    }

     
     
     
    function setTokenAddress(Token _tokenAddress) external onlyOwner() returns(bool res) {
        require(token == address(0));
        token = _tokenAddress;
        return true;
    }

     
     
     
    function advanceStep() public onlyOwner() {

        currentStep = Step.FundingPublicSale;                                             
        minInvestETH = 1 ether/4;                                     
    }

     
     
    function prepareRefund() public payable onlyOwner() {
        
        require(msg.value == ethReceivedPresale.add(ethReceivedMain));  
        currentStep = Step.Refunding;
    }

     
     
    function numberOfBackers() public view returns(uint) {
        return backersIndex.length;
    }

     
     
     
    function () external payable {           
        contribute(msg.sender);
    }

     
    function start(uint _block) external onlyOwner() {   

        require(_block <= (numOfBlocksInMinute * 60 * 24 * 55)/100);   
        startBlock = block.number;
        endBlock = startBlock.add(_block); 
    }

     
     
    function adjustDuration(uint _block) external onlyOwner() {

        require(_block < (numOfBlocksInMinute * 60 * 24 * 60)/100);  
        require(_block > block.number.sub(startBlock));  
        endBlock = startBlock.add(_block); 
    }   

     
     
    function adjustDollarToEtherRatio(uint _dollarToEtherRatio) external onlyOwner() {
        require(_dollarToEtherRatio > 0);
        dollarToEtherRatio = _dollarToEtherRatio;
    }

     
     
     
    function contribute(address _backer) internal whenNotPaused() respectTimeFrame() returns(bool res) {

        require(whiteList.isWhiteListed(_backer));       

        uint tokensToSend = determinePurchase();
            
        Backer storage backer = backers[_backer];

        if (backer.weiReceived == 0)
            backersIndex.push(_backer);
       
        backer.tokensToSend += tokensToSend;  
        backer.weiReceived = backer.weiReceived.add(msg.value);   

        if (Step.FundingPublicSale == currentStep) {  
            ethReceivedMain = ethReceivedMain.add(msg.value);
            tokensSentMain += tokensToSend;
        }else {                                                  
            ethReceivedPresale = ethReceivedPresale.add(msg.value); 
            tokensSentPresale += tokensToSend;
        }
                                                     
        totalTokensSent += tokensToSend;      
        multisig.transfer(this.balance);    

        if (!token.transfer(_backer, tokensToSend)) 
            revert();  

        ReceivedETH(_backer, msg.value, tokensToSend);  
        return true;
    }

     
     
    function determinePurchase() internal view  returns (uint) {

        require(msg.value >= minInvestETH);    
        uint tokenAmount = dollarToEtherRatio.mul(msg.value)/4e10;   
        
        uint tokensToSend;
          
        if (Step.FundingPublicSale == currentStep) {   
            tokensToSend = tokenAmount;
            require(totalTokensSent + tokensToSend + priorTokensSent <= maxCap);  
        }else {
            tokensToSend = tokenAmount + (tokenAmount * 50) / 100; 
            require(totalTokensSent + tokensToSend <= presaleCap);  
        }                                                        
       
        return tokensToSend;
    }

    
     
     
     
    function finalize() external onlyOwner() {

        require(!crowdsaleClosed);        
         
         
        require(block.number >= endBlock || totalTokensSent + priorTokensSent >= maxCap - 1000);                        
        crowdsaleClosed = true; 
        
        if (!token.transfer(team, token.balanceOf(this)))  
            revert();        
        token.unlock();                      
    }

     
    function drain() external onlyOwner() {
        multisig.transfer(this.balance);               
    }

     
    function tokenDrain() external onlyOwner() {
        if (block.number > endBlock) {
            if (!token.transfer(multisig, token.balanceOf(this))) 
                revert();
        }
    }
    
     
     
    function refund() external whenNotPaused() returns (bool) {

        require(currentStep == Step.Refunding);                        

        Backer storage backer = backers[msg.sender];

        require(backer.weiReceived > 0);   
        require(!backer.refunded);         

        backer.refunded = true;   
        refundCount++;
        totalRefunded = totalRefunded + backer.weiReceived;

        if (!token.transfer(msg.sender, backer.tokensToSend))  
            revert();                            
        msg.sender.transfer(backer.weiReceived);   
        RefundETH(msg.sender, backer.weiReceived);
        return true;
    }

   

}


contract ERC20 {
    uint public totalSupply;

    function balanceOf(address who) public view returns(uint);

    function allowance(address owner, address spender) public view returns(uint);

    function transfer(address to, uint value) public returns(bool ok);

    function transferFrom(address from, address to, uint value) public returns(bool ok);

    function approve(address spender, uint value) public returns(bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract Token is ERC20, Ownable {
   
    function unlock() public;

}