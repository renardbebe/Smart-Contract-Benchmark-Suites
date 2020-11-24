 

pragma solidity ^0.5.0;

 
 
interface IERC20 {

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}








 
 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}




 
 
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0),"You can't transfer the ownership to this account");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Remote is Ownable, IERC20 {
    using SafeMath for uint;

    IERC20 internal _remoteToken;
    address internal _remoteContractAddress;

    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

     
    function approveSpenderOnDex (address spender, uint256 value) 
        external onlyOwner returns (bool success) {
         
        _remoteToken.approve(spender, value);     
        success = true;
    }

    
    function remoteTransferFrom (address from, address to, uint256 value) external onlyOwner returns (bool) {
        return _remoteTransferFrom(from, to, value);
    }

     
    function setRemoteContractAddress (address remoteContractAddress)
        external onlyOwner returns (bool success) {
        _remoteContractAddress = remoteContractAddress;        
        _remoteToken = IERC20(_remoteContractAddress);
        success = true;
    }

    function remoteBalanceOf(address owner) external view returns (uint256) {
        return _remoteToken.balanceOf(owner);
    }

    function remoteTotalSupply() external view returns (uint256) {
        return _remoteToken.totalSupply();
    }

     
    function remoteAllowance (address owner, address spender) external view returns (uint256) {
        return _remoteToken.allowance(owner, spender);
    }

     
    function remoteBalanceOfDex () external view onlyOwner 
        returns(uint256 balance) {
        balance = _remoteToken.balanceOf(address(this));
    }

     
    function remoteAllowanceOnMyAddress () public view
        returns(uint256 myRemoteAllowance) {
        myRemoteAllowance = _remoteToken.allowance(msg.sender, address(this));
    } 

     
    function _remoteTransferFrom (address from, address to, uint256 value) internal returns (bool) {
        return _remoteToken.transferFrom(from, to, value);
    }

}

contract Dex is Remote {

    event TokensPurchased(address owner, uint256 amountOfTokens, uint256 amountOfWei);
    event TokensSold(address owner, uint256 amountOfTokens, uint256 amountOfWei);
    event TokenPricesSet(uint256 sellPrice, uint256 buyPrice);
    
    address internal _dexAddress;

    uint256 public sellPrice = 200000000000;
    uint256 public buyPrice = 650000000000;
     
     
     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner returns (bool success) {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;

        emit TokenPricesSet(sellPrice, buyPrice);
        success = true;
    }

    function topUpEther() external payable {
         
         
    }
    
    function _purchaseToken (address sender, uint256 amountOfWei) internal returns (bool success) {
        
        uint256 amountOfTokens = buyTokenExchangeAmount(amountOfWei);
        
        uint256 dexTokenBalance = _remoteToken.balanceOf(_dexAddress);
        require(dexTokenBalance >= amountOfTokens, "The VeriDex does not have enough tokens for this purchase.");

        _remoteToken.transfer(sender, amountOfTokens);

        emit TokensPurchased(sender, amountOfTokens, amountOfWei);
        success = true;
    }

     
    function dexRequestTokensFromUser () external returns (bool success) {

         
         
        uint256 amountAllowed = _remoteToken.allowance(msg.sender, _dexAddress);

        require(amountAllowed > 0, "No allowance has been set.");        
        
        uint256 amountBalance = _remoteToken.balanceOf(msg.sender);

        require(amountBalance >= amountAllowed, "Your balance must be equal or more than your allowance");
        
        uint256 amountOfWei = sellTokenExchangeAmount(amountAllowed);

        uint256 dexWeiBalance = _dexAddress.balance;

        uint256 dexTokenBalance = _remoteToken.balanceOf(_dexAddress);

        require(dexWeiBalance >= amountOfWei, "Dex balance must be equal or more than your allowance");

        _remoteTransferFrom(msg.sender, _dexAddress, amountAllowed);

        _remoteToken.approve(_dexAddress, dexTokenBalance.add(amountAllowed));  
 
         
        msg.sender.transfer(amountOfWei);

        emit TokensSold(msg.sender, amountAllowed, amountOfWei);
        success = true;
    }
 
     
    function etherBalance() public view returns (uint256 etherValue) {
        etherValue = _dexAddress.balance;
    }

     
    function withdrawBalance() public onlyOwner returns (bool success) {
        msg.sender.transfer(_dexAddress.balance);
        success = true;
    }

     
    function buyTokenExchangeAmount(uint256 numberOfWei) public view returns (uint256 tokensOut) {
        tokensOut = numberOfWei.mul(10**18).div(buyPrice);
    }

     
    function sellTokenExchangeAmount(uint256 numberOfTokens) public view returns (uint256 weiOut) {
        weiOut = numberOfTokens.mul(sellPrice).div(10**18);
    }
 
}

 

contract VeriDex is Dex {
    
     

    string public symbol;
    string public  name;
    uint8 public decimals;
     
    constructor ( address remoteContractAddress)
        public  {
        symbol = "VRDX";
        name = "VeriDex";
        decimals = 18;
        _totalSupply = 20000000000 * 10**uint(decimals);
        _remoteContractAddress = remoteContractAddress;
        _remoteToken = IERC20(_remoteContractAddress);
        _dexAddress = address(this);
        balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    function() external payable {
         
        require(_purchaseToken(msg.sender, msg.value), "Validation on purchase failed.");
    }
 
      
    function adminDoDestructContract() external onlyOwner { 
        selfdestruct(msg.sender);
    }

      
    function dexDetails() external view returns (
        address dexAddress,  
        address remoteContractAddress) {
        dexAddress = _dexAddress;
        remoteContractAddress = _remoteContractAddress;
    }

}