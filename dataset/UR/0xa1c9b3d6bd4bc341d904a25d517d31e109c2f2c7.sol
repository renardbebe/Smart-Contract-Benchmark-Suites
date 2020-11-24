 

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


     
     
    function kill() public {
        if (msg.sender == owner) 
            selfdestruct(multisig);
    }

     
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
        minInvestETH = 3 ether;
        startBlock = 0;  
        endBlock = 0;  
        tokenPriceWei = 1 ether/2000;
        maxCap = 30600000e18;         
        minCap = 1000 ether;        
        setStep(Step.FundingPreSale);
    }

     
    function returnWebsiteData() external view returns(uint, uint, uint, uint, uint, uint, uint, uint, Step, bool, bool) {            
    
        return (startBlock, endBlock, backersIndex.length, ethReceivedPresale.add(ethReceivedMain), maxCap, minCap, totalTokensSent,  tokenPriceWei, currentStep, stopped, crowdsaleClosed);
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
            tokenPriceWei = 500000000000000;     
            minInvestETH = 3 ether;                             
        }else if (currentStep == Step.FundingPublicSale) {  
            tokenPriceWei = 833333000000000;   
            minInvestETH = 0;               
        }            
    }


     
     
    function numberOfBackers() public view returns(uint) {
        return backersIndex.length;
    }


     
     
    function () external payable {           
        contribute(msg.sender);
    }


     
    function start(uint _block) external onlyOwner() {   

        require(_block < 216000);   
        startBlock = block.number;
        endBlock = startBlock.add(_block); 
    }

     
     
    function adjustDuration(uint _block) external onlyOwner() {

        require(_block < 288000);   
        require(_block > block.number.sub(startBlock));  
        endBlock = startBlock.add(_block); 
    }

     
     
     
    function contribute(address _backer) internal stopInEmergency respectTimeFrame returns(bool res) {
    
        require(currentStep == Step.FundingPreSale || currentStep == Step.FundingPublicSale);  
        require (msg.value >= minInvestETH);    
          
        uint tokensToSend = msg.value.mul(1e18) / tokenPriceWei;  
        require(totalTokensSent.add(tokensToSend) < maxCap);  
            
        Backer storage backer = backers[_backer];
    
         if (backer.weiReceived == 0)      
            backersIndex.push(_backer);
    
        if (!token.transfer(_backer, tokensToSend)) 
            revert();  
        backer.tokensSent = backer.tokensSent.add(tokensToSend);  
        backer.weiReceived = backer.weiReceived.add(msg.value);   
        totalTokensSent = totalTokensSent.add(tokensToSend);      
    
        if (Step.FundingPublicSale == currentStep)   
                ethReceivedMain = ethReceivedMain.add(msg.value);
        else
                ethReceivedPresale = ethReceivedPresale.add(msg.value);        
    
        multisig.transfer(this.balance);    
    
        ReceivedETH(_backer, msg.value, tokensToSend);  
        return true;
    }

  

     
     
     
    function finalize() external onlyOwner() {

        require(!crowdsaleClosed);        
         
         
        require (block.number >= endBlock || totalTokensSent >= maxCap.sub(100)); 
        
        uint totalEtherReceived = ethReceivedPresale.add(ethReceivedMain);
        require(totalEtherReceived >= minCap);   
        
        if (!token.transfer(team, token.balanceOf(this)))  
                revert();
            token.unlock();
        
        crowdsaleClosed = true;        
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
        
        uint totalEtherReceived = ethReceivedPresale.add(ethReceivedMain);

        require(totalEtherReceived < minCap);   
        require(this.balance > 0);   
                                     

        Backer storage backer = backers[msg.sender];

        require (backer.weiReceived > 0);   
        require(!backer.refunded);          

        if (!token.burn(msg.sender, backer.tokensSent))  
            revert();
        backer.refunded = true;   
    
        refundCount ++;
        totalRefunded = totalRefunded.add(backer.weiReceived);
        msg.sender.transfer(backer.weiReceived);   
        RefundETH(msg.sender, backer.weiReceived);
        return true;
    }
}

 
contract Token is ERC20,  Ownable {

    using SafeMath for uint;
     
    string public name;
    string public symbol;
    uint8 public decimals;  
    string public version = "v0.1";       
    uint public totalSupply;
    bool public locked;
    address public crowdSaleAddress;
    


    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

     
    modifier onlyUnlocked() {
        if (msg.sender != crowdSaleAddress && locked) 
            revert();
        _;
    }


     
    modifier onlyAuthorized() {
        if (msg.sender != owner && msg.sender != crowdSaleAddress ) 
            revert();
        _;
    }


     
    function Token(address _crowdSaleAddress) public {
        
        locked = true;   
        totalSupply = 60000000e18; 
        name = "Requitix";  
        symbol = "RQX";  
        decimals = 18;  
        crowdSaleAddress = _crowdSaleAddress;                                  
        balances[crowdSaleAddress] = totalSupply;
    }

    function unlock() public onlyAuthorized {
        locked = false;
    }

    function lock() public onlyAuthorized {
        locked = true;
    }
    

    function burn( address _member, uint256 _value) public onlyAuthorized returns(bool) {
        balances[_member] = balances[_member].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Transfer(_member, 0x0, _value);
        return true;
    }

    function transfer(address _to, uint _value) public onlyUnlocked returns(bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    
    function transferFrom(address _from, address _to, uint256 _value) public onlyUnlocked returns(bool success) {
        require (balances[_from] >= _value);  
        require (_value <= allowed[_from][msg.sender]);  
        balances[_from] = balances[_from].sub(_value);  
        balances[_to] = balances[_to].add(_value);  
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns(uint balance) {
        return balances[_owner];
    }


     
    function approve(address _spender, uint _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) public view returns(uint remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
        } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}