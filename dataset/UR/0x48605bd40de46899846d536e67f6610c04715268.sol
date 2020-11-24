 

pragma solidity >= 0.4.24 < 0.6.0;


 


 
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
     
     
     

    event Transfer(address indexed from, address indexed to, uint256 value);
     
}


 
contract MegaCoin is IERC20 {
     

    string public name = "MEGA";
    string public symbol = "MEGA";
    uint8 public decimals = 18;
    
    uint256 _totalSupply;
    mapping(address => uint256) balances;

     
    address public owner;
    address public team;
    
     
    enum VaultEnum {mining, mkt, op, team, presale}
    string[] VaultName = ["mining", "mkt", "op", "team", "presale"];
    mapping(string => uint256) vault;

    modifier isOwner {
        require(owner == msg.sender);
        _;
    }
    
    constructor() public {
        uint256 discardCoins;     

        owner = msg.sender;
        team = 0xB20a2214E60fa99911eb597faa1216DAc006fc29;
        require(owner != team);

        setVaultBalanceInDecimal(VaultEnum.mining,   10000000000);    
        setVaultBalanceInDecimal(VaultEnum.mkt,      1000000000);     
        setVaultBalanceInDecimal(VaultEnum.op,       2000000000);     
        setVaultBalanceInDecimal(VaultEnum.team,     3000000000);     
        setVaultBalanceInDecimal(VaultEnum.presale,  2999645274);     

        discardCoins = convertToWei(1000354726);             

         
        _totalSupply = 
            getVaultBalance(VaultEnum.mining) +
            getVaultBalance(VaultEnum.mkt) +
            getVaultBalance(VaultEnum.op) +
            getVaultBalance(VaultEnum.team) +
            getVaultBalance(VaultEnum.presale) +
            discardCoins;
            
        require(_totalSupply == convertToWei(20000000000));
        
        _totalSupply -= discardCoins;    
        balances[owner] = _totalSupply;

        emit Transfer(address(0), owner, balances[owner]);
    }
    
     
    function transferForMining(address to) external isOwner {
        require(to != owner);
        withdrawCoins(VaultName[uint256(VaultEnum.mining)], to);
    }
    
     
    function withdrawForMkt(address to) external isOwner {
        require(to != owner);
        withdrawCoins(VaultName[uint256(VaultEnum.mkt)], to);
    }
    
     
    function withdrawForOp(address to) external isOwner {
        require(to != owner);
        withdrawCoins(VaultName[uint256(VaultEnum.op)], to);
    }

     
    function withdrawTeamFunds() external isOwner {
        uint256 balance = getVaultBalance(VaultEnum.team);
        require(balance > 0);

        withdrawCoins(VaultName[uint256(VaultEnum.team)], team);
    }

     
    function transferPresaleCoins(address to, uint256 amount) external isOwner {
        require(to != owner);
        require(balances[owner] >= amount);
        require(getVaultBalance(VaultEnum.presale) >= amount);
        
        balances[owner] -= amount;
        balances[to] += amount;
        vault[VaultName[uint256(VaultEnum.presale)]] -= amount;

        emit Transfer(owner, to, amount);
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address who) public view returns (uint256) {
        return balances[who];
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
        require(msg.sender != to);
        require(msg.sender != owner);    
        require(to != owner);
        require(value > 0);
        
        require( balances[msg.sender] >= value );
        require( balances[to] + value >= balances[to] );     

        if(msg.sender == team) {
            require(now >= 1576940400);      
        }
        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }
    
     
    function burnCoins(uint256 value) public {
        require(msg.sender != owner);    
        require(balances[msg.sender] >= value);
        require(_totalSupply >= value);
        
        balances[msg.sender] -= value;
        _totalSupply -= value;

        emit Transfer(msg.sender, address(0), value);
    }

    function vaultBalance(string vaultName) public view returns (uint256) {
        return vault[vaultName];
    }
    
     
    function getStat() public isOwner view returns (uint256 vaultTotal) {

        uint256 totalVault =
            getVaultBalance(VaultEnum.mining) +
            getVaultBalance(VaultEnum.mkt) +
            getVaultBalance(VaultEnum.op) +
            getVaultBalance(VaultEnum.team) +
            getVaultBalance(VaultEnum.presale);

        return totalVault;
    }
        
     
    function withdrawCoins(string vaultName, address to) private returns (uint256) {
        uint256 balance = vault[vaultName];
        
        require(balance > 0);
        require(balances[owner] >= balance);
        require(owner != to);

        balances[owner] -= balance;
        balances[to] += balance;
        vault[vaultName] = 0;
        
        emit Transfer(owner, to, balance);
        return balance;
    }
    
     
    function setVaultBalanceInDecimal(VaultEnum vaultNum, uint256 amount) private {
        vault[VaultName[uint256(vaultNum)]] = convertToWei(amount);
    }
    
    function getVaultBalance(VaultEnum vaultNum) private constant returns (uint256) {
        return vault[VaultName[uint256(vaultNum)]];
    }
    
    function convertToWei(uint256 value) private constant returns (uint256) {
        return value * (10 ** uint256(decimals));
    }
}