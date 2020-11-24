 

pragma solidity ^ 0.4.17;

contract SafeMath {
    function safeMul(uint a, uint b) pure internal returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) pure internal returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) pure internal returns(uint) {
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

     
    function emergencyStop() external onlyOwner {
        stopped = true;
    }

     
    function release() external onlyOwner onlyInEmergency {
        stopped = false;
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


contract Token is ERC20, SafeMath, Ownable {

    function transfer(address _to, uint _value) public returns(bool);
}

 
 
contract Presale is SafeMath, Pausable {

    struct Backer {
        uint weiReceived;  
        uint tokensToSend;  
        bool claimed;
        bool refunded;
    }
   
    address public multisig;  
    uint public ethReceived;  
    uint public tokensSent;  
    uint public startBlock;  
    uint public endBlock;  

    uint public minInvestment;  
    uint public maxInvestment;  
    bool public presaleClosed;  
    uint public tokenPriceWei;  
    Token public token;  


    mapping(address => Backer) public backers;  
    address[] public backersIndex;   
    uint public maxCap;   
    uint public claimCount;   
    uint public refundCount;   
    uint public totalClaimed;   
    uint public totalRefunded;   
    bool public mainSaleSuccessfull;  
    mapping(address => uint) public claimed;  
    mapping(address => uint) public refunded;  


     
    modifier respectTimeFrame() {
        if ((block.number < startBlock) || (block.number > endBlock)) 
            revert();
        _;
    }

     
    function kill() public {
        if (msg.sender == owner) 
            selfdestruct(multisig);
    }


     
    event ReceivedETH(address backer, uint amount, uint tokenAmount);
    event TokensClaimed(address backer, uint count);
    event Refunded(address backer, uint amount);



     
     
    function Presale() public {        
        multisig = 0xF821Fd99BCA2111327b6a411C90BE49dcf78CE0f; 
        minInvestment = 5e17;   
        maxInvestment = 75 ether;      
        maxCap = 82500000e18;
        startBlock = 0;  
        endBlock = 0;  
        tokenPriceWei = 1100000000000000;      
        tokensSent = 2534559883e16;         
    }

     
     
    function numberOfBackers() public view returns(uint) {
        return backersIndex.length;
    }

     
    function returnWebsiteData() external view returns(uint, uint, uint, uint, uint, uint, uint, uint, uint, bool, bool) {
    
        return (startBlock, endBlock, numberOfBackers(), ethReceived, maxCap, tokensSent, tokenPriceWei, minInvestment, maxInvestment, stopped, presaleClosed );
    }

     
     
    function claimTokensForUser(address _backer) onlyOwner() external returns(bool) {

        require (!backer.refunded);  
        require (!backer.claimed);  
        require (backer.tokensToSend != 0);  
        Backer storage backer = backers[_backer];
        backer.claimed = true;   

        if (!token.transfer(_backer, backer.tokensToSend)) 
            revert();  

        TokensClaimed(msg.sender, backer.tokensToSend);  
        return true;
    }


     
     
    function () public payable {
        contribute(msg.sender);
    }

     
    function fundContract() external payable onlyOwner() returns (bool) {
        mainSaleSuccessfull = false;
        return true;
    }

     
     
    function start(uint _block) external onlyOwner() {
        require(_block < 54000);   
        startBlock = block.number;
        endBlock = safeAdd(startBlock, _block);   
    }

     
     
     
    function adjustDuration(uint _block) external onlyOwner() {
        
        require(_block <= 72000);   
        require(_block > safeSub(block.number, startBlock));  
        endBlock = safeAdd(startBlock, _block);   
    }

    


     
     
    function setToken(Token _token) public onlyOwner() returns(bool) {

        token = _token;
        mainSaleSuccessfull = true;
        return true;
    }

     
     
    function setMainCampaignStatus(bool _status) public onlyOwner() {
        mainSaleSuccessfull = _status;
    }

     
     
     

    function contribute(address _contributor) internal stopInEmergency respectTimeFrame returns(bool res) {
         
        require (msg.value >= minInvestment && msg.value <= maxInvestment);   
                   
        uint tokensToSend = calculateNoOfTokensToSend();
        
        require (safeAdd(tokensSent, tokensToSend) <= maxCap);   

        Backer storage backer = backers[_contributor];

        if (backer.weiReceived == 0)
            backersIndex.push(_contributor);

        backer.tokensToSend = safeAdd(backer.tokensToSend, tokensToSend);
        backer.weiReceived = safeAdd(backer.weiReceived, msg.value);
        ethReceived = safeAdd(ethReceived, msg.value);  
        tokensSent = safeAdd(tokensSent, tokensToSend);

        multisig.transfer(msg.value);   

        ReceivedETH(_contributor, msg.value, tokensToSend);  
        return true;
    }

     
     

    function calculateNoOfTokensToSend() view internal returns(uint) {
         
        uint tokenAmount = safeMul(msg.value, 1e18) / tokenPriceWei;
        uint ethAmount = msg.value;

        if (ethAmount >= 50 ether)
            return tokenAmount + (tokenAmount * 5) / 100;   
        else if (ethAmount >= 15 ether)
            return tokenAmount + (tokenAmount * 25) / 1000;  
        else 
            return tokenAmount;
    }

     
     

    function finalize() external onlyOwner() {

        require (!presaleClosed);           
        require (block.number >= endBlock);                          
        presaleClosed = true;
    }


     
     

    function claimTokens() external {

        require(mainSaleSuccessfull);
       
        require (token != address(0));   
                                         
                                         
           
        Backer storage backer = backers[msg.sender];

        require (!backer.refunded);  
        require (!backer.claimed);  
        require (backer.tokensToSend != 0);    

        claimCount++;
        claimed[msg.sender] = backer.tokensToSend;   
        backer.claimed = true;
        totalClaimed = safeAdd(totalClaimed, backer.tokensToSend);
        
        if (!token.transfer(msg.sender, backer.tokensToSend)) 
            revert();  

        TokensClaimed(msg.sender, backer.tokensToSend);  
    }

     
     
     

    function refund() external {

        require(!mainSaleSuccessfull);   
        require(this.balance > 0);   
                                     
        Backer storage backer = backers[msg.sender];

        require (!backer.claimed);  
        require (!backer.refunded);  
        require(backer.weiReceived != 0);   

        backer.refunded = true;  
        totalRefunded = safeAdd(totalRefunded, backer.weiReceived);
        refundCount ++;
        refunded[msg.sender] = backer.weiReceived;

        msg.sender.transfer(backer.weiReceived);   
        Refunded(msg.sender, backer.weiReceived);  
    }


     
    function drain() external onlyOwner() {
        multisig.transfer(this.balance);
            
    }
}