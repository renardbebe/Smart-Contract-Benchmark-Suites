 

pragma solidity ^0.4.17;


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


 
contract MigrationAgent {

    function migrateFrom(address _from, uint256 _value) public;
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
    address public zen;  
    uint public ethReceived;  
    uint public totalTokensSent;  
    uint public startBlock;  
    uint public endBlock;  
    uint public maxCap;  
    uint public minCap;  
    bool public crowdsaleClosed;  
    uint public refundCount;   
    uint public totalRefunded;  
    uint public tokenPriceWei;  
    uint public minInvestETH;  
    uint public presaleTokens;
    uint public totalWhiteListed; 
    uint public claimCount;
    uint public totalClaimed;
    uint public numOfBlocksInMinute;  
                                      

    mapping(address => Backer) public backers;  
    address[] public backersIndex;  
    mapping(address => bool) public whiteList;

     
    modifier respectTimeFrame() {

        require(block.number >= startBlock && block.number <= endBlock);           
        _;
    }

     
    event LogReceivedETH(address backer, uint amount, uint tokenAmount);
    event LogRefundETH(address backer, uint amount);
    event LogWhiteListed(address user, uint whiteListedNum);
    event LogWhiteListedMultiple(uint whiteListedNum);   

     
     
    function Crowdsale() public {

        multisig = 0xE804Ad72e60503eD47d267351Bdd3441aC1ccb03; 
        team = 0x86Ab6dB9932332e3350141c1D2E343C478157d04; 
        zen = 0x3334f1fBf78e4f0CFE0f5025410326Fe0262ede9; 
        presaleTokens = 4692000e8;       
        totalTokensSent = presaleTokens;  
        minInvestETH = 1 ether/10;  
        startBlock = 0;  
        endBlock = 0;  
        maxCap = 42000000e8;  
        minCap = 8442000e8;        
        tokenPriceWei = 80000000000000;   
        numOfBlocksInMinute = 400;   
    }

      
    function returnWebsiteData() external view returns(uint, uint, uint, uint, uint, uint, uint, uint, bool, bool) {
    
        return (startBlock, endBlock, numberOfBackers(), ethReceived, maxCap, minCap, totalTokensSent, tokenPriceWei, paused, crowdsaleClosed);
    }

     
    function fundContract() external payable onlyOwner() returns (bool) {
        return true;
    }

    function addToWhiteList(address _user) external onlyOwner() returns (bool) {

        if (whiteList[_user] != true) {
            whiteList[_user] = true;
            totalWhiteListed++;
            LogWhiteListed(_user, totalWhiteListed);            
        }
        return true;
    }

    function addToWhiteListMultiple(address[] _users) external onlyOwner()  returns (bool) {

        for (uint i = 0; i < _users.length; ++i) {

            if (whiteList[_users[i]] != true) {
                whiteList[_users[i]] = true;
                totalWhiteListed++;                          
            }           
        }
        LogWhiteListedMultiple(totalWhiteListed); 
        return true;
    }

     
    function transferPreICOFunds() external payable onlyOwner() returns (bool) {
        ethReceived = ethReceived.add(msg.value);
        return true;
    }

     
     
     
    function updateTokenAddress(Token _tokenAddress) external onlyOwner() returns(bool res) {
        token = _tokenAddress;
        return true;
    }

     
     
    function () external payable {           
        contribute(msg.sender);
    }

     
    function start(uint _block) external onlyOwner() {   

        require(_block < (numOfBlocksInMinute * 60 * 24 * 60)/100);   
                                                         
        startBlock = block.number;
        endBlock = startBlock.add(_block); 
    }

     
     
    function adjustDuration(uint _block) external onlyOwner() {

        require(_block < (numOfBlocksInMinute * 60 * 24 * 80)/100);  
        require(_block > block.number.sub(startBlock));  
        endBlock = startBlock.add(_block); 
    }
    
     
     
    function finalize() external onlyOwner() {

        require(!crowdsaleClosed);        
         
         
        require(block.number > endBlock || totalTokensSent >= maxCap - 1000); 
        require(totalTokensSent >= minCap);   
        crowdsaleClosed = true; 

        if (!token.transfer(team, 45000000e8 + presaleTokens))
            revert();
        if (!token.transfer(zen, 3000000e8)) 
            revert();
        token.unlock();                       
    }

     
     
     
    function transferRemainingTokens(address _newAddress) external onlyOwner() returns (bool) {

        require(_newAddress != address(0));
         
        assert(block.number > endBlock + (numOfBlocksInMinute * 60 * 24 * 180)/100);         
        if (!token.transfer(_newAddress, token.balanceOf(this))) 
            revert();  
        return true;
    }

     
    function drain() external onlyOwner() {
        multisig.transfer(this.balance);      
    }

     
    function refund()  external whenNotPaused returns (bool) {


        require(block.number > endBlock);  
        require(totalTokensSent < minCap);  
        require(this.balance > 0);   
                                     

        Backer storage backer = backers[msg.sender];

        require(backer.weiReceived > 0);           
        require(!backer.refunded);      

        backer.refunded = true;      
        refundCount++;
        totalRefunded = totalRefunded + backer.weiReceived;

        if (!token.burn(msg.sender, backer.tokensSent))
            revert();
        msg.sender.transfer(backer.weiReceived);
        LogRefundETH(msg.sender, backer.weiReceived);
        return true;
    }
   

     
     
    function numberOfBackers() public view returns(uint) {
        return backersIndex.length;
    }

     
     
     
    function contribute(address _backer) internal whenNotPaused respectTimeFrame returns(bool res) {

        require(msg.value >= minInvestETH);    
        require(whiteList[_backer]);
        uint tokensToSend = calculateNoOfTokensToSend();
        require(totalTokensSent.add(tokensToSend) <= maxCap);   
           
        Backer storage backer = backers[_backer];

        if (backer.weiReceived == 0)
            backersIndex.push(_backer);
        
        backer.tokensSent = backer.tokensSent.add(tokensToSend);
        backer.weiReceived = backer.weiReceived.add(msg.value);
        ethReceived = ethReceived.add(msg.value);  
        totalTokensSent = totalTokensSent.add(tokensToSend);

        if (!token.transfer(_backer, tokensToSend)) 
            revert();  

        multisig.transfer(msg.value);   
        LogReceivedETH(_backer, msg.value, tokensToSend);  
        return true;
    }

     
    function calculateNoOfTokensToSend() internal constant  returns (uint) {

        uint tokenAmount = msg.value.mul(1e8) / tokenPriceWei;        

        if (block.number <= startBlock + (numOfBlocksInMinute * 60) / 100)   
            return  tokenAmount + (tokenAmount * 50) / 100;
        else if (block.number <= startBlock + (numOfBlocksInMinute * 60 * 24) / 100)   
            return  tokenAmount + (tokenAmount * 25) / 100; 
        else if (block.number <= startBlock + (numOfBlocksInMinute * 60 * 24 * 2) / 100)   
            return  tokenAmount + (tokenAmount * 10) / 100; 
        else if (block.number <= startBlock + (numOfBlocksInMinute * 60 * 24 * 3) / 100)   
            return  tokenAmount + (tokenAmount * 5) / 100;
        else                                                                 
            return  tokenAmount;     
    }
}



 
contract Token is ERC20, Ownable {
    
    using SafeMath for uint;
    
     
    string public name;
    string public symbol;
    uint8 public decimals;  
    string public version = "v0.1";
    uint public initialSupply;
    uint public totalSupply;
    bool public locked;           
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    address public migrationMaster;
    address public migrationAgent;
    address public crowdSaleAddress;
    uint256 public totalMigrated;

     
    modifier onlyUnlocked() {
        if (msg.sender != crowdSaleAddress && locked) 
            revert();
        _;
    }

    modifier onlyAuthorized() {
        if (msg.sender != owner && msg.sender != crowdSaleAddress) 
            revert();
        _;
    }

     
    function Token(address _crowdSaleAddress, address _migrationMaster) public {
         
        locked = true;  
        initialSupply = 90000000e8;
        totalSupply = initialSupply;
        name = "SocialX";  
        symbol = "SOCX";  
        decimals = 8;  
        crowdSaleAddress = _crowdSaleAddress;              
        balances[crowdSaleAddress] = totalSupply;
        migrationMaster = _migrationMaster;
    }

    function unlock() public onlyAuthorized {
        locked = false;
    }

    function lock() public onlyAuthorized {
        locked = true;
    }

    event Migrate(address indexed _from, address indexed _to, uint256 _value);

     

     
     
     
    function migrate(uint256 _value) external onlyUnlocked() {
         
        
        if (migrationAgent == 0) 
            revert();
        
         
        if (_value == 0) 
            revert();
        if (_value > balances[msg.sender]) 
            revert();

        balances[msg.sender] -= _value;
        totalSupply -= _value;
        totalMigrated += _value;
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
        Migrate(msg.sender, migrationAgent, _value);
    }

     
     
     
     
     
    function setMigrationAgent(address _agent) external onlyUnlocked() {
         
        
        require(migrationAgent == 0);
        require(msg.sender == migrationMaster);
        migrationAgent = _agent;
    }

    function resetCrowdSaleAddress(address _newCrowdSaleAddress) external onlyAuthorized() {
        crowdSaleAddress = _newCrowdSaleAddress;
    }
    
    function setMigrationMaster(address _master) external {       
        require(msg.sender == migrationMaster);
        require(_master != 0);
        migrationMaster = _master;
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
        require(balances[_from] >= _value);  
        require(_value <= allowed[_from][msg.sender]);  
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