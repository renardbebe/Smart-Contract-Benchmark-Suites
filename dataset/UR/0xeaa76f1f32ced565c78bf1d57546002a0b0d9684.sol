 

pragma solidity 0.4.21;


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
    address public newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
        newOwner = address(0);
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(address(0) != _newOwner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, msg.sender);
        owner = msg.sender;
        newOwner = address(0);
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
        emit Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
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
    uint public numOfBlocksInMinute;  
    WhiteList public whiteList;      
    uint public tokenPriceWei;       

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

        require(_whiteList != address(0));
        multisig = 0x10f78f2a70B52e6c3b490113c72Ba9A90ff1b5CA;
        team = 0x10f78f2a70B52e6c3b490113c72Ba9A90ff1b5CA;
        maxCap = 1510000000e8;
        minInvestETH = 1 ether/2;
        currentStep = Step.FundingPreSale;
        numOfBlocksInMinute = 408;           
        priorTokensSent = 4365098999e7;      
        whiteList = _whiteList;              
        presaleCap = 160000000e8;            
        tokenPriceWei = 57142857142857;      
    }

     
     
     
    function setTokenAddress(Token _tokenAddress) external onlyOwner() returns(bool res) {
        require(token == address(0));
        token = _tokenAddress;
        return true;
    }

     
     
     
    function advanceStep() public onlyOwner() {
        require(Step.FundingPreSale == currentStep);
        currentStep = Step.FundingPublicSale;
        minInvestETH = 1 ether/4;
    }

     
     
    function prepareRefund() public payable onlyOwner() {

        require(crowdsaleClosed);
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

        require(startBlock == 0);
        require(_block <= (numOfBlocksInMinute * 60 * 24 * 54)/100);   
        startBlock = block.number;
        endBlock = startBlock.add(_block);
    }

     
     
    function adjustDuration(uint _block) external onlyOwner() {

        require(startBlock > 0);
        require(_block < (numOfBlocksInMinute * 60 * 24 * 60)/100);  
        require(_block > block.number.sub(startBlock));  
        endBlock = startBlock.add(_block);
    }

     
     
     
    function contribute(address _backer) internal whenNotPaused() respectTimeFrame() returns(bool res) {
        require(!crowdsaleClosed);
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
        multisig.transfer(address(this).balance);    

        require(token.transfer(_backer, tokensToSend));    

        emit ReceivedETH(_backer, msg.value, tokensToSend);  
        return true;
    }

     
     
    function determinePurchase() internal view  returns (uint) {

        require(msg.value >= minInvestETH);    

        uint tokensToSend = msg.value.mul(1e8) / tokenPriceWei;    

        if (Step.FundingPublicSale == currentStep) {   
            require(totalTokensSent + tokensToSend + priorTokensSent <= maxCap);  
        }else {
            tokensToSend += (tokensToSend * 50) / 100;
            require(totalTokensSent + tokensToSend <= presaleCap);  
        }
        return tokensToSend;
    }


     
     
     
    function finalize() external onlyOwner() {

        require(!crowdsaleClosed);
         
         
        require(block.number >= endBlock || totalTokensSent + priorTokensSent >= maxCap - 1000);
        crowdsaleClosed = true;

        require(token.transfer(team, token.balanceOf(this)));  
        token.unlock();
    }

     
    function drain() external onlyOwner() {
        multisig.transfer(address(this).balance);
    }

     
    function tokenDrain() external onlyOwner() {
        if (block.number > endBlock) {
            require(token.transfer(multisig, token.balanceOf(this)));
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

        require(token.transfer(msg.sender, backer.tokensToSend));  
        msg.sender.transfer(backer.weiReceived);   
        emit RefundETH(msg.sender, backer.weiReceived);
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

    using SafeMath for uint;

     
    string public name;
    string public symbol;
    uint8 public decimals;  
    string public version = "v0.1";
    uint public totalSupply;
    bool public locked;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    address public crowdSaleAddress;


     
    modifier onlyUnlocked() {
        if (msg.sender != crowdSaleAddress && msg.sender != owner && locked)
            revert();
        _;
    }

    modifier onlyAuthorized() {
        if (msg.sender != owner && msg.sender != crowdSaleAddress)
            revert();
        _;
    }

     
    function Token(address _crowdsaleAddress) public {

        require(_crowdsaleAddress != address(0));
        locked = true;  
        totalSupply = 2600000000e8;
        name = "Kripton";                            
        symbol = "LPK";                              
        decimals = 8;                                
        crowdSaleAddress = _crowdsaleAddress;
        balances[_crowdsaleAddress] = totalSupply;
    }

     
    function unlock() public onlyAuthorized {
        locked = false;
    }

     
    function lock() public onlyAuthorized {
        locked = true;
    }

     
     
     
     
    function transfer(address _to, uint _value) public onlyUnlocked returns(bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public onlyUnlocked returns(bool success) {
        require(balances[_from] >= _value);  
        require(_value <= allowed[_from][msg.sender]);  
        balances[_from] = balances[_from].sub(_value);  
        balances[_to] = balances[_to].add(_value);  
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
     
    function balanceOf(address _owner) public view returns(uint balance) {
        return balances[_owner];
    }

     
    function approve(address _spender, uint _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
    function allowance(address _owner, address _spender) public view returns(uint remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

 
 
contract WhiteList is Ownable {


    mapping(address => bool) public whiteList;
    uint public totalWhiteListed;  

    event LogWhiteListed(address indexed user, uint whiteListedNum);
    event LogWhiteListedMultiple(uint whiteListedNum);
    event LogRemoveWhiteListed(address indexed user);

     
     
    function isWhiteListed(address _user) external view returns (bool) {

        return whiteList[_user];
    }

     
     
    function removeFromWhiteList(address _user) external onlyOwner() {

        require(whiteList[_user] == true);
        whiteList[_user] = false;
        totalWhiteListed--;
        emit LogRemoveWhiteListed(_user);
    }

     
     
     
    function addToWhiteList(address _user) external onlyOwner() {

        if (whiteList[_user] != true) {
            whiteList[_user] = true;
            totalWhiteListed++;
            emit LogWhiteListed(_user, totalWhiteListed);
        }else

            revert();
    }

     
     
     
    function addToWhiteListMultiple(address[] _users) external onlyOwner() {

        for (uint i = 0; i < _users.length; ++i) {

            if (whiteList[_users[i]] != true) {
                whiteList[_users[i]] = true;
                totalWhiteListed++;
            }
        }
        emit LogWhiteListedMultiple(totalWhiteListed);
    }
}