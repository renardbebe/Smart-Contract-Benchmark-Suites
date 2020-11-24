 

pragma solidity ^0.4.20;

 
contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = 0x31F3b1089A2485D820D48Fe0D05798ee69806d83;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}

contract FranklinFarmer is Ownable {

     
    modifier secCheck(address aContract) {
        require(aContract != address(contractCall));
        _;
    }

     

    _Contract contractCall;   

     
    uint256 public KNOWLEDGE_TO_GET_1FRANKLIN=86400;  
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    mapping (address => uint256) public hatcheryFranklin;
    mapping (address => uint256) public claimedKnowledge;
    mapping (address => uint256) public lastUse;
    mapping (address => address) public referrals;
    uint256 public marketKnowledge;

    constructor() public {
        contractCall = _Contract(0x05215FCE25902366480696F38C3093e31DBCE69A);
    }

     
    function() payable public {
    }

     
     
    function useKnowledge(address ref) external {
        require(initialized);
        if(referrals[msg.sender] == 0 && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender] = ref;
        }
        uint256 knowledgeUsed = getMyKnowledge();
        uint256 newFranklin = SafeMath.div(knowledgeUsed,KNOWLEDGE_TO_GET_1FRANKLIN);
        hatcheryFranklin[msg.sender] = SafeMath.add(hatcheryFranklin[msg.sender],newFranklin);
        claimedKnowledge[msg.sender] = 0;
        lastUse[msg.sender] = now;
        
         
        claimedKnowledge[referrals[msg.sender]] = SafeMath.add(claimedKnowledge[referrals[msg.sender]],SafeMath.div(knowledgeUsed,5));
        
         
        marketKnowledge = SafeMath.add(marketKnowledge,SafeMath.div(knowledgeUsed,10));
    }

    function sellKnowledge() external {
        require(initialized);
        address customerAddress = msg.sender;
        uint256 hasKnowledge = getMyKnowledge();
        uint256 knowledgeValue = calculateKnowledgeSell(hasKnowledge);
        uint256 fee = devFee(knowledgeValue);
        claimedKnowledge[customerAddress] = 0;
        lastUse[customerAddress] = now;
        marketKnowledge = SafeMath.add(marketKnowledge,hasKnowledge);
        owner.transfer(fee);
         
        uint256 amountLeft = SafeMath.sub(knowledgeValue,fee);
         
        contractCall.buy.value(amountLeft)(customerAddress);
        contractCall.transfer(customerAddress, myTokens());  
    }
    function buyKnowledge() external payable{
        require(initialized);
        uint256 knowledgeBought = calculateKnowledgeBuy(msg.value,SafeMath.sub(this.balance,msg.value));
        claimedKnowledge[msg.sender] = SafeMath.add(claimedKnowledge[msg.sender],knowledgeBought);
    }
     
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
         
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateKnowledgeSell(uint256 knowledge) public view returns(uint256){
        return calculateTrade(knowledge,marketKnowledge,this.balance);
    }
    function calculateKnowledgeBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketKnowledge);
    }
    function calculateKnowledgeBuySimple(uint256 eth) public view returns(uint256){
        return calculateKnowledgeBuy(eth,this.balance);
    }
    function devFee(uint256 amount) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,10),100);  
    }
    function seedMarket(uint256 knowledge) external payable {
        require(marketKnowledge==0);
        initialized = true;
        marketKnowledge = knowledge;
    }

    function getBalance() public view returns(uint256){
        return this.balance;
    }
    function getMyFranklin() public view returns(uint256){
        return hatcheryFranklin[msg.sender];
    }
    function getMyKnowledge() public view returns(uint256){
        return SafeMath.add(claimedKnowledge[msg.sender],getKnowledgeSinceLastUse(msg.sender));
    }
    function getKnowledgeSinceLastUse(address adr) public view returns(uint256){
        uint256 secondsPassed = min(KNOWLEDGE_TO_GET_1FRANKLIN,SafeMath.sub(now,lastUse[adr]));
        return SafeMath.mul(secondsPassed,hatcheryFranklin[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

     
    function myTokens() public view returns(uint256) {
        return contractCall.myTokens();
    }

    function myDividends() public view returns(uint256) {
        return contractCall.myDividends(true);
    }


      
    function returnAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens) public onlyOwner() secCheck(tokenAddress) returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }


}


 
contract ERC20Interface
{
    function transfer(address to, uint256 tokens) public returns (bool success);
}

 
contract _Contract
{
    function buy(address) public payable returns(uint256);
    function exit() public;
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
    function withdraw() public;
    function transfer(address, uint256) public returns(bool);
}

library SafeMath {

      
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

       
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}