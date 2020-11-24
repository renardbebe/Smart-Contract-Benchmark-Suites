 

pragma solidity >= 0.4.24 < 0.6.0;


 


 
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
     
     
     

    event Transfer(address indexed from, address indexed to, uint256 value);
     
}


 
contract CatCoin is IERC20 {
     

    string public name = "뻘쭘이코인";
    string public symbol = "BBOL";
    uint8 public decimals = 18;
    
    uint256 totalCoins;
    mapping(address => uint256) balances;

     
    address public owner;
    
     
    enum VaultEnum {mining, mkt, op, team, presale}
    string[] VaultName = ["mining", "mkt", "op", "team", "presale"];
    mapping(string => uint256) vault;

    modifier isOwner {
        require(owner == msg.sender);
        _;
    }
    
    event BurnCoin(uint256 amount);

    constructor() public {
        uint256 discardCoins;     

        owner = msg.sender;

        setVaultBalance(VaultEnum.mining,   10000000000);    
        setVaultBalance(VaultEnum.mkt,      1000000000);     
        setVaultBalance(VaultEnum.op,       2000000000);     
        setVaultBalance(VaultEnum.team,     3000000000);     
        setVaultBalance(VaultEnum.presale,  3000000000);     

        discardCoins = convertToWei(1000000000);             

         
        totalCoins = 
            getVaultBalance(VaultEnum.mining) +
            getVaultBalance(VaultEnum.mkt) +
            getVaultBalance(VaultEnum.op) +
            getVaultBalance(VaultEnum.team) +
            getVaultBalance(VaultEnum.presale) +
            discardCoins;
            
        require(totalCoins == convertToWei(20000000000));
        
        totalCoins -= getVaultBalance(VaultEnum.team);     
        balances[owner] = totalCoins;

        emit Transfer(address(0), owner, balances[owner]);
        burnCoin(discardCoins);
    }
    
     
    function transferForMining(address to) external isOwner {
        withdrawCoins(VaultName[uint256(VaultEnum.mining)], to);
    }
    
     
    function withdrawForMkt(address to) external isOwner {
        withdrawCoins(VaultName[uint256(VaultEnum.mkt)], to);
    }
    
     
    function withdrawForOp(address to) external isOwner {
        withdrawCoins(VaultName[uint256(VaultEnum.op)], to);
    }

     
    function withdrawForTeam(address to) external isOwner {
        uint256 balance = getVaultBalance(VaultEnum.team);
        require(balance > 0);
        require(now >= 1576594800);      
         
        
        balances[owner] += balance;
        totalCoins += balance;
        withdrawCoins(VaultName[uint256(VaultEnum.team)], to);
    }

     
    function transferSoldCoins(address to, uint256 amount) external isOwner {
        require(balances[owner] >= amount);
        require(getVaultBalance(VaultEnum.presale) >= amount);
        
        balances[owner] -= amount;
        balances[to] += amount;
        setVaultBalance(VaultEnum.presale, getVaultBalance(VaultEnum.presale) - amount);

        emit Transfer(owner, to, amount);
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
    
    function burnCoin(uint256 amount) public isOwner {
        require(balances[msg.sender] >= amount);
        require(totalCoins >= amount);

        balances[msg.sender] -= amount;
        totalCoins -= amount;

        emit BurnCoin(amount);
    }

    function totalSupply() public constant returns (uint) {
        return totalCoins;
    }

    function balanceOf(address who) public view returns (uint256) {
        return balances[who];
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
        require(msg.sender != to);
        require(value > 0);
        
        require( balances[msg.sender] >= value );
        require( balances[to] + value >= balances[to] );     

        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }
    
     
    function setVaultBalance(VaultEnum vaultNum, uint256 amount) private {
        vault[VaultName[uint256(vaultNum)]] = convertToWei(amount);
    }
    
    function getVaultBalance(VaultEnum vaultNum) private constant returns (uint256) {
        return vault[VaultName[uint256(vaultNum)]];
    }
    
    function convertToWei(uint256 value) private constant returns (uint256) {
        return value * (10 ** uint256(decimals));
    }
}