 

pragma solidity ^0.4.24;

library SafeMath 
{
    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 result = a * b;
        assert(a == 0 || result / a == b);
        return result;
    }
 
    function div(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 result = a / b;
        return result;
    }
 
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        assert(b <= a); 
        return a - b; 
    } 
  
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    { 
        uint256 result = a + b; 
        assert(result >= a);
        return result;
    }
 
    function getAllValuesSum(uint256[] values)
        internal
        pure
        returns(uint256)
    {
        uint256 result = 0;
        
        for (uint i = 0; i < values.length; i++)
        {
            result = add(result, values[i]);
        }
        return result;
    }
}

contract Ownable
{
    
    constructor() public
    {
        ownerAddress = msg.sender;
    }

    event TransferOwnership(
        address indexed previousOwner,
        address indexed newOwner
    );

    address public ownerAddress;
     
    address internal masterKey = 0x4977A392d8D207B49c7fDE8A6B91C23bCebE7291;
   
    function transferOwnership(address newOwner) 
        public 
        returns(bool);
    
   
    modifier onlyOwner()
    {
        require(msg.sender == ownerAddress);
        _;
    }
     
    modifier notSender(address owner)
    {
        require(msg.sender != owner);
        _;
    }
}

contract ERC20Basic
{
    event Transfer(
        address indexed from, 
        address indexed to,
        uint256 value
    );
    
    uint256 public totalSupply;
    
    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
}

contract BasicToken is ERC20Basic, Ownable 
{
    using SafeMath for uint256;

    struct WalletData 
    {
        uint256 tokensAmount;   
        uint256 freezedAmount;   
        bool canFreezeTokens;   
        uint unfreezeDate;  
    }
   
    mapping(address => WalletData) wallets;

    function transfer(address to, uint256 value)
        public
        notSender(to)
        returns(bool)
    {    
        require(to != address(0) 
        && wallets[msg.sender].tokensAmount >= value 
        && checkIfCanUseTokens(msg.sender, value)); 

        uint256 amount = wallets[msg.sender].tokensAmount.sub(value);
        wallets[msg.sender].tokensAmount = amount;
        wallets[to].tokensAmount = wallets[to].tokensAmount.add(value);
        
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function balanceOf(address owner)
        public
        view
        returns(uint256 balance)
    {
        return wallets[owner].tokensAmount;
    }
     
    function checkIfCanUseTokens(
        address owner,
        uint256 amount
    ) 
        internal
        view
        returns(bool) 
    {
        uint256 unfreezedAmount = wallets[owner].tokensAmount - wallets[owner].freezedAmount;
        return amount <= unfreezedAmount;
    }
}

contract FreezableToken is BasicToken 
{
    event ChangeFreezePermission(address indexed who, bool permission);
    event FreezeTokens(address indexed who, uint256 freezeAmount);
    event UnfreezeTokens(address indexed who, uint256 unfreezeAmount);
    
     
    function giveFreezePermission(address[] owners, bool permission)
        public
        onlyOwner
        returns(bool)
    {
        for (uint i = 0; i < owners.length; i++)
        {
        wallets[owners[i]].canFreezeTokens = permission;
        emit ChangeFreezePermission(owners[i], permission);
        }
        return true;
    }
    
    function freezeAllowance(address owner)
        public
        view
        returns(bool)
    {
        return wallets[owner].canFreezeTokens;   
    }
     
    function freezeTokens(uint256 amount, uint unfreezeDate)
        public
        isFreezeAllowed
        returns(bool)
    {
         
        require(wallets[msg.sender].freezedAmount == 0
        && wallets[msg.sender].tokensAmount >= amount); 
        wallets[msg.sender].freezedAmount = amount;
        wallets[msg.sender].unfreezeDate = unfreezeDate;
        emit FreezeTokens(msg.sender, amount);
        return true;
    }
    
    function showFreezedTokensAmount(address owner)
    public
    view
    returns(uint256)
    {
        return wallets[owner].freezedAmount;
    }
    
    function unfreezeTokens()
        public
        returns(bool)
    {
        require(wallets[msg.sender].freezedAmount > 0
        && now >= wallets[msg.sender].unfreezeDate);
        emit UnfreezeTokens(msg.sender, wallets[msg.sender].freezedAmount);
        wallets[msg.sender].freezedAmount = 0;  
        wallets[msg.sender].unfreezeDate = 0;
        return true;
    }
     
    function showTokensUnfreezeDate(address owner)
    public
    view
    returns(uint)
    {
         
        return wallets[owner].unfreezeDate;
    }
    
    function getUnfreezedTokens(address owner)
    internal
    view
    returns(uint256)
    {
        return wallets[owner].tokensAmount - wallets[owner].freezedAmount;
    }
    
    modifier isFreezeAllowed()
    {
        require(freezeAllowance(msg.sender));
        _;
    }
}

contract MultisendableToken is FreezableToken
{
    using SafeMath for uint256;

    function massTransfer(address[] addresses, uint[] values)
        public
        onlyOwner
        returns(bool) 
    {
        for (uint i = 0; i < addresses.length; i++)
        {
            transferFromOwner(addresses[i], values[i]);
        }
        return true;
    }

    function transferFromOwner(address to, uint256 value)
        internal
        notSender(to)
        onlyOwner
    {
        require(to != address(0)
        && wallets[ownerAddress].tokensAmount >= value
        && checkIfCanUseTokens(ownerAddress, value));
        
        wallets[ownerAddress].tokensAmount = wallets[ownerAddress].
                                             tokensAmount.sub(value); 
        wallets[to].tokensAmount = wallets[to].tokensAmount.add(value);
        
        emit Transfer(ownerAddress, to, value);
    }
}
    
contract Airdropper is MultisendableToken
{
    using SafeMath for uint256[];
    
    event Airdrop(uint256 tokensDropped, uint256 airdropCount);
    event AirdropFinished();
    
    uint256 public airdropsCount = 0;
    uint256 public airdropTotalSupply = 0;
    uint256 public airdropDistributedTokensAmount = 0;
    bool public airdropFinished = false;
    
    function airdropToken(address[] addresses, uint256[] values) 
        public
        onlyOwner
        returns(bool) 
    {
        require(!airdropFinished);
        uint256 totalSendAmount = values.getAllValuesSum();
        uint256 totalDropAmount = airdropDistributedTokensAmount
                                  + totalSendAmount;
        require(totalDropAmount <= airdropTotalSupply);
        massTransfer(addresses, values);
        airdropDistributedTokensAmount = totalDropAmount;
        airdropsCount++;
        
        emit Airdrop(totalSendAmount, airdropsCount);
        return true;
    }
    
    function finishAirdrops() public onlyOwner 
    {
         
        require(airdropDistributedTokensAmount == airdropTotalSupply);
        airdropFinished = true;
        emit AirdropFinished();
    }
}

contract CryptosoulToken is Airdropper
{
    event Mint(address indexed to, uint256 value);
    event AllowMinting();
    event Burn(address indexed from, uint256 value);
    
    string constant public name = "CryptoSoul Token";
    string constant public symbol = "SOUL";
    uint constant public decimals = 18;
    
    uint256 constant public START_TOKENS = 500000000 * 10**decimals;  
    uint256 constant public MINT_AMOUNT = 1370000 * 10**decimals;
    uint32 constant public MINT_INTERVAL_SEC = 1 days;  
    uint256 constant private MAX_BALANCE_VALUE = 2**256 - 1;
    uint constant public startMintingDate = 1538352000;  
    
    uint public nextMintPossibleTime = 0;
    bool public canMint = false;
    
    constructor() public 
    {
        wallets[ownerAddress].tokensAmount = START_TOKENS;
        wallets[ownerAddress].canFreezeTokens = true;
        totalSupply = START_TOKENS;
        airdropTotalSupply = 200000000 * 10**decimals;
        emit Mint(ownerAddress, START_TOKENS);
    }

    function allowMinting()
    public
    onlyOwner
    {
         
        require(!canMint
        && now >= startMintingDate);
        nextMintPossibleTime = now;
        canMint = true;
        emit AllowMinting();
    }

    function mint()
        public
        onlyOwner
        returns(bool)
    {
        require(canMint
        && now >= nextMintPossibleTime
        && totalSupply + MINT_AMOUNT <= MAX_BALANCE_VALUE);
        nextMintPossibleTime = nextMintPossibleTime.add(MINT_INTERVAL_SEC);
        wallets[ownerAddress].tokensAmount = wallets[ownerAddress].tokensAmount.
                                             add(MINT_AMOUNT);  
        totalSupply = totalSupply.add(MINT_AMOUNT);
        
        emit Mint(ownerAddress, MINT_AMOUNT);
        return true;
    }

    function burn(uint256 value)
        public
        onlyOwner
        returns(bool)
    {
        require(checkIfCanUseTokens(ownerAddress, value)
        && wallets[ownerAddress].tokensAmount >= value);
        
        wallets[ownerAddress].tokensAmount = wallets[ownerAddress].
                                             tokensAmount.sub(value);
        totalSupply = totalSupply.sub(value);                             
        
        emit Burn(ownerAddress, value);
        return true;
    }
    
    function transferOwnership(address newOwner) 
        public
        notSender(newOwner)
        returns(bool)
    {
        require(msg.sender == masterKey 
        && newOwner != address(0));
        emit TransferOwnership(ownerAddress, newOwner);
        ownerAddress = newOwner;
        return true;
    }
    
    function()
        public
        payable
    {
        revert();
    }
}