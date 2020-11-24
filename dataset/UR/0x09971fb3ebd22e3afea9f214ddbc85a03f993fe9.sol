 

pragma solidity ^ 0.4.17;


library SafeMath {
    function mul(uint a, uint b) pure internal returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint a, uint b) pure internal returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) pure internal returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}





contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) 
            owner = newOwner;
    }

    function kill() public {
        if (msg.sender == owner) 
            selfdestruct(owner);
    }

    modifier onlyOwner() {
        if (msg.sender == owner)
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

     
    function emergencyStop() external onlyOwner() {
        stopped = true;
    }

     
    function release() external onlyOwner() onlyInEmergency {
        stopped = false;
    }
}


 
 
contract Crowdsale is Pausable {

    using SafeMath for uint;

    struct Backer {
        uint weiReceived;  
        uint tokensSent;  
        bool refunded;  
    }

    Token public token;  
    address public multisig;  
    address public team;  
    uint public ethReceivedPresale;  
    uint public ethReceivedMain;  
    uint public totalTokensSent;  
    uint public startBlock;  
    uint public endBlock;  
    uint public maxCap;  
    uint public minCap;  
    uint public minInvestETH;  
    bool public crowdsaleClosed;  
    Step public currentStep;   
    uint public refundCount;   
    uint public totalRefunded;  
    uint public tokenPriceWei;   

    mapping(address => Backer) public backers;  
    address[] public backersIndex;  

    
     
    modifier respectTimeFrame() {
        if ((block.number < startBlock) || (block.number > endBlock)) 
            revert();
        _;
    }

     
    enum Step {
        Unknown,
        FundingPreSale,      
        FundingPublicSale,   
        Refunding   
    }

     
    event ReceivedETH(address backer, uint amount, uint tokenAmount);
    event RefundETH(address backer, uint amount);


     
     
    function Crowdsale() public {
        multisig = 0xc15464420aC025077Ba280cBDe51947Fc12583D6; 
        team = 0xc15464420aC025077Ba280cBDe51947Fc12583D6;                                  
        minInvestETH = 1 ether/100;
        startBlock = 0;  
        endBlock = 0;  
        tokenPriceWei = 1 ether/8000;
        maxCap = 30600000e18;         
        minCap = 900000e18;        
        totalTokensSent = 1253083e18;  
        setStep(Step.FundingPreSale);
    }

     
    function returnWebsiteData() external view returns(uint, uint, uint, uint, uint, uint, uint, uint, Step, bool, bool) {            
    
        return (startBlock, endBlock, backersIndex.length, ethReceivedPresale.add(ethReceivedMain), maxCap, minCap, totalTokensSent, tokenPriceWei, currentStep, stopped, crowdsaleClosed);
    }

     
    function fundContract() external payable onlyOwner() returns (bool) {
        return true;
    }

     
     
     
    function updateTokenAddress(Token _tokenAddress) external onlyOwner() returns(bool res) {
        token = _tokenAddress;
        return true;
    }

     
     
    function setStep(Step _step) public onlyOwner() {
        currentStep = _step;
        
        if (currentStep == Step.FundingPreSale) {   
            tokenPriceWei = 1 ether/8000;  
            minInvestETH = 1 ether/100;                             
        }else if (currentStep == Step.FundingPublicSale) {  
            tokenPriceWei = 1 ether/5000;   
            minInvestETH = 0;               
        }            
    }

     
     
    function numberOfBackers() external view returns(uint) {
        return backersIndex.length;
    }

     
     
    function () external payable {           
        contribute(msg.sender);
    }

     
    function start(uint _block) external onlyOwner() {   

        require(_block < 246528);   
        startBlock = block.number;
        endBlock = startBlock.add(_block); 
    }

     
     
    function adjustDuration(uint _block) external onlyOwner() {

        require(_block < 308160);   
        require(_block > block.number.sub(startBlock));  
        endBlock = startBlock.add(_block); 
    }

     
     
     
    function contribute(address _backer) internal stopInEmergency respectTimeFrame returns(bool res) {
    
        require(currentStep == Step.FundingPreSale || currentStep == Step.FundingPublicSale);  
        require(msg.value >= minInvestETH);    
          
        uint tokensToSend = msg.value.mul(1e18) / tokenPriceWei;  
        require(totalTokensSent.add(tokensToSend) < maxCap);  
            
        Backer storage backer = backers[_backer];
    
        if (backer.weiReceived == 0)      
            backersIndex.push(_backer);
           
        backer.tokensSent = backer.tokensSent.add(tokensToSend);  
        backer.weiReceived = backer.weiReceived.add(msg.value);   
        totalTokensSent = totalTokensSent.add(tokensToSend);      
    
        if (Step.FundingPublicSale == currentStep)   
            ethReceivedMain = ethReceivedMain.add(msg.value);
        else
            ethReceivedPresale = ethReceivedPresale.add(msg.value);     

        if (!token.transfer(_backer, tokensToSend)) 
            revert();  
    
        multisig.transfer(this.balance);    
    
        ReceivedETH(_backer, msg.value, tokensToSend);  
        return true;
    }

     
     
     
    function finalize() external onlyOwner() {

        require(!crowdsaleClosed);        
         
         
        require(block.number >= endBlock || totalTokensSent >= maxCap.sub(1000));                 
        require(totalTokensSent >= minCap);   

        crowdsaleClosed = true;  
        
        if (!token.transfer(team, token.balanceOf(this)))  
            revert();
        token.unlock();                      
    }

     
    function drain() external onlyOwner() {
        multisig.transfer(this.balance);               
    }

     
    function tokenDrian() external onlyOwner() {
        if (block.number > endBlock) {
            if (!token.transfer(team, token.balanceOf(this))) 
                revert();
        }
    }
    
     
    function refund() external stopInEmergency returns (bool) {

        require(currentStep == Step.Refunding);         
       
        require(this.balance > 0);   
                                     

        Backer storage backer = backers[msg.sender];

        require(backer.weiReceived > 0);   
        require(!backer.refunded);          

        if (!token.returnTokens(msg.sender, backer.tokensSent))  
            revert();
        backer.refunded = true;   
    
        refundCount++;
        totalRefunded = totalRefunded.add(backer.weiReceived);
        msg.sender.transfer(backer.weiReceived);   
        RefundETH(msg.sender, backer.weiReceived);
        return true;
    }
}


contract ERC20 {
    uint public totalSupply;
   
    function transfer(address to, uint value) public returns(bool ok);  
    function balanceOf(address who) public view returns(uint);
}


 
contract Token is ERC20, Ownable {

    function returnTokens(address _member, uint256 _value) public returns(bool);
    function unlock() public;
}