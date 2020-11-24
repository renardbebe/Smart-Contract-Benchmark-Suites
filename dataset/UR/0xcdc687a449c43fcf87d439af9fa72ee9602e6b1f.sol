 

pragma solidity ^0.4.24;

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
    }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
    constructor() public {
        owner = msg.sender;
    }

   
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

   
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

   
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0x0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
contract AbstractERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) public constant returns (uint256 value);
    function transfer(address _to, uint256 _value) public returns (bool _success);
    function allowance(address owner, address spender) public constant returns (uint256 _value);
    function transferFrom(address from, address to, uint256 value) public returns (bool _success);
    function approve(address spender, uint256 value) public returns (bool _success);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract LiquidToken is Ownable, AbstractERC20 {
    
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    
    address public teamWallet;
    address public advisorsWallet;
    address public founderWallet;
    address public bountyWallet;
    
    mapping (address => uint256) public balances;
     
    mapping (address => mapping (address => uint256)) public allowed;
    
    mapping(address => bool) public isTeamOrAdvisorsOrFounder;

    event Burn(address indexed burner, uint256 value);
    
    constructor() public {
    
        name = "Liquid";
        symbol = "LIQUID";
        decimals = 18;
        totalSupply = 58e6 * 10**18;     
        owner = msg.sender;
        balances[owner] = totalSupply;
        emit Transfer(0x0, owner, totalSupply);
    }

     
    function balanceOf(address owner) public view returns (uint256){
        return balances[owner];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {

        require(to != address(0x0));
        require(value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0x0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        balances[from] = balances[from].sub(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value); 
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

     
    function increaseApproval(address spender, uint valueToAdd) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(valueToAdd);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseApproval(address spender, uint valueToSubstract) public returns (bool) {
        uint oldValue = allowed[msg.sender][spender];
        if (valueToSubstract > oldValue) {
          allowed[msg.sender][spender] = 0;
        } else {
          allowed[msg.sender][spender] = oldValue.sub(valueToSubstract);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

     
    function burn(address _who, uint256 _value) public onlyOwner {
         
         
        balances[_who] = balances[_who].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
    
         
    function setTeamWallet (address _teamWallet) public onlyOwner returns (bool) {
        require(_teamWallet   !=  address(0x0));
        if(teamWallet ==  address(0x0)){  
            teamWallet    =   _teamWallet;
            balances[teamWallet]  =   4e6 * 10**18;
            balances[owner] = balances[owner].sub(balances[teamWallet]);
        }else{
            address oldTeamWallet =   teamWallet;
            teamWallet    =   _teamWallet;
            balances[teamWallet]  =   balances[oldTeamWallet];
        }
        return true;
    }

     
    function setAdvisorsWallet (address _advisorsWallet) public onlyOwner returns (bool) {
        require(_advisorsWallet   !=  address(0x0));
        if(advisorsWallet ==  address(0x0)){  
            advisorsWallet    =   _advisorsWallet;
            balances[advisorsWallet]  =   2e6 * 10**18;
            balances[owner] = balances[owner].sub(balances[teamWallet]);
        }else{
            address oldAdvisorsWallet =   advisorsWallet;
            advisorsWallet    =   _advisorsWallet;
            balances[advisorsWallet]  =   balances[oldAdvisorsWallet];
        }
        return true;
    }

     
    function setFoundersWallet (address _founderWallet) public onlyOwner returns (bool) {
        require(_founderWallet   !=  address(0x0));
        if(founderWallet ==  address(0x0)){  
            founderWallet    =   _founderWallet;
            balances[founderWallet]  =  8e6 * 10**18;
            balances[owner] = balances[owner].sub(balances[founderWallet]);
        }else{
            address oldFounderWallet =   founderWallet;
            founderWallet    =   _founderWallet;
            balances[founderWallet]  =   balances[oldFounderWallet];
        }
        return true;
    }
     
    function setBountyWallet (address _bountyWallet) public onlyOwner returns (bool) {
        require(_bountyWallet   !=  address(0x0));
        if(bountyWallet ==  address(0x0)){  
            bountyWallet    =   _bountyWallet;
            balances[bountyWallet]  =   4e6 * 10**18;
            balances[owner] = balances[owner].sub(balances[bountyWallet]);
        }else{
            address oldBountyWallet =   bountyWallet;
            bountyWallet    =   _bountyWallet;
            balances[bountyWallet]  =   balances[oldBountyWallet];
        }
        return true;
    }

     
    function airdrop(address[] dests, uint256[] values) public onlyOwner returns (uint256, bool) {
        require(dests.length == values.length);
        uint8 i = 0;
        while (i < dests.length && balances[bountyWallet] >= values[i]) {
            balances[bountyWallet]  =   balances[bountyWallet].sub(values[i]);
            balances[dests[i]]  =   balances[dests[i]].add(values[i]);
            i += 1;
        }
        return (i, true);
    }

     
    function transferTokensToTeams(address teamMember, uint256 values) public onlyOwner returns (bool) {
        require(teamMember != address(0));
        require (values != 0);
        balances[teamWallet]  =   balances[teamWallet].sub(values);
        balances[teamMember]  =   balances[teamMember].add(values);
        isTeamOrAdvisorsOrFounder[teamMember] = true;
        return true;
    }
     
     
    function transferTokensToFounders(address founder, uint256 values) public onlyOwner returns (bool) {
        require(founder != address(0));
        require (values != 0);
        balances[founderWallet]  =   balances[founderWallet].sub(values);
        balances[founder]  =   balances[founder].add(values);
        isTeamOrAdvisorsOrFounder[founder] = true;
        return true;
    }

     
    function transferTokensToAdvisors(address advisor, uint256 values) public onlyOwner returns (bool) {
        require(advisor != address(0));
        require (values != 0);
        balances[advisorsWallet]  =   balances[advisorsWallet].sub(values);
        balances[advisor]  =   balances[advisor].add(values);
        isTeamOrAdvisorsOrFounder[advisor] = true;
        return true;
    }

}

contract Crowdsale is LiquidToken {
    
    using SafeMath for uint256;

    address public ETHCollector;
    uint256 public tokenCost = 140;  
    uint256 public ETH_USD;  
    uint256 public saleStartDate;
    uint256 public saleEndDate;
    uint256 public softCap;
    uint256 public hardCap; 
    uint256 public minContribution = 28000;  
    uint256 public tokensSold;
    uint256 public weiCollected;
     
    uint256 public countInvestorsRefunded;
    uint256 public countTotalInvestors;
     
    bool public paused;
    bool public start;
    bool public stop;
     
    bool public refundStatus;
    
     
    struct Investor {
        uint256 investorID;
        uint256 weiReceived;
        uint256 tokenSent;
    }
    
     
    mapping(address => Investor) public investors;
    mapping(address => bool) public isinvestor;
    mapping(address => bool) public whitelist;
     
    mapping(uint256 => address) public investorList;

     
    event TokenSupplied(address beneficiary, uint256 tokens, uint256 value);   
    event RefundedToInvestor(address indexed beneficiary, uint256 weiAmount);
    event NewSaleEndDate(uint256 endTime);
    event StateChanged(bool changed);

    modifier respectTimeFrame() {
        require (start);
        require(!paused);
        require(now >= saleStartDate);
        require(now <= saleEndDate);
       _;
    }

    constructor(address _ETHCollector) public {
        ETHCollector = _ETHCollector;    
        hardCap = 40e6 * 10**18;
        softCap = 2e6 * 10**18;
         
        countInvestorsRefunded = 0;
         
        refundStatus = false;
    }
    
     
    function transferOwnership(address _newOwner) public onlyOwner {
        super.transfer(_newOwner, balances[owner]);
        _transferOwnership(_newOwner);
    }

      
    function startSale(uint256 _saleStartDate, uint256 _saleEndDate, uint256 _newETH_USD) public onlyOwner{
       require (_saleStartDate < _saleEndDate);
       require (now <= _saleStartDate);
       assert(!start);
       saleStartDate = _saleStartDate;
       saleEndDate = _saleEndDate;  
       start = true; 
       ETH_USD = _newETH_USD;
    }

     
    function finalizeSale() public onlyOwner{
        assert(start);
         
         
        assert(!(tokensSold < hardCap && now < saleEndDate) || (hardCap.sub(tokensSold) <= 1e18));  
        if(!softCapReached()){
            refundStatus = true;
        }
        start = false;
        stop = true;
    }

     
    function stopInEmergency() onlyOwner public {
        require(!paused);
        paused = true;
        emit StateChanged(true);
    }

     
    function release() onlyOwner public {
        require(paused);
        paused = false;
        emit StateChanged(true);
    }

     
    function setETH_USDRate(uint256 _newETH_USD) public onlyOwner {
        require(_newETH_USD > 0);
        ETH_USD = _newETH_USD;
    }

     
    function changeTokenCost(uint256 _tokenCost) public onlyOwner {
        require(_tokenCost > 0);
        tokenCost = _tokenCost;
    }

     
     
    function changeMinContribution(uint256 _minContribution) public onlyOwner {
        require(_minContribution > 0);
        minContribution = _minContribution;
    }

     
    function extendTime(uint256 _newEndSaleDate) onlyOwner public {
         
        require(saleEndDate < _newEndSaleDate);
        require(_newEndSaleDate != 0);
        saleEndDate = _newEndSaleDate;
        emit NewSaleEndDate(saleEndDate);
    }
    
    
     
    function addWhitelistAddress(address addr) public onlyOwner{
        require (!whitelist[addr]); 
        require(addr != address(0x0));
         
        whitelist[addr] = true;
    }
    
     
    function addWhitelistAddresses(address[] _addrs) public onlyOwner{
        for (uint256 i = 0; i < _addrs.length; i++) {
            addWhitelistAddress(_addrs[i]);        
        }
    }

    function transfer(address to, uint256 value) public returns (bool){
        if(isinvestor[msg.sender]){
             
            require(stop);
            super.transfer(to, value);
        }
        
        else if(isTeamOrAdvisorsOrFounder[msg.sender]){
             
            require(now > saleEndDate.add(180 days));
            super.transfer(to, value);
        }
        else {
            super.transfer(to, value);
        }
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool){
        if(isinvestor[from]){
             
            require(stop);
            super.transferFrom(from, to, value);
        } 
         else if(isTeamOrAdvisorsOrFounder[from]){
             
            require(now > saleEndDate.add(180 days));
            super.transferFrom(from,to, value);
        } 
        else {
           super.transferFrom(from, to, value);
        }
    }
    
     
    function buyTokens (address beneficiary) public payable respectTimeFrame {
         
        require(whitelist[beneficiary]);
         
        require(msg.value >= getMinContributionInWei());

        uint256 tokenToTransfer = getTokens(msg.value);

         
        require(tokensSold.add(tokenToTransfer) <= hardCap);
        tokensSold = tokensSold.add(tokenToTransfer);

         
        Investor storage investorStruct = investors[beneficiary];

         
        investorStruct.tokenSent = investorStruct.tokenSent.add(tokenToTransfer);
        investorStruct.weiReceived = investorStruct.weiReceived.add(msg.value);

         
        if(investorStruct.investorID == 0){
            countTotalInvestors++;
            investorStruct.investorID = countTotalInvestors;
            investorList[countTotalInvestors] = beneficiary;
        }

        isinvestor[beneficiary] = true;
        ETHCollector.transfer(msg.value);
        
        weiCollected = weiCollected.add(msg.value);
        
        balances[owner] = balances[owner].sub(tokenToTransfer);
        balances[beneficiary] = balances[beneficiary].add(tokenToTransfer);

        emit TokenSupplied(beneficiary, tokenToTransfer, msg.value);
    }

     
    function () external payable  {
        buyTokens(msg.sender);
    }

     
    function refund() public onlyOwner {
        assert(refundStatus);
        uint256 batchSize = countInvestorsRefunded.add(50) < countTotalInvestors ? countInvestorsRefunded.add(50): countTotalInvestors;
        for(uint256 i = countInvestorsRefunded.add(1); i <= batchSize; i++){
            address investorAddress = investorList[i];
            Investor storage investorStruct = investors[investorAddress];
             
            investorAddress.transfer(investorStruct.weiReceived);
             
            burn(investorAddress, investorStruct.tokenSent);
             
            investorStruct.weiReceived = 0;
            investorStruct.tokenSent = 0;
        }
         
        countInvestorsRefunded = batchSize;
    }

     
    function drain() public onlyOwner {
        ETHCollector.transfer(address(this).balance);
    }

     
    function fundContractForRefund()public payable{
    }

     
     
    
    function getTokens(uint256 weiReceived) internal view returns(uint256){
        uint256 tokens;
         
        if(now >= saleStartDate && now <= saleStartDate.add(10 days)){
            tokens = getTokensForWeiReceived(weiReceived);
            tokens = tokens.mul(100 + 60) / 100;
         
        }else if (now > saleStartDate.add(10 days) && now <= saleStartDate.add(25 days)){
            tokens = getTokensForWeiReceived(weiReceived);
            tokens = tokens.mul(100 + 50) / 100;
         
        }else if (now > saleStartDate.add(25 days)  && now <= saleEndDate){
            tokens = getTokensForWeiReceived(weiReceived);
            tokens = tokens.mul(100 + 30) / 100;
        }
        return tokens;
    }

     
    function getTokensForWeiReceived(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(ETH_USD).div(tokenCost);
    }

     
    function softCapReached() view public returns(bool) {
        return tokensSold >= softCap;
    }

     
    function getSaleStage() view public returns(uint8){
        if(now >= saleStartDate && now <= saleStartDate.add(10 days)){
            return 1;
        }else if(now > saleStartDate.add(10 days) && now <= saleStartDate.add(25 days)){
            return 2;
        }else if (now > saleStartDate.add(25 days)  && now <= saleEndDate){
            return 3;
        }
    }
    
     
     function getMinContributionInWei() public view returns(uint256){
        return (minContribution.mul(1e18)).div(ETH_USD);
    }
    
     
    function isAddressWhitelisted(address addr) public view returns(bool){
        return whitelist[addr];
    }
}