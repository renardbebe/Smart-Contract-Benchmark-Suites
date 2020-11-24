 

pragma solidity ^0.4.24;

 

 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = 0x0B0eFad4aE088a88fFDC50BCe5Fb63c6936b9220;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

 
 
 
 
contract CELT is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


     
     
     
    constructor() public {
        symbol = "CELT";
        name = "COSS Exchange Liquidity Token";
        decimals = 18;
        _totalSupply = 10000000 ether;
        balances[owner] = _totalSupply;
        emit Transfer(address(0),owner, _totalSupply);
        Hub_.setAuto(10);
    }


     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint tokens) updateAccount(to) updateAccount(msg.sender) public returns (bool success) {
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


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens)updateAccount(to) updateAccount(from) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
     
    PlincInterface constant Hub_ = PlincInterface(0xd5D10172e8D8B84AC83031c16fE093cba4c84FC6);
    uint256 public ethPendingDistribution;

     
    function fetchHubVault() public{
        
        uint256 value = Hub_.playerVault(address(this));
        require(value >0);
        Hub_.vaultToWallet();
        ethPendingDistribution = ethPendingDistribution.add(value);
    }
    function fetchHubPiggy() public{
        
        uint256 value = Hub_.piggyBank(address(this));
        require(value >0);
        Hub_.piggyToWallet();
        ethPendingDistribution = ethPendingDistribution.add(value);
    }
    function disburseHub() public  {
    uint256 amount = ethPendingDistribution;
    ethPendingDistribution = 0;
    totalDividendPoints = totalDividendPoints.add(amount.mul(pointMultiplier).div(_totalSupply));
    unclaimedDividends = unclaimedDividends.add(amount);
    }
     
     
    uint256 public pointMultiplier = 10e18;
    struct Account {
    uint balance;
    uint lastDividendPoints;
    }
    mapping(address=>Account) accounts;
    mapping(address=>uint256) public PSA;
    uint public ethtotalSupply;
    uint public totalDividendPoints;
    uint public unclaimedDividends;

    function dividendsOwing(address account) public view returns(uint256) {
        uint256 newDividendPoints = totalDividendPoints.sub(accounts[account].lastDividendPoints);
        return (balances[account] * newDividendPoints) / pointMultiplier;
    }
    
    modifier updateAccount(address account) {
        uint256 owing = dividendsOwing(account);
        if(owing > 0) {
            unclaimedDividends = unclaimedDividends.sub(owing);
            PSA[account] =  PSA[account].add(owing);
        }
        accounts[account].lastDividendPoints = totalDividendPoints;
        _;
    }
     
    function () external payable{}
     
    function fetchPSA() public updateAccount(msg.sender){}
     
    function disburse() public  payable {
        uint256 base = msg.value.div(20);
        uint256 amount = msg.value.sub(base);
        Hub_.buyBonds.value(base)(address(this)) ;
        totalDividendPoints = totalDividendPoints.add(amount.mul(pointMultiplier).div(_totalSupply));
        unclaimedDividends = unclaimedDividends.add(amount);
    }
    function PSAtoWallet() public {
    if(dividendsOwing(msg.sender) > 0)
    {
        fetchPSA();
    }
    
    uint256 amount = PSA[msg.sender];
    require(amount >0);
    PSA[msg.sender] = 0;
    msg.sender.transfer(amount) ;
  
    }
    function PSAtoWalletByAddres(address toAllocate) public {
    
    uint256 amount = PSA[toAllocate];
    require(amount >0);
    PSA[toAllocate] = 0;
    toAllocate.transfer(amount) ;
  
    }
    function rectifyWrongs(address toAllocate, uint256 amount) public onlyOwner {
    
    require(amount >0);
    toAllocate.transfer(amount) ;
  
    }

    }
    interface PlincInterface {
    
    function IdToAdress(uint256 index) external view returns(address);
    function nextPlayerID() external view returns(uint256);
    function bondsOutstanding(address player) external view returns(uint256);
    function playerVault(address player) external view returns(uint256);
    function piggyBank(address player) external view returns(uint256);
    function vaultToWallet() external ;
    function piggyToWallet() external ;
    function setAuto (uint256 percentage)external ;
    function buyBonds( address referral)external payable ;
}