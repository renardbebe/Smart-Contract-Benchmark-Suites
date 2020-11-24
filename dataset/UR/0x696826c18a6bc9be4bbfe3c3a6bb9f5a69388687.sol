 

pragma solidity ^0.4.25;

contract DecentralizationSmartGames{
    using SafeMath for uint256;
    
    string public constant name   = "Decentralization Smart Games";
    string public constant symbol = "DSG";
    uint8 public constant decimals = 18;
    uint256 public constant tokenPrice = 0.00065 ether;
    uint256 public totalSupply;  
    uint256 public divPerTokenPool;  
    uint256 public divPerTokenGaming;  
    uint256 public developmentBalance;  
    uint256 public charityBalance;   
    address[2] public owners;   
    address[2] public candidates;  
     
    Fee public fee = Fee(6,4,3,2,1,1,18,65);
     
    Dividends public totalDividends  = Dividends(0,0,0);
    mapping (address => mapping (address => uint256)) private allowed;
     
    mapping (address => Account) public account;
    mapping (address => bool) public games;  
    
    struct Account {
        uint256 tokenBalance;
        uint256 ethereumBalance;
        uint256 lastDivPerTokenPool;
        uint256 lastDivPerTokenGaming;
        uint256 totalDividendsReferrer;
        uint256 totalDividendsGaming;
        uint256 totalDividendsPool;
        address[5] referrer;
        bool active;
    }
    struct Fee{
        uint8 r1;
        uint8 r2;
        uint8 r3;
        uint8 r4;
        uint8 r5;
        uint8 charity;
        uint8 development;
        uint8 buy;
    }
    struct Dividends{
        uint256 referrer;
        uint256 gaming;
        uint256 pool;
    }
     
    modifier check0x(address address0x) {
        require(address0x != address(0), "Address is 0x");
        _;
    }
     
    modifier checkDSG(uint256 amountDSG) {
        require(account[msg.sender].tokenBalance >= amountDSG, "You don't have enough DSG on balance");
        _;
    }
     
    modifier checkETH(uint256 amountETH) {
        require(account[msg.sender].ethereumBalance >= amountETH, "You don't have enough ETH on balance");
        _;
    }
     
    modifier onlyOwners() {
        require(msg.sender == owners[0] || msg.sender == owners[1], "You are not owner");
        _;
    }
     
    modifier sellTime() { 
        require(now <= 1560211200, "The sale is over");
        _;
    }
     
     
    modifier payDividends(address sender) {
        uint256 poolDividends = getPoolDividends();
        uint256 gamingDividends = getGamingDividends();
		if(poolDividends > 0 && account[sender].active == true){
			account[sender].totalDividendsPool = account[sender].totalDividendsPool.add(poolDividends);
			account[sender].ethereumBalance = account[sender].ethereumBalance.add(poolDividends);
		}
        if(gamingDividends > 0 && account[sender].active == true){
			account[sender].totalDividendsGaming = account[sender].totalDividendsGaming.add(gamingDividends);
			account[sender].ethereumBalance = account[sender].ethereumBalance.add(gamingDividends);
		}
        _;
	    account[sender].lastDivPerTokenPool = divPerTokenPool;
        account[sender].lastDivPerTokenGaming = divPerTokenGaming;
        
    }
     
    constructor(address owner2) public{
        address owner1 = msg.sender;
        owners[0]                = owner1;
        owners[1]                = owner2;
        account[owner1].active   = true;
        account[owner2].active   = true;
        account[owner1].referrer = [owner1, owner1, owner1, owner1, owner1];
        account[owner2].referrer = [owner2, owner2, owner2, owner2, owner2];
    }
     
    function buy(address referrerAddress) payDividends(msg.sender) sellTime public payable
    {
        require(msg.value >= 0.1 ether, "Minimum investment is 0.1 ETH");
        uint256 forTokensPurchase = msg.value.mul(fee.buy).div(100);  
        uint256 forDevelopment = msg.value.mul(fee.development).div(100);  
        uint256 forCharity = msg.value.mul(fee.charity).div(100);  
        uint256 tokens = forTokensPurchase.mul(10 ** uint(decimals)).div(tokenPrice);  
        _setReferrer(referrerAddress, msg.sender);   
        _mint(msg.sender, tokens);  
        _setProjectDividends(forDevelopment, forCharity);  
        _distribution(msg.sender, msg.value.mul(fee.r1).div(100), 0);  
        _distribution(msg.sender, msg.value.mul(fee.r2).div(100), 1);  
        _distribution(msg.sender, msg.value.mul(fee.r3).div(100), 2);  
        _distribution(msg.sender, msg.value.mul(fee.r4).div(100), 3);  
        _distribution(msg.sender, msg.value.mul(fee.r5).div(100), 4);  
        emit Buy(msg.sender, msg.value, tokens, totalSupply, now);
    }
     
    function reinvest(uint256 amountEthereum) payDividends(msg.sender) checkETH(amountEthereum) sellTime public
    {
        uint256 tokens = amountEthereum.mul(10 ** uint(decimals)).div(tokenPrice);  
        _mint(msg.sender, tokens);  
        account[msg.sender].ethereumBalance = account[msg.sender].ethereumBalance.sub(amountEthereum); 
        emit Reinvest(msg.sender, amountEthereum, tokens, totalSupply, now);
    }
     
    function sell(uint256 amountTokens) payDividends(msg.sender) checkDSG(amountTokens) public
    {
        uint256 ethereum = amountTokens.mul(tokenPrice).div(10 ** uint(decimals)); 
        account[msg.sender].ethereumBalance = account[msg.sender].ethereumBalance.add(ethereum);
        _burn(msg.sender, amountTokens); 
        emit Sell(msg.sender, amountTokens, ethereum, totalSupply, now);
    }
     
    function withdraw(uint256 amountEthereum) payDividends(msg.sender) checkETH(amountEthereum) public
    {
        msg.sender.transfer(amountEthereum);  
        account[msg.sender].ethereumBalance = account[msg.sender].ethereumBalance.sub(amountEthereum); 
        emit Withdraw(msg.sender, amountEthereum, now);
    }
     
    function gamingDividendsReception() payable external{
        require(getGame(msg.sender) == true, "Game not active");
        uint256 eth            = msg.value;
        uint256 forDevelopment = eth.mul(19).div(100);  
        uint256 forInvesotrs   = eth.mul(80).div(100);  
        uint256 forCharity     = eth.div(100);  
        _setProjectDividends(forDevelopment, forCharity);  
        _setGamingDividends(forInvesotrs);  
    }
     
    function _distribution(address senderAddress, uint256 eth, uint8 k) private{
        address referrer = account[senderAddress].referrer[k];
        uint256 referrerBalance = account[referrer].tokenBalance;
        uint256 senderTokenBalance = account[senderAddress].tokenBalance;
        uint256 minReferrerBalance = 10000e18;
        if(referrerBalance >= minReferrerBalance){
            _setReferrerDividends(referrer, eth); 
        }
        else if(k == 0 && referrerBalance < minReferrerBalance && referrer != address(0)){
            uint256 forReferrer = eth.mul(referrerBalance).div(minReferrerBalance); 
            uint256 forPool = eth.sub(forReferrer); 
            _setReferrerDividends(referrer, forReferrer); 
            _setPoolDividends(forPool, senderTokenBalance); 
        }
        else{
            _setPoolDividends(eth, senderTokenBalance); 
        }
    }
     
    function _setReferrerDividends(address referrer, uint256 eth) private {
        account[referrer].ethereumBalance = account[referrer].ethereumBalance.add(eth);
        account[referrer].totalDividendsReferrer = account[referrer].totalDividendsReferrer.add(eth);
        totalDividends.referrer = totalDividends.referrer.add(eth);
    }
     
    function _setReferrer(address referrerAddress, address senderAddress) private
    {
        if(account[senderAddress].active == false){
            require(referrerAddress != senderAddress, "You can't be referrer for yourself");
            require(account[referrerAddress].active == true || referrerAddress == address(0), "Your referrer was not found in the contract");
            account[senderAddress].referrer = [
                                               referrerAddress,  
                                               account[referrerAddress].referrer[0],
                                               account[referrerAddress].referrer[1],
                                               account[referrerAddress].referrer[2],
                                               account[referrerAddress].referrer[3]
                                              ];
            account[senderAddress].active   = true;  
            emit Referrer(
                senderAddress,
                account[senderAddress].referrer[0],
                account[senderAddress].referrer[1],
                account[senderAddress].referrer[2],
                account[senderAddress].referrer[3],
                account[senderAddress].referrer[4],
                now
            );
        }
    }
     
    function _setProjectDividends(uint256 forDevelopment, uint256 forCharity) private{
        developmentBalance = developmentBalance.add(forDevelopment);
        charityBalance = charityBalance.add(forCharity);
    }
     
    function _setPoolDividends(uint256 amountEthereum, uint256 userTokens) private{
        if(amountEthereum > 0){
		    divPerTokenPool = divPerTokenPool.add(amountEthereum.mul(10 ** uint(decimals)).div(totalSupply.sub(userTokens)));
		    totalDividends.pool = totalDividends.pool.add(amountEthereum);
        }
    }
     
    function _setGamingDividends(uint256 amountEthereum) private{
        if(amountEthereum > 0){
		    divPerTokenGaming = divPerTokenGaming.add(amountEthereum.mul(10 ** uint(decimals)).div(totalSupply));
		    totalDividends.gaming = totalDividends.gaming.add(amountEthereum);
        }
    }
     
    function setGame(address gameAddress, bool active) public onlyOwners returns(bool){
        games[gameAddress] = active;
        return true;
    }
     
    function getPoolDividends() public view returns(uint256)
    {
        uint newDividendsPerToken = divPerTokenPool.sub(account[msg.sender].lastDivPerTokenPool);
        return account[msg.sender].tokenBalance.mul(newDividendsPerToken).div(10 ** uint(decimals));
    }
     
    function getGamingDividends() public view returns(uint256)
    {
        uint newDividendsPerToken = divPerTokenGaming.sub(account[msg.sender].lastDivPerTokenGaming);
        return account[msg.sender].tokenBalance.mul(newDividendsPerToken).div(10 ** uint(decimals));
    }
     
    function getAccountData() public view returns(
        uint256 tokenBalance,
        uint256 ethereumBalance, 
        uint256 lastDivPerTokenPool,
        uint256 lastDivPerTokenGaming,
        uint256 totalDividendsPool,
        uint256 totalDividendsReferrer,
        uint256 totalDividendsGaming,
        address[5] memory referrer,
        bool active)
    {
        return(
            account[msg.sender].tokenBalance,
            account[msg.sender].ethereumBalance,
            account[msg.sender].lastDivPerTokenPool,
            account[msg.sender].lastDivPerTokenGaming,
            account[msg.sender].totalDividendsPool,
            account[msg.sender].totalDividendsReferrer,
            account[msg.sender].totalDividendsGaming,
            account[msg.sender].referrer,
            account[msg.sender].active
        );
    }
     
    function getContractBalance() view public returns (uint256) {
        return address(this).balance;
    }
     
    function getGame(address gameAddress) view public returns (bool) {
        return games[gameAddress];
    }
     
    function transferOwnership(address candidate, uint8 k) check0x(candidate) onlyOwners public
    {
        candidates[k] = candidate;
    }
     
    function confirmOwner(uint8 k) public
    {
        require(msg.sender == candidates[k], "You are not candidate");
        owners[k] = candidates[k];
        delete candidates[k];
    }
     
    function charitytWithdraw(address recipient) onlyOwners check0x(recipient) public
    {
        recipient.transfer(charityBalance);
        delete charityBalance;
    }
     
    function developmentWithdraw(address recipient) onlyOwners check0x(recipient) public
    {
        recipient.transfer(developmentBalance);
        delete developmentBalance;
    }
     
    function balanceOf(address owner) public view returns(uint256)
    {
        return account[owner].tokenBalance;
    }
     
    function allowance(address owner, address spender) public view returns(uint256)
    {
        return allowed[owner][spender];
    }
     
    function transfer(address to, uint256 value) public returns(bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }
     
    function approve(address spender, uint256 value) check0x(spender) checkDSG(value) public returns(bool)
    {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
     
    function transferFrom(address from, address to, uint256 value) public returns(bool)
    {
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, allowed[from][msg.sender]);
        return true;
    }
     
    function _transfer(address from, address to, uint256 value) payDividends(from) payDividends(to) checkDSG(value) check0x(to) private
    {
        account[from].tokenBalance = account[from].tokenBalance.sub(value);
        account[to].tokenBalance = account[to].tokenBalance.add(value);
        if(account[to].active == false) account[to].active = true;
        emit Transfer(from, to, value);
    }
     
    function _mint(address customerAddress, uint256 value) check0x(customerAddress) private
    {
        totalSupply = totalSupply.add(value);
        account[customerAddress].tokenBalance = account[customerAddress].tokenBalance.add(value);
        emit Transfer(address(0), customerAddress, value);
    }
     
    function _burn(address customerAddress, uint256 value) check0x(customerAddress) private
    {
        totalSupply = totalSupply.sub(value);
        account[customerAddress].tokenBalance = account[customerAddress].tokenBalance.sub(value);
        emit Transfer(customerAddress, address(0), value);
    }
    event Buy(
        address indexed customerAddress,
        uint256 inputEthereum,
        uint256 outputToken,
        uint256 totalSupply,
        uint256 timestamp
    );
    event Sell(
        address indexed customerAddress,
        uint256 amountTokens,
        uint256 outputEthereum,
        uint256 totalSupply,
        uint256 timestamp
    );
    event Reinvest(
        address indexed customerAddress,
        uint256 amountEthereum,
        uint256 outputToken,
        uint256 totalSupply,
        uint256 timestamp
    );
    event Withdraw(
        address indexed customerAddress,
        uint256 indexed amountEthereum,
        uint256 timestamp
    );
    event Referrer(
        address indexed customerAddress,
        address indexed referrer1,
        address referrer2,
        address referrer3,
        address referrer4,
        address referrer5,
        uint256 timestamp
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint tokens
    );
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint tokens
    );
}
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {  return 0; }
        uint256 c = a * b;
        require(c / a == b, "Mul error");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Div error");
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Sub error");
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Add error");
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "Mod error");
        return a % b;
    }
}